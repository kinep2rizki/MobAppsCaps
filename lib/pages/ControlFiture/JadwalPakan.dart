import 'package:flutter/material.dart';

import 'package:my_app/Services/JadwalPakanService.dart';

class JadwalPakanCard extends StatefulWidget {
	const JadwalPakanCard({super.key});

	@override
	State<JadwalPakanCard> createState() => _JadwalPakanCardState();
}

class _JadwalPakanCardState extends State<JadwalPakanCard> {
	static const Color _surface = Color(0xFFFFFFFF);
	static const Color _primary = Color(0xFF2563EB);
	static const Color _textPrimary = Color(0xFF1F2937);
	static const Color _textSecondary = Color(0xFF6B7280);
	static const Color _borderColor = Color(0xFFE5E7EB);
	static const Color _success = Color(0xFF059669);
	static const Color _danger = Color(0xFFDC2626);

	bool _isLoading = false;
	bool _isSubmitting = false;
	bool _isUpdatingItem = false;
	int? _farmingCycleId;
	List<FeedSchedule> _schedules = const [];
	String? _errorMessage;

	@override
	void initState() {
		super.initState();
		WidgetsBinding.instance.addPostFrameCallback((_) {
			if (mounted) {
				_refreshSchedules();
			}
		});
	}

	Future<void> _refreshSchedules() async {
		if (_isLoading) {
			return;
		}

		setState(() {
			_isLoading = true;
			_errorMessage = null;
		});

		try {
			final resolvedCycleId = await JadwalPakanService.resolveFarmingCycleId();
			final schedules = await JadwalPakanService.getFeedSchedules(
				farmingCycleId: resolvedCycleId,
			);

			if (!mounted) {
				return;
			}

			setState(() {
				_farmingCycleId = resolvedCycleId;
				_schedules = schedules;
			});
		} catch (error) {
			if (!mounted) {
				return;
			}

			setState(() {
				_errorMessage = error.toString().replaceFirst('Exception: ', '');
				_schedules = const [];
			});
		} finally {
			if (mounted) {
				setState(() {
					_isLoading = false;
				});
			}
		}
	}

