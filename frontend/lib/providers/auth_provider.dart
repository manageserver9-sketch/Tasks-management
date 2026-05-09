import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;

  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  List<dynamic> _allUsers = [];
  List<dynamic> get allUsers => _allUsers;

  AuthProvider() {
    _checkToken();
  }

  Future<void> _checkToken() async {
    String? token = await _storage.read(key: 'jwt');
    if (token != null) {
      _isAuthenticated = true;
      // Ideally fetch user profile here
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final response = await _api.dio.post('/auth/login.php', data: {
        'phone': phone,
        'password': password,
      });

      if (response.data['success']) {
        final data = response.data['data'];
        await _storage.write(key: 'jwt', value: data['jwt']);
        _user = data['user'];
        _isAuthenticated = true;
        notifyListeners();
        return {'success': true, 'message': response.data['message']};
      }
      return {'success': false, 'message': response.data['message']};
    } catch (e) {
      if (e is DioException && e.response != null) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Login failed'};
      }
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<Map<String, dynamic>> register(String name, String email, String phone, String password) async {
    try {
      final response = await _api.dio.post('/auth/register.php', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      });
      return {
        'success': response.data['success'] == true,
        'message': response.data['message'] ?? 'Registration successful'
      };
    } catch (e) {
      if (e is DioException && e.response != null) {
        return {'success': false, 'message': e.response?.data['message'] ?? 'Registration failed'};
      }
      return {'success': false, 'message': 'Network error'};
    }
  }

  Future<void> fetchAllUsers() async {
    try {
      final response = await _api.dio.get('/users/read.php');
      if (response.data['success']) {
        _allUsers = response.data['data'];
        notifyListeners();
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt');
    _isAuthenticated = false;
    _user = null;
    notifyListeners();
  }
}
