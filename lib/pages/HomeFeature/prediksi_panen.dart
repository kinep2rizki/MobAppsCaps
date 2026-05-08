import 'package:flutter/material.dart';

class HarvestEstimateCard extends StatelessWidget {
	const HarvestEstimateCard({
		super.key,
		required this.estimateData,
		this.isLoading = false,
		this.hasError = false,
		this.onRetry,
		this.onGenerate,
	});

	final Map<String, dynamic>? estimateData;
	final bool isLoading;
	final bool hasError;
	final VoidCallback? onRetry;
	final VoidCallback? onGenerate;

	String _formatLongDate(DateTime? date) {
		if (date == null) return '-';

		const monthNames = [
			'Jan',
			'Feb',
			'Mar',
			'Apr',
			'Mei',
			'Jun',
			'Jul',
			'Agu',
			'Sep',
			'Okt',
			'Nov',
			'Des',
		];

		final local = date.toLocal();
		final day = local.day.toString().padLeft(2, '0');
		final month = monthNames[local.month - 1];
		return '$day $month ${local.year}';
	}

	String _formatHarvestCountdown(DateTime? date) {
		if (date == null) return '-';

		final today = DateTime.now();
		final target = DateTime(date.year, date.month, date.day);
		final current = DateTime(today.year, today.month, today.day);
		final daysLeft = target.difference(current).inDays;

		if (daysLeft <= 0) {
			return 'Hari ini / lewat';
		}

		return '$daysLeft hari lagi';
	}

	DateTime? _parseDate(dynamic value) {
		if (value == null) return null;
		return DateTime.tryParse(value.toString());
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

	@override
	Widget build(BuildContext context) {
		final harvestDate = _parseDate(
			estimateData == null ? null : estimateData!['predicted_harvest_date'],
		);
		final predictionDate = _parseDate(
			estimateData == null ? null : estimateData!['prediction_date'],
		);
		final confidence = estimateData == null
				? null
				: _toDouble(estimateData!['confidence_score']);
		final modelId = estimateData == null
				? null
				: estimateData!['ml_model_id']?.toString();
		final farmingCycleId = estimateData == null
				? null
				: estimateData!['farming_cycle_id']?.toString();

		final showLoading = isLoading && estimateData == null;
		final showError = hasError && estimateData == null;

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: const Color(0xFF0F766E),
				borderRadius: BorderRadius.circular(20),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Row(
						children: [
							Icon(Icons.event_available_outlined, color: Colors.white),
							SizedBox(width: 8),
							Text(
								'Estimasi Panen',
								style: TextStyle(
									color: Colors.white,
									fontSize: 18,
									fontWeight: FontWeight.bold,
								),
							),
						],
					),
					const SizedBox(height: 16),
					if (showLoading)
						const SizedBox(
							width: 22,
							height: 22,
							child: CircularProgressIndicator(
								strokeWidth: 2.4,
								color: Colors.white,
							),
						)
					else if (showError)
						Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Data prediksi panen belum tersedia.',
									style: TextStyle(color: Colors.white70),
								),
								if (onRetry != null) ...[
									const SizedBox(height: 10),
									TextButton(
										onPressed: onRetry,
										style: TextButton.styleFrom(
											foregroundColor: Colors.white,
											backgroundColor: Colors.white.withOpacity(0.12),
										),
										child: const Text('Coba Lagi'),
									),
								],
							],
						)
					else ...[
						Text(
							_formatLongDate(harvestDate),
							style: const TextStyle(
								color: Colors.white,
								fontSize: 28,
								fontWeight: FontWeight.bold,
							),
						),
						const SizedBox(height: 4),
						Text(
							_formatHarvestCountdown(harvestDate),
							style: const TextStyle(color: Colors.white70),
						),
						const SizedBox(height: 12),
						Text(
							'Confidence: ${(confidence == null ? 0 : (confidence <= 1 ? confidence * 100 : confidence)).round()}%',
							style: const TextStyle(color: Colors.white70),
						),
						Text(
							'Predicted at: ${_formatLongDate(predictionDate)}',
							style: const TextStyle(color: Colors.white70),
						),
						if (modelId != null) ...[
							Text(
								'Model: $modelId',
								style: const TextStyle(color: Colors.white70),
							),
						],
						if (farmingCycleId != null) ...[
							Text(
								'Farming cycle: $farmingCycleId',
								style: const TextStyle(color: Colors.white70),
							),
						],
						if (onGenerate != null) ...[
							const SizedBox(height: 12),
							SizedBox(
								width: double.infinity,
								child: OutlinedButton.icon(
									onPressed: onGenerate,
									style: OutlinedButton.styleFrom(
										foregroundColor: Colors.white,
										side: const BorderSide(color: Colors.white70),
									),
									icon: const Icon(Icons.auto_graph_outlined),
									label: const Text('Generate Prediksi Panen'),
								),
							),
						],
					],
				],
			),
		);
	}
}