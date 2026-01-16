import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../constants.dart';

class SessionService {
  static Map<String, dynamic>? cachedUser;

  static Future<Map<String, dynamic>?> loadUser({bool forceRefresh = true}) async {
    if (!forceRefresh && cachedUser != null) {
      return cachedUser;
    }

    if (forceRefresh) {
      final fresh = await refreshUserFromApi();
      if (fresh != null) return fresh;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_data');

    if (raw == null) return null;

    cachedUser = jsonDecode(raw);
    return cachedUser;
  }

  static Future<Map<String, dynamic>?> refreshUserFromApi() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null) return null;

      final res = await http.get(
        Uri.parse('$baseURL/api/auth/me'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final user = data['data']['user'];

        // 🔥 update both cache & local storage
        cachedUser = user;
        await prefs.setString('user_data', jsonEncode(user));

        return user;
      }
    } catch (e) {
      debugPrint('refreshUserFromApi error: $e');
    }

    return null;
  }

  static Future<void> clearSession() async {
    cachedUser = null; // 🔥 THIS IS THE KEY
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
