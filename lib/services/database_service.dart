import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sf;
import '../models/item_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  // Firebase Engines
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Supabase Engine
  final sf.SupabaseClient _supabase = sf.Supabase.instance.client;

  // ==========================================================
  // 1. GET ITEMS (Uses Firebase Firestore)
  // ==========================================================
  Stream<List<ItemModel>> getItems(String filter) {
    Query query = _db.collection('items').where('status', isEqualTo: 'OPEN');
    // .orderBy('createdAt', descending: true);

    if (filter == 'Barang Hilang') {
      query = query.where('type', isEqualTo: 'LOST');
    } else if (filter == 'Barang Ketemu') {
      query = query.where('type', isEqualTo: 'FOUND');
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // ==========================================================
  // 2. UPLOAD IMAGE (Uses Supabase Storage)
  // ==========================================================
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'uploads/$fileName';

      // Upload to Supabase Bucket 'images'
      await _supabase.storage
          .from('images')
          .upload(
            path,
            imageFile,
            fileOptions: const sf.FileOptions(contentType: 'image/jpeg'),
          );

      // Get the Public URL
      final imageUrl = _supabase.storage.from('images').getPublicUrl(path);

      print("✅ Supabase Upload Success: $imageUrl");
      return imageUrl;
    } catch (e) {
      print("❌ Supabase Upload Failed: $e");
      return '';
    }
  }

  // ==========================================================
  // 3. CREATE REPORT (Hybrid Logic)
  // ==========================================================
  Future<void> createItemReport({
    required String type,
    required String itemName,
    required String location,
    required String note,
    File? imageFile,
    DateTime? specificDate,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    String imageUrl = '';

    // Step 1: Upload to Supabase (if image exists)
    if (imageFile != null) {
      imageUrl = await uploadImage(imageFile);
    }

    // Step 2: Save Data to Firebase Firestore
    DateTime dateToUse = specificDate ?? DateTime.now();

    ItemModel newItem = ItemModel(
      id: '', // Firestore generates this
      reporterId: user.uid,
      reporterName: user.displayName ?? user.email!.split('@')[0],
      type: type,
      itemName: itemName,
      imageUrl: imageUrl, // Uses the Supabase Link
      location: location,
      note: note,
      date: dateToUse,
      status: 'OPEN',
    );

    // Save to Firestore
    await _db.collection('items').add(newItem.toMap());
  }

  // ==========================================================
  // 4. CHAT FUNCTIONS
  // ==========================================================

  // A. Create or Get a Chat Room ID
  // We create a unique ID based on the Item + The Two Users
  String getChatRoomId(String itemId, String userA, String userB) {
    // We sort the user IDs so the Chat Room ID is always the same 
    // regardless of who started the chat (A talking to B = B talking to A)
    List<String> users = [userA, userB];
    users.sort(); 
    return "${itemId}_${users[0]}_${users[1]}";
  }

  // B. Send Message (UPDATED to save Names and Item Info)
  Future<void> sendMessage(
    String chatRoomId, 
    String messageText, 
    String receiverId,
    String receiverName, // NEW
    String itemName      // NEW
  ) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    final String myName = user.displayName ?? user.email!.split('@')[0];

    final message = MessageModel(
      senderId: user.uid,
      senderName: myName,
      text: messageText,
      timestamp: DateTime.now(),
    );

    // 1. Add message to subcollection
    await _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .add(message.toMap());
        
    // 2. Update Chat Summary with NAMES and ITEM INFO
    await _db.collection('chats').doc(chatRoomId).set({
      'lastMessage': messageText,
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': [user.uid, receiverId],
      'itemName': itemName, // Store the Item Name
      'names': {            // Store both names map for easy lookup
        user.uid: myName,
        receiverId: receiverName,
      }
    }, SetOptions(merge: true));
  }


  // C. Stream Messages (Real-time!)
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true) // Newest at bottom (List view is reversed)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data());
      }).toList();
    });
  }

  // D. Get User's Inbox (NEW)
  Stream<QuerySnapshot> getUserChats() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .orderBy('lastUpdated', descending: true)
        .snapshots();
  }

  // ==========================================================
  // 5. PROFILE / MAINTENANCE FUNCTIONS
  // ==========================================================

  // A. Delete an Item
  Future<void> deleteItem(String itemId) async {
    // 1. Delete from Firestore
    await _db.collection('items').doc(itemId).delete();
    
    // Note: We leave the image in Supabase for now to keep it safe/simple.
    // In a production app, you would delete the file from Supabase here too.
  }

  // B. Get ONLY My Items (For Profile)
  Stream<List<ItemModel>> getUserItems() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('items')
        .where('reporterId', isEqualTo: user.uid) // Only my items
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // C. Finish/Complete an Item (Handover)
  Future<void> finishItem(String itemId, File proofImage) async {
    try {
      // 1. Upload Proof Image (Reuse the existing bucket 'images')
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'proofs/$fileName'; // Store in a subfolder 'proofs'

      await _supabase.storage.from('images').upload(
            path,
            proofImage,
            fileOptions: const sf.FileOptions(contentType: 'image/jpeg'),
          );

      final proofUrl = _supabase.storage.from('images').getPublicUrl(path);

      // 2. Update Firestore Document
      // We don't delete it; we just change status to 'COMPLETED'
      // This hides it from the Home Screen but keeps it for "Riwayat" (History)
      await _db.collection('items').doc(itemId).update({
        'status': 'COMPLETED',
        'proofImageUrl': proofUrl,
        'completedAt': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print("Error finishing item: $e");
      throw e; // Rethrow to handle in UI
    }
  }

  // ==========================================================
  // 6. USER PROFILE FUNCTIONS (Upgraded)
  // ==========================================================

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String username,
    required String faculty,
    File? imageFile, // NEW: Optional image file
  }) async {
    try {
      String? profilePicUrl;

      // 1. If user picked a new image, upload it to Supabase
      if (imageFile != null) {
        final fileName = 'profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'profiles/$fileName'; // Save in 'profiles' folder

        await _supabase.storage.from('images').upload(
              path,
              imageFile,
              fileOptions: const sf.FileOptions(contentType: 'image/jpeg'),
            );

        profilePicUrl = _supabase.storage.from('images').getPublicUrl(path);
      }

      // 2. Update Firebase Auth (Display Name & Photo URL)
      if (profilePicUrl != null) {
        await _auth.currentUser?.updatePhotoURL(profilePicUrl);
      }
      await _auth.currentUser?.updateDisplayName(fullName);

      // 3. Update Firestore 'users' Document
      final Map<String, dynamic> data = {
        'firstName': fullName,
        'username': username,
        'faculty': faculty,
        'email': _auth.currentUser?.email,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      // Only add profilePicUrl to Firestore if we actually changed it
      if (profilePicUrl != null) {
        data['profilePicUrl'] = profilePicUrl;
      }

      await _db.collection('users').doc(uid).set(data, SetOptions(merge: true));
      
    } catch (e) {
      print("Error updating profile: $e");
      throw e;
    }
  }
}
