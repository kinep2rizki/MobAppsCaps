import 'package:flutter/material.dart';
import 'package:my_app/Services/api_service.dart';
import 'dart:math' as math;
import 'dart:ui';

class RiwayatDataPage extends StatefulWidget {
  const RiwayatDataPage({
    super.key,
    this.fetchSensorData = ApiService.getSensorData,
  });

  final Future<List<dynamic>> Function() fetchSensorData;

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
  bool _isChartLoading = true;
  String? _chartError;
  Map<String, List<double>> _metricSeries = {};
  String? _selectedMetricKey;
  DateTime? _lastUpdatedAt;
  final List<String> _kolamOptions = [
    'Semua Kolam',
    'Kolam A1',
    'Kolam A2',
    'Kolam A3',
  ];

  static const Set<String> _excludedMetricKeys = {
    'id',
    'kolam',
    'kolam_id',
    'pond',
    'pond_id',
    'pool',
    'farm_id',
    'timestamp',
    'date',
    'time',
    'created_at',
    'updated_at',
  };

  @override
  void initState() {
    super.initState();
    _refreshChartData();
  }

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
            if (val != null && val != _selectedKolam) {
              setState(() => _selectedKolam = val);
              _refreshChartData(showLoading: false);
            }
          },
        ),
      ),
    );
  }

  Future<void> _refreshChartData({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _isChartLoading = true;
        _chartError = null;
      });
    }

    try {
      final response = await widget.fetchSensorData();
      final parsedSeries = _buildMetricSeries(response);
      final sortedKeys = parsedSeries.keys.toList()..sort();

      if (!mounted) {
        return;
      }

      setState(() {
        _metricSeries = parsedSeries;
        _lastUpdatedAt = DateTime.now();
        _isChartLoading = false;

        if (sortedKeys.isEmpty) {
          _selectedMetricKey = null;
          _chartError = 'Data sensor dari database belum tersedia.';
        } else {
          _selectedMetricKey = sortedKeys.contains(_selectedMetricKey)
              ? _selectedMetricKey
              : sortedKeys.first;
          _chartError = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isChartLoading = false;
        _chartError = 'Gagal mengambil data sensor dari database.';
      });
    }
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), nestedValue),
    );
  }

  Map<String, dynamic>? _extractRowData(dynamic entry) {
    final entryMap = _asStringKeyedMap(entry);
    if (entryMap == null) {
      return null;
    }

    final nestedData = _asStringKeyedMap(entryMap['data']);
    return nestedData ?? entryMap;
  }

  bool _rowMatchesSelectedKolam(Map<String, dynamic> row) {
    if (_selectedKolam == 'Semua Kolam') {
      return true;
    }

    final selected = _selectedKolam.toLowerCase();
    const lookupKeys = ['kolam', 'kolam_id', 'pond', 'pond_id', 'pool'];

    bool hasKolamMetadata = false;
    for (final key in lookupKeys) {
      final value = row[key];
      if (value == null) {
        continue;
      }

      hasKolamMetadata = true;
      if (value.toString().toLowerCase().contains(selected)) {
        return true;
      }
    }

    return !hasKolamMetadata;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  Map<String, List<double>> _buildMetricSeries(List<dynamic> response) {
    final series = <String, List<double>>{};

    for (final entry in response) {
      final row = _extractRowData(entry);
      if (row == null || !_rowMatchesSelectedKolam(row)) {
        continue;
      }

      for (final item in row.entries) {
        final key = item.key.toLowerCase();
        if (_excludedMetricKeys.contains(key)) {
          continue;
        }

        final parsedValue = _toDouble(item.value);
        if (parsedValue == null) {
          continue;
        }

        series.putIfAbsent(key, () => []).add(parsedValue);
      }
    }

    return series;
  }

  int _chartPointCount() {
    switch (_selectedPeriod) {
      case 0:
        return 7;
      case 1:
        return 14;
      default:
        return 30;
    }
  }

  List<double> _currentSeriesValues() {
    final key = _selectedMetricKey;
    if (key == null) {
      return const [];
    }

    final values = _metricSeries[key] ?? const [];
    final pointCount = _chartPointCount();
    if (values.length <= pointCount) {
      return values;
    }

    return values.sublist(values.length - pointCount);
  }

  String _formatChartTime() {
    if (_lastUpdatedAt == null) {
      return '-';
    }

    final dt = _lastUpdatedAt!;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _metricDisplayName(String key) {
    switch (key) {
      case 'temperature':
      case 'temp':
      case 'suhu':
      case 'suhu_air':
      case 'water_temperature':
        return 'Suhu';
      case 'ph':
      case 'ph_level':
        return 'pH';
      case 'do':
      case 'dissolved_oxygen':
      case 'oxygen':
        return 'DO';
      case 'turbidity':
      case 'kekeruhan':
      case 'ntu':
        return 'Turbidity';
      case 'ammonia':
      case 'amonia':
      case 'nh3':
        return 'Amonia';
      default:
        final parts = key.split('_');
        return parts
            .map(
              (part) => part.isEmpty
                  ? part
                  : '${part[0].toUpperCase()}${part.substring(1)}',
            )
            .join(' ');
    }
  }

  int _metricPrecision(String key) {
    const twoPrecisionKeys = {
      'ph',
      'ph_level',
      'ammonia',
      'amonia',
      'nh3',
    };
    return twoPrecisionKeys.contains(key) ? 2 : 1;
  }

  String _metricUnit(String key) {
    const units = {
      'temperature': 'C',
      'temp': 'C',
      'suhu': 'C',
      'suhu_air': 'C',
      'water_temperature': 'C',
      'do': 'mg/L',
      'dissolved_oxygen': 'mg/L',
      'oxygen': 'mg/L',
      'turbidity': 'NTU',
      'kekeruhan': 'NTU',
      'ntu': 'NTU',
      'ammonia': 'mg/L',
      'amonia': 'mg/L',
      'nh3': 'mg/L',
    };

    return units[key] ?? '';
  }

  String _formatMetricValue(double value, String key) {
    final valueText = value.toStringAsFixed(_metricPrecision(key));
    final unit = _metricUnit(key);
    if (unit.isEmpty) {
      return valueText;
    }
    return '$valueText $unit';
  }

  Color _metricColor(String key) {
    switch (key) {
      case 'temperature':
      case 'temp':
      case 'suhu':
      case 'suhu_air':
      case 'water_temperature':
        return const Color(0xFFEF4444);
      case 'ph':
      case 'ph_level':
        return const Color(0xFF8B5CF6);
      case 'do':
      case 'dissolved_oxygen':
      case 'oxygen':
        return const Color(0xFF06B6D4);
      case 'turbidity':
      case 'kekeruhan':
      case 'ntu':
        return const Color(0xFFF59E0B);
      case 'ammonia':
      case 'amonia':
      case 'nh3':
        return const Color(0xFFF97316);
      default:
        return _primary;
    }
  }

  Widget _buildMetricSelector() {
    final keys = _metricSeries.keys.toList()..sort();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: keys.map((key) {
        final isSelected = key == _selectedMetricKey;
        final chipColor = _metricColor(key);

        return ChoiceChip(
          label: Text(_metricDisplayName(key)),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _selectedMetricKey = key;
            });
          },
          side: BorderSide(
            color: isSelected ? chipColor.withOpacity(0.4) : _border,
          ),
          selectedColor: chipColor.withOpacity(0.16),
          backgroundColor: _surface,
          labelStyle: TextStyle(
            color: isSelected ? chipColor : _textSecondary,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }).toList(),
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
    final selectedKey = _selectedMetricKey;
    final chartValues = _currentSeriesValues();
    final hasData = selectedKey != null && chartValues.isNotEmpty;
    final activeColor = selectedKey == null ? _primary : _metricColor(selectedKey);

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
              const Spacer(),
              IconButton(
                onPressed: () => _refreshChartData(showLoading: false),
                tooltip: 'Refresh data sensor',
                icon: const Icon(Icons.refresh, color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isChartLoading && !hasData)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!hasData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _chartError ?? 'Belum ada data sensor yang bisa divisualisasikan.',
                    style: const TextStyle(
                      color: _textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _refreshChartData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Coba Muat Ulang'),
                  ),
                ],
              ),
            )
          else ...[
            const Text(
              'Pilih Parameter Sensor',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _buildMetricSelector(),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Parameter aktif: ${_metricDisplayName(selectedKey)}',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update terakhir: ${_formatChartTime()}',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 190,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: CustomPaint(
                painter: _SensorLineChartPainter(
                  values: chartValues,
                  lineColor: activeColor,
                  gridColor: _border.withOpacity(0.65),
                ),
                child: const SizedBox.expand(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Min: ${_formatMetricValue(chartValues.reduce(math.min), selectedKey)}',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  'Maks: ${_formatMetricValue(chartValues.reduce(math.max), selectedKey)}',
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Nilai terbaru: ${_formatMetricValue(chartValues.last, selectedKey)}',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Center(
              child: Text(
                'Data ${_periods[_selectedPeriod].toLowerCase()} terakhir - $_selectedKolam',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ),
          ],
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
        onPressed: _showExportDialog,
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

  void _showExportDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Tutup',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, _, __) {
        return Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.white.withOpacity(0.45)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _border),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_outlined,
                              size: 22,
                              color: _textPrimary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Export data',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => Navigator.of(context).pop(),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4),
                                child: Icon(
                                  Icons.close,
                                  color: _danger,
                                  size: 28,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Export data periode ${_periods[_selectedPeriod].toLowerCase()} untuk $_selectedKolam',
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildExportOptionButton(
                          text: 'Export ke Excel (.xlsx)',
                          icon: Icons.table_chart,
                          ext: 'XLS',
                          bgColor: const Color(0xFFDDF4E8),
                          textColor: const Color(0xFF047857),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showExportResult('Excel (.xlsx)');
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildExportOptionButton(
                          text: 'Export ke PDF',
                          icon: Icons.picture_as_pdf,
                          ext: 'PDF',
                          bgColor: const Color(0xFFFBE6E6),
                          textColor: const Color(0xFFB91C1C),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showExportResult('PDF');
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildExportOptionButton(
                          text: 'Export ke CSV',
                          icon: Icons.description_outlined,
                          ext: 'CSV',
                          bgColor: const Color(0xFFF3F4F6),
                          textColor: const Color(0xFF374151),
                          onPressed: () {
                            Navigator.of(context).pop();
                            _showExportResult('CSV');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, animation, _, child) {
        final curve = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: curve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildExportOptionButton({
    required String text,
    required IconData icon,
    required String ext,
    required Color bgColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: textColor),
                Text(
                  ext,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showExportResult(String format) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Proses export $format dimulai...'),
        behavior: SnackBarBehavior.floating,
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

class _SensorLineChartPainter extends CustomPainter {
  const _SensorLineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const horizontalLines = 4;
    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height * i / horizontalLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    final stepX = values.length == 1 ? 0.0 : size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final normalizedY = (values[i] - minValue) / range;
      points.add(
        Offset(
          stepX * i,
          size.height - (normalizedY * size.height),
        ),
      );
    }

    final linePath = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      if (i == 0) {
        linePath.moveTo(point.dx, point.dy);
        fillPath.moveTo(point.dx, size.height);
        fillPath.lineTo(point.dx, point.dy);
      } else {
        linePath.lineTo(point.dx, point.dy);
        fillPath.lineTo(point.dx, point.dy);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.25),
          lineColor.withOpacity(0.03),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final pointPaint = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(point, 2.6, pointPaint);
    }

    final latestPoint = points.last;
    canvas.drawCircle(latestPoint, 5, pointPaint);
    canvas.drawCircle(latestPoint, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SensorLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
