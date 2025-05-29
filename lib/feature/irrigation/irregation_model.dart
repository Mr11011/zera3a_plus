import 'package:cloud_firestore/cloud_firestore.dart';
class Irrigation {
  final String plotId;
  final DateTime date;
  final int days;
  final double hours;
  final int unitCost;
  final double totalCost;
  final String? docId; // Optional for existing records

  Irrigation({
    required this.plotId,
    required this.date,
    required this.days,
    required this.hours,
    required this.unitCost,
    required this.totalCost,
    this.docId,
  });

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'plotId': plotId,
      'date': date.toUtc(),
      'days': days,
      'hours': hours,
      'unitCost': unitCost,
      'totalCost': totalCost,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // Create from Firestore data
  factory Irrigation.fromJson(Map<String, dynamic> json, String docId) {
    return Irrigation(
      plotId: json['plotId'] as String,
      date: (json['date'] as Timestamp).toDate(),
      days: json['days'] as int,
      hours: json['hours'] as double,
      unitCost: json['unitCost'] as int,
      totalCost: json['totalCost'] as double,
      docId: docId,
    );
  }
}