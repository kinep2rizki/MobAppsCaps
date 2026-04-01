import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';

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
	final ImagePicker _picker = ImagePicker();
	File? _profileImage;

	bool _saved = false;

	@override
	void initState() {
		super.initState();
		_namaController = TextEditingController(text: 'Budidaya nila');
		_emailController = TextEditingController(text: 'budidayanila@telkomuniversity.ac.id');
		_teleponController = TextEditingController(text: '+62-858-1665-7890');
		_lokasiController = TextEditingController(text: 'Greenhouse Telyu');
		_alamatController = TextEditingController(
			text: 'Jl.Telekomunikasi no.4 kecamatan sukapura\nbandung wetan, bandung, indonesia',
		);
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
				child: SingleChildScrollView(
					padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
					child: Form(
						key: _formKey,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								_buildHeader(context),
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
								_buildTextField(controller: _alamatController, maxLines: 3),
								const SizedBox(height: 18),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: _saveProfile,
										style: ElevatedButton.styleFrom(
											backgroundColor: _primary,
											foregroundColor: Colors.white,
											elevation: 0,
											shape: RoundedRectangleBorder(
												borderRadius: BorderRadius.circular(12),
											),
											padding: const EdgeInsets.symmetric(vertical: 14),
										),
										child: const Text(
											'Simpan Data',
											style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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
					child: const Icon(Icons.arrow_back_ios_new, size: 22, color: _textSecondary),
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
		return Center(
			child: Column(
				children: [
					Container(
						width: 88,
						height: 88,
						decoration: const BoxDecoration(
							color: _primary,
							shape: BoxShape.circle,
						),
						child: ClipOval(
							child: _profileImage != null
								? Image.file(
										_profileImage!,
										fit: BoxFit.cover,
										width: 88,
										height: 88,
									)
								: const Icon(Icons.person_2_outlined, size: 46, color: Colors.white),
						),
					),
					const SizedBox(height: 10),
					TextButton(
						onPressed: _showImageSourcePicker,
						child: const Text(
							'Ubah Foto Profile',
							style: TextStyle(
								color: _primary,
								fontSize: 16,
								fontWeight: FontWeight.w700,
							),
						),
					),
				],
			),
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
	}) {
		return TextFormField(
			controller: controller,
			keyboardType: keyboardType,
			maxLines: maxLines,
			onChanged: (_) {
				if (_saved) {
					setState(() => _saved = false);
				}
			},
			validator: validator ?? _validateRequired,
			decoration: InputDecoration(
				filled: true,
				fillColor: _surface,
				contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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

	void _saveProfile() {
		final isValid = _formKey.currentState?.validate() ?? false;
		if (!isValid) return;

		FocusScope.of(context).unfocus();
		setState(() => _saved = true);

		ScaffoldMessenger.of(context).showSnackBar(
			const SnackBar(
				content: Text('Profil berhasil diperbarui'),
				behavior: SnackBarBehavior.floating,
			),
		);
	}

	Future<void> _showImageSourcePicker() async {
		if (!mounted) return;
		await showModalBottomSheet<void>(
			context: context,
			shape: const RoundedRectangleBorder(
				borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
			),
			builder: (context) {
				return SafeArea(
					child: Padding(
						padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
						child: Column(
							mainAxisSize: MainAxisSize.min,
							children: [
								ListTile(
									leading: const Icon(Icons.photo_library_outlined),
									title: const Text('Pilih dari Galeri'),
									onTap: () {
										Navigator.of(context).pop();
										_pickImage(ImageSource.gallery);
									},
								),
								ListTile(
									leading: const Icon(Icons.camera_alt_outlined),
									title: const Text('Ambil dari Kamera'),
									onTap: () {
										Navigator.of(context).pop();
										_pickImage(ImageSource.camera);
									},
								),
								if (_profileImage != null)
									ListTile(
										leading: const Icon(Icons.delete_outline, color: Colors.red),
										title: const Text('Hapus Foto', style: TextStyle(color: Colors.red)),
										onTap: () {
											Navigator.of(context).pop();
											setState(() => _profileImage = null);
										},
									),
							],
						),
					),
				);
			},
		);
	}

	Future<void> _pickImage(ImageSource source) async {
		try {
			final XFile? image = await _picker.pickImage(
				source: source,
				imageQuality: 85,
				maxWidth: 1080,
			);

			if (image == null || !mounted) return;

			setState(() {
				_profileImage = File(image.path);
				_saved = false;
			});
		} on PlatformException catch (e) {
			if (!mounted) return;

			String message = 'Tidak dapat mengakses kamera/galeri.';
			if (e.code == 'camera_access_denied') {
				message = 'Izin kamera ditolak. Aktifkan izin kamera di Settings emulator.';
			} else if (e.code == 'photo_access_denied' || e.code == 'storage_access_denied') {
				message = 'Izin galeri ditolak. Aktifkan izin foto/media di Settings emulator.';
			} else if (e.code == 'no_available_camera') {
				message = 'Kamera emulator tidak tersedia. Gunakan galeri atau aktifkan kamera AVD.';
			}

			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				SnackBar(
					content: Text(message),
					behavior: SnackBarBehavior.floating,
				),
			);
		} catch (_) {
			if (!mounted) return;
			ScaffoldMessenger.of(context).showSnackBar(
				const SnackBar(
					content: Text('Terjadi kendala saat mengambil foto. Coba lagi.'),
					behavior: SnackBarBehavior.floating,
				),
			);
		}
	}
}
