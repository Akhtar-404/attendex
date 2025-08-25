import 'package:flutter/material.dart';
import 'pages/emp_dashboard_page.dart';
import 'pages/emp_history_page.dart';
import 'pages/emp_leave_page.dart';
import 'pages/emp_profile_page.dart';

class EmployeeShell extends StatefulWidget {
  const EmployeeShell({super.key});
  @override
  State<EmployeeShell> createState() => _S();
}

class _S extends State<EmployeeShell> {
  int _ix = 0;
  final _pages = const [
    EmpDashboardPage(),
    EmpHistoryPage(),
    EmpLeavePage(),
    EmpProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_ix],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _ix,
        onDestinationSelected: (i) => setState(() => _ix = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            label: 'Leave',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
