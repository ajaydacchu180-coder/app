import 'package:enterprise_attendance/src/services/api_service.dart';

class LeaveService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getLeaveTypes() async {
    try {
      final response = await _apiService.get('/leave/types');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching leave types: $e');
      return [];
    }
  }

  Future<List<dynamic>> getMyLeaveRequests() async {
    try {
      final response = await _apiService.get('/leave/requests');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching leave requests: $e');
      return [];
    }
  }

  Future<List<dynamic>> getLeaveBalance() async {
    try {
      final year = DateTime.now().year;
      final response = await _apiService.get('/leave/balance/$year');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching leave balance: $e');
      return [];
    }
  }

  Future<List<dynamic>> getLeaveRequestsForApproval() async {
    try {
      final response = await _apiService.get('/leave/requests?status=PENDING');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching leave requests for approval: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> createLeaveRequest(Map<String, dynamic> data) async {
    try {
      final response = await _apiService.post('/leave/request', body: data);
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error creating leave request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> approveLeaveRequest(int requestId) async {
    try {
      final response = await _apiService.put(
        '/leave/requests/$requestId/approve',
        body: {'notes': ''},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error approving leave request: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectLeaveRequest(int requestId) async {
    try {
      final response = await _apiService.put(
        '/leave/requests/$requestId/reject',
        body: {'notes': ''},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error rejecting leave request: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getHolidays(int year) async {
    try {
      final response = await _apiService.get('/leave/holidays/$year');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching holidays: $e');
      return [];
    }
  }
}
