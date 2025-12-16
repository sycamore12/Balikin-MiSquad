import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Ensure this is imported
import '../../models/item_model.dart';
import '../../theme/colors.dart';
import 'package:intl/intl.dart';
import '../chat/chat_screen.dart';

class ItemDetailScreen extends StatelessWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isLost = item.type == 'LOST';
    final colorTheme = isLost ? Colors.red : Colors.green;
    
    // 1. Check if the current user is the owner
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser != null && currentUser.uid == item.reporterId;

    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Header ---
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: item.imageUrl.isNotEmpty
                  ? Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => 
                          Icon(isLost ? Icons.search : Icons.inventory_2, size: 80, color: Colors.grey),
                    )
                  : Icon(isLost ? Icons.search : Icons.inventory_2, size: 80, color: Colors.grey),
            ),

            // --- Content ---
            Transform.translate(
              offset: const Offset(0, -30),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.milkWhite,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: colorTheme.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isLost ? "BARANG HILANG" : "BARANG KETEMU",
                        style: TextStyle(color: colorTheme, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.itemName,
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM').format(item.date),
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(Icons.location_on, color: colorTheme, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          item.location,
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const Divider(height: 40),

                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          child: Text(item.reporterName.isNotEmpty ? item.reporterName[0].toUpperCase() : "?"),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Diposting oleh", style: TextStyle(fontSize: 12, color: Colors.grey)),
                            Text(item.reporterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text("Catatan Tambahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    Text(
                      item.note.isEmpty ? "Tidak ada catatan tambahan." : item.note,
                      style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                    ),
                    
                    const SizedBox(height: 30),

                    // --- NEW: PROOF SECTION (Only if Completed) ---
                    if (item.status == 'COMPLETED' && item.proofImageUrl.isNotEmpty) ...[
                      const Divider(height: 40, thickness: 1),
                      Row(
                        children: const [
                          Icon(Icons.handshake, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            "Bukti Serah Terima",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey.shade200,
                          child: Image.network(
                            item.proofImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          "Laporan ini telah diselesaikan.",
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],

                    const SizedBox(height: 100), 
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      
      // --- UPDATED BOTTOM SHEET ---
      bottomSheet: Container(
        color: AppColors.milkWhite,
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 55,
          child: isOwner 
            // 2. IF OWNER: Show Grey "Your Post" Button
            ? ElevatedButton.icon(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Ini adalah postingan Anda sendiri.")),
                  );
                },
                icon: const Icon(Icons.person),
                label: const Text("Postingan Anda"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade400, // Grey color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
              )
            // 3. IF NOT OWNER: Show Orange "Contact" Button
            : ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        itemId: item.id,
                        itemName: item.itemName,
                        receiverId: item.reporterId,
                        receiverName: item.reporterName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: Text("Hubungi ${item.reporterName}"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pumpkinOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
        ),
      ),
    );
  }
}