import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../api_service.dart';
import '../ProfileService.dart';

class FeedStock {
  const FeedStock({
    this.id,
    this.userId,
    this.farmingCycleId,
    required this.currentQuantity,
    required this.unit,
    this.minThreshold,
    this.updatedAt,
    this.rawData = const <String, dynamic>{},
  });

  final int? id;
  final int? userId;
  final int? farmingCycleId;
  final double currentQuantity;
  final String unit;
  final double? minThreshold;
  final DateTime? updatedAt;
  final Map<String, dynamic> rawData;

  factory FeedStock.fromMap(Map<String, dynamic> data) {
    return FeedStock(
      id: _readInt(data, const ['id']),
      userId: _readInt(data, const ['user_id', 'userId']),
      farmingCycleId: _readInt(
        data,
        const ['farming_cycle_id', 'farmingCycleId'],
      ),
      currentQuantity:
          _readDouble(data, const ['current_quantity', 'currentQuantity']) ??
              0,
      unit: _readString(data, const ['unit']) ?? 'Kg',
      minThreshold:
          _readDouble(data, const ['min_threshold', 'minThreshold']),
      updatedAt: _readDateTime(data, const ['updated_at', 'updatedAt']),
      rawData: data,
    );
  }

  bool get isLowStock =>
      minThreshold != null && currentQuantity <= minThreshold!;

  double get thresholdProgress {
    final threshold = minThreshold;
    if (threshold == null || threshold <= 0) {
      return 0;
    }

    final ratio = currentQuantity / threshold;
    return ratio.clamp(0.0, 1.0);
  }
}

class FeedStockTransaction {
  const FeedStockTransaction({
    this.id,
    this.feedStockId,
    required this.transactionType,
    required this.quantity,
    this.notes,
    this.previousQuantity,
    this.newQuantity,
    this.createdAt,
    this.rawData = const <String, dynamic>{},
  });

  final int? id;
  final int? feedStockId;
  final String transactionType;
  final double quantity;
  final String? notes;
  final double? previousQuantity;
  final double? newQuantity;
  final DateTime? createdAt;
  final Map<String, dynamic> rawData;

  bool get isUsage => transactionType.trim().toLowerCase() == 'usage';

  bool get isInput => transactionType.trim().toLowerCase() == 'input';

  factory FeedStockTransaction.fromMap(Map<String, dynamic> data) {
    return FeedStockTransaction(
      id: _readInt(data, const ['id']),
      feedStockId: _readInt(data, const ['feed_stock_id', 'feedStockId']),
      transactionType:
          _readString(data, const ['transaction_type', 'transactionType']) ??
              'input',
      quantity: _readDouble(data, const ['quantity']) ?? 0,
      notes: _readString(data, const ['notes']),
      previousQuantity:
          _readDouble(data, const ['previous_quantity', 'previousQuantity']),
      newQuantity: _readDouble(data, const ['new_quantity', 'newQuantity']),
      createdAt: _readDateTime(data, const ['created_at', 'createdAt']),
      rawData: data,
    );
  }
}

class FeedStockUsagePoint {
  const FeedStockUsagePoint({
    required this.label,
    required this.dateLabel,
    required this.quantity,
  });

  final String label;
  final String dateLabel;
  final double quantity;
}

class FeedStockStats {
  const FeedStockStats({
    this.stockId,
    this.currentQuantity,
    this.minThreshold,
    this.unit,
    this.totalInput,
    this.totalUsage,
    this.averageUsage,
    this.maxUsage,
    this.minUsage,
    this.transactionCount,
    this.usageSeries = const <FeedStockUsagePoint>[],
    this.rawData = const <String, dynamic>{},
  });

  final int? stockId;
  final double? currentQuantity;
  final double? minThreshold;
  final String? unit;
  final double? totalInput;
  final double? totalUsage;
  final double? averageUsage;
  final double? maxUsage;
  final double? minUsage;
  final int? transactionCount;
  final List<FeedStockUsagePoint> usageSeries;
  final Map<String, dynamic> rawData;

