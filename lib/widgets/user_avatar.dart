import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/colors.dart';

class UserAvatar extends StatelessWidget {
  final String userId;
  final String userName; // Fallback if no photo
  final double radius;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.userName,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? profilePicUrl;
        
        // Try to get photoURL from the user's document
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          profilePicUrl = data?['profilePicUrl'];
        }

        // 1. Show Photo if available
        if (profilePicUrl != null && profilePicUrl.isNotEmpty) {
          return CircleAvatar(
            radius: radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: NetworkImage(profilePicUrl),
          );
        }

        // 2. Fallback: Show First Letter
        return CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.pumpkinOrange.withOpacity(0.2),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : "?",
            style: TextStyle(
              color: AppColors.pumpkinOrange, 
              fontWeight: FontWeight.bold,
              fontSize: radius, // Scale text size with radius
            ),
          ),
        );
      },
    );
  }
}