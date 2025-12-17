import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../services/user_gate_service.dart';
import '../../models/item_model.dart';
import '../../theme/colors.dart';
import 'report_lost_screen.dart';
import 'report_found_screen.dart';
import 'item_detail_screen.dart';
import '../chat/chat_list_screen.dart';
import '../profile/edit_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedFilterIndex = 0;
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  String get _currentFilter {
    if (_selectedFilterIndex == 1) return 'Barang Hilang';
    if (_selectedFilterIndex == 2) return 'Barang Ketemu';
    return 'Semua';
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- NEW HELPER: Show Dialog if Profile Incomplete ---
  void _showIncompleteProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lengkapi Profil"),
        content: const Text(
          "Sebelum membuat laporan, nama, fakultas, dan prodi Anda harus lengkap.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pumpkinOrange,
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to Edit Profile
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
            },
            child: const Text(
              "Lengkapi Sekarang",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.milkWhite,
      appBar: AppBar(
        backgroundColor: AppColors.milkWhite,
        elevation: 0,
        title: const Text(
          "Balikin",
          style: TextStyle(
            color: AppColors.pumpkinOrange,
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: AppColors.pumpkinOrange,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatListScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildSegmentedControl(),
        ),
      ),
      body: Column(
        children: [
          // SEARCH BAR & BUTTONS CONTAINER
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchText = val.toLowerCase();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Cari barang (contoh: Kunci)...",
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        "Hilang",
                        Icons.search_off,
                        Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        "Ketemu",
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- List of Items ---
          Expanded(
            child: StreamBuilder<List<ItemModel>>(
              stream: _dbService.getItems(_currentFilter),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Client-side filtering
                final allItems = snapshot.data!;
                final filteredItems = allItems.where((item) {
                  return item.itemName.toLowerCase().contains(_searchText) ||
                      item.location.toLowerCase().contains(_searchText);
                }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Text(
                      "Tidak ditemukan barang '$_searchText'",
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    return _buildItemCard(filteredItems[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // WIDGETS
  // ==========================================================

  Widget _buildSegmentedControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildFilterTab("Semua", 0),
          _buildFilterTab("Barang Hilang", 1),
          _buildFilterTab("Barang Ketemu", 2),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String text, int index) {
    final bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.pumpkinOrange : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade600,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED ACTION BUTTON LOGIC ---
  Widget _buildActionButton(String label, IconData icon, Color color) {
    return ElevatedButton(
      onPressed: () async {
        // 1. Show Loading Indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (c) => const Center(child: CircularProgressIndicator()),
        );

        // 2. Check Profile Completeness
        bool canProceed = await UserGateService().isProfileComplete();

        // 3. Remove Loading Indicator
        if (mounted) Navigator.pop(context);

        // 4. Handle Navigation based on result
        if (canProceed) {
          if (label == "Hilang") {
            if (mounted)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportLostScreen(),
                ),
              );
          } else if (label == "Ketemu") {
            if (mounted)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReportFoundScreen(),
                ),
              );
          }
        } else {
          // Profile incomplete -> Show warning
          if (mounted) _showIncompleteProfileDialog(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: Colors.black12,
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(ItemModel item) {
    final bool isLost = item.type == 'LOST';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ItemDetailScreen(item: item)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
        shadowColor: Colors.black12,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Image Thumbnail ---
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey.shade200,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              isLost ? Icons.search : Icons.inventory_2,
                              color: Colors.grey,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          },
                        )
                      : Icon(
                          isLost ? Icons.search : Icons.inventory_2,
                          color: Colors.grey,
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // --- Details Text ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isLost
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
                      item.itemName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      item.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${item.date.day}/${item.date.month} • ${item.reporterName}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
          Icon(Icons.inbox, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "Belum ada laporan",
            style: TextStyle(color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
