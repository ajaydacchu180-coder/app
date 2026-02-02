import 'dart:math';

/// AIAnomalyDetectionService provides intelligent attendance and productivity analysis.
///
/// This addresses the Project Manager's requirements for:
/// - Intelligent Attendance Anomaly Detection
/// - Burnout Risk Prediction
/// - Predictive Analytics
/// - Pattern Learning
class AIAnomalyDetectionService {
  // Thresholds for anomaly detection
  static const double _lateArrivalThresholdMinutes = 15;
  static const double _earlyDepartureThresholdMinutes = 30;
  static const double _overtimeThresholdHours = 2;
  static const double _burnoutOvertimeWeeklyHours = 50;
  static const int _frequentLateThreshold = 3; // times per week

  /// Analyze attendance patterns and detect anomalies
  AttendanceAnalysisResult analyzeAttendance({
    required List<AttendanceEntry> entries,
    required WorkSchedule schedule,
  }) {
    if (entries.isEmpty) {
      return AttendanceAnalysisResult(
        score: 100,
        anomalies: [],
        insights: ['No attendance data to analyze'],
        riskLevel: RiskLevel.low,
      );
    }

    final anomalies = <AttendanceAnomaly>[];
    final insights = <String>[];

    int lateArrivals = 0;
    int earlyDepartures = 0;
    double totalOvertimeHours = 0;
    int missedDays = 0;
    double totalWorkHours = 0;

    for (final entry in entries) {
      // Check for late arrivals
      if (entry.clockIn != null) {
        final expectedStart = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
          schedule.startHour,
          schedule.startMinute,
        );

        final lateMinutes = entry.clockIn!.difference(expectedStart).inMinutes;
        if (lateMinutes > _lateArrivalThresholdMinutes) {
          lateArrivals++;
          anomalies.add(AttendanceAnomaly(
            type: AnomalyType.lateArrival,
            date: entry.date,
            severity: _calculateLateSeverity(lateMinutes),
            description: 'Arrived ${lateMinutes} minutes late',
            value: lateMinutes.toDouble(),
          ));
        }
      }

      // Check for early departures
      if (entry.clockOut != null) {
        final expectedEnd = DateTime(
          entry.date.year,
          entry.date.month,
          entry.date.day,
          schedule.endHour,
          schedule.endMinute,
        );

        final earlyMinutes = expectedEnd.difference(entry.clockOut!).inMinutes;
        if (earlyMinutes > _earlyDepartureThresholdMinutes) {
          earlyDepartures++;
          anomalies.add(AttendanceAnomaly(
            type: AnomalyType.earlyDeparture,
            date: entry.date,
            severity: _calculateEarlySeverity(earlyMinutes),
            description: 'Left ${earlyMinutes} minutes early',
            value: earlyMinutes.toDouble(),
          ));
        }
      }

      // Check for overtime
      if (entry.clockIn != null && entry.clockOut != null) {
        final workHours =
            entry.clockOut!.difference(entry.clockIn!).inMinutes / 60;
        totalWorkHours += workHours;

        final overtimeHours = workHours - schedule.expectedDailyHours;
        if (overtimeHours > _overtimeThresholdHours) {
          totalOvertimeHours += overtimeHours;
          anomalies.add(AttendanceAnomaly(
            type: AnomalyType.excessiveOvertime,
            date: entry.date,
            severity: _calculateOvertimeSeverity(overtimeHours),
            description:
                'Worked ${overtimeHours.toStringAsFixed(1)} hours overtime',
            value: overtimeHours,
          ));
        }
      }

      // Check for missed days (no clock-in)
      if (entry.clockIn == null && !entry.isWeekend && !entry.isHoliday) {
        missedDays++;
        anomalies.add(AttendanceAnomaly(
          type: AnomalyType.absentWithoutNotice,
          date: entry.date,
          severity: AnomalySeverity.high,
          description: 'No attendance recorded',
          value: 1,
        ));
      }
    }

    // Generate insights
    if (lateArrivals >= _frequentLateThreshold) {
      insights.add('⚠️ Frequent late arrivals detected ($lateArrivals times)');
    }
    if (earlyDepartures >= _frequentLateThreshold) {
      insights.add(
          '⚠️ Frequent early departures detected ($earlyDepartures times)');
    }
    if (totalOvertimeHours > _burnoutOvertimeWeeklyHours) {
      insights.add('🔴 High overtime hours - burnout risk detected');
    }
    if (missedDays > 0) {
      insights.add('❌ $missedDays day(s) with no attendance recorded');
    }

