import 'package:flutter/material.dart';
import '../../core/validators.dart';
import '../../services/token_storage.dart';
import 'auth_service.dart';

class LoginStyledScreen extends StatefulWidget {
  const LoginStyledScreen({super.key});
  @override
  State<LoginStyledScreen> createState() => _S();
}

class _S extends State<LoginStyledScreen> {
  final _f = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false, _obscure = true;
  final _svc = AuthService();

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_f.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      final data = await _svc.login(_email.text, _pass.text);

      // ⬇️ Save tokens & role
      await TokenStorage.save(
        access: data['accessToken'],
        refresh: data['refreshToken'],
        role: (data['user']?['role'] ?? 'EMPLOYEE').toString(),
      );

      // (Optional) quick debug to confirm we actually stored it
      final t = await TokenStorage.readAccess();
      if (t != null && t.isNotEmpty) {
        print('Token prefix: ${t.substring(0, t.length < 12 ? t.length : 12)}');
      } else {
        print('No token saved!');
      }

      if (!mounted) return;
      // Route to role router (or home) after login
      Navigator.pushReplacementNamed(context, '/role');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(28));
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  'ATTENDEX',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 18),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _f,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _email,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: validateEmail,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass,
                            obscureText: _obscure,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: border,
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: validatePassword,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 56,
                            child: FilledButton(
                              onPressed: _busy ? null : _submit,
                              child: _busy
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text('Sign in'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/signup',
                            ),
                            child: const Text(
                              "Don't have an account? Create one",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
