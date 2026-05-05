import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:my_app/Services/api_service.dart';

class HarvestEstimate {
	final int? id;
	final int? farmingCycleId;
	final DateTime? predictedHarvestDate;
	final double? confidenceScore;
	final int? mlModelId;
	final Map<String, dynamic>? featuresUsed;
	final DateTime? predictionDate;

	const HarvestEstimate({
		this.id,
		this.farmingCycleId,
		this.predictedHarvestDate,
		this.confidenceScore,
		this.mlModelId,
		this.featuresUsed,
		this.predictionDate,
	});

	factory HarvestEstimate.fromJson(Map<String, dynamic> json) {
		return HarvestEstimate(
			id: _asInt(json['id']),
			farmingCycleId: _asInt(json['farming_cycle_id'] ?? json['farmingCycleId']),
			predictedHarvestDate: _asDateTime(
				json['predicted_harvest_date'] ?? json['predictedHarvestDate'],
			),
			confidenceScore: _asDouble(json['confidence_score'] ?? json['confidenceScore']),
			mlModelId: _asInt(json['ml_model_id'] ?? json['mlModelId']),
			featuresUsed: _asMap(json['features_used'] ?? json['featuresUsed']),
			predictionDate: _asDateTime(json['prediction_date'] ?? json['predictionDate']),
		);
	}

	Map<String, dynamic> toJson() {
		return {
			if (id != null) 'id': id,
			if (farmingCycleId != null) 'farming_cycle_id': farmingCycleId,
			if (predictedHarvestDate != null)
				'predicted_harvest_date': predictedHarvestDate!.toIso8601String(),
			if (confidenceScore != null) 'confidence_score': confidenceScore,
			if (mlModelId != null) 'ml_model_id': mlModelId,
			if (featuresUsed != null) 'features_used': featuresUsed,
			if (predictionDate != null) 'prediction_date': predictionDate!.toIso8601String(),
		};
	}

	static int? _asInt(Object? value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value is String) return int.tryParse(value);
		return null;
	}

	static double? _asDouble(Object? value) {
		if (value is double) return value;
		if (value is num) return value.toDouble();
		if (value is String) {
			return double.tryParse(value.trim().replaceAll(',', '.'));
		}
		return null;
	}

	static DateTime? _asDateTime(Object? value) {
		if (value is DateTime) return value;
		if (value is String && value.trim().isNotEmpty) {
			return DateTime.tryParse(value);
		}
		return null;
	}

	static Map<String, dynamic>? _asMap(Object? value) {
		if (value is Map<String, dynamic>) return value;
		if (value is Map) {
			return value.map((key, dynamic nestedValue) {
				return MapEntry(key.toString(), nestedValue);
			});
		}
		return null;
	}
}

class PrediksiPanenResult {
	final bool success;
	final String message;
	final List<HarvestEstimate> estimates;

	const PrediksiPanenResult({
		required this.success,
		required this.message,
		required this.estimates,
	});

	HarvestEstimate? get latestEstimate {
		if (estimates.isEmpty) {
			return null;
		}

		final ordered = [...estimates]..sort((left, right) {
			final leftDate = left.predictionDate ?? left.predictedHarvestDate;
			final rightDate = right.predictionDate ?? right.predictedHarvestDate;

			if (leftDate == null && rightDate == null) return 0;
			if (leftDate == null) return 1;
			if (rightDate == null) return -1;
			return rightDate.compareTo(leftDate);
		});

		return ordered.first;
	}
}

class PrediksiPanenService {
	static const String baseUrl = ApiService.baseUrl;
	static const Duration requestTimeout = Duration(seconds: 20);

	static Future<PrediksiPanenResult> getHarvestEstimates({
		required int farmingCycleId,
		http.Client? client,
		String? overrideBaseUrl,
		String? authToken,
	}) async {
		final resolvedToken = authToken ?? await _readStoredToken();
		if (resolvedToken == null || resolvedToken.trim().isEmpty) {
			return const PrediksiPanenResult(
				success: false,
				message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
				estimates: [],
			);
		}

		final httpClient = client ?? http.Client();
		final shouldCloseClient = client == null;

		try {
			final response = await httpClient.get(
				Uri.parse(
					'${_resolveBaseUrl(overrideBaseUrl)}/ml/harvest-estimate/$farmingCycleId',
				),
				headers: {
					'Accept': 'application/json',
					'Authorization': 'Bearer $resolvedToken',
				},
			).timeout(requestTimeout);

			final decodedBody = _decodeResponseBody(response.body);

			if (response.statusCode != 200) {
				debugPrint(
					'PrediksiPanenService GET /ml/harvest-estimate/$farmingCycleId failed with status ${response.statusCode}: '
					'${response.body}',
				);

				return PrediksiPanenResult(
					success: false,
					message: _extractMessage(decodedBody) ??
							'Gagal mengambil prediksi panen (${response.statusCode})',
					estimates: const [],
				);
			}

			final estimates = _extractEstimates(decodedBody);
			if (estimates.isEmpty) {
				return const PrediksiPanenResult(
					success: false,
					message: 'Data prediksi panen kosong.',
					estimates: [],
				);
			}

			return PrediksiPanenResult(
				success: true,
				message: _extractMessage(decodedBody) ?? 'Prediksi panen berhasil dimuat',
				estimates: estimates,
			);
		} on TimeoutException {
			return const PrediksiPanenResult(
				success: false,
				message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
				estimates: [],
			);
		} catch (error) {
			return PrediksiPanenResult(
				success: false,
				message: 'Tidak dapat mengambil prediksi panen: $error',
				estimates: const [],
			);
		} finally {
			if (shouldCloseClient) {
				httpClient.close();
			}
		}
	}

