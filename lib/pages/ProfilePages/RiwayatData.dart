import 'package:flutter/material.dart';
import 'package:my_app/Services/api_service.dart';
import 'dart:math' as math;
import 'dart:ui';

enum _AggregationMode {
  hourly,
  daily,
  weekly,
}

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
  Map<String, List<DateTime?>> _metricSeriesTimes = {};
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
                'Periode Data',
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
                'Pilih Kolam',
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
      final parsedBundle = _buildMetricSeries(response);
      final sortedKeys = parsedBundle.valuesByMetric.keys.toList()..sort();

      if (!mounted) {
        return;
      }

      setState(() {
        _metricSeries = parsedBundle.valuesByMetric;
        _metricSeriesTimes = parsedBundle.timestampsByMetric;
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
    if (nestedData == null) {
      return entryMap;
    }

    // Keep root metadata (e.g. timestamp) while preferring nested payload values.
    return {
      ...entryMap,
      ...nestedData,
    };
  }

  DateTime? _parseTimestamp(dynamic rawValue) {
    if (rawValue == null) {
      return null;
    }

    if (rawValue is DateTime) {
      return rawValue.toLocal();
    }

    if (rawValue is num) {
      final asInt = rawValue.toInt();
      if (asInt <= 0) {
        return null;
      }

      final milliseconds = asInt > 1000000000000 ? asInt : asInt * 1000;
      return DateTime.fromMillisecondsSinceEpoch(
        milliseconds,
        isUtc: true,
      ).toLocal();
    }

    if (rawValue is String) {
      final parsed = DateTime.tryParse(rawValue);
      if (parsed != null) {
        return parsed.toLocal();
      }

      final epochSecondsOrMilliseconds = int.tryParse(rawValue);
      if (epochSecondsOrMilliseconds != null &&
          epochSecondsOrMilliseconds > 0) {
        final milliseconds = epochSecondsOrMilliseconds > 1000000000000
            ? epochSecondsOrMilliseconds
            : epochSecondsOrMilliseconds * 1000;
        return DateTime.fromMillisecondsSinceEpoch(
          milliseconds,
          isUtc: true,
        ).toLocal();
      }
    }

    return null;
  }

  DateTime? _extractTimestampFromRow(Map<String, dynamic> row) {
    const timestampKeys = [
      'timestamp',
      'created_at',
      'updated_at',
      'date_time',
      'datetime',
      'recorded_at',
      'time',
      'date',
    ];

    for (final key in timestampKeys) {
      final parsed = _parseTimestamp(row[key]);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
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

  _MetricSeriesBundle _buildMetricSeries(List<dynamic> response) {
    final series = <String, List<double>>{};
    final timestampsByMetric = <String, List<DateTime?>>{};

    for (final entry in response) {
      final row = _extractRowData(entry);
      if (row == null || !_rowMatchesSelectedKolam(row)) {
        continue;
      }

      final timestamp = _extractTimestampFromRow(row);

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
        timestampsByMetric.putIfAbsent(key, () => []).add(timestamp);
      }
    }

    return _MetricSeriesBundle(
      valuesByMetric: series,
      timestampsByMetric: timestampsByMetric,
    );
  }

  int _chartWindowDays() {
    switch (_selectedPeriod) {
      case 0:
        return 7;
      case 1:
        return 30;
      default:
        return 90;
    }
  }

  int _fallbackPointsPerDay() {
    // Digunakan saat timestamp tidak tersedia; tampilkan cakupan harian yang cukup.
    return 24;
  }

  _AggregationMode _aggregationMode() {
    switch (_selectedPeriod) {
      case 0:
        return _AggregationMode.hourly;
      case 1:
        return _AggregationMode.daily;
      default:
        return _AggregationMode.weekly;
    }
  }

  String _aggregationUnitLabel() {
    switch (_aggregationMode()) {
      case _AggregationMode.hourly:
        return 'jam';
      case _AggregationMode.daily:
        return 'hari';
      case _AggregationMode.weekly:
        return 'minggu';
    }
  }

  DateTime _bucketStartForAggregation(DateTime value) {
    final local = value.toLocal();
    switch (_aggregationMode()) {
      case _AggregationMode.hourly:
        return DateTime(local.year, local.month, local.day, local.hour);
      case _AggregationMode.daily:
        return DateTime(local.year, local.month, local.day);
      case _AggregationMode.weekly:
        final dayStart = DateTime(local.year, local.month, local.day);
        return dayStart.subtract(Duration(days: dayStart.weekday - 1));
    }
  }

  DateTime _bucketLabelTime(DateTime bucketStart) {
    switch (_aggregationMode()) {
      case _AggregationMode.hourly:
        return bucketStart.add(const Duration(minutes: 30));
      case _AggregationMode.daily:
        return bucketStart.add(const Duration(hours: 12));
      case _AggregationMode.weekly:
        return bucketStart.add(const Duration(days: 3, hours: 12));
    }
  }

  List<_ChartDataPoint> _currentAggregatedPoints() {
    final rawPoints = _currentRawPoints();
    if (rawPoints.isEmpty) {
      return const [];
    }

    final pointsWithTimestamp = rawPoints
        .where((point) => point.timestamp != null)
        .map(
          (point) => _ChartDataPoint(
            value: point.value,
            timestamp: point.timestamp!.toLocal(),
          ),
        )
        .toList();

    if (pointsWithTimestamp.isEmpty) {
      return rawPoints;
    }

    pointsWithTimestamp.sort(
      (a, b) => a.timestamp!.compareTo(b.timestamp!),
    );

    final buckets = <DateTime, _AggregationBucket>{};

    for (final point in pointsWithTimestamp) {
      final ts = point.timestamp!;
      final bucketStart = _bucketStartForAggregation(ts);
      final bucket = buckets.putIfAbsent(
        bucketStart,
        () => _AggregationBucket(),
      );
      bucket.add(point.value);
    }

    if (buckets.isEmpty) {
      return pointsWithTimestamp;
    }

    final sortedBucketStarts = buckets.keys.toList()..sort();

    return sortedBucketStarts.map((bucketStart) {
      final bucket = buckets[bucketStart]!;
      return _ChartDataPoint(
        value: bucket.average,
        timestamp: _bucketLabelTime(bucketStart),
        minValue: bucket.min,
        maxValue: bucket.max,
      );
    }).toList();
  }

  List<_ChartDataPoint> _selectedMetricRawPoints() {
    final key = _selectedMetricKey;
    if (key == null) {
      return const [];
    }

    final values = _metricSeries[key] ?? const [];
    if (values.isEmpty) {
      return const [];
    }

    final times = _metricSeriesTimes[key] ?? const [];
    final points = <_ChartDataPoint>[];

    for (int i = 0; i < values.length; i++) {
      points.add(
        _ChartDataPoint(
          value: values[i],
          timestamp: i < times.length ? times[i] : null,
        ),
      );
    }

    return points;
  }

  List<_ChartDataPoint> _currentRawPoints() {
    final points = _selectedMetricRawPoints();
    if (points.isEmpty) {
      return const [];
    }

    final fallbackPointCount = _chartWindowDays() * _fallbackPointsPerDay();
    final pointsWithTimestamp = points
        .where((point) => point.timestamp != null)
        .map(
          (point) => _ChartDataPoint(
            value: point.value,
            timestamp: point.timestamp!.toLocal(),
          ),
        )
        .toList();

    if (pointsWithTimestamp.isEmpty) {
      if (points.length <= fallbackPointCount) {
        return points;
      }

      return points.sublist(points.length - fallbackPointCount);
    }

    pointsWithTimestamp.sort(
      (a, b) => a.timestamp!.compareTo(b.timestamp!),
    );

    final latestTimestamp = pointsWithTimestamp.last.timestamp!;
    final latestDayStart = DateTime(
      latestTimestamp.year,
      latestTimestamp.month,
      latestTimestamp.day,
    );
    final windowStart = latestDayStart.subtract(
      Duration(days: _chartWindowDays() - 1),
    );
    final windowEnd = latestDayStart.add(const Duration(days: 1));

    final filtered = pointsWithTimestamp
        .where(
          (point) =>
              !point.timestamp!.isBefore(windowStart) &&
              point.timestamp!.isBefore(windowEnd),
        )
        .toList();

    if (filtered.isNotEmpty) {
      return filtered;
    }

    if (pointsWithTimestamp.length <= fallbackPointCount) {
      return pointsWithTimestamp;
    }

    return pointsWithTimestamp.sublist(
      pointsWithTimestamp.length - fallbackPointCount,
    );
  }

  List<double> _metricWindowValues(String key) {
    final values = _metricSeries[key] ?? const [];
    if (values.isEmpty) {
      return const [];
    }

    final times = _metricSeriesTimes[key] ?? const [];
    final points = <_ChartDataPoint>[];

    for (int i = 0; i < values.length; i++) {
      points.add(
        _ChartDataPoint(
          value: values[i],
          timestamp: i < times.length ? times[i] : null,
        ),
      );
    }

    final fallbackPointCount = _chartWindowDays() * _fallbackPointsPerDay();
    final pointsWithTimestamp = points
        .where((point) => point.timestamp != null)
        .map(
          (point) => _ChartDataPoint(
            value: point.value,
            timestamp: point.timestamp!.toLocal(),
          ),
        )
        .toList();

    if (pointsWithTimestamp.isEmpty) {
      final fallback = points.length <= fallbackPointCount
          ? points
          : points.sublist(points.length - fallbackPointCount);
      return fallback.map((point) => point.value).toList(growable: false);
    }

    pointsWithTimestamp.sort(
      (a, b) => a.timestamp!.compareTo(b.timestamp!),
    );

    final latestTimestamp = pointsWithTimestamp.last.timestamp!;
    final latestDayStart = DateTime(
      latestTimestamp.year,
      latestTimestamp.month,
      latestTimestamp.day,
    );
    final windowStart = latestDayStart.subtract(
      Duration(days: _chartWindowDays() - 1),
    );
    final windowEnd = latestDayStart.add(const Duration(days: 1));

    final filtered = pointsWithTimestamp
        .where(
          (point) =>
              !point.timestamp!.isBefore(windowStart) &&
              point.timestamp!.isBefore(windowEnd),
        )
        .toList();

    if (filtered.isNotEmpty) {
      return filtered.map((point) => point.value).toList(growable: false);
    }

    final fallback = pointsWithTimestamp.length <= fallbackPointCount
        ? pointsWithTimestamp
        : pointsWithTimestamp.sublist(
            pointsWithTimestamp.length - fallbackPointCount,
          );
    return fallback.map((point) => point.value).toList(growable: false);
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

  double _averageValue(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    final total = values.fold<double>(0, (sum, value) => sum + value);
    return total / values.length;
  }

  double _trendDelta(List<double> values) {
    if (values.length < 2) {
      return 0;
    }

    return values.last - values.first;
  }

  String _trendText(List<double> values, String key) {
    if (values.length < 2) {
      return 'Belum cukup data';
    }

    final delta = _trendDelta(values);
    if (delta.abs() < 0.0001) {
      return 'Stabil';
    }

    final deltaValue = _formatMetricValue(delta.abs(), key);
    return delta > 0 ? 'Naik $deltaValue' : 'Turun $deltaValue';
  }

  Color _trendColor(List<double> values) {
    if (values.length < 2) {
      return _muted;
    }

    final delta = _trendDelta(values);
    if (delta.abs() < 0.0001) {
      return _muted;
    }

    return delta > 0 ? _success : _danger;
  }

  String _formatAxisTick(double value, String key) {
    final text = value.toStringAsFixed(_metricPrecision(key));
    final unit = _metricUnit(key);
    if (unit.isEmpty) {
      return text;
    }

    return '$text $unit';
  }

  Widget _buildInsightCard({
    required String label,
    required String value,
    required Color accent,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: accent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accent,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYAxisLabels({
    required double minValue,
    required double maxValue,
    required String metricKey,
  }) {
    final midValue = (minValue + maxValue) / 2;
    final ticks = [maxValue, midValue, minValue];

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: ticks
          .map(
            (value) => Text(
              _formatAxisTick(value, metricKey),
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildChartLegendItem({
    required Color color,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _monthShort(int month) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return monthNames[month - 1];
  }

  String _formatDateTimeLabel(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthShort(local.month);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month $hour:$minute';
  }

  String _formatXAxisDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = _monthShort(local.month);
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day $month\n$hour:$minute';
  }

  int _xAxisLabelCount() {
    switch (_selectedPeriod) {
      case 0:
        return 7;
      case 1:
        return 6;
      default:
        return 6;
    }
  }

  List<int> _buildXAxisIndices(int dataLength) {
    if (dataLength <= 1) {
      return const [0];
    }

    final desiredLabels = math.min(_xAxisLabelCount(), dataLength);
    final indices = <int>{0, dataLength - 1};

    if (desiredLabels > 2) {
      final step = (dataLength - 1) / (desiredLabels - 1);
      for (int i = 1; i < desiredLabels - 1; i++) {
        indices.add((step * i).round());
      }
    }

    final sorted = indices.toList()..sort();
    return sorted;
  }

  List<String> _xAxisLabels(List<_ChartDataPoint> points) {
    if (points.isEmpty) {
      return const ['-'];
    }

    final indices = _buildXAxisIndices(points.length);

    return indices
        .map(
          (index) => points[index].timestamp == null
              ? '-'
              : _formatXAxisDateTime(points[index].timestamp),
        )
        .toList();
  }

  Widget _buildXAxisLabels(List<_ChartDataPoint> points) {
    final labels = _xAxisLabels(points);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final isFirst = index == 0;
        final isLast = index == labels.length - 1;

        return Expanded(
          child: Text(
            label,
            textAlign: isFirst
                ? TextAlign.left
                : isLast
                    ? TextAlign.right
                    : TextAlign.center,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        );
      }).toList(),
    );
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

  int _metricPriority(String key) {
    switch (key) {
      case 'temperature':
      case 'temp':
      case 'suhu':
      case 'suhu_air':
      case 'water_temperature':
        return 0;
      case 'ph':
      case 'ph_level':
        return 1;
      case 'do':
      case 'dissolved_oxygen':
      case 'oxygen':
        return 2;
      case 'turbidity':
      case 'kekeruhan':
      case 'ntu':
        return 3;
      case 'ammonia':
      case 'amonia':
      case 'nh3':
        return 4;
      default:
        return 99;
    }
  }

  List<_RingkasanMetricItem> _buildRingkasanMetricItems() {
    final keys = _metricSeries.keys.toList()
      ..sort((a, b) {
        final priorityCompare =
            _metricPriority(a).compareTo(_metricPriority(b));
        if (priorityCompare != 0) {
          return priorityCompare;
        }

        return _metricDisplayName(a).compareTo(_metricDisplayName(b));
      });

    final items = <_RingkasanMetricItem>[];

    for (final key in keys) {
      final metricValues = _metricWindowValues(key);
      if (metricValues.isEmpty) {
        continue;
      }

      final average = _averageValue(metricValues);
      final delta = _trendDelta(metricValues);
      final trendUp =
          metricValues.length < 2 || delta.abs() < 0.0001 ? null : delta > 0;
      final trendText = metricValues.length < 2
          ? 'Min. data'
          : delta.abs() < 0.0001
              ? 'Stabil'
              : _formatMetricValue(delta.abs(), key);

      items.add(
        _RingkasanMetricItem(
          label: 'Rata-rata ${_metricDisplayName(key)}',
          value: _formatMetricValue(average, key),
          trend: trendText,
          trendUp: trendUp,
        ),
      );

      if (items.length >= 4) {
        break;
      }
    }

    return items;
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
    final items = _buildRingkasanMetricItems();

    if (_isChartLoading && items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border),
        ),
        child: const Text(
          'Ringkasan belum tersedia karena data sensor pada periode ini kosong.',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < items.length; i += 2) {
      final left = items[i];
      final right = i + 1 < items.length ? items[i + 1] : null;

      rows.add(
        Row(
          children: [
            _buildStatCard(
              label: left.label,
              value: left.value,
              trend: left.trend,
              trendUp: left.trendUp,
            ),
            const SizedBox(width: 12),
            if (right != null)
              _buildStatCard(
                label: right.label,
                value: right.value,
                trend: right.trend,
                trendUp: right.trendUp,
              )
            else
              const Expanded(child: SizedBox.shrink()),
          ],
        ),
      );

      if (i + 2 < items.length) {
        rows.add(const SizedBox(height: 12));
      }
    }

    return Column(children: rows);
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
    final metricKey = selectedKey ?? '';
    final rawPoints = _currentRawPoints();
    final rawValues =
        rawPoints.map((point) => point.value).toList(growable: false);
    final chartPoints = _currentAggregatedPoints();
    final chartValues =
        chartPoints.map((point) => point.value).toList(growable: false);
    final chartMinValues = chartPoints
        .map((point) => point.minValue ?? point.value)
        .toList(growable: false);
    final chartMaxValues = chartPoints
        .map((point) => point.maxValue ?? point.value)
        .toList(growable: false);
    final hasData = selectedKey != null && chartValues.isNotEmpty;
    final activeColor =
        selectedKey == null ? _primary : _metricColor(selectedKey);

    final rangeSourceValues = hasData
        ? <double>[...chartMinValues, ...chartMaxValues]
        : const <double>[];

    final minValue = hasData ? rangeSourceValues.reduce(math.min) : 0.0;
    final maxValue = hasData ? rangeSourceValues.reduce(math.max) : 0.0;
    final averageSourceValues = hasData
        ? (rawValues.isNotEmpty ? rawValues : chartValues)
        : const <double>[];
    final averageValue = hasData ? _averageValue(averageSourceValues) : 0.0;
    final latestValue = hasData
        ? (rawValues.isNotEmpty ? rawValues.last : chartValues.last)
        : 0.0;
    final latestDataTime = hasData
        ? (rawPoints.isNotEmpty
            ? rawPoints.last.timestamp
            : chartPoints.last.timestamp)
        : null;
    final oldestDataTime = hasData
        ? (rawPoints.isNotEmpty
            ? rawPoints.first.timestamp
            : chartPoints.first.timestamp)
        : null;

    final trendSource = hasData ? chartValues : const <double>[];
    final trendText = hasData ? _trendText(trendSource, metricKey) : '-';
    final trendColor = hasData ? _trendColor(trendSource) : _muted;

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
                'Grafik Aggregasi Parameter',
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
          Text(
            'Data diringkas dengan rata-rata per ${_aggregationUnitLabel()} agar grafik lebih renggang dan mudah dibaca.',
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildChartLegendItem(
                color: activeColor,
                label: 'Rata-rata agregasi',
              ),
              const SizedBox(width: 12),
              _buildChartLegendItem(
                color: activeColor.withOpacity(0.28),
                label: 'Rentang min-maks',
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
                    _chartError ??
                        'Belum ada data sensor yang bisa divisualisasikan.',
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
                    'Parameter aktif: ${_metricDisplayName(metricKey)}',
                    style: TextStyle(
                      color: activeColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Data terbaru: ${_formatDateTimeLabel(latestDataTime)} • Rentang ${_periods[_selectedPeriod].toLowerCase()}',
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (latestDataTime == null)
                    Text(
                      'Update aplikasi: ${_formatChartTime()}',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInsightCard(
                  label: 'Nilai terbaru',
                  value: _formatMetricValue(latestValue, metricKey),
                  accent: activeColor,
                  icon: Icons.new_releases_outlined,
                ),
                const SizedBox(width: 10),
                _buildInsightCard(
                  label: 'Rata-rata',
                  value: _formatMetricValue(averageValue, metricKey),
                  accent: _primary,
                  icon: Icons.functions,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildInsightCard(
                  label: 'Rentang nilai agregasi',
                  value:
                      '${_formatMetricValue(minValue, metricKey)} - ${_formatMetricValue(maxValue, metricKey)}',
                  accent: _textSecondary,
                  icon: Icons.straighten,
                ),
                const SizedBox(width: 10),
                _buildInsightCard(
                  label: 'Perubahan agregasi',
                  value: trendText,
                  accent: trendColor,
                  icon: Icons.show_chart,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 220,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 2),
                  SizedBox(
                    width: 58,
                    child: _buildYAxisLabels(
                      minValue: minValue,
                      maxValue: maxValue,
                      metricKey: metricKey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: CustomPaint(
                            painter: _SensorLineChartPainter(
                              values: chartValues,
                              minValues: chartMinValues,
                              maxValues: chartMaxValues,
                              axisMin: minValue,
                              axisMax: maxValue,
                              lineColor: activeColor,
                              gridColor: _border.withOpacity(0.65),
                            ),
                            child: const SizedBox.expand(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildXAxisLabels(chartPoints),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SizedBox(width: 58),
                  const SizedBox(width: 2),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Rentang data agregasi: ${_formatDateTimeLabel(oldestDataTime)} - ${_formatDateTimeLabel(latestDataTime)} • $_selectedKolam',
                style: const TextStyle(color: _muted, fontSize: 12),
                textAlign: TextAlign.center,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

class _MetricSeriesBundle {
  const _MetricSeriesBundle({
    required this.valuesByMetric,
    required this.timestampsByMetric,
  });

  final Map<String, List<double>> valuesByMetric;
  final Map<String, List<DateTime?>> timestampsByMetric;
}

class _ChartDataPoint {
  const _ChartDataPoint({
    required this.value,
    required this.timestamp,
    this.minValue,
    this.maxValue,
  });

  final double value;
  final DateTime? timestamp;
  final double? minValue;
  final double? maxValue;
}

class _RingkasanMetricItem {
  const _RingkasanMetricItem({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
  });

  final String label;
  final String value;
  final String trend;
  final bool? trendUp;
}

class _AggregationBucket {
  double _sum = 0;
  int _count = 0;
  double? _min;
  double? _max;

  void add(double value) {
    _sum += value;
    _count += 1;
    _min = _min == null ? value : math.min(_min!, value);
    _max = _max == null ? value : math.max(_max!, value);
  }

  double get average => _count == 0 ? 0 : _sum / _count;
  double get min => _min ?? 0;
  double get max => _max ?? 0;
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
    required this.minValues,
    required this.maxValues,
    required this.axisMin,
    required this.axisMax,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final List<double> minValues;
  final List<double> maxValues;
  final double axisMin;
  final double axisMax;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final hasRangeBars =
        minValues.length == values.length && maxValues.length == values.length;

    final minValue = math.min(axisMin, axisMax);
    final maxValue = math.max(axisMin, axisMax);
    final range =
        (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);
    const verticalPadding = 10.0;
    const horizontalPadding = 8.0;
    final drawableHeight = size.height - (verticalPadding * 2);
    final drawableWidth = size.width - (horizontalPadding * 2);

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    const horizontalLines = 4;
    for (int i = 0; i <= horizontalLines; i++) {
      final y = size.height * i / horizontalLines;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    const verticalLines = 2;
    for (int i = 0; i <= verticalLines; i++) {
      final x = size.width * i / verticalLines;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    List<Offset> buildPoints(List<double> sourceValues) {
      final points = <Offset>[];
      final stepX = sourceValues.length == 1
          ? 0.0
          : drawableWidth / (sourceValues.length - 1);

      for (int i = 0; i < sourceValues.length; i++) {
        final normalizedY = (sourceValues[i] - minValue) / range;
        points.add(
          Offset(
            horizontalPadding + (stepX * i),
            verticalPadding + ((1 - normalizedY) * drawableHeight),
          ),
        );
      }

      return points;
    }

    Path buildPath(List<Offset> sourcePoints) {
      final path = Path();
      for (int i = 0; i < sourcePoints.length; i++) {
        final point = sourcePoints[i];
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      return path;
    }

    final linePoints = buildPoints(values);

    final rangePaint = Paint()
      ..color = lineColor.withOpacity(0.24)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (hasRangeBars) {
      for (int i = 0; i < linePoints.length; i++) {
        final normalizedMinY = (minValues[i] - minValue) / range;
        final normalizedMaxY = (maxValues[i] - minValue) / range;

        final minY = verticalPadding + ((1 - normalizedMinY) * drawableHeight);
        final maxY = verticalPadding + ((1 - normalizedMaxY) * drawableHeight);

        canvas.drawLine(
          Offset(linePoints[i].dx, maxY),
          Offset(linePoints[i].dx, minY),
          rangePaint,
        );
      }
    }

    canvas.drawPath(buildPath(linePoints), linePaint);

    final pointPaint = Paint()..color = lineColor;
    final shouldDrawAllPoints = linePoints.length <= 48;
    if (shouldDrawAllPoints) {
      for (final point in linePoints) {
        canvas.drawCircle(point, 2.2, pointPaint);
      }
    }

    final latestPoint = linePoints.last;
    canvas.drawLine(
      Offset(latestPoint.dx, 0),
      Offset(latestPoint.dx, size.height),
      Paint()
        ..color = lineColor.withOpacity(0.2)
        ..strokeWidth = 1.1,
    );
    canvas.drawCircle(
      latestPoint,
      7,
      Paint()..color = lineColor.withOpacity(0.18),
    );
    canvas.drawCircle(latestPoint, 5, pointPaint);
    canvas.drawCircle(latestPoint, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _SensorLineChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.minValues != minValues ||
        oldDelegate.maxValues != maxValues ||
        oldDelegate.axisMin != axisMin ||
        oldDelegate.axisMax != axisMax ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
