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
  File? _proofImage;
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();

  Future<void> _pickImage() async {
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.camera); // Prefer Camera for proof
    if (returnedImage == null) return;
    setState(() {
      _proofImage = File(returnedImage.path);
    });
  }

  void _submitFinish() async {
    if (_proofImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Wajib sertakan foto bukti serah terima!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _dbService.finishItem(widget.item.id, _proofImage!);
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context); // Close Finish Screen
        Navigator.pop(context); // Close My Posts Screen (optional, or just refresh)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Laporan Selesai! Terima kasih telah membantu."),
            backgroundColor: Colors.green,
          ),
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
          children: [
            const Icon(Icons.handshake_outlined, size: 60, color: AppColors.pumpkinOrange),
            const SizedBox(height: 16),
            const Text(
              "Bukti Serah Terima",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Silakan unggah foto sebagai bukti bahwa barang '${widget.item.itemName}' telah dikembalikan atau ditemukan.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),

            // IMAGE PICKER
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _proofImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_proofImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined, size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text("Ambil Foto Bukti", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 40),

            // SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _submitFinish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text("Selesaikan Laporan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}