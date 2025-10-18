import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseBatch {
  final String id; // The document ID from Firestore
  final String vendor;
  final String origin;
  final DateTime purchaseDate;
  final double initialQuantity;
  final double currentQuantity;
  final double totalCost;
  final double costPerUnit;

  PurchaseBatch({
    required this.id,
    required this.vendor,
    required this.origin,
    required this.purchaseDate,
    required this.initialQuantity,
    required this.currentQuantity,
    required this.totalCost,
    required this.costPerUnit,
  });

  factory PurchaseBatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PurchaseBatch(
      id: doc.id,
      vendor: data['vendor'] ?? '',
      origin: data['origin'] ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      initialQuantity: (data['initialQuantity'] as num).toDouble(),
      currentQuantity: (data['currentQuantity'] as num).toDouble(),
      totalCost: (data['totalCost'] as num).toDouble(),
      costPerUnit: (data['costPerUnit'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'vendor': vendor,
      'origin': origin,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'initialQuantity': initialQuantity,
      'currentQuantity': currentQuantity,
      'totalCost': totalCost,
      'costPerUnit': costPerUnit,
    };
  }
}