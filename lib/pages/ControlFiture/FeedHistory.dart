import 'package:flutter/material.dart';

import 'package:my_app/Services/ControlService/FeedHistoryService.dart';

class FeedHistoryCard extends StatefulWidget {
  const FeedHistoryCard({super.key});

  @override
  State<FeedHistoryCard> createState() => _FeedHistoryCardState();
}

class _FeedHistoryCardState extends State<FeedHistoryCard> {
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _borderColor = Color(0xFFE5E7EB);
  static const Color _danger = Color(0xFFDC2626);
  static const double _maxEntryQuantityKg = 20.0;

  bool _isLoading = false;
  bool _isSubmitting = false;
  int? _farmingCycleId;
  List<FeedHistoryEntry> _history = const [];
  FeedHistoryStats? _stats;
  String? _errorMessage;
  String? _statsErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshHistory();
      }
    });
  }

  Future<void> _refreshHistory() async {
    if (_isLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statsErrorMessage = null;
    });

    try {
      final resolvedCycleId = await FeedHistoryService.resolveFarmingCycleId();
      if (resolvedCycleId == null) {
        throw Exception('farming_cycle_id belum ditemukan. Silakan pilih farm cycle aktif terlebih dahulu.');
      }

      final results = await Future.wait<dynamic>([
        FeedHistoryService.getFeedHistory(farmingCycleId: resolvedCycleId),
        FeedHistoryService.getFeedHistoryStats(farmingCycleId: resolvedCycleId),
      ]);

      if (!mounted) {
        return;
      }

      setState(() {
        _farmingCycleId = resolvedCycleId;
        _history = results[0] as List<FeedHistoryEntry>;
        _stats = results[1] as FeedHistoryStats;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _history = const [];
        _stats = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCreateDialog() async {
    final cycleId = _farmingCycleId ?? await FeedHistoryService.resolveFarmingCycleId();
    if (cycleId == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih farm cycle aktif terlebih dahulu.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) {
      return;
    }

    final quantityController = TextEditingController(text: '2.5');
    final notesController = TextEditingController(text: 'Pemberian pakan manual');
    final adminController = TextEditingController(text: 'manual');
    final formKey = GlobalKey<FormState>();

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Catat Pemberian Pakan'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'quantity_given',
                          hintText: 'Maks ${_maxEntryQuantityKg.toStringAsFixed(0)} kg',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return 'quantity_given wajib diisi';
                          }

                          final parsed = double.tryParse(text.replaceAll(',', '.'));
                          if (parsed == null) {
                            return 'quantity_given harus berupa angka';
                          }

                          if (parsed <= 0) {
                            return 'quantity_given harus lebih besar dari 0';
                          }

                          if (parsed > _maxEntryQuantityKg) {
                            return 'quantity_given maksimal ${_maxEntryQuantityKg.toStringAsFixed(0)} kg';
                          }

                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: adminController.text.trim().isEmpty ? 'manual' : adminController.text.trim(),
                        items: const [
                          DropdownMenuItem(value: 'manual', child: Text('manual')),
                          DropdownMenuItem(value: 'auto', child: Text('auto')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }

                          setDialogState(() {
                            adminController.text = value;
                          });
                        },
                        decoration: const InputDecoration(
                          labelText: 'administered_by',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'notes',
                          hintText: 'Contoh: Pemberian pakan pagi',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            Navigator.of(dialogContext).pop(true);
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSubmit != true || !mounted) {
      quantityController.dispose();
      notesController.dispose();
      adminController.dispose();
      return;
    }

    final parsedQuantity = double.parse(quantityController.text.trim().replaceAll(',', '.'));

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FeedHistoryService.createFeedHistory(
        farmingCycleId: cycleId,
        quantityGiven: parsedQuantity,
        administeredBy: adminController.text.trim(),
        notes: notesController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Riwayat pemberian pakan berhasil dicatat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _refreshHistory();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _danger,
        ),
      );
    } finally {
      quantityController.dispose();
      notesController.dispose();
      adminController.dispose();
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      'Riwayat Pemberian Pakan',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Catat dan lihat histori pemberian pakan per farm cycle',
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _isLoading ? null : _refreshHistory,
                icon: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                color: _primary,
                tooltip: 'Muat ulang riwayat',
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildStatsSummary(),
          const SizedBox(height: 12),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_history.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              alignment: Alignment.center,
              child: Text(
                _errorMessage ?? 'Belum ada riwayat pemberian pakan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _errorMessage == null ? _textSecondary : _danger,
                  fontSize: 13,
                ),
              ),
            )
          else
            Column(
              children: _history
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildHistoryTile(entry),
                    ),
                  )
                  .toList(),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _openCreateDialog,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: const Text('Catat Pakan'),
            ),
          ),
          if (_errorMessage != null && _errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: _danger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (_statsErrorMessage != null && _statsErrorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _statsErrorMessage!,
              style: const TextStyle(
                color: _danger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSummary() {
    final stats = _stats;
    final totalRecords = stats?.totalRecords ?? _history.length;
    final totalQuantity = stats?.totalQuantityGiven ??
      _history.fold<double>(0, (sum, entry) => sum + (entry.quantityGiven ?? 0));
    final averageQuantity = stats?.averageQuantityGiven ??
        (totalRecords == 0 ? null : totalQuantity / totalRecords);
    final lastTime = stats?.lastActualTime ??
      (_history.isEmpty ? null : _history.first.actualTime);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildChip(Icons.receipt_long_rounded, 'Record', totalRecords.toString()),
          _buildChip(Icons.scale_rounded, 'Total', '${_formatQuantity(totalQuantity)} Kg'),
          _buildChip(
            Icons.trending_up_rounded,
            'Rata-rata',
            averageQuantity == null ? '-' : '${_formatQuantity(averageQuantity)} Kg',
          ),
          _buildChip(
            Icons.schedule_rounded,
            'Terakhir',
            lastTime == null ? '-' : _formatDateTime(lastTime),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(FeedHistoryEntry entry) {
    final quantity = entry.quantityGiven == null ? '-' : '${_formatQuantity(entry.quantityGiven!)} Kg';
    final timeLabel = _formatDateTime(entry.actualTime ?? entry.createdAt);

    return Container(
      padding: const EdgeInsets.all(16),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.restaurant_rounded, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quantity,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Admin: ${entry.administeredBy ?? '-'}',
                      style: const TextStyle(color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                timeLabel,
                style: const TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if ((entry.notes ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.notes!,
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatQuantity(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return '-';
    }

    final localValue = value.toLocal();
    final day = localValue.day.toString().padLeft(2, '0');
    final month = localValue.month.toString().padLeft(2, '0');
    final year = localValue.year.toString();
    final hour = localValue.hour.toString().padLeft(2, '0');
    final minute = localValue.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }
}