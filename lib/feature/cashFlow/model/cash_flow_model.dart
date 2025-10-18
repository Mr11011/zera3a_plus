import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense }

class TransactionModel {
  final String id;
  final String description;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final String category;

  TransactionModel({
    required this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
    required this.category,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      type: (data['type'] == 'income') ? TransactionType.income : TransactionType.expense,
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] ?? 'غير مصنف',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'type': type == TransactionType.income ? 'income' : 'expense',
      'date': Timestamp.fromDate(date),
      'category': category,
    };
  }
}
