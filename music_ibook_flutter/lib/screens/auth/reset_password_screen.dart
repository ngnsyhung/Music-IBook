import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/brutalist_elements.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final emailController = TextEditingController(text: widget.email);
  final otpController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool loading = false;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 32.0,
                  vertical: 40.0,
                ),
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
                              Icons.vpn_key,
                              size: 40,
                              color: Color(0xFF007BFF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            "NEW KEY",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            "RE-ESTABLISH SECURITY",
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: emailController,
                      hint: "Enter registered email",
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "02 / 6-DIGIT OTP",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: otpController,
                      hint: "Enter OTP from Gmail",
                      icon: Icons.pin_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "03 / NEW SECURITY KEY",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    BrutalistInput(
                      controller: passwordController,
                      hint: "Enter new password",
                      icon: Icons.lock,
                      isPassword: true,
                      obscureText: _obscurePassword,
                      onToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    BrutalistButton(
                      onTap: () async {
                        if (loading) return;
                        final email = emailController.text.trim();
                        final otp = otpController.text.trim();
                        final password = passwordController.text;
                        if (!Validators.isValidEmail(email)) {
                          setState(() => errorMessage = 'Email không hợp lệ');
                          return;
                        }
                        if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
                          setState(
                            () => errorMessage = 'OTP phải gồm đúng 6 chữ số',
                          );
                          return;
                        }
                        if (password.length < 8) {
                          setState(
                            () => errorMessage =
                                'Mật khẩu mới phải có ít nhất 8 ký tự',
                          );
                          return;
                        }
                        setState(() {
                          loading = true;
                          errorMessage = null;
                        });
                        try {
                          await AuthService().resetPassword(
                            email: email,
                            otp: otp,
                            newPassword: password,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đổi mật khẩu thành công'),
                            ),
                          );
                          context.go('/login');
                        } catch (error) {
                          if (!mounted) return;
                          setState(
                            () => errorMessage = ApiClient.errorMessage(error),
                          );
                        } finally {
                          if (mounted) setState(() => loading = false);
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            loading ? 'UPDATING...' : "UPDATE PASSWORD",
                            style: const TextStyle(
                              color: Color(0xFF007BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (!loading)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF007BFF),
                              size: 20,
                            ),
                        ],
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
}
