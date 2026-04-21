// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:my_app/Services/NotificationService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PengaturanSistemPage extends StatefulWidget {
  const PengaturanSistemPage({super.key});

  @override
  State<PengaturanSistemPage> createState() => _PengaturanSistemPageState();
}

class _PengaturanSistemPageState extends State<PengaturanSistemPage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _icon = Color(0xFF4B5563);
  static const Color _primary = Color(0xFF22C55E);
  static const Color _muted = Color(0xFF9CA3AF);

  late SharedPreferences _prefs;
  bool _loading = true;
  bool _darkMode = false;
  bool _pushNotifications = true;
  String _language = 'Bahasa Indonesia';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = _prefs.getBool('darkMode') ?? false;
      _pushNotifications = _prefs.getBool('pushNotifications') ?? true;
      _language = _prefs.getString('appLanguage') ?? 'Bahasa Indonesia';
      _loading = false;
    });
  }

  Future<void> _setDarkMode(bool value) async {
    setState(() => _darkMode = value);
    await _prefs.setBool('darkMode', value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text(value ? 'Mode gelap diaktifkan' : 'Mode gelap dimatikan')),
    );
  }

  Future<void> _setNotifications(bool value) async {
    setState(() => _pushNotifications = value);
    await _prefs.setBool('pushNotifications', value);
    await NotificationPopupManager.setPushEnabled(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              value ? 'Notifikasi push aktif' : 'Notifikasi push nonaktif')),
    );
  }

  Future<void> _setLanguage(String value) async {
    setState(() => _language = value);
    await _prefs.setString('appLanguage', value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bahasa diubah ke $value')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 28),
                    Container(
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          _buildSwitchRow(
                            icon: Icons.nightlight_round,
                            title: 'Mode Gelap',
                            subtitle: 'Tampilan nyaman di mata',
                            value: _darkMode,
                            onChanged: _setDarkMode,
                          ),
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                          _buildActionRow(
                            icon: Icons.lock_outline,
                            title: 'Ubah kata sandi',
                            subtitle: 'Terakhir diubah 3 bulan lalu',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const UbahKataSandiPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                          _buildSwitchRow(
                            icon: Icons.notifications_none,
                            title: 'Push Notifikasi',
                            subtitle: 'Peringatan real-time di HP',
                            value: _pushNotifications,
                            onChanged: _setNotifications,
                          ),
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                          _buildActionRow(
                            icon: Icons.menu_book_outlined,
                            title: 'Panduan Pengguna',
                            subtitle: 'Cara penggunaan aplikasi',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const PanduanPenggunaPage(),
                                ),
                              );
                            },
                          ),
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                          _buildActionRow(
                            icon: Icons.language,
                            title: 'Bahasa/Language',
                            subtitle: _language,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => BahasaPage(
                                    currentLanguage: _language,
                                    onSelected: _setLanguage,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Divider(
                              height: 1, thickness: 1, color: _border),
                          _buildVersionRow(),
                        ],
                      ),
                    ),
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
          borderRadius: BorderRadius.circular(20),
          child: const Icon(Icons.chevron_left, size: 34, color: _muted),
        ),
        const SizedBox(width: 8),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan Sistem',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Konfigurasi Aplikasi',
              style: TextStyle(
                color: _textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: _icon, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _textSecondary, fontSize: 12),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: _primary,
      ),
    );
  }

  Widget _buildActionRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: _icon, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: _textSecondary, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: _muted),
      onTap: onTap,
    );
  }

  Widget _buildVersionRow() {
    return const ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(Icons.info_outline, color: _icon, size: 28),
      title: Text(
        'Versi Aplikasi',
        style: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        'v1.1 (Beta)',
        style: TextStyle(color: _textSecondary, fontSize: 12),
      ),
    );
  }
}

class UbahKataSandiPage extends StatefulWidget {
  const UbahKataSandiPage({super.key});

  @override
  State<UbahKataSandiPage> createState() => _UbahKataSandiPageState();
}

class _UbahKataSandiPageState extends State<UbahKataSandiPage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _currentPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _currentPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).maybePop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Icon(Icons.chevron_left,
                          size: 34, color: _textSecondary),
                    ),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ubah Kata Sandi',
                          style: TextStyle(
                              color: _textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w700),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Buat kata sandi yang lebih aman',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    children: [
                      _buildField('Kata sandi saat ini', _currentPassword),
                      const SizedBox(height: 14),
                      _buildField('Kata sandi baru', _newPassword,
                          obscureText: true),
                      const SizedBox(height: 14),
                      _buildField(
                          'Konfirmasi kata sandi baru', _confirmPassword,
                          obscureText: true),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Simpan Kata Sandi',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_saved) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Kata sandi berhasil diperbarui.'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '$label wajib diisi';
        }
        if (controller == _newPassword && value.trim().length < 6) {
          return 'Kata sandi baru minimal 6 karakter';
        }
        if (controller == _confirmPassword &&
            value.trim() != _newPassword.text.trim()) {
          return 'Konfirmasi tidak sama';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: _surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary),
        ),
      ),
    );
  }

  void _savePassword() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Kata sandi tersimpan secara lokal untuk pengujian')),
    );
  }
}

class PanduanPenggunaPage extends StatelessWidget {
  const PanduanPenggunaPage({super.key});

  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final sections = [
      ('Masuk ke halaman Profile', 'Buka tab Profile dari bottom navigation.'),
      (
        'Buka Pengaturan Sistem',
        'Pilih menu Pengaturan Sistem untuk mengatur preferensi aplikasi.'
      ),
      (
        'Atur notifikasi dan bahasa',
        'Gunakan switch dan halaman Language untuk menyimpan preferensi.'
      ),
      (
        'Ubah kata sandi',
        'Masukkan kata sandi lama, lalu isi kata sandi baru dan konfirmasi.'
      ),
    ];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(Icons.chevron_left,
                      size: 34, color: _textSecondary),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Panduan Pengguna',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Langkah singkat penggunaan aplikasi',
                        style: TextStyle(color: _textSecondary, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  for (final section in sections) ...[
                    _buildGuideItem(section.$1, section.$2),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Text(
                'Tips: setiap perubahan di halaman pengaturan langsung disimpan secara lokal agar mudah dites.',
                style: TextStyle(color: _textPrimary, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.check, color: _primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: _textPrimary, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: _textSecondary, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}

class BahasaPage extends StatefulWidget {
  const BahasaPage(
      {super.key, required this.currentLanguage, required this.onSelected});

  final String currentLanguage;
  final ValueChanged<String> onSelected;

  @override
  State<BahasaPage> createState() => _BahasaPageState();
}

class _BahasaPageState extends State<BahasaPage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);

  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final languages = const ['Bahasa Indonesia', 'English'];

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(20),
                  child: const Icon(Icons.chevron_left,
                      size: 34, color: _textSecondary),
                ),
                const SizedBox(width: 8),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bahasa / Language',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 2),
                    Text('Pilih bahasa aplikasi',
                        style: TextStyle(color: _textSecondary, fontSize: 14)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  for (final language in languages) ...[
                    RadioListTile<String>(
                      value: language,
                      groupValue: _selected,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _selected = value);
                        widget.onSelected(value);
                      },
                      activeColor: _primary,
                      title: Text(language,
                          style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        language == 'Bahasa Indonesia'
                            ? 'Bahasa utama aplikasi'
                            : 'App language',
                        style: const TextStyle(color: _textSecondary),
                      ),
                    ),
                    if (language != languages.last)
                      const Divider(height: 1, thickness: 1, color: _border),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
