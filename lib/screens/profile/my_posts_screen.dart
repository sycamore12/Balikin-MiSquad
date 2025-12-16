import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/item_model.dart';
import '../../theme/colors.dart';
import 'package:intl/intl.dart';
import 'finish_report_screen.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Laporan Kamu"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: dbService.getUserItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 60, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text("Kamu belum membuat laporan", style: TextStyle(color: Colors.grey.shade400)),
                ],
              ),
            );
          }

          final allItems = snapshot.data!;
          
          // FILTER: Only show OPEN (Active) items
          final activeItems = allItems.where((item) => item.status == 'OPEN').toList();

          if (activeItems.isEmpty) {
             return Center(/* ... text: "Tidak ada laporan aktif" ... */);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: activeItems.length, // Use activeItems
            itemBuilder: (context, index) {
              final item = activeItems[index]; // Use activeItems
              return _buildMyItemCard(context, item, dbService);
            },
          );
        },
      ),
    );
  }

  Widget _buildMyItemCard(BuildContext context, ItemModel item, DatabaseService dbService) {
    final bool isLost = item.type == 'LOST';
    // Check if it's already completed (just in case)
    final bool isCompleted = item.status == 'COMPLETED'; 
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 70,
                height: 70,
                color: Colors.grey.shade200,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(item.imageUrl, fit: BoxFit.cover)
                    : Icon(isLost ? Icons.search : Icons.inventory_2, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.itemName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLost ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLost ? "HILANG" : "KETEMU",
                      style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold,
                        color: isLost ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d MMM yyyy').format(item.date),
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            // NEW: "Selesaikan" Button
            if (!isCompleted)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinishReportScreen(item: item),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.pumpkinOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text("Selesaikan", style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}