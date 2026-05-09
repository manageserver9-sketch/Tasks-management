import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/category.dart';
import 'package:dio/dio.dart';

class CategoryProvider with ChangeNotifier {
  final _api = ApiService();
  List<Category> _categories = [];
  bool _isLoading = false;

  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _api.dio.get('/categories/read/');
      if (response.data['success']) {
        _categories = (response.data['data'] as List)
            .map((item) => Category.fromJson(item))
            .toList();
      }
    } catch (e) {
      print('Error fetching categories: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCategory(String name) async {
    try {
      final response = await _api.dio.post('/categories/create/', data: {'name': name});
      if (response.data['success']) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      print('Error creating category: $e');
      return false;
    }
  }

  Future<bool> updateCategory(int id, String name) async {
    try {
      final response = await _api.dio.post('/categories/update/', data: {'id': id, 'name': name});
      if (response.data['success']) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final response = await _api.dio.post('/categories/delete/', data: {'id': id});
      if (response.data['success']) {
        await fetchCategories();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }
}
