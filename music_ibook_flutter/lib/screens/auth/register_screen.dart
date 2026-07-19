import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brutalist_elements.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  String role = 'Student';
  bool _obscurePassword = true;
  String? _emailError;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

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
                              Icons.person_add,
                              size: 40,
                              color: Color(0xFF007BFF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "JOIN ARCHIVE",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "START YOUR MUSICAL JOURNEY",
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
                    if (auth.error != null)
                      Text(
                        auth.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      "01 / FULL NAME",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: nameController,
                      hint: "Enter your name",
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "02 / EMAIL ADDRESS",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: emailController,
                      hint: "Enter your email",
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
                    const SizedBox(height: 24),
                    const Text(
                      "03 / SECURITY KEY",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: passwordController,
                      hint: "Enter password",
                      icon: Icons.lock,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "04 / CHOOSE ROLE",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: role,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'Student', child: Text('STUDENT')),
                            DropdownMenuItem(value: 'Teacher', child: Text('TEACHER')),
                          ],
                          onChanged: (v) => setState(() => role = v!),
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    BrutalistButton(
                      onTap: auth.loading
                          ? () {}
                          : () async {
                              setState(() {
                                _emailError = null;
                              });
                              final email = emailController.text.trim();
                              if (!Validators.isValidEmail(email)) {
                                setState(() {
                                  _emailError = 'Email không hợp lệ';
                                });
                                return;
                              }
                              final success = await auth.register(
                                nameController.text,
                                email,
                                passwordController.text,
                                role,
                              );
                              if (!mounted) return;
                              if (success) {
                                context.go(role == 'Teacher' ? '/teacher' : '/student');
                              }
                            },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "CREATE ACCOUNT",
                            style: TextStyle(
                              color: Color(0xFF007BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Color(0xFF007BFF), size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          "ALREADY HAVE AN ACCOUNT? LOGIN",
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

  Widget _textField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withValues(alpha: .08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
