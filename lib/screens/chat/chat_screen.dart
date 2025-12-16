import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/database_service.dart';
import '../../models/message_model.dart';
import '../../theme/colors.dart';
import '../../widgets/user_avatar.dart';
import '../profile/user_profile_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final String itemId;
  final String itemName;
  final String receiverId; // The person you are talking to
  final String receiverName;

  const ChatScreen({
    super.key, 
    required this.itemId,
    required this.itemName,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  late String chatRoomId;

  @override
  void initState() {
    super.initState();
    // Generate the unique room ID
    chatRoomId = _dbService.getChatRoomId(widget.itemId, _currentUserId, widget.receiverId);
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    // UPDATED CALL: Pass receiverName and itemName
    _dbService.sendMessage(
      chatRoomId, 
      _messageController.text.trim(), 
      widget.receiverId,
      widget.receiverName, // Pass Name
      widget.itemName      // Pass Item Name
    );
    
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black,
        titleSpacing: 0,
        title: GestureDetector( // <--- WRAP WITH GESTURE DETECTOR
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileViewScreen(
                  userId: widget.receiverId,
                  userName: widget.receiverName,
                ),
              ),
            );
          },
          child: Row(
            children: [
              UserAvatar(
                userId: widget.receiverId,
                userName: widget.receiverName,
                radius: 18,
              ),
              const SizedBox(width: 10),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.receiverName, style: const TextStyle(fontSize: 16)),
                    Text(
                      "Item: ${widget.itemName}", 
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // --- MESSAGES LIST ---
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _dbService.getMessages(chatRoomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Text("Mulai obrolan dengan ${widget.receiverName}...", 
                      style: TextStyle(color: Colors.grey.shade400)),
                  );
                }

                return ListView.builder(
                  reverse: true, // Scroll from bottom
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == _currentUserId;
                    return _buildMessageBubble(msg, isMe);
                  },
                );
              },
            ),
          ),

          // --- INPUT AREA ---
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Tulis pesan...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.pumpkinOrange,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.pumpkinOrange : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(2),
            bottomRight: isMe ? const Radius.circular(2) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          msg.text,
          style: TextStyle(color: isMe ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}