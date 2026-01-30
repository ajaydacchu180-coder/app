import 'package:flutter/material.dart';
import 'package:enterprise_attendance/src/features/payroll/payroll_service.dart';
import 'package:enterprise_attendance/src/widgets/common_card.dart';

class PayslipManagementScreen extends StatefulWidget {
  const PayslipManagementScreen({Key? key}) : super(key: key);

  @override
  State<PayslipManagementScreen> createState() => _PayslipManagementScreenState();
}

class _PayslipManagementScreenState extends State<PayslipManagementScreen> {
  final PayrollService _payrollService = PayrollService();
  int? _selectedYear;
  int? _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payslips'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    isExpanded: true,
                    items: List.generate(12, (i) => i + 1)
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text('Month: $month'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedMonth = value),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    isExpanded: true,
                    items: [2024, 2025, 2026]
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('Year: $year'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedYear = value),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildPayslipsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPayslipsList() {
    return FutureBuilder(
      future: _payrollService.getPayslips(_selectedMonth, _selectedYear),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || (snapshot.data as List).isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text('No payslips found',
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          );
        }

        final payslips = snapshot.data as List;
        return ListView.builder(
          itemCount: payslips.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final payslip = payslips[index];
            return GestureDetector(
              onTap: () => _showPayslipDetails(payslip),
              child: CommonCard(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Payslip - ${payslip['month']}/${payslip['year']}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          _buildStatusChip(payslip['status']),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gross Salary',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '₹${payslip['totalEarnings'].toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Deductions',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '₹${payslip['totalDeductions'].toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Net Salary',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                '₹${payslip['netSalary'].toStringAsFixed(2)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Worked: ${payslip['attendedDays']}/${payslip['workingDays']} days',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
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
    IconData icon;

    switch (status) {
      case 'PAID':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'APPROVED':
        color = Colors.blue;
        icon = Icons.verified;
        break;
      case 'DRAFT':
        color = Colors.orange;
        icon = Icons.pending_actions;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help;
    }

    return Chip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(status),
        ],
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }

  void _showPayslipDetails(Map<String, dynamic> payslip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Payslip - ${payslip['month']}/${payslip['year']}',
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Base Salary', '₹${payslip['baseSalary']}'),
              const Divider(),
              Text(
                'Earnings',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...?payslip['lineItems']?.map<Widget>((item) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildDetailRow(
                    item['description'],
                    '₹${item['amount'].toStringAsFixed(2)}',
                    isEarning: true,
                  ),
                );
              }).toList(),
              const Divider(),
              Text(
                'Deductions',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              ...?payslip['deductions']?.map<Widget>((deduction) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: _buildDetailRow(
                    deduction['description'] ?? deduction['type'],
                    '₹${deduction['amount'].toStringAsFixed(2)}',
                    isEarning: false,
                  ),
                );
              }).toList(),
              const Divider(thickness: 2),
              _buildDetailRow(
                'Net Salary',
                '₹${payslip['netSalary'].toStringAsFixed(2)}',
                isBold: true,
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                'Worked Days',
                '${payslip['attendedDays']}/${payslip['workingDays']}',
              ),
              _buildDetailRow(
                'Leave Taken',
                '${payslip['leaveTaken']} days',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _downloadPayslip(payslip),
            icon: const Icon(Icons.download),
            label: const Text('Download'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isEarning = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? Colors.black
                : (isEarning ? Colors.green : Colors.red),
          ),
        ),
      ],
    );
  }

  void _downloadPayslip(Map<String, dynamic> payslip) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payslip download started')),
    );
    // Implement PDF generation and download
  }
}
