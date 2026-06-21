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
  String role = 'Student';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Họ tên')),
          TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
          TextField(controller: password, decoration: const InputDecoration(labelText: 'Mật khẩu'), obscureText: true),
          DropdownButtonFormField<String>(
            value: role,
            items: const [
              DropdownMenuItem(value: 'Student', child: Text('Học sinh')),
              DropdownMenuItem(value: 'Teacher', child: Text('Giáo viên')),
            ],
            onChanged: (v) => setState(() => role = v!),
            decoration: const InputDecoration(labelText: 'Vai trò'),
          ),
          const SizedBox(height: 16),
          if (auth.error != null) Text(auth.error!, style: const TextStyle(color: Colors.red)),
          ElevatedButton(
            onPressed: () => auth.register(name.text, email.text, password.text, role),
            child: const Text('Đăng ký'),
          ),
          TextButton(onPressed: () => context.go('/login'), child: const Text('Đã có tài khoản')),
        ],
      ),
    );
  }
}
