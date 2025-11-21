// ignore_for_file: file_names

import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
	const AnalyticsScreen({super.key});

	static const Color _primary = Color(0xFF2563EB);
	static const Color _background = Color(0xFFF9FAFB);
	static const Color _surface = Color(0xFFFFFFFF);
	static const Color _muted = Color(0xFF9CA3AF);
	static const Color _textPrimary = Color(0xFF1F2937);
	static const Color _textSecondary = Color(0xFF6B7280);
	static const Color _softBlue = Color(0xFFEFF6FF);
	static const Color _accentBlue = Color(0xFF3B82F6);
	static const Color _accentGreen = Color(0xFF10B981);
	static const Color _accentOrange = Color(0xFFF59E0B);
	static const Color _accentRed = Color(0xFFEF4444);
	static const Color _cardOutline = Color(0xFFDBEAFE);
	static const Color _predictionCard = Color(0xFF00B050);

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
							const SizedBox(height: 24),
							_buildPredictionCard(),
							const SizedBox(height: 20),
							_buildOptimizationCard(),
							const SizedBox(height: 20),
							_buildQuickActions(),
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
					'Analytics & Prediksi',
					style: TextStyle(
						color: _textPrimary,
						fontSize: 26,
						fontWeight: FontWeight.w600,
					),
				),
				SizedBox(height: 4),
				Text(
					'Powered by Machine Learning',
					style: TextStyle(
						color: _muted,
						fontSize: 14,
					),
				),
			],
		);
	}

	Widget _buildPredictionCard() {
		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: _predictionCard,
				borderRadius: BorderRadius.circular(20),
			),
			child: const Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						children: [
							Icon(Icons.calendar_today, color: Colors.white),
							SizedBox(width: 8),
							Text(
								'Prediksi panen',
								style: TextStyle(color: Colors.white, fontSize: 16),
							),
						],
					),
					SizedBox(height: 16),
					Text(
						'13 April 2025',
						style: TextStyle(
							color: Colors.white,
							fontSize: 28,
							fontWeight: FontWeight.bold,
						),
					),
					SizedBox(height: 4),
					Text(
						'Akurasi prediksi : 95%',
						style: TextStyle(color: Colors.white70),
					),
				],
			),
		);
	}

	Widget _buildOptimizationCard() {
		final metrics = <_MetricData>[
			const _MetricData('Suhu Air', 0.92, _accentGreen),
			const _MetricData('Kualitas Air', 0.88, _accentBlue),
			const _MetricData('Pemberian Pakan', 0.85, _accentGreen),
			const _MetricData('Kepadatan Populasi', 0.90, _accentOrange),
		];

		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(20),
				boxShadow: [
					BoxShadow(
						color: _textPrimary.withOpacity(0.06),
						blurRadius: 12,
						offset: const Offset(0, 6),
					),
				],
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Text(
						'Skor Optimalisasi Kondisi',
						style: TextStyle(
							color: _textPrimary,
							fontSize: 18,
							fontWeight: FontWeight.w600,
						),
					),
					const SizedBox(height: 20),
					Row(
						children: [
							_buildOptimizationGauge(),
							const SizedBox(width: 24),
							Expanded(
								child: Column(
									children: metrics
											.map((metric) => _buildMetricRow(metric))
											.toList(),
								),
							),
						],
					),
				],
			),
		);
	}

	Widget _buildOptimizationGauge() {
		const double progress = 0.87;
		return const SizedBox(
			width: 140,
			height: 140,
			child: Stack(
				alignment: Alignment.center,
				children: [
					SizedBox(
						width: 140,
						height: 140,
						child: CircularProgressIndicator(
							value: progress,
							strokeWidth: 12,
							backgroundColor: _softBlue,
							valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
						),
					),
					Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							Text(
								'87%',
								style: TextStyle(
									fontSize: 32,
									fontWeight: FontWeight.bold,
									color: _textPrimary,
								),
							),
							SizedBox(height: 4),
							Text(
								'optimal',
								style: TextStyle(color: _textSecondary),
							),
						],
					),
				],
			),
		);
	}

	Widget _buildMetricRow(_MetricData metric) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 8),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Row(
						mainAxisAlignment: MainAxisAlignment.spaceBetween,
						children: [
							Text(
								metric.label,
								style: const TextStyle(
									color: _textSecondary,
									fontSize: 14,
								),
							),
							Text(
								'${(metric.value * 100).round()}%',
								style: const TextStyle(
									color: _textPrimary,
									fontWeight: FontWeight.w600,
								),
							),
						],
					),
					const SizedBox(height: 6),
					ClipRRect(
						borderRadius: BorderRadius.circular(6),
						child: LinearProgressIndicator(
							value: metric.value,
							backgroundColor: _softBlue,
							valueColor: AlwaysStoppedAnimation<Color>(metric.color),
							minHeight: 8,
						),
					),
				],
			),
		);
	}

	Widget _buildQuickActions() {
		final actions = <_ActionData>[
			const _ActionData(
				title: 'Tingkatkan Aerasi',
				description: 'DO cenderung menurun sore hari. Tambah aerasi jam 15:00-18:00',
				dotColor: _accentOrange,
			),
			const _ActionData(
				title: 'Monitoring Ammonia',
				description: 'Level ammonia meningkat 0.03 mg/L. Pertimbangkan partial water change',
				dotColor: _accentBlue,
			),
			const _ActionData(
				title: 'Optimasi Pakan',
				description: 'Berdasarkan growth rate, kurangi pakan 5% untuk efisiensi FCR',
				dotColor: _accentGreen,
			),
			const _ActionData(
				title: 'Kurangi Populasi',
				description: 'Populasi padat, kurangi populasi untuk mencegah ikan stres',
				dotColor: _accentRed,
			),
		];

		return Container(
			width: double.infinity,
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				color: _softBlue,
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: _cardOutline),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Row(
						children: [
							Icon(Icons.show_chart, color: _primary),
							SizedBox(width: 8),
							Text(
								'Aksi Cepat',
								style: TextStyle(
									color: _textPrimary,
									fontSize: 18,
									fontWeight: FontWeight.w600,
								),
							),
						],
					),
					const SizedBox(height: 16),
					Column(
						children: actions
								.map((action) => _buildQuickActionCard(action))
								.toList(),
					),
				],
			),
		);
	}

	Widget _buildQuickActionCard(_ActionData action) {
		return Container(
			margin: const EdgeInsets.only(bottom: 12),
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: _surface,
				borderRadius: BorderRadius.circular(16),
				border: Border.all(color: _cardOutline.withOpacity(0.5)),
			),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					Container(
						width: 10,
						height: 10,
						margin: const EdgeInsets.only(top: 6),
						decoration: BoxDecoration(
							color: action.dotColor,
							shape: BoxShape.circle,
						),
					),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									action.title,
									style: const TextStyle(
										color: _textPrimary,
										fontSize: 16,
										fontWeight: FontWeight.w600,
									),
								),
								const SizedBox(height: 6),
								Text(
									action.description,
									style: const TextStyle(
										color: _textSecondary,
										fontSize: 14,
									),
								),
							],
						),
					),
				],
			),
		);
	}
}

class _MetricData {
	const _MetricData(this.label, this.value, this.color);

	final String label;
	final double value;
	final Color color;
}

class _ActionData {
	const _ActionData({
		required this.title,
		required this.description,
		required this.dotColor,
	});

	final String title;
	final String description;
	final Color dotColor;
}
