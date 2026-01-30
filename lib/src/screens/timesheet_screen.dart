import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system.dart';
import '../widgets/common_card.dart';
import '../widgets/ui_buttons.dart';
import '../providers.dart';
import '../features/timesheet/timesheet_service.dart';

class TimesheetScreen extends ConsumerStatefulWidget {
  const TimesheetScreen({super.key});

  @override
  ConsumerState<TimesheetScreen> createState() => _TimesheetScreenState();
}

class _TimesheetScreenState extends ConsumerState<TimesheetScreen> {
  Timesheet? _ts;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final auth = ref.read(authNotifierProvider);
    if (!auth.isAuthenticated) {
      setState(() => _loading = false);
      return;
    }
    final svc = ref.read(timesheetServiceProvider);
    try {
      final ts = await svc.generateDailyTimesheet(auth.user!.id, DateTime.now().toUtc());
      setState(() {
        _ts = ts;
      });
    } catch (_) {
      setState(() {
        _ts = null;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _manualSync() async {
    setState(() => _loading = true);
    final svc = ref.read(timesheetServiceProvider);
    final res = await svc.syncUnsyncedSegments();
    final success = res['status'] == 'ok';
    ref.read(syncStatusProvider.notifier).setResult(success: success, message: res.toString());
    await _load();
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Manual sync: ${res['status']}')));
    }
  }

  Future<void> _submit() async {
    if (_ts == null) return;
    setState(() => _loading = true);
    final svc = ref.read(timesheetServiceProvider);
    final res = await svc.submitTimesheet(_ts!);
    setState(() => _loading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submitted: ${res['status']}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Timesheet', style: DesignSystem.textTheme.titleLarge)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unsynced + manual sync
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Consumer(builder: (context, ref, _) {
                    final unsynced = ref.watch(unsyncedSegmentsProvider);
                    return unsynced.when(
                      data: (count) => Text('Unsynced segments: $count'),
                      loading: () => const Text('Unsynced: ...'),
                      error: (_, __) => const Text('Unsynced: ?'),
                    );
                  }),
                  const SizedBox(width: 12),
                  SizedBox(width: 140, child: SecondaryButton(label: 'Sync Now', onPressed: _loading ? null : _manualSync)),
                  const SizedBox(width: 12),
                  Expanded(child: Consumer(builder: (context, ref, _) {
                    final sync = ref.watch(syncStatusProvider);
                    final label = sync.lastSync == null ? 'Last: never' : 'Last: ${sync.lastSync}';
                    return Text(label);
                  })),
                ],
              ),
            ),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _ts == null
                      ? const Center(child: Text('No entries'))
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _ts!.entries.length,
                                itemBuilder: (context, idx) {
                                  final e = _ts!.entries[idx];
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: CommonCard(
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('${e.projectId} • ${e.taskId}', style: DesignSystem.textTheme.titleMedium),
                                              const SizedBox(height: 6),
                                              Text('${e.hours.toStringAsFixed(2)} hours', style: DesignSystem.textTheme.bodyMedium),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              SizedBox(
                                                width: 86,
                                                child: TextFormField(
                                                  initialValue: e.hours.toStringAsFixed(2),
                                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                                  onChanged: (v) {
                                                    final parsed = double.tryParse(v) ?? e.hours;
                                                    e.hours = parsed;
                                                  },
                                                  decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton(onPressed: () {}, icon: Icon(Icons.edit, color: DesignSystem.primaryBlue))
                                            ],
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: double.infinity, child: PrimaryButton(label: 'Submit Timesheet', onPressed: _submit)),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
