import 'package:flutter/material.dart';
import 'dart:ui';

class ManajemenKolamPage extends StatelessWidget {
	const ManajemenKolamPage({super.key});

	static const Color _textPrimary = Color(0xFF1F2937);
	static const Color _textSecondary = Color(0xFF6B7280);
	static const Color _textTertiary = Color(0xFF4B5563);
	static const Color _muted = Color(0xFF9CA3AF);
	static const Color _primary = Color(0xFF2563EB);
	static const Color _background = Color(0xFFF9FAFB);
	static const Color _surface = Color(0xFFFFFFFF);
	static const Color _surfaceAlt = Color(0xFFEFF6FF);
	static const Color _border = Color(0xFFE5E7EB);
	static const Color _cardAccent = Color(0xFFDBEAFE);
	static const Color _danger = Color(0xFFEF4444);
	static const Color _success = Color(0xFF047857);
	static const Color _successSurface = Color(0xFFD1FAE5);

	final List<_PondData> _ponds = const [
		_PondData(name: 'Kolam 1', dayCount: 45, size: '200 m²', isActive: true),
		_PondData(name: 'Kolam 2', dayCount: 32, size: '150 m²', isActive: true),
		_PondData(name: 'Kolam 3', dayCount: 12, size: '200 m²', isActive: false),
	];

