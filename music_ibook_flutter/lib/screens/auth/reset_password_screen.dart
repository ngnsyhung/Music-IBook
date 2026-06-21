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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lại mật khẩu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: token, decoration: const InputDecoration(labelText: 'Reset token')),
          TextField(controller: password, decoration: const InputDecoration(labelText: 'Mật khẩu mới'), obscureText: true),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await AuthService().resetPassword(token.text, password.text);
              if (context.mounted) context.go('/login');
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }
}
