import 'package:flutter/material.dart';
import '../../../services/token_storage.dart';

class EmpProfilePage extends StatelessWidget {
  const EmpProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: FilledButton.tonal(
          onPressed: () async {
            await TokenStorage.clear();
            if (context.mounted)
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
          },
          child: const Text('Logout'),
        ),
      ),
    );
  }
}
