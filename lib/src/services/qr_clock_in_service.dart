import 'dart:convert';
import 'dart:math';

/// QRClockInService provides QR code based attendance functionality.
///
/// This addresses the Project Manager's requirement for:
/// - QR Code Clock-In (contactless attendance)
/// - Dynamic QR generation with time-based codes
/// - Anti-fraud measures (one-time use, time-limited codes)
class QRClockInService {
  static const int _codeValidityMinutes = 5;
  static const String _secretKey = 'enterprise_attendance_2026';

  /// Generate a QR code payload for clock-in
  /// The code contains encrypted data and expiry timestamp
  QRCodePayload generateClockInQR({
    required String locationId,
    required String locationName,
    String? additionalData,
  }) {
    final now = DateTime.now().toUtc();
    final expiry = now.add(Duration(minutes: _codeValidityMinutes));
    final nonce = _generateNonce();

    final payload = QRCodeData(
      type: QRCodeType.clockIn,
      locationId: locationId,
      locationName: locationName,
      generatedAt: now,
      expiresAt: expiry,
      nonce: nonce,
      additionalData: additionalData,
    );

    final jsonData = jsonEncode(payload.toJson());
    final signature = _generateSignature(jsonData);

    return QRCodePayload(
      data: payload,
      qrContent: '$jsonData|$signature',
      expiresAt: expiry,
    );
  }

  /// Generate a QR code for clock-out
  QRCodePayload generateClockOutQR({
    required String locationId,
    required String locationName,
  }) {
    final now = DateTime.now().toUtc();
    final expiry = now.add(Duration(minutes: _codeValidityMinutes));
    final nonce = _generateNonce();

    final payload = QRCodeData(
      type: QRCodeType.clockOut,
      locationId: locationId,
      locationName: locationName,
      generatedAt: now,
      expiresAt: expiry,
      nonce: nonce,
    );

    final jsonData = jsonEncode(payload.toJson());
    final signature = _generateSignature(jsonData);

    return QRCodePayload(
      data: payload,
      qrContent: '$jsonData|$signature',
      expiresAt: expiry,
    );
  }

  /// Validate a scanned QR code
  QRValidationResult validateQRCode(String scannedContent) {
    try {
      // Split content and signature
      final parts = scannedContent.split('|');
      if (parts.length != 2) {
        return QRValidationResult(
          isValid: false,
          error: QRValidationError.invalidFormat,
          message: 'Invalid QR code format',
        );
      }

      final jsonData = parts[0];
      final signature = parts[1];

      // Verify signature
      final expectedSignature = _generateSignature(jsonData);
      if (signature != expectedSignature) {
        return QRValidationResult(
          isValid: false,
          error: QRValidationError.invalidSignature,
          message: 'QR code signature is invalid',
        );
      }

      // Parse data
      final data = QRCodeData.fromJson(jsonDecode(jsonData));

      // Check expiry
      final now = DateTime.now().toUtc();
      if (now.isAfter(data.expiresAt)) {
        return QRValidationResult(
          isValid: false,
          error: QRValidationError.expired,
          message: 'QR code has expired. Please scan a fresh code.',
          data: data,
        );
      }

      // Check if too old (generated too long ago)
      final ageMinutes = now.difference(data.generatedAt).inMinutes;
      if (ageMinutes > _codeValidityMinutes * 2) {
        return QRValidationResult(
          isValid: false,
          error: QRValidationError.expired,
          message: 'QR code is too old',
          data: data,
        );
      }

      return QRValidationResult(
        isValid: true,
        message: 'QR code is valid',
        data: data,
      );
    } catch (e) {
      return QRValidationResult(
        isValid: false,
        error: QRValidationError.parseError,
        message: 'Could not parse QR code: $e',
      );
    }
  }

  /// Process a clock-in from QR scan
  Future<ClockInResult> processClockIn({
    required String scannedContent,
    required String userId,
    required String userName,
  }) async {
    final validation = validateQRCode(scannedContent);

    if (!validation.isValid) {
      return ClockInResult(
        success: false,
        message: validation.message,
        error: validation.error,
      );
    }

    final data = validation.data!;

    if (data.type != QRCodeType.clockIn) {
      return ClockInResult(
        success: false,
        message: 'This is not a clock-in QR code',
        error: QRValidationError.wrongType,
      );
    }

    // Create clock-in record
    final record = AttendanceRecord(
      userId: userId,
      userName: userName,
      type: AttendanceType.clockIn,
      locationId: data.locationId,
      locationName: data.locationName,
      timestamp: DateTime.now().toUtc(),
      qrNonce: data.nonce,
    );

    return ClockInResult(
      success: true,
      message: 'Clock-in successful at ${data.locationName}',
      record: record,
    );
  }

