import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../services/api_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Login history from API
  List<LoginHistoryEntry> _loginHistory = [];
  bool _showLoginHistory = false;
  bool _isLoadingHistory = false;
  bool _is2FAEnabled = false;
  bool _isTogglin2FA = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    final authState = ref.read(authNotifierProvider);
    if (!authState.isAuthenticated) return;

    final userId = authState.user!.id;

    try {
      // Check 2FA status
      final apiService = ref.read(apiServiceProvider);
      final is2FA = await apiService.get2FAStatus(userId);

      // Check biometric availability
      final biometricService = ref.read(biometricAuthProvider);
      final canUseBiometric = await biometricService.canCheckBiometrics();
      final isBiometricEnabled =
          await biometricService.isBiometricLoginEnabled();

      if (mounted) {
        setState(() {
          _is2FAEnabled = is2FA;
          _isBiometricAvailable = canUseBiometric;
          _isBiometricEnabled = isBiometricEnabled;
        });
      }
    } catch (e) {
      // Silently fail - settings will use defaults
      debugPrint('Failed to load security settings: $e');
    }
  }

  Future<void> _loadLoginHistory() async {
    if (_isLoadingHistory) return;

    setState(() => _isLoadingHistory = true);

    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user!.id;
      final apiService = ref.read(apiServiceProvider);
      final history = await apiService.getLoginHistory(userId);

      if (mounted) {
        setState(() {
          _loginHistory = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load login history: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() => _isLoggingOut = true);

      try {
        final authState = ref.read(authNotifierProvider);
        final userId = authState.user?.id ?? '';

        // Log the logout event with real device/IP info
        await _logLogoutEvent();

        // Call logout on API
        final apiService = ref.read(apiServiceProvider);
        await apiService.logout(userId);

        // Clear local auth state
        ref.read(authNotifierProvider.notifier).logout();

        // Clear secure storage
        final biometricService = ref.read(biometricAuthProvider);
        await biometricService.clearAllCredentials();

        // Navigate to login screen
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        }
      } catch (e) {
        setState(() => _isLoggingOut = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _logLogoutEvent() async {
    try {
      final authState = ref.read(authNotifierProvider);
      final userId = authState.user?.id ?? '';

      // Get real device info and IP
      final auditService = ref.read(auditLoggingProvider);
      final logEntry = await auditService.logLogout(userId: userId);

      // Send to backend
      final apiService = ref.read(apiServiceProvider);
      await apiService.sendAuditLog(logEntry);
    } catch (e) {
      debugPrint('Failed to log logout event: $e');
    }
  }

  void _changePassword() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool showCurrentPassword = false;
    bool showNewPassword = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Change Password'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: !showCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(showCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(
                          () => showCurrentPassword = !showCurrentPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: !showNewPassword,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Min 8 characters',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(showNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => showNewPassword = !showNewPassword),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Password strength indicator
                _PasswordStrengthIndicator(
                  password: newPasswordController.text,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabled: !isLoading,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () => _handlePasswordChange(
                        context: dialogContext,
                        currentPassword: currentPasswordController.text,
                        newPassword: newPasswordController.text,
                        confirmPassword: confirmPasswordController.text,
                        setState: setState,
                        setLoading: (loading) =>
                            setState(() => isLoading = loading),
                      ),
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Change'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handlePasswordChange({
    required BuildContext context,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
    required void Function(void Function()) setState,
    required void Function(bool) setLoading,
  }) async {
    // Validation
    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('All fields are required'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPassword.length < 8) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 8 characters'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password strength
    if (!_isPasswordStrong(newPassword)) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content:
              Text('Password must contain uppercase, lowercase, and numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setLoading(true);

    try {
      final authState = ref.read(authNotifierProvider);
      final apiService = ref.read(apiServiceProvider);

      await apiService.changePassword(
        userId: authState.user!.id,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setLoading(false);
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text('Failed to change password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  bool _isPasswordStrong(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  Future<void> _toggle2FA(bool enable) async {
    if (_isTogglin2FA) return;

    if (enable) {
      // Setup 2FA
      await _setup2FA();
    } else {
      // Disable 2FA - requires verification
      await _disable2FA();
    }
  }

  Future<void> _setup2FA() async {
    setState(() => _isTogglin2FA = true);

    try {
      final authState = ref.read(authNotifierProvider);
      final apiService = ref.read(apiServiceProvider);

      // Get 2FA setup data
      final setupData = await apiService.setup2FA(
        authState.user!.id,
        authState.user!.id, // Using id as email for mock
      );

      if (mounted) {
        // Show QR code and verification dialog
        await _show2FASetupDialog(
          secret: setupData['secret'],
          qrData: setupData['qrCodeData'],
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to setup 2FA: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTogglin2FA = false);
      }
    }
  }

  Future<void> _show2FASetupDialog({
    required String secret,
    required String qrData,
  }) async {
    final codeController = TextEditingController();
    bool isVerifying = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Setup 2FA'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scan this QR code with your authenticator app:',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // QR Code placeholder
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.qr_code_2, size: 100, color: Colors.grey),
                        Text('QR Code', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Or enter this secret manually:\n$secret',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: codeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit code',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    counterText: '',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying
                  ? null
                  : () async {
                      setState(() => isVerifying = true);
                      try {
                        final authState = ref.read(authNotifierProvider);
                        final apiService = ref.read(apiServiceProvider);

                        final result = await apiService.verify2FASetup(
                          authState.user!.id,
                          codeController.text,
                        );

                        if (result['success'] == true) {
                          Navigator.pop(context);
                          this.setState(() => _is2FAEnabled = true);

                          // Show backup codes
                          _showBackupCodes(result['backupCodes'] ?? []);
                        }
                      } catch (e) {
                        setState(() => isVerifying = false);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text('Verification failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
              child: isVerifying
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Verify & Enable'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupCodes(List<dynamic> codes) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.save, color: Colors.green),
            SizedBox(width: 8),
            Text('Backup Codes'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Save these backup codes securely. Each can only be used once.',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: codes
                    .map((code) => Text(
                          code.toString(),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 16,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('I\'ve Saved These'),
          ),
        ],
      ),
    );
  }

  Future<void> _disable2FA() async {
    final codeController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your 2FA code to disable:'),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                counterText: '',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Disable'),
          ),
        ],
      ),
    );

    if (confirmed == true && codeController.text.isNotEmpty) {
      try {
        final authState = ref.read(authNotifierProvider);
        final apiService = ref.read(apiServiceProvider);

        await apiService.disable2FA(authState.user!.id, codeController.text);

        setState(() => _is2FAEnabled = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('2FA disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to disable 2FA: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _toggleBiometric(bool enable) async {
    final biometricService = ref.read(biometricAuthProvider);

    if (enable) {
      // Authenticate first
      final result = await biometricService.authenticate(
        reason: 'Authenticate to enable biometric login',
      );

      if (result.success) {
        await biometricService.enableBiometricLogin();
        setState(() => _isBiometricEnabled = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric login enabled'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await biometricService.disableBiometricLogin();
      setState(() => _isBiometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric login disabled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.user?.name ?? 'Guest';
    final userEmail = authState.user?.id ?? 'not-logged-in';
    final userRole = authState.user?.role.name.toUpperCase() ?? 'GUEST';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(context, userName, userEmail, userRole),
            const SizedBox(height: 24),

            // Security Settings Section
            _buildSectionHeader('Security Settings'),
            const SizedBox(height: 12),

            // Change Password
            _buildSettingsTile(
              icon: Icons.lock,
              title: 'Change Password',
              subtitle: 'Update your password',
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _changePassword,
            ),
            const SizedBox(height: 8),

            // Two-Factor Authentication
            _buildSettingsTile(
              icon: Icons.security,
              title: 'Two-Factor Authentication',
              subtitle: _is2FAEnabled ? 'Enabled' : 'Add extra security',
              trailing: _isTogglin2FA
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _is2FAEnabled,
                      onChanged: _toggle2FA,
                    ),
            ),
            const SizedBox(height: 8),

            // Biometric Login
            if (_isBiometricAvailable)
              _buildSettingsTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Use Face ID or fingerprint',
                trailing: Switch(
                  value: _isBiometricEnabled,
                  onChanged: _toggleBiometric,
                ),
              ),
            const SizedBox(height: 24),

            // Login History Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Login History'),
                TextButton(
                  onPressed: () {
                    setState(() => _showLoginHistory = !_showLoginHistory);
                    if (_showLoginHistory && _loginHistory.isEmpty) {
                      _loadLoginHistory();
                    }
                  },
                  child: Text(_showLoginHistory ? 'Hide' : 'Show'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_showLoginHistory) _buildLoginHistoryList(),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoggingOut ? null : _logout,
                icon: _isLoggingOut
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.logout),
                label: Text(_isLoggingOut ? 'Logging out...' : 'Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Security Info Box
            _buildSecurityInfoBox(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, String userName,
      String userEmail, String userRole) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).primaryColor,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty
                      ? userName.substring(0, 1).toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              userName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              userEmail,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                userRole,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _is2FAEnabled ? Icons.verified_user : Icons.shield_outlined,
                  size: 16,
                  color: _is2FAEnabled ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _is2FAEnabled ? '2FA Enabled' : '2FA Not Enabled',
                  style: TextStyle(
                    color: _is2FAEnabled ? Colors.green : Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: trailing,
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildLoginHistoryList() {
    if (_isLoadingHistory) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loginHistory.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No login history available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _loginHistory.length,
      itemBuilder: (context, index) {
        final login = _loginHistory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              login.success ? Icons.login : Icons.error_outline,
              color: login.success ? Colors.green : Colors.red,
            ),
            title: Text(login.device),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_formatDateTime(login.timestamp)),
                Text('IP: ${login.ip}'),
              ],
            ),
            trailing: login.success
                ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                : const Icon(Icons.warning, color: Colors.red, size: 20),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} minutes ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${dt.day}/${dt.month}/${dt.year}';
    }
  }

  Widget _buildSecurityInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security Tips',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Enable 2FA for maximum security\n'
            '• Use biometric login for convenience\n'
            '• Review login history regularly\n'
            '• Change password every 90 days\n'
            '• Never share your credentials',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const _PasswordStrengthIndicator({required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final color = strength < 0.3
        ? Colors.red
        : strength < 0.6
            ? Colors.orange
            : Colors.green;
    final label = strength < 0.3
        ? 'Weak'
        : strength < 0.6
            ? 'Medium'
            : 'Strong';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey.shade300,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          password.isEmpty ? '' : 'Strength: $label',
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  double _calculateStrength(String password) {
    if (password.isEmpty) return 0;

    double strength = 0;
    if (password.length >= 8) strength += 0.25;
    if (password.length >= 12) strength += 0.15;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength += 0.2;
    if (RegExp(r'[a-z]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[0-9]').hasMatch(password)) strength += 0.15;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength += 0.1;

    return strength.clamp(0.0, 1.0);
  }
}
