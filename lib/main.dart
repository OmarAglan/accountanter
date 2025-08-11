import 'package:accountanter/features/auth/login_screen.dart'; // Make sure the path is correct
import 'package:accountanter/theme/app_theme.dart'; // Import the theme
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accountanter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // Use our custom theme
      // For now, we start with the LoginScreen.
      // We will add routing logic later based on App.tsx.
      home: LoginScreen(
        onLogin: () {
          print('Login successful!');
          // Here we would navigate to the dashboard
        },
      ),
    );
  }
}