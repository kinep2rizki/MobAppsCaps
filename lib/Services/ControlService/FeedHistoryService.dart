import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../AuthSessionService.dart';
import '../ProfileService.dart';
import '../api_service.dart';

class FeedHistoryEntry {
  const FeedHistoryEntry({
    this.id,
    this.feedingScheduleId,
    this.farmingCycleId,
    this.actualTime,
    this.quantityGiven,
    this.administeredBy,
    this.notes,
    this.createdAt,
    this.rawData = const <String, dynamic>{},
  });

  final int? id;
  final int? feedingScheduleId;
  final int? farmingCycleId;
  final DateTime? actualTime;
  final double? quantityGiven;
  final String? administeredBy;
  final String? notes;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  factory FeedHistoryEntry.fromMap(Map<String, dynamic> data) {
    return FeedHistoryEntry(
      id: _readInt(data, const ['id']),
      feedingScheduleId:
          _readInt(data, const ['feeding_schedule_id', 'feedingScheduleId']),
      farmingCycleId:
          _readInt(data, const ['farming_cycle_id', 'farmingCycleId']),
      actualTime: _readDateTime(data, const ['actual_time', 'actualTime']),
      quantityGiven: _readDouble(
        data,
        const ['quantity_given', 'quantityGiven', 'quantity'],
      ),
      administeredBy:
          _readString(data, const ['administered_by', 'administeredBy']),
      notes: _readString(data, const ['notes']),
      createdAt: _readDateTime(data, const ['created_at', 'createdAt']),
      rawData: data,
    );
  }
}

class FeedHistoryStats {
  const FeedHistoryStats({
    this.totalRecords,
    this.totalQuantityGiven,
    this.averageQuantityGiven,
    this.lastActualTime,
    this.rawData = const <String, dynamic>{},
  });

  final int? totalRecords;
  final double? totalQuantityGiven;
  final double? averageQuantityGiven;
  final DateTime? lastActualTime;
  final Map<String, dynamic> rawData;

  factory FeedHistoryStats.fromMap(Map<String, dynamic> data) {
    return FeedHistoryStats(
      totalRecords:
          _readInt(data, const ['total_records', 'totalRecords', 'count']),
      totalQuantityGiven: _readDouble(
        data,
        const ['total_quantity_given', 'totalQuantityGiven', 'total_given'],
      ),
      averageQuantityGiven: _readDouble(
        data,
        const ['average_quantity_given', 'averageQuantityGiven', 'average_given'],
      ),
      lastActualTime:
          _readDateTime(data, const ['last_actual_time', 'lastActualTime']),
      rawData: data,
    );
  }
}

class FeedHistoryService {
  static const Duration requestTimeout = Duration(seconds: 10);
  static const double maxEntryQuantityKg = 20.0;

  static Future<List<FeedHistoryEntry>> getFeedHistory({
    required int farmingCycleId,
    int limit = 100,
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
      '[FeedHistoryService] GET $resolvedBaseUrl/feed/history/$farmingCycleId?limit=$limit '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final historyUri = Uri.parse('$resolvedBaseUrl/feed/history/$farmingCycleId')
          .replace(queryParameters: <String, String>{'limit': limit.toString()});

      final response = await AuthSessionService.performWithAutoRefresh(
        client: httpClient,
        overrideBaseUrl: overrideBaseUrl,
        authToken: resolvedToken,
        timeout: requestTimeout,
        request: (token) {
          return httpClient
              .get(
                historyUri,
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(requestTimeout);
        },
      );

      debugPrint(
        '[FeedHistoryService] GET /feed/history/$farmingCycleId status: ${response.statusCode}',
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
              'Gagal mengambil riwayat pemberian pakan (${response.statusCode})',
        );
      }

      return _extractEntries(decodedBody);
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<FeedHistoryEntry> createFeedHistory({
    required int farmingCycleId,
    required double quantityGiven,
    String administeredBy = 'manual',
    String? notes,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
    }

    final normalizedAdministeredBy = administeredBy.trim().isEmpty
        ? 'manual'
        : administeredBy.trim();
    final normalizedNotes = notes?.trim();

    if (quantityGiven <= 0) {
      throw Exception('quantity_given harus lebih besar dari 0.');
    }

    if (quantityGiven > maxEntryQuantityKg) {
      throw Exception(
        'quantity_given maksimal ${maxEntryQuantityKg.toStringAsFixed(0)} kg.',
      );
    }

    final payload = <String, dynamic>{
      'administered_by': normalizedAdministeredBy,
      'quantity_given': quantityGiven,
      if (normalizedNotes != null && normalizedNotes.isNotEmpty) 'notes': normalizedNotes,
    };

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

    debugPrint(
      '[FeedHistoryService] POST $resolvedBaseUrl/feed/history/$farmingCycleId '
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
                Uri.parse('$resolvedBaseUrl/feed/history/$farmingCycleId'),
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
        '[FeedHistoryService] POST /feed/history/$farmingCycleId status: ${response.statusCode}',
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
              'Gagal mencatat pemberian pakan (${response.statusCode})',
        );
      }

      final entries = _extractEntries(decodedBody);
      if (entries.isNotEmpty) {
        return entries.first;
      }

      return FeedHistoryEntry.fromMap({
        'farming_cycle_id': farmingCycleId,
        'administered_by': normalizedAdministeredBy,
        'quantity_given': quantityGiven,
        if (normalizedNotes != null && normalizedNotes.isNotEmpty) 'notes': normalizedNotes,
      });
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<FeedHistoryStats> getFeedHistoryStats({
    required int farmingCycleId,
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
      '[FeedHistoryService] GET $resolvedBaseUrl/feed/history/$farmingCycleId/stats '
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
                Uri.parse('$resolvedBaseUrl/feed/history/$farmingCycleId/stats'),
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(requestTimeout);
        },
      );

      debugPrint(
        '[FeedHistoryService] GET /feed/history/$farmingCycleId/stats status: ${response.statusCode}',
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
              'Gagal mengambil statistik pemberian pakan (${response.statusCode})',
        );
      }

      return _extractStats(decodedBody);
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
    debugPrint('[FeedHistoryService] Cleared invalid auth session after 401');
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

  static List<FeedHistoryEntry> _extractEntries(Object? decodedBody) {
    final candidates = <Object?>[];

    if (decodedBody is List) {
      candidates.addAll(decodedBody);
    } else if (decodedBody is Map) {
      final normalized = _normalizeMap(decodedBody);
      final nested = normalized['data'] ??
          normalized['items'] ??
          normalized['results'] ??
          normalized['history'] ??
          normalized['records'];

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
        .map(FeedHistoryEntry.fromMap)
        .toList();
  }

  static FeedHistoryStats _extractStats(Object? decodedBody) {
    if (decodedBody is Map) {
      final normalized = _normalizeMap(decodedBody);
      final nested = normalized['data'] ?? normalized['stats'] ?? normalized['summary'];
      if (nested is Map) {
        return FeedHistoryStats.fromMap({
          ...normalized,
          ..._normalizeMap(nested),
        });
      }

      return FeedHistoryStats.fromMap(normalized);
    }

    return const FeedHistoryStats();
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