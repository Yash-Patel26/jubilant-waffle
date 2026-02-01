import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gamer_flick/models/community/community.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/providers/community/community_notifier.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/repositories/storage/storage_repository.dart';
import '../shared/image_cropper_screen.dart';

class CommunitySettingsScreen extends ConsumerStatefulWidget {
  final Community community;
  const CommunitySettingsScreen({super.key, required this.community});

  @override
  ConsumerState<CommunitySettingsScreen> createState() =>
      _CommunitySettingsScreenState();
}

class _CommunitySettingsScreenState extends ConsumerState<CommunitySettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  late TextEditingController _gameController;
  late TextEditingController _rulesController;
  bool _isPublic = true;
  XFile? _pickedImage;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.community.name);
    _descriptionController =
        TextEditingController(text: widget.community.description);
    _tagsController =
        TextEditingController(text: widget.community.tags.join(', '));
    _gameController = TextEditingController(text: widget.community.game ?? '');
    _rulesController = TextEditingController(); // Add rules to model if needed
    _isPublic = widget.community.isPublic;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _gameController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      // Show cropping screen
      final croppedFile = await Navigator.of(context).push<XFile>(
        MaterialPageRoute(
          builder: (context) => ImageCropperScreen(
            selectedImage: picked,
            title: 'Crop Community Image',
            aspectRatio: 'square', // Square aspect ratio for community images
          ),
        ),
      );

      if (croppedFile != null) {
        setState(() {
          _pickedImage = croppedFile;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Community Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(_error!,
                    style: TextStyle(color: theme.colorScheme.error)),
              ),
            if (_isSaving) const Center(child: CircularProgressIndicator()),
            if (!_isSaving) ...[
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : (widget.community.imageUrl != null
                              ? NetworkImage(widget.community.imageUrl!)
                              : null) as ImageProvider<Object>?,
                      child: (_pickedImage == null &&
                              widget.community.imageUrl == null)
                          ? const Icon(Icons.group, size: 48)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.crop,
                            color: theme.colorScheme.onPrimary,
                            size: 20,
                          ),
                          onPressed: _pickImage,
                          tooltip: 'Change & Crop Image',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Community Name'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tagsController,
                decoration:
                    const InputDecoration(labelText: 'Tags (comma separated)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _gameController,
                decoration: const InputDecoration(labelText: 'Game'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Public Community'),
                  Switch(
                    value: _isPublic,
                    onChanged: (val) => setState(() => _isPublic = val),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _rulesController,
                decoration:
                    const InputDecoration(labelText: 'Rules/Guidelines'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    onPressed: () async {
                      setState(() {
                        _isSaving = true;
                        _error = null;
                      });
                      try {
                        String? imageUrl = widget.community.imageUrl;
                        if (_pickedImage != null) {
                          final user =
                              Supabase.instance.client.auth.currentUser;
                          if (user == null) throw Exception('Not logged in');
                          final storageRepo = ref.read(storageRepositoryProvider);
                          imageUrl =
                              await storageRepo.uploadCommunityPostImage(
                            _pickedImage!,
                            user.id,
                            widget.community.id,
                          );
                        }
                        final updatedCommunity = widget.community.copyWith(
                          name: _nameController.text.trim(),
                          description: _descriptionController.text.trim(),
                          tags: _tagsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList(),
                          game: _gameController.text.trim(),
                          isPublic: _isPublic,
                          imageUrl: imageUrl,
                          // Add rules if you add to model
                        );
                        await ref.read(communitiesProvider.notifier).updateCommunity(updatedCommunity);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() {
                          _error = e.toString();
                        });
                      } finally {
                        if (mounted) setState(() => _isSaving = false);
                      }
                    },
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  if (Supabase.instance.client.auth.currentUser?.id ==
                      widget.community.createdBy) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Community'),
                            content: const Text(
                                'Are you sure you want to delete this community? This action cannot be undone.'),
                            actions: [
                              TextButton(
                                child: const Text('Cancel'),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text('Delete'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          setState(() => _isSaving = true);
                          try {
                            await ref.read(communitiesProvider.notifier).deleteCommunity(widget.community.id);
                            if (mounted) {
                              Navigator.of(context).pushNamedAndRemoveUntil(
                                  '/Home', (route) => false);
                            }
                          } catch (e) {
                            setState(() {
                              _error = e.toString();
                            });
                          } finally {
                            if (mounted) setState(() => _isSaving = false);
                          }
                        }
                      },
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
