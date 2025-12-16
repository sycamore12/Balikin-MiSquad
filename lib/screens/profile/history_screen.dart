import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/item_model.dart';
import '../../theme/colors.dart';
import 'package:intl/intl.dart';
import '../home/item_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final DatabaseService dbService = DatabaseService();

    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        title: const Text("Riwayat Laporan"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<List<ItemModel>>(
        // Reuse the existing user stream
        stream: dbService.getUserItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return _buildEmptyState();
          }

          // FILTER: Only show COMPLETED items
          final allItems = snapshot.data!;
          final historyItems = allItems.where((item) => item.status == 'COMPLETED').toList();

          if (historyItems.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historyItems.length,
            itemBuilder: (context, index) {
              return _buildHistoryCard(context, historyItems[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, ItemModel item) { // Added context param
    final bool isLost = item.type == 'LOST';

    return GestureDetector( // WRAP WITH GESTURE DETECTOR
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
        );
      },
      child: Card(
        // ... (Keep your existing Card code exactly the same) ...
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        color: Colors.white.withOpacity(0.9),
        child: Padding(
           // ... existing padding content ...
           padding: const EdgeInsets.all(12.0),
           child: Row(
             children: [
               // ... existing thumbnail ...
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
                
                // ... existing text info ...
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text(
                        item.itemName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                      // ... rest of your text widgets ...
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
             ]
           ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("Belum ada riwayat laporan", style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}