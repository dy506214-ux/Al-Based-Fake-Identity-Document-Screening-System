import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
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
                const SizedBox(height: 18),
                Text(
                  'Capture $_selectedDocType',
                  style: const TextStyle(
                    fontSize: 18,
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
                          backgroundColor: const Color(0xFF475E35),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF354E28),
                              content: Text(
                                  'Camera initialized for $_selectedDocType screening'),
                            ),
                          );
                        },
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
                          foregroundColor: const Color(0xFF354E28),
                          side: const BorderSide(color: Color(0xFF354E28)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: const Color(0xFF354E28),
                              content: Text(
                                  'Gallery file picker opened for $_selectedDocType'),
                            ),
                          );
                        },
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

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Tactical Dark Green Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              color: const Color(0xFF142416),
              child: Row(
                children: [
                  // Back Button
                  InkWell(
                    onTap: () {
                      context.go('/dashboard');
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223624),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Step Info
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'NEW SCREENING',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Step 1 of 8 · Select document type',
                        style: TextStyle(
                          color: const Color(0xFFC4D1BC).withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
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
                              ? const Color(0xFF475E35)
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
                  ],
                ),
              ),
            ),
          ],
        ),
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

  const _DocumentOptionCard({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                ? const Color(0xFF475E35)
                : Colors.grey.shade200,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF475E35).withValues(alpha: 0.08)
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
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? const Color(0xFF1E293B)
                          : const Color(0xFF1E293B),
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
                      ? const Color(0xFF475E35)
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
