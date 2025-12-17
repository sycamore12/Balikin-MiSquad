import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';

class UserProfileViewScreen extends StatelessWidget {
  final String userId;
  final String userName; // Fallback

  const UserProfileViewScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Info Pengguna"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Pengguna tidak ditemukan"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String fullName = data['firstName'] ?? userName;
          final String username = data['username'] ?? '-';
          final String faculty = data['faculty'] ?? '-';
          final String studyProgram = data['studyProgram'] ?? '-';
          final String? profilePicUrl = data['profilePicUrl'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. BIG PROFILE PICTURE
                Center(
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: profilePicUrl != null ? NetworkImage(profilePicUrl) : null,
                    child: profilePicUrl == null 
                        ? Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : "?",
                            style: const TextStyle(fontSize: 50, color: Colors.grey),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // 2. INFO CARDS
                _buildInfoCard(Icons.person, "Nama Lengkap", fullName),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.alternate_email, "Username", "@$username"),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.school, "Fakultas", faculty),
                const SizedBox(height: 12),
                _buildInfoCard(Icons.school, "Jurusan", studyProgram),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.pumpkinOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.pumpkinOrange, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
