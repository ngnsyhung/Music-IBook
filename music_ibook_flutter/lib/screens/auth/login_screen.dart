import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController(text: "teacher@gmail.com");
  final password = TextEditingController(text: "123456");

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
            child: _circle(260, Colors.purple.withValues(alpha: .35)),
          ),

          Positioned(
            bottom: -140,
            right: -80,
            child: _circle(280, Colors.blue.withValues(alpha: .35)),
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
                                colors: [Colors.purple, Colors.pink],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.purple.withValues(alpha: .5),
                                  blurRadius: 30,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.music_note,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "Music Learning",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Đăng nhập để tiếp tục học tập",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ),

                          const SizedBox(height: 35),

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

                          const SizedBox(height: 20),

                          if (auth.error != null)
                            Text(
                              auth.error!,
                              style: const TextStyle(color: Colors.redAccent),
                            ),

                          const SizedBox(height: 15),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.purple, Colors.pink],
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
                                        auth.login(email.text, password.text);
                                      },
                                child: Text(
                                  auth.loading
                                      ? "Đang đăng nhập..."
                                      : "Đăng nhập",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  elevation: 0,
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                ),
                                icon: Image.network(
                                  'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                                  height: 24,
                                ),
                                onPressed: auth.loading
                                    ? null
                                    : () {
                                        // Call google login
                                        auth.googleLogin('Student');
                                      },
                                label: const Text(
                                  "Đăng nhập với Google",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          TextButton(
                            onPressed: () => context.go('/forgot-password'),
                            child: const Text(
                              "Quên mật khẩu?",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Chưa có tài khoản?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text("Đăng ký"),
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
        prefixIcon: Icon(icon, color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
