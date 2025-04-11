import 'package:flutter/material.dart';
import 'login.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> otpFocusNodes =
      List.generate(6, (index) => FocusNode());

  Future<void> _nextStep() async {
    String email = emailController.text.trim();
    String password = passwordController.text;
    String confirmPassword = confirmPasswordController.text;

    if (_currentStep == 0) {
      // Email validation
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (email.isEmpty || !emailRegex.hasMatch(email)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid email address")),
        );
        return;
      }
    } else if (_currentStep == 1) {
      // Password validation
      if (password.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Password must be at least 6 characters")),
        );
        return;
      }
    } else if (_currentStep == 2) {
      // Confirm password match
      if (password != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Passwords do not match")),
        );
        return;
      }

      // Send OTP
      final otpUrl = Uri.parse(
          "https://script.google.com/macros/s/AKfycbwhwuA_9cX7hysheXB6PzKfZ93AOcwgk2_xjtbde2Ol10Pi4Ueh63dG_idrfJBf-XE_/exec");
      try {
        final response = await http.post(
          otpUrl,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "email": emailController.text.trim(),
          }),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("OTP sent to ${emailController.text.trim()}")),
          );
          debugPrint("OTP sent: ${response.body}");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text("Failed to send OTP: ${response.reasonPhrase}")),
          );
          return;
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Network error: $e")),
        );
        return;
      }
    } else if (_currentStep == 3) {
      // Verify OTP
      String otp = otpControllers.map((controller) => controller.text).join();
      if (otp.length != 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Please enter the complete 6-digit OTP")),
        );
        return;
      }

      // Here you would typically verify the OTP with your backend
      // For now, we'll just proceed to the next step
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
      // Navigate to login or home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      return;
    }

    // If validation passes
    setState(() {
      _currentStep++;
    });
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return CustomInputField(
          controller: emailController,
          hint: "Email address",
        );
      case 1:
        return CustomInputField(
          controller: passwordController,
          hint: "Set password",
          obscure: true,
        );
      case 2:
        return CustomInputField(
          controller: confirmPasswordController,
          hint: "Confirm password",
          obscure: true,
        );
      case 3:
        return Column(
          children: [
            const Text(
              "Enter the 6-digit OTP sent to your email",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    onChanged: (value) {
                      if (value.length == 1 && index < 5) {
                        FocusScope.of(context)
                            .requestFocus(otpFocusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context)
                            .requestFocus(otpFocusNodes[index - 1]);
                      }
                    },
                  ),
                );
              }),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  String _getButtonLabel() {
    switch (_currentStep) {
      case 0:
        return "Continue";
      case 1:
        return "Continue";
      case 2:
        return "Send OTP";
      case 3:
        return "Verify OTP";
      default:
        return "";
    }
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in otpFocusNodes) {
      node.dispose();
    }
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0B3628),
              Color(0xFF002218),
              Color(0xFF081613),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/appicon.png', height: 48),
                    const SizedBox(width: 8),
                    const Text(
                      "JiboMonie",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  _currentStep == 3 ? "Verify OTP" : "Create an Account",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 3
                      ? "Enter the 6-digit code sent to ${emailController.text.trim()}"
                      : "To create an account provide details, verify email and set a password.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 32),

                // Social Buttons only on first step
                if (_currentStep == 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AuthButton(
                        icon: FontAwesome.google,
                        label: "Google",
                        bgColor: Colors.white,
                        textColor: Colors.white,
                        onPressed: () {
                          debugPrint("Tapped Google!");
                        },
                      ),
                      AuthButton(
                        icon: FontAwesome.apple,
                        label: "Apple",
                        bgColor: Colors.white,
                        textColor: Colors.white,
                        onPressed: () {
                          debugPrint("Tapped Apple!");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Or",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                ],

                _buildStepContent(),
                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    padding: const EdgeInsets.symmetric(
                        vertical: 20, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _nextStep,
                  child: Text(
                    _getButtonLabel(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                const SizedBox(height: 20),
                if (_currentStep != 3) ...[
                  Center(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()));
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: "Have an account? ",
                          style: TextStyle(color: Colors.white70),
                          children: [
                            TextSpan(
                              text: "Log In",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
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

class CustomInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;

  const CustomInputField({
    required this.controller,
    required this.hint,
    this.obscure = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color textColor;
  final VoidCallback onPressed;

  const AuthButton({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.textColor,
    required this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: TextStyle(color: textColor)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
