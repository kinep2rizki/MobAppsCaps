import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../AuthSessionService.dart';
import '../ProfileService.dart';
import '../api_service.dart';

class FeedSchedule {
	const FeedSchedule({
		this.id,
		this.farmingCycleId,
		this.scheduledTime,
		this.expectedQuantity,
		this.frequency,
		this.status,
		this.createdAt,
		this.rawData = const <String, dynamic>{},
	});

	final int? id;
	final int? farmingCycleId;
	final String? scheduledTime;
	final double? expectedQuantity;
	final String? frequency;
	final String? status;
	final DateTime? createdAt;
	final Map<String, dynamic> rawData;

	factory FeedSchedule.fromMap(Map<String, dynamic> data) {
		return FeedSchedule(
			id: _readInt(data, const ['id']),
			farmingCycleId: _readInt(data, const ['farming_cycle_id', 'farmingCycleId']),
			scheduledTime: _readString(data, const ['scheduled_time', 'scheduledTime']),
			expectedQuantity: _readDouble(data, const ['expected_quantity', 'expectedQuantity']),
			frequency: _readString(data, const ['frequency']),
			status: _readString(data, const ['status']),
			createdAt: _readDateTime(data, const ['created_at', 'createdAt']),
			rawData: data,
		);
	}

	bool get isActive {
		final normalized = status?.trim().toLowerCase();
		return normalized == 'active' || normalized == 'enabled' || normalized == 'on';
	}
}

class JadwalPakanService {
	static const Duration requestTimeout = Duration(seconds: 10);

	static Future<List<FeedSchedule>> getFeedSchedules({
		int? farmingCycleId,
		http.Client? client,
		String? overrideBaseUrl,
		String? authToken,
	}) async {
		final resolvedFarmingCycleId =
				farmingCycleId ?? await resolveFarmingCycleId();

		if (resolvedFarmingCycleId == null) {
			throw Exception(
				'farming_cycle_id belum ditemukan. Silakan pilih farm cycle aktif terlebih dahulu.',
			);
		}

		final resolvedToken = authToken ?? await _readStoredToken();
		if (resolvedToken == null || resolvedToken.trim().isEmpty) {
			throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
		}

		final httpClient = client ?? http.Client();
		final shouldCloseClient = client == null;
		final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

		debugPrint(
			'[JadwalPakanService] GET $resolvedBaseUrl/feed/schedule/$resolvedFarmingCycleId '
			'(token length: ${resolvedToken.trim().length})',
		);

		try {
			final response = await AuthSessionService.performWithAutoRefresh(
				client: httpClient,
				overrideBaseUrl: overrideBaseUrl,
				authToken: resolvedToken,
				timeout: requestTimeout,
				request: (token) {
					return httpClient
							.get(
								Uri.parse('$resolvedBaseUrl/feed/schedule/$resolvedFarmingCycleId'),
								headers: {
									'Accept': 'application/json',
									'Authorization': 'Bearer $token',
								},
							)
							.timeout(requestTimeout);
				},
			);

			debugPrint(
				'[JadwalPakanService] GET /feed/schedule/$resolvedFarmingCycleId status: ${response.statusCode}',
			);

			final decodedBody = _decodeResponseBody(response.body);

			if (response.statusCode == 401) {
				await _clearInvalidSession();
				throw Exception(
					_extractMessage(decodedBody) ??
							'Token tidak valid atau sudah expired. Silakan login ulang.',
				);
			}

			if (response.statusCode != 200) {
				throw Exception(
					_extractMessage(decodedBody) ??
							'Gagal mengambil daftar jadwal pakan (${response.statusCode})',
				);
			}

			return _extractSchedules(decodedBody);
		} on TimeoutException {
			throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
		} finally {
			if (shouldCloseClient) {
				httpClient.close();
			}
		}
	}

