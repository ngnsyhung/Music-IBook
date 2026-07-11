import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final token = TextEditingController(text: widget.token);

  final password = TextEditingController();

  bool loading = false;
  bool hidePassword = true;

  @override
  Widget build(BuildContext context) {
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
            left: -90,
            child: _circle(260, Colors.deepPurple.withValues(alpha: .35)),
          ),

          Positioned(
            bottom: -140,
            right: -80,
            child: _circle(280, Colors.blueAccent.withValues(alpha: .30)),
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
                              Icons.lock_reset,
                              size: 45,
                              color: Colors.white,
                            ),
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            "Đặt lại mật khẩu",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            "Tạo mật khẩu mới để tiếp tục sử dụng ứng dụng",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .7),
                            ),
                          ),

                          const SizedBox(height: 35),

                          _textField(
                            controller: token,
                            hint: "Reset Token",
                            icon: Icons.vpn_key_outlined,
                          ),

                          const SizedBox(height: 18),

                          TextField(
                            controller: password,
                            obscureText: hidePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: "Mật khẩu mới",
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(
                                Icons.lock_outline,
                                color: Colors.white70,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  hidePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: Colors.white70,
                                ),
                                onPressed: () {
                                  setState(() {
                                    hidePassword = !hidePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: .08),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

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
                                onPressed: loading
                                    ? null
                                    : () async {
                                        setState(() {
                                          loading = true;
                                        });

                                        await AuthService().resetPassword(
                                          token.text,
                                          password.text,
                                        );

                                        if (!mounted) {
                                          return;
                                        }

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              "Đổi mật khẩu thành công",
                                            ),
                                          ),
                                        );

                                        context.go("/login");
                                      },
                                child: Text(
                                  loading ? "Đang xử lý..." : "Đổi mật khẩu",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          TextButton.icon(
                            onPressed: () => context.go("/login"),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white70,
                              size: 18,
                            ),
                            label: const Text(
                              "Quay lại đăng nhập",
                              style: TextStyle(color: Colors.white70),
                            ),
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
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
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
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
