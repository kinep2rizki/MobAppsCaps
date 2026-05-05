import 'package:flutter/material.dart';
import 'package:my_app/Services/ProfileService.dart';

class ChangePasswordPage extends StatefulWidget {
	const ChangePasswordPage({super.key});

	@override
	State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
	static const Color _background = Color(0xFFF9FAFB);
	static const Color _surface = Color(0xFFFFFFFF);
	static const Color _border = Color(0xFFE5E7EB);
	static const Color _primary = Color(0xFF2563EB);
	static const Color _textPrimary = Color(0xFF1F2937);
	static const Color _textSecondary = Color(0xFF6B7280);

	final _formKey = GlobalKey<FormState>();
	late final TextEditingController _oldPasswordController;
	late final TextEditingController _newPasswordController;
	late final TextEditingController _confirmPasswordController;

	bool _isSubmitting = false;
	bool _obscureOldPassword = true;
	bool _obscureNewPassword = true;
	bool _obscureConfirmPassword = true;

	@override
	void initState() {
		super.initState();
		_oldPasswordController = TextEditingController();
		_newPasswordController = TextEditingController();
		_confirmPasswordController = TextEditingController();
	}

	@override
	void dispose() {
		_oldPasswordController.dispose();
		_newPasswordController.dispose();
		_confirmPasswordController.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			backgroundColor: _background,
			appBar: AppBar(
				backgroundColor: _surface,
				elevation: 0,
				foregroundColor: _textPrimary,
				title: const Text(
					'Ubah Password',
					style: TextStyle(
						fontWeight: FontWeight.w700,
					),
				),
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(20),
					child: Form(
						key: _formKey,
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								const Text(
									'Ganti password akun kamu dari menu profil.',
									style: TextStyle(
										color: _textSecondary,
										fontSize: 14,
									),
								),
								const SizedBox(height: 20),
								_buildPasswordField(
									controller: _oldPasswordController,
									label: 'Password Lama',
									obscureText: _obscureOldPassword,
									onToggleVisibility: () {
										setState(() => _obscureOldPassword = !_obscureOldPassword);
									},
									validator: _validateRequired,
								),
								const SizedBox(height: 16),
								_buildPasswordField(
									controller: _newPasswordController,
									label: 'Password Baru',
									obscureText: _obscureNewPassword,
									onToggleVisibility: () {
										setState(() => _obscureNewPassword = !_obscureNewPassword);
									},
									validator: _validateNewPassword,
								),
								const SizedBox(height: 16),
								_buildPasswordField(
									controller: _confirmPasswordController,
									label: 'Konfirmasi Password Baru',
									obscureText: _obscureConfirmPassword,
									onToggleVisibility: () {
										setState(
											() => _obscureConfirmPassword = !_obscureConfirmPassword,
										);
									},
									validator: _validateConfirmPassword,
								),
								const SizedBox(height: 24),
								SizedBox(
									width: double.infinity,
									child: ElevatedButton(
										onPressed: _isSubmitting ? null : _submitChangePassword,
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
															valueColor:
																	AlwaysStoppedAnimation<Color>(Colors.white),
														),
													)
												: const Text(
														'Simpan Password Baru',
														style: TextStyle(
															fontSize: 16,
															fontWeight: FontWeight.w700,
														),
													),
									),
								),
							],
						),
					),
				),
			),
		);
	}

	Widget _buildPasswordField({
		required TextEditingController controller,
		required String label,
		required bool obscureText,
		required VoidCallback onToggleVisibility,
		String? Function(String?)? validator,
	}) {
		return TextFormField(
			controller: controller,
			obscureText: obscureText,
			validator: validator,
			decoration: InputDecoration(
				labelText: label,
				filled: true,
				fillColor: _surface,
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
				suffixIcon: IconButton(
					onPressed: onToggleVisibility,
					icon: Icon(
						obscureText
								? Icons.visibility_off_outlined
								: Icons.visibility_outlined,
					),
				),
			),
		);
	}

	String? _validateRequired(String? value) {
		if (value == null || value.trim().isEmpty) {
			return 'Field tidak boleh kosong';
		}
		return null;
	}

	String? _validateNewPassword(String? value) {
		final requiredError = _validateRequired(value);
		if (requiredError != null) return requiredError;

		if (value!.trim().length < 6) {
			return 'Password minimal 6 karakter';
		}

		return null;
	}

	String? _validateConfirmPassword(String? value) {
		final requiredError = _validateRequired(value);
		if (requiredError != null) return requiredError;

		if (value!.trim() != _newPasswordController.text.trim()) {
			return 'Konfirmasi password tidak sama';
		}

		return null;
	}

	Future<void> _submitChangePassword() async {
		final isValid = _formKey.currentState?.validate() ?? false;
		if (!isValid) return;

		FocusScope.of(context).unfocus();

		setState(() {
			_isSubmitting = true;
		});

		final result = await ProfileService.changePassword(
			oldPassword: _oldPasswordController.text,
			newPassword: _newPasswordController.text,
		);

		if (!mounted) {
			return;
		}

		setState(() {
			_isSubmitting = false;
		});

		ScaffoldMessenger.of(context).showSnackBar(
			SnackBar(
				content: Text(result.message),
				behavior: SnackBarBehavior.floating,
				backgroundColor: result.success ? Colors.green : Colors.red,
			),
		);

		if (result.success) {
			_oldPasswordController.clear();
			_newPasswordController.clear();
			_confirmPasswordController.clear();
		}
	}
}
