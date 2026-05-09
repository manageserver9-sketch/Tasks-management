import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  static String get baseUrl {
    if (kIsWeb) return "https://tasks-management-production.up.railway.app";
    if (Platform.isAndroid) return "https://tasks-management-production.up.railway.app";
    return "https://tasks-management-production.up.railway.app";
  }
  
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  
  // Simple memory cache
  final Map<String, dynamic> _cache = {};

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _storage.read(key: 'jwt');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        // Cache GET requests
        if (response.requestOptions.method == 'GET') {
          _cache[response.requestOptions.uri.toString()] = response.data;
        }
        return handler.next(response);
      },
    ));
  }

  Dio get dio => _dio;

  dynamic getFromCache(String url) => _cache[url];
  void clearCache() => _cache.clear();
}
