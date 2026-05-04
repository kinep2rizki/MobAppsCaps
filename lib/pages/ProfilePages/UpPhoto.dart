import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/Services/ProfileService.dart';

class UpPhotoSection extends StatefulWidget {
  const UpPhotoSection({
    super.key,
    this.initialPhotoUrl,
    this.onChanged,
  });

  final String? initialPhotoUrl;
  final VoidCallback? onChanged;

  @override
  State<UpPhotoSection> createState() => UpPhotoSectionState();
}

class UpPhotoSectionState extends State<UpPhotoSection> {
  static const Color _primary = Color(0xFF2563EB);

  final ImagePicker _picker = ImagePicker();
  File? _selectedPhoto;
  String? _remotePhotoUrl;
  String? _photoError;

  @override
  void initState() {
    super.initState();
    _remotePhotoUrl = widget.initialPhotoUrl;
  }

  @override
  void didUpdateWidget(covariant UpPhotoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPhotoUrl != widget.initialPhotoUrl &&
        _selectedPhoto == null) {
      _remotePhotoUrl = widget.initialPhotoUrl;
    }
  }

  Future<ProfileResult> uploadSelectedPhoto() async {
    final photo = _selectedPhoto;
    if (photo == null) {
      return const ProfileResult(
        success: true,
        message: 'Tidak ada foto baru untuk diupload',
      );
    }

    final result = await ProfileService.uploadProfilePhoto(photoFile: photo);

    if (!mounted) {
      return result;
    }

    if (result.success) {
      setState(() {
        _photoError = null;
        _selectedPhoto = null;
        _remotePhotoUrl = result.profile?.profilePhotoUrl ?? _remotePhotoUrl;
      });
    } else {
      setState(() {
        _photoError = result.message;
      });
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
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
              child: _buildAvatarContent(),
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
          if (_photoError != null) ...[
            const SizedBox(height: 4),
            Text(
              _photoError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatarContent() {
    if (_selectedPhoto != null) {
      return Image.file(
        _selectedPhoto!,
        fit: BoxFit.cover,
        width: 88,
        height: 88,
      );
    }

    final remoteUrl = _remotePhotoUrl;
    if (remoteUrl != null && remoteUrl.trim().isNotEmpty) {
      return Image.network(
        remoteUrl,
        fit: BoxFit.cover,
        width: 88,
        height: 88,
        errorBuilder: (_, __, ___) {
          return const Icon(
            Icons.person_2_outlined,
            size: 46,
            color: Colors.white,
          );
        },
      );
    }

    return const Icon(Icons.person_2_outlined, size: 46, color: Colors.white);
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
                if (_selectedPhoto != null || _remotePhotoUrl != null)
                  ListTile(
                    leading:
                        const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text(
                      'Hapus Foto',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.of(context).pop();
                      setState(() {
                        _selectedPhoto = null;
                        _remotePhotoUrl = null;
                        _photoError = null;
                      });
                      widget.onChanged?.call();
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
        _selectedPhoto = File(image.path);
        _photoError = null;
      });

      widget.onChanged?.call();
    } on PlatformException catch (e) {
      if (!mounted) return;

      String message = 'Tidak dapat mengakses kamera/galeri.';
      if (e.code == 'camera_access_denied') {
        message =
            'Izin kamera ditolak. Aktifkan izin kamera di Settings emulator.';
      } else if (e.code == 'photo_access_denied' ||
          e.code == 'storage_access_denied') {
        message =
            'Izin galeri ditolak. Aktifkan izin foto/media di Settings emulator.';
      } else if (e.code == 'no_available_camera') {
        message =
            'Kamera emulator tidak tersedia. Gunakan galeri atau aktifkan kamera AVD.';
      }

      setState(() {
        _photoError = message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _photoError = 'Terjadi kendala saat mengambil foto. Coba lagi.';
      });
    }
  }
}
