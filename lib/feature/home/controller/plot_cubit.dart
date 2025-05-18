import 'dart:developer';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:zera3a/feature/home/controller/plot_states.dart';
import '../data/plot_model.dart';

class PlotCubit extends Cubit<PlotStates> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  PlotCubit(
      {required FirebaseAuth firebaseAuth,
      required FirebaseFirestore firestore})
      : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        super(PlotInitial());

  Future<void> fetchPlots() async {
    emit(PlotLoading());

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(PlotError('يرجى تسجيل الدخول أولاً'));
        return;
      }

      final querySnapshot = await _firestore
          .collection('plots')
          .orderBy(
            'createdAt',
            descending: true,
          )
          .get();

      final plots =
          querySnapshot.docs.map((doc) => Plot.fromFirestore(doc)).toList();
      emit(PlotLoaded(plots));
    } catch (e) {
      emit(PlotError('فشل في جلب الحوش'));
      log("$e");
    }
  }

  // Add a new plot
  Future<void> addPlot(
      {required String name,
      required String number,
      required String cropType}) async {
    emit(PlotLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(PlotError('يرجى تسجيل الدخول أولاً'));
        return;
      }

      final plot = Plot(
        plotId: '',
        // Will be set by Firestore
        name: name,
        number: number,
        cropType: cropType,
        ownerId: user.uid,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('plots').add(plot.toFirestore());
      await fetchPlots(); // Refresh the list
    } catch (e) {
      emit(PlotError('فشل في إضافة الحوشة'));
    }
  }

  // Delete a plot
  Future<void> deletePlot(String plotId) async {
    emit(PlotLoading());
    try {
      await _firestore.collection('plots').doc(plotId).delete();
      await fetchPlots(); // Refresh the list
    } catch (e) {
      emit(PlotError('فشل في حذف الحوشة'));
    }
  }

  // Edit a plot
  Future<void> editPlot(String plotId,
      {required String name,
      required String number,
      required String cropType}) async {
    emit(PlotLoading());
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(PlotError('يرجى تسجيل الدخول أولاً'));
        return;
      }

      final updatedPlot = Plot(
        plotId: plotId,
        name: name,
        number: number,
        cropType: cropType,
        ownerId: user.uid,
        createdAt: DateTime.now(), // Or fetch the original createdAt
      );

      await _firestore
          .collection('plots')
          .doc(plotId)
          .update(updatedPlot.toFirestore());
      await fetchPlots(); // Refresh the list
    } catch (e) {
      emit(PlotError('فشل في تعديل الحوشة'));
    }
  }
}
