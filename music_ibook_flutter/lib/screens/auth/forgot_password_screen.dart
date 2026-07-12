import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/brutalist_elements.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  String result = '';
  String? _emailError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const AnimatedBrutalistBackground(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.black, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFE0E0E0),
                                  offset: Offset(6, 6),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.lock_reset,
                              size: 40,
                              color: Color(0xFF007BFF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "LOST KEY",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "RECOVER YOUR ACCESS",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF007BFF),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 48),
                    const Text(
                      "01 / EMAIL ADDRESS",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: emailController,
                      hint: "Enter registered email",
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    if (_emailError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 16),
                        child: Text(
                          _emailError!,
                          style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 32),
                    BrutalistButton(
                      onTap: () async {
                        setState(() {
                          _emailError = null;
                          result = '';
                        });
                        final email = emailController.text.trim();
                        if (!Validators.isValidEmail(email)) {
                          setState(() {
                            _emailError = 'Email không hợp lệ';
                          });
                          return;
                        }
                        final token = await AuthService().forgotPassword(email);
                        setState(() => result = token);
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "SEND RESET LINK",
                            style: TextStyle(
                              color: Color(0xFF007BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.send, color: Color(0xFF007BFF), size: 20),
                        ],
                      ),
                    ),
                    if (result.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "DEBUG TOKEN RECEIVED:",
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              result,
                              style: const TextStyle(color: Color(0xFF007BFF), fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      BrutalistButton(
                        onTap: () => context.go('/reset-password?token=$result'),
                        child: const Text(
                          "PROCEED TO RESET",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ),
                      )
                    ],
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          "BACK TO LOGIN",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
