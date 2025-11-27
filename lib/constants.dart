import 'package:flutter/material.dart';

// Base / Primary Colors
const Color kPrimaryColor =  Color(0xFF0D2851); // Dark Blue
const Color kAccentColor = Color(0xFF1976D2);  // Lighter Blue
const Color kBackgroundColor = Color(0xFFF5F5F5); // Light grey background
const Color kFieldBackgroundColor = Colors.white; // TextField background
const Color backgroundColor =  Color(0xFFF7F9FC);
const String baseURL= "http://cshdxb.ddns.net:3010";
  const String xjwtsecret= "80384bcd0c04af5d29743362aa6a242edc8e3366ca1fa1f097f69d11576fb2f1568a6cfa7b7ff8401edb96beb04274167b8bdc7cca9a7c6a93755db24a80d";

String toSentenceCase(String value) {
  // replace underscores with spaces
  value = value.replaceAll('_', ' ');

  if (value.isEmpty) return value;

  // capitalize first letter only
  return value[0].toUpperCase() + value.substring(1).toLowerCase();
}

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
