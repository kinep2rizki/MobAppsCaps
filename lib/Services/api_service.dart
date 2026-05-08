import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String defaultBaseUrl =
      'https://backend-nila-iot-production.up.railway.app';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static String resolveBaseUrl(String? overrideBaseUrl) {
    final value = overrideBaseUrl?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return baseUrl;
    }

    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Future<List<dynamic>> getSensorData({
    http.Client? client,
    String? overrideBaseUrl,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final resolvedBaseUrl = resolveBaseUrl(overrideBaseUrl);
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/sensor-data/history'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to load data');
      }

      final decodedBody = json.decode(response.body);
      if (decodedBody is List<dynamic>) {
        return decodedBody;
      }

      if (decodedBody is Map && decodedBody['data'] is List<dynamic>) {
        return decodedBody['data'] as List<dynamic>;
      }

      throw Exception('Unexpected response format');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}