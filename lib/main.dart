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
      // 👇 Add this block to change the global CircularProgressIndicator color
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: kPrimaryColor, // change to your preferred color
        circularTrackColor: Colors.white, // optional
      ),
      // 👇 Change focus, cursor, splash, and highlight colors globally
      colorScheme: ColorScheme.light(primary: Colors.black,secondary: kPrimaryColor),
      inputDecorationTheme: const InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: kPrimaryColor, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
        labelStyle: TextStyle(color: Colors.black54),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: kPrimaryColor,          // blinking cursor
        selectionColor: kPrimaryColor, // text highlight
        selectionHandleColor: kPrimaryColor, // handle color
      ),
      splashColor: kPrimaryColor.withOpacity(0.2), // ripple effect
      highlightColor: Colors.transparent,        // optional, removes default purple glow
    ),
      home: LoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}
