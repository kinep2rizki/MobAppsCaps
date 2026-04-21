import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

const String notificationBackgroundTaskName =
    'bluvera.notifications.background.sync';
const String notificationBackgroundUniqueName =
    'bluvera.notifications.background.unique';

@pragma('vm:entry-point')
void notificationBackgroundDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await NotificationPopupManager.executeBackgroundSync();
      return true;
    } catch (_) {
      return true;
    }
  });
}

class NotificationApiService {
  static const String baseUrl =
      'https://haematological-jovan-bloomless.ngrok-free.dev';

  static String _resolveBaseUrl(String? overrideBaseUrl) {
    final value = overrideBaseUrl?.trim();
    if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
      return baseUrl;
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static Future<List<AppNotificationItem>> getUnreadNotifications({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/notifications/unread'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load unread notifications');
      }

      return _decodeNotificationList(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<int> getUnreadCount({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/notifications/unread/count'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load unread notification count');
      }

      return _decodeUnreadCount(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<List<AppNotificationItem>> getAllNotifications({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.get(
        Uri.parse('$resolvedBaseUrl/notifications/'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to load notifications');
      }

      return _decodeNotificationList(response.body);
    } on TimeoutException {
      throw Exception('Request timeout');
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  static Future<Map<String, dynamic>> markAsRead({
    required String notificationId,
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.patch(
        Uri.parse('$resolvedBaseUrl/notifications/$notificationId/read'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to mark notification as read');
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

  static Future<Map<String, dynamic>> markAllAsRead({
    http.Client? client,
    String? overrideBaseUrl,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;
    final resolvedBaseUrl = _resolveBaseUrl(overrideBaseUrl);

    try {
      final response = await httpClient.patch(
        Uri.parse('$resolvedBaseUrl/notifications/read-all'),
        headers: const {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Failed to mark all notifications as read');
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

  static List<AppNotificationItem> _decodeNotificationList(
      String responseBody) {
    final decoded = json.decode(responseBody);
    final list = _extractList(decoded);

    return list.map((item) => AppNotificationItem.fromMap(item)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<Map<String, dynamic>> _extractList(dynamic decoded) {
    if (decoded is List) {
      return decoded
          .whereType<Map>()
          .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
          .toList();
    }

    if (decoded is Map<String, dynamic>) {
      final listCandidate =
          decoded['data'] ?? decoded['notifications'] ?? decoded['items'];
      if (listCandidate is List) {
        return listCandidate
            .whereType<Map>()
            .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }

      return [decoded];
    }

    if (decoded is Map) {
      final normalized =
          decoded.map((key, value) => MapEntry(key.toString(), value));
      final listCandidate = normalized['data'] ??
          normalized['notifications'] ??
          normalized['items'];
      if (listCandidate is List) {
        return listCandidate
            .whereType<Map>()
            .map((item) => item.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }

      return [normalized];
    }

    throw Exception('Unexpected response format');
  }

  static int _decodeUnreadCount(String responseBody) {
    final decoded = json.decode(responseBody);

    if (decoded is int) {
      return decoded;
    }

    if (decoded is num) {
      return decoded.toInt();
    }

    if (decoded is String) {
      return int.tryParse(decoded) ?? 0;
    }

    if (decoded is Map<String, dynamic>) {
      final direct =
          decoded['count'] ?? decoded['unread_count'] ?? decoded['total'];
      final count = _toInt(direct);
      if (count != null) {
        return count;
      }

      final data = decoded['data'];
      if (data is Map<String, dynamic>) {
        return _toInt(data['count'] ?? data['unread_count'] ?? data['total']) ??
            0;
      }
      if (data is Map) {
        final normalized =
            data.map((key, value) => MapEntry(key.toString(), value));
        return _toInt(normalized['count'] ??
                normalized['unread_count'] ??
                normalized['total']) ??
            0;
      }
    }

    if (decoded is Map) {
      final normalized =
          decoded.map((key, value) => MapEntry(key.toString(), value));
      return _toInt(normalized['count'] ??
              normalized['unread_count'] ??
              normalized['total']) ??
          0;
    }

    return 0;
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }
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

  static Map<String, dynamic> _decodeMap(String responseBody) {
    final decodedBody = json.decode(responseBody);

    if (decodedBody is Map<String, dynamic>) {
      return decodedBody;
    }

    if (decodedBody is Map) {
      return decodedBody.map((key, value) => MapEntry(key.toString(), value));
    }

    if (decodedBody is List &&
        decodedBody.isNotEmpty &&
        decodedBody.first is Map) {
      final first = decodedBody.first as Map;
      return first.map((key, value) => MapEntry(key.toString(), value));
    }

    return {'success': true};
  }
}

class NotificationPopupManager {
  static const String _pushNotificationsKey = 'pushNotifications';
  static const String _shownNotificationIdsKey = 'shownNotificationIds';
  static const String _cachedUnreadCountKey = 'cachedUnreadNotificationCount';
  static const String _lastUnreadSyncAtKey = 'lastUnreadNotificationSyncAt';
  static const int _maxStoredShownIds = 300;
  static const Duration _foregroundPollingInterval = Duration(seconds: 60);
  static const Duration _unreadListRefreshInterval = Duration(minutes: 5);

  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'bluvera_notification_channel',
    'BluVera Notifications',
    description: 'Popup notifikasi untuk alert dan reminder BluVera.',
    importance: Importance.max,
  );

  static bool _localInitialized = false;
  static bool _workmanagerInitialized = false;
  static bool _isForegroundSyncing = false;
  static Timer? _pollingTimer;
  static Future<void> Function()? _onNotificationTap;
  static DateTime? _lastUnreadListSyncAt;

  static bool get _supportsBackgroundSync =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get _supportsLocalNotifications =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static Future<void> initialize({
    Future<void> Function()? onNotificationTap,
  }) async {
    _onNotificationTap = onNotificationTap;

    final prefs = await SharedPreferences.getInstance();
    unreadCountNotifier.value = prefs.getInt(_cachedUnreadCountKey) ?? 0;
    final lastUnreadSyncMillis = prefs.getInt(_lastUnreadSyncAtKey);
    _lastUnreadListSyncAt = lastUnreadSyncMillis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lastUnreadSyncMillis);

    await _initializeLocalNotifications();
    await _initializeWorkmanager();
    await syncPushStateWithSystemSetting();

    _startForegroundPolling();
    await _foregroundSyncTick();
  }

  static Future<void> _initializeWorkmanager() async {
    if (!_supportsBackgroundSync || _workmanagerInitialized) {
      return;
    }

    try {
      await Workmanager().initialize(
        notificationBackgroundDispatcher,
        isInDebugMode: false,
      );
      _workmanagerInitialized = true;
    } catch (_) {}
  }

  static Future<void> _initializeLocalNotifications() async {
    if (!_supportsLocalNotifications || _localInitialized) {
      return;
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (_) async {
        final handler = _onNotificationTap;
        if (handler != null) {
          await handler();
        }
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(_androidChannel);
      await androidImplementation?.requestNotificationsPermission();
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    _localInitialized = true;
  }

  static Future<void> setPushEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, enabled);

    await _configureBackgroundTask(enabled);

    if (!enabled && _supportsLocalNotifications) {
      await _localNotifications.cancelAll();
    }

    if (enabled) {
      await _foregroundSyncTick();
    }
  }

  static Future<void> syncPushStateWithSystemSetting() async {
    final enabled = await isPushEnabled();
    await _configureBackgroundTask(enabled);
  }

  static Future<bool> isPushEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushNotificationsKey) ?? true;
  }

  static Future<void> _configureBackgroundTask(bool enabled) async {
    if (!_supportsBackgroundSync || !_workmanagerInitialized) {
      return;
    }

    try {
      if (enabled) {
        await Workmanager().registerPeriodicTask(
          notificationBackgroundUniqueName,
          notificationBackgroundTaskName,
          frequency: const Duration(minutes: 15),
          initialDelay: const Duration(minutes: 1),
          existingWorkPolicy: ExistingWorkPolicy.replace,
          constraints: Constraints(networkType: NetworkType.connected),
        );
      } else {
        await Workmanager()
            .cancelByUniqueName(notificationBackgroundUniqueName);
      }
    } catch (_) {}
  }

  static void _startForegroundPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_foregroundPollingInterval, (_) {
      _foregroundSyncTick();
    });
  }

  static Future<void> _foregroundSyncTick() async {
    if (_isForegroundSyncing) {
      return;
    }

    _isForegroundSyncing = true;
    try {
      final previousUnreadCount = unreadCountNotifier.value;
      final currentUnreadCount = await refreshUnreadCount();
      final pushEnabled = await isPushEnabled();

      if (pushEnabled &&
          _shouldRefreshUnreadList(
            previousUnreadCount: previousUnreadCount,
            currentUnreadCount: currentUnreadCount,
          )) {
        await _showNewUnreadNotifications();
      }
    } finally {
      _isForegroundSyncing = false;
    }
  }

  static Future<int> refreshUnreadCount() async {
    try {
      final count = await NotificationApiService.getUnreadCount();
      unreadCountNotifier.value = count;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_cachedUnreadCountKey, count);

      return count;
    } catch (_) {
      return unreadCountNotifier.value;
    }
  }

  static Future<void> _showNewUnreadNotifications() async {
    await _initializeLocalNotifications();
    if (!_supportsLocalNotifications) {
      return;
    }

    final unreadNotifications =
        await NotificationApiService.getUnreadNotifications();
    if (unreadNotifications.isEmpty) {
      return;
    }

    final shownIds = await _loadShownNotificationIds();

    final latestNotification = unreadNotifications.first;
    if (shownIds.contains(latestNotification.id)) {
      await _markUnreadListSynced();
      return;
    }

    await _showSystemNotification(latestNotification);
    shownIds.add(latestNotification.id);

    await _saveShownNotificationIds(shownIds);
    await _markUnreadListSynced();
  }

  static Future<void> _showSystemNotification(
    AppNotificationItem notification,
  ) async {
    final id = notification.id.hashCode & 0x7fffffff;

    final androidDetails = AndroidNotificationDetails(
      _androidChannel.id,
      _androidChannel.name,
      channelDescription: _androidChannel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      ticker: 'BluVera notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      notification.title,
      notification.message,
      details,
      payload: notification.id,
    );
  }

  static Future<void> executeBackgroundSync() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (!await isPushEnabled()) {
      return;
    }

    final previousUnreadCount = unreadCountNotifier.value;
    final currentUnreadCount = await refreshUnreadCount();

    if (_shouldRefreshUnreadList(
      previousUnreadCount: previousUnreadCount,
      currentUnreadCount: currentUnreadCount,
    )) {
      await _showNewUnreadNotifications();
    }
  }

  static Future<void> handleLaunchNotificationTap() async {
    if (!_supportsLocalNotifications) {
      return;
    }

    final launchDetails =
        await _localNotifications.getNotificationAppLaunchDetails();

    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final handler = _onNotificationTap;
      if (handler != null) {
        await handler();
      }
    }
  }

  static Future<Set<String>> _loadShownNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final values = prefs.getStringList(_shownNotificationIdsKey) ?? const [];
    return values.toSet();
  }

  static Future<void> _saveShownNotificationIds(Set<String> values) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = values.toList()..sort();

    final trimmed = sorted.length > _maxStoredShownIds
        ? sorted.sublist(sorted.length - _maxStoredShownIds)
        : sorted;

    await prefs.setStringList(_shownNotificationIdsKey, trimmed);
  }

  static bool _shouldRefreshUnreadList({
    required int previousUnreadCount,
    required int currentUnreadCount,
  }) {
    if (currentUnreadCount <= 0) {
      return false;
    }

    if (currentUnreadCount > previousUnreadCount) {
      return true;
    }

    return _lastUnreadListSyncAt == null ||
        DateTime.now().difference(_lastUnreadListSyncAt!) >=
            _unreadListRefreshInterval;
  }

  static Future<void> _markUnreadListSynced() async {
    _lastUnreadListSyncAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastUnreadSyncAtKey,
      _lastUnreadListSyncAt!.millisecondsSinceEpoch,
    );
  }
}

class AppNotificationItem {
  AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
  });

  factory AppNotificationItem.fromMap(Map<String, dynamic> raw) {
    final normalized = raw.map((key, value) => MapEntry(key.toString(), value));

    final title = _readString(
      normalized,
      ['title', 'subject', 'name', 'type'],
      fallback: 'Notifikasi Baru',
    );
    final message = _readString(
      normalized,
      ['message', 'body', 'description', 'detail', 'text'],
      fallback: 'Anda memiliki notifikasi baru dari sistem.',
    );
    final id = _readString(
      normalized,
      ['id', 'notif_id', 'notification_id', 'uuid'],
      fallback: '${title}_${message}_${DateTime.now().millisecondsSinceEpoch}',
    );

    final type = _readString(
      normalized,
      ['type', 'category', 'kind'],
      fallback: 'general',
    );

    final createdAt = _readDate(
          normalized,
          ['created_at', 'timestamp', 'time', 'published_at', 'updated_at'],
        ) ??
        DateTime.now();

    return AppNotificationItem(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: _resolveReadState(normalized),
      type: type,
    );
  }

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type;

  AppNotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? type,
  }) {
    return AppNotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
    );
  }

  String get relativeTime {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.isNegative || diff.inMinutes < 1) {
      return 'Baru saja';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }
    if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()} minggu lalu';
    }
    return '${(diff.inDays / 30).floor()} bulan lalu';
  }

  String get displayTypeLabel {
    final normalized = type.trim().toLowerCase();

    if (normalized.isEmpty ||
        normalized == 'general' ||
        normalized == 'notification' ||
        normalized == 'notif') {
      return 'Notifikasi';
    }

    if (normalized.contains('alert') || normalized.contains('peringatan')) {
      return 'Alert';
    }

    if (normalized.contains('reminder') || normalized.contains('jadwal')) {
      return 'Reminder';
    }

    if (normalized.contains('warning')) {
      return 'Peringatan';
    }

    return normalized
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  static bool _resolveReadState(Map<String, dynamic> source) {
    final directRead = source['is_read'] ?? source['read'];
    if (directRead is bool) {
      return directRead;
    }
    if (directRead is num) {
      return directRead != 0;
    }
    if (directRead is String) {
      final value = directRead.trim().toLowerCase();
      if (value == 'true' || value == '1' || value == 'read') {
        return true;
      }
      if (value == 'false' || value == '0' || value == 'unread') {
        return false;
      }
    }

    final status = source['status']?.toString().toLowerCase();
    if (status == 'read') {
      return true;
    }

    return source['read_at'] != null;
  }

  static String _readString(
    Map<String, dynamic> source,
    List<String> keys, {
    required String fallback,
  }) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') {
        continue;
      }
      return text;
    }

    return fallback;
  }

  static DateTime? _readDate(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
      if (value == null) {
        continue;
      }

      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') {
        continue;
      }

      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return parsed.toLocal();
      }
    }

    return null;
  }
}
