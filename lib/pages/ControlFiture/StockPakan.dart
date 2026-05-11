import 'package:flutter/material.dart';

import 'package:my_app/Services/ControlService/StockPakanService.dart';

class StockPakanCard extends StatelessWidget {
  const StockPakanCard({
    super.key,
    required this.stock,
    required this.isLoading,
    required this.stats,
    required this.isStatsLoading,
    required this.history,
    required this.isHistoryLoading,
    required this.onRefresh,
    this.errorMessage,
    this.statsErrorMessage,
    this.historyErrorMessage,
  });

  final FeedStock? stock;
  final bool isLoading;
  final FeedStockStats? stats;
  final bool isStatsLoading;
  final List<FeedStockTransaction> history;
  final bool isHistoryLoading;
  final String? errorMessage;
  final String? statsErrorMessage;
  final String? historyErrorMessage;
  final VoidCallback onRefresh;

  static const Color _surface = Color(0xFFFFF7ED);
  static const Color _surfaceAlt = Color(0xFFFEE3C8);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _warning = Color(0xFFEA580C);
  static const Color _success = Color(0xFF059669);
  static const Color _danger = Color(0xFFDC2626);
  static const double _stockGaugeMaxKg = 20.0;
  static const double _maxTransactionQuantityKg = 20.0;