	@override
	Widget build(BuildContext context) {
		final int activePonds = _ponds.where((pond) => pond.isActive).length;

		return Scaffold(
			backgroundColor: _background,
			body: SafeArea(
				child: Padding(
					padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							_buildHeader(context),
							const SizedBox(height: 12),
							Text(
								'$activePonds Kolam aktif',
								style: const TextStyle(
									color: _textSecondary,
									fontSize: 14,
								),
							),
							const SizedBox(height: 20),
							Expanded(
								child: ListView.separated(
									itemCount: _ponds.length,
									separatorBuilder: (_, __) => const SizedBox(height: 16),
									itemBuilder: (context, index) => _buildPondCard(context, _ponds[index]),
								),
							),
							const SizedBox(height: 20),
							_buildAddButton(context),
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
					child: Container(
						padding: const EdgeInsets.all(10),
						decoration: BoxDecoration(
							color: _surface,
							borderRadius: BorderRadius.circular(16),
							border: Border.all(color: _border),
						),
						child: const Icon(Icons.arrow_back_ios_new, size: 18, color: _textPrimary),
					),
				),
				const SizedBox(width: 16),
				Expanded(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: const [
							Text(
								'Manajemen Kolam',
								style: TextStyle(
									color: _textPrimary,
									fontSize: 22,
									fontWeight: FontWeight.w700,
								),
							),
							SizedBox(height: 4),
							Text(
								'Kelola kolam budidaya kamu',
								style: TextStyle(
									color: _textSecondary,
									fontSize: 14,
								),
							),
						],
					),
				),
			],
		);
	}

	Widget _buildPondCard(BuildContext context, _PondData pond) {
		return Container(
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(18),
				border: Border.all(color: _border),
				boxShadow: [
					BoxShadow(
						color: _textPrimary.withOpacity(0.04),
						blurRadius: 14,
						offset: const Offset(0, 8),
					),
				],
			),
			padding: const EdgeInsets.all(18),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								width: 48,
								height: 48,
								decoration: BoxDecoration(
									color: _cardAccent,
									borderRadius: BorderRadius.circular(14),
								),
								child: Icon(
									Icons.set_meal,
									color: _primary,
									size: 28,
								),
							),
							const SizedBox(width: 14),
							Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											pond.name,
											style: const TextStyle(
												color: _textPrimary,
												fontSize: 18,
												fontWeight: FontWeight.w600,
											),
										),
										const SizedBox(height: 2),
										Text(
											'Hari Budidaya ${pond.dayCount}',
											style: const TextStyle(color: _textTertiary, fontSize: 13),
										),
									],
								),
							),
							_buildStatusChip(pond.isActive),
							const SizedBox(width: 8),
							IconButton(
								onPressed: () {},
								icon: const Icon(Icons.close, size: 20, color: _danger),
							),
						],
					),
					const SizedBox(height: 16),
					Row(
						children: [
							_buildStatBox('Hari Budidaya', '${pond.dayCount}'),
							const SizedBox(width: 14),
							_buildStatBox('Ukuran', pond.size),
						],
					),
					const SizedBox(height: 16),
					_buildDetailButton(context, pond),
				],
			),
		);
	}

	Future<void> _showPondDetail(BuildContext context, _PondData pond) {
		return showGeneralDialog<void>(
			context: context,
			barrierDismissible: true,
			barrierLabel: 'Tutup',
			barrierColor: Colors.transparent,
			transitionDuration: const Duration(milliseconds: 180),
			pageBuilder: (context, animation, secondaryAnimation) {
				return Material(
					color: Colors.transparent,
					child: Stack(
						children: [
							Positioned.fill(
								child: BackdropFilter(
									filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
									child: Container(
										color: _textPrimary.withOpacity(0.16),
									),
								),
							),
							Center(
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 20),
									child: ConstrainedBox(
										constraints: const BoxConstraints(maxWidth: 420),
										child: Container(
											decoration: BoxDecoration(
												color: _surface.withOpacity(0.88),
												borderRadius: BorderRadius.circular(20),
												border: Border.all(color: _border),
											),
											child: Padding(
												padding: const EdgeInsets.all(18),
												child: Column(
													mainAxisSize: MainAxisSize.min,
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														Row(
															children: [
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Detail Kolam',
																				style: TextStyle(
																					color: _textPrimary,
																					fontSize: 18,
																					fontWeight: FontWeight.w700,
																				),
																			),
																			const SizedBox(height: 2),
																			Text(
																				pond.name,
																				style: const TextStyle(
																					color: _textSecondary,
																					fontSize: 13,
																				),
																			),
																		],
																	),
																),
																IconButton(
																	onPressed: () => Navigator.of(context).pop(),
																	icon: const Icon(Icons.close, color: _textSecondary),
																),
															],
														),
														const SizedBox(height: 14),
														Row(
															children: [
																_buildStatBox('Hari Budidaya', '${pond.dayCount}'),
																const SizedBox(width: 14),
																_buildStatBox('Ukuran', pond.size),
															],
														),
														const SizedBox(height: 14),
														Row(
															children: [
																const Text(
																	'Status',
																	style: TextStyle(
																		color: _textSecondary,
																		fontSize: 13,
																	),
																),
																const SizedBox(width: 10),
																_buildStatusChip(pond.isActive),
															],
														),
														const SizedBox(height: 18),
														SizedBox(
															width: double.infinity,
															child: TextButton(
																onPressed: () => Navigator.of(context).pop(),
																style: TextButton.styleFrom(
																	foregroundColor: _primary,
																	padding: const EdgeInsets.symmetric(vertical: 14),
																	shape: RoundedRectangleBorder(
																		borderRadius: BorderRadius.circular(14),
																		side: const BorderSide(color: _border),
																	),
																),
																child: const Text(
																	'Tutup',
																	style: TextStyle(fontWeight: FontWeight.w600),
																),
															),
														),
													],
												),
											),
										),
									),
								),
							),
						],
					),
				);
			},
			transitionBuilder: (context, animation, secondaryAnimation, child) {
				final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
				return FadeTransition(
					opacity: curved,
					child: ScaleTransition(
						scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
						child: child,
					),
				);
			},
		);
	}

	Widget _buildStatusChip(bool isActive) {
		final Color bg = isActive ? _successSurface : _surfaceAlt;
		final Color fg = isActive ? _success : _muted;
		final String label = isActive ? 'Aktif' : 'Nonaktif';

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
			decoration: BoxDecoration(
				color: bg,
				borderRadius: BorderRadius.circular(999),
			),
			child: Text(
				label,
				style: TextStyle(
					color: fg,
					fontWeight: FontWeight.w600,
					fontSize: 12,
				),
			),
		);
	}

	Widget _buildStatBox(String label, String value) {
		return Expanded(
			child: Container(
				padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
				decoration: BoxDecoration(
					color: _surfaceAlt,
					borderRadius: BorderRadius.circular(14),
				),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Text(
							label,
							style: const TextStyle(color: _textSecondary, fontSize: 13),
						),
						const SizedBox(height: 6),
						Text(
							value,
							style: const TextStyle(
								color: _textPrimary,
								fontSize: 20,
								fontWeight: FontWeight.bold,
							),
						),
					],
				),
			),
		);
	}

	Widget _buildDetailButton(BuildContext context, _PondData pond) {
		return Container(
			width: double.infinity,
			decoration: BoxDecoration(
				color: _cardAccent,
				borderRadius: BorderRadius.circular(14),
			),
			child: TextButton(
				onPressed: () => _showPondDetail(context, pond),
				child: const Text(
					'Lihat Detail',
					style: TextStyle(
						color: _primary,
						fontWeight: FontWeight.w600,
					),
				),
			),
		);
	}

	Future<void> _showAddPondDialog(BuildContext context) {
		final int activePonds = _ponds.where((p) => p.isActive).length;

		return showGeneralDialog<void>(
			context: context,
			barrierDismissible: true,
			barrierLabel: 'Tutup',
			barrierColor: Colors.transparent,
			transitionDuration: const Duration(milliseconds: 180),
			pageBuilder: (dialogContext, animation, secondaryAnimation) {
				return Material(
					color: Colors.transparent,
					child: Stack(
						children: [
							Positioned.fill(
								child: BackdropFilter(
									filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
									child: Container(
										color: _textPrimary.withOpacity(0.16),
									),
								),
							),
							Center(
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 20),
									child: ConstrainedBox(
										constraints: const BoxConstraints(maxWidth: 420),
										child: Container(
											decoration: BoxDecoration(
												color: _surface,
												borderRadius: BorderRadius.circular(20),
												boxShadow: [
													BoxShadow(
														color: _textPrimary.withOpacity(0.08),
														blurRadius: 24,
														offset: const Offset(0, 8),
													),
												],
											),
											child: Padding(
												padding: const EdgeInsets.all(20),
												child: Column(
													mainAxisSize: MainAxisSize.min,
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														// Header
														Row(
															children: [
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Manajemen Kolam',
																				style: TextStyle(
																					color: _textPrimary,
																					fontSize: 18,
																					fontWeight: FontWeight.w700,
																				),
																			),
																			const SizedBox(height: 2),
																			Text(
																				'$activePonds Kolam aktif',
																				style: const TextStyle(
																					color: _textSecondary,
																					fontSize: 13,
																				),
																			),
																		],
																	),
																),
																IconButton(
																	onPressed: () => Navigator.of(dialogContext).pop(),
																	icon: const Icon(Icons.close, color: _textSecondary),
																),
															],
														),
														const SizedBox(height: 18),
														// Nama Kolam
														const Text(
															'Nama Kolam',
															style: TextStyle(
																color: _textPrimary,
																fontSize: 14,
																fontWeight: FontWeight.w600,
															),
														),
														const SizedBox(height: 8),
														TextField(
															decoration: InputDecoration(
																hintText: 'Contoh: Kolam Nila B3',
																hintStyle: const TextStyle(color: _muted, fontSize: 14),
																filled: true,
																fillColor: _background,
																contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
																	borderSide: const BorderSide(color: _primary, width: 1.5),
																),
															),
														),
														const SizedBox(height: 16),
														// Ukuran & Tgl tebar
														Row(
															children: [
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Ukuran (m)',
																				style: TextStyle(
																					color: _textPrimary,
																					fontSize: 14,
																					fontWeight: FontWeight.w600,
																				),
																			),
																			const SizedBox(height: 8),
																			TextField(
																				keyboardType: TextInputType.number,
																				decoration: InputDecoration(
																					hintText: '200',
																					hintStyle: const TextStyle(color: _muted, fontSize: 14),
																					filled: true,
																					fillColor: _background,
																					contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
																						borderSide: const BorderSide(color: _primary, width: 1.5),
																					),
																				),
																			),
																		],
																	),
																),
																const SizedBox(width: 14),
																Expanded(
																	child: Column(
																		crossAxisAlignment: CrossAxisAlignment.start,
																		children: [
																			const Text(
																				'Tgl tebar',
																				style: TextStyle(
																					color: _textPrimary,
																					fontSize: 14,
																					fontWeight: FontWeight.w600,
																				),
																			),
																			const SizedBox(height: 8),
																			TextField(
																				readOnly: true,
																				decoration: InputDecoration(
																					hintText: 'Hari ini',
																					hintStyle: const TextStyle(color: _muted, fontSize: 14),
																					prefixIcon: const Icon(Icons.calendar_today, size: 18, color: _muted),
																					filled: true,
																					fillColor: _background,
																					contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
																						borderSide: const BorderSide(color: _primary, width: 1.5),
																					),
																				),
																				onTap: () async {
																					// TODO: date picker
																				},
																			),
																		],
																	),
																),
															],
														),
														const SizedBox(height: 16),
														// ID Perangkat IoT
														const Text(
															'ID Perangkat IoT',
															style: TextStyle(
																color: _textPrimary,
																fontSize: 14,
																fontWeight: FontWeight.w600,
															),
														),
														const SizedBox(height: 8),
														TextField(
															decoration: InputDecoration(
																hintText: 'Masukan ID anda',
																hintStyle: const TextStyle(color: _muted, fontSize: 14),
																filled: true,
																fillColor: _background,
																contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
																	borderSide: const BorderSide(color: _primary, width: 1.5),
																),
															),
														),
														const SizedBox(height: 4),
														const Text(
															'*Kosongkan jika belum ada perangkat',
															style: TextStyle(
																color: _muted,
																fontSize: 12,
															),
														),
														const SizedBox(height: 24),
														// Buttons
														Row(
															children: [
																Expanded(
																	child: OutlinedButton(
																		style: OutlinedButton.styleFrom(
																			padding: const EdgeInsets.symmetric(vertical: 16),
																			side: const BorderSide(color: _border),
																			shape: RoundedRectangleBorder(
																				borderRadius: BorderRadius.circular(14),
																			),
																		),
																		onPressed: () => Navigator.of(dialogContext).pop(),
																		child: const Text(
																			'Batal',
																			style: TextStyle(
																				color: _textPrimary,
																				fontSize: 16,
																				fontWeight: FontWeight.w600,
																			),
																		),
																	),
																),
																const SizedBox(width: 14),
																Expanded(
																	child: ElevatedButton.icon(
																		style: ElevatedButton.styleFrom(
																			elevation: 0,
																			padding: const EdgeInsets.symmetric(vertical: 16),
																			backgroundColor: _primary,
																			shape: RoundedRectangleBorder(
																				borderRadius: BorderRadius.circular(14),
																			),
																		),
																		onPressed: () {
																			// TODO: handle save
																			Navigator.of(dialogContext).pop();
																		},
																		icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
																		label: const Text(
																			'Simpan',
																			style: TextStyle(
																				color: Colors.white,
																				fontSize: 16,
																				fontWeight: FontWeight.w600,
																			),
																		),
																	),
																),
															],
														),
													],
												),
											),
										),
									),
								),
							),
						],
					),
				);
			},
			transitionBuilder: (context, animation, secondaryAnimation, child) {
				final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
				return FadeTransition(
					opacity: curved,
					child: ScaleTransition(
						scale: Tween<double>(begin: 0.98, end: 1).animate(curved),
						child: child,
					),
				);
			},
		);
	}

	Widget _buildAddButton(BuildContext context) {
		return SizedBox(
			width: double.infinity,
			child: ElevatedButton(
				style: ElevatedButton.styleFrom(
					elevation: 0,
					padding: const EdgeInsets.symmetric(vertical: 16),
					backgroundColor: _primary,
					shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
				),
				onPressed: () => _showAddPondDialog(context),
				child: const Text(
					'+ Tambah Kolam Baru',
					style: TextStyle(
						fontSize: 16,
						fontWeight: FontWeight.w600,
						color: Colors.white,
					),
				),
			),
		);
	}
}

class _PondData {
	const _PondData({
		required this.name,
		required this.dayCount,
		required this.size,
		required this.isActive,
	});

	final String name;
	final int dayCount;
	final String size;
	final bool isActive;
}
