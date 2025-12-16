import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';
import 'signup_screen.dart'; // We'll create this in a moment

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  void _login() async {
    if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
      // Logic call
      var user = await _auth.signInWithEmail(
        _emailController.text.trim(), 
        _passwordController.text.trim()
      );
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login Failed. Check credentials.")),
        );
      }
      // If user is not null, the Wrapper will automatically switch to Home!
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Balikin",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                color: AppColors.pumpkinOrange
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pumpkinOrange,
                foregroundColor: Colors.white,
              ),
              child: const Text("Log In"),
            ),
            TextButton(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
              },
              child: const Text("Don't have an account? Sign Up Here"),
            )
          ],
        ),
      ),
    );
  }
}