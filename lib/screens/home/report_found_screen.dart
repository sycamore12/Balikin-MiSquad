import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../theme/colors.dart';

class ReportFoundScreen extends StatefulWidget {
  const ReportFoundScreen({super.key});

  @override
  State<ReportFoundScreen> createState() => _ReportFoundScreenState();
}

class _ReportFoundScreenState extends State<ReportFoundScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _noteController = TextEditingController();
  
  File? _selectedImage;
  bool _isLoading = false;

  // 1. Image Picker Logic
  Future<void> _pickImage() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) return;
    setState(() {
      _selectedImage = File(returnedImage.path);
    });
  }

  // 2. Submit Logic
  void _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // CALL THE DATABASE SERVICE
        // Notice we set type: 'FOUND' here
        await DatabaseService().createItemReport(
          type: 'FOUND', 
          itemName: _nameController.text.trim(),
          location: _locationController.text.trim(),
          note: _noteController.text.trim(),
          imageFile: _selectedImage, 
        );

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context); // Go back to Home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Terima kasih! Laporan berhasil disimpan."),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print("Error submitting report: $e");
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
    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Lapor Barang Ketemu"),
        backgroundColor: AppColors.milkWhite,
        foregroundColor: Colors.green, // Green theme for "Found"
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Image Picker ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.green.shade300, size: 50),
                                  const SizedBox(height: 8),
                                  const Text("Upload Foto Barang", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- Form Fields ---
                    _buildLabel("Nama Barang Temuan*"),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration("Contoh: Kunci Motor Honda"),
                      validator: (val) => val!.isEmpty ? "Nama barang wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Ditemukan di Lokasi*"),
                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration("Contoh: Parkiran Gedung B"),
                      validator: (val) => val!.isEmpty ? "Lokasi wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Catatan / Cara Pengambilan"),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: _inputDecoration("Contoh: Saya titipkan di pos satpam depan."),
                    ),
                    const SizedBox(height: 30),

                    // --- Submit Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Green button for Found
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text(
                          "Publikasikan Temuan", 
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // --- Helper Widgets ---
  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.green, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
    );
  }
}