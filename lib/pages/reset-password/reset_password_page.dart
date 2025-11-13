import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../constants.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordC = TextEditingController();
  final _confirmC = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _resetPassword() async {
    if (_passwordC.text.trim().isEmpty ||
        _confirmC.text.trim().isEmpty) {
      _show("Please enter all fields");
      return;
    }

    if (_passwordC.text.trim() != _confirmC.text.trim()) {
      _show("Passwords do not match");
      return;
    }

    setState(() => _loading = true);

    final url = Uri.parse('$baseURL/api/auth/reset-password');

    final body = {
      "token": widget.token,
      "password": _passwordC.text.trim(),
    };

    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data["success"] == true) {
        _show("Password updated successfully!");
        Navigator.pushReplacementNamed(context, "/");
      } else {
        _show(data["message"] ?? "Reset failed");
      }
    } catch (e) {
      _show("Error: $e");
    }

    setState(() => _loading = false);
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Reset Password",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor)),
              const SizedBox(height: 20),

              TextField(
                controller: _passwordC,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: Icon(Icons.lock_outline, color: kPrimaryColor),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _confirmC,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: Icon(Icons.lock_reset_outlined, color: kPrimaryColor),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _loading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text("Update Password",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}