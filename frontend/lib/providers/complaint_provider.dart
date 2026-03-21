import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/api_service.dart';

class ComplaintProvider extends ChangeNotifier {
  List<Complaint> _complaints = [];
  final ApiService _apiService = ApiService();

  List<Complaint> get complaints => _complaints;

  Future<void> fetchComplaints() async {
    final response = await _apiService.get('/complaints');
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      _complaints = data.map((json) => Complaint.fromJson(json)).toList();
      notifyListeners();
    }
  }

  Future<bool> createComplaint({
    required String title,
    required String description,
    required String image,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiService.post('/complaints', {
      'title': title,
      'description': description,
      'image': image,
      'location': {'latitude': latitude, 'longitude': longitude},
    });

    if (response.statusCode == 201) {
      await fetchComplaints();
      return true;
    }
    return false;
  }

  Future<bool> verifyComplaint(String id) async {
    final response = await _apiService.put('/complaints/$id/verify', {});
    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }

  Future<bool> assignComplaint(String id, String engineerId) async {
    final response = await _apiService.put('/complaints/$id/assign', {'engineerId': engineerId});
    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }

  Future<bool> resolveComplaint(String id, String resolutionImage, double lat, double lon) async {
    final response = await _apiService.put('/complaints/$id/resolve', {
      'resolutionImage': resolutionImage,
      'currentLocation': {'latitude': lat, 'longitude': lon},
    });

    if (response.statusCode == 200) {
      await fetchComplaints();
      return true;
    }
    return false;
  }
}
