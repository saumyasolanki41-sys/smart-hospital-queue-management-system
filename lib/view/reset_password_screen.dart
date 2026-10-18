
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthViewModel>();

    final success = await auth.resetPassword(
      email: widget.email,
      otp: _otpController.text.trim(),
      newPassword: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset successful. Please log in with your new password.',
          ),
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Unable to reset password.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(
                  Icons.password_rounded,
                  size: 78,
                  color: colors.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Create a new password',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter the six-digit reset OTP sent to ${widget.email}, '
                  'then choose your new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Reset OTP',
                    hintText: 'Enter 6-digit OTP',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^\d{6}$').hasMatch(value)) {
                      return 'Enter a valid 6-digit OTP.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: 'New password',
                    hintText: 'At least 8 characters',
                    prefixIcon: const Icon(Icons.lock_outline),
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
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a new password.';
                    }

                    if (value.length < 8) {
                      return 'Password must be at least 8 characters.';
                    }

                    if (value.length > 72) {
                      return 'Password is too long.';
                    }

                    if (RegExp(
                      r'[\uD800-\uDBFF][\uDC00-\uDFFF]',
                    ).hasMatch(value)) {
                      // UTF-8 byte validation is also performed below.
                    }

                    if (value.codeUnits.length > 72) {
                      return 'Password is too long.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) {
                    if (!auth.isLoading) _resetPassword();
                  },
                  decoration: InputDecoration(
                    labelText: 'Confirm new password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
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
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your new password.';
                    }

                    if (value != _passwordController.text) {
                      return 'Passwords do not match.';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: auth.isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  child: auth.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Reset Password'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
