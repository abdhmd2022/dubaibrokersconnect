import 'package:flutter/material.dart';
import 'constants.dart';
import 'pages/login/login_page.dart';
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dubai Brokers Connect',
      navigatorObservers: [routeObserver],

      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,

        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kPrimaryColor,
          circularTrackColor: Colors.white,
        ),
        colorScheme: const ColorScheme.light(
          primary: kPrimaryColor,
          secondary: kAccentColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: kPrimaryColor, width: 1.6),
          ),
        ),
      ),

      home: SelectableRegion(
        focusNode: FocusNode(),
        selectionControls: materialTextSelectionControls,
        child: LoginPage(),   // 👈 text inside here becomes selectable
      ),
    );
  }
}