  factory FeedStockStats.fromMap(Map<String, dynamic> data) {
    return FeedStockStats(
      stockId: _readInt(data, const ['stock_id', 'stockId', 'id']),
      currentQuantity:
          _readDouble(data, const ['current_quantity', 'currentQuantity']),
      minThreshold:
          _readDouble(data, const ['min_threshold', 'minThreshold']),
      unit: _readString(data, const ['unit']),
      totalInput: _readDouble(data, const ['total_input', 'totalInput']),
      totalUsage: _readDouble(data, const ['total_usage', 'totalUsage']),
      averageUsage:
          _readDouble(data, const ['average_usage', 'averageUsage']),
      maxUsage: _readDouble(data, const ['max_usage', 'maxUsage']),
      minUsage: _readDouble(data, const ['min_usage', 'minUsage']),
      transactionCount:
          _readInt(data, const ['transaction_count', 'transactionCount', 'count']),
      usageSeries: StockPakanService._extractUsageSeries(data),
      rawData: data,
    );
  }

  bool get hasUsageSeries => usageSeries.isNotEmpty;
}

class StockPakanService {
  static const String baseUrl = ApiService.baseUrl;
  static const Duration requestTimeout = Duration(seconds: 10);
  static const double maxStockQuantityKg = 20.0;

