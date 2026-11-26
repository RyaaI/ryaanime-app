import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth_gate.dart';
import 'screens/main_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isLoggedIn = prefs.getBool('logged_in') ?? false;
  runApp(RyaaNimeApp(isLoggedIn: isLoggedIn));
}

class RyaaNimeApp extends StatelessWidget {
  final bool isLoggedIn;
  const RyaaNimeApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RyaaNime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF38BDF8),
          secondary: Color(0xFFFBBF24),
          surface: Color(0xFF111827),
        ),
      ),
      home: isLoggedIn
          ? const MainNav()
          : AuthGate(onAuthenticated: () => const MainNav()),
    );
  }
}
