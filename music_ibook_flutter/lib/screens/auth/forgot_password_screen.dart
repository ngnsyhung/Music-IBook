import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final email = TextEditingController();
  String result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quên mật khẩu')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final token = await AuthService().forgotPassword(email.text);
              setState(() => result = token);
            },
            child: const Text('Gửi yêu cầu'),
          ),
          if (result.isNotEmpty) ...[
            const SizedBox(height: 12),
            SelectableText('Token test: $result'),
            ElevatedButton(
              onPressed: () => context.go('/reset-password?token=$result'),
              child: const Text('Đổi mật khẩu bằng token này'),
            )
          ]
        ],
      ),
    );
  }
}
