import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/cash_flow_model.dart';
import 'cash_flow_states.dart';

class CashFlowCubit extends Cubit<CashFlowState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  CashFlowCubit({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(CashFlowInitial());

  /// Fetches all transactions and calculates the financial summary.
  Future<void> fetchTransactions() async {
    emit(CashFlowLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final snapshot = await _firestore
          .collection('transactions')
          // .where('ownerId', isEqualTo: user.uid)
          .orderBy('date', descending: true)
          .get();

      final transactions = snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .toList();

      // --- This is the "simpler backend approach" ---
      // All calculations are done here in the app, not in the database.
      double totalIncome = 0;
      double totalExpenses = 0;
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.income) {
          totalIncome += transaction.amount;
        } else {
          // Amount is negative for expenses
          totalExpenses += transaction.amount;
        }
      }
      final netBalance = totalIncome + totalExpenses;

      emit(CashFlowLoaded(
        transactions: transactions,
        totalIncome: totalIncome,
        totalExpenses: totalExpenses.abs(), // Show expenses as a positive number in UI
        netBalance: netBalance,
      ));
    } catch (e) {
      emit(CashFlowError("فشل في تحميل السجل المالي"));
    }
  }

  /// Adds a new income or expense transaction.
  Future<void> addTransaction({
    required String description,
    required double amount,
    required TransactionType type,
    required DateTime date,
    required String category,
  }) async {
    emit(CashFlowLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Ensure expenses are stored as negative numbers
      final double finalAmount = type == TransactionType.expense ? -amount.abs() : amount.abs();

      final newTransaction = {
        'description': description,
        'amount': finalAmount,
        'type': type == TransactionType.income ? 'income' : 'expense',
        'date': Timestamp.fromDate(date),
        'category': category,
        // 'ownerId': user.uid,
      };

      await _firestore.collection('transactions').add(newTransaction);
      emit(CashFlowSuccess());
      await fetchTransactions(); // Refresh the list
    } catch (e) {
      emit(CashFlowError("فشل في إضافة المعاملة"));
    }
  }

  /// Updates an existing transaction.
  Future<void> updateTransaction({
    required String transactionId,
    required Map<String, dynamic> updatedData,
  }) async {
    emit(CashFlowLoading());
    try {
      // --- FIX: Correctly handle the incoming string 'type' ---
      if (updatedData.containsKey('type') && updatedData.containsKey('amount')) {
        final typeString = updatedData['type'] as String;
        final amount = (updatedData['amount'] as num).abs();
        // Recalculate the amount's sign based on the string.
        updatedData['amount'] = typeString == 'expense' ? -amount : amount;
      }

      await _firestore.collection('transactions').doc(transactionId).update(updatedData);
      emit(CashFlowSuccess());
    } catch (e) {
      emit(CashFlowError("فشل في تعديل المعاملة"));
    }
  }

  /// Deletes a transaction.
  Future<void> deleteTransaction({required String transactionId}) async {
    emit(CashFlowLoading());
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
      emit(CashFlowSuccess());
      await fetchTransactions();
    } catch (e) {
      emit(CashFlowError("فشل في حذف المعاملة"));
    }
  }
}
