import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  
  final AuthService _auth = AuthService();

  void _signUp() async {
    // Basic validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    var user = await _auth.signUpWithEmail(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _usernameController.text.trim(),
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    );

    if (user != null) {
      // Pop the signup screen so we go back to wrapper -> Home
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Failed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sign Up")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
             TextField(controller: _firstNameController, decoration: const InputDecoration(labelText: "First Name")),
             const SizedBox(height: 12),
             TextField(controller: _lastNameController, decoration: const InputDecoration(labelText: "Last Name")),
             const SizedBox(height: 12),
             TextField(controller: _usernameController, decoration: const InputDecoration(labelText: "Username")),
             const SizedBox(height: 12),
             TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
             const SizedBox(height: 12),
             TextField(controller: _passwordController, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
             const SizedBox(height: 24),
             ElevatedButton(
              onPressed: _signUp,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pumpkinOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text("Create Account"),
            ),
          ],
        ),
      ),
    );
  }
}