  static Future<FeedStock?> getRemainingFeedStock({
    int? farmingCycleId,
    Map<String, dynamic>? fallbackData,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedFarmingCycleId =
        farmingCycleId ?? await resolveFarmingCycleId(fallbackData: fallbackData);

    if (resolvedFarmingCycleId == null) {
      throw Exception(
        'farming_cycle_id belum ditemukan. Silakan pilih atau simpan cycle aktif terlebih dahulu.',
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
      '[StockPakanService] GET $resolvedBaseUrl/feed/stocks/$resolvedFarmingCycleId '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/feed/stocks/$resolvedFarmingCycleId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
      ).timeout(requestTimeout);

      debugPrint(
        '[StockPakanService] GET /feed/stocks/$resolvedFarmingCycleId status: ${response.statusCode}',
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
              'Gagal mengambil stok pakan (${response.statusCode})',
        );
      }

      final stocks = _extractStocks(decodedBody);
      if (stocks.isEmpty) {
        return null;
      }

      return _pickLatestStock(stocks);
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

    static Future<FeedStock> updateFeedStockConfig({
      required int stockId,
      double? minThreshold,
      String? unit,
      http.Client? client,
      String? overrideBaseUrl,
      String? authToken,
    }) async {
      final resolvedToken = authToken ?? await _readStoredToken();
      if (resolvedToken == null || resolvedToken.trim().isEmpty) {
        throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
      }

      final payload = <String, dynamic>{
        if (minThreshold != null) 'min_threshold': minThreshold,
        if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
      };

      if (payload.isEmpty) {
        throw Exception('Tidak ada perubahan stok yang dikirim.');
      }

      final httpClient = client ?? http.Client();
      final shouldCloseClient = client == null;
      final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

      debugPrint(
        '[StockPakanService] PATCH $resolvedBaseUrl/feed/stocks/$stockId '
        '(token length: ${resolvedToken.trim().length})',
      );

      try {
        final response = await httpClient
            .patch(
              Uri.parse('$resolvedBaseUrl/feed/stocks/$stockId'),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $resolvedToken',
              },
              body: jsonEncode(payload),
            )
            .timeout(requestTimeout);

        debugPrint(
          '[StockPakanService] PATCH /feed/stocks/$stockId status: ${response.statusCode}',
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
                'Gagal memperbarui konfigurasi stok pakan (${response.statusCode})',
          );
        }

        final updatedStock = _extractStocks(decodedBody);
        if (updatedStock.isEmpty) {
          return FeedStock.fromMap({
            'id': stockId,
            if (minThreshold != null) 'min_threshold': minThreshold,
            if (unit != null && unit.trim().isNotEmpty) 'unit': unit.trim(),
          });
        }

        return updatedStock.first;
      } on TimeoutException {
        throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
      } finally {
        if (shouldCloseClient) {
          httpClient.close();
        }
      }
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
    debugPrint('[StockPakanService] Cleared invalid auth session after 401');
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

  static Future<FeedStockTransaction> createFeedStockTransaction({
    required int stockId,
    required String transactionType,
    required double quantity,
    double? currentQuantity,
    String? notes,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      throw Exception('Token autentikasi tidak ditemukan. Silakan login ulang.');
    }

    final normalizedType = transactionType.trim().toLowerCase();
    if (normalizedType != 'input' && normalizedType != 'usage') {
      throw Exception('transaction_type harus bernilai input atau usage.');
    }

    if (quantity <= 0) {
      throw Exception('quantity harus lebih besar dari 0.');
    }

    if (normalizedType == 'input' && currentQuantity != null) {
      if (currentQuantity >= maxStockQuantityKg) {
        throw Exception('Stok sudah mencapai batas maksimal ${maxStockQuantityKg.toStringAsFixed(0)} kg. Input tidak dapat dilakukan.');
      }

      if (currentQuantity + quantity > maxStockQuantityKg) {
        throw Exception('Total stok setelah input tidak boleh melebihi ${maxStockQuantityKg.toStringAsFixed(0)} kg.');
      }
    }

    final payload = <String, dynamic>{
      'transaction_type': normalizedType,
      'quantity': quantity,
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
    };

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

    debugPrint(
      '[StockPakanService] POST $resolvedBaseUrl/feed/stocks/$stockId/transaction '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient
          .post(
            Uri.parse('$resolvedBaseUrl/feed/stocks/$stockId/transaction'),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $resolvedToken',
            },
            body: jsonEncode(payload),
          )
          .timeout(requestTimeout);

      debugPrint(
        '[StockPakanService] POST /feed/stocks/$stockId/transaction status: ${response.statusCode}',
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
              'Gagal mencatat transaksi stok pakan (${response.statusCode})',
        );
      }

      final transactions = _extractTransactions(decodedBody);
      if (transactions.isNotEmpty) {
        return transactions.first;
      }

      return FeedStockTransaction.fromMap({
        'feed_stock_id': stockId,
        'transaction_type': normalizedType,
        'quantity': quantity,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      });
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<FeedStockStats> getFeedStockStats({
    required int stockId,
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
      '[StockPakanService] GET $resolvedBaseUrl/feed/stocks/$stockId/stats '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/feed/stocks/$stockId/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
      ).timeout(requestTimeout);

      debugPrint(
        '[StockPakanService] GET /feed/stocks/$stockId/stats status: ${response.statusCode}',
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
              'Gagal mengambil statistik stok pakan (${response.statusCode})',
        );
      }

      return _extractStats(decodedBody, fallbackStockId: stockId);
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static List<FeedStockUsagePoint> _extractUsageSeries(Map<String, dynamic> data) {
    final candidates = <Object?>[
      data['usage_series'],
      data['usageSeries'],
      data['daily_usage'],
      data['dailyUsage'],
      data['chart_data'],
      data['chartData'],
      data['series'],
      data['data'],
    ];

    final usagePoints = <FeedStockUsagePoint>[];

    for (final candidate in candidates) {
      if (candidate is List) {
        for (final item in candidate) {
          if (item is Map) {
            final normalized = _normalizeMap(item);
            usagePoints.add(
              FeedStockUsagePoint(
                label: _readString(normalized, const ['label', 'day', 'name']) ?? '-',
                dateLabel: _readString(normalized, const ['date', 'date_label', 'dateLabel']) ?? '-',
                quantity:
                    _readDouble(normalized, const ['quantity', 'usage', 'value', 'total']) ?? 0,
              ),
            );
          } else if (item is num) {
            final today = DateTime.now();
            usagePoints.add(
              FeedStockUsagePoint(
                label: '${today.month}/${today.day}',
                dateLabel: '${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}',
                quantity: item.toDouble(),
              ),
            );
          }
        }
      }
    }

    return usagePoints;
  }

  static Future<List<FeedStockTransaction>> getFeedStockHistory({
    required int stockId,
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
      '[StockPakanService] GET $resolvedBaseUrl/feed/stocks/$stockId/history?limit=$limit '
      '(token length: ${resolvedToken.trim().length})',
    );

    try {
      final historyUri = Uri.parse('$resolvedBaseUrl/feed/stocks/$stockId/history')
          .replace(queryParameters: <String, String>{'limit': limit.toString()});

      final response = await httpClient.get(
        historyUri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $resolvedToken',
        },
      ).timeout(requestTimeout);

      debugPrint(
        '[StockPakanService] GET /feed/stocks/$stockId/history status: ${response.statusCode}',
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
              'Gagal mengambil riwayat stok pakan (${response.statusCode})',
        );
      }

      return _extractTransactions(decodedBody);
    } on TimeoutException {
      throw Exception('Request timeout. Server terlalu lama merespons, coba lagi.');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
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

  static List<FeedStock> _extractStocks(Object? decodedBody) {
    final candidates = <Object?>[];

    if (decodedBody is List) {
      candidates.addAll(decodedBody);
    } else if (decodedBody is Map) {
      final normalized = _normalizeMap(decodedBody);
      final nested = normalized['data'] ??
          normalized['items'] ??
          normalized['results'] ??
          normalized['stocks'];

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
        .map(FeedStock.fromMap)
        .toList();
  }

  static FeedStock _pickLatestStock(List<FeedStock> stocks) {
    stocks.sort((left, right) {
      final leftUpdatedAt = left.updatedAt;
      final rightUpdatedAt = right.updatedAt;

      if (leftUpdatedAt == null && rightUpdatedAt == null) {
        return 0;
      }

      if (leftUpdatedAt == null) {
        return 1;
      }

      if (rightUpdatedAt == null) {
        return -1;
      }

      return rightUpdatedAt.compareTo(leftUpdatedAt);
    });

    return stocks.first;
  }

  static List<FeedStockTransaction> _extractTransactions(Object? decodedBody) {
    final candidates = <Object?>[];

    if (decodedBody is List) {
      candidates.addAll(decodedBody);
    } else if (decodedBody is Map) {
      final normalized = _normalizeMap(decodedBody);
      final nested = normalized['data'] ??
          normalized['items'] ??
          normalized['results'] ??
          normalized['transactions'];

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
        .map(FeedStockTransaction.fromMap)
        .toList();
  }

  static FeedStockStats _extractStats(
    Object? decodedBody, {
    required int fallbackStockId,
  }) {
    final map = decodedBody is Map
        ? _normalizeMap(decodedBody)
        : <String, dynamic>{};

    final nested = map['data'] ?? map['stats'] ?? map['summary'] ?? map['item'];
    if (nested is Map) {
      final normalized = _normalizeMap(nested);
      return FeedStockStats.fromMap({
        ...map,
        ...normalized,
        'id': normalized['id'] ?? fallbackStockId,
      });
    }

    return FeedStockStats.fromMap({
      ...map,
      'id': map['id'] ?? fallbackStockId,
    });
  }

  static int? _extractFarmingCycleIdFromMap(Map<String, dynamic>? map) {
    if (map == null || map.isEmpty) {
      return null;
    }

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
      final parsed = _readIntValue(value);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }
}

Map<String, dynamic> _normalizeMap(Map<dynamic, dynamic> data) {
  return data.map((key, value) => MapEntry(key.toString(), value));
}

int? _readIntValue(Object? value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value.trim());
  }

  return null;
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