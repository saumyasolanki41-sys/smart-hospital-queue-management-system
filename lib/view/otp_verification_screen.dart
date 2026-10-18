
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_viewmodel.dart';

enum OtpVerificationType {
  registration,
  login,
}

class OtpVerificationScreen extends StatefulWidget {
  final OtpVerificationType type;
  final String email;

  const OtpVerificationScreen({
    super.key,
    required this.type,
    required this.email,
  });

  @override
  State<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState
    extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final auth = context.read<AuthViewModel>();
    final otp = _otpController.text.trim();

    try {
      final bool success;

      if (widget.type == OtpVerificationType.registration) {
        success = await auth.verifyRegistration(
          email: widget.email,
          otp: otp,
        );
      } else {
        success = await auth.verifyLogin(
          otp: otp,
        );
      }

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              auth.errorMessage ?? 'OTP verification failed.',
            ),
          ),
        );
        return;
      }

      if (widget.type == OtpVerificationType.registration) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registration successful. Please log in.',
            ),
          ),
        );

        Navigator.of(context).popUntil(
          (route) => route.isFirst,
        );
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();
    final colors = Theme.of(context).colorScheme;

    final isRegistration =
        widget.type == OtpVerificationType.registration;

    final isBusy = _isSubmitting || auth.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isRegistration
              ? 'Verify Registration'
              : 'Verify Login',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),

                Icon(
                  Icons.mark_email_read_outlined,
                  size: 84,
                  color: colors.primary,
                ),

                const SizedBox(height: 24),

                Text(
                  'Enter your OTP',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Enter the six-digit code sent to ${widget.email}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  autofocus: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    labelText: 'Six-digit OTP',
                    hintText: '000000',
                    prefixIcon: Icon(Icons.password_outlined),
                    counterText: '',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null ||
                        !RegExp(r'^\d{6}$').hasMatch(value)) {
                      return 'Enter a valid six-digit OTP.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) {
                    if (!isBusy) {
                      _verifyOtp();
                    }
                  },
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isBusy ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(
                      double.infinity,
                      52,
                    ),
                  ),
                  child: isBusy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Verify OTP'),
                ),

                const SizedBox(height: 16),

                Text(
                  'Your OTP expires after 5 minutes. '
                  'If it expires, you may need to request a new code.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
