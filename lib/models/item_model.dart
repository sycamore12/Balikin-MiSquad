import 'package:cloud_firestore/cloud_firestore.dart';

class ItemModel {
  final String id;
  final String reporterId;
  final String reporterName;
  final String type; // 'LOST' or 'FOUND'
  final String itemName;
  final String imageUrl;
  final String location;
  final String note;
  final DateTime date;
  final String status; // 'OPEN' or 'COMPLETED'
  // NEW FIELD
  final String proofImageUrl; 

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
    // NEW
    this.proofImageUrl = '', 
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
      date: (data['date'] is Timestamp) 
          ? (data['date'] as Timestamp).toDate() 
          : DateTime.tryParse(data['date'].toString()) ?? DateTime.now(),
      status: data['status'] ?? 'OPEN',
      // NEW: Read proof image
      proofImageUrl: data['proofImageUrl'] ?? '', 
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
      'date': date,
      'status': status,
      'proofImageUrl': proofImageUrl, // NEW
    };
  }
}