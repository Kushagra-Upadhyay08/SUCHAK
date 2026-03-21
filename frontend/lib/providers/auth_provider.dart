import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isAuthenticated => _user != null;

  Future<bool> login(String name, String password) async {
    final response = await _apiService.post('/auth/login', {
      'name': name,
      'password': password,
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _user = User.fromJson(data['user']);
      await _apiService.saveToken(data['token']);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register(String name, String password, String role, {String? employeeId}) async {
    final response = await _apiService.post('/auth/register', {
      'name': name,
      'password': password,
      'role': role,
      'employeeId': employeeId,
    });

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      _user = User.fromJson(data['user']);
      await _apiService.saveToken(data['token']);
      notifyListeners();
      return true;
    } else {
      throw Exception(data['message'] ?? 'Registration Failed');
    }
  }

  void logout() {
    _user = null;
    _apiService.logout();
    notifyListeners();
  }
}
