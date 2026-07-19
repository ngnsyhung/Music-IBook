import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/api_client.dart';
import '../../core/validators.dart';
import '../../services/auth_service.dart';
import '../../widgets/brutalist_elements.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final emailController = TextEditingController();
  String? _emailError;
  String? _errorMessage;

  String? _otp;
  bool _loading = false;
  bool _otpCopied = false;

  // Countdown 15 phút
  int _secondsLeft = 0;
  Timer? _countdownTimer;

  late AnimationController _otpCardController;
  late Animation<double> _otpCardAnimation;

  @override
  void initState() {
    super.initState();
    _otpCardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _otpCardAnimation = CurvedAnimation(
      parent: _otpCardController,
      curve: Curves.easeOutBack,
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    _countdownTimer?.cancel();
    _otpCardController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _secondsLeft = 15 * 60; // 15 phút
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _countdownText {
    if (_secondsLeft <= 0) return 'ĐÃ HẾT HẠN';
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _sendOtp() async {
    setState(() {
      _emailError = null;
      _errorMessage = null;
      _loading = true;
    });

    final email = emailController.text.trim();
    if (!Validators.isValidEmail(email)) {
      setState(() {
        _emailError = 'Email không hợp lệ';
        _loading = false;
      });
      return;
    }

    try {
      final otp = await AuthService().forgotPassword(email);
      if (!mounted) return;
      setState(() {
        _otp = otp;
        _loading = false;
        _otpCopied = false;
      });
      _otpCardController.forward(from: 0);
      _startCountdown();
    } catch (e) {
      if (!mounted) return;

      // Dùng ApiClient.errorMessage để lấy đúng message từ BE
      final raw = ApiClient.errorMessage(e);

      // Map sang thông báo thân thiện
      final String friendly;
      if (raw.contains('Không tìm thấy email') || raw.contains('not found')) {
        friendly = 'Email này chưa được đăng ký trong hệ thống. Vui lòng kiểm tra lại.';
      } else if (raw.contains('Google')) {
        friendly = 'Tài khoản này đăng nhập bằng Google — không thể đặt lại mật khẩu tại đây.';
      } else if (raw.contains('Email không hợp lệ')) {
        friendly = 'Địa chỉ email không đúng định dạng. Vui lòng nhập lại.';
      } else if (raw.contains('kết nối') || raw.contains('connect') || raw.contains('timeout')) {
        friendly = 'Không thể kết nối máy chủ. Kiểm tra mạng và thử lại.';
      } else if (raw.isNotEmpty) {
        friendly = raw;
      } else {
        friendly = 'Đã xảy ra lỗi. Vui lòng thử lại sau.';
      }

      setState(() {
        _errorMessage = friendly;
        _loading = false;
      });
    }
  }

  Future<void> _copyOtp() async {
    if (_otp == null) return;
    await Clipboard.setData(ClipboardData(text: _otp!));
    setState(() => _otpCopied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _otpCopied = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
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
                            Icons.lock_reset,
                            size: 40,
                            color: Color(0xFF007BFF),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'QUÊN MẬT KHẨU',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'NHẬN MÃ OTP ĐỂ ĐỔI MẬT KHẨU',
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

                  // ── Email input ─────────────────────────────────────────
                  const Text(
                    '01 / ĐỊA CHỈ EMAIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  BrutalistInput(
                    controller: emailController,
                    hint: 'Nhập email đã đăng ký',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (_emailError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        _emailError!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // ── Send button ─────────────────────────────────────────
                  BrutalistButton(
                    onTap: _loading ? null : _sendOtp,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF007BFF),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _otp != null ? 'GỬI LẠI MÃ' : 'GỬI MÃ OTP',
                                style: const TextStyle(
                                  color: Color(0xFF007BFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                _otp != null ? Icons.refresh : Icons.send,
                                color: const Color(0xFF007BFF),
                                size: 20,
                              ),
                            ],
                          ),
                  ),

                  // ── Global error ────────────────────────────────────────
                  if (_errorMessage != null) ...[
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
                          const Icon(Icons.error_outline, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
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

                  // ── OTP Card ────────────────────────────────────────────
                  if (_otp != null) ...[
                    const SizedBox(height: 32),
                    ScaleTransition(
                      scale: _otpCardAnimation,
                      child: _buildOtpCard(),
                    ),
                    const SizedBox(height: 20),
                    BrutalistButton(
                      onTap: () => context.push(
                        '/reset-password',
                        extra: {'otp': _otp!},
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'NHẬP MÃ & ĐỔI MẬT KHẨU',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Back to login ───────────────────────────────────────
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text(
                        'QUAY LẠI ĐĂNG NHẬP',
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

  Widget _buildOtpCard() {
    final isExpired = _secondsLeft <= 0;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0xFF007BFF),
            offset: Offset(5, 5),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: const Color(0xFF007BFF),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'MÃ OTP CỦA BẠN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                // Countdown
                Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      color: isExpired ? Colors.red.shade200 : Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _countdownText,
                      style: TextStyle(
                        color: isExpired ? Colors.red.shade200 : Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // OTP digits
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _otp!.split('').map((digit) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 40,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.grey.shade800
                        : const Color(0xFF1A1A2E),
                    border: Border.all(
                      color: isExpired
                          ? Colors.grey.shade600
                          : const Color(0xFF007BFF),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    digit,
                    style: TextStyle(
                      color: isExpired
                          ? Colors.grey.shade500
                          : const Color(0xFF00D4FF),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 0,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Copy button
          Padding(
            padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            child: GestureDetector(
              onTap: isExpired ? null : _copyOtp,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _otpCopied
                      ? Colors.green.shade800
                      : (isExpired ? Colors.grey.shade800 : Colors.white10),
                  border: Border.all(
                    color: _otpCopied
                        ? Colors.green
                        : (isExpired ? Colors.grey.shade600 : Colors.white24),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _otpCopied ? Icons.check : Icons.copy,
                      color: _otpCopied ? Colors.green : Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _otpCopied ? 'ĐÃ COPY!' : 'NHẤN ĐỂ COPY MÃ',
                      style: TextStyle(
                        color: _otpCopied ? Colors.green : Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isExpired)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Mã đã hết hạn — vui lòng gửi lại',
                style: TextStyle(
                  color: Colors.red.shade400,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