	static Future<FeedSchedule> createFeedSchedule({
		required int farmingCycleId,
		required double expectedQuantity,
		required String frequency,
		required String scheduledTime,
		http.Client? client,
		String? overrideBaseUrl,
		String? authToken,
	}) async {
		final resolvedToken = authToken ?? await _readStoredToken();
		if (resolvedToken == null || resolvedToken.trim().isEmpty) {
			throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
		}

		final normalizedFrequency = frequency.trim();
		final normalizedTime = scheduledTime.trim();

		if (normalizedFrequency.isEmpty) {
			throw Exception('frequency wajib diisi.');
		}

		if (normalizedTime.isEmpty) {
			throw Exception('scheduled_time wajib diisi.');
		}

		if (expectedQuantity <= 0) {
			throw Exception('expected_quantity harus lebih besar dari 0.');
		}

		final payload = <String, dynamic>{
			'expected_quantity': expectedQuantity,
			'frequency': normalizedFrequency,
			'scheduled_time': normalizedTime,
		};

		final httpClient = client ?? http.Client();
		final shouldCloseClient = client == null;
		final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

		debugPrint(
			'[JadwalPakanService] POST $resolvedBaseUrl/feed/schedule/$farmingCycleId '
			'(token length: ${resolvedToken.trim().length})',
		);

		try {
			final response = await AuthSessionService.performWithAutoRefresh(
				client: httpClient,
				overrideBaseUrl: overrideBaseUrl,
				authToken: resolvedToken,
				timeout: requestTimeout,
				request: (token) {
					return httpClient
							.post(
								Uri.parse('$resolvedBaseUrl/feed/schedule/$farmingCycleId'),
								headers: {
									'Accept': 'application/json',
									'Content-Type': 'application/json',
									'Authorization': 'Bearer $token',
								},
								body: jsonEncode(payload),
							)
							.timeout(requestTimeout);
				},
			);

			debugPrint(
				'[JadwalPakanService] POST /feed/schedule/$farmingCycleId status: ${response.statusCode}',
			);

			final decodedBody = _decodeResponseBody(response.body);

			if (response.statusCode == 401) {
				await _clearInvalidSession();
				throw Exception(
					_extractMessage(decodedBody) ??
							'Token tidak valid atau sudah expired. Silakan login ulang.',
				);
			}

			if (response.statusCode != 200 && response.statusCode != 201) {
				throw Exception(
					_extractMessage(decodedBody) ??
							'Gagal membuat jadwal pakan (${response.statusCode})',
				);
			}

			final schedules = _extractSchedules(decodedBody);
			if (schedules.isNotEmpty) {
				return schedules.first;
			}

			return FeedSchedule.fromMap({
				'farming_cycle_id': farmingCycleId,
				'expected_quantity': expectedQuantity,
				'frequency': normalizedFrequency,
				'scheduled_time': normalizedTime,
			});
		} on TimeoutException {
			throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
		} finally {
			if (shouldCloseClient) {
				httpClient.close();
			}
		}
	}

