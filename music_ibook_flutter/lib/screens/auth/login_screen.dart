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
  final email = TextEditingController(text: 'teacher@gmail.com');
  final password = TextEditingController(text: '123456');

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: password, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
          const SizedBox(height: 16),
          if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: auth.loading ? null : () => auth.login(email.text, password.text),
            child: Text(auth.loading ? 'Đang xử lý...' : 'Đăng nhập'),
          ),
          TextButton(onPressed: () => context.go('/register'), child: const Text('Tạo tài khoản')),
          TextButton(onPressed: () => context.go('/forgot-password'), child: const Text('Quên mật khẩu')),
        ],
      ),
    );
  }
}
