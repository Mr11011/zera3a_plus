import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:zera3a/core/widgets/customTextFormField.dart';
import 'package:zera3a/feature/auth/auth_cubit.dart';
import 'package:zera3a/feature/auth/auth_states.dart';
import 'package:zera3a/core/di.dart';
import 'package:zera3a/feature/auth/signIn_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool isHidden = true;
  bool confirmIsHidden = true;
  String _selectedRole = 'supervisor';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthStates>(
        listener: (context, state) {
          if (state is AuthPendingOwnerState) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text('طلب انشاء الحساب قيد المراجعة',
                      style: TextStyle(color: Colors.green)),
                  content: const Column(mainAxisSize: MainAxisSize.min, children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.0),
                      child: Text(
                        '• تم إرسال طلبك للتسجيل كصاحب مزرعة. سنتحقق من بياناتك',
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(bottom: 5.0),
                      child: Text(
                        '• لقد إرسل اليك رابط التأكيد إلى بريدك الإلكتروني',
                      ),
                    ),
                    Text(
                      '• قبل الغلق , يرجى التحقق من بريدك والنقر على الرابط لتفعيل حسابك',
                    ),
                  ]),
                  actions: [
                    TextButton(
                      onPressed: () {
                        state.user.sendEmailVerification();
                        Fluttertoast.showToast(
                          msg: 'تم إعادة إرسال رابط التأكيد',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                      },
                      child: Text(
                        'إعادة إرسال',
                        style: TextStyle(color: AppColor.green),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInScreen()));
                      },
                      child: const Text('حسنًا'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is AuthEmailVerificationSent) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => Directionality(
                textDirection: TextDirection.rtl,
                child: AlertDialog(
                  title: const Text(
                    'تأكيد البريد الإلكتروني',
                    style: TextStyle(color: Colors.green),
                  ),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          '• تم إرسال رابط التأكيد إلى بريدك الإلكتروني',
                        ),
                      ),
                      Text(
                        '• قبل الغلق , يرجى التحقق من بريدك والنقر على الرابط لتفعيل حسابك',
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        state.user.sendEmailVerification();
                        Fluttertoast.showToast(
                          msg: 'تم إعادة إرسال رابط التأكيد',
                          backgroundColor: Colors.green,
                          textColor: Colors.white,
                        );
                      },
                      child: Text('إعادة إرسال',
                          style: TextStyle(color: AppColor.green)),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignInScreen()));
                      },
                      child: const Text('حسنًا'),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is AuthError) {
            Fluttertoast.showToast(
              msg: state.error,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG,
            );
          }
        },
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              // backgroundColor: AppColor.beige,
              backgroundColor: Colors.grey.shade100,
              appBar: AppBar(
                title: const Text('انشاء حساب الدخول'),
                backgroundColor: AppColor.flaxBeige,
              ),
              body: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 180,
                        width: 180,
                        child: ClipOval(
                          child: Image(
                            image: AssetImage('assets/images/1.jpg'),
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'مرحبًا! سجل الآن لإدارة مزرعتك بسهولة وكفاءة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: AppColor.medBrown,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      CustomTextFormField(
                        labelText: 'الاسم',
                        prefixIcon: Icons.person,
                        keyboardType: TextInputType.name,
                        controller: _fullNameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال الاسم الكامل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomTextFormField(
                        controller: _emailController,
                        prefixIcon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        labelText: 'البريد الالكتروني',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال البريد الإلكتروني';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'البريد الإلكتروني غير صحيح';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomTextFormField(
                        labelText: 'كلمه السر',
                        obscureText: isHidden,
                        prefixIcon: Icons.lock,
                        controller: _passwordController,
                        suffixIcon:
                            isHidden ? Icons.visibility : Icons.visibility_off,
                        onSuffixIconPressed: () {
                          setState(() {
                            isHidden = !isHidden;
                          });
                        },
                        keyboardType: TextInputType.visiblePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى إدخال كلمة المرور';
                          }
                          if (value.toString().trim().length < 6) {
                            return 'كلمة المرور يجب أن تكون 6 أحرف او ارقام علي الأقل';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomTextFormField(
                        keyboardType: TextInputType.visiblePassword,
                        labelText: 'تأكيد كلمه السر',
                        prefixIcon: Icons.lock,
                        obscureText: confirmIsHidden,
                        suffixIcon: confirmIsHidden
                            ? Icons.visibility
                            : Icons.visibility_off,
                        onSuffixIconPressed: () {
                          setState(() {
                            confirmIsHidden = !confirmIsHidden;
                          });
                        },
                        controller: _confirmPasswordController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'يرجى تأكيد كلمة المرور';
                          }
                          if (value != _passwordController.text) {
                            return 'كلمة المرور غير متطابقة';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      CustomTextFormField(
                        labelText: 'رقم الهاتف (اختياري)',
                        controller: _phoneController,
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                              return 'يرجى إدخال رقم هاتف صحيح';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.topRight,
                        child: Text(
                          'اختر دورك',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.medBrown,
                          ),
                        ),
                      ),
                      RadioListTile(
                        title: const Text('صاحب المزرعة'),
                        value: 'owner',
                        groupValue: _selectedRole,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      RadioListTile(
                        title: const Text('مشرف'),
                        value: 'supervisor',
                        groupValue: _selectedRole,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColor.green,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: state is AuthLoadingState
                              ? null
                              : () {
                                  if (formKey.currentState!.validate()) {
                                    sl<AuthCubit>().signUp(
                                      _emailController.text.trim(),
                                      _passwordController.text,
                                      _fullNameController.text.trim(),
                                      role: _selectedRole,
                                      phone: _phoneController.text.isEmpty
                                          ? null
                                          : _phoneController.text.trim(),
                                    );
                                  }
                                },
                          child: state is AuthLoadingState
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  'تسجيل الحساب',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
