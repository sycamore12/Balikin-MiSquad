import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth/login_screen.dart'; // We will build this next
import '../main_layout.dart'; // We will build this later (The detailed dashboard)

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to the stream of Auth Changes
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the snapshot has data, the user is logged in
        if (snapshot.hasData) {
          // TODO: Return your Homepage/MainLayout here
          return const MainLayout();
        } else {
          // Otherwise, return Login Screen
          return const LoginScreen();
        }
      },
    );
  }
}

// Temporary placeholder until we build the full navigation
class MainLayoutPlaceholder extends StatelessWidget {
  const MainLayoutPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Balikin Home")),
      body: Center(
        child: ElevatedButton(
          onPressed: () => FirebaseAuth.instance.signOut(),
          child: const Text("Log Out (Test)"),
        ),
      ),
    );
  }
}
