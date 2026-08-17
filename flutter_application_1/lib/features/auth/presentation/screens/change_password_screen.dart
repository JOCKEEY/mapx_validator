import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/app_providers.dart';
import '../../../../app/theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

/// Lets a logged-in validator change their account password
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  late TextEditingController _oldPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _oldPasswordController = TextEditingController()..addListener(_onFieldChanged);
    _newPasswordController = TextEditingController()..addListener(_onFieldChanged);
    _confirmPasswordController = TextEditingController()..addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _oldPasswordController.removeListener(_onFieldChanged);
    _newPasswordController.removeListener(_onFieldChanged);
    _confirmPasswordController.removeListener(_onFieldChanged);
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    setState(() => _errorMessage = null);

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'New password and confirmation do not match.');
      return;
    }

    setState(() => _isLoading = true);

    final result = await ref
        .read(changePasswordUseCaseProvider)
        .call(oldPassword: oldPassword, newPassword: newPassword);

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.match(
      (failure) {
        setState(() => _errorMessage = failure.message);
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully.')),
        );
        Navigator.of(context).pop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Change Password'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.lock_reset_outlined, size: 56, color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              Text(
                'Update Your Password',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your current password and choose a new one',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                ErrorMessageWidget(message: _errorMessage!),
                const SizedBox(height: 16),
              ],
              AuthTextField(
                controller: _oldPasswordController,
                label: 'Current Password',
                hintText: 'Enter your current password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
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
                label: 'Confirm New Password',
                hintText: 'Re-enter new password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
                enabled: !_isLoading,
                textInputAction: TextInputAction.done,
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
                      text: 'Different from current password',
                      isMet:
                          _newPasswordController.text.isNotEmpty &&
                          _newPasswordController.text != _oldPasswordController.text,
                    ),
                    const SizedBox(height: 6),
                    PasswordRequirement(
                      text: 'Passwords match',
                      isMet:
                          _newPasswordController.text.isNotEmpty &&
                          _newPasswordController.text == _confirmPasswordController.text,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _handleChangePassword,
                label: 'Change Password',
                backgroundColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
