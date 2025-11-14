// ignore_for_file: file_names
import 'package:flutter/material.dart';

class ControlScreen extends StatefulWidget {
	const ControlScreen({super.key});

	@override
	State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
	static const Color _background = Color(0xFFF9FAFB);
	static const Color _surface = Color(0xFFFFFFFF);
	static const Color _primary = Color(0xFF2563EB);
	static const Color _secondaryBlue = Color(0xFF3B82F6);
	static const Color _textPrimary = Color(0xFF1F2937);
	static const Color _textSecondary = Color(0xFF6B7280);
	static const Color _borderColor = Color(0xFFE5E7EB);
	static const Color _warning = Color(0xFFEA580C);

	bool _isAutoMode = true;
	late final List<bool> _scheduleEnabled;
	final TextEditingController _stockController = TextEditingController();

	final List<_SchedulePlan> _schedules = const [
		_SchedulePlan(time: '07:00', amount: '3.0 Kg'),
		_SchedulePlan(time: '13:00', amount: '3.0 Kg'),
		_SchedulePlan(time: '19:00', amount: '3.0 Kg'),
	];

	final List<_ConsumptionPoint> _consumption = const [
		_ConsumptionPoint(day: 'Sen', amount: 10),
		_ConsumptionPoint(day: 'Sel', amount: 8.3),
		_ConsumptionPoint(day: 'Rab', amount: 5.2),
		_ConsumptionPoint(day: 'Kam', amount: 9.5),
		_ConsumptionPoint(day: 'Jum', amount: 10),
		_ConsumptionPoint(day: 'Sab', amount: 10),
		_ConsumptionPoint(day: 'Mgg', amount: 7.3),
	];

	@override
	void initState() {
		super.initState();
		_scheduleEnabled = List<bool>.filled(_schedules.length, true);
	}

