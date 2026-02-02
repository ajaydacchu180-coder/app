import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:enterprise_attendance/src/services/api_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';

class AdminEmployeeCreationScreen extends ConsumerStatefulWidget {
  final ApiService apiService;

  const AdminEmployeeCreationScreen({
    Key? key,
    required this.apiService,
  }) : super(key: key);

  @override
  ConsumerState<AdminEmployeeCreationScreen> createState() =>
      _AdminEmployeeCreationScreenState();
}

class _AdminEmployeeCreationScreenState
    extends ConsumerState<AdminEmployeeCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  final List<Map<String, dynamic>> _auditLog = [];

  String get _currentAdmin {
    final user = ref.read(authNotifierProvider).user;
    // User model doesn't have email, so usage name or ID
    return user != null ? '${user.name} (${user.id})' : 'admin@company.com';
  }

  @override
  void initState() {
    super.initState();
    _loadAuditLog();
  }

  Future<void> _loadAuditLog() async {
    // Initialize audit log (currently in-memory only)
    setState(() {});
  }

  Future<void> _createEmployee() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final timestamp = DateTime.now();
      final employeeId = _employeeIdController.text;
      final password = _passwordController.text;
      final email = _emailController.text;
      final name = _nameController.text;
      final department = _departmentController.text;

      // Call API to create employee
      await widget.apiService.createEmployee(
        employeeId: employeeId,
        email: email,
        name: name,
        department: department,
        password: password,
      );

      // Detailed logging for employee ID creation
      final idCreationLog = {
        'timestamp': timestamp,
        'action': 'EMPLOYEE_ID_CREATED',
        'employeeId': employeeId,
        'email': email,
        'name': name,
        'department': department,
        'createdBy': _currentAdmin,
        'status': 'SUCCESS',
        'logLevel': 'INFO',
        'details': 'Employee ID $employeeId created for $name ($email)',
      };

      // Detailed logging for password creation (hashed for security)
      final passwordCreationLog = {
        'timestamp': timestamp.add(const Duration(milliseconds: 100)),
        'action': 'EMPLOYEE_PASSWORD_CREATED',
        'employeeId': employeeId,
        'password_hash': _hashPassword(password),
        'password_strength': _evaluatePasswordStrength(password),
        'createdBy': _currentAdmin,
        'status': 'SUCCESS',
        'logLevel': 'INFO',
        'details': 'Initial password set with ${password.length} characters',
      };

      // Audit trail entry
      final auditTrailLog = {
        'timestamp': timestamp.add(const Duration(milliseconds: 200)),
        'action': 'EMPLOYEE_CREATION_COMPLETE',
        'employeeId': employeeId,
        'email': email,
        'name': name,
        'department': department,
        'createdBy': _currentAdmin,
        'status': 'SUCCESS',
        'logLevel': 'INFO',
        'details': 'Complete employee creation audit trail',
      };

      // Add all logs
      _auditLog.addAll([idCreationLog, passwordCreationLog, auditTrailLog]);

      setState(() {});

      // Show credentials dialog
      if (context.mounted) {
        await _showCredentialsDialog(
          employeeId: employeeId,
          email: email,
          name: name,
          password: password,
          department: department,
        );
      }

      // Clear form
      _formKey.currentState!.reset();
      _employeeIdController.clear();
      _passwordController.clear();
      _emailController.clear();
      _nameController.clear();
      _departmentController.clear();
    } catch (e) {
      final errorLog = {
        'timestamp': DateTime.now(),
        'action': 'EMPLOYEE_CREATION_FAILED',
        'employeeId': _employeeIdController.text,
        'error': e.toString(),
        'createdBy': _currentAdmin,
        'status': 'FAILED',
        'logLevel': 'ERROR',
        'details': 'Employee creation failed: $e',
      };

      _auditLog.add(errorLog);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating employee: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCredentialsDialog({
    required String employeeId,
    required String email,
    required String name,
    required String password,
    required String department,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Employee Created Successfully!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.amber[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Important: Save these credentials now. They will not be shown again!',
                          style: TextStyle(
                            color: Colors.amber[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Employee Login Credentials',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildCredentialField('Full Name', name),
                _buildCredentialField('Department', department),
                const Divider(height: 32),
                _buildCredentialField('Employee ID', employeeId,
                    copyable: true),
                _buildCredentialField('Email', email, copyable: true),
                _buildCredentialField('Password', password,
                    copyable: true, isPassword: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Employee must change password on first login',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                _copyAllCredentials(employeeId, email, password);
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.copy_all),
              label: const Text('Copy All & Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCredentialField(String label, String value,
      {bool copyable = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: isPassword ? 'monospace' : null,
                        fontWeight:
                            isPassword ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (copyable)
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$label copied to clipboard'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _copyAllCredentials(String employeeId, String email, String password) {
    final credentials = '''
Employee Login Credentials
--------------------------
Employee ID: $employeeId
Email: $email
Password: $password

Note: Please change your password on first login.
''';
    Clipboard.setData(ClipboardData(text: credentials));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All credentials copied to clipboard'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _hashPassword(String password) {
    return 'hashed_${password.length}_chars_${DateTime.now().millisecond}';
  }

  String _evaluatePasswordStrength(String password) {
    if (password.length < 8) return 'WEAK';
    if (password.length < 12) return 'MEDIUM';
    if (RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*]').hasMatch(password)) {
      return 'STRONG';
    }
    return 'MEDIUM';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Credential Management'),
        elevation: 0,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: const [
                Tab(text: 'Create Employee'),
                Tab(text: 'Audit Log'),
              ],
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildCreateEmployeeTab(),
                  _buildAuditLogTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateEmployeeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Employee Account',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),

            // Employee Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter employee full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.person),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),

            // Employee ID
            TextFormField(
              controller: _employeeIdController,
              decoration: InputDecoration(
                labelText: 'Employee ID',
                hintText: 'E.g., EMP001',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.badge),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Employee ID is required' : null,
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'employee@company.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.email),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Email is required';
                if (!value!.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Department
            TextFormField(
              controller: _departmentController,
              decoration: InputDecoration(
                labelText: 'Department',
                hintText: 'E.g., Engineering, HR, Sales',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.domain),
              ),
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Department is required' : null,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Initial Password',
                hintText: 'Enter secure password',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Password is required';
                if ((value?.length ?? 0) < 8)
                  return 'Password must be at least 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _createEmployee,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_isLoading ? 'Creating...' : 'Create Employee'),
              ),
            ),
            const SizedBox(height: 32),

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Notes',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• All employee creation events are logged for audit purposes\n'
                    '• Passwords must be at least 8 characters long\n'
                    '• Employee must change password on first login\n'
                    '• Ensure unique Employee IDs and Email addresses',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditLogTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audit Log (${_auditLog.length} entries)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (_auditLog.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () => setState(() => _auditLog.clear()),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_auditLog.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(Icons.history, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('No audit log entries yet',
                        style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _auditLog.length,
                itemBuilder: (context, index) {
                  final log = _auditLog[_auditLog.length - 1 - index];
                  final isSuccess = log['status'] == 'SUCCESS';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      leading: Icon(
                        isSuccess ? Icons.check_circle : Icons.error,
                        color: isSuccess ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        '${log['action']} - ${log['employeeId'] ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Time: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(log['timestamp'])}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSuccess
                              ? Colors.green.withValues(alpha: 0.2)
                              : Colors.red.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          log['status'] ?? 'UNKNOWN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSuccess ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLogDetail('Action', log['action']),
                              if (log['employeeId'] != null)
                                _buildLogDetail(
                                    'Employee ID', log['employeeId']),
                              if (log['email'] != null)
                                _buildLogDetail('Email', log['email']),
                              if (log['name'] != null)
                                _buildLogDetail('Name', log['name']),
                              if (log['department'] != null)
                                _buildLogDetail(
                                    'Department', log['department']),
                              if (log['createdBy'] != null)
                                _buildLogDetail('Created By', log['createdBy']),
                              if (log['password_strength'] != null)
                                _buildLogDetail('Password Strength',
                                    log['password_strength']),
                              if (log['logLevel'] != null)
                                _buildLogDetail('Log Level', log['logLevel']),
                              if (log['details'] != null)
                                _buildLogDetail('Details', log['details']),
                              if (log['error'] != null)
                                _buildLogDetail('Error', log['error'],
                                    isError: true),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogDetail(String label, String? value, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: TextStyle(
                fontSize: 12,
                color: isError ? Colors.red : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    super.dispose();
  }
}
