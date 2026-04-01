import 'dart:async';

import 'package:flutter/material.dart';

Future<bool?> showPopupKalibrasi(
	BuildContext context, {
	required String sensorType,
	required String pembacaan,
	required String akurasi,
}) {
	return showDialog<bool>(
		context: context,
		barrierDismissible: false,
		builder: (_) => _PopupKalibrasiDialog(
			sensorType: sensorType,
			pembacaan: pembacaan,
			akurasi: akurasi,
		),
	);
}

class _PopupKalibrasiDialog extends StatefulWidget {
	const _PopupKalibrasiDialog({
		required this.sensorType,
		required this.pembacaan,
		required this.akurasi,
	});

	final String sensorType;
	final String pembacaan;
	final String akurasi;

	@override
	State<_PopupKalibrasiDialog> createState() => _PopupKalibrasiDialogState();
}

class _PopupKalibrasiDialogState extends State<_PopupKalibrasiDialog> {
	static const Color _textPrimary = Color(0xFF1F2937);
	static const Color _textSecondary = Color(0xFF6B7280);
	static const Color _primary = Color(0xFF3F7EE8);
	static const Color _border = Color(0xFFE5E7EB);
	static const Color _stepInactive = Color(0xFFD1D5DB);
	static const Color _infoBackground = Color(0xFFE5F1F8);
	static const Color _infoBorder = Color(0xFFB6D6FA);
	static const Color _readBackground = Color(0xFFF3F4F6);

	int _step = 1;
	bool _isProcessing = false;
	Timer? _timer;

