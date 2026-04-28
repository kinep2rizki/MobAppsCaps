import 'package:flutter/material.dart';
import 'package:my_app/Services/ControlService.dart';

class ControlActuatorPage extends StatefulWidget {
  const ControlActuatorPage({super.key});

  @override
  State<ControlActuatorPage> createState() => _ControlActuatorPageState();
}

class _ControlActuatorPageState extends State<ControlActuatorPage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Colors.white;
  static const Color _surfaceAlt = Color(0xFFF3F4F6);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF111827);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);

  static const List<String> _devices = ['pompa', 'aerator'];
  String _selectedDevice = 'pompa';
  String _selectedMode = 'manual';
  bool _isLoading = false;
  bool _isSending = false;
  bool _isUpdatingMode = false;
  String? _errorMessage;
  final Map<String, ActuatorSnapshot> _snapshots = {};
  final Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadSelectedStatus();
      }
    });
  }

  Future<void> _loadSelectedStatus() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await ControlService.getActuatorStatus(
        deviceName: _selectedDevice,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _snapshots[_selectedDevice] = snapshot;
        _selectedMode = snapshot.mode;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errors[_selectedDevice] =
            error.toString().replaceFirst('Exception: ', '');
        _errorMessage = _errors[_selectedDevice];
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _controlSelected(String action) async {
    if (_isSending) {
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await ControlService.controlActuator(
        deviceName: _selectedDevice,
        action: action,
        triggeredBy: 'manual',
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _snapshots[_selectedDevice] = snapshot;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedDevice.toUpperCase()} berhasil ${action == 'on' ? 'dinyalakan' : 'dimatikan'}.',
          ),
        ),
      );
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
          _isSending = false;
        });
      }
    }
  }

  Future<void> _changeSelectedMode(String mode) async {
    if (_isUpdatingMode) {
      return;
    }

    setState(() {
      _isUpdatingMode = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await ControlService.updateActuatorMode(
        deviceName: _selectedDevice,
        mode: mode,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedMode = snapshot.mode;
        _snapshots[_selectedDevice] = snapshot;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedDevice.toUpperCase()} diubah ke mode ${mode == 'auto' ? 'otomatis' : 'manual'}.',
          ),
        ),
      );
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
    final snapshot = _snapshots[_selectedDevice];
    final selectedError = _errors[_selectedDevice];
    final bool isActive = snapshot?.isActive ?? false;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        elevation: 0,
        foregroundColor: _textPrimary,
        title: const Text(
          'Control Actuator',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDeviceSelector(),
              const SizedBox(height: 16),
              _buildStatusCard(snapshot, isActive),
              const SizedBox(height: 16),
              _buildModeCard(snapshot),
              const SizedBox(height: 16),
              _buildActionCard(snapshot),
              if (_errorMessage != null || selectedError != null) ...[
                const SizedBox(height: 16),
                _buildErrorCard(_errorMessage ?? selectedError!),
              ],
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
          'Kontrol Aktuator Manual',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Pilih pompa atau aerator, lalu kirim perintah on/off dari sini.',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildDeviceSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Device',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: _devices.map((device) {
              final bool selected = _selectedDevice == device;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: device == _devices.last ? 0 : 10,
                  ),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDevice = device;
                        _errorMessage = null;
                      });
                      _loadSelectedStatus();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: selected ? _primary : _surfaceAlt,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: selected ? _primary : _border),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        device.toUpperCase(),
                        style: TextStyle(
                          color: selected ? Colors.white : _textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(ActuatorSnapshot? snapshot, bool isActive) {
    final String statusLabel = snapshot == null
        ? (_isLoading ? 'Memuat status...' : 'Belum dimuat')
        : (snapshot.status.isEmpty
            ? (isActive ? 'Aktif' : 'Nonaktif')
            : snapshot.status);
    final String modeLabel = snapshot == null
        ? '-'
        : (snapshot.mode == 'auto' ? 'Otomatis' : 'Manual');
    final String updatedLabel = snapshot?.updatedAt ?? '-';

    final Color statusColor = isActive ? _success : _textSecondary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _infoChip('Status', statusLabel, statusColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _infoChip('Mode', modeLabel, _primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow('Device', _selectedDevice),
          const SizedBox(height: 8),
          _infoRow('Updated at', updatedLabel),
          const SizedBox(height: 8),
          _infoRow('Mode aktif', modeLabel),
          const SizedBox(height: 8),
          _infoRow('Data real-time', _isLoading ? 'Sedang memuat...' : 'Siap'),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(ActuatorSnapshot? snapshot) {
    final bool isAuto = _selectedMode == 'auto';
    final String currentLabel = snapshot == null
        ? (_isLoading ? 'Memuat...' : 'Belum dimuat')
        : (_selectedMode == 'auto' ? 'Otomatis' : 'Manual');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mode Pompa / Aerator',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Pilih apakah device berjalan otomatis atau manual.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  title: 'Otomatis',
                  isAuto: true,
                  isSelected: isAuto,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeButton(
                  title: 'Manual',
                  isAuto: false,
                  isSelected: !isAuto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                'Mode saat ini',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Text(
                currentLabel,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _isLoading || _isSending || _isUpdatingMode
                    ? null
                    : _loadSelectedStatus,
                child: const Text('Sync'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String title,
    required bool isAuto,
    required bool isSelected,
  }) {
    return OutlinedButton(
      onPressed: _isUpdatingMode
          ? null
          : () => _changeSelectedMode(isAuto ? 'auto' : 'manual'),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? _primary : _surfaceAlt,
        foregroundColor: isSelected ? Colors.white : _textPrimary,
        side: BorderSide(color: isSelected ? _primary : _border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: _isUpdatingMode && isSelected
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
    );
  }

  Widget _infoRow(String label, String value) {
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

  Widget _buildActionCard(ActuatorSnapshot? snapshot) {
    final bool isActive = snapshot?.isActive ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kirim Kontrol Manual',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Gunakan tombol ini untuk menyalakan atau mematikan aktuator yang dipilih.',
            style: TextStyle(color: _textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _controlSelected('on'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.power_settings_new_rounded),
                  label: const Text('Nyalakan'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : () => _controlSelected('off'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _danger,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.power_off_rounded),
                  label: const Text('Matikan'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.info_outline,
                color: isActive ? _success : _textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isActive
                      ? 'Aktuator sedang aktif.'
                      : 'Aktuator sedang nonaktif atau status belum diperbarui.',
                  style: const TextStyle(color: _textSecondary, fontSize: 12),
                ),
              ),
              TextButton(
                onPressed:
                    _isLoading || _isSending ? null : _loadSelectedStatus,
                child: Text(_isLoading ? 'Memuat...' : 'Refresh status'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFB91C1C),
          fontSize: 13,
        ),
      ),
    );
  }
}
