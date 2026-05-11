// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:my_app/Services/ControlService.dart';
import 'package:my_app/pages/ControlFiture/FeedHistory.dart';
import 'package:my_app/Services/ControlService/StockPakanService.dart';
import 'package:my_app/pages/ControlFiture/ControlActuator.dart';
import 'package:my_app/pages/ControlFiture/JadwalPakan.dart';
import 'package:my_app/pages/ControlFiture/StockPakan.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _success = Color(0xFF059669);
  static const List<String> _actuatorDeviceNames = ['pompa', 'aerator'];

  bool _isAutoMode = true;
  bool _isLoadingActuatorStatus = false;
  bool _isLoadingStockPakan = false;
  bool _isLoadingStockHistory = false;
  bool _isLoadingStockStats = false;
  final Map<String, ActuatorSnapshot> _actuatorSnapshots = {};
  final Map<String, String> _actuatorStatusErrors = {};
  FeedStock? _stockPakan;
  FeedStockStats? _stockStats;
  List<FeedStockTransaction> _stockHistory = const [];
  String? _stockPakanError;
  String? _stockStatsError;
  String? _stockHistoryError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshActuatorStatus();
        _refreshStockPakan();
      }
    });
  }

  Future<void> _refreshActuatorStatus() async {
    if (_isLoadingActuatorStatus) {
      return;
    }

    setState(() {
      _isLoadingActuatorStatus = true;
      _actuatorStatusErrors.clear();
    });

    final snapshots = <String, ActuatorSnapshot>{};
    final errors = <String, String>{};

    for (final deviceName in _actuatorDeviceNames) {
      try {
        final snapshot = await ControlService.getActuatorStatus(
          deviceName: deviceName,
        );
        snapshots[deviceName] = snapshot;
      } catch (error) {
        errors[deviceName] = error.toString().replaceFirst('Exception: ', '');
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _actuatorSnapshots
        ..clear()
        ..addAll(snapshots);
      _actuatorStatusErrors
        ..clear()
        ..addAll(errors);
      _isLoadingActuatorStatus = false;
    });
  }

  Future<void> _refreshStockPakan() async {
    if (_isLoadingStockPakan) {
      return;
    }

    setState(() {
      _isLoadingStockPakan = true;
      _stockPakanError = null;
    });

    try {
      final stock = await StockPakanService.getRemainingFeedStock();
      if (!mounted) {
        return;
      }

      setState(() {
        _stockPakan = stock;
      });

      final stockId = stock?.id;
      if (stockId != null) {
        await _refreshStockStats(stockId);
        await _refreshStockHistory(stockId);
      } else {
        if (!mounted) {
          return;
        }

        setState(() {
          _stockStats = null;
          _stockHistory = const [];
          _stockStatsError = null;
          _stockHistoryError = null;
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stockPakanError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStockPakan = false;
        });
      }
    }
  }

  Future<void> _refreshStockStats(int stockId) async {
    if (_isLoadingStockStats) {
      return;
    }

    setState(() {
      _isLoadingStockStats = true;
      _stockStatsError = null;
    });

    try {
      final stats = await StockPakanService.getFeedStockStats(stockId: stockId);

      if (!mounted) {
        return;
      }

      setState(() {
        _stockStats = stats;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stockStats = null;
        _stockStatsError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStockStats = false;
        });
      }
    }
  }

  Future<void> _refreshStockHistory(int stockId) async {
    if (_isLoadingStockHistory) {
      return;
    }

    setState(() {
      _isLoadingStockHistory = true;
      _stockHistoryError = null;
    });

    try {
      final history = await StockPakanService.getFeedStockHistory(
        stockId: stockId,
        limit: 100,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _stockHistory = history;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _stockHistory = const [];
        _stockHistoryError = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStockHistory = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildActuatorStatusCard(),
              const SizedBox(height: 16),
              _buildControlActuatorShortcut(),
              const SizedBox(height: 16),
              _buildModeCard(),
              const SizedBox(height: 16),
              _buildScheduleCard(),
              const SizedBox(height: 16),
              _buildFeedHistoryCard(),
              const SizedBox(height: 16),
              _buildStockCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BluVera',
          style: TextStyle(
            color: _primary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Kontrol Sistem',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Alat pemberian pakan otomatis/manual',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActuatorStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Aktuator',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lihat status real-time pompa dan aerator',
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.settings_input_component,
                  color: _primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._actuatorDeviceNames.map(_buildActuatorRow),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed:
                  _isLoadingActuatorStatus ? null : _refreshActuatorStatus,
              icon: _isLoadingActuatorStatus
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 16),
              label:
                  Text(_isLoadingActuatorStatus ? 'Memuat' : 'Refresh semua'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlActuatorShortcut() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEFF6FF), Color(0xFFF8FAFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune_rounded, color: _primary),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kontrol Manual Aktuator',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Buka halaman untuk memilih pompa atau aerator lalu kirim perintah on/off.',
                  style: TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ControlActuatorPage(),
                ),
              );
              if (!context.mounted) {
                return;
              }
              await _refreshActuatorStatus();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Buka'),
          ),
        ],
      ),
    );
  }

  Widget _buildActuatorRow(String deviceName) {
    final snapshot = _actuatorSnapshots[deviceName];
    final errorMessage = _actuatorStatusErrors[deviceName];
    final bool isActive = snapshot?.isActive ?? false;
    final Color statusColor = isActive ? _success : _textSecondary;
    final String statusLabel = snapshot == null
        ? (_isLoadingActuatorStatus ? 'Memuat...' : 'Belum dimuat')
        : snapshot.status;
    final String modeLabel = snapshot == null
        ? '-'
        : (snapshot.mode == 'auto' ? 'Otomatis' : 'Manual');
    final String updatedLabel = snapshot?.updatedAt ?? '-';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  deviceName.toUpperCase(),
                  style: const TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatusPill(
                  label: statusLabel,
                  valueColor: statusColor,
                  backgroundColor: statusColor.withOpacity(0.12),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatusPill(
                  label: modeLabel,
                  valueColor: _primary,
                  backgroundColor: const Color(0xFFEFF6FF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                'Updated at',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                updatedLabel,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              errorMessage,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color valueColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: valueColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildModeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mode Pemberian Pakan',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pilih mode otomatis atau manual',
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.power_settings_new, color: _primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(title: 'Otomatis', isAuto: true),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton(title: 'Manual', isAuto: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({required String title, required bool isAuto}) {
    final bool isActive = _isAutoMode == isAuto;
    return GestureDetector(
      onTap: () => setState(() => _isAutoMode = isAuto),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive ? _primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _primary : _borderColor),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : _textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard() {
    return const JadwalPakanCard();
  }

  Widget _buildFeedHistoryCard() {
    return const FeedHistoryCard();
  }

  Widget _buildStockCard() {
    return StockPakanCard(
      stock: _stockPakan,
      isLoading: _isLoadingStockPakan,
      stats: _stockStats,
      isStatsLoading: _isLoadingStockStats,
      statsErrorMessage: _stockStatsError,
      errorMessage: _stockPakanError,
      history: _stockHistory,
      isHistoryLoading: _isLoadingStockHistory,
      historyErrorMessage: _stockHistoryError,
      onRefresh: _refreshStockPakan,
    );
  }
}
