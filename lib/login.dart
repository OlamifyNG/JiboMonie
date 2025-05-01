// ignore_for_file: deprecated_member_use
import 'main.dart'; // 👈 Import this to access checkForUpdateAndNotify
import 'package:dev/register.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'logger.dart';
import 'auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const storage = FlutterSecureStorage();

Future<bool> checkIfEmailExists(String email) async {
  final url = Uri.parse(
      "https://jibomoniebackend.onrender.com/check-user-info"); // Replace with your deployed backend

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await storage.write(key: 'user_balance', value: data['user']['balance']);
      await storage.write(
          key: 'user_fullname', value: data['user']['full_name']);
      await storage.write(key: 'user_logged_in', value: 'true');

      return data['exists'] == true;
    } else {
      debugPrint('Server responded with error: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error checking email: $e');
    return false;
  }
}

Future<bool> checkIfEmailAndPasswordValid(String email, String password) async {
  final url = Uri.parse(
      "https://jibomoniebackend.onrender.com/authenticate"); // Replace with your actual backend URL for authentication

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email,
        "password": password,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Write the user data to secure storage
      await storage.write(key: 'user_balance', value: data['user']['balance']);
      await storage.write(
          key: 'user_fullname', value: data['user']['full_name']);
      await storage.write(key: 'user_logged_in', value: 'true');

      return data['success'] ==
          true; // Assuming the response contains a success flag
    } else {
      debugPrint('Authentication failed: ${response.body}');
      return false;
    }
  } catch (e) {
    debugPrint('Error checking email and password: $e');
    return false;
  }
}

final AuthService _authService = AuthService();

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkForUpdateAndNotify(context); // 👈 Check for updates on screen load
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3628), // top - green
              Color(0xFF002218), // middle - deep forest green
              Color(0xFF081613), // bottom - near black
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/appicon.png', // 👈 make sure the image exists here
                      height: 64,
                    ),
                    const Text(
                      "JiboMonie",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                const Text("Hi There!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Please enter required details.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    AuthButton(
                      icon: FontAwesome.google,
                      label: "Google",
                      bgColor: Colors.white,
                      textColor: Colors.white,
                      onPressed: () async {
                        final userCredential =
                            await _authService.signInWithGoogle();
                        final userEmail = userCredential?.user?.email;
                        if (userEmail != null) {
                          final exists = await checkIfEmailExists(userEmail);
                          if (exists) {
                            // Continue login
                            Navigator.pushReplacementNamed(context, '/home');
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Google Sign-In failed.")),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Failed to fetch email")),
                          );
                        }
                      },
                    ),
                    AuthButton(
                      icon: FontAwesome.apple,
                      label: "Apple",
                      bgColor: Colors.white,
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/home');
                        ReleaseLogger.log("Tapped Apple!");
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Or",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                CustomInputField(
                    controller: emailController, hint: "Email address"),
                const SizedBox(height: 12),
                CustomInputField(
                    controller: passwordController,
                    hint: "Password",
                    obscure: true),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to forgot password screen or show a dialog
                    },
                    child: const Text("Forgot Password?",
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    final email = emailController.text;
                    final password = passwordController.text;

                    // Validate email and password
                    if (email.isEmpty || password.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Email and Password are required")),
                      );
                      return;
                    }

                    // Check if the email and password are valid
                    final valid =
                        await checkIfEmailAndPasswordValid(email, password);
                    if (valid) {
                      // If the login is successful, navigate to the home screen
                      Navigator.pushReplacementNamed(context, '/home');
                    } else {
                      // If the login fails, show an error message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Invalid email or password")),
                      );
                    }
                  },
                  child: const Text(
                    "Log In",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()));
                    },
                    child: RichText(
                      text: const TextSpan(
                        text: "Create an account? ",
                        style: TextStyle(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Sign Up",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                const Center(
                  child: Text("Terms of Service | Privacy Policy",
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback? onPressed;

  const AuthButton({
    super.key,
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: bgColor.withOpacity(0.2), // glass effect background
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            splashColor: Colors.white.withOpacity(0.1), // optional ripple color
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: textColor),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(color: textColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const CustomInputField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // translucent glass
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
