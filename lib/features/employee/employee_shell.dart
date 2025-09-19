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
    final theme = Theme.of(context);
    return Scaffold(
      body: _pages[_ix],
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 0,
        ), // No bottom margin
        decoration: BoxDecoration(
          color: theme.cardColor.withOpacity(0.98),
          borderRadius: BorderRadius.circular(10), // Tighter corners
          border: const Border(
            top: BorderSide(color: Colors.blue, width: 2),
            bottom: BorderSide(color: Colors.blue, width: 2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            indicatorColor: theme.primaryColor.withOpacity(0.12),
            selectedIndex: _ix,
            height: 60,
            elevation: 0,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) => setState(() => _ix = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: Colors.blue),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.history),
                selectedIcon: Icon(Icons.history, color: Colors.blue),
                label: 'History',
              ),
              NavigationDestination(
                icon: Icon(Icons.event_available_outlined),
                selectedIcon: Icon(Icons.event_available, color: Colors.blue),
                label: 'Leave',
              ),
              NavigationDestination(
                icon: Icon(Icons.person),
                selectedIcon: Icon(Icons.person, color: Colors.blue),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
