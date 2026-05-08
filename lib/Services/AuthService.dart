import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class AuthResult {
  final bool success;
  final String message;
  final String? token;
  final String? refreshToken;
  final String? tokenType;
  final Map<String, dynamic>? user;

  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.refreshToken,
    this.tokenType,
    this.user,
  });
}

class AuthService {
  static const String baseUrl = ApiService.baseUrl;
  static const Duration requestTimeout = Duration(seconds: 20);

  static Future<AuthResult> login({
    required String email,
    required String password,
    http.Client? client,
    String? overrideBaseUrl,
  }) async {
    return _sendAuthRequest(
      path: '/auth/login',
      payload: {
        'email': email,
        'password': password,
      },
      successStatusCodes: const {200},
      defaultSuccessMessage: 'Login berhasil',
      client: client,
      overrideBaseUrl: overrideBaseUrl,
    );
  }

  static Future<AuthResult> register({
    required String address,
    required String email,
    required String fullName,
    required String greenhouseLocation,
    required String password,
    required String phoneNumber,
    http.Client? client,
    String? overrideBaseUrl,
  }) async {
    debugPrint('Register password length: ${password.length}');
    debugPrint('Register password: $password');

    return _sendAuthRequest(
      path: '/auth/register',
      payload: {
        'address': address,
        'email': email,
        'full_name': fullName,
        'greenhouse_location': greenhouseLocation,
        'password': password,
        'phone_number': phoneNumber,
      },
      successStatusCodes: const {200, 201},
      defaultSuccessMessage: 'Pendaftaran berhasil',
      client: client,
      overrideBaseUrl: overrideBaseUrl,
    );
  }

  static Future<AuthResult> _sendAuthRequest({
    required String path,
    required Map<String, dynamic> payload,
    required Set<int> successStatusCodes,
    required String defaultSuccessMessage,
    http.Client? client,
    String? overrideBaseUrl,
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final resolvedBaseUrl = ApiService.resolveBaseUrl(overrideBaseUrl);
      final response = await httpClient.post(
        Uri.parse('$resolvedBaseUrl$path'),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(requestTimeout);

      final decodedBody = _decodeResponseBody(response.body);
      final isSuccess = successStatusCodes.contains(response.statusCode);

      if (!isSuccess) {
        debugPrint(
          'AuthService $path failed with status ${response.statusCode}: '
          '${response.body}',
        );

        return AuthResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Request gagal (${response.statusCode})',
        );
      }

      final responseMap = decodedBody is Map<String, dynamic>
          ? decodedBody
          : <String, dynamic>{};
      final data = _extractDataMap(responseMap);
      final token = _extractToken(responseMap, data);

      return AuthResult(
        success: true,
        message: _extractMessage(responseMap) ?? defaultSuccessMessage,
        token: token,
        refreshToken: _extractRefreshToken(responseMap, data),
        tokenType: _extractTokenType(responseMap, data),
        user: _extractUserMap(responseMap, data),
      );
    } catch (error) {
      if (error is TimeoutException) {
        return const AuthResult(
          success: false,
          message:
              'Request timeout. Server terlalu lama merespons, coba lagi.',
        );
      }

      return AuthResult(
        success: false,
        message: 'Tidak dapat terhubung ke server: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Object? _decodeResponseBody(String body) {
    if (body.isEmpty) {
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
      final String? detailMessage = _extractFastApiDetailMessage(detail);
      if (detailMessage != null) {
        return detailMessage;
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

  static String? _extractFastApiDetailMessage(Object? detail) {
    if (detail == null) {
      return null;
    }

    if (detail is String && detail.trim().isNotEmpty) {
      return detail;
    }

    if (detail is List) {
      final messages = <String>[];

      for (final item in detail) {
        if (item is Map) {
          final dynamic loc = item['loc'];
          final dynamic msg = item['msg'];

          final locText = _formatFastApiLocation(loc);
          final msgText = msg is String ? msg : item.toString();

          if (locText.isNotEmpty) {
            messages.add('$locText: $msgText');
          } else {
            messages.add(msgText);
          }
        } else if (item != null) {
          messages.add(item.toString());
        }
      }

      if (messages.isNotEmpty) {
        return messages.join('; ');
      }
    }

    if (detail is Map && detail.isNotEmpty) {
      return detail.toString();
    }

    return null;
  }

  static String _formatFastApiLocation(Object? loc) {
    if (loc is List && loc.isNotEmpty) {
      return loc.map((part) => part.toString()).join('.');
    }

    if (loc is String) {
      return loc;
    }

    return '';
  }

  static Map<String, dynamic>? _extractDataMap(
      Map<String, dynamic> responseMap) {
    final dynamic data = responseMap['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static String? _extractToken(
    Map<String, dynamic> responseMap,
    Map<String, dynamic>? data,
  ) {
    final candidates = <Object?>[
      responseMap['token'],
      responseMap['access_token'],
      responseMap['accessToken'],
      data?['token'],
      data?['access_token'],
      data?['accessToken'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  static String? _extractRefreshToken(
    Map<String, dynamic> responseMap,
    Map<String, dynamic>? data,
  ) {
    final candidates = <Object?>[
      responseMap['refresh_token'],
      responseMap['refreshToken'],
      data?['refresh_token'],
      data?['refreshToken'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  static String? _extractTokenType(
    Map<String, dynamic> responseMap,
    Map<String, dynamic>? data,
  ) {
    final candidates = <Object?>[
      responseMap['token_type'],
      responseMap['tokenType'],
      data?['token_type'],
      data?['tokenType'],
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  static Map<String, dynamic>? _extractUserMap(
    Map<String, dynamic> responseMap,
    Map<String, dynamic>? data,
  ) {
    final candidates = <Object?>[
      responseMap['user'],
      responseMap['data'],
      data?['user'],
    ];

    for (final candidate in candidates) {
      if (candidate is Map<String, dynamic>) {
        return candidate;
      }
      if (candidate is Map) {
        return Map<String, dynamic>.from(candidate);
      }
    }

    return null;
  }
}
