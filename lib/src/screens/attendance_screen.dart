import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../widgets/common_card.dart';
import '../core/models.dart';
import '../widgets/ui_buttons.dart';
import '../core/design_system.dart';

class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final userId = auth.user?.id ?? '';
    final attendanceState = ref.watch(attendanceProvider(userId));
    final attendanceNotifier = ref.read(attendanceProvider(userId).notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          CommonCard(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Current', style: DesignSystem.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text('$attendanceState', style: DesignSystem.textTheme.bodyLarge),
              ]),
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: attendanceState == AttendanceState.checkedIn ? DesignSystem.secondaryBlue : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Text(attendanceState.toString().split('.').last)),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: PrimaryButton(label: 'Check In', onPressed: () async {
              try {
                await attendanceNotifier.checkIn();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked in')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            })),
            const SizedBox(width: 12),
            Expanded(child: SecondaryButton(label: 'Check Out', onPressed: () async {
              try {
                await attendanceNotifier.checkOut();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Checked out')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            })),
          ])
        ]),
      ),
    );
  }
}
