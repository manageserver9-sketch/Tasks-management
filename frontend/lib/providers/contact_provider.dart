import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ContactProvider with ChangeNotifier {
  final _api = ApiService();
  List<dynamic> _contacts = [];
  bool _isLoading = false;

  List<dynamic> get contacts => _contacts;
  bool get isLoading => _isLoading;

  Future<void> fetchContacts({String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _api.dio.get('/contacts/read.php', queryParameters: {'search': search});
      if (response.statusCode == 200) {
        _contacts = (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createContact(String name, String phone, {String email = ''}) async {
    try {
      final response = await _api.dio.post('/contacts/create.php', data: {
        'name': name,
        'phone': phone,
        'email': email,
      });
      if (response.statusCode == 201) {
        fetchContacts();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> updateContact(int id, String name, String phone) async {
    try {
      final response = await _api.dio.post('/contacts/update.php', data: {
        'id': id,
        'name': name,
        'phone': phone,
      });
      if (response.statusCode == 200) {
        fetchContacts();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> deleteContact(int id) async {
    try {
      final response = await _api.dio.post('/contacts/delete.php', data: {'id': id});
      if (response.statusCode == 200) {
        _contacts.removeWhere((c) => c['id'] == id);
        notifyListeners();
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
}
