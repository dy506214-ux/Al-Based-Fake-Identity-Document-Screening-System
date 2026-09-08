import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/widgets/app_pull_to_refresh.dart';
import '../../dashboard/data/dashboard_repository.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  // Currently selected document type
  String? _selectedDocType;

  final List<DocumentTypeOption> _docOptions = const [
    DocumentTypeOption(
      id: 'aadhaar',
      title: 'Aadhaar Card',
      subtitle: 'UIDAI-issued biometric identity card (12-digit UID)',
      icon: Icons.fingerprint,
      iconColor: Color(0xFFD97706),
      iconBgColor: Color(0xFFFEF3C7),
    ),
    DocumentTypeOption(
      id: 'driving_licence',
      title: 'Driving Licence',
      subtitle: 'Issued by regional transport office (RTO)',
      icon: Icons.directions_car_outlined,
      iconColor: Color(0xFF7C3AED),
      iconBgColor: Color(0xFFEDE9FE),
    ),
    DocumentTypeOption(
      id: 'passport',
      title: 'Passport',
      subtitle: 'International travel document — biometric pages',
      icon: Icons.menu_book_outlined,
      iconColor: Color(0xFF3F562C),
      iconBgColor: Color(0xFFF1F5F9),
    ),
    DocumentTypeOption(
      id: 'visa',
      title: 'Visa',
      subtitle: 'Entry permit — visa sticker or e-Visa',
      icon: Icons.language,
      iconColor: Color(0xFF2563EB),
      iconBgColor: Color(0xFFEFF6FF),
    ),
    DocumentTypeOption(
      id: 'national_id',
      title: 'Other National ID',
      subtitle: 'PAN card, voter ID, or other government ID',
      icon: Icons.credit_card,
      iconColor: Color(0xFF0284C7),
      iconBgColor: Color(0xFFE0F2FE),
    ),
    DocumentTypeOption(
      id: 'permit_other',
      title: 'Permit / Other',
      subtitle: 'Work permit, residency card, or other documents',
      icon: Icons.article_outlined,
      iconColor: Color(0xFF64748B),
      iconBgColor: Color(0xFFF1F5F9),
    ),
  ];

  void _handleContinue() {
    if (_selectedDocType == null) return;
    context.push('/capture', extra: _selectedDocType);
  }

  @override
  Widget build(BuildContext context) {
    final bool isContinueEnabled = _selectedDocType != null;
    final theme = ref.watch(appThemeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: Column(
        children: [
          // 2. Security Connection Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
            color: const Color(0xFFDCFCE7),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 13,
                  color: Color(0xFF15803D),
                ),
                SizedBox(width: 6),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'SECURE CONNECTION · AUTHORIZED OFFICER',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Document Selection List
          Expanded(
            child: AppPullToRefresh(
              onRefresh: () async {
                ref.invalidate(dashboardStatsProvider);
                await ref.read(dashboardStatsProvider.future);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subtitle Instruction
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 14),
                      child: Text(
                        'Choose the document type to begin AI-assisted screening',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),

                    // Document Options List
                    ..._docOptions.map((option) {
                      final isSelected = _selectedDocType == option.title;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _DocumentOptionCard(
                          option: option,
                          isSelected: isSelected,
                          themeColor: theme.primaryColor,
                          onTap: () {
                            setState(() {
                              _selectedDocType = option.title;
                            });
                          },
                        ),
                      );
                    }),

                    const SizedBox(height: 12),

                    // 4. Continue Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isContinueEnabled
                              ? theme.primaryColor
                              : const Color(0xFFE2E8F0),
                          foregroundColor: isContinueEnabled
                              ? Colors.white
                              : const Color(0xFF94A3B8),
                          elevation: isContinueEnabled ? 2 : 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isContinueEnabled ? _handleContinue : null,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'CONTINUE TO DOCUMENT CAPTURE',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isContinueEnabled
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Model for Document Option
class DocumentTypeOption {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  const DocumentTypeOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });
}

/// Document Option Card
class _DocumentOptionCard extends StatelessWidget {
  final DocumentTypeOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? themeColor;

  const _DocumentOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
    this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = themeColor ?? const Color(0xFF475E35);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? activeColor
                : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Square
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: option.iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                option.icon,
                color: option.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Title and Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Radio Indicator Circle
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : Colors.grey.shade400,
                  width: isSelected ? 6.5 : 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
