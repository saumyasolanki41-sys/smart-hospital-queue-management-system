
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';
import 'otp_verification_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthViewModel>();
    final email = _emailController.text.trim().toLowerCase();

    try {
      final success = await auth.register(
        name: _nameController.text.trim(),
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (success) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              type: OtpVerificationType.registration,
              email: email,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.errorMessage ?? 'Registration request failed.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  int utf8Length(String value) {
    return value.runes.fold<int>(
      0,
      (total, rune) {
        if (rune <= 0x7F) return total + 1;
        if (rune <= 0x7FF) return total + 2;
        if (rune <= 0xFFFF) return total + 3;
        return total + 4;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = _isSubmitting || auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 68,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Join Hospital Queue',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your patient account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),

                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final name = value?.trim() ?? '';

                      if (name.length < 2 || name.length > 100) {
                        return 'Name must contain 2–100 characters.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final email = value?.trim() ?? '';

                      if (email.isEmpty ||
                          !RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                        return 'Enter a valid email address.';
                      }

                      if (email.length > 254) {
                        return 'Email address is too long.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.newPassword],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      final password = value ?? '';

                      if (password.length < 8) {
                        return 'Password must be at least 8 characters.';
                      }

                      if (utf8Length(password) > 72) {
                        return 'Password is too long.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_reset_outlined),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword =
                                !_obscureConfirmPassword;
                          });
                        },
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'Passwords do not match.';
                      }

                      return null;
                    },
                    onFieldSubmitted: (_) {
                      if (!isBusy) _signup();
                    },
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    onPressed: isBusy ? null : _signup,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: isBusy
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Create Account'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'We will send a six-digit verification code to your email.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
