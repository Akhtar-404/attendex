import 'package:flutter/material.dart';
import '../../services/token_storage.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});
  @override
  State<RoleRouter> createState() => _S();
}

class _S extends State<RoleRouter> {
  @override
  void initState() {
    super.initState();
    _go();
  }

  Future<void> _go() async {
    final t = await TokenStorage.readAccess();
    final role = (await TokenStorage.readRole()) ?? 'EMPLOYEE';
    if (!mounted) return;
    if (t == null) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      switch (role) {
        case 'ADMIN':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        case 'HR':
          Navigator.pushReplacementNamed(context, '/hr');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/employee');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
