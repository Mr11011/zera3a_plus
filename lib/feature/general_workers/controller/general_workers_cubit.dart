import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/contractors.dart';
import '../data/fixed_workers.dart';
import '../data/salary_notes.dart';
import 'general_workers_state.dart';

class GeneralWorkersCubit extends Cubit<GeneralWorkersState> {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  GeneralWorkersCubit({
    required FirebaseFirestore firestore,
    required FirebaseAuth firebaseAuth,
  })  : _firestore = firestore,
        _firebaseAuth = firebaseAuth,
        super(WorkersInitial());

  String? get _userId => _firebaseAuth.currentUser?.uid;

  /// Fetches both lists at the same time to populate the main screen.
  Future<void> fetchWorkers() async {
    emit(WorkersLoading());
    try {
      if (_userId == null) throw Exception("User not logged in");

      // Fetch both lists in parallel
      final fixedSnapshotFuture = _firestore
          .collection('fixed_workers')
          .where('ownerId', isEqualTo: _userId)
          .orderBy('name')
          .get();

      final contractorSnapshotFuture = _firestore
          .collection('contractors')
          .where('ownerId', isEqualTo: _userId)
          .orderBy('contractorName')
          .get();

      final fixedSnapshot = await fixedSnapshotFuture;
      final contractorSnapshot = await contractorSnapshotFuture;

      final fixedWorkers = fixedSnapshot.docs
          .map((doc) => FixedWorker.fromFirestore(doc))
          .toList();
      final contractors = contractorSnapshot.docs
          .map((doc) => Contractor.fromFirestore(doc))
          .toList();

      emit(WorkersLoaded(
        fixedWorkers: fixedWorkers,
        contractors: contractors,
      ));
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  // --- Fixed Worker CRUD ---
  Future<void> addFixedWorker(Map<String, dynamic> data) async {
    emit(WorkersLoading());
    try {
      if (_userId == null) throw Exception("User not logged in");
      data['ownerId'] = _userId; // Add ownerId
      await _firestore.collection('fixed_workers').add(data);
      emit(WorkersSuccess("تم إضافة العامل بنجاح"));
      await fetchWorkers();
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  Future<void> updateFixedWorker(
      String workerId, Map<String, dynamic> data) async {
    emit(WorkersLoading());
    try {
      await _firestore.collection('fixed_workers').doc(workerId).update(data);
      emit(WorkersSuccess("تم تعديل العامل بنجاح"));
      await fetchWorkers();
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  Future<void> deleteFixedWorker(String workerId) async {
    emit(WorkersLoading());
    try {
      // We must also delete the notes subcollection (Batched Write)
      final batch = _firestore.batch();
      final workerRef = _firestore.collection('fixed_workers').doc(workerId);
      final notesSnapshot = await workerRef.collection('salary_notes').get();

      for (final doc in notesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(workerRef);

      await batch.commit();
      emit(GeneralWorkersItemDeleted());
      await fetchWorkers();
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  // --- Contractor CRUD ---
  Future<void> addContractor(Map<String, dynamic> data) async {
    emit(WorkersLoading());
    try {
      if (_userId == null) throw Exception("User not logged in");
      data['ownerId'] = _userId;
      await _firestore.collection('contractors').add(data);
      emit(WorkersSuccess("تم إضافة المقاول بنجاح"));
      await fetchWorkers();
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  Future<void> updateContractor(
      String contractorId, Map<String, dynamic> data) async {
    emit(WorkersLoading());
    try {
      await _firestore.collection('contractors').doc(contractorId).update(data);
      emit(WorkersSuccess("تم تعديل المقاول بنجاح"));
      await fetchWorkers();
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  Future<void> deleteContractor(String contractorId) async {
    emit(WorkersLoading());
    try {
      await _firestore.collection('contractors').doc(contractorId).delete();
      emit(GeneralWorkersItemDeleted());
      await fetchWorkers();
    } catch (e) {
      emit(WorkersError(e.toString()));
    }
  }

  // --- Salary Notes CRUD ---
  Future<void> fetchSalaryNotes(String workerId) async {
    try {
      final snapshot = await _firestore
          .collection('fixed_workers')
          .doc(workerId)
          .collection('salary_notes')
          .orderBy('date', descending: true)
          .get();
      final notes =
          snapshot.docs.map((doc) => SalaryNote.fromFirestore(doc)).toList();
      emit(NotesLoaded(notes));
    } catch (e) {
      emit(WorkersError("فشل في تحميل الملاحظات"));
    }
  }

  Future<void> addSalaryNote({
    required String workerId,
    required String noteText,
    bool isAdvance = false,
  }) async {
    try {
      final noteData = {
        'noteText': noteText,
        'date': Timestamp.now(),
        'isAdvance': isAdvance,
      };
      await _firestore
          .collection('fixed_workers')
          .doc(workerId)
          .collection('salary_notes')
          .add(noteData);
      emit(WorkersSuccess("تم إضافة الملاحظة"));
      await fetchSalaryNotes(workerId); // Refresh only the notes
    } catch (e) {
      emit(WorkersError("فشل في إضافة الملاحظة"));
    }
  }

  Future<void> deleteSalaryNote({
    required String workerId,
    required String noteId,
  }) async {
    try {
      await _firestore
          .collection('fixed_workers')
          .doc(workerId)
          .collection('salary_notes')
          .doc(noteId)
          .delete();
      emit(WorkersSuccess("تم حذف الملاحظة"));
      await fetchSalaryNotes(workerId); // Refresh only the notes
    } catch (e) {
      emit(WorkersError("فشل في حذف الملاحظة"));
    }
  }
}
