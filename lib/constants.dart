import 'package:flutter/material.dart';

// Base / Primary Colors
const Color kPrimaryColor =  Color(0xFF0D2851); // Dark Blue
const Color kAccentColor = Color(0xFF1976D2);  // Lighter Blue
const Color kBackgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color kFieldBackgroundColor = Colors.white; // TextField background
const Color backgroundColor =  Color(0xFFF7F9FC);
const String baseURL= "http://192.168.2.185:3001";



class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
          MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double maxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1440) return 1200;
    if (width >= 1024) return 900;
    if (width >= 600) return 600;
    return width * 0.95;
  }
}
