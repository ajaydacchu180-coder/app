import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_attendance/src/services/qr_clock_in_service.dart';

void main() {
  group('QRClockInService', () {
    late QRClockInService service;

    setUp(() {
      service = QRClockInService();
    });

    group('generateClockInQR', () {
      test('should generate valid clock-in QR code', () {
        final result = service.generateClockInQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        expect(result.data.type, equals(QRCodeType.clockIn));
        expect(result.data.locationId, equals('loc1'));
        expect(result.data.locationName, equals('Main Office'));
        expect(result.qrContent, isNotEmpty);
        expect(result.isExpired, isFalse);
      });

      test('should generate QR with additional data', () {
        final result = service.generateClockInQR(
          locationId: 'loc1',
          locationName: 'Main Office',
          additionalData: 'Floor 5',
        );

        expect(result.data.additionalData, equals('Floor 5'));
      });

      test('should have expiry time in future', () {
        final result = service.generateClockInQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        expect(result.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
        expect(result.secondsRemaining, greaterThan(0));
      });
    });

    group('generateClockOutQR', () {
      test('should generate valid clock-out QR code', () {
        final result = service.generateClockOutQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        expect(result.data.type, equals(QRCodeType.clockOut));
        expect(result.data.locationId, equals('loc1'));
      });
    });

    group('validateQRCode', () {
      test('should validate correct QR code', () {
        final qr = service.generateClockInQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        final result = service.validateQRCode(qr.qrContent);

        expect(result.isValid, isTrue);
        expect(result.data, isNotNull);
        expect(result.data!.locationId, equals('loc1'));
      });

      test('should reject invalid format', () {
        final result = service.validateQRCode('invalid-data');

        expect(result.isValid, isFalse);
        expect(result.error, equals(QRValidationError.invalidFormat));
      });

      test('should reject tampered signature', () {
        final qr = service.generateClockInQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        // Tamper with the signature
        final parts = qr.qrContent.split('|');
        final tamperedContent = '${parts[0]}|wrongsignature';

        final result = service.validateQRCode(tamperedContent);

        expect(result.isValid, isFalse);
        expect(result.error, equals(QRValidationError.invalidSignature));
      });
    });

    group('processClockIn', () {
      test('should process valid clock-in', () async {
        final qr = service.generateClockInQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        final result = await service.processClockIn(
          scannedContent: qr.qrContent,
          userId: 'user1',
          userName: 'John Doe',
        );

        expect(result.success, isTrue);
        expect(result.record, isNotNull);
        expect(result.record!.userId, equals('user1'));
        expect(result.record!.type, equals(AttendanceType.clockIn));
      });

      test('should reject clock-out QR for clock-in', () async {
        final qr = service.generateClockOutQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        final result = await service.processClockIn(
          scannedContent: qr.qrContent,
          userId: 'user1',
          userName: 'John Doe',
        );

        expect(result.success, isFalse);
        expect(result.error, equals(QRValidationError.wrongType));
      });
    });

    group('processClockOut', () {
      test('should process valid clock-out', () async {
        final qr = service.generateClockOutQR(
          locationId: 'loc1',
          locationName: 'Main Office',
        );

        final result = await service.processClockOut(
          scannedContent: qr.qrContent,
          userId: 'user1',
          userName: 'John Doe',
        );

        expect(result.success, isTrue);
        expect(result.record, isNotNull);
        expect(result.record!.type, equals(AttendanceType.clockOut));
      });
    });
  });

  group('QRCodeData', () {
    test('should serialize to JSON correctly', () {
      final data = QRCodeData(
        type: QRCodeType.clockIn,
        locationId: 'loc1',
        locationName: 'Main Office',
        generatedAt: DateTime.utc(2026, 1, 29, 10, 0, 0),
        expiresAt: DateTime.utc(2026, 1, 29, 10, 5, 0),
        nonce: 'abc123',
      );

      final json = data.toJson();

      expect(json['type'], equals('clockIn'));
      expect(json['locationId'], equals('loc1'));
      expect(json['locationName'], equals('Main Office'));
      expect(json['nonce'], equals('abc123'));
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'type': 'clockOut',
        'locationId': 'loc2',
        'locationName': 'Branch Office',
        'generatedAt': '2026-01-29T10:00:00.000Z',
        'expiresAt': '2026-01-29T10:05:00.000Z',
        'nonce': 'xyz789',
      };

      final data = QRCodeData.fromJson(json);

      expect(data.type, equals(QRCodeType.clockOut));
      expect(data.locationId, equals('loc2'));
      expect(data.locationName, equals('Branch Office'));
    });
  });

  group('AttendanceRecord', () {
    test('should create and serialize correctly', () {
      final record = AttendanceRecord(
        userId: 'user1',
        userName: 'John Doe',
        type: AttendanceType.clockIn,
        locationId: 'loc1',
        locationName: 'Main Office',
        timestamp: DateTime.utc(2026, 1, 29, 9, 0, 0),
        qrNonce: 'nonce123',
      );

      final json = record.toJson();

      expect(json['userId'], equals('user1'));
      expect(json['userName'], equals('John Doe'));
      expect(json['type'], equals('clockIn'));
      expect(json['locationId'], equals('loc1'));
    });
  });
}
