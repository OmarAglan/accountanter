import 'package:accountanter/features/auth/activation_screen.dart';
import 'package:accountanter/features/auth/auth_service.dart';
import 'package:accountanter/features/auth/login_screen.dart';
import 'package:accountanter/features/main/main_screen.dart';
import 'package:accountanter/theme/app_theme.dart';
import 'package:flutter/material.dart';

// --- FIX: Enum is now declared outside the class ---
enum AppStatus { uninitialized, unactivated, loggedOut, loggedIn }

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  AppStatus _status = AppStatus.uninitialized;
  late final AuthService _authService;
  String? _prefilledUsername;

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _initializeApp();
  }
  
  @override
  void dispose() {
    _authService.dispose(); // Close the database connection
    super.dispose();
  }

  Future<void> _initializeApp() async {
    final isActivated = await _authService.isAppActivated();
    if (!isActivated) {
      setState(() => _status = AppStatus.unactivated);
      return;
    }

    final rememberedUser = await _authService.getLoggedInUser();
    if (rememberedUser != null) {
      setState(() => _status = AppStatus.loggedIn);
    } else {
      // Get the local username to pre-fill the login form
      final user = await _authService.database.getLocalUser();
      setState(() {
        _prefilledUsername = user?.username;
        _status = AppStatus.loggedOut;
      });
    }
  }

  void _onActivatedOrLoggedIn() {
    setState(() => _status = AppStatus.loggedIn);
  }
  
  void _onLogout() async {
    await _authService.logout();
    _initializeApp();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Accountanter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildHomeScreen(),
    );
  }

  Widget _buildHomeScreen() {
    switch (_status) {
      case AppStatus.uninitialized:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case AppStatus.unactivated:
        return ActivationScreen(onActivated: _initializeApp);
      case AppStatus.loggedOut:
        return LoginScreen(onLogin: _onActivatedOrLoggedIn, prefilledUsername: _prefilledUsername);
      case AppStatus.loggedIn:
        return MainScreen(onLogout: _onLogout);
    }
  }
}