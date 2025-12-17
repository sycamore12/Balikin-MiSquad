import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/database_service.dart';
import '../../models/item_model.dart';
import '../../theme/colors.dart';

// ==============================================================================
// 1. MAIN LIST SCREEN
// ==============================================================================
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
        stream: dbService.getUserItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return _buildEmptyState();
          }

          // FILTER: Only show items marked as 'COMPLETED'
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

  Widget _buildHistoryCard(BuildContext context, ItemModel item) {
    final bool isLost = item.type == 'LOST';

    return GestureDetector(
      onTap: () {
        // Navigate to the specialized History Detail Screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HistoryDetailScreen(item: item)),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        color: Colors.white,
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
               
               // Text Info
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                      Text(
                        item.itemName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough, // Crossed out style
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Display completed date or fallback to reported date
                        "Selesai: ${item.completedAt != null ? DateFormat('dd MMM yyyy').format(item.completedAt!) : '-'}", 
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
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

// ==============================================================================
// 2. DETAIL SCREEN (Implements FR-4.2 with Real Data Fetching)
// ==============================================================================

class HistoryDetailScreen extends StatefulWidget {
  final ItemModel item;

  const HistoryDetailScreen({super.key, required this.item});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _isLoading = true;
  
  // Data holders for the two parties
  Map<String, dynamic>? _reporterData;  // Pihak 1 (Pelapor)
  Map<String, dynamic>? _completerData; // Pihak 2 (Penyelesai)

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final db = FirebaseFirestore.instance;
    try {
      // 1. Fetch Pihak 1 (Reporter) using item.reporterId
      // Note: Use 'reporterId' from your updated Model, not 'uid'
      final reporterDoc = await db.collection('users').doc(widget.item.reporterId).get();
      
      // 2. Fetch Pihak 2 (Completer) using item.completedBy
      DocumentSnapshot? completerDoc;
      if (widget.item.completedBy != null && widget.item.completedBy!.isNotEmpty) {
        completerDoc = await db.collection('users').doc(widget.item.completedBy).get();
      }

      if (mounted) {
        setState(() {
          _reporterData = reporterDoc.data() as Map<String, dynamic>?;
          _completerData = completerDoc?.data() as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching history details: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Colors.white, body: Center(child: CircularProgressIndicator()));
    }

    // --- LOGIC PERBAIKAN NAMA (FIXED HERE) ---

    // 1. Pihak 1 (Pelapor)
    String p1Name = widget.item.reporterName;
    if (_reporterData != null) {
      String fName = _reporterData!['firstName'] ?? '';
      String lName = _reporterData!['lastName'] ?? '';
      String fullName = "$fName $lName".trim();
      
      if (fullName.isNotEmpty) {
        p1Name = fullName;
      } else {
        // Fallback to username if names are empty
        p1Name = _reporterData!['username'] ?? widget.item.reporterName;
      }
    }
    final String p1Faculty = _reporterData?['faculty'] ?? '-';
    final String p1Prodi = _reporterData?['studyProgram'] ?? '-';

    // 2. Pihak 2 (Penyelesai)
    String p2Name = 'Tidak Diketahui';
    if (_completerData != null) {
      String fName = _completerData!['firstName'] ?? '';
      String lName = _completerData!['lastName'] ?? '';
      String fullName = "$fName $lName".trim();

      if (fullName.isNotEmpty) {
        p2Name = fullName;
      } else {
        // Fallback to username
        p2Name = _completerData!['username'] ?? 'Tanpa Nama';
      }
    }
    final String p2Faculty = _completerData?['faculty'] ?? '-';
    final String p2Prodi = _completerData?['studyProgram'] ?? '-';

    // Dates
    final String reportDate = DateFormat('dd MMMM yyyy, HH:mm').format(widget.item.date);
    final String finishDate = widget.item.completedAt != null 
        ? DateFormat('dd MMMM yyyy, HH:mm').format(widget.item.completedAt!) 
        : '-';

    // Proof Image URL (Prioritize the new proof image field, fallback to item image)
    final String displayImage = widget.item.proofImageUrl.isNotEmpty 
        ? widget.item.proofImageUrl 
        : widget.item.imageUrl;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Berita Acara"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share), 
            onPressed: () {
              // Optional: Share receipt feature
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- STATUS HEADER ---
            const Icon(Icons.verified, color: Colors.green, size: 64),
            const SizedBox(height: 8),
            const Text(
              "LAPORAN SELESAI",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            Text(
              "ID: #${widget.item.id.substring(0, 8).toUpperCase()}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const Divider(height: 32),

            // --- FOTO BUKTI (Proof) ---
            Align(
              alignment: Alignment.centerLeft, 
              child: Text("Bukti Barang / Serah Terima", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]))
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: displayImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(displayImage, fit: BoxFit.cover),
                    )
                  : const Center(child: Text("Tidak ada foto tersedia", style: TextStyle(color: Colors.grey))),
            ),
            const SizedBox(height: 24),

            // --- PIHAK 1 & PIHAK 2 CARDS ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPartyCard("Pihak 1 (Pelapor)", p1Name, p1Faculty, p1Prodi)),
                const SizedBox(width: 12),
                Expanded(child: _buildPartyCard("Pihak 2 (Penyelesai)", p2Name, p2Faculty, p2Prodi)),
              ],
            ),
            const SizedBox(height: 24),

            // --- TIMELINE ---
            Align(
              alignment: Alignment.centerLeft, 
              child: Text("Timeline", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[800]))
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.milkWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTimelineRow("Tanggal Dilaporkan", reportDate, Icons.calendar_today_outlined),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                  _buildTimelineRow("Tanggal Diselesaikan", finishDate, Icons.check_circle_outline),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            Text(
              "Data ini tercatat secara permanen di sistem Balikin.",
              style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPartyCard(String title, String name, String faculty, String prodi) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 10, color: AppColors.pumpkinOrange, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(prodi, style: const TextStyle(fontSize: 11, color: Colors.black87)),
          Text(faculty, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String label, String date, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text(date, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ],
    );
  }
}