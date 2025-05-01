// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:email_validator/email_validator.dart';
import 'auth_service.dart';
import 'dart:ui';
import 'dart:async';
import 'logger.dart';
import 'package:crypto/crypto.dart';

// Constants
const String baseUrl = "https://jibomoniebackend.onrender.com";
const storage = FlutterSecureStorage();
final AuthService _authService = AuthService();

// Registration Service
class RegistrationService {
  static Future<http.Response> sendOtp(String email) async {
    final otpUrl = Uri.parse("$baseUrl/send-otp");
    ReleaseLogger.log("Sending OTP to email: $email");
    try {
      final response = await http.post(
        otpUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
      ReleaseLogger.log("OTP send response status: ${response.statusCode}");
      return response;
    } catch (e) {
      ReleaseLogger.log("Error sending OTP: $e", level: LogLevel.error);
      rethrow;
    }
  }

  static Future<http.Response> registerUser({
    required String email,
    required String password,
    required String fullName,
    required String dob,
  }) async {
    final registerUrl = Uri.parse("$baseUrl/register");
    ReleaseLogger.log("Registering user with email: $email");
    try {
      final response = await http.post(
        registerUrl,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "full_name": fullName,
          "kyc": {"dob": dob},
        }),
      );
      ReleaseLogger.log("Registration response status: ${response.statusCode}");
      return response;
    } catch (e) {
      ReleaseLogger.log("Error during registration: $e", level: LogLevel.error);
      rethrow;
    }
  }
}