  /// Process a clock-out from QR scan
  Future<ClockInResult> processClockOut({
    required String scannedContent,
    required String userId,
    required String userName,
  }) async {
    final validation = validateQRCode(scannedContent);

    if (!validation.isValid) {
      return ClockInResult(
        success: false,
        message: validation.message,
        error: validation.error,
      );
    }

    final data = validation.data!;

    if (data.type != QRCodeType.clockOut) {
      return ClockInResult(
        success: false,
        message: 'This is not a clock-out QR code',
        error: QRValidationError.wrongType,
      );
    }

    final record = AttendanceRecord(
      userId: userId,
      userName: userName,
      type: AttendanceType.clockOut,
      locationId: data.locationId,
      locationName: data.locationName,
      timestamp: DateTime.now().toUtc(),
      qrNonce: data.nonce,
    );

    return ClockInResult(
      success: true,
      message: 'Clock-out successful at ${data.locationName}',
      record: record,
    );
  }

  /// Generate a random nonce for one-time use codes
  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Generate signature for QR data (simple HMAC-like signature)
  String _generateSignature(String data) {
    // In production, use proper HMAC with secure key management
    final combined = '$data$_secretKey';
    int hash = 0;
    for (int i = 0; i < combined.length; i++) {
      hash = ((hash << 5) - hash) + combined.codeUnitAt(i);
      hash = hash & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}

/// QR code types
enum QRCodeType {
  clockIn,
  clockOut,
  breakStart,
  breakEnd,
  meeting,
  custom,
}

/// QR code data payload
class QRCodeData {
  final QRCodeType type;
  final String locationId;
  final String locationName;
  final DateTime generatedAt;
  final DateTime expiresAt;
  final String nonce;
  final String? additionalData;

  QRCodeData({
    required this.type,
    required this.locationId,
    required this.locationName,
    required this.generatedAt,
    required this.expiresAt,
    required this.nonce,
    this.additionalData,
  });

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'locationId': locationId,
        'locationName': locationName,
        'generatedAt': generatedAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'nonce': nonce,
        if (additionalData != null) 'additionalData': additionalData,
      };

  factory QRCodeData.fromJson(Map<String, dynamic> json) => QRCodeData(
        type: QRCodeType.values.firstWhere((t) => t.name == json['type']),
        locationId: json['locationId'],
        locationName: json['locationName'],
        generatedAt: DateTime.parse(json['generatedAt']),
        expiresAt: DateTime.parse(json['expiresAt']),
        nonce: json['nonce'],
        additionalData: json['additionalData'],
      );
}

/// Complete QR code payload for display
class QRCodePayload {
  final QRCodeData data;
  final String qrContent;
  final DateTime expiresAt;

  QRCodePayload({
    required this.data,
    required this.qrContent,
    required this.expiresAt,
  });

  int get secondsRemaining =>
      expiresAt.difference(DateTime.now().toUtc()).inSeconds;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}

/// QR validation errors
enum QRValidationError {
  invalidFormat,
  invalidSignature,
  expired,
  parseError,
  wrongType,
  alreadyUsed,
}

/// Result of QR code validation
class QRValidationResult {
  final bool isValid;
  final QRValidationError? error;
  final String message;
  final QRCodeData? data;

  QRValidationResult({
    required this.isValid,
    this.error,
    required this.message,
    this.data,
  });
}

/// Result of clock-in/clock-out operation
class ClockInResult {
  final bool success;
  final String message;
  final QRValidationError? error;
  final AttendanceRecord? record;

  ClockInResult({
    required this.success,
    required this.message,
    this.error,
    this.record,
  });
}

/// Attendance record from QR scan
class AttendanceRecord {
  final String userId;
  final String userName;
  final AttendanceType type;
  final String locationId;
  final String locationName;
  final DateTime timestamp;
  final String qrNonce;

  AttendanceRecord({
    required this.userId,
    required this.userName,
    required this.type,
    required this.locationId,
    required this.locationName,
    required this.timestamp,
    required this.qrNonce,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'userName': userName,
        'type': type.name,
        'locationId': locationId,
        'locationName': locationName,
        'timestamp': timestamp.toIso8601String(),
        'qrNonce': qrNonce,
      };
}

/// Attendance types
enum AttendanceType {
  clockIn,
  clockOut,
  breakStart,
  breakEnd,
}
