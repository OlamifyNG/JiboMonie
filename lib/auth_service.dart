import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart' show TargetPlatform;

class AuthService {
  static const String baseUrl = 'https://jibomonie-backend.onrender.com';
  static final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final deviceData = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('$baseUrl/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
          'device': {
            'imei': deviceData['imei'],
            'model': deviceData['model'],
            'osVersion': deviceData['osVersion'],
          }
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', responseData['userId']);
        await prefs.setString('username', username);
        await prefs.setString('email', email);
        await prefs.setBool('isLoggedIn', true);

        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Registration failed');
      }
    } catch (e) {
      throw Exception('Registration error: ${e.toString()}');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final deviceData = await _getDeviceInfo();

      final response = await http.post(
        Uri.parse('$baseUrl/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'device': {
            'imei': deviceData['imei'],
          }
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        // Save user data to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', responseData['userId']);
        await prefs.setString('username', responseData['username']);
        await prefs.setString('email', email);
        await prefs.setBool('isLoggedIn', true);

        return responseData;
      } else {
        throw Exception(responseData['error'] ?? 'Login failed');
      }
    } catch (e) {
      throw Exception('Login error: ${e.toString()}');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  static Future<Map<String, dynamic>> _getDeviceInfo() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await deviceInfo.androidInfo;
        return {
          'imei': androidInfo.id ?? 'unknown-android-id',
          'model': '${androidInfo.manufacturer} ${androidInfo.model}',
          'osVersion': 'Android ${androidInfo.version.release}',
        };
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return {
          'imei': iosInfo.identifierForVendor ?? 'unknown-ios-id',
          'model': iosInfo.utsname.machine,
          'osVersion': 'iOS ${iosInfo.systemVersion}',
        };
      }
      return {
        'imei': 'unknown-device',
        'model': 'Unknown',
        'osVersion': 'Unknown',
      };
    } catch (e) {
      return {
        'imei': 'error-getting-device-id',
        'model': 'Error',
        'osVersion': 'Error',
      };
    }
  }
}
