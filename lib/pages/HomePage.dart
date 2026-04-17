import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_app/pages/AnalyticsScreen.dart';
import 'package:my_app/pages/ControlScreen.dart';
import 'package:my_app/pages/ProfileScreen.dart';
import 'package:my_app/Services/HomePage_api.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<Map<String, dynamic>> futureData;
  Map<String, dynamic>? _lastSensorData;
  Timer? _pollingTimer;
  bool _isFetching = false;

  static const String _overrideBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _success = Color(0xFF10B981);
  static const Color _successBackground = Color(0xFFECFDF5);
  static const Color _warning = Color(0xFFF97316);
  static const Color _warningDeep = Color(0xFFD97706);
  static const Color _warningBackground = Color(0xFFFDE68A);
  static const Color _teal = Color(0xFF06B6D4);
  static const Color _violet = Color(0xFFA855F7);

  @override
  void initState() {
    super.initState();
    futureData = _fetchInitialData();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchInitialData() async {
    _isFetching = true;
    try {
      final raw = await HomePageApi.getLatestSensorData(
        overrideBaseUrl: _overrideBaseUrl.isEmpty ? null : _overrideBaseUrl,
        timeout: const Duration(seconds: 8),
      );

      final latest = _getLatestSensorData(raw);
      if (latest != null) {
        _lastSensorData = latest;
      }

      return raw;
    } finally {
      _isFetching = false;
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _refreshSilently();
    });
  }

  Future<void> _refreshSilently() async {
    if (!mounted || _isFetching) return;

    _isFetching = true;
    try {
      final raw = await HomePageApi.getLatestSensorData(
        overrideBaseUrl: _overrideBaseUrl.isEmpty ? null : _overrideBaseUrl,
        timeout: const Duration(seconds: 8),
      );

      final latest = _getLatestSensorData(raw);
      if (!mounted || latest == null) return;

      setState(() {
        _lastSensorData = latest;
      });
    } catch (_) {
    } finally {
      _isFetching = false;
    }
  }

  void refreshData() {
    if (!mounted || _isFetching) return;

    setState(() {
      futureData = _fetchInitialData();
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(),
          const ControlScreen(),
          const AnalyticsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_input_component),
            label: 'Control',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: _primary,
        unselectedItemColor: _muted,
        showUnselectedLabels: true,
        backgroundColor: _surface,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  Widget _buildStatusKolamCard(Map<String, dynamic>? sensorData, {bool isLoading = false}) {
    final loading = isLoading && sensorData == null;
    final status = loading ? 'Memuat...' : _pondStatusFromSensor(sensorData);
    final statusColor = loading ? _muted : _pondStatusTextColor(status);
    final statusBackground = loading ? Colors.grey.shade200 : _pondStatusBackground(status);

    final hariBudidaya = sensorData == null
        ? null
        : _extractNumericValue(sensorData, [
            'hari_budidaya',
            'budidaya_hari',
            'culture_day',
            'day_of_culture',
          ]);

    final estimasiPanen = sensorData == null
        ? null
        : _extractNumericValue(sensorData, [
            'estimasi_panen_hari',
            'est_panen_hari',
            'harvest_estimate_day',
            'harvest_days_left',
          ]);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.waves, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Status Kolam',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hari Budidaya', style: TextStyle(color: Colors.white)),
                  if (loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      _formatWholeNumber(hariBudidaya),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Est. Panen', style: TextStyle(color: Colors.white)),
                  if (loading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  else
                    Text(
                      _formatDays(estimasiPanen),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _asStringKeyedMap(dynamic value) {
    if (value is! Map) {
      return null;
    }

    return value.map(
      (key, dynamic nestedValue) => MapEntry(key.toString(), nestedValue),
    );
  }

  Map<String, dynamic>? _getLatestSensorData(Map<String, dynamic> rawData) {
    final nestedData = rawData['data'];

    if (nestedData is List && nestedData.isNotEmpty) {
      return _asStringKeyedMap(nestedData.first);
    }

    final mapData = _asStringKeyedMap(nestedData);
    return mapData ?? rawData;
  }

  String _extractStringValue(Map<String, dynamic>? data, List<String> keys) {
    if (data == null || data.isEmpty) return '-';

    final normalizedKeys = keys.map((e) => e.toLowerCase()).toSet();

    for (final entry in data.entries) {
      if (!normalizedKeys.contains(entry.key.toLowerCase())) continue;

      final value = entry.value;
      if (value == null) return '-';

      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return '-';

      return text;
    }

    return '-';
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    return null;
  }

  String _normalizeMetricKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double? _extractNumericValue(Map<String, dynamic> data, List<String> keys) {
    final normalizedKeys = keys.map(_normalizeMetricKey).toSet();

    for (final entry in data.entries) {
      final entryKey = _normalizeMetricKey(entry.key);

      if (normalizedKeys.contains(entryKey)) {
        final directValue = _toDouble(entry.value);
        if (directValue != null) return directValue;

        if (entry.value is Map) {
          final mapValue = entry.value as Map;
          final nestedValue = mapValue['value'] ?? mapValue['nilai'] ?? mapValue['val'];
          final parsedNested = _toDouble(nestedValue);
          if (parsedNested != null) return parsedNested;
        }
      }
    }

    return null;
  }

  String _pondStatusFromSensor(Map<String, dynamic>? sensorData) {
    final statusFromApi = _extractStringValue(sensorData, [
      'status',
      'status_kolam',
      'pond_status',
    ]);

    if (statusFromApi != '-') {
      return statusFromApi;
    }

    if (sensorData == null) {
      return 'Tidak ada data';
    }

    final ammonia = _extractNumericValue(sensorData, ['ammonia', 'amonia', 'nh3']);
    final ph = _extractNumericValue(sensorData, ['ph', 'ph_level']);
    final doLevel = _extractNumericValue(sensorData, [
      'do',
      'do_level',
      'dissolved_oxygen',
      'dissolvedoxygen',
      'oxygen',
    ]);
    final suhu = _extractNumericValue(sensorData, [
      'suhu',
      'suhu_air',
      'temperature',
      'temp',
      'water_temperature',
    ]);

    final hasAnyData = [ammonia, ph, doLevel, suhu].any((value) => value != null);
    if (!hasAnyData) {
      return 'Tidak ada data';
    }

    final warning = (ammonia != null && ammonia > 0.2) ||
        (ph != null && (ph < 6.5 || ph > 8.5)) ||
        (doLevel != null && doLevel < 5) ||
        (suhu != null && (suhu < 24 || suhu > 32));

    return warning ? 'Perlu perhatian' : 'Optimal';
  }

  Color _pondStatusTextColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'optimal' || normalized == 'normal') {
      return _success;
    }

    if (normalized == 'tidak ada data' || normalized == '-') {
      return _muted;
    }

    return _warning;
  }

  Color _pondStatusBackground(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'optimal' || normalized == 'normal') {
      return _successBackground;
    }

    if (normalized == 'tidak ada data' || normalized == '-') {
      return Colors.grey.shade200;
    }

    return _warningBackground;
  }

  String _formatWholeNumber(double? value) {
    if (value == null) {
      return '-';
    }

    return value.toStringAsFixed(0);
  }

  String _formatDays(double? value) {
    if (value == null) {
      return '-';
    }

    return '${value.toStringAsFixed(0)} Hari';
  }

  String _formatValue(double? value, {String unit = '', int precision = 1}) {
    if (value == null) {
      return '-';
    }

    return '${value.toStringAsFixed(precision)}$unit';
  }

  String _statusInRange(double? value, {required double min, required double max}) {
    if (value == null) {
      return 'No Data';
    }

    return (value >= min && value <= max) ? 'Normal' : 'Alert';
  }

  String _statusMin(double? value, {required double min}) {
    if (value == null) {
      return 'No Data';
    }

    return value >= min ? 'Normal' : 'Alert';
  }

  String _statusMax(double? value, {required double max}) {
    if (value == null) {
      return 'No Data';
    }

    return value <= max ? 'Normal' : 'Alert';
  }

  Color _metricStatusColor(String status) {
    if (status == 'Normal') {
      return _success;
    }

    if (status == 'No Data') {
      return _muted;
    }

    return _warning;
  }

  Widget _buildSensorGrid(Map<String, dynamic>? sensorData, {bool isLoading = false}) {
    final loading = isLoading && sensorData == null;

    final suhuAir = sensorData == null
        ? null
        : _extractNumericValue(sensorData, [
            'suhu',
            'suhu_air',
            'temperature',
            'temp',
            'water_temperature',
          ]);

    final turbidity = sensorData == null
        ? null
        : _extractNumericValue(sensorData, ['turbidity', 'kekeruhan', 'ntu']);

    final phLevel = sensorData == null
        ? null
        : _extractNumericValue(sensorData, ['ph', 'ph_level']);

    final doLevel = sensorData == null
        ? null
        : _extractNumericValue(sensorData, [
            'do',
            'do_level',
            'dissolved_oxygen',
            'dissolvedoxygen',
            'oxygen',
          ]);

    final suhuStatus = _statusInRange(suhuAir, min: 24, max: 32);
    final turbidityStatus = _statusMax(turbidity, max: 50);
    final phStatus = _statusInRange(phLevel, min: 6.5, max: 8.5);
    final doStatus = _statusMin(doLevel, min: 5);

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15,
      children: [
        _buildSensorCard(
          'Suhu Air',
          _formatValue(suhuAir, unit: '°C'),
          Icons.thermostat,
          _warning,
          statusText: loading ? 'Loading' : suhuStatus,
          statusColor: loading ? _muted : _metricStatusColor(suhuStatus),
          isLoading: loading,
        ),
        _buildSensorCard(
          'Turbidity',
          _formatValue(turbidity, unit: ' NTU'),
          Icons.visibility,
          _teal,
          statusText: loading ? 'Loading' : turbidityStatus,
          statusColor: loading ? _muted : _metricStatusColor(turbidityStatus),
          isLoading: loading,
        ),
        _buildSensorCard(
          'pH Level',
          _formatValue(phLevel, precision: 2),
          Icons.science_outlined,
          _violet,
          statusText: loading ? 'Loading' : phStatus,
          statusColor: loading ? _muted : _metricStatusColor(phStatus),
          isLoading: loading,
        ),
        _buildSensorCard(
          'DO',
          _formatValue(doLevel, unit: ' mg/L'),
          Icons.air,
          _success,
          statusText: loading ? 'Loading' : doStatus,
          statusColor: loading ? _muted : _metricStatusColor(doStatus),
          isLoading: loading,
        ),
      ],
    );
  }

  Widget _buildSensorCard(
    String title,
    String value,
    IconData icon,
    Color iconColor, {
    required String statusText,
    required Color statusColor,
    bool isLoading = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _muted.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(color: _textPrimary)),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 2, bottom: 2),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            )
          else
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(color: statusColor),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmmoniaWarningCard(Map<String, dynamic>? sensorData, {bool isLoading = false}) {
    final loading = isLoading && sensorData == null;

    if (loading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Memuat data ammonia...',
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final ammoniaLevel = sensorData == null
        ? null
        : _extractNumericValue(sensorData, ['ammonia', 'amonia', 'nh3']);

    final isSafe = ammoniaLevel != null && ammoniaLevel <= 0.2;
    final ammoniaText = ammoniaLevel == null ? '-' : ammoniaLevel.toStringAsFixed(2);

    final titleColor = ammoniaLevel == null
        ? _muted
        : isSafe
            ? _success
            : _warning;

    final subtitleColor = ammoniaLevel == null
        ? _textSecondary
        : isSafe
            ? _success
            : _warningDeep;

    final bgColor = ammoniaLevel == null
        ? Colors.grey.shade100
        : isSafe
            ? _successBackground
            : _warningBackground;

    final message = ammoniaLevel == null
        ? 'Data ammonia belum tersedia'
        : isSafe
            ? 'Masih dalam batas aman'
            : 'Melebihi batas aman';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: titleColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perhatian Ammonia',
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ammonia: $ammoniaText mg/L - $message',
                  style: TextStyle(color: subtitleColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Gagal mengambil data sensor dari endpoint.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: refreshData,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildAksiCepatGrid() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildAksiCard(
            'Atur Pakan',
            'Kontrol pemberian pakan',
            Icons.schedule,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAksiCard(
            'Lihat Prediksi',
            'Analisa machine learning',
            Icons.trending_up,
          ),
        ),
      ],
    );
  }

  Widget _buildAksiCard(String title, String subtitle, IconData icon) {
    return Container(
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _muted.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _primary, size: 24),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: _textSecondary, fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardView() {
    return SafeArea(
      child: FutureBuilder<Map<String, dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          final initialData = snapshot.hasData
              ? _getLatestSensorData(snapshot.data!)
              : null;

          final sensorData = _lastSensorData ?? initialData;

          final isInitialLoading =
              snapshot.connectionState == ConnectionState.waiting &&
              sensorData == null;

          final hasInitialError = snapshot.hasError && sensorData == null;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const Text(
                'BluVera',
                style: TextStyle(
                  color: _primary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Dashboard',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Greenhouse Tel-U - Kolam 1',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              _buildStatusKolamCard(sensorData, isLoading: isInitialLoading),
              const SizedBox(height: 16),
              if (hasInitialError)
                _buildDataErrorCard()
              else ...[
                _buildAmmoniaWarningCard(sensorData, isLoading: isInitialLoading),
                const SizedBox(height: 16),
                _buildSensorGrid(sensorData, isLoading: isInitialLoading),
              ],
              const SizedBox(height: 24),
              const Text(
                'Aksi Cepat',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildAksiCepatGrid(),
            ],
          );
        },
      ),
    );
  }
}
