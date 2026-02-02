import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../core/models.dart';
import '../widgets/logo.dart';
import '../widgets/ui_buttons.dart';
import '../core/design_system.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController(text: 'jane');
  final _passCtrl = TextEditingController(text: 'password');
  Role _role = Role.employee;
  bool _loading = false;

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await ref.read(authNotifierProvider.notifier).login(_userCtrl.text, _passCtrl.text, _role);
      if (mounted) Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFEAF2FF), Color(0xFFFFFFFF)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: SizedBox(
            width: 420,
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const CompanyLogo(size: 64),
                  const SizedBox(height: 12),
                  Text('Welcome back', style: DesignSystem.textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(controller: _userCtrl, decoration: const InputDecoration(labelText: 'Username')),
                  const SizedBox(height: 12),
                  TextField(controller: _passCtrl, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                  const SizedBox(height: 12),
                  DropdownButton<Role>(value: _role, items: Role.values.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(), onChanged: (v) => setState(() => _role = v!)),
                  const SizedBox(height: 18),
                  PrimaryButton(label: _loading ? 'Signing in...' : 'Sign In', onPressed: _loading ? null : _doLogin),
                  const SizedBox(height: 8),
                  TextButton(onPressed: () {}, child: const Text('Forgot password?'))
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