	Future<void> _openEditDialog(FeedSchedule schedule) async {
		final scheduleId = schedule.id;
		if (scheduleId == null) {
			if (!mounted) {
				return;
			}

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Schedule ID belum tersedia.'),
					behavior: SnackBarBehavior.floating,
				),
			);
			return;
		}

		final quantityController = TextEditingController(
			text: schedule.expectedQuantity?.toString() ?? '',
		);
		final frequencyController = TextEditingController(text: schedule.frequency ?? 'daily');
		final timeController = TextEditingController(
			text: _normalizeScheduleTime(schedule.scheduledTime),
		);
		String selectedStatus = (schedule.status?.trim().isNotEmpty ?? false)
			? schedule.status!.trim().toLowerCase()
			: (schedule.isActive ? 'active' : 'inactive');
		final formKey = GlobalKey<FormState>();

		final shouldSubmit = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return StatefulBuilder(
					builder: (dialogContext, setDialogState) {
						return AlertDialog(
							title: const Text('Update Jadwal Pakan'),
							content: SingleChildScrollView(
								child: Form(
									key: formKey,
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											TextFormField(
												controller: quantityController,
												keyboardType: const TextInputType.numberWithOptions(decimal: true),
												decoration: const InputDecoration(
													labelText: 'expected_quantity',
													hintText: 'Contoh: 3',
												),
												validator: (value) {
													final text = value?.trim() ?? '';
													if (text.isEmpty) {
														return 'expected_quantity wajib diisi';
													}

													final parsed = double.tryParse(text.replaceAll(',', '.'));
													if (parsed == null) {
														return 'expected_quantity harus berupa angka';
													}

													if (parsed <= 0) {
														return 'expected_quantity harus lebih besar dari 0';
													}

													return null;
												},
											),
											const SizedBox(height: 12),
											TextFormField(
												controller: frequencyController,
												decoration: const InputDecoration(
													labelText: 'frequency',
													hintText: 'Contoh: daily',
												),
												validator: (value) {
													if (value == null || value.trim().isEmpty) {
														return 'frequency wajib diisi';
													}

													return null;
												},
											),
											const SizedBox(height: 12),
											TextFormField(
												controller: timeController,
												decoration: const InputDecoration(
													labelText: 'scheduled_time',
													hintText: 'Contoh: 07:00:00',
												),
												validator: (value) {
													final text = value?.trim() ?? '';
													if (text.isEmpty) {
														return 'scheduled_time wajib diisi';
													}

													return null;
												},
											),
											const SizedBox(height: 12),
											DropdownButtonFormField<String>(
												value: selectedStatus,
												items: const [
													DropdownMenuItem(value: 'active', child: Text('active')),
													DropdownMenuItem(value: 'inactive', child: Text('inactive')),
												],
												onChanged: (value) {
													if (value == null) {
														return;
													}

													setDialogState(() {
														selectedStatus = value;
													});
												},
												decoration: const InputDecoration(
													labelText: 'status',
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
									onPressed: _isSubmitting || _isUpdatingItem
										? null
										: () {
											if (formKey.currentState?.validate() ?? false) {
												Navigator.of(dialogContext).pop(true);
											}
										},
									child: (_isSubmitting || _isUpdatingItem)
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
			frequencyController.dispose();
			timeController.dispose();
			return;
		}

		final parsedQuantity = double.parse(quantityController.text.trim().replaceAll(',', '.'));
		final normalizedTime = timeController.text.trim();

		setState(() {
			_isUpdatingItem = true;
		});

		try {
			await JadwalPakanService.updateFeedSchedule(
				scheduleId: scheduleId,
				expectedQuantity: parsedQuantity,
				frequency: frequencyController.text.trim(),
				scheduledTime: normalizedTime,
				status: selectedStatus,
			);

			if (!mounted) {
				return;
			}

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Jadwal pakan berhasil diperbarui.'),
					behavior: SnackBarBehavior.floating,
				),
			);
			await _refreshSchedules();
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
			frequencyController.dispose();
			timeController.dispose();
			if (mounted) {
				setState(() {
					_isUpdatingItem = false;
				});
			}
		}
	}

	Future<void> _deleteSchedule(FeedSchedule schedule) async {
		final scheduleId = schedule.id;
		if (scheduleId == null) {
			if (!mounted) {
				return;
			}

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Schedule ID belum tersedia.'),
					behavior: SnackBarBehavior.floating,
				),
			);
			return;
		}

		final shouldDelete = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return AlertDialog(
					title: const Text('Hapus Jadwal Pakan'),
					content: Text(
						'Yakin ingin menghapus jadwal ${_normalizeScheduleTime(schedule.scheduledTime)}?',
					),
					actions: [
						TextButton(
							onPressed: () => Navigator.of(dialogContext).pop(false),
							child: const Text('Batal'),
						),
						FilledButton(
							style: FilledButton.styleFrom(backgroundColor: _danger),
							onPressed: _isSubmitting || _isUpdatingItem
								? null
								: () => Navigator.of(dialogContext).pop(true),
							child: const Text('Hapus'),
						),
					],
				);
			},
		);

		if (shouldDelete != true || !mounted) {
			return;
		}

		setState(() {
			_isUpdatingItem = true;
		});

		try {
			await JadwalPakanService.deleteFeedSchedule(scheduleId: scheduleId);

			if (!mounted) {
				return;
			}

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Jadwal pakan berhasil dihapus.'),
					behavior: SnackBarBehavior.floating,
				),
			);
			await _refreshSchedules();
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
			if (mounted) {
				setState(() {
					_isUpdatingItem = false;
				});
			}
		}
	}

	Future<void> _openCreateDialog() async {
		final cycleId = _farmingCycleId ?? await JadwalPakanService.resolveFarmingCycleId();
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
		final frequencyController = TextEditingController(text: 'daily');
		TimeOfDay selectedTime = const TimeOfDay(hour: 7, minute: 0);
		final formKey = GlobalKey<FormState>();

		final shouldSubmit = await showDialog<bool>(
			context: context,
			builder: (dialogContext) {
				return StatefulBuilder(
					builder: (dialogContext, setDialogState) {
						return AlertDialog(
							title: const Text('Tambah Jadwal Pakan'),
							content: SingleChildScrollView(
								child: Form(
									key: formKey,
									child: Column(
										mainAxisSize: MainAxisSize.min,
										children: [
											TextFormField(
												controller: quantityController,
												keyboardType: const TextInputType.numberWithOptions(decimal: true),
												decoration: const InputDecoration(
													labelText: 'expected_quantity',
													hintText: 'Contoh: 2.5',
												),
												validator: (value) {
													final text = value?.trim() ?? '';
													if (text.isEmpty) {
														return 'expected_quantity wajib diisi';
													}

													final parsed = double.tryParse(text.replaceAll(',', '.'));
													if (parsed == null) {
														return 'expected_quantity harus berupa angka';
													}

													if (parsed <= 0) {
														return 'expected_quantity harus lebih besar dari 0';
													}

													return null;
												},
											),
											const SizedBox(height: 12),
											TextFormField(
												controller: frequencyController,
												decoration: const InputDecoration(
													labelText: 'frequency',
													hintText: 'Contoh: daily',
												),
												validator: (value) {
													if (value == null || value.trim().isEmpty) {
														return 'frequency wajib diisi';
													}

													return null;
												},
											),
											const SizedBox(height: 12),
											InkWell(
												onTap: () async {
													final pickedTime = await showTimePicker(
														context: dialogContext,
														initialTime: selectedTime,
													);

													if (pickedTime == null) {
														return;
													}

													setDialogState(() {
														selectedTime = pickedTime;
													});
												},
												borderRadius: BorderRadius.circular(14),
												child: Container(
													width: double.infinity,
													padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
													decoration: BoxDecoration(
														borderRadius: BorderRadius.circular(14),
														border: Border.all(color: _borderColor),
														color: const Color(0xFFF8FAFC),
													),
													child: Row(
														children: [
															const Icon(Icons.schedule_outlined, color: _primary),
															const SizedBox(width: 10),
															Expanded(
																child: Text(
																	'scheduled_time: ${_formatTimeOfDay(selectedTime)}',
																	style: const TextStyle(
																		color: _textPrimary,
																		fontWeight: FontWeight.w600,
																	),
																),
															),
															const Icon(Icons.edit_outlined, color: _textSecondary, size: 18),
														],
													),
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
			frequencyController.dispose();
			return;
		}

		final parsedQuantity = double.parse(quantityController.text.trim().replaceAll(',', '.'));
		final scheduledTime = _formatTimeOfDay(selectedTime);

		setState(() {
			_isSubmitting = true;
		});

		try {
			await JadwalPakanService.createFeedSchedule(
				farmingCycleId: cycleId,
				expectedQuantity: parsedQuantity,
				frequency: frequencyController.text.trim(),
				scheduledTime: scheduledTime,
			);

			if (!mounted) {
				return;
			}

			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Jadwal pakan berhasil dibuat.'),
					behavior: SnackBarBehavior.floating,
				),
			);
			await _refreshSchedules();
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
			frequencyController.dispose();
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
											'Jadwal Pemberian Pakan',
											style: TextStyle(
												color: _textPrimary,
												fontSize: 18,
												fontWeight: FontWeight.w700,
											),
										),
										SizedBox(height: 4),
										Text(
											'Buat dan lihat jadwal pakan otomatis',
											style: TextStyle(color: _textSecondary, fontSize: 13),
										),
									],
								),
							),
							IconButton(
								onPressed: _isLoading ? null : _refreshSchedules,
								icon: _isLoading
										? const SizedBox(
												width: 18,
												height: 18,
												child: CircularProgressIndicator(strokeWidth: 2),
											)
										: const Icon(Icons.refresh_rounded),
								color: _primary,
								tooltip: 'Muat ulang jadwal',
							),
						],
					),
					const SizedBox(height: 18),
					if (_isLoading)
						const Padding(
							padding: EdgeInsets.symmetric(vertical: 24),
							child: Center(child: CircularProgressIndicator()),
						)
					else if (_schedules.isEmpty)
						Container(
							width: double.infinity,
							padding: const EdgeInsets.symmetric(vertical: 18),
							alignment: Alignment.center,
							child: Text(
								_errorMessage ?? 'Belum ada jadwal pakan.',
								textAlign: TextAlign.center,
								style: TextStyle(
									color: _errorMessage == null ? _textSecondary : _danger,
									fontSize: 13,
								),
							),
						)
					else
						Column(
							children: _schedules
									.map((schedule) => Padding(
												padding: const EdgeInsets.only(bottom: 12),
												child: _buildScheduleTile(schedule),
											))
									.toList(),
						),
					const SizedBox(height: 4),
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
							label: const Text('Tambah Jadwal'),
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
				],
			),
		);
	}

	Widget _buildScheduleTile(FeedSchedule schedule) {
		final quantityLabel = schedule.expectedQuantity == null
				? '-'
				: '${_formatQuantity(schedule.expectedQuantity!)} Kg';
		final timeLabel = _normalizeScheduleTime(schedule.scheduledTime);
		final statusLabel = schedule.status ?? 'unknown';
		final statusColor = schedule.isActive ? _success : _textSecondary;

		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
			decoration: BoxDecoration(
				color: const Color(0xFFF8FAFC),
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: _borderColor),
			),
			child: Row(
				children: [
					Container(
						padding: const EdgeInsets.all(10),
						decoration: BoxDecoration(
							color: const Color(0xFFEFF6FF),
							borderRadius: BorderRadius.circular(14),
						),
						child: const Icon(Icons.schedule, color: _primary),
					),
					const SizedBox(width: 14),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(
									timeLabel,
									style: const TextStyle(
										color: _textPrimary,
										fontSize: 16,
										fontWeight: FontWeight.bold,
									),
								),
								const SizedBox(height: 2),
								Text(
									'Target $quantityLabel • ${schedule.frequency ?? '-'}',
									style: const TextStyle(color: _textSecondary, fontSize: 13),
								),
								const SizedBox(height: 6),
								Row(
									children: [
										Text(
											'Status: $statusLabel',
											style: TextStyle(
												color: statusColor,
												fontSize: 12,
												fontWeight: FontWeight.w600,
											),
										),
										const SizedBox(width: 8),
										if (schedule.isActive)
											Container(
												padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
												decoration: BoxDecoration(
													color: _success.withOpacity(0.10),
													borderRadius: BorderRadius.circular(999),
												),
												child: const Text(
													'AKTIF',
													style: TextStyle(
														color: _success,
														fontSize: 10,
														fontWeight: FontWeight.w700,
													),
												),
										),
									],
								),
							],
						),
					),
					const SizedBox(width: 12),
					Column(
						children: [
							IconButton(
								onPressed: _isUpdatingItem || _isSubmitting ? null : () => _openEditDialog(schedule),
								icon: const Icon(Icons.edit_outlined),
								tooltip: 'Update jadwal',
								color: _primary,
							),
							IconButton(
								onPressed: _isUpdatingItem || _isSubmitting ? null : () => _deleteSchedule(schedule),
								icon: const Icon(Icons.delete_outline),
								tooltip: 'Hapus jadwal',
								color: _danger,
							),
						],
					),
				],
			),
		);
	}

	String _formatTimeOfDay(TimeOfDay timeOfDay) {
		final hour = timeOfDay.hour.toString().padLeft(2, '0');
		final minute = timeOfDay.minute.toString().padLeft(2, '0');
		return '$hour:$minute:00';
	}

	String _normalizeScheduleTime(String? value) {
		if (value == null || value.trim().isEmpty) {
			return '-';
		}

		final text = value.trim();
		if (text.length >= 5) {
			return text.substring(0, 5);
		}

		return text;
	}

	String _formatQuantity(double value) {
		if (value % 1 == 0) {
			return value.toStringAsFixed(0);
		}

		return value.toStringAsFixed(1);
	}
}