	@override
	void dispose() {
		_stockController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Material(
			color: _background,
			child: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							_buildHeader(),
							const SizedBox(height: 20),
							_buildModeCard(),
							const SizedBox(height: 16),
							_buildScheduleCard(),
							const SizedBox(height: 16),
							_buildStockCard(),
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
					style: TextStyle(color: _primary, fontSize: 28, fontWeight: FontWeight.w700),
				),
				SizedBox(height: 6),
				Text(
					'Kontrol Sistem',
					style: TextStyle(color: _textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
				),
				SizedBox(height: 4),
				Text(
					'Alat pemberian pakan otomatis/manual',
					style: TextStyle(color: _textSecondary, fontSize: 14),
				),
			],
		);
	}

	Widget _buildModeCard() {
		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(28),
				border: Border.all(color: _borderColor),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.03),
						blurRadius: 18,
						offset: const Offset(0, 8),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							const Expanded(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'Mode Pemberian Pakan',
											style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
										),
										SizedBox(height: 4),
										Text(
											'Pilih mode otomatis atau manual',
											style: TextStyle(color: _textSecondary, fontSize: 13),
										),
									],
								),
							),
							Container(
								width: 42,
								height: 42,
								decoration: BoxDecoration(
									color: const Color(0xFFE8F5FF),
									borderRadius: BorderRadius.circular(12),
								),
								child: const Icon(Icons.power_settings_new, color: _primary),
							),
						],
					),
					const SizedBox(height: 20),
					Row(
						children: [
							Expanded(child: _buildModeButton(title: 'Otomatis', isAuto: true)),
							const SizedBox(width: 12),
							Expanded(child: _buildModeButton(title: 'Manual', isAuto: false)),
						],
					),
				],
			),
		);
	}

	Widget _buildModeButton({required String title, required bool isAuto}) {
		final bool isActive = _isAutoMode == isAuto;
		return GestureDetector(
			onTap: () => setState(() => _isAutoMode = isAuto),
			child: AnimatedContainer(
				duration: const Duration(milliseconds: 200),
				padding: const EdgeInsets.symmetric(vertical: 14),
				decoration: BoxDecoration(
					color: isActive ? _primary : const Color(0xFFF1F5F9),
					borderRadius: BorderRadius.circular(20),
					border: Border.all(color: isActive ? _primary : _borderColor),
				),
				alignment: Alignment.center,
				child: Text(
					title,
					style: TextStyle(
						color: isActive ? Colors.white : _textSecondary,
						fontWeight: FontWeight.w600,
					),
				),
			),
		);
	}

	Widget _buildScheduleCard() {
		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(28),
				border: Border.all(color: _borderColor),
				boxShadow: [
					BoxShadow(
						color: Colors.black.withOpacity(0.03),
						blurRadius: 18,
						offset: const Offset(0, 8),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text(
						'Jadwal Pemberian Pakan',
						style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
					),
					const SizedBox(height: 4),
					const Text(
						'Atur jadwal pakan otomatis harian',
						style: TextStyle(color: _textSecondary, fontSize: 13),
					),
					const SizedBox(height: 18),
					...List.generate(_schedules.length, (index) {
						final schedule = _schedules[index];
						return Padding(
							padding: EdgeInsets.only(bottom: index == _schedules.length - 1 ? 16 : 12),
							child: _buildScheduleTile(schedule, index),
						);
					}),
					_buildAddScheduleButton(),
				],
			),
		);
	}

	Widget _buildScheduleTile(_SchedulePlan schedule, int index) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: _borderColor),
			),
			child: Row(
				children: [
					Container(
						padding: const EdgeInsets.all(10),
						decoration: BoxDecoration(
							color: const Color(0xFFEFF6FF),
							borderRadius: BorderRadius.circular(14),
						),
						child: const Icon(Icons.schedule, color: _primary),
					),
					const SizedBox(width: 14),
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								schedule.time,
								style: const TextStyle(color: _textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
							),
							const SizedBox(height: 2),
							Text(
								schedule.amount,
								style: const TextStyle(color: _textSecondary, fontSize: 13),
							),
						],
					),
					const Spacer(),
					Switch(
						value: _scheduleEnabled[index],
						onChanged: (value) => setState(() => _scheduleEnabled[index] = value),
						activeColor: Colors.white,
						activeTrackColor: _primary,
						inactiveThumbColor: Colors.white,
						inactiveTrackColor: _borderColor,
					),
				],
			),
		);
	}

	Widget _buildAddScheduleButton() {
		return GestureDetector(
			onTap: () {},
			child: Container(
				width: double.infinity,
				padding: const EdgeInsets.symmetric(vertical: 14),
				decoration: BoxDecoration(
					color: const Color(0xFFEFF4FF),
					borderRadius: BorderRadius.circular(18),
				),
				alignment: Alignment.center,
				child: const Text(
					'+ Tambah Jadwal',
					style: TextStyle(color: _primary, fontWeight: FontWeight.w600),
				),
			),
		);
	}

	Widget _buildStockCard() {
		return Container(
			padding: const EdgeInsets.all(22),
			decoration: BoxDecoration(
				gradient: const LinearGradient(
					colors: [Color(0xFFFFF7ED), Color(0xFFFEE3C8)],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				borderRadius: BorderRadius.circular(30),
				boxShadow: [
					BoxShadow(
						color: Colors.orange.withOpacity(0.15),
						blurRadius: 24,
						offset: const Offset(0, 12),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Container(
								padding: const EdgeInsets.all(10),
								decoration: BoxDecoration(
									color: Colors.white,
									borderRadius: BorderRadius.circular(14),
								),
								child: const Icon(Icons.eco, color: _warning),
							),
							const SizedBox(width: 12),
							const Text(
								'Stok Pakan',
								style: TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
							),
						],
					),
					const SizedBox(height: 18),
					const Row(
						crossAxisAlignment: CrossAxisAlignment.end,
						children: [
							Text(
								'45.5',
								style: TextStyle(color: _textPrimary, fontSize: 44, fontWeight: FontWeight.bold),
							),
							SizedBox(width: 6),
							Padding(
								padding: EdgeInsets.only(bottom: 6),
								child: Text('Kg Tersisa', style: TextStyle(color: _textSecondary, fontSize: 14)),
							),
						],
					),
					const SizedBox(height: 8),
					const Text(
						'perkiraan habis dalam 5 hari',
						style: TextStyle(color: _warning, fontWeight: FontWeight.w600),
					),
					const SizedBox(height: 12),
					ClipRRect(
						borderRadius: BorderRadius.circular(10),
						child: LinearProgressIndicator(
							value: 0.65,
							minHeight: 10,
							backgroundColor: Colors.white.withOpacity(0.4),
							valueColor: const AlwaysStoppedAnimation<Color>(_warning),
						),
					),
					const SizedBox(height: 20),
					_buildConsumptionChart(),
					const SizedBox(height: 18),
					_buildUpdateStockForm(),
				],
			),
		);
	}

	Widget _buildConsumptionChart() {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: Colors.white.withOpacity(0.6)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Row(
						children: [
							Icon(Icons.bar_chart, color: _primary, size: 18),
							SizedBox(width: 6),
							Text(
								'Konsumsi 7 Hari Terakhir',
								style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w600),
							),
						],
					),
					const SizedBox(height: 14),
					SingleChildScrollView(
						scrollDirection: Axis.horizontal,
						child: Row(
							children: _consumption
								.map((point) => Padding(
									padding: const EdgeInsets.only(right: 8),
									child: _buildConsumptionChip(point),
								))
								.toList(),
						),
					),
				],
			),
		);
	}

	Widget _buildConsumptionChip(_ConsumptionPoint point) {
		return Container(
			width: 44,
			padding: const EdgeInsets.symmetric(vertical: 8),
			decoration: BoxDecoration(
				color: _secondaryBlue,
				borderRadius: BorderRadius.circular(14),
			),
			child: Column(
				children: [
					Text(
						point.amount.toStringAsFixed(point.amount % 1 == 0 ? 0 : 1),
						style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
					),
					const SizedBox(height: 4),
					Text(
						point.day,
						style: const TextStyle(color: Colors.white, fontSize: 11),
					),
				],
			),
		);
	}

	Widget _buildUpdateStockForm() {
		Widget buildTextField() {
			return TextField(
				controller: _stockController,
				keyboardType: const TextInputType.numberWithOptions(decimal: true),
				decoration: InputDecoration(
					hintText: 'Jumlah (Kg)',
					filled: true,
					fillColor: Colors.white,
					contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
					border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(16),
						borderSide: BorderSide.none,
					),
				),
			);
		}

		Widget buildActionButton() {
			return SizedBox(
				height: 52,
				child: ElevatedButton(
					onPressed: () => _stockController.clear(),
					style: ElevatedButton.styleFrom(
						backgroundColor: _secondaryBlue,
						padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
					),
					child: const Text('Update Stok'),
				),
			);
		}

		return LayoutBuilder(
			builder: (context, constraints) {
				if (constraints.maxWidth < 360) {
					return Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: [
							buildTextField(),
							const SizedBox(height: 12),
							buildActionButton(),
						],
					);
				}

				return Row(
					children: [
						Expanded(child: buildTextField()),
						const SizedBox(width: 12),
						buildActionButton(),
					],
				);
			},
		);
	}
}

class _SchedulePlan {
	final String time;
	final String amount;
	const _SchedulePlan({required this.time, required this.amount});
}

class _ConsumptionPoint {
	final String day;
	final double amount;
	const _ConsumptionPoint({required this.day, required this.amount});
}
