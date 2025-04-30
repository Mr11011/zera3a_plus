import 'package:cloud_firestore/cloud_firestore.dart';

class Plot {
  final String plotId;
  final String name;
  final String number;
  final String cropType;
  final String ownerId;
  final DateTime createdAt;

  Plot({
    required this.plotId,
    required this.name,
    required this.number,
    required this.cropType,
    required this.ownerId,
    required this.createdAt,
  });

  // Convert Firestore document to Plot object
  factory Plot.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Plot(
      plotId: doc.id,
      name: data['name'] ?? '',
      number: data['number'] ?? '',
      cropType: data['cropType'] ?? '',
      ownerId: data['ownerId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  // Convert Plot object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'number': number,
      'cropType': cropType,
      'ownerId': ownerId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}