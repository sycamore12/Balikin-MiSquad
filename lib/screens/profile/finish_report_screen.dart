import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/database_service.dart';
import '../../models/item_model.dart';
import '../../theme/colors.dart';

class FinishReportScreen extends StatefulWidget {
  final ItemModel item;

  const FinishReportScreen({super.key, required this.item});

  @override
  State<FinishReportScreen> createState() => _FinishReportScreenState();
}

class _FinishReportScreenState extends State<FinishReportScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  
  File? _proofImage;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final returnedImage = await ImagePicker().pickImage(source: source, imageQuality: 50);
    if (returnedImage == null) return;
    setState(() {
      _proofImage = File(returnedImage.path);
      _errorMessage = null; // Clear previous errors
    });
  }

  void _submitFinish() async {
    final username = _usernameController.text.trim();

    // 1. INPUT VALIDATION
    if (username.isEmpty) {
      setState(() => _errorMessage = "Wajib mengisi username Pihak 2 (Penerima/Penemu).");
      return;
    }
    if (_proofImage == null) {
      setState(() => _errorMessage = "Wajib sertakan foto bukti serah terima!");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 2. CHECK IF USERNAME EXISTS (The Logic we added to DatabaseService)
      final String? foundUid = await _dbService.getUserIdByUsername(username);

      if (foundUid == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Username '$username' tidak ditemukan. Pastikan ejaan benar.";
        });
        return;
      }

      // 3. PREVENT SELF-COMPLETION (Optional safety check)
      if (foundUid == widget.item.reporterId) {
         setState(() {
          _isLoading = false;
          _errorMessage = "Anda tidak bisa menyelesaikan laporan dengan akun sendiri.";
        });
        return;
      }

      // 4. SUBMIT TO DATABASE (Using the updated finishItem function)
      await _dbService.finishItem(
        itemId: widget.item.id, 
        proofImage: _proofImage!,
        completedByUid: foundUid, // <--- Passing the found ID
      );
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Show Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Laporan Selesai! Data tersimpan di Riwayat."),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back (Close Screen)
        // Adjust this based on your navigation stack. 
        // Usually need to pop twice if you came from MyPosts -> FinishScreen
        Navigator.pop(context); 
        Navigator.pop(context); 
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Selesaikan Laporan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER ---
            const Icon(Icons.handshake_outlined, size: 60, color: AppColors.pumpkinOrange),
            const SizedBox(height: 16),
            const Text(
              "Verifikasi Pihak Kedua",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Untuk keamanan data, masukkan username orang yang menerima/menemukan barang ini.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 30),

            // --- 1. USERNAME INPUT ---
            const Text("Username Pihak 2", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                hintText: "Contoh: budisantoso123",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),

            // --- 2. IMAGE PICKER ---
            const Text("Bukti Foto Serah Terima", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                // Show choice between Camera and Gallery
                showModalBottomSheet(context: context, builder: (context) {
                  return SafeArea(
                    child: Wrap(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.camera_alt),
                          title: const Text('Kamera'),
                          onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
                        ),
                        ListTile(
                          leading: const Icon(Icons.photo_library),
                          title: const Text('Galeri'),
                          onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
                        ),
                      ],
                    ),
                  );
                });
              },
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_proofImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text("Tap untuk ambil foto", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
              ),
            ),
            
            // --- ERROR DISPLAY ---
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade100),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 30),

            // --- SUBMIT BUTTON ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24, 
                        width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                      )
                    : const Text(
                        "Konfirmasi Selesai", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}