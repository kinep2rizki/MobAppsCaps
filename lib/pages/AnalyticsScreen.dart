import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({
    super.key,
    this.predictionData,
    this.isLoading = false,
    this.hasError = false,
    this.onRetry,
  });

  final Map<String, dynamic>? predictionData;
  final bool isLoading;
  final bool hasError;
  final VoidCallback? onRetry;

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
    final showLoading = isLoading && predictionData == null;
    final showError = hasError && predictionData == null;

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
              _buildPredictionCard(
                predictionData,
                isLoading: showLoading,
              ),
              const SizedBox(height: 20),
              if (showError)
                _buildDataErrorCard()
              else ...[
                _buildOptimizationCard(
                  predictionData,
                  isLoading: showLoading,
                ),
                const SizedBox(height: 20),
                _buildQuickActions(
                  predictionData,
                  isLoading: showLoading,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _extractStringValue(
    Map<String, dynamic>? data,
    List<String> keys, {
    String fallback = '-',
  }) {
    if (data == null || data.isEmpty) return fallback;

    final normalizedKeys = keys.map((e) => e.toLowerCase()).toSet();

    for (final entry in data.entries) {
      if (!normalizedKeys.contains(entry.key.toLowerCase())) continue;

      final value = entry.value;
      if (value == null) return fallback;

      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return fallback;

      return text;
    }

    return fallback;
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

  String _normalizeMetricKey(String key) {
    return key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  double? _extractNumericValue(Map<String, dynamic> data, List<String> keys) {
    final normalizedKeys = keys.map(_normalizeMetricKey).toSet();

    for (final entry in data.entries) {
      final entryKey = _normalizeMetricKey(entry.key);

      if (normalizedKeys.contains(entryKey)) {
        final directValue = _toDouble(entry.value);
        if (directValue != null) return directValue;

        if (entry.value is Map) {
          final mapValue = entry.value as Map;
          final nestedValue =
              mapValue['value'] ?? mapValue['nilai'] ?? mapValue['val'];
          final parsedNested = _toDouble(nestedValue);
          if (parsedNested != null) return parsedNested;
        }
      }
    }

    return null;
  }

  String _humanizeText(String text) {
    final normalized = text.trim().replaceAll('_', ' ');
    if (normalized.isEmpty) return '-';

    final parts = normalized.split(RegExp(r'\s+'));
    return parts.map((part) {
      if (part.isEmpty) return part;
      if (part.length == 1) return part.toUpperCase();
      return '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}';
    }).join(' ');
  }

  double _normalizeProbability(double raw) {
    if (raw <= 1) {
      return raw.clamp(0.0, 1.0);
    }

    return (raw / 100).clamp(0.0, 1.0);
  }

  double _extractProbability(Map<String, dynamic>? data, List<String> keys) {
    if (data == null || data.isEmpty) {
      return 0;
    }

    final rawValue = _extractNumericValue(data, keys);
    if (rawValue == null) {
      return 0;
    }

    return _normalizeProbability(rawValue);
  }

  double _optimizationScore(Map<String, dynamic>? predictionData) {
    if (predictionData == null || predictionData.isEmpty) {
      return 0;
    }

    final confidence = _extractProbability(predictionData, [
      'confidence',
      'score',
      'optimization_score',
    ]);

    final probNormal = _extractProbability(predictionData, [
      'prob_normal',
      'probnormal',
    ]);

    return confidence > 0 ? confidence : probNormal;
  }

  Color _scoreColor(double score) {
    if (score >= 0.8) {
      return _accentGreen;
    }

    if (score >= 0.6) {
      return _accentOrange;
    }

    if (score <= 0) {
      return _muted;
    }

    return _accentRed;
  }

  String _scoreLabel(double score) {
    if (score >= 0.8) {
      return 'Optimal';
    }

    if (score >= 0.6) {
      return 'Cukup';
    }

    if (score <= 0) {
      return 'No data';
    }

    return 'Perlu atensi';
  }

  String _formatTimestamp(dynamic rawValue) {
    if (rawValue == null) {
      return '-';
    }

    final parsed = DateTime.tryParse(rawValue.toString());
    if (parsed == null) {
      return rawValue.toString();
    }

    final local = parsed.toLocal();
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

    final day = local.day.toString().padLeft(2, '0');
    final month = monthNames[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month $year $hour:$minute';
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

  Widget _buildPredictionCard(
    Map<String, dynamic>? predictionData, {
    required bool isLoading,
  }) {
    final confidence = _optimizationScore(predictionData);
    final confidencePercent = (confidence * 100).round();
    final status = _humanizeText(
      _extractStringValue(
        predictionData,
        ['status', 'urgency'],
        fallback: 'No data',
      ),
    );
    final createdAt = _formatTimestamp(
      predictionData == null ? null : predictionData['created_at'],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _predictionCard,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Prediksi kondisi terbaru',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && predictionData == null)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Colors.white,
              ),
            )
          else
            Text(
              '$confidencePercent%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 4),
          Text(
            'Akurasi prediksi: $confidencePercent%',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: $status',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          Text(
            'Update: $createdAt',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  List<_MetricData> _buildProbabilityMetrics(
    Map<String, dynamic>? predictionData,
    bool isLoading,
  ) {
    if (predictionData == null || predictionData.isEmpty) {
      return [
        _MetricData(
          label: 'Prob Normal',
          reading: isLoading ? 'Loading...' : '-',
          status: isLoading ? 'Loading' : 'No Data',
          progress: 0,
          color: _muted,
        ),
        _MetricData(
          label: 'Prob Waspada',
          reading: isLoading ? 'Loading...' : '-',
          status: isLoading ? 'Loading' : 'No Data',
          progress: 0,
          color: _muted,
        ),
        _MetricData(
          label: 'Prob Kritis',
          reading: isLoading ? 'Loading...' : '-',
          status: isLoading ? 'Loading' : 'No Data',
          progress: 0,
          color: _muted,
        ),
      ];
    }

    final probNormal = _extractProbability(predictionData, [
      'prob_normal',
      'probnormal',
    ]);

    final probWaspada = _extractProbability(predictionData, [
      'prob_waspada',
      'probwaspada',
    ]);

    final probKritis = _extractProbability(predictionData, [
      'prob_kritis',
      'probkritis',
    ]);

    return [
      _MetricData(
        label: 'Prob Normal',
        reading: '${(probNormal * 100).round()}%',
        status: probNormal >= 0.6 ? 'Dominan' : 'Rendah',
        progress: probNormal,
        color: _accentGreen,
      ),
      _MetricData(
        label: 'Prob Waspada',
        reading: '${(probWaspada * 100).round()}%',
        status: probWaspada >= 0.4 ? 'Perhatian' : 'Terkendali',
        progress: probWaspada,
        color: _accentOrange,
      ),
      _MetricData(
        label: 'Prob Kritis',
        reading: '${(probKritis * 100).round()}%',
        status: probKritis >= 0.3 ? 'Risiko Tinggi' : 'Risiko Rendah',
        progress: probKritis,
        color: _accentRed,
      ),
    ];
  }

  Widget _buildOptimizationCard(
    Map<String, dynamic>? predictionData, {
    required bool isLoading,
  }) {
    final score = _optimizationScore(predictionData);
    final metrics = _buildProbabilityMetrics(predictionData, isLoading);
    final scoreColor = _scoreColor(score);
    final scoreLabel = _scoreLabel(score);

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
              _buildOptimizationGauge(
                score,
                label: scoreLabel,
                color: scoreColor,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children:
                      metrics.map((metric) => _buildMetricRow(metric)).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationGauge(
    double progress, {
    required String label,
    required Color color,
  }) {
    final percentageText = '${(progress * 100).round()}%';

    return SizedBox(
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
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                percentageText,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(color: _textSecondary),
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
                metric.reading,
                style: TextStyle(
                  color: _textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: metric.reading == 'Loading...' ? 13 : 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: metric.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                metric.status,
                style: TextStyle(
                  color: metric.color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: metric.progress,
              backgroundColor: _softBlue,
              valueColor: AlwaysStoppedAnimation<Color>(metric.color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  List<_ActionData> _buildQuickActionsData(
      Map<String, dynamic>? predictionData) {
    final actions = <_ActionData>[];

    final status = _extractStringValue(
      predictionData,
      ['status'],
      fallback: '',
    ).toLowerCase();

    final urgency = _extractStringValue(
      predictionData,
      ['urgency'],
      fallback: '',
    ).toLowerCase();

    final probWaspada = _extractProbability(predictionData, [
      'prob_waspada',
      'probwaspada',
    ]);

    final probKritis = _extractProbability(predictionData, [
      'prob_kritis',
      'probkritis',
    ]);

    final modelVersion = _extractStringValue(
      predictionData,
      ['model_version'],
      fallback: '-',
    );

    if (probKritis >= 0.3 || status.contains('kritis')) {
      actions.add(
        const _ActionData(
          title: 'Prioritaskan Penanganan',
          description:
              'Probabilitas kritis cukup tinggi. Tingkatkan frekuensi monitoring sekarang.',
          dotColor: _accentRed,
        ),
      );
    }

    if (probWaspada >= 0.4 || status.contains('waspada')) {
      actions.add(
        const _ActionData(
          title: 'Mode Waspada',
          description:
              'Model menunjukkan potensi risiko. Lakukan inspeksi kondisi kolam lebih rutin.',
          dotColor: _accentOrange,
        ),
      );
    }

    if (urgency.contains('high') || urgency.contains('tinggi')) {
      actions.add(
        const _ActionData(
          title: 'Urgency Tinggi',
          description:
              'Sistem menandai urgency tinggi. Utamakan penanganan operasional di lapangan.',
          dotColor: _accentRed,
        ),
      );
    }

    actions.add(
      _ActionData(
        title: 'Model Aktif',
        description: 'Versi model saat ini: $modelVersion',
        dotColor: _accentBlue,
      ),
    );

    if (actions.isEmpty) {
      actions.add(
        const _ActionData(
          title: 'Kondisi Stabil',
          description: 'Prediksi saat ini menunjukkan kondisi relatif aman.',
          dotColor: _accentGreen,
        ),
      );
    }

    return actions.take(4).toList();
  }

  Widget _buildQuickActions(
    Map<String, dynamic>? predictionData, {
    required bool isLoading,
  }) {
    final actions = _buildQuickActionsData(predictionData);

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
                'Saran Tindakan Cepat',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (isLoading && predictionData == null)
            const SizedBox(
              height: 28,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              ),
            )
          else
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

  Widget _buildDataErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Gagal mengambil data analytics dari endpoint.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.reading,
    required this.status,
    required this.progress,
    required this.color,
  });

  final String label;
  final String reading;
  final String status;
  final double progress;
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
