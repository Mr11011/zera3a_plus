import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_states.dart';

class AuthCubit extends Cubit<AuthStates> {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthCubit(
      {required FirebaseAuth firebaseAuth,
      required FirebaseFirestore firestore})
      : _firebaseAuth = firebaseAuth,
        _firestore = firestore,
        super(AuthInitState());

  Future<void> signUp(
    String email,
    String password,
    String fullName, {
    required String role,
    String? phone,
  }) async {
    emit(AuthLoadingState());
    User? user;
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;
      if (user == null) {
        emit(AuthError("فشل إنشاء الحساب، حاول مرة أخرى"));
        return;
      }
      await user.sendEmailVerification();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'email': email,
        'fullName': fullName,
        'role': role,
        'phone': phone,
        'status': role.toLowerCase() == 'owner' ? 'pending' : 'approved',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (role.toLowerCase() == 'owner') {
        emit(AuthPendingOwnerState(user));
      } else {
        emit(AuthEmailVerificationSent(user));
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        emit(AuthError("كلمة المرور ضعيفة جدًا، اختر كلمة أقوى"));
      } else if (e.code == 'invalid-email') {
        emit(AuthError("البريد الإلكتروني غير صحيح"));
      } else if (e.code == 'email-already-in-use') {
        emit(AuthError("البريد الإلكتروني مستخدم بالفعل"));
      } else {
        emit(AuthError("فشل التسجيل، تحقق من بياناتك وحاول مجددًا"));
      }
    } catch (e) {
      if (user != null) {
        await user.delete(); // Delete auth user if Firestore fails
      }
      String errorMessage = 'حدث خطأ غير متوقع، حاول مرة أخرى';
      if (e is FirebaseException && e.plugin == 'cloud_firestore') {
        errorMessage = 'فشل حفظ البيانات، تحقق من الاتصال بالإنترنت';
        emit(AuthError(errorMessage));
      } else {
        emit(AuthError('حدث خطأ غير متوقع، حاول مرة أخرى'));
      }
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(AuthLoadingState());
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);

      final user = userCredential.user;

      if (user == null) {
        emit(AuthError("لم يتم العثور على الحساب"));
        return;
      }

      // Reload to get the latest info.
      await user.reload();
      final updatedUser = _firebaseAuth.currentUser;
      if (updatedUser == null || !updatedUser.emailVerified) {
        await _firebaseAuth.signOut();
        // emit(AuthError("يرجى التحقق من بريدك الإلكتروني أولاً"));
        emit(AuthEmailVerificationFailed(email: email, password: password));
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        emit(AuthError("الحساب غير مسجل"));
        return;
      }

      if (userDoc['status'] != 'approved') {
        await _firebaseAuth.signOut();
        emit(AuthPendingState());
        return;
      }

      emit(AuthLoadedState(user: user));
    } on FirebaseAuthException catch (e) {
      String message = 'فشل تسجيل الدخول، حاول مرة أخرى';
      switch (e.code) {
        case 'invalid-email':
          message = 'البريد الإلكتروني غير صحيح';
          break;
        case 'user-disabled':
          message = 'الحساب معطل';
          break;
        case 'account-exists-with-different-credential':
          message = 'الحساب مرتبط بطريقة تسجيل أخرى';
          break;
        case 'user-not-found':
          message = 'لا يوجد حساب بهذا البريد';
          break;
        case 'wrong-password':
          message = 'كلمة المرور غير صحيحة';
          break;
        case 'too-many-requests':
          message = 'محاولات كثيرة، حاول لاحقًا';
          break;
        default:
          message = 'فشل تسجيل الدخول، تحقق من بياناتك';
      }
      emit(AuthError(message));
    } catch (e) {
      emit(AuthError('حدث خطأ غير متوقع، حاول مرة أخرى'));
    }
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    // emit(AuthInitState());
  }

  Future<void> checkAuthStatus() async {
    emit(AuthLoadingState());
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      emit(AuthSignOutState());
      return;
    }

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        await _firebaseAuth.signOut();
        emit(AuthSignOutState());
        return;
      }
      if (!user.emailVerified) {
        _firebaseAuth.signOut();
        // emit(AuthSignOutState());
        emit(AuthEmailVerificationFailed(
            email: user.email!, password: user.email!));
        return;
      }

      if (userDoc['status'] != 'approved') {
        _firebaseAuth.signOut();
        emit(AuthSignOutState());
        return;
      }

      emit(AuthLoadedState(user: user));
    } catch (e) {
      emit(AuthError("فشل في وجود المستخدم"));
    }
  }

  Future<void> resetPassword(String email) async {
    emit(ResetPasswordLoading());
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      emit(ResetPasswordSuccess(
          "تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك"));
    } on FirebaseAuthException {
      emit(ResetPasswordError(
          "تعذر إرسال الرابط، تأكد من إدخال بريدك الإلكتروني"));
    }
  }

  Future<void> resendEmailVerification(String email, String password) async {
    emit(AuthLoadingState());

    try {
      // Re-authenticate the user temporarily
      await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        emit(AuthError("لم يتم العثور على الحساب"));
        return;
      }

      // Reload to ensure the latest state
      await user.reload();
      if (user.emailVerified) {
        await _firebaseAuth.signOut();
        emit(AuthError(
            "تم التحقق من بريدك الإلكتروني. يُرجى تسجيل الدخول مرة أخرى"));
        return;
      }
      await user.sendEmailVerification();
      await _firebaseAuth.signOut(); // Sign out after sending the email
      emit(AuthEmailVerificationSent(user));
    } on FirebaseAuthException {
      await _firebaseAuth.signOut();
      emit(AuthError('فشلت محاولة إعادة إرسال رسالة التحقق'));
    } catch (e) {
      await _firebaseAuth.signOut(); // Ensure sign out on error
      emit(AuthError('فشل في ارسال بريد التحقق'));
    }
  }
}
