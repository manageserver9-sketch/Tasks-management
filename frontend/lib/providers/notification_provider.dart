import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final _api = ApiService();
  List<dynamic> _notifications = [];
  bool _isLoading = false;

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => n['is_read'] == 0 || n['is_read'] == '0').length;
  bool get isLoading => _isLoading;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get('/notifications/read.php');
      if (response.statusCode == 200) {
        _notifications = (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead({int? id}) async {
    try {
      await _api.dio.post('/notifications/mark_as_read.php', data: id != null ? {'id': id} : {});
      fetchNotifications();
    } catch (e) {
      print(e);
    }
  }
}
