import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:zera3a/core/utils/colors.dart';
import 'package:zera3a/core/widgets/customTextFormField.dart';
import 'package:zera3a/feature/auth/auth_cubit.dart';
import 'package:zera3a/feature/auth/auth_states.dart';
import 'package:zera3a/core/di.dart';
import 'package:zera3a/feature/auth/pendingUser_screen.dart';
import 'package:zera3a/feature/auth/signUp_Screen.dart';

import '../home/views/home_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isHidden = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocProvider.value(
      value: sl<AuthCubit>(),
      child: BlocConsumer<AuthCubit, AuthStates>(
        listener: (context, state) {
          if (state is AuthPendingState) {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const PendingScreen()));
          }
          if (state is AuthEmailVerificationFailed) {
            showDialog(
                context: context,
                builder: (context) => Directionality(
                      textDirection: TextDirection.rtl,
                      child: AlertDialog(
                        icon: const Icon(
                          Icons.verified_rounded,
                          color: Colors.blue,
                          size: 25,
                        ),
                        content: const Text(
                          maxLines: 12,
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          'لقد أرسلنا رابط تحقق إلى بريدك الإلكتروني.\nيرجى التحقق من بريدك والنقر على الرابط للتحقق من حسابك.\nإذا لم تستلم الرسالة، فتحقق من مجلد البريد العشوائي أو أعد إرسالها من خلال الزر.',
                          style: TextStyle(color: Colors.black54),
                        ),
                        title: const Text(
                          "يرجي التحقق من بريدك الألكتروني",
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 18),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: const Text('حسناً')),
                          TextButton(
                            child: const Text('اعادة ارسال'),
                            onPressed: () {
                              context.read<AuthCubit>().resendEmailVerification(
                                  state.email, state.password);
                            },
                          )
                        ],
                      ),
                    ),
                barrierDismissible: false);
            // Fluttertoast.showToast(
            //     msg: "لم يتحقق من الحساب, يرجى مراجعه بريدك الإلكتروني");
          }
          if (state is AuthLoadedState) {
            Fluttertoast.showToast(
              msg: 'تم تسجيل الدخول بنجاح',
              backgroundColor: Colors.green,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG,
            );
            // Navigate to home screen (replace with your route)
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (context) => const HomePage()));
          } else if (state is AuthError) {
            Fluttertoast.showToast(
              msg: state.error,
              backgroundColor: Colors.red,
              textColor: Colors.white,
              toastLength: Toast.LENGTH_LONG,
            );
          } else if (state is ResetPasswordSuccess) {
            Fluttertoast.showToast(
              msg: 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك',
              backgroundColor: Colors.green,
              textColor: Colors.white,
            );
          } else if (state is ResetPasswordError) {
            Fluttertoast.showToast(
              msg: state.error,
              backgroundColor: Colors.red,
              textColor: Colors.white,
            );
          }
        },
        builder: (context, state) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Stack(
                fit: StackFit.expand, // Makes the background fill the screen
                children: [
                  // Background Image (70% of the screen)
                  SizedBox(
                    height: size.height * 0.70,
                    width: size.width,
                    child: Image.asset(
                      'assets/images/background3.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // White Circular Container with Login Form
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: size.height * 0.50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(70),
                        ),
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  'أهلاً بك مجددًا! ادخل بياناتك لتستمر في تنظيم مزرعتك بكل سهوله',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColor.green,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Divider(
                                    color: AppColor.flaxBeige, thickness: 0.6),
                                const SizedBox(height: 20),
                                CustomTextFormField(
                                  controller: _emailController,
                                  prefixIcon: Icons.email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  labelText: 'البريد الإلكتروني',
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'يرجى إدخال البريد الإلكتروني';
                                    }
                                    if (!RegExp(
                                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                        .hasMatch(value)) {
                                      return 'البريد الإلكتروني غير صحيح';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 15),
                                CustomTextFormField(
                                  controller: _passwordController,
                                  labelText: 'كلمة المرور',
                                  obscureText: isHidden,
                                  prefixIcon: Icons.lock,
                                  suffixIcon: isHidden
                                      ? Icons.visibility
                                      : Icons.visibility_off,
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
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: state is AuthLoadingState
                                      ? null
                                      : () {
                                          if (formKey.currentState!
                                              .validate()) {
                                            context.read<AuthCubit>().signIn(
                                                  email: _emailController.text
                                                      .trim(),
                                                  password:
                                                      _passwordController.text,
                                                );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColor.medBrown,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  child: state is AuthLoadingState
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : const Text(
                                          'تسجيل الدخول',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    if (_emailController.text.isNotEmpty) {
                                      context
                                          .read<AuthCubit>()
                                          .resetPassword(_emailController.text);
                                    } else {
                                      Fluttertoast.showToast(
                                        msg:
                                            'يرجى إدخال البريد الإلكتروني أولاً',
                                        backgroundColor: Colors.orange,
                                        textColor: Colors.white,
                                      );
                                    }
                                  },
                                  child: Text(
                                    'نسيت كلمة المرور؟',
                                    style: TextStyle(
                                      color: AppColor.medBrown,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SignUpScreen(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'ليس لديك حساب؟ سجل الآن',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
