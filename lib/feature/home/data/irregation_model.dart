import 'package:cloud_firestore/cloud_firestore.dart';

class Irrigation {
  final String irrigationId;
  final DateTime date;
  final double hours;
  final double costPerHour;
  final double totalCost;
  final String recordedBy;

  Irrigation({
    required this.irrigationId,
    required this.date,
    required this.hours,
    required this.costPerHour,
    required this.totalCost,
    required this.recordedBy,
  });

  // Convert Firestore document to Irrigation object
  factory Irrigation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Irrigation(
      irrigationId: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      hours: (data['hours'] as num).toDouble(),
      costPerHour: (data['costPerHour'] as num).toDouble(),
      totalCost: (data['totalCost'] as num).toDouble(),
      recordedBy: data['recordedBy'] ?? '',
    );
  }

  // Convert Irrigation object to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'date': Timestamp.fromDate(date),
      'hours': hours,
      'costPerHour': costPerHour,
      'totalCost': totalCost,
      'recordedBy': recordedBy,
    };
  }
}