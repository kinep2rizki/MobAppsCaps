import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AnalyticsService {
  static const String baseUrl = ApiService.baseUrl;

  static Future<List<Map<String, dynamic>>> getPredictions({
    int? limit = 50,
    int? offset = 0,
    String? status,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _fetchPredictionList(
      endpoint: '/predictions/',
      limit: limit,
      offset: offset,
      status: status,
      client: client,
      overrideBaseUrl: overrideBaseUrl,
      timeout: timeout,
    );
  }

  static Future<List<Map<String, dynamic>>> getPredictionHistory({
    int? limit = 15,
    int? offset = 0,
    String? status,
    String? period,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return _fetchPredictionList(
      endpoint: '/predictions/history',
      limit: limit,
      offset: offset,
      status: status,
      period: period,
      client: client,
      overrideBaseUrl: overrideBaseUrl,
      timeout: timeout,
    );
  }

  static Future<Map<String, dynamic>> getLatestPrediction({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/predictions/latest'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load latest prediction data');
      }

      final decodedBody = json.decode(response.body);

      if (decodedBody is Map<String, dynamic>) {
        return decodedBody;
      }

      if (decodedBody is Map) {
        return decodedBody.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }

      if (decodedBody is List &&
          decodedBody.isNotEmpty &&
          decodedBody.first is Map) {
        final first = decodedBody.first as Map;
        return first.map((key, value) => MapEntry(key.toString(), value));
      }

      throw Exception('Unexpected response format');
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static List<Map<String, dynamic>> _extractPredictionItems(Object? decodedBody) {
    final candidates = <Object?>[];

    if (decodedBody is List) {
      candidates.addAll(decodedBody);
    } else if (decodedBody is Map) {
      final normalized = decodedBody.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final nested = normalized['data'] ??
          normalized['results'] ??
          normalized['items'] ??
          normalized['predictions'];

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
        .map(
          (item) => item.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();
  }

  static Future<List<Map<String, dynamic>>> _fetchPredictionList({
    required String endpoint,
    int? limit,
    int? offset,
    String? status,
    String? period,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);

    try {
      final queryParameters = <String, String>{};

      if (limit != null) {
        queryParameters['limit'] = limit.toString();
      }

      if (offset != null) {
        queryParameters['offset'] = offset.toString();
      }

      final normalizedStatus = status?.trim();
      if (normalizedStatus != null && normalizedStatus.isNotEmpty) {
        queryParameters['status'] = normalizedStatus;
      }

      final normalizedPeriod = period?.trim();
      if (normalizedPeriod != null && normalizedPeriod.isNotEmpty) {
        queryParameters['period'] = normalizedPeriod;
      }

      final uri = Uri.parse('$resolvedBaseUrl$endpoint').replace(
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );

      final response = await httpClient
          .get(
            uri,
            headers: const {'Accept': 'application/json'},
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load predictions data');
      }

      final decodedBody = json.decode(response.body);
      final items = _extractPredictionItems(decodedBody);

      if (items.isEmpty) {
        return const [];
      }

      return items;
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}