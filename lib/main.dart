import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher_string.dart';
import 'home.dart';
import 'login.dart';
import 'register.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'logger.dart';

const storage = FlutterSecureStorage();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with Web support
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  String? sessionToken = await storage.read(key: 'sess_token');
  runApp(MyApp(isLoggedIn: sessionToken != null));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JiboMonie',
      debugShowCheckedModeBanner: false,
      initialRoute: isLoggedIn ? '/home' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
      },
      theme: ThemeData(
        fontFamily: 'OpenSans',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontWeight: FontWeight.w600),
          displaySmall: TextStyle(fontWeight: FontWeight.w500),
          headlineMedium: TextStyle(fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontWeight: FontWeight.w500),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
          titleMedium: TextStyle(fontWeight: FontWeight.w500),
          titleSmall: TextStyle(fontWeight: FontWeight.w400),
          bodyLarge: TextStyle(fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          bodySmall: TextStyle(fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontWeight: FontWeight.w500),
          labelSmall: TextStyle(fontWeight: FontWeight.w400),
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
    );
  }
}

// Check if an update is available
Future<Map<String, String>> checkForUpdate() async {
  try {
    final response = await http
        .get(Uri.parse('https://jibomoniebackend.onrender.com/version'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return {
        'version': data['version'],
        'apk_url': data['apk_url'],
      };
    } else {
      throw Exception('Failed to load version info');
    }
  } catch (e) {
    ReleaseLogger.log('Error checking for update: $e');
    return {};
  }
}

// Get the current version of the app
Future<String> getCurrentVersion() async {
  final packageInfo = await PackageInfo.fromPlatform();
  return packageInfo.version;
}

// Check for updates and show notification
void checkForUpdateAndNotify(BuildContext context) async {
  Map<String, String> updateInfo = await checkForUpdate();

  if (updateInfo.isNotEmpty) {
    String latestVersion = updateInfo['version']!;
    String apkUrl = updateInfo['apk_url']!;
    String currentVersion = await getCurrentVersion();

    if (currentVersion != latestVersion) {
      // Notify user about the update
      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.black87,
          title: const Text('Update Available'),
          content: const Text(
              'A new version of the app is available. Please update to continue.'),
          actions: [
            TextButton(
              onPressed: () {
                // Launch the APK download URL
                if (kIsWeb) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                  );
                } else {
                  _downloadAndUpdate(apkUrl);
                }
              },
              child: const Text('Download APK',
                  style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    }
  }
}

// Launch the APK download URL
void _downloadAndUpdate(String apkUrl) async {
  try {
    if (await canLaunchUrlString(apkUrl)) {
      await launchUrlString(apkUrl);
    } else {
      ReleaseLogger.log('Could not launch $apkUrl');
      // Optionally show an error message
    }
  } catch (e) {
    ReleaseLogger.log('Error launching APK URL: $e');
  }
}
