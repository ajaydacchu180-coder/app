import 'package:flutter/material.dart';
import 'package:enterprise_attendance/src/features/leave/leave_service.dart';
import 'package:enterprise_attendance/src/widgets/common_card.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({Key? key}) : super(key: key);

  @override
  State<LeaveManagementScreen> createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final LeaveService _leaveService = LeaveService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My Leaves'),
            Tab(text: 'Balance'),
            Tab(text: 'Requests'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyLeavesTab(),
          _buildBalanceTab(),
          _buildRequestsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showApplyLeaveDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMyLeavesTab() {
    return FutureBuilder(
      future: _leaveService.getMyLeaveRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No leave requests yet',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        final leaves = snapshot.data as List;
        return ListView.builder(
          itemCount: leaves.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final leave = leaves[index];
            return CommonCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          leave['leaveType']['name'],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _buildStatusChip(leave['status']),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${leave['startDate']} to ${leave['endDate']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${leave['numberOfDays']} days',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBalanceTab() {
    return FutureBuilder(
      future: _leaveService.getLeaveBalance(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No leave balance data'));
        }

        final balances = snapshot.data as List;
        return ListView.builder(
          itemCount: balances.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final balance = balances[index];
            return CommonCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      balance['leaveType']['name'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    _buildProgressBar(
                      'Used Days',
                      balance['usedDays'],
                      balance['totalDays'],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining: ${balance['remainingDays']} days',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          'Total: ${balance['totalDays']} days',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return FutureBuilder(
      future: _leaveService.getLeaveRequestsForApproval(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return const Center(child: Text('No pending requests'));
        }

        final requests = snapshot.data as List;
        return ListView.builder(
          itemCount: requests.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final request = requests[index];
            return CommonCard(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request['user']['name'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${request['startDate']} to ${request['endDate']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (request['reason'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${request['reason']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (request['status'] == 'PENDING')
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _approveLeaveRequest(request['id']),
                              icon: const Icon(Icons.check),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _rejectLeaveRequest(request['id']),
                              icon: const Icon(Icons.close),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'APPROVED':
        color = Colors.green;
        break;
      case 'REJECTED':
        color = Colors.red;
        break;
      case 'PENDING':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  Widget _buildProgressBar(String label, double used, double total) {
    final percentage = (used / total) * 100;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: used / total,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 80 ? Colors.red : Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  void _showApplyLeaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apply for Leave'),
        content: SingleChildScrollView(
          child: _ApplyLeaveForm(
            onSubmit: (data) {
              _leaveService.createLeaveRequest(data);
              Navigator.pop(context);
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Leave request submitted')),
              );
            },
          ),
        ),
      ),
    );
  }

  void _approveLeaveRequest(int requestId) {
    _leaveService.approveLeaveRequest(requestId).then((_) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request approved')),
      );
    });
  }

  void _rejectLeaveRequest(int requestId) {
    _leaveService.rejectLeaveRequest(requestId).then((_) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave request rejected')),
      );
    });
  }
}

class _ApplyLeaveForm extends StatefulWidget {
  final Function(Map<String, dynamic>) onSubmit;

  const _ApplyLeaveForm({required this.onSubmit});

  @override
  State<_ApplyLeaveForm> createState() => _ApplyLeaveFormState();
}

class _ApplyLeaveFormState extends State<_ApplyLeaveForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _reasonController;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _selectedLeaveType;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FutureBuilder(
            future: LeaveService().getLeaveTypes(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();

              final types = snapshot.data as List;
              return DropdownButton<int?>(
                hint: const Text('Select Leave Type'),
                value: _selectedLeaveType,
                items: types
                    .map<DropdownMenuItem<int>>(
                      (type) => DropdownMenuItem<int>(
                        value: type['id'] as int,
                        child: Text(type['name']),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedLeaveType = value),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _pickDate(true),
            child: Text(_startDate == null
                ? 'Select Start Date'
                : 'Start: ${_startDate!.toLocal().toString().split(' ')[0]}'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _pickDate(false),
            child: Text(_endDate == null
                ? 'Select End Date'
                : 'End: ${_endDate!.toLocal().toString().split(' ')[0]}'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _reasonController,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _pickDate(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        if (isStart) {
          _startDate = date;
        } else {
          _endDate = date;
        }
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() &&
        _selectedLeaveType != null &&
        _startDate != null &&
        _endDate != null) {
      widget.onSubmit({
        'leaveTypeId': _selectedLeaveType,
        'startDate': _startDate,
        'endDate': _endDate,
        'reason': _reasonController.text.isNotEmpty ? _reasonController.text : null,
      });
    }
  }
}
