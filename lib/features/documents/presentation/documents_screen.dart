import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme_controller.dart';
import '../../../core/widgets/app_pull_to_refresh.dart';
import '../../dashboard/data/dashboard_repository.dart';
import '../../history/data/history_repository.dart';
import '../data/document_repository.dart';

class DocumentsScreen extends ConsumerStatefulWidget {
  const DocumentsScreen({super.key});

  @override
  ConsumerState<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends ConsumerState<DocumentsScreen> {
  // Currently selected document type
  String? _selectedDocType;
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickAndScreenDocument(ImageSource source) async {
    Navigator.pop(context); // Close source selection sheet

    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 92,
      );

      if (pickedFile == null || !mounted) return;

      // Show processing dialog
      final theme = ref.read(appThemeProvider);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Running AI Screening',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Analyzing document for tampering, OCR extraction, and risk verification on security server...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      );

      final repo = ref.read(documentRepositoryProvider);

      // Step 1: Upload document
      final docId = await repo.uploadDocument(
        file: pickedFile,
        documentType: _selectedDocType ?? 'PASSPORT',
      );

      // Step 2: Process document
      final result = await repo.processDocument(docId);

      // Refresh dashboard and history
      ref.invalidate(dashboardStatsProvider);
      ref.invalidate(historyCasesProvider);

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // Close processing dialog

      // Step 3: Show result sheet
      _showScreeningResultSheet(result);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Close processing dialog if open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Screening completed with notification: ${e.toString().replaceAll("Exception:", "").trim()}'),
          ),
        );
      }
    }
  }

  void _showScreeningResultSheet(ScreeningProcessResult result) {
    final theme = ref.read(appThemeProvider);
    final isHigh = result.riskLevel.toUpperCase() == 'HIGH' ||
        result.riskLevel.toUpperCase() == 'CRITICAL' ||
        result.fakeDocumentStatus.toUpperCase() == 'SUSPICIOUS';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isHigh ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHigh ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                        color: isHigh ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHigh ? 'Suspicious Document Detected' : 'Document Verified Authentic',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: SCR-${result.id.length > 6 ? result.id.substring(result.id.length - 6).toUpperCase() : result.id}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildResultRow('OCR Extraction', result.ocrStatus, const Color(0xFF16A34A)),
                      const Divider(height: 16),
                      _buildResultRow('Validation Status', result.validationStatus, const Color(0xFF2563EB)),
                      const Divider(height: 16),
                      _buildResultRow('Fake Detection', result.fakeDocumentStatus, isHigh ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                      const Divider(height: 16),
                      _buildResultRow('Risk Assessment', '${result.riskLevel} (${result.riskScore}/100)', isHigh ? const Color(0xFFDC2626) : const Color(0xFF16A34A)),
                    ],
                  ),
                ),
                if (result.riskReasons.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Detected Security Flags',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  ...result.riskReasons.map((flag) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                flag,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.primaryColor,
                          side: BorderSide(color: theme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/history');
                        },
                        child: const Text('View in History', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      ],
    );
  }

  void _handleContinue() {
    if (_selectedDocType == null) return;
    final theme = ref.read(appThemeProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Capture Document',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose capture source for automated OCR and forgery screening',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _pickAndScreenDocument(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text(
                            'Scan Camera',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.primaryColor,
                            side: BorderSide(color: theme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => _pickAndScreenDocument(ImageSource.gallery),
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text(
                            'Upload File',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isContinueEnabled = _selectedDocType != null;
    final theme = ref.watch(appThemeProvider);

    return Container(
      color: const Color(0xFFFAF9F5),
      child: Column(
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
                Text(
                  'SECURE CONNECTION · AUTHORIZED OFFICER',
                  style: TextStyle(
                    color: Color(0xFF15803D),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
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
