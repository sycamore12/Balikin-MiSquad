import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String reporterId; // User's ID (formerly uid)
  final String reporterName;
  final String type; // 'LOST' or 'FOUND'
  final String itemName;
  final String imageUrl;
  final String location;
  final String note;
  final DateTime date;
  final String status; // 'OPEN' or 'COMPLETED'
  
  // --- NEW FIELDS ---
  final String proofImageUrl; 
  final String? completedBy; // UID of the person who finished it
  final DateTime? completedAt; // Time it was finished

  ItemModel({
    required this.id,
    required this.reporterId,
    required this.reporterName,
    required this.type,
    required this.itemName,
    required this.imageUrl,
    required this.location,
    required this.note,
    required this.date,
    required this.status,
    this.proofImageUrl = '', 
    // New Optional Params
    this.completedBy,
    this.completedAt,
  });

  factory ItemModel.fromMap(Map<String, dynamic> data, String docId) {
    return ItemModel(
      id: docId,
      reporterId: data['reporterId'] ?? '',
      reporterName: data['reporterName'] ?? 'Anonymous',
      type: data['type'] ?? 'LOST',
      itemName: data['itemName'] ?? 'Unknown',
      imageUrl: data['imageUrl'] ?? '',
      location: data['location'] ?? '',
      note: data['note'] ?? '',
      status: data['status'] ?? 'OPEN',
      proofImageUrl: data['proofImageUrl'] ?? '',
      
      // 1. Safe Date Conversion for Created Date
      date: (data['date'] is Timestamp) 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.tryParse(data['date'].toString()) ?? DateTime.now(),

      // 2. NEW: Safe Conversion for CompletedAt
      // We check if it exists first to avoid "null is not subtype of Timestamp" error
      completedBy: data['completedBy'],
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reporterId': reporterId,
      'reporterName': reporterName,
      'type': type,
      'itemName': itemName,
      'imageUrl': imageUrl,
      'location': location,
      'note': note,
      'status': status,
      'proofImageUrl': proofImageUrl,
      'completedBy': completedBy,
      
      // 3. Convert Dates back to Timestamp for Firestore
      'date': Timestamp.fromDate(date),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
}