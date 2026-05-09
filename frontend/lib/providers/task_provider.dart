import 'package:flutter/material.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final _api = ApiService();
  List<dynamic> _tasks = [];
  Map<String, dynamic>? _dashboardStats;
  bool _isLoading = false;

  List<dynamic> get tasks => _tasks;
  Map<String, dynamic>? get dashboardStats => _dashboardStats;
  bool get isLoading => _isLoading;

  Future<void> fetchTasks({String search = '', String status = '', String priority = '', String assignedTo = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get('/tasks/read.php', queryParameters: {
        'search': search,
        'status': status,
        'priority': priority,
        'assigned_to': assignedTo,
      });
      if (response.statusCode == 200) {
        _tasks = (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDashboardStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get('/tasks/dashboard_stats.php');
      if (response.statusCode == 200) {
        _dashboardStats = (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await _api.dio.post('/tasks/create.php', data: taskData);
      if (response.statusCode == 201) {
        fetchTasks();
        fetchDashboardStats();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> updateTask(int id, String status, {String? comment, DateTime? nextFollowupDate}) async {
    try {
      final response = await _api.dio.post('/tasks/update.php', data: {
        'id': id,
        'status': status,
        'comment': comment,
        'next_followup_date': nextFollowupDate?.toIso8601String(),
      });
      if (response.statusCode == 200) {
        fetchTasks();
        fetchDashboardStats();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> updateTaskFull(Map<String, dynamic> data) async {
    try {
      final response = await _api.dio.post('/tasks/update.php', data: data);
      if (response.statusCode == 200) {
        fetchTasks();
        fetchDashboardStats();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
}
