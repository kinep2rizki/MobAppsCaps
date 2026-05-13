import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'api_service.dart';

class ControlService {
  static const String baseUrl = ApiService.baseUrl;

  static String _resolveBaseUrl(String? overrideBaseUrl) {
    return ApiService.resolveBaseUrl(overrideBaseUrl);
  }

  static String normalizeMode(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return 'manual';
    }
    if (normalized == 'otomatis' ||
        normalized == 'auto' ||
        normalized == 'automatic') {
      return 'auto';
    }
    return 'manual';
  }

  static bool normalizeIsActive(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) {
      return false;
    }

    return normalized == 'true' ||
        normalized == '1' ||
        normalized == 'aktif' ||
        normalized == 'on' ||
        normalized == 'running';
  }

  static String normalizeStatus(dynamic value) {
    if (value is bool) {
      return value ? 'Aktif' : 'Nonaktif';
    }

    if (value is num) {
      return value != 0 ? 'Aktif' : 'Nonaktif';
    }

    final normalized = value?.toString().trim();
    if (normalized == null || normalized.isEmpty) {
      return 'Tidak diketahui';
    }

    final lower = normalized.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'aktif' || lower == 'on') {
      return 'Aktif';
    }
    if (lower == 'false' ||
        lower == '0' ||
        lower == 'nonaktif' ||
        lower == 'off') {
      return 'Nonaktif';
    }

    return normalized;
  }

  static Future<ActuatorSnapshot> getActuatorStatus({
    required String deviceName,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse(
            '$resolvedBaseUrl/actuator/status/${Uri.encodeComponent(deviceName)}'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat status aktuator');
      }

      return _snapshotFromResponse(
        response.body,
        fallbackDeviceName: deviceName,
      );
    } on TimeoutException {
      throw Exception('Permintaan status aktuator timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<List<ActuatorSnapshot>> getAllActuatorStatus({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/actuator/status'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat status semua aktuator');
      }

      return _snapshotListFromResponse(response.body);
    } on TimeoutException {
      throw Exception('Permintaan status semua aktuator timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<ActuatorSnapshot> updateActuatorMode({
    required String deviceName,
    required String mode,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);
    final normalizedMode = normalizeMode(mode);

    try {
      final response = await httpClient.patch(
        Uri.parse(
          '$resolvedBaseUrl/actuator/mode/${Uri.encodeComponent(deviceName)}',
        ).replace(queryParameters: <String, String>{'mode': normalizedMode}),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal mengubah mode aktuator');
      }

      return getActuatorStatus(
        deviceName: deviceName,
        client: httpClient,
        overrideBaseUrl: resolvedBaseUrl,
        timeout: timeout,
      );
    } on TimeoutException {
      throw Exception('Permintaan ubah mode timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<ActuatorSnapshot> controlActuator({
    required String deviceName,
    required String action,
    String triggeredBy = 'manual',
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient
          .post(
            Uri.parse('$resolvedBaseUrl/actuator/control'),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(<String, dynamic>{
              'device_name': deviceName,
              'action': action,
              'triggered_by': triggeredBy,
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Gagal mengontrol aktuator');
      }

      return _snapshotFromResponse(
        response.body,
        fallbackDeviceName: deviceName,
      );
    } on TimeoutException {
      throw Exception('Permintaan kontrol aktuator timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static ActuatorSnapshot _snapshotFromResponse(String body,
      {required String fallbackDeviceName}) {
    final decoded = jsonDecode(body);
    if (decoded is List) {
      if (decoded.isEmpty) {
        throw Exception('Data aktuator kosong');
      }

      final first = decoded.first;
      if (first is Map<String, dynamic>) {
        return _snapshotFromMap(first, fallbackDeviceName: fallbackDeviceName);
      }

      if (first is Map) {
        return _snapshotFromMap(
          first.map((key, value) => MapEntry(key.toString(), value)),
          fallbackDeviceName: fallbackDeviceName,
        );
      }

      throw Exception('Format list respons aktuator tidak dikenali');
    }

    if (decoded is Map<String, dynamic>) {
      return _snapshotFromMap(decoded, fallbackDeviceName: fallbackDeviceName);
    }

    if (decoded is Map) {
      return _snapshotFromMap(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
        fallbackDeviceName: fallbackDeviceName,
      );
    }

    throw Exception('Format respons aktuator tidak dikenali');
  }

  static ActuatorSnapshot _snapshotFromMap(
    Map<String, dynamic> data, {
    required String fallbackDeviceName,
  }) {
    String? readString(List<String> keys) {
      for (final key in keys) {
        final value = data[key];
        if (value != null) {
          return value.toString();
        }
      }
      return null;
    }

    dynamic readValue(List<String> keys) {
      for (final key in keys) {
        if (data.containsKey(key)) {
          return data[key];
        }
      }
      return null;
    }

    final mode = normalizeMode(
        readString(const ['mode', 'actuator_mode', 'current_mode']));
    final isActive =
        normalizeIsActive(readValue(const ['is_active', 'active', 'status']));

    return ActuatorSnapshot(
      id: readString(const ['id']),
      deviceName: readString(const ['device_name', 'deviceName', 'name']) ??
          fallbackDeviceName,
      mode: mode,
      isActive: isActive,
      status:
          normalizeStatus(readValue(const ['is_active', 'active', 'status'])),
      updatedAt: readString(const ['updated_at', 'updatedAt']),
      note: readString(const ['message', 'note', 'detail']),
      rawData: data,
    );
  }

  static List<ActuatorSnapshot> _snapshotListFromResponse(String body) {
    final decoded = jsonDecode(body);

    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map(
            (item) => _snapshotFromMap(
              item.map((key, value) => MapEntry(key.toString(), value)),
              fallbackDeviceName: item['device_name']?.toString() ??
                  item['deviceName']?.toString() ??
                  item['name']?.toString() ??
                  'unknown',
            ),
          )
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final nested = decoded['data'] ?? decoded['actuators'] ?? decoded['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map(
              (item) => _snapshotFromMap(
                item.map((key, value) => MapEntry(key.toString(), value)),
                fallbackDeviceName: item['device_name']?.toString() ??
                    item['deviceName']?.toString() ??
                    item['name']?.toString() ??
                    'unknown',
              ),
            )
            .toList();
      }
    }

    if (decoded is Map) {
      final normalized = decoded.map(
        (key, value) => MapEntry(key.toString(), value),
      );
      final nested = normalized['data'] ??
          normalized['actuators'] ??
          normalized['items'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map(
              (item) => _snapshotFromMap(
                item.map((key, value) => MapEntry(key.toString(), value)),
                fallbackDeviceName: item['device_name']?.toString() ??
                    item['deviceName']?.toString() ??
                    item['name']?.toString() ??
                    'unknown',
              ),
            )
            .toList();
      }
    }

    throw Exception('Format respons status aktuator tidak dikenali');
  }
}

class ActuatorSnapshot {
  const ActuatorSnapshot({
    this.id,
    required this.deviceName,
    required this.mode,
    required this.isActive,
    required this.status,
    this.updatedAt,
    this.note,
    this.rawData = const <String, dynamic>{},
  });

  final String? id;
  final String deviceName;
  final String mode;
  final bool isActive;
  final String status;
  final String? updatedAt;
  final String? note;
  final Map<String, dynamic> rawData;
}
