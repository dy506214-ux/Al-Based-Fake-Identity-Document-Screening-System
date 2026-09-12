import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isGeneratingEmail = false;
  bool _isGeneratingPassword = false;
  bool _isCreatingAccount = false;
  int _emailVariantIndex = 0;
  String? _errorMessage;
  late final AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGenerateEmail() async {
    final name = _nameController.text.trim();
    final rawMobile = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');

    if (name.length < 2) {
      setState(() {
        _errorMessage = 'Please enter your Full Name first to generate a personalized Login ID.';
      });
      return;
    }

    setState(() {
      _isGeneratingEmail = true;
      _errorMessage = null;
    });

    try {
      final email = await ref.read(authControllerProvider.notifier).generateOfficerEmail(
            name: name,
            mobile: rawMobile,
            variantIndex: _emailVariantIndex++,
          );

      if (!mounted) return;
      setState(() {
        _emailController.text = email;
        _isGeneratingEmail = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Fallback local robust generation if offline
      final clean = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
      final candidate = '${clean.isNotEmpty ? clean : "officer"}officer@dociscan.gov.in';
      setState(() {
        _emailController.text = candidate;
        _isGeneratingEmail = false;
      });
    }
  }

  Future<void> _handleGeneratePassword() async {
    setState(() {
      _isGeneratingPassword = true;
      _errorMessage = null;
    });

    try {
      final password = await ref.read(authControllerProvider.notifier).generateOfficerPassword();

      if (!mounted) return;
      setState(() {
        _passwordController.text = password;
        _isPasswordVisible = true; // Show on generate so officer can see it
        _isGeneratingPassword = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Fallback cryptographic client generation if offline
      final uppers = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
      final lowers = 'abcdefghijkmnopqrstuvwxyz';
      final digits = '23456789';
      final symbols = '!@#\$%&*';
      final rnd = math.Random.secure();
      final list = [
        uppers[rnd.nextInt(uppers.length)],
        uppers[rnd.nextInt(uppers.length)],
        lowers[rnd.nextInt(lowers.length)],
        lowers[rnd.nextInt(lowers.length)],
        digits[rnd.nextInt(digits.length)],
        digits[rnd.nextInt(digits.length)],
        symbols[rnd.nextInt(symbols.length)],
        symbols[rnd.nextInt(symbols.length)],
      ];
      final all = uppers + lowers + digits + symbols;
      while (list.length < 12) {
        list.add(all[rnd.nextInt(all.length)]);
      }
      list.shuffle(rnd);
      setState(() {
        _passwordController.text = list.join();
        _isPasswordVisible = true;
        _isGeneratingPassword = false;
      });
    }
  }

  Future<void> _handleCreateAccount() async {
    final name = _nameController.text.trim();
    final rawMobile = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.length < 3) {
      setState(() {
        _errorMessage = 'Please enter your full name (at least 3 characters).';
      });
      return;
    }

    if (rawMobile.length != 10 || !RegExp(r'^[6-9]\d{9}$').hasMatch(rawMobile)) {
      setState(() {
        _errorMessage = 'Please enter a valid 10-digit Indian mobile number (e.g., 9876543210).';
      });
      return;
    }

    if (email.length < 4) {
      setState(() {
        _errorMessage = 'Please generate or enter a valid Email / Login ID.';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'Please generate or enter a strong password (minimum 8 characters).';
      });
      return;
    }

    setState(() {
      _isCreatingAccount = true;
      _errorMessage = null;
    });

    try {
      final credentials = await ref
          .read(authControllerProvider.notifier)
          .createOfficerAccount(
            name: name,
            mobile: rawMobile,
            email: email,
            password: password,
          );

      if (!mounted) return;
      setState(() {
        _isCreatingAccount = false;
      });

      // Navigate to the secure credential display screen
      context.go('/credentials', extra: credentials);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingAccount = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 380;
    final cardWidth = math.min(screenSize.width - 20.0, 440.0);
    final isBusy = _isCreatingAccount || _isGeneratingEmail || _isGeneratingPassword;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B0F), // Dark tactical green background
      body: Stack(
        children: [
          // Background Tactical Grid
          const Positioned.fill(
            child: CustomPaint(
              painter: _TacticalGridPainter(),
            ),
          ),

          // Glowing Chakra / Radar Arc
          Positioned(
            top: -60,
            right: -60,
            child: RotationTransition(
              turns: _rotationController,
              child: const SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _GlowingChakraWheelPainter(),
                ),
              ),
            ),
          ),

          // Main Registration Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                child: Container(
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(isCompact ? 16 : 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF2E7D32).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_rounded, size: 14, color: Color(0xFF2E7D32)),
                            SizedBox(width: 6),
                            Text(
                              'OFFICER ONBOARDING',
                              style: TextStyle(
                                color: Color(0xFF2E7D32),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title
                      const Text(
                        'OFFICER REGISTRATION',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create your official screening credentials with AI assist.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Error Alert Box
                      if (_errorMessage != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    color: Color(0xFF991B1B),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // 1. Full Name Input
                      _buildInputField(
                        controller: _nameController,
                        key: const Key('registerFullNameField'),
                        label: 'Full Name',
                        hintText: 'e.g., Dhirendra Kumar Yadav',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        enabled: !isBusy,
                      ),
                      const SizedBox(height: 14),

                      // 2. Mobile Number Input
                      _buildMobileInputField(
                        controller: _mobileController,
                        key: const Key('registerMobileField'),
                        enabled: !isBusy,
                      ),
                      const SizedBox(height: 14),

                      // 3. Generate New Email ID with SEPARATE AI GENERATE Button
                      _buildEmailGeneratorField(
                        controller: _emailController,
                        key: const Key('registerEmailField'),
                        enabled: !isBusy,
                        isLoading: _isGeneratingEmail,
                        onGenerate: _handleGenerateEmail,
                      ),
                      const SizedBox(height: 14),

                      // 4. Generate New Password with SEPARATE AI GENERATE Button & Toggle
                      _buildPasswordGeneratorField(
                        controller: _passwordController,
                        key: const Key('registerPasswordField'),
                        enabled: !isBusy,
                        isLoading: _isGeneratingPassword,
                        isPasswordVisible: _isPasswordVisible,
                        onGenerate: _handleGeneratePassword,
                        onToggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 22),

                      // 5. CREATE ACCOUNT CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('createAccountButton'),
                          onPressed: isBusy ? null : _handleCreateAccount,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E4620), // Dark tactical green
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isCreatingAccount
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'CREATING ACCOUNT...',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                )
                              : const Text(
                                  'CREATE ACCOUNT',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Footer link back to Login
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Already registered? ',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          InkWell(
                            key: const Key('loginHereLink'),
                            onTap: () {
                              context.go('/login');
                            },
                            child: const Text(
                              'Login here',
                              style: TextStyle(
                                color: Color(0xFF1E4620),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required Key key,
    required String label,
    required String hintText,
    required IconData icon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFF2D5A27), size: 19),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileInputField({
    required TextEditingController controller,
    required Key key,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number (India)',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: key,
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
          decoration: InputDecoration(
            hintText: '77048 49886',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13, letterSpacing: 0),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_iphone_rounded, color: Color(0xFF2D5A27), size: 19),
                  SizedBox(width: 4),
                  Text(
                    '+91',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text('|', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 1.8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailGeneratorField({
    required TextEditingController controller,
    required Key key,
    required bool enabled,
    required bool isLoading,
    required VoidCallback onGenerate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generate New Email ID',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  key: key,
                  controller: controller,
                  enabled: enabled,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    hintText: 'dhirendraofficer@dociscan.gov.in',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                    prefixIcon: const Icon(Icons.alternate_email_rounded, color: Color(0xFF2D5A27), size: 19),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 1.8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AiGenerateButton(
              buttonKey: const Key('generateEmailButton'),
              enabled: enabled,
              isLoading: isLoading,
              onGenerate: onGenerate,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordGeneratorField({
    required TextEditingController controller,
    required Key key,
    required bool enabled,
    required bool isLoading,
    required bool isPasswordVisible,
    required VoidCallback onGenerate,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Generate New Password',
          style: TextStyle(
            color: Color(0xFF334155),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: TextField(
                  key: key,
                  controller: controller,
                  enabled: enabled,
                  obscureText: !isPasswordVisible,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontFamily: 'Courier',
                  ),
                  decoration: InputDecoration(
                    hintText: '85Pi!PTFx%yt',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12, letterSpacing: 0),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: Color(0xFF2D5A27), size: 19),
                    suffixIcon: IconButton(
                      key: const Key('toggleRegisterPasswordVisibility'),
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 19,
                        color: Colors.grey.shade700,
                      ),
                      onPressed: onToggleVisibility,
                      tooltip: isPasswordVisible ? 'Hide Password' : 'Show Password',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2D5A27), width: 1.8),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _AiGenerateButton(
              buttonKey: const Key('generatePasswordButton'),
              enabled: enabled,
              isLoading: isLoading,
              onGenerate: onGenerate,
            ),
          ],
        ),
      ],
    );
  }
}

class _AiGenerateButton extends StatelessWidget {
  final Key? buttonKey;
  final bool enabled;
  final bool isLoading;
  final VoidCallback onGenerate;

  const _AiGenerateButton({
    this.buttonKey,
    required this.enabled,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        key: buttonKey,
        onPressed: enabled && !isLoading ? onGenerate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E4620), // Dark tactical green
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF1E4620).withValues(alpha: 0.65),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Generating...',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'AI Generate',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GlowingChakraWheelPainter extends CustomPainter {
  const _GlowingChakraWheelPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final glowPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

    final linePaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..isAntiAlias = true;

    canvas.drawCircle(center, radius - 2, glowPaint);
    canvas.drawCircle(center, radius - 2, linePaint);
    canvas.drawCircle(center, radius * 0.72, linePaint);
    canvas.drawCircle(center, radius * 0.44, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _TacticalGridPainter extends CustomPainter {
  const _TacticalGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
