import 'package:device_info_plus/device_info_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// AuditLoggingService provides comprehensive device information
/// and audit logging capabilities.
///
/// This addresses the Project Manager's requirements for:
/// - Complete audit logging with real device/IP info
/// - Security event tracking
/// - Login/logout event logging
class AuditLoggingService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final NetworkInfo _networkInfo = NetworkInfo();
  String _appVersion = 'unknown';

  AuditLoggingService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = info.version;
    } catch (_) {
      // ignore and keep fallback
    }
  }

  /// Get comprehensive device information
  Future<DeviceDetails> getDeviceDetails() async {
    try {
      if (kIsWeb) {
        return await _getWebDeviceInfo();
      }

      // Use defaultTargetPlatform for native platforms
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          return await _getAndroidDeviceInfo();
        case TargetPlatform.iOS:
          return await _getIOSDeviceInfo();
        case TargetPlatform.windows:
          return await _getWindowsDeviceInfo();
        case TargetPlatform.macOS:
          return await _getMacOSDeviceInfo();
        case TargetPlatform.linux:
          return await _getLinuxDeviceInfo();
        default:
          return DeviceDetails(
            deviceType: 'Unknown',
            deviceName: 'Unknown Device',
            osVersion: 'Unknown',
            appVersion: _appVersion,
          );
      }
    } catch (e) {
      return DeviceDetails(
        deviceType: 'Error',
        deviceName: 'Could not detect device',
        osVersion: 'Unknown',
  appVersion: _appVersion,
      );
    }
  }

  Future<DeviceDetails> _getAndroidDeviceInfo() async {
    final info = await _deviceInfo.androidInfo;
    return DeviceDetails(
      deviceType: 'Android',
      deviceName: '${info.manufacturer} ${info.model}',
      osVersion: 'Android ${info.version.release} (SDK ${info.version.sdkInt})',
      deviceId: info.id,
  appVersion: _appVersion,
      additionalInfo: {
        'brand': info.brand,
        'device': info.device,
        'fingerprint': info.fingerprint,
        'isPhysicalDevice': info.isPhysicalDevice,
      },
    );
  }

  Future<DeviceDetails> _getIOSDeviceInfo() async {
    final info = await _deviceInfo.iosInfo;
    return DeviceDetails(
      deviceType: 'iOS',
      deviceName: info.name,
      osVersion: '${info.systemName} ${info.systemVersion}',
      deviceId: info.identifierForVendor,
  appVersion: _appVersion,
      additionalInfo: {
        'model': info.model,
        'utsname': info.utsname.machine,
        'isPhysicalDevice': info.isPhysicalDevice,
      },
    );
  }

  Future<DeviceDetails> _getWindowsDeviceInfo() async {
    final info = await _deviceInfo.windowsInfo;
    return DeviceDetails(
      deviceType: 'Windows',
      deviceName: info.computerName,
      osVersion: 'Windows ${info.productName} (${info.displayVersion})',
      deviceId: info.deviceId,
  appVersion: _appVersion,
      additionalInfo: {
        'numberOfCores': info.numberOfCores,
        'systemMemoryInMegabytes': info.systemMemoryInMegabytes,
      },
    );
  }

  Future<DeviceDetails> _getMacOSDeviceInfo() async {
    final info = await _deviceInfo.macOsInfo;
    return DeviceDetails(
      deviceType: 'macOS',
      deviceName: info.computerName,
      osVersion: 'macOS ${info.osRelease}',
      deviceId: info.systemGUID,
  appVersion: _appVersion,
      additionalInfo: {
        'model': info.model,
        'arch': info.arch,
        'kernelVersion': info.kernelVersion,
      },
    );
  }

  Future<DeviceDetails> _getLinuxDeviceInfo() async {
    final info = await _deviceInfo.linuxInfo;
    return DeviceDetails(
      deviceType: 'Linux',
      deviceName: info.prettyName,
      osVersion: info.versionId ?? 'Unknown',
      deviceId: info.machineId,
  appVersion: _appVersion,
      additionalInfo: {
        'name': info.name,
        'id': info.id,
      },
    );
  }

  Future<DeviceDetails> _getWebDeviceInfo() async {
    final info = await _deviceInfo.webBrowserInfo;
    return DeviceDetails(
      deviceType: 'Web',
      deviceName: info.browserName.name,
      osVersion: info.platform ?? 'Unknown',
      appVersion: '1.0.0',
      additionalInfo: {
        'userAgent': info.userAgent,
        'vendor': info.vendor,
        'language': info.language,
      },
    );
  }

  /// Get the device's IP address
  Future<String> getIPAddress() async {
    try {
      // Try to get WiFi IP first (works on most platforms)
      final wifiIP = await _networkInfo.getWifiIP();
      if (wifiIP != null && wifiIP.isNotEmpty) {
        return wifiIP;
      }

      // On web, we can't access network interfaces directly
      if (kIsWeb) {
        return 'Web Client';
      }

      // Fallback for native: try to get IP via network interfaces
      // This uses dart:io which only works on native platforms
      return await _getNativeIPAddress();
    } catch (e) {
      return 'Unknown';
    }
  }

  /// Native-only IP address detection using dart:io
  Future<String> _getNativeIPAddress() async {
    // This will be stubbed on web via conditional import
    // For now, return Unknown as fallback
    return 'Unknown';
  }

  /// Get WiFi network name (SSID)
  Future<String?> getWifiName() async {
    try {
      return await _networkInfo.getWifiName();
    } catch (e) {
      return null;
    }
  }

  /// Create a comprehensive audit log entry
  Future<AuditLogEntry> createAuditLog({
    required String action,
    required String userId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    final deviceDetails = await getDeviceDetails();
    final ipAddress = await getIPAddress();

    return AuditLogEntry(
      action: action,
      userId: userId,
      timestamp: DateTime.now().toUtc(),
      ipAddress: ipAddress,
      deviceDetails: deviceDetails,
      description: description,
      metadata: metadata,
    );
  }

  /// Log a login event
  Future<AuditLogEntry> logLogin({
    required String userId,
    required bool success,
    String? failureReason,
  }) async {
    return createAuditLog(
      action: success ? 'USER_LOGIN_SUCCESS' : 'USER_LOGIN_FAILED',
      userId: userId,
      description: success
          ? 'User logged in successfully'
          : 'Login failed: ${failureReason ?? 'Unknown reason'}',
      metadata: {
        'success': success,
        if (failureReason != null) 'failureReason': failureReason,
      },
    );
  }

  /// Log a logout event
  Future<AuditLogEntry> logLogout({
    required String userId,
  }) async {
    return createAuditLog(
      action: 'USER_LOGOUT',
      userId: userId,
      description: 'User logged out',
    );
  }

  /// Log a password change event
  Future<AuditLogEntry> logPasswordChange({
    required String userId,
    required bool success,
  }) async {
    return createAuditLog(
      action: success ? 'PASSWORD_CHANGE_SUCCESS' : 'PASSWORD_CHANGE_FAILED',
      userId: userId,
      description: success
          ? 'Password changed successfully'
          : 'Password change attempt failed',
      metadata: {'success': success},
    );
  }

  /// Log a 2FA related event
  Future<AuditLogEntry> log2FAEvent({
    required String userId,
    required String eventType, // 'ENABLED', 'DISABLED', 'VERIFIED', 'FAILED'
  }) async {
    return createAuditLog(
      action: '2FA_$eventType',
      userId: userId,
      description: '2FA $eventType',
      metadata: {'eventType': eventType},
    );
  }

  /// Log attendance event
  Future<AuditLogEntry> logAttendance({
    required String userId,
    required String
        eventType, // 'CHECK_IN', 'CHECK_OUT', 'BREAK_START', 'BREAK_END'
    String? location,
  }) async {
    return createAuditLog(
      action: 'ATTENDANCE_$eventType',
      userId: userId,
      description: 'Attendance: $eventType',
      metadata: {
        'eventType': eventType,
        if (location != null) 'location': location,
      },
    );
  }
}

/// Device details model
class DeviceDetails {
  final String deviceType;
  final String deviceName;
  final String osVersion;
  final String? deviceId;
  final String appVersion;
  final Map<String, dynamic>? additionalInfo;

  DeviceDetails({
    required this.deviceType,
    required this.deviceName,
    required this.osVersion,
    this.deviceId,
    required this.appVersion,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() => {
        'deviceType': deviceType,
        'deviceName': deviceName,
        'osVersion': osVersion,
        if (deviceId != null) 'deviceId': deviceId,
        'appVersion': appVersion,
        if (additionalInfo != null) 'additionalInfo': additionalInfo,
      };

  String get displayString => '$deviceName on $osVersion';
}

/// Audit log entry model
class AuditLogEntry {
  final String action;
  final String userId;
  final DateTime timestamp;
  final String ipAddress;
  final DeviceDetails deviceDetails;
  final String? description;
  final Map<String, dynamic>? metadata;

  AuditLogEntry({
    required this.action,
    required this.userId,
    required this.timestamp,
    required this.ipAddress,
    required this.deviceDetails,
    this.description,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'ipAddress': ipAddress,
        'device': deviceDetails.toJson(),
        if (description != null) 'description': description,
        if (metadata != null) 'metadata': metadata,
      };
}
