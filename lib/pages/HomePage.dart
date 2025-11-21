// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:my_app/pages/AnalyticsScreen.dart';
import 'package:my_app/pages/ControlScreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
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
          _buildPlaceholder('Profile segera hadir'),
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

  Widget _buildAmmoniaWarningCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _warningBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _warning),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Perhatian Ammonia',
                  style: TextStyle(
                    color: _warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Level ammonia : 0.15 mg/L - Masih dalam batas aman',
                  style: TextStyle(color: _warningDeep),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.15, // kembali lebih proporsional namun masih aman dari overflow
      children: [
        _buildSensorCard('Suhu Air', '30°C', Icons.thermostat, _warning),
        _buildSensorCard('Turbidity', '42 NTU', Icons.visibility, _teal),
        _buildSensorCard('pH Level', '7.3', Icons.science_outlined, _violet),
        _buildSensorCard('DO', '7.3', Icons.air, _success),
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
    // Solusi sederhana: Row dengan kartu yang memiliki tinggi minimum tetap
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
    // Kartu dengan constraints minimum untuk menghindari overflow
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
      child: ListView(
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
          _buildAmmoniaWarningCard(),
          const SizedBox(height: 16),
          _buildSensorGrid(),
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
      ),
    );
  }

  Widget _buildPlaceholder(String message) {
    return SafeArea(
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
