import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:a2abrokerapp/constants.dart';
import 'package:a2abrokerapp/pages/dashboard/admindashboard.dart';
import 'package:a2abrokerapp/pages/dashboard/brokerdashboard.dart';

import '../brokermanagement/broker_setup_page.dart';
import '../dashboard/admin_shell.dart';
import '../dashboard/broker_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

enum AuthMode { login, signup, forgot }

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _rememberMe = true;

  bool _isLoading = false;
  AuthMode _mode = AuthMode.login;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];
        final accessToken = data['data']['accessToken'];
        final refreshToken = data['data']['refreshToken'];
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('access_token', accessToken);
        await prefs.setString('refresh_token', refreshToken);
        await prefs.setString('user_id', userData['id'].toString());

        if (_rememberMe) {
          await prefs.setString('email', _emailController.text.trim());
          await prefs.setString('password', _passwordController.text.trim());
        }

        // ✅ Role-based Navigation
        if (userData['role'] == 'ADMIN') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => AdminShell(userData: userData)),
          );
        } else if (userData['role'] == 'BROKER') {
          if (userData['broker'] == null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => BrokerSetupPage(userData: userData),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => BrokerShell(userData: userData)),
            );
          }
        }
      } else {
        _showError(data['message'] ?? 'Invalid credentials');
      }
    } catch (e) {
      _showError('Error connecting to server → $e');
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
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final userData = data['data']['user'];
        final accessToken = data['data']['accessToken'];
        // Save user & token for next screen
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', accessToken);
        await prefs.setString('user_id', userData['id'].toString());

        // 🚀 Go to Broker Setup Page instead of Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => BrokerSetupPage(userData: userData)),

        );
        setState(() => _mode = AuthMode.login);
      } else {
        _showError(data['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _showError('Error connecting to server.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
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




  Widget _buildTitle(double width) {
    return Column(
      children: [
        Text(
          'Welcome to Dubai Realtors Collaboration Hub',
          textAlign: TextAlign.center,
          style: TextStyle(
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
              : 'Recover your password',
          style: const TextStyle(fontSize: 15, color: Colors.black54),
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
            child: Text('Forgot Password?', style: TextStyle(color: kPrimaryColor)),
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
          "We'll send password reset instructions to your email.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    final btnText = _mode == AuthMode.login
        ? 'Sign In'
        : _mode == AuthMode.signup
        ? 'Sign Up'
        : 'Send Reset Link';

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
            : () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset link sent!')),
        ),
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
              colors: [kPrimaryColor, kAccentColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.grey)
                : Text(
              btnText,
              style: const TextStyle(
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
          style: const TextStyle(color: Colors.black54),
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
            style: TextStyle(
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
        labelStyle: const TextStyle(color: Colors.black87),
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


}
