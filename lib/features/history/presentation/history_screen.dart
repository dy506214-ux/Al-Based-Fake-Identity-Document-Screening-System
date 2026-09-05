import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRiskFilter = 'All Risk';
  String _selectedDocFilter = 'All';

  final List<HistoryCaseModel> _allCases = const [
    HistoryCaseModel(
      id: 'SCR-2026-0001',
      name: 'Rahul Kumar',
      docType: 'Passport',
      dateTime: '26 Aug, 10:30 AM',
      risk: 'LOW RISK',
      status: 'Completed',
      riskBgColor: Color(0xFFDCFCE7),
      riskTextColor: Color(0xFF15803D),
      statusBgColor: Color(0xFFDCFCE7),
      statusTextColor: Color(0xFF15803D),
      confidence: '99.2%',
    ),
    HistoryCaseModel(
      id: 'SCR-2026-0002',
      name: 'Amit Singh',
      docType: 'Passport',
      dateTime: '26 Aug, 10:15 AM',
      risk: 'HIGH RISK',
      status: 'Suspicious',
      riskBgColor: Color(0xFFFEE2E2),
      riskTextColor: Color(0xFFDC2626),
      statusBgColor: Color(0xFFFEE2E2),
      statusTextColor: Color(0xFFDC2626),
      confidence: '42.8%',
    ),
    HistoryCaseModel(
      id: 'SCR-2026-0003',
      name: 'Vikram Das',
      docType: 'Visa',
      dateTime: '26 Aug, 10:00 AM',
      risk: 'MEDIUM RISK',
      status: 'Reviewed',
      riskBgColor: Color(0xFFFEF3C7),
      riskTextColor: Color(0xFFD97706),
      statusBgColor: Color(0xFFFEF3C7),
      statusTextColor: Color(0xFFD97706),
      confidence: '78.5%',
    ),
    HistoryCaseModel(
      id: 'SCR-2026-0004',
      name: 'Priya Verma',
      docType: 'National ID',
      dateTime: '26 Aug, 09:45 AM',
      risk: 'LOW RISK',
      status: 'Completed',
      riskBgColor: Color(0xFFDCFCE7),
      riskTextColor: Color(0xFF15803D),
      statusBgColor: Color(0xFFDCFCE7),
      statusTextColor: Color(0xFF15803D),
      confidence: '98.9%',
    ),
    HistoryCaseModel(
      id: 'SCR-2026-0005',
      name: 'Sunita Patel',
      docType: 'Driving Licence',
      dateTime: '26 Aug, 09:20 AM',
      risk: 'MEDIUM RISK',
      status: 'Pending',
      riskBgColor: Color(0xFFFEF3C7),
      riskTextColor: Color(0xFFD97706),
      statusBgColor: Color(0xFFF1F5F9),
      statusTextColor: Color(0xFF475569),
      confidence: '81.0%',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<HistoryCaseModel> get _filteredCases {
    final query = _searchController.text.trim().toLowerCase();

    return _allCases.where((item) {
      final matchesQuery = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.id.toLowerCase().contains(query) ||
          item.docType.toLowerCase().contains(query);

      final matchesRisk = _selectedRiskFilter == 'All Risk' ||
          (_selectedRiskFilter == 'Low Risk' && item.risk == 'LOW RISK') ||
          (_selectedRiskFilter == 'Medium Risk' &&
              item.risk == 'MEDIUM RISK') ||
          (_selectedRiskFilter == 'High Risk' && item.risk == 'HIGH RISK');

      final matchesDoc = _selectedDocFilter == 'All' ||
          item.docType.toLowerCase() == _selectedDocFilter.toLowerCase();

      return matchesQuery && matchesRisk && matchesDoc;
    }).toList();
  }

  void _showCaseDetails(HistoryCaseModel item) {
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: item.riskBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.risk,
                        style: TextStyle(
                          color: item.riskTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.id} · ${item.docType}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const Divider(height: 28),
                _detailRow('Timestamp', item.dateTime),
                const SizedBox(height: 8),
                _detailRow('AI Authenticity Confidence', item.confidence),
                const SizedBox(height: 8),
                _detailRow('Screening Status', item.status),
                const SizedBox(height: 8),
                _detailRow('Verified By', 'Officer Sharma (OFC-2024-0847)'),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF354E28),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'CLOSE CASE DETAILS',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredCases;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F5),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

                  // Title
                  const Text(
                    'SCREENING HISTORY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search & Filter Bar Container
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              color: Colors.white,
              child: Column(
                children: [
                  // Search TextField
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF9F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(fontSize: 13.5),
                      decoration: const InputDecoration(
                        hintText: 'Search by name, ID, or document...',
                        hintStyle: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF94A3B8),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          size: 20,
                          color: Color(0xFF94A3B8),
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Risk Filter Chips (Horizontal Scroll)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterChip('All Risk'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Low Risk'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Medium Risk'),
                        const SizedBox(width: 8),
                        _buildFilterChip('High Risk'),
                        const SizedBox(width: 8),
                        _buildMoreFilterButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Subtle divider line
            Container(height: 1, color: const Color(0xFFE2E8F0)),

            // 3. Case Count Title
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                '${filtered.length} cases found',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ),

            // 4. Case Cards List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No cases match your filters',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _HistoryCaseCard(
                          item: item,
                          onTap: () => _showCaseDetails(item),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedRiskFilter == label;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedRiskFilter = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF364F28) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF364F28) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreFilterButton() {
    final hasDocFilter = _selectedDocFilter != 'All';

    return InkWell(
      onTap: _showMoreFiltersSheet,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: hasDocFilter ? const Color(0xFF364F28) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasDocFilter ? const Color(0xFF364F28) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune,
              size: 16,
              color: hasDocFilter ? Colors.white : const Color(0xFF475569),
            ),
            const SizedBox(width: 6),
            Text(
              hasDocFilter ? _selectedDocFilter : 'More',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: hasDocFilter ? FontWeight.w700 : FontWeight.w600,
                color: hasDocFilter ? Colors.white : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreFiltersSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final docTypes = ['All', 'Passport', 'Visa', 'National ID', 'Driving Licence'];

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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'More Filters',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedDocFilter = 'All';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Reset All',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Filter by Document Type',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: docTypes.map((doc) {
                        final isSelected = _selectedDocFilter == doc;
                        return ChoiceChip(
                          label: Text(doc),
                          selected: isSelected,
                          selectedColor: const Color(0xFF364F28),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF364F28) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedDocFilter = doc;
                            });
                            setModalState(() {});
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }
}

/// Model representing a Screening Case in History
class HistoryCaseModel {
  final String id;
  final String name;
  final String docType;
  final String dateTime;
  final String risk;
  final String status;
  final Color riskBgColor;
  final Color riskTextColor;
  final Color statusBgColor;
  final Color statusTextColor;
  final String confidence;

  const HistoryCaseModel({
    required this.id,
    required this.name,
    required this.docType,
    required this.dateTime,
    required this.risk,
    required this.status,
    required this.riskBgColor,
    required this.riskTextColor,
    required this.statusBgColor,
    required this.statusTextColor,
    required this.confidence,
  });
}

/// Pixel-Perfect History Case Card Component
class _HistoryCaseCard extends StatelessWidget {
  final HistoryCaseModel item;
  final VoidCallback onTap;

  const _HistoryCaseCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left Content: Name, Doc ID, Date/Time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${item.id} · ${item.docType}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.dateTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),

            // Right Badges & Chevron Arrow
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Risk Badge (e.g. LOW RISK, HIGH RISK)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: item.riskBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.risk,
                        style: TextStyle(
                          color: item.riskTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Chevron Right Arrow
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Status Badge (e.g. Completed, Suspicious, Reviewed, Pending)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: item.statusBgColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.status,
                    style: TextStyle(
                      color: item.statusTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
