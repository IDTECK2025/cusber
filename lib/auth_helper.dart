import 'package:shared_preferences/shared_preferences.dart';

class AuthHelper {
  static const String _tokenKey = 'token';

  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);

      // Validate token
      if (token == null ||
          token.isEmpty ||
          token == 'null' ||
          token == 'undefined') {
        print('Invalid or missing token');
        return null;
      }

      // Basic JWT structure validation
      final parts = token.split('.');
      if (parts.length != 3) {
        print('Invalid JWT token format');
        await clearAllData();
        return null;
      }

      print('Token retrieved successfully');
      return token;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('Token saved successfully');
    } catch (e) {
      print('Error saving token: $e');
    }
  }

  static Future<void> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('All data cleared');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }
}
