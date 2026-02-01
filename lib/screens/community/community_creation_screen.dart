import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/community/community_notifier.dart';
import 'package:gamer_flick/repositories/storage/storage_repository.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../shared/image_cropper_screen.dart';

class CommunityCreationScreen extends ConsumerStatefulWidget {
  const CommunityCreationScreen({super.key});

  @override
  ConsumerState<CommunityCreationScreen> createState() =>
      _CommunityCreationScreenState();
}

class _CommunityCreationScreenState extends ConsumerState<CommunityCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _gameController = TextEditingController();
  bool _isPublic = true;
  XFile? _pickedImage;
  String? _uploadedImageUrl;
  bool _isUploading = false;
  // TODO: Add image picker logic

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Create Community'),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? double.infinity : 600,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Community Name Section
                      _buildFormSection(
                        theme,
                        'Community Name',
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText:
                                'e.g. Valorant SEA, Indie Devs, NYC Board Games',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                                  ? 'Name required'
                                  : null,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Description Section
                      _buildFormSection(
                        theme,
                        'Description',
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            hintText: 'Say a few words about your community...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                          maxLines: 4,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Public Community Section
                      _buildFormSection(
                        theme,
                        'Public Community',
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Anyone can find and join this community',
                                style: TextStyle(
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                            Switch(
                              value: _isPublic,
                              onChanged: (val) =>
                                  setState(() => _isPublic = val),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Community Image Section
                      _buildFormSection(
                        theme,
                        'Community Image',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select an image for your community. You can crop it to fit perfectly.',
                              style: TextStyle(
                                fontSize: 14,
                                color: theme.textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Crop Available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildImageUploadArea(theme),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Game Section
                      _buildFormSection(
                        theme,
                        'Game (optional)',
                        TextFormField(
                          controller: _gameController,
                          decoration: InputDecoration(
                            hintText: 'e.g. Valorant',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: theme.cardColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tags Section
                      _buildFormSection(
                        theme,
                        'Tags',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _tagsController,
                              decoration: InputDecoration(
                                hintText:
                                    'Type a tag and press Enter (or comma)',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: theme.cardColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: theme.textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Add up to 8 tags to help people find your community.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Create Community Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isUploading ? null : _createCommunity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isUploading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Create Community',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
        },
      ),
    );
  }

  Widget _buildFormSection(ThemeData theme, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildImageUploadArea(ThemeData theme) {
    return GestureDetector(
      onTap: () async {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          // Show cropping screen
          final croppedFile = await Navigator.of(context).push<XFile>(
            MaterialPageRoute(
              builder: (context) => ImageCropperScreen(
                selectedImage: picked,
                title: 'Crop Community Image',
                aspectRatio: 'square',
              ),
            ),
          );

          if (croppedFile != null) {
            setState(() {
              _pickedImage = croppedFile;
            });
            setState(() => _isUploading = true);
            final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
            final storageRepo = ref.read(storageRepositoryProvider);
            final url = await storageRepo.uploadCommunityPostImage(
              croppedFile,
              userId,
              'new',
            );
            setState(() {
              _uploadedImageUrl = url;
              _isUploading = false;
            });
          }
        }
      },
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor,
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: _pickedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                    ? Image.network(
                        _pickedImage!.path,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildUploadPlaceholder(theme);
                        },
                      )
                    : Image.file(
                        File(_pickedImage!.path),
                        fit: BoxFit.cover,
                      ),
              )
            : _buildUploadPlaceholder(theme),
      ),
    );
  }

  Widget _buildUploadPlaceholder(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.camera_alt,
          size: 32,
          color: theme.textTheme.bodySmall?.color,
        ),
        const SizedBox(height: 8),
        Text(
          'Add Image',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Click or drop a file. Tap to crop.',
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  void _createCommunity() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);
      final userId = Supabase.instance.client.auth.currentUser?.id ?? '';
      final community = Community(
        id: '', // Will be set by backend
        name: _nameController.text.trim(),
        displayName: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: _uploadedImageUrl,
        isPublic: _isPublic,
        isVerified: false,
        memberCount: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: userId,
        game: _gameController.text.trim().isEmpty
            ? null
            : _gameController.text.trim(),
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );
      await ref.read(communitiesProvider.notifier).createCommunity(community);
      setState(() => _isUploading = false);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Community created!')),
        );
      }
    }
  }
}
