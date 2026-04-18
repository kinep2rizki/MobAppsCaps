import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AnalyticsService {
  static const String baseUrl =
      'https://haematological-jovan-bloomless.ngrok-free.dev';

  static String _resolveBaseUrl(String? overrideBaseUrl) {
    final value = overrideBaseUrl?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return baseUrl;
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Future<Map<String, dynamic>> getLatestPrediction({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

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
}