    // Calculate overall score (0-100)
    final score = _calculateAttendanceScore(
      lateArrivals: lateArrivals,
      earlyDepartures: earlyDepartures,
      missedDays: missedDays,
      totalDays: entries.length,
    );

    return AttendanceAnalysisResult(
      score: score,
      anomalies: anomalies,
      insights: insights,
      riskLevel: _determineRiskLevel(score),
      lateArrivals: lateArrivals,
      earlyDepartures: earlyDepartures,
      missedDays: missedDays,
      totalOvertimeHours: totalOvertimeHours,
      averageWorkHours: totalWorkHours / entries.length,
    );
  }

  /// Predict burnout risk based on work patterns
  BurnoutRiskAssessment assessBurnoutRisk({
    required List<AttendanceEntry> recentEntries, // Last 30 days
    required List<double> weeklyHours, // Last 4-8 weeks
  }) {
    final riskFactors = <String>[];
    double riskScore = 0;

    // Factor 1: Excessive weekly hours
    final averageWeeklyHours = weeklyHours.isEmpty
        ? 0.0
        : weeklyHours.reduce((a, b) => a + b) / weeklyHours.length;

    if (averageWeeklyHours > 50) {
      riskScore += 25;
      riskFactors.add(
          'Average weekly hours (${averageWeeklyHours.toStringAsFixed(1)}) exceeds healthy limit');
    } else if (averageWeeklyHours > 45) {
      riskScore += 15;
      riskFactors.add(
          'Weekly hours trending high (${averageWeeklyHours.toStringAsFixed(1)}h/week)');
    }

    // Factor 2: Increasing trend in work hours
    if (weeklyHours.length >= 4) {
      final firstHalf = weeklyHours.sublist(0, weeklyHours.length ~/ 2);
      final secondHalf = weeklyHours.sublist(weeklyHours.length ~/ 2);
      final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
      final secondAvg = secondHalf.reduce((a, b) => a + b) / secondHalf.length;

      if (secondAvg > firstAvg * 1.15) {
        riskScore += 20;
        riskFactors.add('Work hours increasing trend detected');
      }
    }

    // Factor 3: Weekend work
    final weekendEntries =
        recentEntries.where((e) => e.isWeekend && e.clockIn != null);
    if (weekendEntries.length >= 2) {
      riskScore += 15;
      riskFactors.add(
          'Frequent weekend work detected (${weekendEntries.length} days)');
    }

    // Factor 4: Late night work
    final lateNightEntries = recentEntries.where((e) {
      if (e.clockOut == null) return false;
      return e.clockOut!.hour >= 21;
    });
    if (lateNightEntries.length >= 3) {
      riskScore += 15;
      riskFactors.add('Frequent late night work detected');
    }

    // Factor 5: No breaks/vacation
    final daysWithLongHours = recentEntries.where((e) {
      if (e.clockIn == null || e.clockOut == null) return false;
      final hours = e.clockOut!.difference(e.clockIn!).inHours;
      return hours >= 10;
    });
    if (daysWithLongHours.length >= 5) {
      riskScore += 20;
      riskFactors.add('Multiple 10+ hour days without adequate rest');
    }

    // Determine risk level
    final riskLevel = riskScore >= 60
        ? BurnoutRiskLevel.high
        : riskScore >= 35
            ? BurnoutRiskLevel.medium
            : BurnoutRiskLevel.low;

    // Generate recommendations
    final recommendations =
        _generateBurnoutRecommendations(riskFactors, riskLevel);

    return BurnoutRiskAssessment(
      riskScore: riskScore.clamp(0, 100).toInt(),
      riskLevel: riskLevel,
      riskFactors: riskFactors,
      recommendations: recommendations,
      averageWeeklyHours: averageWeeklyHours,
    );
  }

  /// Predict staffing needs based on historical data
  StaffingPrediction predictStaffingNeeds({
    required List<DailyAttendance> historicalData,
    required DateTime targetDate,
  }) {
    // Simple prediction based on day of week patterns
    final dayOfWeek = targetDate.weekday;

    final sameDayData =
        historicalData.where((d) => d.date.weekday == dayOfWeek).toList();

    if (sameDayData.isEmpty) {
      return StaffingPrediction(
        date: targetDate,
        predictedAttendance: 0,
        confidence: 0,
        recommendation: 'Insufficient data for prediction',
      );
    }

    final averageAttendance =
        sameDayData.map((d) => d.presentCount).reduce((a, b) => a + b) /
            sameDayData.length;

    final variance = _calculateVariance(
      sameDayData.map((d) => d.presentCount.toDouble()).toList(),
    );

    // Higher variance = lower confidence
    final confidence = (100 - (variance * 10)).clamp(50.0, 95.0);

    return StaffingPrediction(
      date: targetDate,
      predictedAttendance: averageAttendance.round(),
      confidence: confidence.round(),
      recommendation: _generateStaffingRecommendation(
        averageAttendance,
        confidence,
        dayOfWeek,
      ),
    );
  }

  /// Detect unusual patterns that might indicate issues
  List<PatternAlert> detectUnusualPatterns({
    required String userId,
    required List<AttendanceEntry> entries,
  }) {
    final alerts = <PatternAlert>[];

    // Pattern 1: Sudden change in arrival time
    if (entries.length >= 10) {
      final recentArrivals = entries
          .where((e) => e.clockIn != null)
          .take(5)
          .map((e) => e.clockIn!.hour * 60 + e.clockIn!.minute)
          .toList();

      final historicalArrivals = entries
          .where((e) => e.clockIn != null)
          .skip(5)
          .take(10)
          .map((e) => e.clockIn!.hour * 60 + e.clockIn!.minute)
          .toList();

      if (recentArrivals.isNotEmpty && historicalArrivals.isNotEmpty) {
        final recentAvg =
            recentArrivals.reduce((a, b) => a + b) / recentArrivals.length;
        final historicalAvg = historicalArrivals.reduce((a, b) => a + b) /
            historicalArrivals.length;

        if ((recentAvg - historicalAvg).abs() > 30) {
          alerts.add(PatternAlert(
            type: PatternAlertType.arrivalTimeShift,
            message: 'Significant change in usual arrival time detected',
            severity: AlertSeverity.medium,
            suggestion:
                'Consider checking if there are personal or schedule changes',
          ));
        }
      }
    }

    // Pattern 2: Declining work hours
    if (entries.length >= 14) {
      final recentHours = entries
          .take(7)
          .where((e) => e.clockIn != null && e.clockOut != null)
          .map((e) => e.clockOut!.difference(e.clockIn!).inHours.toDouble())
          .toList();

      final previousHours = entries
          .skip(7)
          .take(7)
          .where((e) => e.clockIn != null && e.clockOut != null)
          .map((e) => e.clockOut!.difference(e.clockIn!).inHours.toDouble())
          .toList();

      if (recentHours.isNotEmpty && previousHours.isNotEmpty) {
        final recentAvg =
            recentHours.reduce((a, b) => a + b) / recentHours.length;
        final previousAvg =
            previousHours.reduce((a, b) => a + b) / previousHours.length;

        if (previousAvg - recentAvg > 1.5) {
          alerts.add(PatternAlert(
            type: PatternAlertType.decliningHours,
            message: 'Work hours have decreased significantly recently',
            severity: AlertSeverity.low,
            suggestion: 'May indicate disengagement - consider a check-in',
          ));
        }
      }
    }

    return alerts;
  }

  // Helper methods
  AnomalySeverity _calculateLateSeverity(int minutes) {
    if (minutes > 60) return AnomalySeverity.high;
    if (minutes > 30) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }

  AnomalySeverity _calculateEarlySeverity(int minutes) {
    if (minutes > 120) return AnomalySeverity.high;
    if (minutes > 60) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }

  AnomalySeverity _calculateOvertimeSeverity(double hours) {
    if (hours > 4) return AnomalySeverity.high;
    if (hours > 2) return AnomalySeverity.medium;
    return AnomalySeverity.low;
  }

  int _calculateAttendanceScore({
    required int lateArrivals,
    required int earlyDepartures,
    required int missedDays,
    required int totalDays,
  }) {
    if (totalDays == 0) return 100;

    double score = 100;
    score -= (lateArrivals / totalDays) * 30;
    score -= (earlyDepartures / totalDays) * 20;
    score -= (missedDays / totalDays) * 50;

    return score.clamp(0, 100).round();
  }

  RiskLevel _determineRiskLevel(int score) {
    if (score >= 80) return RiskLevel.low;
    if (score >= 60) return RiskLevel.medium;
    return RiskLevel.high;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  List<String> _generateBurnoutRecommendations(
    List<String> riskFactors,
    BurnoutRiskLevel level,
  ) {
    final recommendations = <String>[];

    if (level == BurnoutRiskLevel.high) {
      recommendations.add('🚨 Schedule immediate wellness check-in with HR');
      recommendations.add('📅 Review and redistribute workload');
      recommendations.add('🏖️ Encourage taking earned leave');
    } else if (level == BurnoutRiskLevel.medium) {
      recommendations
          .add('💬 Consider scheduling a 1-on-1 to discuss workload');
      recommendations.add('⏰ Monitor work hours for the next 2 weeks');
    }

    if (riskFactors.any((f) => f.contains('weekend'))) {
      recommendations.add('📵 Establish clear boundaries for weekend work');
    }
    if (riskFactors.any((f) => f.contains('late night'))) {
      recommendations.add('🌙 Encourage ending work by reasonable hours');
    }

    return recommendations;
  }

  String _generateStaffingRecommendation(
    double avgAttendance,
    double confidence,
    int dayOfWeek,
  ) {
    final dayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final dayName = dayNames[dayOfWeek];

    if (confidence < 70) {
      return 'Low confidence prediction for $dayName. Consider collecting more historical data.';
    }

    if (avgAttendance < 10) {
      return 'Expected low attendance on $dayName. Consider reduced staffing.';
    } else if (avgAttendance > 50) {
      return 'High attendance expected on $dayName. Ensure adequate resources.';
    }

    return 'Normal attendance expected for $dayName.';
  }
}