	static Future<PrediksiPanenResult> getLatestHarvestEstimate({
		Map<String, dynamic>? fallbackData,
		http.Client? client,
		String? overrideBaseUrl,
		String? authToken,
	}) async {
		final farmingCycleId = await resolveFarmingCycleId(
			fallbackData: fallbackData,
		);

		if (farmingCycleId == null) {
			return const PrediksiPanenResult(
				success: false,
				message: 'farming_cycle_id belum ditemukan.',
				estimates: [],
			);
		}

		return getHarvestEstimates(
			farmingCycleId: farmingCycleId,
			client: client,
			overrideBaseUrl: overrideBaseUrl,
			authToken: authToken,
		);
	}

	static Future<int?> resolveFarmingCycleId({
		Map<String, dynamic>? fallbackData,
	}) async {
		final fromData = _extractFarmingCycleIdFromMap(fallbackData);
		if (fromData != null) {
			return fromData;
		}

		final prefs = await SharedPreferences.getInstance();
		const keys = <String>[
			'farming_cycle_id',
			'farmingCycleId',
			'selected_farming_cycle_id',
			'selectedFarmingCycleId',
			'active_farming_cycle_id',
			'activeFarmingCycleId',
			'cycle_id',
			'cycleId',
		];

		for (final key in keys) {
			final intValue = prefs.getInt(key);
			if (intValue != null) {
				return intValue;
			}

			final stringValue = prefs.getString(key);
			final parsed = int.tryParse(stringValue?.trim() ?? '');
			if (parsed != null) {
				return parsed;
			}
		}

		return null;
	}

	static List<HarvestEstimate> _extractEstimates(Object? decodedBody) {
		final candidates = <Object?>[];

		if (decodedBody is List) {
			candidates.addAll(decodedBody);
		} else if (decodedBody is Map) {
			final map = _normalizeMap(decodedBody);
			final nested = map['data'] ?? map['results'] ?? map['items'] ?? map['predictions'];

			if (nested is List) {
				candidates.addAll(nested);
			} else if (nested is Map) {
				candidates.add(nested);
			} else {
				candidates.add(map);
			}
		}

		return candidates
				.whereType<Map>()
				.map((entry) => HarvestEstimate.fromJson(_normalizeMap(entry)))
				.toList();
	}

	static int? _extractFarmingCycleIdFromMap(Map<String, dynamic>? map) {
		if (map == null || map.isEmpty) return null;

		final normalized = _normalizeMap(map);
		for (final key in const [
			'farming_cycle_id',
			'farmingCycleId',
			'selected_farming_cycle_id',
			'selectedFarmingCycleId',
			'active_farming_cycle_id',
			'activeFarmingCycleId',
			'cycle_id',
			'cycleId',
		]) {
			final value = normalized[key];
			final parsed = _asInt(value);
			if (parsed != null) return parsed;
		}

		return null;
	}

	static Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> map) {
		return map.map((key, dynamic value) => MapEntry(key.toString(), value));
	}

	static Object? _decodeResponseBody(String body) {
		if (body.isEmpty) return null;

		try {
			return jsonDecode(body);
		} catch (_) {
			return body;
		}
	}

	static String? _extractMessage(Object? decodedBody) {
		if (decodedBody is Map) {
			final normalized = _normalizeMap(decodedBody);
			final dynamic message =
					normalized['message'] ?? normalized['error'] ?? normalized['msg'];
			if (message is String && message.trim().isNotEmpty) {
				return message;
			}

			final dynamic detail = normalized['detail'];
			if (detail is String && detail.trim().isNotEmpty) {
				return detail;
			}
			if (detail is List && detail.isNotEmpty) {
				return detail.map((item) => item.toString()).join('; ');
			}
		}

		if (decodedBody is String && decodedBody.trim().isNotEmpty) {
			return decodedBody;
		}

		return null;
	}

	static int? _asInt(Object? value) {
		if (value is int) return value;
		if (value is num) return value.toInt();
		if (value is String) return int.tryParse(value.trim());
		return null;
	}

	static String _resolveBaseUrl(String? overrideBaseUrl) {
		final value = overrideBaseUrl?.trim();
		if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
			return baseUrl;
		}

		return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
	}

	static Future<String?> _readStoredToken() async {
		final prefs = await SharedPreferences.getInstance();
		final token = prefs.getString('authToken');
		if (token != null && token.trim().isNotEmpty) {
			return token.trim();
		}

		final fallbackToken = prefs.getString('accessToken');
		if (fallbackToken != null && fallbackToken.trim().isNotEmpty) {
			return fallbackToken.trim();
		}

		return null;
	}
}
