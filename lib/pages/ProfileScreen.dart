// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:my_app/Services/NotificationService.dart';
import 'package:my_app/pages/ProfilePages/ManajemenKolam.dart';
import 'package:my_app/pages/ProfilePages/AlertDanNotifikasi.dart';
import 'package:my_app/pages/ProfilePages/RiwayatData.dart';
import 'package:my_app/pages/ProfilePages/KalibrasiSensor.dart';
import 'package:my_app/pages/ProfilePages/EditProfile.dart';
import 'package:my_app/pages/ProfilePages/PengaturanSistem.dart';
import 'package:my_app/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primary = Color(0xFF2563EB);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _muted = Color(0xFF9CA3AF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _highlight = Color(0xFFBFDBFE);
  static const Color _iconAccent = Color(0xFF3B82F6);
  static const Color _danger = Color(0xFFDC2626);
  static const Color _cardBackground = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildProfileCard(),
              const SizedBox(height: 20),
              _buildMenuCard(context),
              const SizedBox(height: 24),
              _buildLogoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BluVera',
          style: TextStyle(
            color: _primary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Profile',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Pengaturan akun dan sistem',
          style: TextStyle(
            color: _textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: _highlight,
            child: Icon(Icons.person, color: _primary, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budidaya Nila',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Greenhouse Telu',
                  style: TextStyle(color: Colors.white70),
                ),
                Text(
                  'gthelyu@gmail.com',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context) {
    final items = <_MenuItemData>[
      const _MenuItemData(
        icon: Icons.waves,
        title: 'Manajemen Kolam',
        subtitle: '3 Kolam Aktif',
        isPondManagement: true,
      ),
      const _MenuItemData(
        icon: Icons.notifications_active_outlined,
        title: 'Notifikasi & Alert',
        subtitle: 'Atur peringatan sistem',
        isNotificationAlert: true,
      ),
      const _MenuItemData(
        icon: Icons.history,
        title: 'Riwayat Data',
        subtitle: 'Lihat data historis',
        isRiwayatData: true,
      ),
      const _MenuItemData(
        icon: Icons.water_drop_outlined,
        title: 'Kalibrasi Sensor',
        subtitle: 'Terakhir : 2 hari lalu',
        isKalibrasiSensor: true,
      ),
      const _MenuItemData(
        icon: Icons.person_outline,
        title: 'Edit Profile',
        subtitle: 'Perbarui informasi akun',
        isEditProfile: true,
      ),
      const _MenuItemData(
        icon: Icons.settings_outlined,
        title: 'Pengaturan Sistem',
        subtitle: 'Atur preferensi aplikasi',
        isSystemSettings: true,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: items.map((item) => _buildMenuItem(context, item)).toList(),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, _MenuItemData item) {
    return Column(
      children: [
        ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: _buildMenuLeading(item),
          title: Text(
            item.title,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            item.subtitle,
            style: const TextStyle(color: _textSecondary),
          ),
          trailing: const Icon(Icons.chevron_right, color: _muted),
          onTap: () {
            if (item.isPondManagement) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ManajemenKolamPage(),
                ),
              );
            } else if (item.isNotificationAlert) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AlertDanNotifikasiPage(),
                ),
              );
            } else if (item.isRiwayatData) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RiwayatDataPage(),
                ),
              );
            } else if (item.isKalibrasiSensor) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const KalibrasiSensorPage(),
                ),
              );
            } else if (item.isEditProfile) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditProfilePage(),
                ),
              );
            } else if (item.isSystemSettings) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PengaturanSistemPage(),
                ),
              );
            }
          },
        ),
        if (item != _menuDividerSentinel)
          const Divider(height: 1, thickness: 1, color: _border),
      ],
    );
  }

  Widget _buildMenuLeading(_MenuItemData item) {
    final base = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(item.icon, color: _iconAccent),
    );

    if (!item.isNotificationAlert) {
      return base;
    }

    return ValueListenableBuilder<int>(
      valueListenable: NotificationPopupManager.unreadCountNotifier,
      builder: (_, unreadCount, __) {
        if (unreadCount <= 0) {
          return base;
        }

        final badgeText = unreadCount > 99 ? '99+' : '$unreadCount';

        return Stack(
          clipBehavior: Clip.none,
          children: [
            base,
            Positioned(
              right: -7,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: _danger,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Keluar'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: _danger),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true || !context.mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Keluar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _danger,
          side: const BorderSide(color: _danger),
          backgroundColor: _surface,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

class _MenuItemData {
  const _MenuItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPondManagement = false,
    this.isNotificationAlert = false,
    this.isRiwayatData = false,
    this.isKalibrasiSensor = false,
    this.isEditProfile = false,
    this.isSystemSettings = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPondManagement;
  final bool isNotificationAlert;
  final bool isRiwayatData;
  final bool isKalibrasiSensor;
  final bool isEditProfile;
  final bool isSystemSettings;
}

const _MenuItemData _menuDividerSentinel =
    _MenuItemData(icon: Icons.info, title: '', subtitle: '');
