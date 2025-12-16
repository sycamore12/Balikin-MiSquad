import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../theme/colors.dart';

class ReportLostScreen extends StatefulWidget {
  const ReportLostScreen({super.key});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
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
        // Call the database service
        await DatabaseService().createItemReport(
          type: 'LOST',
          itemName: _nameController.text.trim(),
          location: _locationController.text.trim(),
          note: _noteController.text.trim(),
          imageFile: _selectedImage, // Can be null for Lost items
        );

        // If successful:
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context); // Go back to Home
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Laporan Berhasil Dibuat!")),
          );
        }
      } catch (e) {
        // If error happens (e.g. Firebase 404):
        print("Error submitting report: $e");
        if (mounted) {
          setState(() => _isLoading = false); // Stop the spinner!
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal mengirim laporan: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lapor Barang Hilang"),
        backgroundColor: AppColors.milkWhite,
        foregroundColor: AppColors.pumpkinOrange,
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
                    // --- Image Picker Widget ---
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.camera_alt, color: Colors.grey, size: 40),
                                  SizedBox(height: 8),
                                  Text("Upload Foto (Opsional)", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- Form Fields ---
                    _buildLabel("Nama Barang*"),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration("Contoh: Dompet Coklat"),
                      validator: (val) => val!.isEmpty ? "Nama barang wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Lokasi Terakhir*"),
                    TextFormField(
                      controller: _locationController,
                      decoration: _inputDecoration("Contoh: Kantin Fasilkom"),
                      validator: (val) => val!.isEmpty ? "Lokasi wajib diisi" : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel("Catatan Tambahan"),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: _inputDecoration("Ciri-ciri khusus, isi dompet, dll."),
                    ),
                    const SizedBox(height: 30),

                    // --- Submit Button ---
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.pumpkinOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Kirim Laporan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }
}