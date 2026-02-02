import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../services/api_service.dart';

class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final ApiService api;
  final String userId;

  AttendanceNotifier(this.api, this.userId) : super(AttendanceState.checkedOut);

  Future<AttendanceRecord> checkIn() async {
    if (state != AttendanceState.checkedOut) {
      throw Exception('Cannot check in from state $state');
    }
    final rec = await api.checkIn(userId);
    state = AttendanceState.checkedIn;
    return rec;
  }

  Future<AttendanceRecord> checkOut() async {
    if (state == AttendanceState.checkedOut) {
      throw Exception('Already checked out');
    }
    final rec = await api.checkOut(userId);
    state = AttendanceState.checkedOut;
    return rec;
  }

  void setWorking() {
    if (state != AttendanceState.checkedIn) throw Exception('Must be checked in to start working');
    state = AttendanceState.working;
  }

  void setIdle() {
    if (state == AttendanceState.checkedOut) throw Exception('Cannot go idle while checked out');
    state = AttendanceState.idle;
  }
}
