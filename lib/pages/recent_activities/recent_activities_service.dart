import 'dart:convert';
import 'package:a2abrokerapp/pages/recent_activities/recent_activities_model.dart';
import 'package:http/http.dart' as http;
import '../../constants.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';

class RecentActivitiesService {
  Future<ActivityResponse> fetchActivities(int page) async {
    // 🔐 Get token from your session service
    final token = await AuthService.getToken();

    final url = "$baseURL/api/activity?page=$page&limit=10";

    print("🔗 URL: $url");
    print("🔑 TOKEN: $token");

    final response = await http.get(
      Uri.parse(url),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token", // 👈 IMPORTANT
      },
    );

    print("📡 STATUS: ${response.statusCode}");
    print("📦 BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return ActivityResponse.fromJson(data);
    }

    // 🔒 Handle unauthorized (token expired etc.)
    else if (response.statusCode == 401) {
      throw Exception('Unauthorized - Token expired');
    }

    else {
      throw Exception('Failed to load activities');
    }
  }
}