  Future<void> _openTransactionDialog(BuildContext context) async {
    if (stock?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock ID belum tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedTransactionType = 'usage';

    final shouldSubmit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Catat Transaksi Stok'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'usage',
                          label: Text('Usage'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                        ButtonSegment<String>(
                          value: 'input',
                          label: Text('Input'),
                          icon: Icon(Icons.add_circle_outline),
                        ),
                      ],
                      selected: {selectedTransactionType},
                      onSelectionChanged: (selection) {
                        setDialogState(() {
                          selectedTransactionType = selection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Quantity (${stock?.unit ?? 'kg'})',
                        hintText: 'Maks ${_maxTransactionQuantityKg.toStringAsFixed(0)} kg',
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'quantity wajib diisi';
                        }

                        final parsed = double.tryParse(text.replaceAll(',', '.'));
                        if (parsed == null) {
                          return 'quantity harus berupa angka';
                        }

                        if (parsed <= 0) {
                          return 'quantity harus lebih besar dari 0';
                        }

                        if (parsed > _maxTransactionQuantityKg) {
                          return 'quantity maksimal ${_maxTransactionQuantityKg.toStringAsFixed(0)} kg';
                        }

                        if (selectedTransactionType == 'input' && stock != null) {
                          if (stock!.currentQuantity >= _stockGaugeMaxKg) {
                            return 'Stok sudah maksimal ${_stockGaugeMaxKg.toStringAsFixed(0)} kg, input tidak bisa dilakukan';
                          }

                          if (stock!.currentQuantity + parsed > _stockGaugeMaxKg) {
                            return 'Total stok setelah input tidak boleh melebihi ${_stockGaugeMaxKg.toStringAsFixed(0)} kg';
                          }
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Keterangan transaksi',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    if (shouldSubmit != true || !context.mounted) {
      quantityController.dispose();
      notesController.dispose();
      return;
    }

    final parsedQuantity = double.parse(
      quantityController.text.trim().replaceAll(',', '.'),
    );

    try {
      await StockPakanService.createFeedStockTransaction(
        stockId: stock!.id!,
        transactionType: selectedTransactionType,
        quantity: parsedQuantity,
        currentQuantity: stock!.currentQuantity,
        notes: notesController.text.trim(),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaksi stok pakan berhasil dicatat.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onRefresh();
    } catch (error) {
      if (!context.mounted) {
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
    }
  }

  List<_UsageDayPoint> _buildUsagePoints() {
    final statsSeries = stats?.usageSeries;
    if (statsSeries != null && statsSeries.isNotEmpty) {
      return statsSeries
          .map(
            (point) => _UsageDayPoint(
              label: point.label,
              dateLabel: point.dateLabel,
              quantity: point.quantity,
            ),
          )
          .toList();
    }

    final usageTransactions = history.where((transaction) => transaction.isUsage);
    final dailyTotals = <DateTime, double>{};

    for (final transaction in usageTransactions) {
      final createdAt = transaction.createdAt;
      if (createdAt == null) {
        continue;
      }

      final dayKey = DateTime(createdAt.year, createdAt.month, createdAt.day);
      dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + transaction.quantity;
    }

    final today = DateTime.now();
    return List.generate(7, (index) {
      final offset = 6 - index;
      final date = DateTime(today.year, today.month, today.day - offset);
      final dayKey = DateTime(date.year, date.month, date.day);
      return _UsageDayPoint(
        label: _shortDayLabel(date),
        dateLabel: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}',
        quantity: dailyTotals[dayKey] ?? 0,
      );
    });
  }

  Widget _buildUsageGraph(BuildContext context) {
    final usagePoints = _buildUsagePoints();
    final maxQuantity = usagePoints.fold<double>(0, (maxValue, point) {
      return point.quantity > maxValue ? point.quantity : maxValue;
    });
    final graphMax = maxQuantity < 1 ? 1.0 : maxQuantity;
    final hasAnyUsage = usagePoints.any((point) => point.quantity > 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart_rounded, color: _primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  stats?.hasUsageSeries == true
                      ? 'Grafik Usage dari Stats'
                      : 'Grafik Usage 7 Hari',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Usage',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isStatsLoading && stats == null && isHistoryLoading)
            const SizedBox(
              height: 150,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!hasAnyUsage)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada data usage untuk ditampilkan.',
                style: TextStyle(color: _textSecondary, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: usagePoints.map((point) {
                  final ratio = point.quantity / graphMax;
                  final barHeight = 92.0 * ratio.clamp(0.0, 1.0);
                  final isLatest = point == usagePoints.last;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            point.quantity == 0
                                ? '-'
                                : _formatQuantity(point.quantity),
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 96,
                            width: double.infinity,
                            alignment: Alignment.bottomCenter,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: barHeight,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: isLatest
                                    ? _warning
                                    : _primary.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            point.label,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            point.dateLabel,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          if (statsErrorMessage != null && statsErrorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              statsErrorMessage!,
              style: const TextStyle(
                color: _danger,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
          if (historyErrorMessage != null && historyErrorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              historyErrorMessage!,
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
    if (stats == null) {
      return const SizedBox.shrink();
    }

    final currentQuantity = stats!.currentQuantity ?? stock?.currentQuantity;
    final totalUsage = stats!.totalUsage;
    final totalInput = stats!.totalInput;
    final transactionCount = stats!.transactionCount;
    final unitLabel = stats!.unit ?? stock?.unit ?? 'kg';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _buildStatChip(
            icon: Icons.inventory_2_rounded,
            label: 'Sisa stok',
            value: currentQuantity == null ? '-' : '${_formatQuantity(currentQuantity)} $unitLabel',
          ),
          _buildStatChip(
            icon: Icons.trending_down_rounded,
            label: 'Total usage',
            value: totalUsage == null ? '-' : '${_formatQuantity(totalUsage)} $unitLabel',
          ),
          _buildStatChip(
            icon: Icons.trending_up_rounded,
            label: 'Total input',
            value: totalInput == null ? '-' : '${_formatQuantity(totalInput)} $unitLabel',
          ),
          _buildStatChip(
            icon: Icons.receipt_long_rounded,
            label: 'Transaksi',
            value: transactionCount?.toString() ?? '-',
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
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

  Future<void> _openEditDialog(BuildContext context) async {
    if (stock?.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stock ID belum tersedia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final thresholdController = TextEditingController(
      text: stock?.minThreshold?.toString() ?? '',
    );
    final unitController = TextEditingController(text: stock?.unit ?? 'kg');
    final formKey = GlobalKey<FormState>();

    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update Stok Pakan'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: thresholdController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'min_threshold',
                    hintText: 'Contoh: 10',
                  ),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'min_threshold wajib diisi';
                    }

                    final parsed = double.tryParse(text.replaceAll(',', '.'));
                    if (parsed == null) {
                      return 'min_threshold harus berupa angka';
                    }

                    if (parsed < 0) {
                      return 'min_threshold tidak boleh negatif';
                    }

                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'unit',
                    hintText: 'Contoh: kg',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'unit wajib diisi';
                    }

                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  Navigator.of(dialogContext).pop(true);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    if (shouldUpdate != true || !context.mounted) {
      return;
    }

    final parsedThreshold = double.parse(
      thresholdController.text.trim().replaceAll(',', '.'),
    );

    try {
      await StockPakanService.updateFeedStockConfig(
        stockId: stock!.id!,
        minThreshold: parsedThreshold,
        unit: unitController.text.trim(),
      );

      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfigurasi stok pakan berhasil diperbarui.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      onRefresh();
    } catch (error) {
      if (!context.mounted) {
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
      thresholdController.dispose();
      unitController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasData = stock != null;
    final quantityLabel = hasData ? _formatQuantity(stock!.currentQuantity) : '--';
    final unitLabel = hasData ? stock!.unit : 'Kg';
    final statusLabel = !hasData
        ? 'Data belum tersedia'
        : stock!.isLowStock
            ? 'Stok menipis'
            : 'Stok aman';
    final statusColor = !hasData
        ? _textSecondary
        : stock!.isLowStock
            ? _warning
            : _success;
    final progressValue = hasData
      ? (stock!.currentQuantity / _stockGaugeMaxKg).clamp(0.0, 1.0)
      : 0.0;
    final thresholdLabel = hasData && stock!.minThreshold != null
        ? 'Ambang minimum ${_formatQuantity(stock!.minThreshold!)} $unitLabel'
        : 'Ambang minimum belum tersedia';
    final updatedLabel = hasData ? _formatDateTime(stock!.updatedAt) : '-';
    final gaugeLabel = hasData
      ? '0 - ${_formatQuantity(_stockGaugeMaxKg)} $unitLabel'
      : '0 - ${_formatQuantity(_stockGaugeMaxKg)} Kg';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_surface, _surfaceAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.inventory_2_rounded, color: _warning),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stok Pakan',
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Data stok tersisa dari server',
                      style: TextStyle(color: _textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: (isLoading || stock?.id == null)
                    ? null
                    : () => _openTransactionDialog(context),
                icon: const Icon(Icons.swap_horiz_rounded),
                color: _primary,
                tooltip: 'Catat transaksi stok',
              ),
              IconButton(
                onPressed:
                    (isLoading || stock?.id == null) ? null : () => _openEditDialog(context),
                icon: const Icon(Icons.edit_outlined),
                color: _primary,
                tooltip: 'Edit konfigurasi stok',
              ),
              IconButton(
                onPressed: isLoading ? null : onRefresh,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                color: _primary,
                tooltip: 'Muat ulang stok',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quantityLabel,
                style: const TextStyle(
                  color: _textPrimary,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  unitLabel,
                  style: const TextStyle(color: _textSecondary, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            statusLabel,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildStatsSummary(),
          if (stats != null) const SizedBox(height: 12),
          _buildUsageGraph(context),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progressValue,
              minHeight: 12,
              backgroundColor: Colors.white.withOpacity(0.72),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0 kg',
                style: TextStyle(color: _textSecondary, fontSize: 11),
              ),
              Text(
                gaugeLabel,
                style: const TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            thresholdLabel,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            'Diperbarui $updatedLabel',
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
          if (errorMessage != null && errorMessage!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _danger.withOpacity(0.22)),
              ),
              child: Text(
                errorMessage!,
                style: const TextStyle(
                  color: _danger,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (!hasData && !isLoading && (errorMessage == null || errorMessage!.isEmpty)) ...[
            const SizedBox(height: 14),
            const Text(
              'Belum ada data stok pakan yang bisa ditampilkan.',
              style: TextStyle(color: _textSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _shortDayLabel(DateTime date) {
    const labels = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    return labels[date.weekday % 7];
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

class _UsageDayPoint {
  const _UsageDayPoint({
    required this.label,
    required this.dateLabel,
    required this.quantity,
  });

  final String label;
  final String dateLabel;
  final double quantity;
}