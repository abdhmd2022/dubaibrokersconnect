import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'pages/login/login_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override

  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dubai Brokers Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,

        // 👇 Global loader color
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kPrimaryColor,
          circularTrackColor: Colors.white,
        ),

        // 👇 Primary color scheme (light theme)
        colorScheme: ColorScheme.light(
          primary: kPrimaryColor,
          secondary: kAccentColor,
        ),

        // 👇 TextField styling across app
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: kPrimaryColor, width: 1.6),
          ),
          labelStyle: const TextStyle(color: Colors.black54),
          floatingLabelStyle: const TextStyle(
            color: kPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),

        // 👇 Softer text selection highlight
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: kPrimaryColor,
          selectionColor: kPrimaryColor.withOpacity(0.25),  // soft, subtle highlight
          selectionHandleColor: kPrimaryColor,
        ),

        // 👇 Ripple and glow controls
        splashColor: kPrimaryColor.withOpacity(0.12),
        highlightColor: Colors.transparent,
      ),

        home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
