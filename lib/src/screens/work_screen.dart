import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../core/models.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_buttons.dart';
import '../core/design_system.dart';

class WorkScreen extends ConsumerWidget {
  const WorkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider);
    final userId = auth.user?.id ?? '';
    final workState = ref.watch(workProvider(userId));
    final workNotifier = ref.read(workProvider(userId).notifier);

    final sampleTask = Task(id: 't1', title: 'Implement feature X', projectId: 'p1');

    return Scaffold(
      appBar: AppBar(title: const Text('Work')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CommonCard(
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Active Task', style: DesignSystem.textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(workState.activeTask?.title ?? 'None', style: DesignSystem.textTheme.bodyLarge),
              ]),
              if (workState.taskState == TaskState.running) Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: DesignSystem.alpha(DesignSystem.primaryBlue, 0.1), borderRadius: BorderRadius.circular(12)), child: const Text('Running'))
            ]),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 12, children: [
            SizedBox(width: 160, child: PrimaryButton(label: 'Start Task', onPressed: () async {
              try {
                await workNotifier.startTask(sampleTask);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task started')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            })),
            SizedBox(width: 160, child: SecondaryButton(label: 'Pause Task', onPressed: () async {
              try {
                await workNotifier.pauseTask();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task paused')));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            })),
            SizedBox(width: 160, child: DangerButton(label: 'Stop', onPressed: () async {
              await workNotifier.stopTask();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Stopped')));
            })),
          ])
        ]),
      ),
    );
  }
}
