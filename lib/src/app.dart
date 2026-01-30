import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/attendance_screen.dart';
import 'screens/work_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/timesheet_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/leave_management_screen.dart';
import 'screens/payslip_screen.dart';
import 'screens/admin_employee_creation_screen.dart';

import 'providers.dart';

class EnterpriseApp extends ConsumerWidget {
  const EnterpriseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apiService = ref.watch(apiServiceProvider);

    return MaterialApp(
      title: 'Enterprise Attendance',
      theme: DesignSystem.theme,
      home: const LoginScreen(),
      routes: {
        '/home': (_) => const HomeScreen(),
        '/attendance': (_) => const AttendanceScreen(),
        '/work': (_) => const WorkScreen(),
        '/chat': (_) => const ChatScreen(),
        '/timesheet': (_) => const TimesheetScreen(),
        '/reports': (_) => const ReportsScreen(),
        '/privacy': (_) => const PrivacyScreen(),
        '/leave': (_) => const LeaveManagementScreen(),
        '/payslip': (_) => const PayslipManagementScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/admin/employees/create') {
          return MaterialPageRoute(
            builder: (_) => AdminEmployeeCreationScreen(apiService: apiService),
          );
        }
        return null;
      },
    );
  }
}
