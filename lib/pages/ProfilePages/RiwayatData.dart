import 'package:flutter/material.dart';

class RiwayatDataPage extends StatefulWidget {
  const RiwayatDataPage({super.key});

  @override
  State<RiwayatDataPage> createState() => _RiwayatDataPageState();
}

class _RiwayatDataPageState extends State<RiwayatDataPage> {
  // -- Colour palette --
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _success = Color(0xFF10B981);
  static const Color _danger = Color(0xFFEF4444);

  // -- State --
  int _selectedPeriod = 0;
  final List<String> _periods = ['7 Hari', '30 Hari', '90 Hari'];
  String _selectedKolam = 'Semua Kolam';
  final List<String> _kolamOptions = [
    'Semua Kolam',
    'Kolam A1',
    'Kolam A2',
    'Kolam A3',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              const Text(
                'Riwayat Alert',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _buildPeriodChips(),
              const SizedBox(height: 18),
              const Text(
                'Riwayat Alert',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              _buildKolamDropdown(),
              const SizedBox(height: 22),
              const Text(
                'Ringkasan Data',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildRingkasanGrid(),
              const SizedBox(height: 22),
              _buildGrafikCard(),
              const SizedBox(height: 22),
              const Text(
                'Timeline Aktivitas',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              _buildTimeline(),
              const SizedBox(height: 22),
              _buildExportButton(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(24),
          child: const Icon(
            Icons.arrow_back_ios_new,
            size: 22,
            color: _textPrimary,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Data',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Data historis sistem',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodChips() {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(_periods.length, (index) {
          final isSelected = _selectedPeriod == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  _periods[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : _textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKolamDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedKolam,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: _textSecondary),
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: _kolamOptions.map((kolam) {
            return DropdownMenuItem(value: kolam, child: Text(kolam));
          }).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedKolam = val);
          },
        ),
      ),
    );
  }

  Widget _buildRingkasanGrid() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard(
              label: 'Rata-rata Suhu',
              value: '28.3 C',
              trend: '2.1',
              trendUp: true,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              label: 'Rata-rata pH',
              value: '7.1',
              trend: '0.5',
              trendUp: false,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard(
              label: 'Konsumsi Pakan',
              value: '42.3 Kg',
              trend: '2.7',
              trendUp: true,
            ),
            const SizedBox(width: 12),
            _buildStatCard(
              label: 'Feeding Rate',
              value: '2.8%',
              trend: 'Stabil',
              trendUp: null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required String trend,
    bool? trendUp,
  }) {
    Color trendColor;
    IconData? trendIcon;
    if (trendUp == true) {
      trendColor = _success;
      trendIcon = Icons.trending_up;
    } else if (trendUp == false) {
      trendColor = _danger;
      trendIcon = Icons.trending_down;
    } else {
      trendColor = _textSecondary;
      trendIcon = null;
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      trend,
                      style: TextStyle(
                        color: trendColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (trendIcon != null) ...[
                      const SizedBox(width: 2),
                      Icon(trendIcon, size: 16, color: trendColor),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrafikCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart, size: 18, color: _primary),
              ),
              const SizedBox(width: 10),
              const Text(
                'Grafik Tren Parameter',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          Center(
            child: Icon(
              Icons.bar_chart_outlined,
              size: 56,
              color: _primary.withOpacity(0.25),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              'Visualisasi grafik akan ditampilkan di sini',
              style: TextStyle(
                color: _textPrimary.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Data ${_periods[_selectedPeriod].toLowerCase()} terakhir - $_selectedKolam',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final activities = <_TimelineItem>[
      _TimelineItem(
        title: 'Timeline Aktivitas',
        description: 'Suhu: 28.5 C, pH: 7.2, DO: 6.8 mg/L',
        date: '04 Des 2025',
        time: '14:30',
        dotColor: _primary,
      ),
      _TimelineItem(
        title: 'Pemberian Pakan Otomatis',
        description: 'Diberikan 3.0 kg pakan - Kolam A1',
        date: '04 Des 2025',
        time: '12:00',
        dotColor: _success,
      ),
    ];

    return Column(
      children: activities.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        final isLast = i == activities.length - 1;
        return _buildTimelineRow(item, isLast: isLast);
      }).toList(),
    );
  }

  Widget _buildTimelineRow(_TimelineItem item, {bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                const SizedBox(height: 4),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: _border,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        item.time,
                        style: const TextStyle(color: _muted, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.date,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEFF6FF),
          foregroundColor: const Color(0xFF1E40AF),
          elevation: 0,
          side: const BorderSide(color: _border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        child: const Text(
          'Export data',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TimelineItem {
  const _TimelineItem({
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.dotColor,
  });

  final String title;
  final String description;
  final String date;
  final String time;
  final Color dotColor;
}
