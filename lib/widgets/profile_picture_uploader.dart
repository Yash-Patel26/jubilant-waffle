import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/repositories/storage/storage_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show File; // Only used on mobile
import 'safe_network_image.dart';

class ProfilePictureUploader extends ConsumerStatefulWidget {
  final String userId;
  final String? currentUrl;
  final void Function(String newUrl)? onUploaded;

  const ProfilePictureUploader({
    super.key,
    required this.userId,
    this.currentUrl,
    this.onUploaded,
  });

  @override
  ConsumerState<ProfilePictureUploader> createState() => _ProfilePictureUploaderState();
}

class _ProfilePictureUploaderState extends ConsumerState<ProfilePictureUploader> {
  Uint8List? _webImageBytes;
  File? _imageFile;
  bool _isUploading = false;
  String? _uploadedUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _imageFile = null;
        });
      } else {
        setState(() {
          _imageFile = File(picked.path);
          _webImageBytes = null;
        });
      }
      await _uploadImage(picked);
    }
  }

  Future<void> _uploadImage(XFile picked) async {
    setState(() => _isUploading = true);
    try {
      final storageRepo = ref.read(storageRepositoryProvider);
      final publicUrl = await storageRepo.uploadAvatar(picked, widget.userId);

      if (publicUrl == null) {
        throw Exception('Upload failed: Invalid response');
      }

      // Update the profile in the database
      final supabase = Supabase.instance.client;
      await supabase
          .from('profiles')
          .update({'profile_picture_url': publicUrl}).eq('id', widget.userId);

      setState(() {
        _uploadedUrl = publicUrl;
        _isUploading = false;
      });

      if (widget.onUploaded != null) {
        widget.onUploaded!(publicUrl);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isUploading = false);

      String errorMessage = 'Upload failed.';
      if (e.toString().contains('409')) {
        errorMessage = 'File already exists. Please try again.';
      } else if (e.toString().contains('400')) {
        errorMessage = 'Invalid file format. Please try a different image.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _uploadedUrl ?? widget.currentUrl;

    return Column(
      children: [
        Stack(
          children: [
            // Show memory image if available (for web uploads)
            if (_webImageBytes != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: MemoryImage(_webImageBytes!),
              )
            // Show file image if available (for mobile uploads)
            else if (_imageFile != null)
              CircleAvatar(
                radius: 50,
                backgroundImage: FileImage(_imageFile!),
              )
            // Show network image with error handling
            else if (imageUrl != null)
              SafeCircleAvatar(
                imageUrl: imageUrl,
                radius: 50,
              )
            // Show fallback
            else
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 50, color: Colors.grey),
              ),
            Positioned(
              bottom: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _isUploading ? null : _pickImage,
              ),
            ),
          ],
        ),
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: CircularProgressIndicator(),
          ),
      ],
    );
  }
}
