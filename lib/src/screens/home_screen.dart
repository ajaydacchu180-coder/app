import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../widgets/common_card.dart';
import '../core/design_system.dart';
import '../core/models.dart';
// import '../widgets/ui_buttons.dart';
import '../widgets/logo.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    // ensure IdleWatcher is created for the current session
    ref.read(idleWatcherProvider);
    // ensure SyncScheduler is created for periodic syncs
    ref.read(syncSchedulerProvider);
    final name = auth.user?.name ?? 'User';
    final isAdmin = auth.user?.role == Role.admin;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const CompanyLogo(size: 36),
          const SizedBox(width: 12),
          Expanded(child: Text('Welcome, $name')),
        ]),
        actions: [
          IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications, color: DesignSystem.primaryBlue))
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          CommonCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Today', style: DesignSystem.textTheme.titleLarge),
              const SizedBox(height: 8),
              Row(children: [
                Icon(Icons.circle, color: DesignSystem.primaryBlue, size: 12),
                const SizedBox(width: 8),
                Text(
                    'Status: ${ref.watch(attendanceProvider(auth.user?.id ?? ''))}',
                    style: DesignSystem.textTheme.bodyLarge),
              ])
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, runSpacing: 12, children: [
            _actionCard(context, 'Attendance', Icons.login,
                () => Navigator.pushNamed(context, '/attendance')),
            _actionCard(context, 'Work', Icons.work_outline,
                () => Navigator.pushNamed(context, '/work')),
            _actionCard(context, 'Chat', Icons.chat_bubble_outline,
                () => Navigator.pushNamed(context, '/chat')),
            _actionCard(context, 'Timesheet', Icons.calendar_today_outlined,
                () => Navigator.pushNamed(context, '/timesheet')),
            _actionCard(context, 'Leave', Icons.beach_access,
                () => Navigator.pushNamed(context, '/leave')),
            _actionCard(context, 'Payslip', Icons.receipt_long,
                () => Navigator.pushNamed(context, '/payslip')),
            _actionCard(context, 'Reports', Icons.insert_chart_outlined,
                () => Navigator.pushNamed(context, '/reports')),
            _actionCard(context, 'Privacy', Icons.lock_outline,
                () => Navigator.pushNamed(context, '/privacy')),
            if (isAdmin)
              _actionCard(
                context,
                'Admin Panel',
                Icons.admin_panel_settings,
                () => Navigator.pushNamed(context, '/admin/employees/create'),
                isAdmin: true,
              ),
          ])
        ]),
      ),
    );
  }

  Widget _actionCard(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {bool isAdmin = false}) {
    final cardColor = isAdmin ? Colors.purple.shade50 : Colors.white;
    final iconColor =
        isAdmin ? Colors.purple.shade700 : DesignSystem.primaryBlue;
    final borderColor = isAdmin ? Colors.purple.shade200 : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 160,
        height: 100,
        child: Container(
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: isAdmin ? Border.all(color: borderColor, width: 2) : null,
              boxShadow: [
                BoxShadow(
                    color: DesignSystem.alpha(Colors.black, 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4))
              ]),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 8),
              Text(title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isAdmin ? Colors.purple.shade900 : null))
            ]),
          ),
        ),
      ),
    );
  }
}
