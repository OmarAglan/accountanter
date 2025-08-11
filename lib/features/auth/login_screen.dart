import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLogin;
  final String? prefilledUsername;

  const LoginScreen({super.key, required this.onLogin, this.prefilledUsername});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _showPassword = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  final _authService = AuthService();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledUsername != null) {
      _usernameController.text = widget.prefilledUsername!;
      _rememberMe = true;
    }
  }

  void _handleSubmit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      final success = await _authService.login(
        _usernameController.text,
        _passwordController.text,
        _rememberMe,
      );

      setState(() => _isLoading = false);

      if (success) {
        widget.onLogin();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid username or password.')),
          );
        }
      }
    }
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
                    // Header remains the same...
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(LucideIcons.package, color: Theme.of(context).colorScheme.onPrimary, size: 32),
                    ),
                    const SizedBox(height: 24),
                    Text('Accountanter', textAlign: TextAlign.center, style: textTheme.headlineMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontSize: 24)),
                    const SizedBox(height: 8),
                    Text('Welcome Back', textAlign: TextAlign.center, style: textTheme.headlineSmall),
                    const SizedBox(height: 32),

                    // Username Field
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Username or Email'),
                      validator: (v) => v!.isEmpty ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 24),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye, size: 16),
                          onPressed: () => setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) => v!.isEmpty ? 'Password is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Remember Me Checkbox
                    Row(
                      children: [
                        Checkbox(value: _rememberMe, onChanged: (val) => setState(() => _rememberMe = val!)),
                        const SizedBox(width: 8),
                        const Text('Remember Me'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Login'),
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