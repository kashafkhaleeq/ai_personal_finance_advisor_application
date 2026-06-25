import 'package:flutter/material.dart';
import 'package:finance_advisor/screens/home_shell.dart';
import 'screens/splash_screen.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FinanceApp());
}

class FinanceApp extends StatelessWidget {
  const FinanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Advisor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2E7D32),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),    );
  }
}