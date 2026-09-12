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

  bool _isLoading = false;
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
    super.dispose();
  }

  Future<void> _handleCreateCredentials() async {
    final name = _nameController.text.trim();
    final rawMobile = _mobileController.text.trim().replaceAll(RegExp(r'\D'), '');

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

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credentials = await ref
          .read(authControllerProvider.notifier)
          .createOfficerCredentials(
            name: name,
            mobile: rawMobile,
          );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      // Navigate to the secure credential display screen
      context.go('/credentials', extra: credentials);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isCompact = screenSize.width < 380;
    final cardWidth = math.min(screenSize.width - 20.0, 430.0);

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
                  padding: EdgeInsets.all(isCompact ? 16 : 28),
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
                      const SizedBox(height: 14),

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
                      const SizedBox(height: 6),
                      Text(
                        'Enter your official details to generate your secure Login ID and Password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),

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
                        const SizedBox(height: 16),
                      ],

                      // Full Name Input
                      _buildInputField(
                        controller: _nameController,
                        label: 'Full Name',
                        hintText: 'e.g., Dhirendra Kumar',
                        icon: Icons.person_outline_rounded,
                        textCapitalization: TextCapitalization.words,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),

                      // Mobile Number Input
                      _buildMobileInputField(
                        controller: _mobileController,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 24),

                      // CREATE ID & PASSWORD CTA Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('createCredentialsButton'),
                          onPressed: _isLoading ? null : _handleCreateCredentials,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2D5A27), // Tactical deep green
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  'CREATE ID & PASSWORD',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

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
                                color: Color(0xFFF59E0B),
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
          key: const Key('registerFullNameField'),
          controller: controller,
          enabled: enabled,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
            prefixIcon: Icon(icon, color: const Color(0xFF2D5A27), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          key: const Key('registerMobileField'),
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          decoration: InputDecoration(
            hintText: '98765 43210',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5, letterSpacing: 0),
            prefixIcon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.phone_iphone_rounded, color: Color(0xFF2D5A27), size: 20),
                  SizedBox(width: 6),
                  Text(
                    '+91',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('|', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