	static Future<FeedSchedule> updateFeedSchedule({
		required int scheduleId,
		double? expectedQuantity,
		String? frequency,
		String? scheduledTime,
		String? status,
		http.Client? client,
		String? overrideBaseUrl,
		String? authToken,
	}) async {
		final resolvedToken = authToken ?? await _readStoredToken();
		if (resolvedToken == null || resolvedToken.trim().isEmpty) {
			throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
		}

		final normalizedFrequency = frequency?.trim();
		final normalizedTime = scheduledTime?.trim();
		final normalizedStatus = status?.trim().toLowerCase();

		if (expectedQuantity != null && expectedQuantity <= 0) {
			throw Exception('expected_quantity harus lebih besar dari 0.');
		}

		if (normalizedFrequency != null && normalizedFrequency.isEmpty) {
			throw Exception('frequency tidak boleh kosong.');
		}

		if (normalizedTime != null && normalizedTime.isEmpty) {
			throw Exception('scheduled_time tidak boleh kosong.');
		}

		if (normalizedStatus != null &&
			normalizedStatus != 'active' &&
			normalizedStatus != 'inactive') {
			throw Exception('status harus active atau inactive.');
		}

		final payload = <String, dynamic>{
			if (expectedQuantity != null) 'expected_quantity': expectedQuantity,
			if (normalizedFrequency != null) 'frequency': normalizedFrequency,
			if (normalizedTime != null) 'scheduled_time': normalizedTime,
			if (normalizedStatus != null) 'status': normalizedStatus,
		};

		if (payload.isEmpty) {
			throw Exception('Tidak ada data yang diubah.');
		}

		final httpClient = client ?? http.Client();
		final shouldCloseClient = client == null;
		final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

		debugPrint(
			'[JadwalPakanService] PATCH $resolvedBaseUrl/feed/schedule/$scheduleId '
			'(token length: ${resolvedToken.trim().length})',
		);

		try {
			final response = await AuthSessionService.performWithAutoRefresh(
				client: httpClient,
				overrideBaseUrl: overrideBaseUrl,
				authToken: resolvedToken,
				timeout: requestTimeout,
				request: (token) {
					return httpClient
							.put(
								Uri.parse('$resolvedBaseUrl/feed/schedule/$scheduleId'),
								headers: {
									'Accept': 'application/json',
									'Content-Type': 'application/json',
									'Authorization': 'Bearer $token',
								},
								body: jsonEncode(payload),
							)
							.timeout(requestTimeout);
				},
			);

			debugPrint(
				'[JadwalPakanService] PATCH /feed/schedule/$scheduleId status: ${response.statusCode}',
			);

			final decodedBody = _decodeResponseBody(response.body);

			if (response.statusCode == 401) {
				await _clearInvalidSession();
				throw Exception(
					_extractMessage(decodedBody) ??
						'Token tidak valid atau sudah expired. Silakan login ulang.',
				);
			}

			if (response.statusCode != 200 && response.statusCode != 201) {
				throw Exception(
					_extractMessage(decodedBody) ??
						'Gagal memperbarui jadwal pakan (${response.statusCode})',
				);
			}

			final schedules = _extractSchedules(decodedBody);
			if (schedules.isNotEmpty) {
				return schedules.first;
			}

			return FeedSchedule.fromMap({
				'id': scheduleId,
				if (expectedQuantity != null) 'expected_quantity': expectedQuantity,
				if (normalizedFrequency != null) 'frequency': normalizedFrequency,
				if (normalizedTime != null) 'scheduled_time': normalizedTime,
				if (normalizedStatus != null) 'status': normalizedStatus,
			});
		} on TimeoutException {
			throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
		} finally {
			if (shouldCloseClient) {
				httpClient.close();
			}
		}
	}

	static Future<void> deleteFeedSchedule({
		required int scheduleId,
		http.Client? client,
		String? overrideBaseUrl,
		String? authToken,
	}) async {
		final resolvedToken = authToken ?? await _readStoredToken();
		if (resolvedToken == null || resolvedToken.trim().isEmpty) {
			throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
		}

		final httpClient = client ?? http.Client();
		final shouldCloseClient = client == null;
		final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

		debugPrint(
			'[JadwalPakanService] DELETE $resolvedBaseUrl/feed/schedule/$scheduleId '
			'(token length: ${resolvedToken.trim().length})',
		);

		try {
			final response = await httpClient.delete(
				Uri.parse('$resolvedBaseUrl/feed/schedule/$scheduleId'),
				headers: {
					'Accept': 'application/json',
					'Authorization': 'Bearer $resolvedToken',
				},
			).timeout(requestTimeout);

			debugPrint(
				'[JadwalPakanService] DELETE /feed/schedule/$scheduleId status: ${response.statusCode}',
			);

			final decodedBody = _decodeResponseBody(response.body);

			if (response.statusCode == 401) {
				await _clearInvalidSession();
				throw Exception(
					_extractMessage(decodedBody) ??
						'Token tidak valid atau sudah expired. Silakan login ulang.',
				);
			}

			if (response.statusCode != 200 && response.statusCode != 204) {
				throw Exception(
					_extractMessage(decodedBody) ??
						'Gagal menghapus jadwal pakan (${response.statusCode})',
				);
			}
		} on TimeoutException {
			throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
		} finally {
			if (shouldCloseClient) {
				httpClient.close();
			}
		}
	}

