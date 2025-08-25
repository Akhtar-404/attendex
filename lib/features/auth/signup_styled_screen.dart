import 'package:flutter/material.dart';
import '../../core/validators.dart';
import 'auth_service.dart';

class SignupStyledScreen extends StatefulWidget {
  const SignupStyledScreen({super.key});
  @override
  State<SignupStyledScreen> createState() => _S();
}

class _S extends State<SignupStyledScreen> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _conf = TextEditingController();
  bool _busy = false, _obscure = true, _obscure2 = true;
  final _svc = AuthService();

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _conf.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_f.currentState?.validate() ?? false)) return;
    setState(() => _busy = true);
    try {
      await _svc.signup(_name.text.trim(), _email.text.trim(), _pass.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created. Please sign in.')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Signup failed: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    InputDecoration deco(String label, {IconData? icon}) => InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon) : null,
      border: const OutlineInputBorder(),
    );
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
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
                        children: [
                          TextFormField(
                            controller: _name,
                            decoration: deco(
                              'Full name',
                              icon: Icons.person_outline,
                            ),
                            validator: (v) => validateNonEmpty('Name', v),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _email,
                            decoration: deco(
                              'Email',
                              icon: Icons.email_outlined,
                            ),
                            validator: validateEmail,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _pass,
                            obscureText: _obscure,
                            decoration:
                                deco(
                                  'Password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
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
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _conf,
                            obscureText: _obscure2,
                            decoration:
                                deco(
                                  'Confirm password',
                                  icon: Icons.lock_outline,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscure2
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscure2 = !_obscure2),
                                  ),
                                ),
                            validator: (v) => v == _pass.text
                                ? null
                                : 'Passwords do not match',
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
                                  : const Text('Create account'),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                            child: const Text(
                              'Already have an account? Sign in',
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
