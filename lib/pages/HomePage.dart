// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:my_app/pages/AnalyticsScreen.dart';
import 'package:my_app/pages/ControlScreen.dart';
import 'package:my_app/pages/ProfileScreen.dart';
import 'package:my_app/Services/api_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.fetchSensorData = ApiService.getSensorData,
  });

  final Future<List<dynamic>> Function() fetchSensorData;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  late Future<List<dynamic>> futureData;
  Map<String, dynamic>? _lastSensorData;
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
    futureData = widget.fetchSensorData();

    Future.delayed(const Duration(seconds: 5), refreshData);
  }

  void refreshData() {
    if (!mounted) {
      return;
    }

    setState(() {
      futureData = widget.fetchSensorData();
    });

    Future.delayed(const Duration(seconds: 5), refreshData);
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

  Widget _buildStatusKolamCard() {
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
                  color: _successBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Optimal',
                  style: TextStyle(
                    color: _success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hari Budidaya', style: TextStyle(color: Colors.white)),
                  Text('45', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Est. Panen', style: TextStyle(color: Colors.white)),
                  Text('75 Hari', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
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

  Map<String, dynamic>? _getLatestSensorData(List<dynamic> rawData) {
    if (rawData.isEmpty) {
      return null;
    }

    final latestEntry = _asStringKeyedMap(rawData.last);
    if (latestEntry == null) {
      return null;
    }

    final nestedData = _asStringKeyedMap(latestEntry['data']);
    return nestedData ?? latestEntry;
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

  double? _extractNumericValue(Map<String, dynamic> data, List<String> keys) {
    final normalizedKeys = keys.map((key) => key.toLowerCase()).toSet();

    for (final entry in data.entries) {
      if (normalizedKeys.contains(entry.key.toLowerCase())) {
        return _toDouble(entry.value);
      }
    }

    return null;
  }

  String _formatValue(double? value, {String unit = '', int precision = 1}) {
    if (value == null) {
      return '-';
    }

    return '${value.toStringAsFixed(precision)}$unit';
  }

  Widget _buildAmmoniaWarningCard(Map<String, dynamic>? sensorData) {
    final ammoniaLevel = sensorData == null
        ? null
        : _extractNumericValue(sensorData, ['ammonia', 'amonia', 'nh3']);

    final statusText = ammoniaLevel == null
        ? 'Data ammonia belum tersedia'
        : ammoniaLevel <= 0.2
            ? 'Masih dalam batas aman'
            : 'Melebihi batas aman';

    final ammoniaText =
        ammoniaLevel == null ? '-' : ammoniaLevel.toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warningBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: _warning),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Perhatian Ammonia',
                  style: TextStyle(
                    color: _warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ammonia : $ammoniaText mg/L - $statusText',
                  style: const TextStyle(color: _warningDeep),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gagal mengambil data sensor dari database.',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
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

  Widget _buildSensorGrid(Map<String, dynamic>? sensorData) {
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
            'dissolved_oxygen',
            'oxygen',
          ]);

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
        ),
        _buildSensorCard(
          'Turbidity',
          _formatValue(turbidity, unit: ' NTU'),
          Icons.visibility,
          _teal,
        ),
        _buildSensorCard(
          'pH Level',
          _formatValue(phLevel, precision: 2),
          Icons.science_outlined,
          _violet,
        ),
        _buildSensorCard(
          'DO',
          _formatValue(doLevel, unit: ' mg/L'),
          Icons.air,
          _success,
        ),
      ],
    );
  }

  Widget _buildSensorCard(String title, String value, IconData icon, Color iconColor) {
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
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: _success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              const Text('Normal', style: TextStyle(color: _success)),
            ],
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
          child: _buildAksiCard('Atur Pakan', 'Kontrol Pemberian pakan', Icons.schedule),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAksiCard('Lihat Prediksi', 'Analisa Machine Learning', Icons.trending_up),
        ),
      ],
    );
  }

  Widget _buildAksiCard(String title, String subtitle, IconData icon) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 110,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      child: FutureBuilder<List<dynamic>>(
        future: futureData,
        builder: (context, snapshot) {
          final freshData = snapshot.hasData
              ? _getLatestSensorData(snapshot.data!)
              : null;

          if (freshData != null) {
            _lastSensorData = freshData;
          }

          final sensorData = freshData ?? _lastSensorData;

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
              _buildStatusKolamCard(),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting &&
                  sensorData == null)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (snapshot.hasError && sensorData == null)
                _buildDataErrorCard()
              else ...[
                _buildAmmoniaWarningCard(sensorData),
                const SizedBox(height: 16),
                _buildSensorGrid(sensorData),
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
