import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/colors.dart';
import 'my_posts_screen.dart';
import 'edit_profile_screen.dart';
import 'history_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // 1. HEADER (Photo & Name)
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null 
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    // Fetch extra details (like Faculty) from Firestore 'users' collection
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text("Loading...");
                        }
                        final userData = snapshot.data?.data() as Map<String, dynamic>?;
                        final String fullName = userData?['firstName'] ?? user?.displayName ?? "User";
                        final String username = userData?['username'] ?? user?.email ?? "";
                        final String faculty = userData?['faculty'] ?? "";
                        
                        return Column(
                          children: [
                            Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text("@$username • $faculty", style: const TextStyle(color: Colors.grey)),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () {
                        // NAVIGATE TO EDIT PROFILE
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const EditProfileScreen())
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Edit Profile"),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 2. MENU OPTIONS
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                     BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    _buildMenuItem(
                      context, 
                      icon: Icons.article_outlined, 
                      text: "Laporan Kamu", 
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPostsScreen()));
                      }
                    ),
                    const Divider(height: 1),
                    _buildMenuItem(context, icon: Icons.help_outline, text: "Bantuan", onTap: () {}),
                    const Divider(height: 1),
                    _buildMenuItem(
                      context, 
                      icon: Icons.history, 
                      text: "Riwayat", 
                      onTap: () {
                        // NAVIGATE TO HISTORY
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const HistoryScreen())
                        );
                      }
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 3. LOGOUT BUTTON
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _buildMenuItem(
                  context, 
                  icon: Icons.logout, 
                  text: "Keluar", 
                  textColor: Colors.red,
                  onTap: () async {
                     await FirebaseAuth.instance.signOut();
                     // Wrapper will automatically detect change and show Login Screen
                  }
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, {required IconData icon, required String text, required VoidCallback onTap, Color textColor = Colors.black87}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.milkWhite,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.pumpkinOrange, size: 20),
      ),
      title: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}