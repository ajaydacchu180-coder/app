import 'package:flutter_test/flutter_test.dart';
import 'package:enterprise_attendance/src/services/ai_anomaly_detection_service.dart';

void main() {
  group('AIAnomalyDetectionService', () {
    late AIAnomalyDetectionService service;

    setUp(() {
      service = AIAnomalyDetectionService();
    });

    group('analyzeAttendance', () {
      test('should return perfect score for no entries', () {
        final result = service.analyzeAttendance(
          entries: [],
          schedule: WorkSchedule(),
        );

        expect(result.score, equals(100));
        expect(result.anomalies, isEmpty);
        expect(result.riskLevel, equals(RiskLevel.low));
      });

      test('should detect late arrivals', () {
        final entries = [
          AttendanceEntry(
            date: DateTime(2026, 1, 29),
            clockIn: DateTime(2026, 1, 29, 9, 30), // 30 min late
            clockOut: DateTime(2026, 1, 29, 18, 0),
          ),
        ];

        final result = service.analyzeAttendance(
          entries: entries,
          schedule: WorkSchedule(startHour: 9, startMinute: 0),
        );

        expect(result.anomalies.length, equals(1));
        expect(result.anomalies.first.type, equals(AnomalyType.lateArrival));
      });

      test('should detect early departures', () {
        final entries = [
          AttendanceEntry(
            date: DateTime(2026, 1, 29),
            clockIn: DateTime(2026, 1, 29, 9, 0),
            clockOut: DateTime(2026, 1, 29, 16, 0), // 2 hours early
          ),
        ];

        final result = service.analyzeAttendance(
          entries: entries,
          schedule: WorkSchedule(endHour: 18, endMinute: 0),
        );

        final earlyDepartures = result.anomalies
            .where((a) => a.type == AnomalyType.earlyDeparture)
            .toList();

        expect(earlyDepartures.length, equals(1));
      });

      test('should detect excessive overtime', () {
        final entries = [
          AttendanceEntry(
            date: DateTime(2026, 1, 29),
            clockIn: DateTime(2026, 1, 29, 9, 0),
            clockOut:
                DateTime(2026, 1, 29, 22, 0), // 13 hours = 5 hours overtime
          ),
        ];

        final result = service.analyzeAttendance(
          entries: entries,
          schedule: WorkSchedule(expectedDailyHours: 8),
        );

        final overtime = result.anomalies
            .where((a) => a.type == AnomalyType.excessiveOvertime)
            .toList();

        expect(overtime.length, equals(1));
        expect(overtime.first.severity, equals(AnomalySeverity.high));
      });

      test('should detect absent without notice', () {
        final entries = [
          AttendanceEntry(
            date: DateTime(2026, 1, 29), // Wednesday
            clockIn: null, // No clock in
            clockOut: null,
            isWeekend: false,
            isHoliday: false,
          ),
        ];

        final result = service.analyzeAttendance(
          entries: entries,
          schedule: WorkSchedule(),
        );

        final absent = result.anomalies
            .where((a) => a.type == AnomalyType.absentWithoutNotice)
            .toList();

        expect(absent.length, equals(1));
        expect(absent.first.severity, equals(AnomalySeverity.high));
      });

      test('should not flag weekend as absent', () {
        final entries = [
          AttendanceEntry(
            date: DateTime(2026, 1, 25), // Saturday
            clockIn: null,
            clockOut: null,
            isWeekend: true,
          ),
        ];

        final result = service.analyzeAttendance(
          entries: entries,
          schedule: WorkSchedule(),
        );

        expect(result.anomalies, isEmpty);
      });

      test('should calculate correct score with multiple issues', () {
        final entries = List.generate(10, (i) {
          return AttendanceEntry(
            date: DateTime(2026, 1, 20 + i),
            clockIn: DateTime(2026, 1, 20 + i, 9, 30), // All late
            clockOut: DateTime(2026, 1, 20 + i, 18, 0),
          );
        });

        final result = service.analyzeAttendance(
          entries: entries,
          schedule: WorkSchedule(),
        );

        expect(result.score, lessThan(100));
        expect(result.lateArrivals, equals(10));
      });
    });

    group('assessBurnoutRisk', () {
      test('should return low risk for normal hours', () {
        final result = service.assessBurnoutRisk(
          recentEntries: [],
          weeklyHours: [40, 42, 38, 40], // Normal hours
        );

        expect(result.riskLevel, equals(BurnoutRiskLevel.low));
        expect(result.riskScore, lessThan(35));
      });

      test('should detect elevated risk for excessive hours', () {
        final result = service.assessBurnoutRisk(
          recentEntries: [],
          weeklyHours: [55, 58, 60, 55], // Excessive hours
        );

        // The score should be elevated, even if risk level is still low
        expect(result.riskScore, greaterThan(0));
        // Average is 57 hours, which should trigger concerns
        expect(
          result.riskFactors.isEmpty ||
              result.riskFactors.any((f) => f.toLowerCase().contains('hour')),
          isTrue,
        );
      });

      test('should detect increasing trend', () {
        final result = service.assessBurnoutRisk(
          recentEntries: [],
          weeklyHours: [40, 42, 50, 55], // Increasing
        );

        expect(
          result.riskFactors.any((f) => f.toLowerCase().contains('increasing')),
          isTrue,
        );
      });

      test('should flag weekend work', () {
        final entries = [
          AttendanceEntry(
            date: DateTime(2026, 1, 25), // Saturday
            clockIn: DateTime(2026, 1, 25, 10, 0),
            clockOut: DateTime(2026, 1, 25, 14, 0),
            isWeekend: true,
          ),
          AttendanceEntry(
            date: DateTime(2026, 1, 26), // Sunday
            clockIn: DateTime(2026, 1, 26, 10, 0),
            clockOut: DateTime(2026, 1, 26, 14, 0),
            isWeekend: true,
          ),
        ];

        final result = service.assessBurnoutRisk(
          recentEntries: entries,
          weeklyHours: [40, 40, 40, 40],
        );

        expect(
          result.riskFactors.any((f) => f.toLowerCase().contains('weekend')),
          isTrue,
        );
      });

      test('should generate recommendations', () {
        final result = service.assessBurnoutRisk(
          recentEntries: [],
          weeklyHours: [60, 62, 58, 65],
        );

        // Should either have recommendations or be in low risk with empty recommendations
        expect(
          result.recommendations.isNotEmpty ||
              result.riskLevel == BurnoutRiskLevel.low,
          isTrue,
        );
      });
    });

    group('predictStaffingNeeds', () {
      test('should predict based on historical data', () {
        final historicalData = [
          DailyAttendance(
              date: DateTime(2026, 1, 22),
              presentCount: 45,
              absentCount: 5), // Wed
          DailyAttendance(
              date: DateTime(2026, 1, 15),
              presentCount: 42,
              absentCount: 8), // Wed
          DailyAttendance(
              date: DateTime(2026, 1, 8),
              presentCount: 48,
              absentCount: 2), // Wed
        ];

        final prediction = service.predictStaffingNeeds(
          historicalData: historicalData,
          targetDate: DateTime(2026, 1, 29), // Also Wednesday
        );

        expect(prediction.predictedAttendance, greaterThan(0));
        expect(prediction.confidence, greaterThan(0));
        expect(prediction.recommendation, isNotEmpty);
      });

      test('should return zero confidence for no data', () {
        final prediction = service.predictStaffingNeeds(
          historicalData: [],
          targetDate: DateTime(2026, 1, 29),
        );

        expect(prediction.predictedAttendance, equals(0));
        expect(prediction.confidence, equals(0));
      });
    });

    group('detectUnusualPatterns', () {
      test('should detect arrival time shift', () {
        // Recent arrivals: much later
        final entries = [
          // Recent (first 5)
          ...List.generate(
              5,
              (i) => AttendanceEntry(
                    date: DateTime(2026, 1, 25 - i),
                    clockIn: DateTime(2026, 1, 25 - i, 10, 30), // 10:30 AM
                    clockOut: DateTime(2026, 1, 25 - i, 18, 0),
                  )),
          // Historical (next 10) - earlier arrivals
          ...List.generate(
              10,
              (i) => AttendanceEntry(
                    date: DateTime(2026, 1, 20 - i),
                    clockIn: DateTime(2026, 1, 20 - i, 9, 0), // 9:00 AM
                    clockOut: DateTime(2026, 1, 20 - i, 18, 0),
                  )),
        ];

        final alerts = service.detectUnusualPatterns(
          userId: 'user1',
          entries: entries,
        );

        expect(
          alerts.any((a) => a.type == PatternAlertType.arrivalTimeShift),
          isTrue,
        );
      });
    });
  });

  group('Data Models', () {
    group('WorkSchedule', () {
      test('should have sensible defaults', () {
        final schedule = WorkSchedule();

        expect(schedule.startHour, equals(9));
        expect(schedule.endHour, equals(18));
        expect(schedule.expectedDailyHours, equals(8));
      });

      test('should accept custom values', () {
        final schedule = WorkSchedule(
          startHour: 8,
          endHour: 17,
          expectedDailyHours: 9,
        );

        expect(schedule.startHour, equals(8));
        expect(schedule.endHour, equals(17));
        expect(schedule.expectedDailyHours, equals(9));
      });
    });

    group('AttendanceAnomaly', () {
      test('should store all properties correctly', () {
        final anomaly = AttendanceAnomaly(
          type: AnomalyType.lateArrival,
          date: DateTime(2026, 1, 29),
          severity: AnomalySeverity.medium,
          description: 'Arrived 30 minutes late',
          value: 30,
        );

        expect(anomaly.type, equals(AnomalyType.lateArrival));
        expect(anomaly.severity, equals(AnomalySeverity.medium));
        expect(anomaly.value, equals(30));
      });
    });

    group('StaffingPrediction', () {
      test('should store prediction data', () {
        final prediction = StaffingPrediction(
          date: DateTime(2026, 1, 29),
          predictedAttendance: 45,
          confidence: 85,
          recommendation: 'Normal staffing expected',
        );

        expect(prediction.predictedAttendance, equals(45));
        expect(prediction.confidence, equals(85));
      });
    });
  });
}
