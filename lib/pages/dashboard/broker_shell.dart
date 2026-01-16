import 'package:flutter/material.dart';
import '../../constants.dart';
import 'sidebar_broker.dart';

class BrokerShell extends StatelessWidget {
  final Map<String, dynamic> userData;
  final Widget child;

  const BrokerShell({
    super.key,
    required this.userData,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Row(
        children: [
          /// -------- BROKER SIDEBAR --------
          BrokerSidebar(
            userData: userData,
          ),

          /// -------- ROUTED CONTENT --------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: child, // 🔑 router controls this
            ),
          ),
        ],
      ),
    );
  }
}
