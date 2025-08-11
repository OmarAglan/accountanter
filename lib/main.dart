import 'package:accountanter/features/auth/login_screen.dart';
import 'package:accountanter/features/main/main_screen.dart'; // We will create this next
import 'package:accountanter/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isAuthenticated = false;

  void _login() {
    setState(() {
      _isAuthenticated = true;
    });
  }

  void _logout() {
    setState(() {
      _isAuthenticated = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accountanter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _isAuthenticated
          ? MainScreen(onLogout: _logout) // If logged in, show the main app
          : LoginScreen(onLogin: _login), // Otherwise, show the login screen
    );
  }
}