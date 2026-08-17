import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Password recovery screen
class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  late TextEditingController _emailController;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;
  int _step = 0; // 0: Email, 1: OTP, 2: New Password

  late TextEditingController _otpController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _otpController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Step 1: Send recovery email
  Future<void> _handleSendEmail() async {
    setState(() => _errorMessage = null);

    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _successMessage = 'Recovery code sent to $email';
        _step = 1;
      });
    }
  }

  /// Step 2: Verify OTP
  Future<void> _handleVerifyOTP() async {
    setState(() => _errorMessage = null);

    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      setState(() => _errorMessage = 'Recovery code is required');
      return;
    }

    if (otp.length != 6) {
      setState(() => _errorMessage = 'Recovery code must be 6 digits');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _successMessage = 'Recovery code verified successfully';
        _step = 2;
      });
    }
  }

  /// Step 3: Reset password
  Future<void> _handleResetPassword() async {
    setState(() => _errorMessage = null);

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty) {
      setState(() => _errorMessage = 'New password is required');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() => _isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Show success dialog
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        icon: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppTheme.successColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: AppTheme.successColor,
            size: 32,
          ),
        ),
        title: const Text('Password Reset Successful'),
        content: const Text(
          'Your password has been reset successfully. You can now login with your new password.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.pop(); // Back to login
            },
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  /// Build step 1: Email verification
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.email_outlined,
          size: 56,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Forgot Password?',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email address and we\'ll send you a recovery code',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) ...[
          ErrorMessageWidget(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        if (_successMessage != null) ...[
          SuccessMessageWidget(message: _successMessage!),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _emailController,
          enabled: !_isLoading,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email Address',
            hintText: 'Enter your email',
            prefixIcon: const Icon(Icons.email_outlined),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleSendEmail(),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          isLoading: _isLoading,
          onPressed: _handleSendEmail,
          label: 'Send Recovery Code',
        ),
      ],
    );
  }

  /// Build step 2: OTP verification
  Widget _buildOTPStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.security_outlined,
          size: 56,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Verify Recovery Code',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent a 6-digit code to ${_emailController.text}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) ...[
          ErrorMessageWidget(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        TextFormField(
          controller: _otpController,
          enabled: !_isLoading,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          decoration: InputDecoration(
            hintText: '000000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _handleVerifyOTP(),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          isLoading: _isLoading,
          onPressed: _handleVerifyOTP,
          label: 'Verify Code',
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: _isLoading ? null : _handleSendEmail,
            child: Text(
              'Resend Code',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build step 3: New password
  Widget _buildPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(
          Icons.lock_reset_outlined,
          size: 56,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 24),
        Text(
          'Set New Password',
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Create a strong password for your account',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (_errorMessage != null) ...[
          ErrorMessageWidget(message: _errorMessage!),
          const SizedBox(height: 16),
        ],
        AuthTextField(
          controller: _newPasswordController,
          label: 'New Password',
          hintText: 'Enter new password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        AuthTextField(
          controller: _confirmPasswordController,
          label: 'Confirm Password',
          hintText: 'Confirm new password',
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          enabled: !_isLoading,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Password Requirements:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              PasswordRequirement(
                text: 'At least 6 characters',
                isMet: _newPasswordController.text.length >= 6,
              ),
              const SizedBox(height: 6),
              PasswordRequirement(
                text: 'Passwords match',
                isMet: _newPasswordController.text.isNotEmpty &&
                    _newPasswordController.text == _confirmPasswordController.text,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        LoadingButton(
          isLoading: _isLoading,
          onPressed: _handleResetPassword,
          label: 'Reset Password',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Password Recovery'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Progress indicator
              Row(
                children: List.generate(
                  3,
                  (index) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: index <= _step
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Step content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _step == 0
                    ? _buildEmailStep()
                    : _step == 1
                        ? _buildOTPStep()
                        : _buildPasswordStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
