import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a2abrokerapp/constants.dart';
import 'package:a2abrokerapp/pages/dashboard/admindashboard.dart';
import 'package:a2abrokerapp/pages/dashboard/brokerdashboard.dart';

import '../../services/session_service.dart';
import '../brokermanagement/broker_setup_page.dart';
import '../dashboard/admin_shell.dart';
import '../dashboard/broker_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum AuthMode { login, signup, forgot, emailVerify }

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
  List.generate(4, (_) => TextEditingController());

  final List<FocusNode> _focusNodes =
  List.generate(4, (_) => FocusNode());

  int _resendSeconds = 60;
  Timer? _timer;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  int forgotStep = 1;
  String? _resetOtp;
  String? _resetEmail;
  final _otpController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmNewPassController = TextEditingController();

  bool _isLoading = false;
  AuthMode _mode = AuthMode.login;

  void _startTimer() {
    _resendSeconds = 60;
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _resetPassword() async {
    if (_newPassController.text.trim().isEmpty ||
        _confirmNewPassController.text.trim().isEmpty) {
      _showError("Enter all fields");
      return;
    }

    if (_newPassController.text.trim() !=
        _confirmNewPassController.text.trim()) {
      _showError("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('$baseURL/api/auth/reset-password');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _resetEmail,
          "otp": _resetOtp,
          "password": _newPassController.text.trim(),
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Password reset successfully"),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _mode = AuthMode.login;
          forgotStep = 1;
        });
      } else {
        _showError(data['message'] ?? "Password reset failed");
      }
    } catch (e) {
      _showError("Error: $e");
    }

    setState(() => _isLoading = false);
  }


  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('email');
    final savedPassword = prefs.getString('password');

    if (savedEmail != null && savedPassword != null) {
      _emailController.text = savedEmail;
      _passwordController.text = savedPassword;
      _rememberMe = true;
      _login(autoLogin: true);
    }
  }

  Future<void> _login({bool autoLogin = false}) async {


    if (!autoLogin && !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('$baseURL/api/auth/login');
    final body = {
      'email': _emailController.text.trim(),
      'password': _passwordController.text.trim(),
    };

    try {
      final res = await http.post(
        url,
        headers: {
          'x-jwt-secret' : xjwtsecret,
          'Content-Type': 'application/json'
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {


        final userData = data['data']['user'];
        final accessToken = data['data']['accessToken'];
        final refreshToken = data['data']['refreshToken'];
        final prefs = await SharedPreferences.getInstance();

        final isVerified = userData['broker']?['isVerified'] ?? false;
        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_id', userData['id'].toString());
        await prefs.setBool('isVerified',isVerified );


        print('token ->>>> $accessToken');





        if (_rememberMe) {
          await prefs.setString('email', _emailController.text.trim());
          await prefs.setString('password', _passwordController.text.trim());
        }

        final isEmailVerified = userData['isEmailVerified'] ?? false;

        await prefs.setString(
          'user_data',
          jsonEncode(userData),
        );

        if (!isEmailVerified) {
          setState(() {
            _mode = AuthMode.emailVerify;
            _resetEmail = userData['email'];
          });
          _startTimer(); // 🔥 start countdown immediately

          return; // 🚨 stop here (no navigation)
        }

        // ✅ Role-based Navigation
        if (userData['role'] == 'ADMIN') {
          context.go('/admin/dashboard');

        } else if (userData['role'] == 'BROKER') {

          final broker = userData['broker'];

          // Broker setup incomplete cases:
          // 1. broker == null
          // 2. broker = {}
          // 3. broker.id == null
          // 4. broker.isVerified == false

          final bool isBrokerMissing =
              broker == null ||
                  (broker is Map && broker.isEmpty) ||
                  broker?['id'] == null;

          if (isBrokerMissing) {
            print('Broker is NULL / EMPTY → Navigating to setup');
            context.go('/broker/setup', extra: userData);
          } else {
            print('Broker exists → Navigating to dashboard');
            context.go('/broker/dashboard', extra: userData);
          }
        }
      } else {
        _showError(data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      _showError('Error connecting to server → $e');
      print('login response -> ${e}');

    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final url = Uri.parse('$baseURL/api/auth/register');
    final body = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "first_name": _firstNameController.text.trim(),
      "last_name": _lastNameController.text.trim(),
      // "phone": _phoneController.text.trim(),
    };

    try {
      final res = await http.post(
        url,
        headers: {
          'x-jwt-secret' : xjwtsecret,
          'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {

        print('registration response -> ${data}');
        // final userData = data['data']['user'];
        //final accessToken = data['data']['accessToken'];
        // Save user & token for next screen
        //final prefs = await SharedPreferences.getInstance();
       // await prefs.setString('access_token', accessToken);
        //await prefs.setString('user_id', userData['id'].toString());

        // 🚀 Go to Broker Setup Page instead of Login
       /* Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BrokerSetupPage(userData: userData)),

        );*/
        setState(() => _mode = AuthMode.login);
      } else {
        _showError(data['message'] ?? 'Registration failed');
        print('registration response -> ${data}');
      }
    } catch (e) {
      _showError('Error connecting to server.');
      print('registration response -> ${e}');

    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _verifyEmailOtp() async {
    final otp = getOtp();

    if (otp.isEmpty) {
      _showError("Please enter OTP");
      return;
    }


    // ✅ STEP 6: Validation (this was missing)
    if (otp.isEmpty || otp.length < 4) {
      _showError("Please enter complete 4-digit OTP");
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('$baseURL/api/auth/verify-email');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _resetEmail,
          "otp": otp,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email verified successfully"),
            backgroundColor: Colors.green,
          ),
        );

        _goToDashboard(); // 🚀 continue normal flow
      } else {
        _showError(data['message'] ?? "Invalid OTP");
      }
    } catch (e) {
      _showError("Verification failed");
    }

    setState(() => _isLoading = false);
  }

  void _goToDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonDecode(prefs.getString('user_data')!);

    if (userData['role'] == 'ADMIN') {
      context.go('/admin/dashboard');
    } else if (userData['role'] == 'BROKER') {
      final broker = userData['broker'];

      final bool isBrokerMissing =
          broker == null ||
              (broker is Map && broker.isEmpty) ||
              broker?['id'] == null;

      if (isBrokerMissing) {
        context.go('/broker/setup', extra: userData);
      } else {
        context.go('/broker/dashboard', extra: userData);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final scrollController = ScrollController();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        radius: const Radius.circular(10),
        thickness: 8,
        child: SingleChildScrollView(
          controller: scrollController,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: height),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                child: Container(
                  width: width > 600 ? 480 : width * 0.95,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.1),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 24),
                        _buildTitle(width),
                        const SizedBox(height: 30),
                        if (_mode == AuthMode.login) _buildLoginFields(),
                        if (_mode == AuthMode.signup) _buildSignupFields(),
                        if (_mode == AuthMode.forgot) _buildForgotPassword(),
                        if (_mode == AuthMode.emailVerify) _buildEmailVerification(),

                        const SizedBox(height: 20),

                        // ✅ Remember Me (Login Only)
                        if (_mode == AuthMode.login)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: kPrimaryColor,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                              ),
                              const Text("Remember Me"),
                            ],
                          ),

                        const SizedBox(height: 10),
                        _buildActionButton(),
                        const SizedBox(height: 18),
                        _buildToggleText(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Container(
    height: 110,
    width: 110,
    decoration: BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: Colors.black12.withOpacity(0.2),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
      border: Border.all(color: Colors.grey.shade200, width: 1.2),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: ClipOval(
        child: Image.asset('assets/collabrix_logo.png', fit: BoxFit.contain),
      ),
    ),
  );

  Future<void> _sendResetOtp() async {
    if (_emailController.text.trim().isEmpty) {
      _showError("Please enter your email");
      return;
    }

    setState(() => _isLoading = true);

    final url = Uri.parse('$baseURL/api/auth/forgot-password');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": _emailController.text.trim()}),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        if(data['data'] == null)
        {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message']),
                backgroundColor: Colors.green,
              ),
            );
        }
        else
        {
            final resetOtp = data['data']?['resetOtp'];

            print('data -> $data');

            if (resetOtp == null) {
              _showError("OTP not received from server");
              return;
            }

            _resetOtp = resetOtp;
            _resetEmail = _emailController.text.trim();

            setState(() {
              forgotStep = 2; // Move to OTP screen
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("OTP sent to your email"),
                backgroundColor: Colors.green,
              ),
            );
          }
          }
      else {
        _showError(data['message'] ?? "Failed to send OTP");
      }

    } catch (e) {
      _showError("Error: $e");
    }

    setState(() => _isLoading = false);
  }
  void _verifyOtp() {
    if (_otpController.text.trim() == _resetOtp) {
      setState(() {
        forgotStep = 3; // Show new password fields
      });
    } else {
      _showError("Incorrect OTP");
    }
  }



  Widget _buildTitle(double width) {
    return Column(
      children: [
        Text(
          'Welcome to Dubai Realtors Collaboration Hub',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: width > 600 ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _mode == AuthMode.login
              ? 'Sign in to continue'
              : _mode == AuthMode.signup
              ? 'Create your account'
              : _mode == AuthMode.forgot
              ? 'Recover your password'
              : '',
          style:  GoogleFonts.poppins(fontSize: 15, color: Colors.black54),
        ),
      ],
    );



  }

  Widget _buildLoginFields() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => setState(() => _mode = AuthMode.forgot),
            child: Text('Forgot Password?', style: GoogleFonts.poppins(color: kPrimaryColor)),
          ),
        ),
      ],
    );
  }

  Widget _buildSignupFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _firstNameController,
                label: 'First Name',
                icon: Icons.person_outline,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _lastNameController,
                label: 'Last Name',
                icon: Icons.person_outline,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Email',
          icon: Icons.email_outlined,
          inputType: TextInputType.emailAddress,
        ),
        /*const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          inputType: TextInputType.phone,
        ),*/
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          label: 'Password',
          icon: Icons.lock_outline,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          icon: Icons.lock_reset_outlined,
          isPassword: true,
        ),
      ],
    );
  }

  Widget _buildForgotPassword() {
    if (forgotStep == 1) {
      return Column(
        children: [
          _buildTextField(
            controller: _emailController,
            label: 'Enter your registered email',
            icon: Icons.email_outlined,
            inputType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
           Text(
            "We will send an OTP to your email.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(color: Colors.black54),
          ),
        ],
      );
    }

    if (forgotStep == 2) {
      return Column(
        children: [
          const Text("Enter the OTP sent to your email"),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _otpController,
            label: 'Enter OTP',
            icon: Icons.lock_outline,
            isPassword: true,   // 👈 Hide OTP

          ),
        ],
      );
    }

    if (forgotStep == 3) {
      return Column(
        children: [
          const Text("Reset Your Password"),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _newPassController,
            label: 'New Password',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _confirmNewPassController,
            label: 'Confirm Password',
            icon: Icons.lock_reset_outlined,
            isPassword: true,
          ),
        ],
      );
    }

    return Container();
  }

  String maskEmail(String email) {
    final parts = email.split('@');
    return parts[0].substring(0, 2) + "***@" + parts[1];
  }

  Widget _buildActionButton() {
    final btnText = _mode == AuthMode.login
        ? 'Sign In'
        : _mode == AuthMode.signup
        ? 'Sign Up'
        : _mode == AuthMode.forgot
        ? (forgotStep == 1
        ? 'Send OTP'
        : forgotStep == 2
        ? 'Verify OTP'
        : 'Reset Password')
        : 'Verify Email';


    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : _mode == AuthMode.login
            ? _login
            : _mode == AuthMode.signup
            ? _register
            : _mode == AuthMode.forgot
            ? (forgotStep == 1
            ? _sendResetOtp
            : forgotStep == 2
            ? _verifyOtp
            : _resetPassword)
            : _verifyEmailOtp,

        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [kPrimaryColor, kPrimaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(
              btnText,
              style:  GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _mode == AuthMode.login
              ? "Don't have an account? "
              : _mode == AuthMode.signup
              ? "Already have an account? "
              : "Remembered your password? ",
          style:  GoogleFonts.poppins(color: Colors.black54),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              if (_mode == AuthMode.login) {
                _mode = AuthMode.signup;
              } else {
                _mode = AuthMode.login;
              }
            });
          },
          child: Text(
            _mode == AuthMode.login ? 'Sign Up' : 'Sign In',
            style: GoogleFonts.poppins(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? inputType,
    bool isPassword = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword
          ? (label.toLowerCase().contains('confirm')
          ? _obscureConfirmPassword
          : _obscurePassword)
          : false,
      keyboardType: inputType,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Please enter $label';
        if (label == 'Confirm Password' &&
            v.trim() != _passwordController.text.trim()) {
          return 'Passwords do not match';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle:  GoogleFonts.poppins(color: Colors.black87),
        prefixIcon: Icon(icon, color: kPrimaryColor),
        filled: true,
        fillColor: kFieldBackgroundColor,
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: kPrimaryColor, width: 1.2),
        ),
        // 👁 Eye toggle button (works for Login + Signup)
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            (label.toLowerCase().contains('confirm')
                ? _obscureConfirmPassword
                : _obscurePassword)
                ? Icons.visibility_off
                : Icons.visibility,
            color: (label.toLowerCase().contains('confirm')
                ? !_obscureConfirmPassword
                : !_obscurePassword)
                ? kPrimaryColor
                : Colors.grey[700],
          ),
          onPressed: () {
            setState(() {
              if (label.toLowerCase().contains('confirm')) {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              } else {
                _obscurePassword = !_obscurePassword;
              }
            });
          },
        )
            : null,
      ),
    );
  }

  Widget _buildEmailVerification() {
    return Column(
      children: [
         Text(
          "Verify Your Email",
          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        Text(
          "Enter the 4-digit code sent to\n${maskEmail(_resetEmail!)}",
          textAlign: TextAlign.center,
          style:  GoogleFonts.poppins(color: Colors.black54),
        ),

        const SizedBox(height: 30),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _buildOtpBox(index),
            );
          }),
        ),

        const SizedBox(height: 20),

        GestureDetector(
          onTap: (_resendSeconds == 0 && !_isLoading)
              ? _resendVerificationOtp
              : null,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _resendSeconds == 0 ? 1 : 0.5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (_isLoading) const SizedBox(width: 8),

                Text(
                  _resendSeconds == 0
                      ? "Resend OTP"
                      : "Resend in $_resendSeconds s",
                  style: GoogleFonts.poppins(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 58,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,



      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        maxLength: 1,
        style:  GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              _autoSubmitOtp();
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
          setState(() {});
        },
      ),
    );
  }


  String getOtp() {
    return _otpControllers.map((c) => c.text).join();
  }

  void _autoSubmitOtp() {
    final otp = getOtp();

    if (otp.length == 4) {
      _verifyEmailOtp(); // your API call
    }
  }

  Future<void> _resendVerificationOtp() async {
    if (_resetEmail == null) return;

    setState(() => _isLoading = true);

    final url = Uri.parse('$baseURL/api/auth/resend-verification');

    try {
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": _resetEmail,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("OTP resent successfully"),
            backgroundColor: Colors.green,
          ),
        );

        _clearOtpFields();   // 🧹 clear old input
        _startTimer();       // 🔁 restart countdown
      } else {
        _showError(data['message'] ?? "Failed to resend OTP");
      }
    } catch (e) {
      _showError("Error resending OTP");
    }

    setState(() => _isLoading = false);
  }

  void _clearOtpFields() {
    for (var c in _otpControllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus(); // back to first box
  }
}
