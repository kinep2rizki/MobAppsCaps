import 'package:flutter/material.dart';

class AlertDanNotifikasiPage extends StatefulWidget {
  const AlertDanNotifikasiPage({super.key});

  @override
  State<AlertDanNotifikasiPage> createState() => _AlertDanNotifikasiPageState();
}

class _AlertDanNotifikasiPageState extends State<AlertDanNotifikasiPage> {
  // ── Colour palette (same as ManajemenKolam) ──
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _danger = Color(0xFFEF4444);
  static const Color _success = Color(0xFF10B981);

  // Extra tones for this page
  static const Color _warning = Color(0xFFEA580C);
  static const Color _warningSurface = Color(0xFFFFF7ED);
  static const Color _dangerSurface = Color(0xFFFEF2F2);
  static const Color _primarySurface = Color(0xFFEFF6FF);

  // ── Toggle states ──
  bool _parameterAir = true;
  bool _stokPakan = true;
  bool _jadwalPanen = true;
  bool _kalibrasiSensor = true;
  bool _laporanHarian = true;

  // ── Alert data ──
  final List<_AlertData> _alerts = [
    _AlertData(
      title: 'Suhu Air Tinggi',
      description: 'Kolam A1: 32 C (Batas Normal: 26-30 C)',
      tag: 'Kolam A1',
      timeAgo: '2 Jam Lalu',
      isUnread: true,
      severity: _AlertSeverity.critical,
    ),
    _AlertData(
      title: 'Do Menurun',
      description: 'Dissolved Oxygen turun ke 4.5 mg/L',
      tag: 'Kolam A2',
      timeAgo: '2 Jam Lalu',
      isUnread: true,
      severity: _AlertSeverity.critical,
    ),
    _AlertData(
      title: 'Stok Pakan Menipis',
      description: 'Dissolved Oxygen turun ke 4.5 mg/L',
      tag: 'Semua kolam',
      timeAgo: '1 Hari Lalu',
      isUnread: false,
      severity: _AlertSeverity.warning,
    ),
    _AlertData(
      title: 'Pemberian Pakan Otomatis',
      description: 'Pakan berhasil diberikan : 2.5 Kg pukul 07:00',
      tag: 'Semua kolam',
      timeAgo: '3 Hari Lalu',
      isUnread: false,
      severity: _AlertSeverity.info,
    ),
  ];

  int get _unreadCount => _alerts.where((a) => a.isUnread).length;

  void _markAllRead() {
    setState(() {
      for (final a in _alerts) {
        a.isUnread = false;
      }
    });
  }

  void _clearAll() {
    setState(() => _alerts.clear());
  }

  void _removeAlert(int index) {
    setState(() => _alerts.removeAt(index));
  }

  // ── Build ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: [
                    // ── Pengaturan Notifikasi ──
                    const Text(
                      'Pengaturan Notifikasi',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildToggleTile(
                      title: 'Parameter Air abnormal',
                      subtitle:
                          'Notifikasi saat Suhu, PH atau DO di luar batas',
                      value: _parameterAir,
                      onChanged: (v) => setState(() => _parameterAir = v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Stok Pakan Menipis',
                      subtitle: 'Peringatan saat stok pakan < 20 Kg',
                      value: _stokPakan,
                      onChanged: (v) => setState(() => _stokPakan = v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Jadwal Panen',
                      subtitle: 'Reminder 7 hari sebelum waktu panen',
                      value: _jadwalPanen,
                      onChanged: (v) => setState(() => _jadwalPanen = v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Kalibrasi Sensor',
                      subtitle: 'Reminder kalibrasi rutin sensor',
                      value: _kalibrasiSensor,
                      onChanged: (v) => setState(() => _kalibrasiSensor = v),
                    ),
                    const SizedBox(height: 12),
                    _buildToggleTile(
                      title: 'Laporan Harian',
                      subtitle: 'Ringkasan kondisi kolam setiap hari',
                      value: _laporanHarian,
                      onChanged: (v) => setState(() => _laporanHarian = v),
                    ),
                    const SizedBox(height: 28),

                    // ── Riwayat Alert ──
                    Row(
                      children: [
                        const Text(
                          'Riwayat Alert',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (_unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _danger,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$_unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        GestureDetector(
                          onTap: _markAllRead,
                          child: const Text(
                            'Tandai Semua dibaca',
                            style: TextStyle(
                              color: _primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _clearAll,
                          child: const Text(
                            'Hapus Semua',
                            style: TextStyle(
                              color: _danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Alert cards
                    ...List.generate(_alerts.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildAlertCard(_alerts[i], i),
                      );
                    }),
                    if (_alerts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'Tidak ada alert',
                            style: TextStyle(color: _muted, fontSize: 14),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _border),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              size: 18,
              color: _textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Notifikasi & Alert',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Atur Peringatan Sistem',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Toggle tile ──
  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          // Left accent line
          Container(
            width: 3,
            height: 40,
            decoration: BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: _success,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: _muted.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  // ── Alert card ──
  Widget _buildAlertCard(_AlertData alert, int index) {
    final bool isCritical = alert.severity == _AlertSeverity.critical;
    final Color accentColor = isCritical ? _danger : _warning;
    final Color cardBg =
        isCritical
            ? _dangerSurface
            : (alert.severity == _AlertSeverity.warning
                ? _warningSurface
                : _primarySurface);
    final Color iconBg =
        isCritical ? _danger.withOpacity(0.15) : _warning.withOpacity(0.15);
    final IconData iconData =
        isCritical ? Icons.warning_amber_rounded : Icons.info_outline_rounded;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left colour bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(iconData, size: 18, color: accentColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  alert.title,
                                  style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (alert.isUnread)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: _danger,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _removeAlert(index),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 18, color: _danger),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Description
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Text(
                        alert.description,
                        style: const TextStyle(
                          color: _textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Tag + time
                    Padding(
                      padding: const EdgeInsets.only(left: 42),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isCritical
                                      ? _danger.withOpacity(0.12)
                                      : _primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              alert.tag,
                              style: TextStyle(
                                color: isCritical ? _danger : _primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.circle, size: 4, color: _muted),
                          const SizedBox(width: 8),
                          Text(
                            alert.timeAgo,
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
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

// ── Models ──
enum _AlertSeverity { critical, warning, info }

class _AlertData {
  _AlertData({
    required this.title,
    required this.description,
    required this.tag,
    required this.timeAgo,
    required this.isUnread,
    required this.severity,
  });

  final String title;
  final String description;
  final String tag;
  final String timeAgo;
  bool isUnread;
  final _AlertSeverity severity;
}
