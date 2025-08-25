import 'package:flutter/material.dart';
import 'core/palette.dart';
import 'features/auth/login_styled_screen.dart';
import 'features/auth/signup_styled_screen.dart';
import 'features/gate/role_router.dart';
import 'features/employee/employee_shell.dart';
import 'features/hr/hr_home_page.dart';
import 'features/admin/admin_home_page.dart';

class AttendexApp extends StatelessWidget {
  const AttendexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.midBlue);
    return MaterialApp(
      title: 'Attendex',
      theme: ThemeData(colorScheme: scheme, useMaterial3: true),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginStyledScreen(),
        '/signup': (_) => const SignupStyledScreen(),
        '/role': (_) => const RoleRouter(),
        '/employee': (_) => const EmployeeShell(),
        '/hr': (_) => const HrHomePage(),
        '/admin': (_) => const AdminHomePage(),
      },
    );
  }
}
