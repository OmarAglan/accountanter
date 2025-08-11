import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

class LoginScreen extends StatefulWidget {
  // The onLogin callback is equivalent to the one in your React component
  final VoidCallback onLogin;

  const LoginScreen({super.key, required this.onLogin});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _handleSubmit() {
    // This is equivalent to your handleSubmit function
    if (_formKey.currentState?.validate() ?? false) {
      widget.onLogin();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Header
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        LucideIcons.package,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Accountanter',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 24
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Welcome Back',
                      textAlign: TextAlign.center,
                      style: textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to manage your business finances',
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    Text('Email Address', style: textTheme.labelLarge?.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'Enter your email',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty || !value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    Text('Password', style: textTheme.labelLarge?.copyWith(fontSize: 14)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        hintText: 'Enter your password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                            size: 16,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _showPassword = !_showPassword;
                            });
                          },
                        ),
                      ),
                       validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: _handleSubmit,
                      child: const Text('Login'),
                    ),
                    const SizedBox(height: 16),

                    // Forgot Password Link
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // TODO: Handle forgot password logic
                        },
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}