	@override
	void dispose() {
		_timer?.cancel();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final data = _stepData(_step);
		final progressStep = _isProcessing ? 1 : _step;

		return Dialog(
			backgroundColor: Colors.white,
			insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
			child: ConstrainedBox(
				constraints: const BoxConstraints(maxWidth: 360),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					crossAxisAlignment: CrossAxisAlignment.start,
					children: [
						Padding(
							padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									Expanded(
										child: Column(
											crossAxisAlignment: CrossAxisAlignment.start,
											children: [
												const Text(
													'Kalibrasi Sensor',
													style: TextStyle(
														color: _textPrimary,
														fontSize: 31 / 2,
														fontWeight: FontWeight.w700,
													),
												),
												Text(
													widget.sensorType,
													style: const TextStyle(
														color: _textSecondary,
														fontSize: 14,
													),
												),
											],
										),
									),
									IconButton(
										onPressed: () => Navigator.of(context).pop(false),
										icon: const Icon(Icons.close, color: _textSecondary),
									),
								],
							),
						),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 14),
							child: Row(
								children: List.generate(3, (index) {
									return Expanded(
										child: Container(
											margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
											height: 6,
											decoration: BoxDecoration(
												color: index < progressStep ? _primary : _stepInactive,
												borderRadius: BorderRadius.circular(100),
											),
										),
									);
								}),
							),
						),
						const SizedBox(height: 4),
						Padding(
							padding: const EdgeInsets.symmetric(horizontal: 14),
							child: Text(
								'Langkah $progressStep/3',
								style: const TextStyle(
									color: _textSecondary,
									fontSize: 14,
								),
							),
						),
						const SizedBox(height: 10),
						const Divider(height: 1, color: _border),
						if (_isProcessing)
							_buildProcessing()
						else
							_buildStepContent(data),
					],
				),
			),
		);
	}

	Widget _buildStepContent(_StepData data) {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				Padding(
					padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
					child: Text(
						data.title,
						style: const TextStyle(
							color: _textPrimary,
							fontSize: 18,
							fontWeight: FontWeight.w700,
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
					child: Text(
						data.subtitle,
						style: const TextStyle(
							color: _textSecondary,
							fontSize: 14,
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
					child: Container(
						width: double.infinity,
						padding: const EdgeInsets.all(12),
						decoration: BoxDecoration(
							color: _infoBackground,
							borderRadius: BorderRadius.circular(10),
							border: Border.all(color: _infoBorder),
						),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Row(
									children: [
										Icon(Icons.info_outline, size: 16, color: _primary),
										SizedBox(width: 4),
										Text(
											'Langkah-langkah:',
											style: TextStyle(
												color: _textPrimary,
												fontSize: 15,
												fontWeight: FontWeight.w700,
											),
										),
									],
								),
								const SizedBox(height: 6),
								...data.steps.map(
									(item) => Padding(
										padding: const EdgeInsets.only(bottom: 2),
										child: Text(
											'• $item',
											style: const TextStyle(
												color: _textPrimary,
												fontSize: 14,
												height: 1.35,
											),
										),
									),
								),
							],
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
					child: Container(
						width: double.infinity,
						padding: const EdgeInsets.all(12),
						decoration: BoxDecoration(
							color: _readBackground,
							borderRadius: BorderRadius.circular(10),
							border: Border.all(color: const Color(0xFFD1D5DB)),
						),
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Pembacaan Saat Ini',
									style: TextStyle(color: _textSecondary, fontSize: 13),
								),
								const SizedBox(height: 2),
								Text(
									widget.pembacaan,
									style: const TextStyle(
										color: _textPrimary,
										fontSize: 34 / 2,
										fontWeight: FontWeight.w700,
									),
								),
								Text(
									'Akurasi : ${widget.akurasi}',
									style: const TextStyle(color: _textSecondary, fontSize: 13),
								),
							],
						),
					),
				),
				Padding(
					padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
					child: Row(
						children: [
							if (_step > 1) ...[
								Expanded(
									child: SizedBox(
										height: 44,
										child: ElevatedButton(
											onPressed: () => setState(() => _step -= 1),
											style: ElevatedButton.styleFrom(
												backgroundColor: const Color(0xFFE5E7EB),
												foregroundColor: _textPrimary,
												elevation: 0,
												shape: RoundedRectangleBorder(
													borderRadius: BorderRadius.circular(10),
												),
											),
											child: const Text(
												'Kembali',
												style: TextStyle(
													fontSize: 30 / 2,
													fontWeight: FontWeight.w700,
												),
											),
										),
									),
								),
								const SizedBox(width: 6),
							],
							Expanded(
								child: SizedBox(
									height: 44,
									child: ElevatedButton(
										onPressed: _next,
										style: ElevatedButton.styleFrom(
											backgroundColor: _primary,
											foregroundColor: Colors.white,
											elevation: 0,
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(10),
											),
										),
										child: const Text(
											'Lanjut',
											style: TextStyle(
												fontSize: 30 / 2,
												fontWeight: FontWeight.w700,
											),
										),
									),
								),
							),
						],
					),
				),
			],
		);
	}

	Widget _buildProcessing() {
		return const Padding(
			padding: EdgeInsets.fromLTRB(14, 52, 14, 52),
			child: Column(
				children: [
					Center(
						child: Text(
							'Sedang Mengkalibrasi......',
							style: TextStyle(
								color: _textPrimary,
								fontSize: 22,
								fontWeight: FontWeight.w700,
							),
						),
					),
					SizedBox(height: 14),
					Center(
						child: Text(
							'Harap tunggu, Proses kalibrasi sedang berlangsung',
							style: TextStyle(
								color: _textSecondary,
								fontSize: 14,
							),
						),
					),
				],
			),
		);
	}

	_StepData _stepData(int step) {
		if (step == 1) {
			return const _StepData(
				title: 'Persiapan',
				subtitle: 'Pastikan sensor bersih dan siap untuk dikalibrasi',
				steps: [
					'Bersihkan probe sensor dengan air bersih',
					'Keringkan dengan kain lembut',
					'Siapkan larutan kalibrasi standar',
					'Pastikan suhu ruangan stabil (20-25 C)',
				],
			);
		}

		if (step == 2) {
			return const _StepData(
				title: 'Kalibrasi Point 1',
				subtitle: 'Masukkan sensor ke larutan kalibrasi pertama',
				steps: [
					'Celupkan sensor ke larutan standar',
					'Tunggu hingga pembacaan stabil (±30 detik)',
					'Pastikan tidak ada gelembung udara',
					'Catat nilai yang ditampilkan',
				],
			);
		}

		return const _StepData(
			title: 'Kalibrasi Point 2',
			subtitle: 'Masukkan sensor ke larutan kalibrasi kedua',
			steps: [
				'Bilas sensor dengan air bersih',
				'Celupkan ke larutan standar kedua',
				'Tunggu pembacaan stabil',
				'Verifikasi akurasi pembacaan',
			],
		);
	}

	void _next() {
		if (_step < 3) {
			setState(() => _step += 1);
			return;
		}

		setState(() {
			_isProcessing = true;
			_step = 1;
		});

		_timer = Timer(const Duration(seconds: 2), () {
			if (!mounted) return;
			Navigator.of(context).pop(true);
		});
	}
}

class _StepData {
	const _StepData({
		required this.title,
		required this.subtitle,
		required this.steps,
	});

	final String title;
	final String subtitle;
	final List<String> steps;
}
