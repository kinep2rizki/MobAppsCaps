import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'AuthSessionService.dart';
import 'api_service.dart';

class ProfileUser {
  final int? id;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? greenhouseLocation;
  final String? address;
  final String? profilePhotoUrl;
  final DateTime? createdAt;

  const ProfileUser({
    this.id,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.greenhouseLocation,
    this.address,
    this.profilePhotoUrl,
    this.createdAt,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: _asInt(json['id']),
      email: _asString(json['email']),
      fullName: _asString(json['full_name'] ?? json['fullName']),
      phoneNumber: _asString(json['phone_number'] ?? json['phoneNumber']),
      greenhouseLocation:
          _asString(json['greenhouse_location'] ?? json['greenhouseLocation']),
      address: _asString(json['address']),
      profilePhotoUrl:
          _asString(json['profile_photo_url'] ?? json['profilePhotoUrl']),
      createdAt: _asDateTime(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (greenhouseLocation != null) 'greenhouse_location': greenhouseLocation,
      if (address != null) 'address': address,
      if (profilePhotoUrl != null) 'profile_photo_url': profilePhotoUrl,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  static String? _asString(Object? value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

class ProfileResult {
  final bool success;
  final String message;
  final ProfileUser? profile;

  const ProfileResult({
    required this.success,
    required this.message,
    this.profile,
  });
}

class ProfileService {
  static const String baseUrl = ApiService.baseUrl;
  static const Duration requestTimeout = Duration(seconds: 20);
  static const String _cachedProfileKey = 'cachedProfile';

  static Future<void> saveCachedProfile(ProfileUser? profile) async {
    final prefs = await SharedPreferences.getInstance();
    if (profile == null) {
      await prefs.remove(_cachedProfileKey);
      return;
    }

    await prefs.setString(_cachedProfileKey, jsonEncode(profile.toJson()));
  }

  static Future<ProfileUser?> getCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final rawProfile = prefs.getString(_cachedProfileKey);
    if (rawProfile == null || rawProfile.trim().isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is Map<String, dynamic>) {
        return ProfileUser.fromJson(decoded);
      }
      if (decoded is Map) {
        return ProfileUser.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  static Future<void> clearCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedProfileKey);
  }

  static Future<void> saveCachedProfileFromMap(
    Map<String, dynamic>? profileMap,
  ) async {
    if (profileMap == null || profileMap.isEmpty) {
      return;
    }

    await saveCachedProfile(ProfileUser.fromJson(profileMap));
  }

  static Future<ProfileResult> changePassword({
    required String oldPassword,
    required String newPassword,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      return const ProfileResult(
        success: false,
        message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
    }

    final queryParameters = <String, String>{
      'old_password': oldPassword.trim(),
      'new_password': newPassword.trim(),
    };

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await AuthSessionService.performWithAutoRefresh(
        client: httpClient,
        overrideBaseUrl: overrideBaseUrl,
        authToken: resolvedToken,
        timeout: requestTimeout,
        request: (token) {
          return httpClient
              .put(
                Uri.parse(
                        '${_resolveBaseUrl(overrideBaseUrl)}/users/change-password')
                    .replace(queryParameters: queryParameters),
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(requestTimeout);
        },
      );

      final decodedBody = _decodeResponseBody(response.body);

      if (response.statusCode != 200) {
        debugPrint(
          'ProfileService PUT /users/change-password failed with status ${response.statusCode}: '
          '${response.body}',
        );

        return ProfileResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Gagal mengubah password (${response.statusCode})',
        );
      }

      final responseMap = _extractMap(decodedBody);

      return ProfileResult(
        success: true,
        message: _extractMessage(responseMap) ?? 'Password berhasil diubah',
      );
    } on TimeoutException {
      return const ProfileResult(
        success: false,
        message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
      );
    } catch (error) {
      return ProfileResult(
        success: false,
        message: 'Tidak dapat mengubah password: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<ProfileResult> uploadProfilePhoto({
    required File photoFile,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      return const ProfileResult(
        success: false,
        message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await AuthSessionService.performWithAutoRefresh(
        client: httpClient,
        overrideBaseUrl: overrideBaseUrl,
        authToken: resolvedToken,
        timeout: requestTimeout,
        request: (token) async {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('${_resolveBaseUrl(overrideBaseUrl)}/auth/upload-photo'),
          )
            ..headers.addAll({
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            })
            ..files.add(
              await http.MultipartFile.fromPath('file', photoFile.path),
            );

          final streamedResponse = await httpClient.send(request).timeout(
                requestTimeout,
              );
          return http.Response.fromStream(streamedResponse);
        },
      );
      final decodedBody = _decodeResponseBody(response.body);

      if (response.statusCode != 200) {
        debugPrint(
          'ProfileService POST /auth/upload-photo failed with status ${response.statusCode}: '
          '${response.body}',
        );

        return ProfileResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Gagal mengupload foto profile (${response.statusCode})',
        );
      }

      final responseMap = _extractMap(decodedBody);
      final profileMap = _extractProfileMap(responseMap);
      final profile = profileMap == null ? null : ProfileUser.fromJson(profileMap);

      if (profile != null) {
        await saveCachedProfile(profile);
      }

      return ProfileResult(
        success: true,
        message:
            _extractMessage(responseMap) ?? 'Foto profile berhasil diperbarui',
        profile: profile,
      );
    } on TimeoutException {
      return const ProfileResult(
        success: false,
        message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
      );
    } catch (error) {
      return ProfileResult(
        success: false,
        message: 'Tidak dapat mengupload foto profile: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<ProfileResult> updateMyProfile({
    required String fullName,
    required String phoneNumber,
    required String greenhouseLocation,
    required String address,
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
  }) async {
    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      return const ProfileResult(
        success: false,
        message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
    }

    final payload = <String, dynamic>{
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'greenhouse_location': greenhouseLocation.trim(),
      'address': address.trim(),
    };

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await AuthSessionService.performWithAutoRefresh(
        client: httpClient,
        overrideBaseUrl: overrideBaseUrl,
        authToken: resolvedToken,
        timeout: requestTimeout,
        request: (token) {
          return httpClient
              .put(
                Uri.parse('${_resolveBaseUrl(overrideBaseUrl)}/auth/me'),
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

      final decodedBody = _decodeResponseBody(response.body);

      if (response.statusCode != 200) {
        debugPrint(
          'ProfileService PUT /auth/me failed with status ${response.statusCode}: '
          '${response.body}',
        );

        return ProfileResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Gagal memperbarui profile (${response.statusCode})',
        );
      }

      final responseMap = _extractMap(decodedBody);
      final profileMap = _extractProfileMap(responseMap);
      final profile = profileMap == null ? null : ProfileUser.fromJson(profileMap);

      if (profile != null) {
        await saveCachedProfile(profile);
      }

      return ProfileResult(
        success: true,
        message: _extractMessage(responseMap) ?? 'Profile berhasil diperbarui',
        profile: profile,
      );
    } on TimeoutException {
      return const ProfileResult(
        success: false,
        message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
      );
    } catch (error) {
      return ProfileResult(
        success: false,
        message: 'Tidak dapat memperbarui profile: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<ProfileResult> getMyProfile({
    http.Client? client,
    String? overrideBaseUrl,
    String? authToken,
    bool useCache = true,
  }) async {
    if (useCache) {
      final cachedProfile = await getCachedProfile();
      if (cachedProfile != null) {
        return ProfileResult(
          success: true,
          message: 'Profile berhasil dimuat dari cache',
          profile: cachedProfile,
        );
      }
    }

    final resolvedToken = authToken ?? await _readStoredToken();
    if (resolvedToken == null || resolvedToken.trim().isEmpty) {
      return const ProfileResult(
        success: false,
        message: 'Token autentikasi tidak ditemukan. Silakan login ulang.',
      );
    }

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final response = await AuthSessionService.performWithAutoRefresh(
        client: httpClient,
        overrideBaseUrl: overrideBaseUrl,
        authToken: resolvedToken,
        timeout: requestTimeout,
        request: (token) {
          return httpClient
              .get(
                Uri.parse('${_resolveBaseUrl(overrideBaseUrl)}/auth/me'),
                headers: {
                  'Accept': 'application/json',
                  'Authorization': 'Bearer $token',
                },
              )
              .timeout(requestTimeout);
        },
      );

      final decodedBody = _decodeResponseBody(response.body);

      if (response.statusCode != 200) {
        debugPrint(
          'ProfileService /auth/me failed with status ${response.statusCode}: '
          '${response.body}',
        );

        return ProfileResult(
          success: false,
          message: _extractMessage(decodedBody) ??
              'Gagal mengambil profile (${response.statusCode})',
        );
      }

      final responseMap = _extractMap(decodedBody);
      final profileMap = _extractProfileMap(responseMap);

      if (profileMap == null) {
        return const ProfileResult(
          success: false,
          message: 'Format respons profile tidak sesuai.',
        );
      }

      final profile = ProfileUser.fromJson(profileMap);
      await saveCachedProfile(profile);

      return ProfileResult(
        success: true,
        message: _extractMessage(responseMap) ?? 'Profile berhasil dimuat',
        profile: profile,
      );
    } on TimeoutException {
      return const ProfileResult(
        success: false,
        message: 'Request timeout. Server terlalu lama merespons, coba lagi.',
      );
    } catch (error) {
      return ProfileResult(
        success: false,
        message: 'Tidak dapat mengambil profile: $error',
      );
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static String _resolveBaseUrl(String? overrideBaseUrl) {
    return ApiService.resolveBaseUrl(overrideBaseUrl);
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

  static Map<String, dynamic> _extractMap(Object? decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      return decodedBody;
    }
    if (decodedBody is Map) {
      return Map<String, dynamic>.from(decodedBody);
    }
    return <String, dynamic>{};
  }

  static Map<String, dynamic>? _extractProfileMap(
    Map<String, dynamic> responseMap,
  ) {
    final candidates = <Object?>[
      responseMap,
      responseMap['data'],
      responseMap['user'],
      responseMap['profile'],
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
}
