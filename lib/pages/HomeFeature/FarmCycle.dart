import 'package:flutter/material.dart';
import 'package:my_app/Services/HomeService/FarmCycleService.dart';

class FarmCyclePage extends StatefulWidget {
  const FarmCyclePage({super.key});

  @override
  State<FarmCyclePage> createState() => _FarmCyclePageState();
}

class _FarmCyclePageState extends State<FarmCyclePage> {
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _success = Color(0xFF10B981);

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cycleNameController;
  late final TextEditingController _seedingDateController;

  bool _isLoadingCycles = true;
  bool _isSubmitting = false;
  String? _loadError;
  String? _submitMessage;
  List<FarmCycle> _cycles = const [];
  DateTime? _selectedSeedingDate;
  int? _editingCycleId;

  @override
  void initState() {
    super.initState();
    _cycleNameController = TextEditingController();
    _seedingDateController = TextEditingController();
    _loadCycles();
  }

  @override
  void dispose() {
    _cycleNameController.dispose();
    _seedingDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          'Farm Cycle',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadCycles,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Buat dan kelola farming cycle saat pembibitan dimulai.',
                style: TextStyle(color: _textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 16),
              _buildFormCard(),
              const SizedBox(height: 16),
              _buildCyclesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    final isEditing = _editingCycleId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit Farm Cycle' : 'Tambah Farm Cycle',
              style: const TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 6),
              const Text(
                'Mode edit aktif. Simpan perubahan untuk memperbarui data.',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _cycleNameController,
              validator: _validateRequired,
              decoration: InputDecoration(
                labelText: 'Cycle Name',
                filled: true,
                fillColor: _background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _seedingDateController,
              readOnly: true,
              validator: _validateDate,
              onTap: _pickSeedingDate,
              decoration: InputDecoration(
                labelText: 'Seeding Date',
                hintText: 'Pilih tanggal pembibitan',
                filled: true,
                fillColor: _background,
                suffixIcon: const Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        isEditing ? 'Simpan Perubahan' : 'Simpan Farm Cycle',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            if (isEditing) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _isSubmitting ? null : _cancelEdit,
                  child: const Text('Batal Edit'),
                ),
              ),
            ],
            if (_submitMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _submitMessage!,
                style: TextStyle(
                  color: _submitMessage!.toLowerCase().contains('berhasil')
                      ? _success
                      : Colors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCyclesSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daftar Farm Cycle',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          if (_isLoadingCycles)
            const Center(child: CircularProgressIndicator())
          else if (_loadError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadError!,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loadCycles,
                  child: const Text('Coba Lagi'),
                ),
              ],
            )
          else if (_cycles.isEmpty)
            const Text(
              'Belum ada farm cycle.',
              style: TextStyle(color: _textSecondary),
            )
          else
            Column(
              children: _cycles.map(_buildCycleTile).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildCycleTile(FarmCycle cycle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cycle.cycleName ?? '-',
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _startEdit(cycle),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit cycle',
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Seeding: ${_formatDate(cycle.seedingDate)}'),
          Text('Est. Harvest: ${_formatDate(cycle.estimatedHarvestDate)}'),
          Text('Status: ${cycle.status ?? '-'}'),
        ],
      ),
    );
  }

  void _startEdit(FarmCycle cycle) {
    setState(() {
      _editingCycleId = cycle.id;
      _cycleNameController.text = cycle.cycleName ?? '';
      _selectedSeedingDate = cycle.seedingDate;
      _seedingDateController.text = _formatDate(cycle.seedingDate);
      _submitMessage = null;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingCycleId = null;
      _cycleNameController.clear();
      _seedingDateController.clear();
      _selectedSeedingDate = null;
      _submitMessage = null;
    });
  }

  Future<void> _loadCycles() async {
    setState(() {
      _isLoadingCycles = true;
      _loadError = null;
    });

    try {
      final cycles = await FarmCycleService.getFarmCycles();
      if (!mounted) return;

      setState(() {
        _cycles = cycles;
        _isLoadingCycles = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loadError = error.toString();
        _isLoadingCycles = false;
      });
    }
  }

  Future<void> _pickSeedingDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedSeedingDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 5),
    );

    if (pickedDate == null || !mounted) return;

    setState(() {
      _selectedSeedingDate = pickedDate;
      _seedingDateController.text = _formatDate(pickedDate);
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _selectedSeedingDate == null) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _submitMessage = null;
    });

    final isEditing = _editingCycleId != null;
    final result = isEditing
        ? await FarmCycleService.updateFarmCycle(
            cycleId: _editingCycleId!,
            cycleName: _cycleNameController.text,
            seedingDate: _selectedSeedingDate!,
          )
        : await FarmCycleService.createFarmCycle(
            cycleName: _cycleNameController.text,
            seedingDate: _selectedSeedingDate!,
          );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _submitMessage = result.message;
    });

    if (result.success) {
      _cancelEdit();
      await _loadCycles();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: result.success ? _success : Colors.red,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field tidak boleh kosong';
    }
    return null;
  }

  String? _validateDate(String? value) {
    if (_selectedSeedingDate == null || value == null || value.trim().isEmpty) {
      return 'Tanggal seeding wajib dipilih';
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day-$month-${date.year}';
  }
}