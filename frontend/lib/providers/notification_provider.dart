import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
        final List<dynamic> fetched = (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
        
        // Show pop-ups for new unread notifications
        final prefs = await SharedPreferences.getInstance();
        int lastNotifiedId = prefs.getInt('last_notified_id') ?? 0;
        int newLastId = lastNotifiedId;

        for (var notif in fetched) {
          int id = notif['id'];
          if ((notif['is_read'] == 0 || notif['is_read'] == '0') && id > lastNotifiedId) {
            NotificationService.showNotification(
              id,
              "New Task Update",
              notif['message'],
            );
            if (id > newLastId) newLastId = id;
          }
        }

        if (newLastId > lastNotifiedId) {
          await prefs.setInt('last_notified_id', newLastId);
        }

        _notifications = fetched;
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

