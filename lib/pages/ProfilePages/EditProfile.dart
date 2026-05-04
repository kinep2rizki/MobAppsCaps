import 'package:flutter/material.dart';
import 'package:my_app/Services/ProfileService.dart';
import 'package:my_app/pages/ProfilePages/UpPhoto.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const Color _textPrimary = Color(0xFF1F2937);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _background = Color(0xFFF9FAFB);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _primary = Color(0xFF2563EB);
  static const Color _successBg = Color(0xFFD1FAE5);
  static const Color _successText = Color(0xFF047857);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _namaController;
  late final TextEditingController _emailController;
  late final TextEditingController _teleponController;
  late final TextEditingController _lokasiController;
  late final TextEditingController _alamatController;
  final GlobalKey<UpPhotoSectionState> _photoSectionKey =
      GlobalKey<UpPhotoSectionState>();
  String? _profilePhotoUrl;

  bool _saved = false;
  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
    _emailController = TextEditingController();
    _teleponController = TextEditingController();
    _lokasiController = TextEditingController();
    _alamatController = TextEditingController();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _lokasiController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: _isLoadingProfile
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      if (_loadError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _loadError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      _buildAvatarSection(),
                      const SizedBox(height: 20),
                      _buildLabel('Nama Lengkap'),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _namaController),
                      const SizedBox(height: 18),
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: _validateEmail,
                        readOnly: true,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Nomor Telepon'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _teleponController,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 18),
                      _buildLabel('Lokasi Greenhouse'),
                      const SizedBox(height: 8),
                      _buildTextField(controller: _lokasiController),
                      const SizedBox(height: 18),
                      _buildLabel('Alamat Lengkap'),
                      const SizedBox(height: 8),
                      _buildTextField(
                          controller: _alamatController, maxLines: 3),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isLoadingProfile || _isSavingProfile)
                              ? null
                              : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _isSavingProfile
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Simpan Data',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_saved) _buildSavedInfo(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).maybePop(),
          borderRadius: BorderRadius.circular(20),
          child: const Icon(Icons.arrow_back_ios_new,
              size: 22, color: _textSecondary),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 38 / 2,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Ubah informasi akun',
              style: TextStyle(color: _textSecondary, fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAvatarSection() {
    return UpPhotoSection(
      key: _photoSectionKey,
      initialPhotoUrl: _profilePhotoUrl,
      onChanged: () {
        if (_saved) {
          setState(() => _saved = false);
        }
      },
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      readOnly: readOnly,
      onChanged: (_) {
        if (_saved) {
          setState(() => _saved = false);
        }
      },
      validator: validator ?? _validateRequired,
      decoration: InputDecoration(
        filled: true,
        fillColor: _surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      style: const TextStyle(
        color: _textPrimary,
        fontSize: 33 / 2,
      ),
    );
  }

  Widget _buildSavedInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _successBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline, color: _successText, size: 18),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Tersimpan',
                  style: TextStyle(
                    color: _successText,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Semua informasi profile sudah diperbarui',
                  style: TextStyle(
                    color: _successText,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Field tidak boleh kosong';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final requiredError = _validateRequired(value);
    if (requiredError != null) return requiredError;
    final email = value!.trim();
    if (!email.contains('@') || !email.contains('.')) {
      return 'Format email tidak valid';
    }
    return null;
  }

  Future<void> _loadCurrentProfile() async {
    final result = await ProfileService.getMyProfile();

    if (!mounted) {
      return;
    }

    if (!result.success || result.profile == null) {
      setState(() {
        _isLoadingProfile = false;
        _loadError = result.message;
      });
      return;
    }

    final profile = result.profile!;
    setState(() {
      _namaController.text = profile.fullName ?? '';
      _emailController.text = profile.email ?? '';
      _teleponController.text = profile.phoneNumber ?? '';
      _lokasiController.text = profile.greenhouseLocation ?? '';
      _alamatController.text = profile.address ?? '';
      _profilePhotoUrl = profile.profilePhotoUrl;
      _isLoadingProfile = false;
      _loadError = null;
    });
  }

  Future<void> _saveProfile() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSavingProfile = true;
      _loadError = null;
    });

    final result = await ProfileService.updateMyProfile(
      fullName: _namaController.text,
      phoneNumber: _teleponController.text,
      greenhouseLocation: _lokasiController.text,
      address: _alamatController.text,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      setState(() {
        _isSavingProfile = false;
        _loadError = result.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final photoResult =
        await _photoSectionKey.currentState?.uploadSelectedPhoto() ??
            const ProfileResult(
                success: true, message: 'Tidak ada foto baru untuk diupload');

    if (!mounted) {
      return;
    }

    if (!photoResult.success) {
      setState(() {
        _isSavingProfile = false;
        _loadError = photoResult.message;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(photoResult.message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedProfile = result.profile;
    if (updatedProfile != null) {
      _namaController.text = updatedProfile.fullName ?? _namaController.text;
      _emailController.text = updatedProfile.email ?? _emailController.text;
      _teleponController.text =
          updatedProfile.phoneNumber ?? _teleponController.text;
      _lokasiController.text =
          updatedProfile.greenhouseLocation ?? _lokasiController.text;
      _alamatController.text = updatedProfile.address ?? _alamatController.text;
      _profilePhotoUrl = updatedProfile.profilePhotoUrl ?? _profilePhotoUrl;
    }

    setState(() {
      _saved = true;
      _isSavingProfile = false;
      _loadError = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
