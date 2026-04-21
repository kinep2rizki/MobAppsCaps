// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:my_app/Services/NotificationService.dart';

class PopupNotifPage extends StatefulWidget {
  const PopupNotifPage({super.key});

  @override
  State<PopupNotifPage> createState() => _PopupNotifPageState();
}

class _PopupNotifPageState extends State<PopupNotifPage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF4B5563);
  static const Color _muted = Color(0xFF6B7280);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _danger = Color(0xFFDC2626);

  List<AppNotificationItem> _notifications = <AppNotificationItem>[];
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _errorMessage;

  int get _unreadCount => _notifications.where((item) => !item.isRead).length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final items = await NotificationApiService.getAllNotifications();

      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = items;
        _isLoading = false;
        _errorMessage = null;
      });

      await NotificationPopupManager.refreshUnreadCount();
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
        _errorMessage =
            'Gagal memuat notifikasi. Tarik ke bawah untuk mencoba lagi.';
      });
    }
  }

  Future<void> _markAsRead(AppNotificationItem item) async {
    if (item.isRead) {
      return;
    }

    try {
      await NotificationApiService.markAsRead(notificationId: item.id);
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map(
              (entry) =>
                  entry.id == item.id ? entry.copyWith(isRead: true) : entry,
            )
            .toList();
      });

      await NotificationPopupManager.refreshUnreadCount();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Gagal menandai notifikasi sebagai dibaca')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll || _unreadCount == 0) {
      return;
    }

    setState(() => _isMarkingAll = true);

    try {
      await NotificationApiService.markAllAsRead();
      if (!mounted) {
        return;
      }

      setState(() {
        _notifications = _notifications
            .map((entry) => entry.copyWith(isRead: true))
            .toList();
      });

      await NotificationPopupManager.refreshUnreadCount();

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua notifikasi sudah ditandai dibaca')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menandai semua notifikasi')),
      );
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: false,
        foregroundColor: _textPrimary,
        title: const Text(
          'Popup & Reminder',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _loadNotifications(silent: true),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              _buildTopActions(),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_isLoading && _errorMessage != null) _buildErrorState(),
              if (!_isLoading &&
                  _errorMessage == null &&
                  _notifications.isEmpty)
                _buildEmptyState(),
              if (!_isLoading && _notifications.isNotEmpty)
                ..._notifications.map(_buildNotificationCard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Unread: $_unreadCount',
              style: const TextStyle(
                color: _danger,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Spacer(),
          FilledButton.icon(
            onPressed:
                _unreadCount > 0 && !_isMarkingAll ? _markAllAsRead : null,
            icon: _isMarkingAll
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.done_all, size: 16),
            label: Text(_isMarkingAll ? 'Memproses...' : 'Tandai Semua Dibaca'),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              textStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: _textSecondary),
            ),
          ),
          TextButton(
            onPressed: _loadNotifications,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: const Column(
        children: [
          Icon(Icons.notifications_none, size: 30, color: _muted),
          SizedBox(height: 8),
          Text(
            'Belum ada notifikasi',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Notifikasi baru akan tampil di sini.',
            style: TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(AppNotificationItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => _markAsRead(item),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: item.isRead ? _surface : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: item.isRead ? _border : _primary.withOpacity(0.28),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: item.isRead
                      ? _muted.withOpacity(0.14)
                      : _primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  item.isRead
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: item.isRead ? _muted : _primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 14,
                              fontWeight: item.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: _danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.displayTypeLabel,
                            style: const TextStyle(
                              color: _primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.circle, size: 4, color: _muted),
                        const SizedBox(width: 8),
                        Text(
                          item.relativeTime,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
