import 'package:enterprise_attendance/src/services/api_service.dart';

class PayrollService {
  final ApiService _apiService = ApiService();

  Future<List<dynamic>> getPayslips(int? month, int? year) async {
    try {
      String query = '/payroll/payslips';
      final params = <String>[];

      if (month != null) params.add('month=$month');
      if (year != null) params.add('year=$year');

      if (params.isNotEmpty) {
        query += '?${params.join('&')}';
      }

      final response = await _apiService.get(query);
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching payslips: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getPayslipById(int id) async {
    try {
      final response = await _apiService.get('/payroll/payslips/$id');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching payslip: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getSalaryComponents() async {
    try {
      final response = await _apiService.get('/payroll/components');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching salary components: $e');
      return [];
    }
  }

  Future<List<dynamic>> getSalaryStructure(int userId) async {
    try {
      final response = await _apiService.get('/payroll/structure/$userId');
      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching salary structure: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getMySalaryData() async {
    try {
      final response = await _apiService.get('/payroll/my-salary-data');
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching salary data: $e');
      return {};
    }
  }

  Future<List<dynamic>> generatePayslipsForMonth({
    required int month,
    required int year,
    required int workingDays,
  }) async {
    try {
      final response = await _apiService.post(
        '/payroll/payslips/generate-month',
        body: {
          'month': month,
          'year': year,
          'workingDays': workingDays,
        },
      );
      return response as List<dynamic>;
    } catch (e) {
      print('Error generating payslips: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> approvePayslip(int payslipId) async {
    try {
      final response = await _apiService.put(
        '/payroll/payslips/$payslipId/approve',
        body: {},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error approving payslip: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> markPayslipAsPaid(int payslipId) async {
    try {
      final response = await _apiService.put(
        '/payroll/payslips/$payslipId/mark-paid',
        body: {},
      );
      return response as Map<String, dynamic>;
    } catch (e) {
      print('Error marking payslip as paid: $e');
      rethrow;
    }
  }
}
