import 'dart:io'; // Import IO
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Import Image Picker
import '../../services/database_service.dart';
import '../../theme/colors.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _facultyController = TextEditingController();
  
  // Image Logic
  File? _selectedImage; // To store the locally picked image
  
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;
    _nameController.text = user!.displayName ?? '';

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['firstName'] ?? user!.displayName ?? '';
          _usernameController.text = data['username'] ?? '';
          _facultyController.text = data['faculty'] ?? '';
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
    }
  }

  // 1. Pick Image Function
  Future<void> _pickImage() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  // 2. Save Function (Updated)
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _dbService.updateUserProfile(
          uid: user!.uid,
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          faculty: _facultyController.text.trim(),
          imageFile: _selectedImage, // Pass the new image
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context); 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profil berhasil diperbarui!"), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: $e"), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Logic to decide which image provider to show
    ImageProvider? imageProvider;
    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!); // New local image
    } else if (user?.photoURL != null) {
      imageProvider = NetworkImage(user!.photoURL!); // Existing cloud image
    }

    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Edit Profil"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- PROFILE PICTURE SECTION ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey.shade300,
                            backgroundImage: imageProvider,
                            child: imageProvider == null 
                                ? const Icon(Icons.person, size: 60, color: Colors.white)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: AppColors.pumpkinOrange,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _pickImage, 
                      child: const Text("Ubah Foto", style: TextStyle(color: AppColors.pumpkinOrange))
                    ),
                    const SizedBox(height: 20),

                    // Fields
                    _buildTextField("Nama Lengkap", _nameController, Icons.person),
                    const SizedBox(height: 16),
                    _buildTextField("Username", _usernameController, Icons.alternate_email),
                    const SizedBox(height: 16),
                    _buildTextField("Fakultas / Jurusan", _facultyController, Icons.school),
                    
                    const SizedBox(height: 40),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pumpkinOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text("Simpan Perubahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (val) => val!.isEmpty ? "$label tidak boleh kosong" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}