	static Future<int?> resolveFarmingCycleId() async {
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

	static Future<void> _clearInvalidSession() async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool('isLoggedIn', false);
		await prefs.remove('authToken');
		await prefs.remove('refreshToken');
		await prefs.remove('tokenType');
		await prefs.remove('userEmail');
		await prefs.remove('farming_cycle_id');
		await prefs.remove('farmingCycleId');
		await prefs.remove('selected_farming_cycle_id');
		await prefs.remove('selectedFarmingCycleId');
		await prefs.remove('active_farming_cycle_id');
		await prefs.remove('activeFarmingCycleId');
		await prefs.remove('cycle_id');
		await prefs.remove('cycleId');
		await ProfileService.clearCachedProfile();
		debugPrint('[JadwalPakanService] Cleared invalid auth session after 401');
	}

	static Object? _decodeResponseBody(String body) {
		if (body.trim().isEmpty) {
			return null;
		}

		try {
			return jsonDecode(body);
		} catch (_) {
			return body;
		}
	}

	static String? _extractMessage(Object? decodedBody) {
		if (decodedBody is Map) {
			final dynamic message =
					decodedBody['message'] ?? decodedBody['error'] ?? decodedBody['msg'];
			if (message is String && message.trim().isNotEmpty) {
				return message;
			}

			final dynamic detail = decodedBody['detail'];
			if (detail is String && detail.trim().isNotEmpty) {
				return detail;
			}

			if (detail is List && detail.isNotEmpty) {
				final first = detail.first;
				if (first is Map) {
					final dynamic nestedMsg = first['msg'] ?? first['message'];
					if (nestedMsg is String && nestedMsg.trim().isNotEmpty) {
						return nestedMsg;
					}
				}
			}

			final dynamic data = decodedBody['data'];
			if (data is Map) {
				final dynamic nestedMessage = data['message'] ?? data['error'];
				if (nestedMessage is String && nestedMessage.trim().isNotEmpty) {
					return nestedMessage;
				}
			}
		}

		if (decodedBody is String && decodedBody.trim().isNotEmpty) {
			return decodedBody;
		}

		return null;
	}

	static List<FeedSchedule> _extractSchedules(Object? decodedBody) {
		final candidates = <Object?>[];

		if (decodedBody is List) {
			candidates.addAll(decodedBody);
		} else if (decodedBody is Map) {
			final normalized = _normalizeMap(decodedBody);
			final nested = normalized['data'] ?? normalized['items'] ?? normalized['results'];

			if (nested is List) {
				candidates.addAll(nested);
			} else if (nested is Map) {
				candidates.add(nested);
			} else {
				candidates.add(normalized);
			}
		}

		return candidates
				.whereType<Map>()
				.map((item) => _normalizeMap(item))
				.map(FeedSchedule.fromMap)
				.toList();
	}
}

Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> data) {
	return data.map((key, value) => MapEntry(key.toString(), value));
}

int? _readInt(Map<String, dynamic> data, List<String> keys) {
	for (final key in keys) {
		final value = data[key];
		if (value is int) {
			return value;
		}

		if (value is num) {
			return value.toInt();
		}

		if (value != null) {
			final parsed = int.tryParse(value.toString().trim());
			if (parsed != null) {
				return parsed;
			}
		}
	}

	return null;
}

double? _readDouble(Map<String, dynamic> data, List<String> keys) {
	for (final key in keys) {
		final value = data[key];
		if (value is double) {
			return value;
		}

		if (value is num) {
			return value.toDouble();
		}

		if (value != null) {
			final normalized = value.toString().trim().replaceAll(',', '.');
			final parsed = double.tryParse(normalized);
			if (parsed != null) {
				return parsed;
			}
		}
	}

	return null;
}

String? _readString(Map<String, dynamic> data, List<String> keys) {
	for (final key in keys) {
		final value = data[key];
		if (value != null) {
			final text = value.toString().trim();
			if (text.isNotEmpty) {
				return text;
			}
		}
	}

	return null;
}

DateTime? _readDateTime(Map<String, dynamic> data, List<String> keys) {
	for (final key in keys) {
		final value = data[key];
		if (value is DateTime) {
			return value;
		}

		if (value != null) {
			final parsed = DateTime.tryParse(value.toString().trim());
			if (parsed != null) {
				return parsed;
			}
		}
	}

	return null;
}