// =================== Data Models ===================

class AttendanceEntry {
  final DateTime date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final bool isWeekend;
  final bool isHoliday;

  AttendanceEntry({
    required this.date,
    this.clockIn,
    this.clockOut,
    this.isWeekend = false,
    this.isHoliday = false,
  });
}

class WorkSchedule {
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final double expectedDailyHours;

  WorkSchedule({
    this.startHour = 9,
    this.startMinute = 0,
    this.endHour = 18,
    this.endMinute = 0,
    this.expectedDailyHours = 8,
  });
}

class AttendanceAnomaly {
  final AnomalyType type;
  final DateTime date;
  final AnomalySeverity severity;
  final String description;
  final double value;

  AttendanceAnomaly({
    required this.type,
    required this.date,
    required this.severity,
    required this.description,
    required this.value,
  });
}

enum AnomalyType {
  lateArrival,
  earlyDeparture,
  excessiveOvertime,
  absentWithoutNotice,
  unusualPattern,
}

enum AnomalySeverity { low, medium, high }

enum RiskLevel { low, medium, high }

class AttendanceAnalysisResult {
  final int score;
  final List<AttendanceAnomaly> anomalies;
  final List<String> insights;
  final RiskLevel riskLevel;
  final int? lateArrivals;
  final int? earlyDepartures;
  final int? missedDays;
  final double? totalOvertimeHours;
  final double? averageWorkHours;

