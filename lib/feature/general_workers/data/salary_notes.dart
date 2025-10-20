import 'package:cloud_firestore/cloud_firestore.dart';

class SalaryNote {
  final String id;
  final String noteText;
  final DateTime date;
  final bool isAdvance; // To track if the note is about an advance payment

  SalaryNote({
    required this.id,
    required this.noteText,
    required this.date,
    this.isAdvance = false,
  });

  factory SalaryNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalaryNote(
      id: doc.id,
      noteText: data['noteText'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      isAdvance: data['isAdvance'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'noteText': noteText,
      'date': Timestamp.fromDate(date),
      'isAdvance': isAdvance,
    };
  }
}