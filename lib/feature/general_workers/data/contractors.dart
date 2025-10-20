import 'package:cloud_firestore/cloud_firestore.dart';

class Contractor {
  final String id;
  final String contractorName;
  final String contactPerson;
  final String phoneNumber;
  final double pricePerDay; // The contractor's price per worker

  Contractor({
    required this.id,
    required this.contractorName,
    required this.contactPerson,
    required this.phoneNumber,
    required this.pricePerDay,
  });

  factory Contractor.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Contractor(
      id: doc.id,
      contractorName: data['contractorName'] ?? '',
      contactPerson: data['contactPerson'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
    'contractorName': contractorName,
    'contactPerson': contactPerson,
    'phoneNumber': phoneNumber,
    'pricePerDay': pricePerDay,
    // ownerId will be added in the cubit
    };
  }
}