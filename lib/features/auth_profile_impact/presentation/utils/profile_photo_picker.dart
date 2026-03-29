import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:savebite/features/auth_profile_impact/state/providers/auth_provider.dart';

String profilePhotoExtensionFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return '.png';
  if (lower.endsWith('.webp')) return '.webp';
  if (lower.endsWith('.jpeg')) return '.jpeg';
  return '.jpg';
}

String? profilePhotoContentTypeFromPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.jpeg') || lower.endsWith('.jpg')) return 'image/jpeg';
  return 'image/jpeg';
}

/// Shows camera/gallery choice, uploads via [AuthProvider], then optional snackbar.
Future<void> pickAndUploadProfilePhoto(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
        ],
      ),
    ),
  );

  if (source == null || !context.mounted) return;

  final picker = ImagePicker();
  final xfile = await picker.pickImage(
    source: source,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
  );

  if (xfile == null || !context.mounted) return;

  final bytes = await xfile.readAsBytes();
  if (!context.mounted) return;

  final ext = profilePhotoExtensionFromPath(xfile.path);
  final contentType = profilePhotoContentTypeFromPath(xfile.path);

  final auth = context.read<AuthProvider>();
  final ok = await auth.updateProfileImageFromBytes(
    bytes,
    fileExtension: ext,
    contentType: contentType,
  );

  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        ok ? 'Profile photo updated' : (auth.errorMessage ?? 'Could not upload photo'),
      ),
      backgroundColor: ok ? Colors.green : Colors.red,
    ),
  );
}
