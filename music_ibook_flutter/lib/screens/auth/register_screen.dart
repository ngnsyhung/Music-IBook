import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  String role = "Student";

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E1E2C),
                  Color(0xFF6C63FF).withValues(alpha: 0.6),
                  Color(0xFF121212),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Positioned(
            top: -120,
            left: -80,
            child: _circle(260, Colors.deepPurple.withValues(alpha: .35)),
          ),

          Positioned(
            bottom: -140,
            right: -90,
            child: _circle(280, Colors.blue.withValues(alpha: .30)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .15),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.deepPurple, Colors.pink],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: .5),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.library_music,
                              color: Colors.white,
                              size: 45,
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "Tạo tài khoản",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Tham gia cộng đồng học nhạc",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ),

                          const SizedBox(height: 35),

                          _textField(
                            controller: name,
                            icon: Icons.person_outline,
                            hint: "Họ và tên",
                          ),

                          const SizedBox(height: 18),

                          _textField(
                            controller: email,
                            icon: Icons.email_outlined,
                            hint: "Email",
                          ),

                          const SizedBox(height: 18),

                          _textField(
                            controller: password,
                            icon: Icons.lock_outline,
                            hint: "Mật khẩu",
                            obscure: true,
                          ),

                          const SizedBox(height: 18),

                          DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xff243B55),
                            initialValue: role,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                color: Colors.white70,
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: .08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Student",
                                child: Text("🎓 Học sinh"),
                              ),
                              DropdownMenuItem(
                                value: "Teacher",
                                child: Text("🎼 Giáo viên"),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                role = v!;
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          if (auth.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                auth.error!,
                                style: const TextStyle(color: Colors.redAccent),
                              ),
                            ),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.deepPurple, Colors.pink],
                                ),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                onPressed: auth.loading
                                    ? null
                                    : () {
                                        auth.register(
                                          name.text,
                                          email.text,
                                          password.text,
                                          role,
                                        );
                                      },
                                child: Text(
                                  auth.loading ? "Đang đăng ký..." : "Đăng ký",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Đã có tài khoản?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () => context.go("/login"),
                                child: const Text("Đăng nhập"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
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
