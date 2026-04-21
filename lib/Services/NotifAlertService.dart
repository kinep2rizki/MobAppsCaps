import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotifAlertService {
  static const String baseUrl =
      'https://haematological-jovan-bloomless.ngrok-free.dev';

  static const List<String> _notificationSettingsPaths = [
    '/alerts/settings',
    '/alerts/preferences',
    '/notifications/settings',
  ];

  static String _resolveBaseUrl(String? overrideBaseUrl) {
    final value = overrideBaseUrl?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return baseUrl;
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static List<Map<String, dynamic>> _decodeAlertList(String responseBody) {
    final decodedBody = json.decode(responseBody);

    if (decodedBody is List) {
      return decodedBody
          .whereType<Map>()
          .map((item) => _normalizeAlertMap(item))
          .toList();
    }

    if (decodedBody is Map<String, dynamic>) {
      final listCandidate = decodedBody['data'] ?? decodedBody['alerts'];
      if (listCandidate is List) {
        return listCandidate
            .whereType<Map>()
            .map((item) => _normalizeAlertMap(item))
            .toList();
      }

      return [_normalizeAlertMap(decodedBody)];
    }

    if (decodedBody is Map) {
      final normalized = decodedBody.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final listCandidate = normalized['data'] ?? normalized['alerts'];
      if (listCandidate is List) {
        return listCandidate
            .whereType<Map>()
            .map((item) => _normalizeAlertMap(item))
            .toList();
      }

      return [_normalizeAlertMap(normalized)];
    }

    throw Exception('Unexpected response format');
  }

  static Map<String, dynamic> _decodeMap(String responseBody) {
    final decodedBody = json.decode(responseBody);

    if (decodedBody is Map<String, dynamic>) {
      return _normalizeAlertMap(decodedBody);
    }

    if (decodedBody is Map) {
      return _normalizeAlertMap(decodedBody);
    }

    if (decodedBody is List &&
        decodedBody.isNotEmpty &&
        decodedBody.first is Map) {
      final first = decodedBody.first as Map;
      return _normalizeAlertMap(first);
    }

    return {'success': true};
  }

  static Map<String, dynamic> _extractSettingsMap(String responseBody) {
    final decoded = _decodeMap(responseBody);

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }

    final settings = decoded['settings'];
    if (settings is Map<String, dynamic>) {
      return settings;
    }
    if (settings is Map) {
      return settings.map((key, value) => MapEntry(key.toString(), value));
    }

    final preferences = decoded['preferences'];
    if (preferences is Map<String, dynamic>) {
      return preferences;
    }
    if (preferences is Map) {
      return preferences.map((key, value) => MapEntry(key.toString(), value));
    }

    return decoded;
  }

  static Map<String, dynamic> _normalizeAlertMap(Map rawAlert) {
    final normalized =
        rawAlert.map((key, value) => MapEntry(key.toString(), value));
    final resolvedState = _resolveAlertState(normalized);
    if (resolvedState != null) {
      normalized['state'] = resolvedState;
    }
    return normalized;
  }

  static String? _resolveAlertState(Map<String, dynamic> alert) {
    final stateRaw =
        (alert['state'] ?? alert['status'])?.toString().toLowerCase();
    if (stateRaw == 'active') {
      return 'active';
    }
    if (stateRaw == 'resolved' || stateRaw == 'dismissed') {
      return 'resolved';
    }

    if (alert['resolved_at'] != null || alert['is_resolved'] == true) {
      return 'resolved';
    }
    if (alert['is_active'] == true) {
      return 'active';
    }
    if (alert['is_active'] == false) {
      return 'resolved';
    }

    return null;
  }

  static Future<List<Map<String, dynamic>>> getActiveAlerts({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/alerts/active'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load active alerts');
      }

      return _decodeAlertList(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<List<Map<String, dynamic>>> getAlertHistory({
    http.Client? client,
    String? overrideBaseUrl,
    String? period,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    final historyUri = Uri.parse('$resolvedBaseUrl/alerts/history').replace(
      queryParameters: period == null || period.trim().isEmpty
          ? null
          : {'period': period.trim()},
    );

    try {
      final response = await httpClient.get(
        historyUri,
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load alert history');
      }

      return _decodeAlertList(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<Map<String, dynamic>> resolveAlert({
    required String alertId,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.patch(
        Uri.parse('$resolvedBaseUrl/alerts/$alertId/resolve'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to resolve alert');
      }

      if (response.body.trim().isEmpty) {
        return {'success': true, 'state': 'resolved'};
      }

      return _decodeMap(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<Map<String, dynamic>> resolveAllAlerts({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.patch(
        Uri.parse('$resolvedBaseUrl/alerts/resolve-all'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to resolve all alerts');
      }

      if (response.body.trim().isEmpty) {
        return {'success': true};
      }

      return _decodeMap(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<Map<String, dynamic>> getNotificationSettings({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      Exception? lastException;

      for (final path in _notificationSettingsPaths) {
        final uri = Uri.parse('$resolvedBaseUrl$path');

        try {
          final response = await httpClient.get(
            uri,
            headers: const {'Accept': 'application/json'},
          ).timeout(timeout);

          if (response.statusCode == 200) {
            return _extractSettingsMap(response.body);
          }

          if (response.statusCode == 404 || response.statusCode == 405) {
            continue;
          }

          lastException = Exception(
            'Failed to load notification settings (${response.statusCode})',
          );
        } on TimeoutException {
          lastException = Exception('Request timeout');
        }
      }

      throw lastException ?? Exception('Failed to load notification settings');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<Map<String, dynamic>> updateNotificationSettings({
    required Map<String, dynamic> settings,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);
    final payload = json.encode(settings);

    try {
      Exception? lastException;

      for (final path in _notificationSettingsPaths) {
        final uri = Uri.parse('$resolvedBaseUrl$path');

        for (final method in ['PATCH', 'PUT']) {
          try {
            final response = await (method == 'PATCH'
                    ? httpClient.patch(
                        uri,
                        headers: const {
                          'Accept': 'application/json',
                          'Content-Type': 'application/json',
                        },
                        body: payload,
                      )
                    : httpClient.put(
                        uri,
                        headers: const {
                          'Accept': 'application/json',
                          'Content-Type': 'application/json',
                        },
                        body: payload,
                      ))
                .timeout(timeout);

            if (response.statusCode >= 200 && response.statusCode < 300) {
              if (response.body.trim().isEmpty) {
                return {'success': true};
              }
              return _decodeMap(response.body);
            }

            if (response.statusCode == 404 || response.statusCode == 405) {
              continue;
            }

            lastException = Exception(
              'Failed to update notification settings (${response.statusCode})',
            );
          } on TimeoutException {
            lastException = Exception('Request timeout');
          }
        }
      }

      throw lastException ??
          Exception('Failed to update notification settings');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }
}
