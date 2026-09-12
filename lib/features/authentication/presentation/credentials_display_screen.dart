import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../domain/auth_repository.dart';

class CredentialsDisplayScreen extends StatefulWidget {
  final GeneratedCredentials credentials;

  const CredentialsDisplayScreen({
    super.key,
    required this.credentials,
  });

  @override
  State<CredentialsDisplayScreen> createState() => _CredentialsDisplayScreenState();
}

class _CredentialsDisplayScreenState extends State<CredentialsDisplayScreen> {
  bool _isPasswordVisible = false;
  bool _copiedLoginId = false;
  bool _copiedPassword = false;
  bool _copiedAll = false;

  void _copyToClipboard(String text, String label, {required VoidCallback onSuccess}) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    onSuccess();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard!'),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _copyLoginId() {
    _copyToClipboard(
      widget.credentials.loginId,
      'Login ID',
      onSuccess: () => setState(() => _copiedLoginId = true),
    );
  }

  void _copyPassword() {
    _copyToClipboard(
      widget.credentials.password,
      'Password',
      onSuccess: () => setState(() => _copiedPassword = true),
    );
  }

  void _copyAllCredentials() {
    final formatted = '''
AI-Based Fake Identity & Document Screening System
==================================================
Officer Name      : ${widget.credentials.name}
Registered Mobile : +91 ${widget.credentials.mobile}
Login ID          : ${widget.credentials.loginId}
Password          : ${widget.credentials.password}
==================================================
Keep this securely for future logins.''';

    _copyToClipboard(
      formatted,
      'All credentials',
      onSuccess: () => setState(() => _copiedAll = true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Account Credentials'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Header Badge
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.success,
                        size: 52,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'ACCOUNT CREATED',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.success,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      'Your official screening officer account is active and ready.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall.copyWith(
                        color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Important Screenshot Alert Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.warning,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Take a screenshot of this page and keep it safely for future login. The password will not be shown again.',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? const Color(0xFFFFD54F) : const Color(0xFFE65100),
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Officer Metadata Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildMetaRow(
                          context,
                          icon: Icons.person_outline_rounded,
                          label: 'Officer Name',
                          value: widget.credentials.name.isNotEmpty ? widget.credentials.name : 'Officer',
                        ),
                        const Divider(height: 16),
                        _buildMetaRow(
                          context,
                          icon: Icons.phone_android_rounded,
                          label: 'Registered Mobile',
                          value: _formatDisplayMobile(widget.credentials.mobile),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Credentials Main Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // LOGIN ID FIELD
                        Text(
                          'LOGIN ID',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.badge_outlined, size: 19, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SelectableText(
                                    widget.credentials.loginId,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton.icon(
                                key: const Key('copyLoginIdButton'),
                                onPressed: _copyLoginId,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  _copiedLoginId ? Icons.check_rounded : Icons.copy_rounded,
                                  size: 13,
                                ),
                                label: Text(
                                  _copiedLoginId ? 'Copied' : 'Copy',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // PASSWORD FIELD
                        Text(
                          'PASSWORD',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.lock_outline_rounded, size: 19, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: SelectableText(
                                    _isPasswordVisible
                                        ? widget.credentials.password
                                        : '•' * widget.credentials.password.length,
                                    style: AppTypography.bodyMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      letterSpacing: _isPasswordVisible ? 0.6 : 2.0,
                                      fontFamily: 'Courier',
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                key: const Key('togglePasswordVisibilityButton'),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 18,
                                  color: theme.iconTheme.color,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                                tooltip: _isPasswordVisible ? 'Hide Password' : 'Show Password',
                              ),
                              const SizedBox(width: 4),
                              OutlinedButton.icon(
                                key: const Key('copyPasswordButton'),
                                onPressed: _copyPassword,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: Icon(
                                  _copiedPassword ? Icons.check_rounded : Icons.copy_rounded,
                                  size: 13,
                                ),
                                label: Text(
                                  _copiedPassword ? 'Copied' : 'Copy',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // COPY ALL CREDENTIALS BUTTON
                        OutlinedButton.icon(
                          key: const Key('copyAllCredentialsButton'),
                          onPressed: _copyAllCredentials,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
                            ),
                          ),
                          icon: Icon(
                            _copiedAll ? Icons.check_circle_rounded : Icons.copy_all_rounded,
                            size: 18,
                            color: _copiedAll ? AppColors.success : null,
                          ),
                          label: Text(_copiedAll ? 'All Credentials Copied!' : 'COPY ALL CREDENTIALS'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // DONE / PROCEED TO LOGIN BUTTON
                  ElevatedButton(
                    key: const Key('credentialsDoneButton'),
                    onPressed: () {
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'DONE',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20, color: Colors.white),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetaRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: theme.textTheme.bodySmall?.color ?? AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDisplayMobile(String mobile) {
    final digits = mobile.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      final last10 = digits.substring(digits.length - 10);
      return '+91 $last10';
    }
    return mobile.startsWith('+') ? mobile : '+91 $mobile';
  }
}