  AttendanceAnalysisResult({
    required this.score,
    required this.anomalies,
    required this.insights,
    required this.riskLevel,
    this.lateArrivals,
    this.earlyDepartures,
    this.missedDays,
    this.totalOvertimeHours,
    this.averageWorkHours,
  });
}

enum BurnoutRiskLevel { low, medium, high }

class BurnoutRiskAssessment {
  final int riskScore;
  final BurnoutRiskLevel riskLevel;
  final List<String> riskFactors;
  final List<String> recommendations;
  final double averageWeeklyHours;

  BurnoutRiskAssessment({
    required this.riskScore,
    required this.riskLevel,
    required this.riskFactors,
    required this.recommendations,
    required this.averageWeeklyHours,
  });
}

class DailyAttendance {
  final DateTime date;
  final int presentCount;
  final int absentCount;

  DailyAttendance({
    required this.date,
    required this.presentCount,
    required this.absentCount,
  });
}

class StaffingPrediction {
  final DateTime date;
  final int predictedAttendance;
  final int confidence;
  final String recommendation;

  StaffingPrediction({
    required this.date,
    required this.predictedAttendance,
    required this.confidence,
    required this.recommendation,
  });
}

enum PatternAlertType {
  arrivalTimeShift,
  decliningHours,
  increasingAbsence,
  overtimeTrend,
}

enum AlertSeverity { low, medium, high }

class PatternAlert {
  final PatternAlertType type;
  final String message;
  final AlertSeverity severity;
  final String suggestion;

  PatternAlert({
    required this.type,
    required this.message,
    required this.severity,
    required this.suggestion,
  });
}
