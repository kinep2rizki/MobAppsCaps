// ignore_for_file: file_names

import 'package:flutter/material.dart';

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
							_buildMenuCard(),
							const SizedBox(height: 24),
							_buildLogoutButton(),
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

	Widget _buildMenuCard() {
		final items = <_MenuItemData>[
			const _MenuItemData(
				icon: Icons.waves,
				title: 'Manajemen Kolam',
				subtitle: '3 Kolam Aktif',
			),
			const _MenuItemData(
				icon: Icons.notifications_active_outlined,
				title: 'Notifikasi & Alert',
				subtitle: 'Atur peringatan sistem',
			),
			const _MenuItemData(
				icon: Icons.history,
				title: 'Riwayat Data',
				subtitle: 'Lihat data historis',
			),
			const _MenuItemData(
				icon: Icons.water_drop_outlined,
				title: 'Kalibrasi Sensor',
				subtitle: 'Terakhir : 2 hari lalu',
			),
			const _MenuItemData(
				icon: Icons.person_outline,
				title: 'Edit Profile',
				subtitle: 'Perbarui informasi akun',
			),
			const _MenuItemData(
				icon: Icons.settings_outlined,
				title: 'Pengaturan Sistem',
				subtitle: 'Atur preferensi aplikasi',
			),
		];

		return Container(
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: _border),
			),
			child: Column(
				children: items
						.map((item) => _buildMenuItem(item))
						.toList(),
			),
		);
	}

	Widget _buildMenuItem(_MenuItemData item) {
		return Column(
			children: [
				ListTile(
					contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
					leading: Container(
						width: 40,
						height: 40,
						decoration: BoxDecoration(
							color: _cardBackground,
							borderRadius: BorderRadius.circular(12),
						),
						child: Icon(item.icon, color: _iconAccent),
					),
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
					onTap: () {},
				),
				if (item != _menuDividerSentinel)
					const Divider(height: 1, thickness: 1, color: _border),
			],
		);
	}

	Widget _buildLogoutButton() {
		return Center(
			child: TextButton(
				onPressed: () {},
				child: const Text(
					'Keluar',
					style: TextStyle(
						color: _danger,
						fontSize: 16,
						fontWeight: FontWeight.bold,
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
	});

	final IconData icon;
	final String title;
	final String subtitle;
}

const _MenuItemData _menuDividerSentinel =
		_MenuItemData(icon: Icons.info, title: '', subtitle: '');
