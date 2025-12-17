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
  String getChatRoomId(String itemId, String userA, String userB) {
    List<String> users = [userA, userB];
    users.sort(); 
    return "${itemId}_${users[0]}_${users[1]}";
  }

  // B. Send Message
  Future<void> sendMessage(
    String chatRoomId, 
    String messageText, 
    String receiverId,
    String receiverName,
    String itemName
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
        
    // 2. Update Chat Summary
    await _db.collection('chats').doc(chatRoomId).set({
      'lastMessage': messageText,
      'lastUpdated': FieldValue.serverTimestamp(),
      'participants': [user.uid, receiverId],
      'itemName': itemName,
      'names': {
        user.uid: myName,
        receiverId: receiverName,
      }
    }, SetOptions(merge: true));
  }


  // C. Stream Messages
  Stream<List<MessageModel>> getMessages(String chatRoomId) {
    return _db
        .collection('chats')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MessageModel.fromMap(doc.data());
      }).toList();
    });
  }

  // D. Get User's Inbox
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
    await _db.collection('items').doc(itemId).delete();
  }

  // B. Get ONLY My Items (For Profile)
  Stream<List<ItemModel>> getUserItems() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('items')
        .where('reporterId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return ItemModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // C. NEW: Get User ID by Username (Used for Finish Report)
  Future<String?> getUserIdByUsername(String username) async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      print("Error finding user: $e");
      return null;
    }
  }

  // D. Finish/Complete an Item (UPDATED: Now accepts completedByUid)
  Future<void> finishItem({
    required String itemId, 
    required File proofImage,
    required String completedByUid, // <--- NEW PARAMETER
  }) async {
    try {
      // 1. Upload Proof Image
      final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'proofs/$fileName';

      await _supabase.storage
          .from('images')
          .upload(
            path,
            proofImage,
            fileOptions: const sf.FileOptions(contentType: 'image/jpeg'),
          );

      final proofUrl = _supabase.storage.from('images').getPublicUrl(path);

      // 2. Update Firestore Document
      await _db.collection('items').doc(itemId).update({
        'status': 'COMPLETED',
        'proofImageUrl': proofUrl,
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': completedByUid, // <--- SAVED HERE
      });
      
    } catch (e) {
      print("Error finishing item: $e");
      throw e;
    }
  }

  // ==========================================================
  // 6. USER PROFILE FUNCTIONS
  // ==========================================================

  Future<void> updateUserProfile({
    required String uid,
    required String fullName,
    required String username,
    required String faculty,
    required String studyProgram,
    File? imageFile,
  }) async {
    try {
      String? profilePicUrl;

      // 1. If user picked a new image, upload it to Supabase
      if (imageFile != null) {
        final fileName = 'profile_${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final path = 'profiles/$fileName';

        await _supabase.storage
            .from('images')
            .upload(
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
        'studyProgram' : studyProgram,
        'email': _auth.currentUser?.email,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

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