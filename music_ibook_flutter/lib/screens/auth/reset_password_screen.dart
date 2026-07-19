import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/brutalist_elements.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController tokenController;
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  // Validation errors
  String? _tokenError;
  String? _passwordError;
  String? _confirmError;
  String? _globalError;

  @override
  void initState() {
    super.initState();
    tokenController = TextEditingController(text: widget.token);
  }

  @override
  void dispose() {
    tokenController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    String? tokenErr, passErr, confirmErr;

    final token = tokenController.text.trim();
    final pass = passwordController.text;
    final confirm = confirmController.text;

    if (token.isEmpty) {
      tokenErr = 'Vui lòng nhập mã OTP';
    } else if (token.length != 6 || !RegExp(r'^\d{6}$').hasMatch(token)) {
      tokenErr = 'Mã OTP phải gồm đúng 6 chữ số';
    }

    if (pass.isEmpty) {
      passErr = 'Vui lòng nhập mật khẩu mới';
    } else if (pass.length < 6) {
      passErr = 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    if (confirm.isEmpty) {
      confirmErr = 'Vui lòng xác nhận mật khẩu';
    } else if (confirm != pass) {
      confirmErr = 'Mật khẩu xác nhận không khớp';
    }

    setState(() {
      _tokenError = tokenErr;
      _passwordError = passErr;
      _confirmError = confirmErr;
    });

    return tokenErr == null && passErr == null && confirmErr == null;
  }

  Future<void> _resetPassword() async {
    setState(() => _globalError = null);
    if (!_validate()) return;

    setState(() => _loading = true);
    try {
      await AuthService().resetPassword(
        tokenController.text.trim(),
        passwordController.text,
      );
      if (!mounted) return;

      // Thông báo thành công
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black,
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: Colors.green, width: 1.5),
          ),
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 10),
              Text(
                'Đổi mật khẩu thành công!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) context.go('/login');
    } catch (e) {
      if (!mounted) return;
      String msg = e.toString();
      final match = RegExp(r'"message"\s*:\s*"([^"]+)"').firstMatch(msg);
      if (match != null) msg = match.group(1)!;
      setState(() {
        _globalError = msg.replaceAll('Exception: ', '');
        _loading = false;
      });
    }
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
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 40.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
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
                            Icons.vpn_key_rounded,
                            size: 40,
                            color: Color(0xFF007BFF),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'ĐẶT MẬT KHẨU MỚI',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'NHẬP MÃ OTP VÀ MẬT KHẨU MỚI',
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

                  // ── OTP input ───────────────────────────────────────────
                  const Text(
                    '01 / MÃ OTP (6 CHỮ SỐ)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BrutalistInput(
                    controller: tokenController,
                    hint: 'Nhập mã OTP nhận được',
                    icon: Icons.confirmation_number_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  if (_tokenError != null)
                    _buildFieldError(_tokenError!),

                  const SizedBox(height: 24),

                  // ── New password ────────────────────────────────────────
                  const Text(
                    '02 / MẬT KHẨU MỚI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BrutalistInput(
                    controller: passwordController,
                    hint: 'Tối thiểu 6 ký tự',
                    icon: Icons.lock_outline,
                    isPassword: true,
                    obscureText: _obscurePassword,
                    onToggle: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  if (_passwordError != null)
                    _buildFieldError(_passwordError!),

                  const SizedBox(height: 24),

                  // ── Confirm password ────────────────────────────────────
                  const Text(
                    '03 / XÁC NHẬN MẬT KHẨU',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BrutalistInput(
                    controller: confirmController,
                    hint: 'Nhập lại mật khẩu mới',
                    icon: Icons.lock_person_outlined,
                    isPassword: true,
                    obscureText: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  if (_confirmError != null)
                    _buildFieldError(_confirmError!),

                  // ── Global error ────────────────────────────────────────
                  if (_globalError != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F3),
                        border: Border.all(color: Colors.red, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _globalError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // ── Submit button ───────────────────────────────────────
                  BrutalistButton(
                    onTap: _loading ? null : _resetPassword,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF007BFF),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'CẬP NHẬT MẬT KHẨU',
                                style: TextStyle(
                                  color: Color(0xFF007BFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.check_circle_outline,
                                color: Color(0xFF007BFF),
                                size: 20,
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),

                  // ── Back to forgot password ─────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/forgot-password'),
                      child: const Text(
                        'CHƯA CÓ MÃ? GỬI LẠI',
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
        ],
      ),
    );
  }

  Widget _buildFieldError(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message,
        style: const TextStyle(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
