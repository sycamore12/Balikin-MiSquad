import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../theme/colors.dart';
import '../../widgets/user_avatar.dart'; // Make sure you created this file!
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Pesan Masuk"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: dbService.getUserChats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Belum ada pesan", style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          final chats = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: chats.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final chatData = chats[index].data() as Map<String, dynamic>;
              
              // 1. Basic Chat Info
              final String lastMessage = chatData['lastMessage'] ?? 'Gambar / Lampiran';
              final String itemName = chatData['itemName'] ?? 'Barang';
              
              // 2. Parse IDs to find "The Other Person"
              // Format: itemId_userA_userB
              final parts = chats[index].id.split('_');
              final String itemId = parts[0];
              final String otherUserId = (parts[1] == currentUserId) ? parts[2] : parts[1];

              // 3. Fetch REAL-TIME User Profile (for Faculty & Name)
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                builder: (context, userSnapshot) {
                  
                  // Default/Fallback values
                  String displayName = "User";
                  String faculty = "";

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                    displayName = userData['firstName'] ?? "User";
                    faculty = userData['faculty'] ?? "";
                  } else {
                    // If loading or failed, use the fallback name stored in the chat doc
                    Map<String, dynamic> names = chatData['names'] ?? {};
                    displayName = names[otherUserId] ?? 'User';
                  }

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    // A. AVATAR (Uses our smart widget)
                    leading: UserAvatar(
                      userId: otherUserId,
                      userName: displayName,
                      radius: 26,
                    ),
                    
                    // B. NAME & FACULTY
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName, 
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Show Faculty Badge if available
                        if (faculty.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.pumpkinOrange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              faculty,
                              style: const TextStyle(
                                fontSize: 10, 
                                color: AppColors.pumpkinOrange, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                      ],
                    ),

                    // C. SUBTITLE (Item Name + Message)
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "$itemName • $lastMessage", 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),

                    // D. ARROW
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    
                    // E. NAVIGATION
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            itemId: itemId, 
                            itemName: itemName,
                            receiverId: otherUserId,
                            receiverName: displayName,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}