import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_app/Services/api_service.dart';
import 'package:my_app/Services/ProfileService.dart';

class FarmCycle {
  final int? id;
  final int? userId;
  final String? cycleName;
  final DateTime? seedingDate;
  final DateTime? estimatedHarvestDate;
  final DateTime? actualHarvestDate;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FarmCycle({
    this.id,
    this.userId,
    this.cycleName,
    this.seedingDate,
    this.estimatedHarvestDate,
    this.actualHarvestDate,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory FarmCycle.fromJson(Map<String, dynamic> json) {
    return FarmCycle(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id'] ?? json['userId']),
      cycleName: _asString(json['cycle_name'] ?? json['cycleName']),
      seedingDate: _asDateTime(json['seeding_date'] ?? json['seedingDate']),
      estimatedHarvestDate: _asDateTime(
        json['estimated_harvest_date'] ?? json['estimatedHarvestDate'],
      ),
      actualHarvestDate: _asDateTime(
        json['actual_harvest_date'] ?? json['actualHarvestDate'],
      ),
      status: _asString(json['status']),
      createdAt: _asDateTime(json['created_at'] ?? json['createdAt']),
      updatedAt: _asDateTime(json['updated_at'] ?? json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (cycleName != null) 'cycle_name': cycleName,
      if (seedingDate != null) 'seeding_date': seedingDate!.toIso8601String(),
      if (estimatedHarvestDate != null)
        'estimated_harvest_date': estimatedHarvestDate!.toIso8601String(),
      if (actualHarvestDate != null)
        'actual_harvest_date': actualHarvestDate!.toIso8601String(),
      if (status != null) 'status': status,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  int? get daysSinceSeeding {
    final seeding = seedingDate;
    if (seeding == null) {
      return null;
    }

    final today = DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final startOfSeeding = DateTime(seeding.year, seeding.month, seeding.day);

    final difference = startOfToday.difference(startOfSeeding).inDays;
    return difference < 0 ? 0 : difference;
  }

  String get daysSinceSeedingText {
    final days = daysSinceSeeding;
    if (days == null) {
      return '-';
    }

    return 'Sudah $days hari sejak pembibitan';
  }
}

class FarmCycleResult {
  final bool success;
  final String message;
  final FarmCycle? farmCycle;

  const FarmCycleResult({
    required this.success,
    required this.message,
    this.farmCycle,
  });
}

class FarmCycleService {
  static const String baseUrl = ApiService.baseUrl;
  static const Duration requestTimeout = Duration(seconds: 20);

  static Future<FarmCycle?> getActiveFarmCycle({
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      debugPrint('[FarmCycleService] Missing auth token for GET /farming-cycle/active');
      throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    debugPrint(
      '[FarmCycleService] GET $resolvedBaseUrl/farming-cycle/active '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/farming-cycle/active'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
      ).timeout(requestTimeout);

      debugPrint(
        '[FarmCycleService] GET /farming-cycle/active status: ${response.statusCode}',
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
        _logFailure(
          'GET /farming-cycle/active',
          response.statusCode,
          response.body,
        );

        throw Exception(_extractMessage(decodedBody) ??
            'Gagal mengambil farming cycle aktif (${response.statusCode})');
      }

      return _extractSingleCycle(decodedBody);
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<FarmCycle?> getLatestFarmCycle({
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final cycles = await getFarmCycles(
      client: client,
      overrideBaseUrl: overrideBaseUrl,
      authToken: authToken,
    );
    
    if (cycles.isEmpty) {
      return null;
    }
    
    final ordered = [...cycles]..sort((left, right) {
      final leftDate = left.updatedAt ?? left.createdAt ?? left.seedingDate;
      final rightDate = right.updatedAt ?? right.createdAt ?? right.seedingDate;
      
      if (leftDate == null && rightDate == null) return 0;
      if (leftDate == null) return 1;
      if (rightDate == null) return -1;
      return rightDate.compareTo(leftDate);
    });
    
    return ordered.first;
  }

  static Future<List<FarmCycle>> getFarmCycles({
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      debugPrint('[FarmCycleService] Missing auth token for GET /farming-cycle/');
      throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    debugPrint(
      '[FarmCycleService] GET $resolvedBaseUrl/farming-cycle/ '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/farming-cycle/'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
      ).timeout(requestTimeout);

      debugPrint(
        '[FarmCycleService] GET /farming-cycle/ status: ${response.statusCode}',
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
        _logFailure('GET /farming-cycle/', response.statusCode, response.body);

        throw Exception(_extractMessage(decodedBody) ??
            'Gagal mengambil farming cycle (${response.statusCode})');
      }

      return _extractCycles(decodedBody);
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<FarmCycleResult> createFarmCycle({
    required String cycleName,
    required DateTime seedingDate,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      debugPrint('[FarmCycleService] Missing auth token for POST /farming-cycle/');
      return const FarmCycleResult(
        success: false,
        message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
    }

    final payload = <String, dynamic>{
      'cycle_name': cycleName.trim(),
      'seeding_date': _formatDate(seedingDate),
    };

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    debugPrint(
      '[FarmCycleService] POST $resolvedBaseUrl/farming-cycle/ '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient.post(
        Uri.parse('$resolvedBaseUrl/farming-cycle/'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
        body: jsonEncode(payload),
      ).timeout(requestTimeout);

      debugPrint(
        '[FarmCycleService] POST /farming-cycle/ status: ${response.statusCode}',
      );

      final decodedBody = _decodeResponseBody(response.body);

      if (response.statusCode == 401) {
        await _clearInvalidSession();
        return FarmCycleResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Token tidak valid atau sudah expired. Silakan login ulang.',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logFailure('POST /farming-cycle/', response.statusCode, response.body);

        return FarmCycleResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Gagal membuat farming cycle (${response.statusCode})',
        );
      }

      final responseMap = _extractMap(decodedBody);
      final cycleMap = _extractCycleMap(responseMap);

      return FarmCycleResult(
        success: true,
        message: _extractMessage(responseMap) ?? 'Farming cycle berhasil dibuat',
        farmCycle: cycleMap == null ? null : FarmCycle.fromJson(cycleMap),
      );
    } on TimeoutException {
      return const FarmCycleResult(
        success: false,
        message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
      );
    } catch (error) {
      return FarmCycleResult(
        success: false,
        message: 'Tidak dapat membuat farming cycle: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<FarmCycleResult> updateFarmCycle({
    required int cycleId,
    String? cycleName,
    DateTime? seedingDate,
    DateTime? estimatedHarvestDate,
    DateTime? actualHarvestDate,
    String? status,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      debugPrint('[FarmCycleService] Missing auth token for PUT /farming-cycle/$cycleId');
      return const FarmCycleResult(
        success: false,
        message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
    }

    final payload = <String, dynamic>{
      if (cycleName != null && cycleName.trim().isNotEmpty)
        'cycle_name': cycleName.trim(),
      if (seedingDate != null) 'seeding_date': _formatDate(seedingDate),
      if (estimatedHarvestDate != null)
        'estimated_harvest_date': _formatDate(estimatedHarvestDate),
      if (actualHarvestDate != null)
        'actual_harvest_date': _formatDate(actualHarvestDate),
      if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
    };

    if (payload.isEmpty) {
      return const FarmCycleResult(
        success: false,
        message: 'Tidak ada data yang ingin diperbarui.',
      );
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    debugPrint(
      '[FarmCycleService] PUT $resolvedBaseUrl/farming-cycle/$cycleId '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient.put(
        Uri.parse('$resolvedBaseUrl/farming-cycle/$cycleId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
        body: jsonEncode(payload),
      ).timeout(requestTimeout);

      debugPrint(
        '[FarmCycleService] PUT /farming-cycle/$cycleId status: ${response.statusCode}',
      );

      final decodedBody = _decodeResponseBody(response.body);

      if (response.statusCode == 401) {
        await _clearInvalidSession();
        return FarmCycleResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Token tidak valid atau sudah expired. Silakan login ulang.',
        );
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        _logFailure('PUT /farming-cycle/$cycleId', response.statusCode, response.body);

        return FarmCycleResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Gagal memperbarui farming cycle (${response.statusCode})',
        );
      }

      final responseMap = _extractMap(decodedBody);
      final cycleMap = _extractCycleMap(responseMap);

      return FarmCycleResult(
        success: true,
        message: _extractMessage(responseMap) ?? 'Farming cycle berhasil diperbarui',
        farmCycle: cycleMap == null ? null : FarmCycle.fromJson(cycleMap),
      );
    } on TimeoutException {
      return const FarmCycleResult(
        success: false,
        message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
      );
    } catch (error) {
      return FarmCycleResult(
        success: false,
        message: 'Tidak dapat memperbarui farming cycle: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static List<FarmCycle> _extractCycles(Object? decodedBody) {
    final candidates = <Object?>[];

    if (decodedBody is List) {
      candidates.addAll(decodedBody);
    } else if (decodedBody is Map) {
      final map = _extractMap(decodedBody);
      final nested = map['data'] ?? map['items'] ?? map['results'] ?? map['cycles'];

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
        .map((entry) => FarmCycle.fromJson(_extractMap(entry)))
        .toList();
  }

  static FarmCycle? _extractSingleCycle(Object? decodedBody) {
    if (decodedBody is List) {
      if (decodedBody.isEmpty) {
        return null;
      }

      final first = decodedBody.first;
      if (first is Map<String, dynamic>) {
        return FarmCycle.fromJson(first);
      }
      if (first is Map) {
        return FarmCycle.fromJson(_extractMap(first));
      }
      return null;
    }

    if (decodedBody is Map<String, dynamic>) {
      final map = _extractMap(decodedBody);
      final nested = map['data'] ?? map['cycle'] ?? map['item'] ?? map['active_cycle'];
      if (nested is Map<String, dynamic>) {
        return FarmCycle.fromJson(nested);
      }
      if (nested is Map) {
        return FarmCycle.fromJson(_extractMap(nested));
      }

      return FarmCycle.fromJson(map);
    }

    if (decodedBody is Map) {
      final map = _extractMap(decodedBody);
      final nested = map['data'] ?? map['cycle'] ?? map['item'] ?? map['active_cycle'];
      if (nested is Map<String, dynamic>) {
        return FarmCycle.fromJson(nested);
      }
      if (nested is Map) {
        return FarmCycle.fromJson(_extractMap(nested));
      }

      return FarmCycle.fromJson(map);
    }

    return null;
  }

  static Map<String, dynamic>? _extractCycleMap(Map<String, dynamic> responseMap) {
    final candidates = <Object?>[
      responseMap,
      responseMap['data'],
      responseMap['item'],
      responseMap['cycle'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) return candidate;
      if (candidate is Map) {
        return candidate.map((key, dynamic value) => MapEntry(key.toString(), value));
      }
    }

    return null;
  }

  static Map<String, dynamic> _extractMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic nestedValue) {
        return MapEntry(key.toString(), nestedValue);
      });
    }
    return <String, dynamic>{};
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
      final map = _extractMap(decodedBody);
      final dynamic message = map['message'] ?? map['error'] ?? map['msg'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }

      final dynamic detail = map['detail'];
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

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _resolveBaseUrl(String? overrideBaseUrl) {
    return ApiService.resolveBaseUrl(overrideBaseUrl);
  }

  static void _logFailure(String action, int statusCode, String responseBody) {
    final trimmedBody = responseBody.trim();
    final bodyPreview = trimmedBody.length > 500
        ? '${trimmedBody.substring(0, 500)}...'
        : trimmedBody;

    debugPrint(
      '[FarmCycleService] $action failed with status $statusCode: $bodyPreview',
    );
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
    await ProfileService.clearCachedProfile();
    debugPrint('[FarmCycleService] Cleared invalid auth session after 401');
  }
}