// Main Registration Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _otpLocked = false;
  DateTime? _otpLockTime;
  int _otpAttempts = 0;
  String? _otpFromBackend;
  Timer? _resendTimer;
  int _resendCountdown = 30;

  // Controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Focus Nodes
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    ReleaseLogger.log("RegisterScreen initialized");
    _startResendTimer();
  }

  @override
  void dispose() {
    ReleaseLogger.log("RegisterScreen disposed");
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    ReleaseLogger.log("Starting OTP resend timer");
    _otpController.clear(); // Add this line
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        ReleaseLogger.log("OTP resend timer completed");
      }
    });
  }

  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      ReleaseLogger.log("Form validation failed");
      return;
    }

    ReleaseLogger.log("Starting registration process, step: $_currentStep");
    setState(() => _isLoading = true);
    try {
      if (_currentStep == 3) {
        ReleaseLogger.log("OTP Verification Step");
        await _verifyOtpAndRegister();
      } else {
        setState(() {
          _currentStep++;
          ReleaseLogger.log("Moving to step $_currentStep");
        });
      }
    } catch (e) {
      ReleaseLogger.log("Error in registration process: ${e.toString()}",
          level: LogLevel.error);
      _showErrorSnackbar("Error: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtpAndRegister() async {
    ReleaseLogger.log("Verifying OTP and registering user");

    // Clear any existing error messages
    ScaffoldMessenger.of(context).clearSnackBars();

    if (_otpLocked && _otpLockTime != null) {
      final lockDuration = DateTime.now().difference(_otpLockTime!);
      if (lockDuration.inMinutes < 5) {
        final remainingTime = 5 - lockDuration.inMinutes;
        ReleaseLogger.log(
            "OTP verification locked, remaining time: $remainingTime minutes");
        _showErrorSnackbar(
          "Too many attempts. Please try again in $remainingTime minute${remainingTime > 1 ? 's' : ''}",
        );
        return;
      } else {
        ReleaseLogger.log("OTP lock expired, resetting attempts");
        setState(() {
          _otpLocked = false;
          _otpAttempts = 0;
        });
      }
    }

    if (_otpController.text.length != 6) {
      ReleaseLogger.log("Incomplete OTP entered");
      _showErrorSnackbar("Please enter the complete 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_otpFromBackend == null || _otpController.text != _otpFromBackend) {
        ReleaseLogger.log("Invalid OTP entered, attempt $_otpAttempts");
        setState(() {
          _otpAttempts++;
          if (_otpAttempts >= 3) {
            _otpLocked = true;
            _otpLockTime = DateTime.now();
            ReleaseLogger.log(
                "OTP verification locked due to too many attempts");
          }
        });

        _otpController.clear();

        if (_otpLocked) {
          _showErrorSnackbar(
            "Too many incorrect attempts. Please try again after 5 minutes.",
          );
        } else {
          final remainingAttempts = 3 - _otpAttempts;
          _showErrorSnackbar(
            "Invalid OTP. $remainingAttempts attempt${remainingAttempts > 1 ? 's' : ''} remaining.",
          );
        }
        return;
      }

      ReleaseLogger.log(
          "OTP verified successfully, proceeding with registration");
      final response = await RegistrationService.registerUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        dob: _dobController.text.trim(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ReleaseLogger.log("Registration successful");
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        ReleaseLogger.log(responseData.toString());
        await _storeUserData(responseData);
        if (mounted) {
          _showConnectDialog();
        }
      } else {
        ReleaseLogger.log("Registration failed: ${response.body}",
            level: LogLevel.error);
        if (mounted) {
          _showErrorSnackbar("Registration failed: ${response.body}");
        }
      }
    } catch (e) {
      ReleaseLogger.log("Error during registration: ${e.toString()}",
          level: LogLevel.error);
      if (mounted) {
        _showErrorSnackbar("Error: ${e.toString()}");
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _storeUserData(Map<String, dynamic> responseData) async {
    ReleaseLogger.log("Storing user data in secure storage");
    try {
      await storage.write(
          key: 'user_email', value: _emailController.text.trim());
      await storage.write(
          key: 'user_fullname', value: _fullNameController.text.trim());
      String token = md5
          .convert(utf8.encode(
              '${_emailController.text.trim()}${_fullNameController.text.trim()}'))
          .toString();
      await storage.write(key: 'sess_token', value: token);

      //: Add User balance
      // await storage.write(
      //   key: 'user_balance',
      //   value: int.parse(responseData['balance'].toString()).toString(),
      // );
      await storage.write(key: 'user_logged_in', value: 'true');
      ReleaseLogger.log("User data stored successfully");
    } catch (e) {
      ReleaseLogger.log("Error storing user data: $e", level: LogLevel.error);
      rethrow;
    }
  }

  Future<void> _sendOtp() async {
    ReleaseLogger.log("Sending OTP to email");
    setState(() => _isLoading = true);
    try {
      final response =
          await RegistrationService.sendOtp(_emailController.text.trim());

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        ReleaseLogger.log("OTP sent successfully, OTP: ${responseData['otp']}");
        setState(() {
          _otpFromBackend = responseData['otp'].toString();
          _otpAttempts = 0;
          _otpLocked = false;
          _resendCountdown = 30;
          _startResendTimer();
        });
        _showSuccessSnackbar("OTP sent to ${_emailController.text.trim()}");
        setState(() => _currentStep++);
      } else {
        ReleaseLogger.log("Failed to send OTP: ${response.body}",
            level: LogLevel.error);
        _showErrorSnackbar("Failed to send OTP: ${response.body}");
      }
    } catch (e) {
      ReleaseLogger.log("Error sending OTP: ${e.toString()}",
          level: LogLevel.error);
      _showErrorSnackbar("Error sending OTP: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackbar(String message) {
    ReleaseLogger.log("Showing error snackbar: $message",
        level: LogLevel.warning);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ReleaseLogger.log("Showing success snackbar: $message");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.greenAccent,
      ),
    );
  }

  void _showConnectDialog() {
    final provider = Platform.isIOS ? 'Apple' : 'Google';
    final icon = Platform.isIOS ? FontAwesome.apple : FontAwesome.google;

    ReleaseLogger.log("Showing connect with $provider dialog");
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF002218),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Connect with $provider?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Would you like to link your account with your $provider ID for easier login?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ReleaseLogger.log("User skipped $provider connection");
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Skip', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton.icon(
            icon: Icon(icon, color: Colors.black),
            label: Text(
              'Connect with $provider',
              style: const TextStyle(color: Colors.black),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent[400],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            onPressed: () {
              final _gmailaddr = _authService.storage.read(key: 'user_email');
              ReleaseLogger.log(
                  "User connected with $provider and email $_gmailaddr");
              _authService.signInWithGoogle;
              if (_gmailaddr.toString().trim() ==
                  _emailController.text.trim()) {}
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    return Form(
      key: _formKey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _getCurrentStepWidget(),
      ),
    );
  }

  Widget _getCurrentStepWidget() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalInfoStep();
      case 1:
        return _buildEmailStep();
      case 2:
        return _buildPasswordStep();
      case 3:
        return _buildOtpStep(); // Changed from _buildConfirmPasswordStep()
      default:
        return const SizedBox();
    }
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _fullNameController,
          label: "Full Name",
          validator: (value) {
            if (value == null || value.isEmpty) {
              ReleaseLogger.log("Full name validation failed: empty");
              return "Please enter your full name";
            }
            if (value.length < 3) {
              ReleaseLogger.log("Full name validation failed: too short");
              return "Name too short";
            }
            if (RegExp(r'[0-9]').hasMatch(value)) {
              ReleaseLogger.log(
                  "Full name validation failed: contains numbers");
              return "Name cannot contain numbers";
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        CustomTextFormField(
          controller: _dobController,
          label: "Date of Birth",
          readOnly: true,
          onTap: () => _selectDate(context),
          validator: (value) {
            if (value == null || value.isEmpty) {
              ReleaseLogger.log("DOB validation failed: empty");
              return "Please select your date of birth";
            }
            try {
              final dob = DateTime.parse(value);
              final age = DateTime.now().difference(dob).inDays ~/ 365;
              if (age < 18) {
                ReleaseLogger.log("DOB validation failed: under 18");
                return "You must be at least 18 years old";
              }
            } catch (_) {
              ReleaseLogger.log("DOB validation failed: invalid format");
              return "Invalid date format";
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildEmailStep() {
    return CustomTextFormField(
      controller: _emailController,
      label: "Email address",
      keyboardType: TextInputType.emailAddress,
      focusNode: _emailFocus,
      validator: (value) {
        if (value == null || value.isEmpty) {
          ReleaseLogger.log("Email validation failed: empty");
          return "Please enter your email";
        }
        if (!EmailValidator.validate(value)) {
          ReleaseLogger.log("Email validation failed: invalid format");
          return "Please enter a valid email";
        }
        return null;
      },
    );
  }

  Widget _buildPasswordStep() {
    return Column(
      children: [
        CustomTextFormField(
          controller: _passwordController,
          label: "Password",
          obscureText: true,
          focusNode: _passwordFocus,
          validator: (value) => _validatePassword(value),
        ),
        const SizedBox(height: 8),
        PasswordStrengthIndicator(controller: _passwordController),
        const SizedBox(height: 16),
        _buildConfirmPasswordStep()
      ],
    );
  }

  Widget _buildConfirmPasswordStep() {
    return CustomTextFormField(
      controller: _confirmPasswordController,
      label: "Confirm Password",
      obscureText: true,
      focusNode: _confirmPasswordFocus,
      validator: (value) {
        if (value != _passwordController.text) {
          ReleaseLogger.log(
              "Password confirmation validation failed: mismatch");
          return "Passwords don't match";
        }
        return null;
      },
    );
  }

  Widget _buildOtpStep() {
    return Column(
      children: [
        const Text(
          "Enter the 6-digit OTP sent to your email",
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 20),
        OtpInputField(
          controller: _otpController,
          onCompleted: _handleRegistration,
        ),
        const SizedBox(height: 16),
        if (_resendCountdown > 0)
          Text(
            "Resend OTP in $_resendCountdown seconds",
            style: const TextStyle(color: Colors.white54),
          )
        else
          TextButton(
            onPressed: _sendOtp,
            child: const Text(
              "Resend OTP",
              style: TextStyle(color: Colors.greenAccent),
            ),
          ),
        if (_otpLocked && _otpLockTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              "Too many attempts. Please try again after ${5 - DateTime.now().difference(_otpLockTime!).inMinutes} minutes.",
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      ReleaseLogger.log("Password validation failed: empty");
      return "Please enter a password";
    }
    if (value.length < 8) {
      ReleaseLogger.log("Password validation failed: too short");
      return "Password must be at least 8 characters";
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      ReleaseLogger.log("Password validation failed: no uppercase");
      return "Include at least one uppercase letter";
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      ReleaseLogger.log("Password validation failed: no number");
      return "Include at least one number";
    }
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      ReleaseLogger.log("Password validation failed: no special character");
      return "Include at least one special character";
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context) async {
    ReleaseLogger.log("Showing date picker");
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      ReleaseLogger.log("Date selected: $picked");
      _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
    } else {
      ReleaseLogger.log("Date selection cancelled");
    }
  }

  String _getButtonLabel() {
    switch (_currentStep) {
      case 0:
        return "Continue";
      case 1:
        return "Continue";
      case 2:
        return "Send OTP"; // Changed from "Continue"
      case 3:
        return _isLoading ? "Verifying..." : "Verify OTP";
      default:
        return "---";
    }
  }

  @override
  Widget build(BuildContext context) {
    // ReleaseLogger.log("Building RegisterScreen, current step: $_currentStep");
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                const AppLogoHeader(),
                const SizedBox(height: 40),
                Text(
                  _currentStep == 4 ? "Verify OTP" : "Create an Account",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _currentStep == 4
                      ? "Enter the 6-digit code sent to ${_emailController.text.trim()}"
                      : "To create an account provide details, verify email and set a password.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54),
                ),
                const SizedBox(height: 32),
                if (_currentStep == 0) ...[
                  SocialAuthButtons(
                    onGooglePressed: _handleGoogleSignIn,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Or",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                ],
                Expanded(child: _buildStepContent()),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent[400],
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: (_isLoading || (_currentStep == 3 && _otpLocked))
                      ? null
                      : () {
                          if (_currentStep == 2) {
                            // Changed from 3
                            ReleaseLogger.log("Send OTP button pressed");
                            _sendOtp();
                          } else if (_currentStep == 3) {
                            // Changed from 4
                            ReleaseLogger.log("Verify OTP button pressed");
                            _verifyOtpAndRegister();
                          } else {
                            ReleaseLogger.log("Continue button pressed");
                            _handleRegistration();
                          }
                        },
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          _getButtonLabel(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                ),
                if (_currentStep != 4) ...[
                  const SizedBox(height: 20),
                  const LoginPrompt(),
                ],
                const SizedBox(height: 16),
                const TermsAndPrivacyFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    ReleaseLogger.log("Google Sign-In initiated");
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        ReleaseLogger.log("Google Sign-In successful");
        await storage.write(key: 'user_logged_in', value: 'true');
        if (mounted) Navigator.pushReplacementNamed(context, '/home');
      } else {
        ReleaseLogger.log("Google Sign-In failed: null user",
            level: LogLevel.error);
        _showErrorSnackbar("Google Sign-In failed");
      }
    } catch (e) {
      ReleaseLogger.log("Error during Google Sign-In: ${e.toString()}",
          level: LogLevel.error);
      _showErrorSnackbar("Error during Google Sign-In: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

// Custom Widgets
class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/appicon.png', height: 48),
        const SizedBox(width: 8),
        const Text(
          "JiboMonie",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class SocialAuthButtons extends StatelessWidget {
  final VoidCallback onGooglePressed;
  final bool isLoading;

  const SocialAuthButtons({
    required this.onGooglePressed,
    required this.isLoading,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        AuthButton(
          icon: FontAwesome.apple,
          label: "Apple",
          bgColor: Colors.white,
          textColor: Colors.white,
          onPressed: () {
            ReleaseLogger.log("Apple Sign-In button pressed");
          },
        ),
        isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white))
            : AuthButton(
                icon: FontAwesome.google,
                label: "Google",
                bgColor: Colors.white,
                textColor: Colors.white,
                onPressed: onGooglePressed,
              ),
      ],
    );
  }
}

class LoginPrompt extends StatelessWidget {
  const LoginPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () {
          ReleaseLogger.log("Login prompt tapped");
          Navigator.pushReplacementNamed(context, '/login');
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
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TermsAndPrivacyFooter extends StatelessWidget {
  const TermsAndPrivacyFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Terms of Service | Privacy Policy",
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final bool readOnly;
  final TextInputType? keyboardType;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final Widget? suffixIcon;

  const CustomTextFormField({
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType,
    this.focusNode,
    this.validator,
    this.onTap,
    this.suffixIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            readOnly: readOnly,
            keyboardType: keyboardType,
            focusNode: focusNode,
            validator: validator,
            onTap: onTap,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Colors.white54),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ),
    );
  }
}

class OtpInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onCompleted;

  const OtpInputField({
    required this.controller,
    required this.onCompleted,
    super.key,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> digitControllers;
  late List<FocusNode> focusNodes;

  @override
  void initState() {
    super.initState();
    ReleaseLogger.log("Initializing OTP input field");
    digitControllers = List.generate(6, (index) => TextEditingController());
    focusNodes = List.generate(6, (index) => FocusNode());
    widget.controller.text = ''; // Initialize main controller
  }

  @override
  void dispose() {
    ReleaseLogger.log("Disposing OTP input field");
    for (var controller in digitControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _updateMainController() {
    widget.controller.text = digitControllers.map((c) => c.text).join();
    if (widget.controller.text.length == 6) {
      ReleaseLogger.log("OTP input completed");
      widget.onCompleted();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          child: TextField(
            controller: digitControllers[index],
            focusNode: focusNodes[index],
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
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).requestFocus(focusNodes[index + 1]);
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).requestFocus(focusNodes[index - 1]);
              }
              _updateMainController();
            },
          ),
        );
      }),
    );
  }
}

class PasswordStrengthIndicator extends StatefulWidget {
  final TextEditingController controller;
  final double indicatorHeight;
  final TextStyle? textStyle;

  const PasswordStrengthIndicator({
    required this.controller,
    this.indicatorHeight = 4.0,
    this.textStyle,
    super.key,
  });

  @override
  State<PasswordStrengthIndicator> createState() =>
      _PasswordStrengthIndicatorState();
}

class _PasswordStrengthIndicatorState extends State<PasswordStrengthIndicator> {
  late PasswordStrength _strength;

  @override
  void initState() {
    super.initState();
    _strength = _calculateStrength(widget.controller.text);
    widget.controller.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onPasswordChanged);
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _strength = _calculateStrength(widget.controller.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: _strength.value,
          backgroundColor: Colors.grey[300],
          color: _strength.color,
          minHeight: widget.indicatorHeight,
          borderRadius: BorderRadius.circular(widget.indicatorHeight / 2),
        ),
        if (_strength.message.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _strength.message,
            style: widget.textStyle?.copyWith(color: _strength.color) ??
                TextStyle(
                  color: _strength.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ],
    );
  }

  PasswordStrength _calculateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.empty();

    double strength = 0;
    bool hasLength = password.length >= 8;
    bool hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
    bool hasDigits = RegExp(r'[0-9]').hasMatch(password);
    bool hasSpecialChars = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);

    // Calculate strength with weights
    if (hasLength) strength += 0.3;
    if (hasUppercase) strength += 0.2;
    if (hasDigits) strength += 0.2;
    if (hasSpecialChars) strength += 0.3;

    // Additional checks for very short passwords
    if (password.length < 4) strength = 0.1;

    return PasswordStrength.fromValue(strength);
  }
}

class PasswordStrength {
  final double value;
  final Color color;
  final String message;

  PasswordStrength({
    required this.value,
    required this.color,
    required this.message,
  });

  factory PasswordStrength.empty() {
    return PasswordStrength(
      value: 0,
      color: Colors.grey,
      message: "",
    );
  }

  factory PasswordStrength.fromValue(double strength) {
    if (strength < 0.3) {
      return PasswordStrength(
        value: strength,
        color: Colors.red,
        message: "Weak - add more characters or complexity",
      );
    } else if (strength < 0.6) {
      return PasswordStrength(
        value: strength,
        color: Colors.orange,
        message: "Fair - could be stronger",
      );
    } else if (strength < 0.8) {
      return PasswordStrength(
        value: strength,
        color: Colors.blue,
        message: "Good",
      );
    } else {
      return PasswordStrength(
        value: strength,
        color: Colors.green,
        message: "Strong password!",
      );
    }
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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: bgColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(30),
            splashColor: Colors.white.withOpacity(0.1),
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
