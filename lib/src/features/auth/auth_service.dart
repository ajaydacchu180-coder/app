import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models.dart';
import '../../services/api_service.dart';

class AuthState {
  final String? token;
  final User? user;
  AuthState({this.token, this.user});

  bool get isAuthenticated => token != null && user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService api;
  AuthNotifier(this.api) : super(AuthState());

  Future<void> login(String username, String password, Role role) async {
    final res = await api.login(username, password, role);
    final userMap = res['user'] as Map<String, dynamic>;
    state = AuthState(
      token: res['token'] as String,
      user: User(id: userMap['id'], name: userMap['name'], role: Role.values.firstWhere((r) => r.name == userMap['role'])),
    );
  }

  void logout() {
    state = AuthState();
  }
}
