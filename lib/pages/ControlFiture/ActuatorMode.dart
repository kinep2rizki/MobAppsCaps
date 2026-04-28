import 'package:flutter/material.dart';
import 'package:my_app/Services/ControlService.dart';

typedef ActuatorSnapshotFetcher = Future<ActuatorSnapshot> Function(
  String deviceName,
);

typedef ActuatorModeUpdater = Future<ActuatorSnapshot> Function(
  String deviceName,
  String mode,
);

class ActuatorModePage extends StatefulWidget {
  const ActuatorModePage({
    super.key,
    this.initialDeviceName = 'actuator-01',
    this.initialMode = 'manual',
    this.initialStatus = 'Siaga',
    this.onFetchStatus,
    this.onUpdateMode,
  });

  final String initialDeviceName;
  final String initialMode;
  final String initialStatus;
  final ActuatorSnapshotFetcher? onFetchStatus;
  final ActuatorModeUpdater? onUpdateMode;

  @override
  State<ActuatorModePage> createState() => _ActuatorModePageState();
}

class _ActuatorModePageState extends State<ActuatorModePage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFF3F4F6);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _success = Color(0xFF059669);
  static const Color _warning = Color(0xFFF97316);

  late final TextEditingController _deviceController;
  late String _selectedMode;
  late String _statusText;
  String? _updatedAtText;
  bool _isLoadingStatus = false;
  bool _isUpdatingMode = false;
  String? _errorMessage;
  DateTime? _lastFetchedAt;

  @override
  void initState() {
    super.initState();
    _deviceController = TextEditingController(text: widget.initialDeviceName);
    _selectedMode = _normalizeMode(widget.initialMode);
    _statusText = widget.initialStatus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lihatStatusSatuAktuator();
      }
    });
  }

  @override
  void dispose() {
    _deviceController.dispose();
    super.dispose();
  }

  String _normalizeMode(String value) {
    return ControlService.normalizeMode(value);
  }

  String _normalizeStatus(String value) {
    return ControlService.normalizeStatus(value);
  }

  String _modeLabel(String mode) {
    return mode == 'auto' ? 'Otomatis' : 'Manual';
  }

  String _lastUpdatedLabel() {
    if (_lastFetchedAt == null) {
      return '-';
    }
    final time = _lastFetchedAt!;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }

  Color _statusColor(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.contains('aktif') ||
        normalized.contains('jalan') ||
        normalized.contains('run')) {
      return _success;
    }
    if (normalized.contains('siaga') ||
        normalized.contains('nonaktif') ||
        normalized.contains('idle')) {
      return _textSecondary;
    }
    return _warning;
  }

  Future<void> _lihatStatusSatuAktuator() async {
    final deviceName = _deviceController.text.trim();
    if (deviceName.isEmpty) {
      setState(() {
        _errorMessage = 'Nama aktuator belum diisi.';
      });
      return;
    }

    setState(() {
      _isLoadingStatus = true;
      _errorMessage = null;
    });

    try {
      if (widget.onFetchStatus != null) {
        final snapshot = await widget.onFetchStatus!(deviceName);
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedMode = _normalizeMode(snapshot.mode);
          _statusText = _normalizeStatus(snapshot.status);
          _updatedAtText = snapshot.updatedAt;
          _lastFetchedAt = DateTime.now();
        });
      } else {
        final snapshot = await ControlService.getActuatorStatus(
          deviceName: deviceName,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedMode = snapshot.mode;
          _statusText = snapshot.status;
          _updatedAtText = snapshot.updatedAt;
          _lastFetchedAt = DateTime.now();
        });
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingStatus = false;
        });
      }
    }
  }

  Future<void> _ubahModeSatuAktuator(String mode) async {
    final deviceName = _deviceController.text.trim();
    if (deviceName.isEmpty) {
      setState(() {
        _errorMessage = 'Nama aktuator belum diisi.';
      });
      return;
    }

    final normalizedMode = _normalizeMode(mode);
    setState(() {
      _isUpdatingMode = true;
      _errorMessage = null;
    });

    try {
      if (widget.onUpdateMode != null) {
        final snapshot = await widget.onUpdateMode!(deviceName, normalizedMode);
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedMode = _normalizeMode(snapshot.mode);
          _statusText = _normalizeStatus(snapshot.status);
          _updatedAtText = snapshot.updatedAt;
          _lastFetchedAt = DateTime.now();
        });
      } else {
        final snapshot = await ControlService.updateActuatorMode(
          deviceName: deviceName,
          mode: normalizedMode,
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _selectedMode = snapshot.mode;
          _statusText = snapshot.status;
          _updatedAtText = snapshot.updatedAt;
          _lastFetchedAt = DateTime.now();
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Mode aktuator diubah ke ${_modeLabel(normalizedMode)}.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingMode = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Actuator Mode',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _isLoadingStatus || _isUpdatingMode
                ? null
                : _lihatStatusSatuAktuator,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 18),
              _buildSummaryBanner(),
              const SizedBox(height: 16),
              _buildDeviceCard(),
              const SizedBox(height: 16),
              _buildStatusCard(),
              const SizedBox(height: 16),
              _buildModeCard(),
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
          'Kontrol Satu Aktuator',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Lihat status lalu ubah mode tanpa mengubah bagian kontrol lain.',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSummaryBanner() {
    final bool isKnown = _statusText.trim().isNotEmpty;
    final Color bannerColor = _statusColor(_statusText);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            bannerColor.withOpacity(0.12),
            _surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bannerColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isKnown ? Icons.power_settings_new_rounded : Icons.sync,
              color: bannerColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status Aktuator Saat Ini',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _deviceController.text.trim(),
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    _buildMiniChip(
                      label: _statusText,
                      color: bannerColor,
                    ),
                    _buildMiniChip(
                      label: _modeLabel(_selectedMode),
                      color: _primary,
                    ),
                    _buildMiniChip(
                      label: _updatedAtText ?? _lastUpdatedLabel(),
                      color: _textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDeviceCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Aktuator',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Isi nama device sesuai yang dipakai backend.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _deviceController,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _lihatStatusSatuAktuator(),
            decoration: InputDecoration(
              labelText: 'Nama aktuator',
              filled: true,
              fillColor: _surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _primary),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoadingStatus ? null : _lihatStatusSatuAktuator,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isLoadingStatus
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search_rounded),
              label:
                  Text(_isLoadingStatus ? 'Memuat status...' : 'Lihat Status'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status Aktuator',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                  child: _buildInfoTile(
                      'Status', _statusText, _statusColor(_statusText))),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildInfoTile(
                      'Mode', _modeLabel(_selectedMode), _primary)),
            ],
          ),
          const SizedBox(height: 14),
          _buildMetaRow('Device', _deviceController.text.trim()),
          const SizedBox(height: 8),
          _buildMetaRow('Updated at', _updatedAtText ?? _lastUpdatedLabel()),
          const SizedBox(height: 8),
          _buildMetaRow('Last update', _lastUpdatedLabel()),
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ubah Mode',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih mode manual atau otomatis untuk aktuator ini.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildModeButton('auto', 'Otomatis')),
              const SizedBox(width: 12),
              Expanded(child: _buildModeButton('manual', 'Manual')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton(String mode, String label) {
    final bool isSelected = _selectedMode == mode;
    final bool isBusy = _isUpdatingMode;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      child: OutlinedButton(
        onPressed: isBusy ? null : () => _ubahModeSatuAktuator(mode),
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? _primary : _surfaceAlt,
          foregroundColor: isSelected ? Colors.white : _textPrimary,
          side: BorderSide(color: isSelected ? _primary : _border),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: isBusy && isSelected
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(color: _textSecondary, fontSize: 13),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
