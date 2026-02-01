import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/profile_picture_uploader.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const EditProfileScreen({super.key, required this.userProfile});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  late TextEditingController _gameController;
  late TextEditingController _gamingIdController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: widget.userProfile['username'],
    );
    _bioController = TextEditingController(
      text: widget.userProfile['bio'] ?? '',
    );
    _gameController = TextEditingController(
      text: widget.userProfile['preferred_game'] ?? '',
    );
    _gamingIdController = TextEditingController(
      text: widget.userProfile['gaming_id'] ?? '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    _gameController.dispose();
    _gamingIdController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final theme = Theme.of(context);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      await Supabase.instance.client.from('profiles').update({
        'username': _usernameController.text.trim(),
        'bio': _bioController.text.trim(),
        'preferred_game': _gameController.text.trim(),
        'gaming_id': _gamingIdController.text.trim(),
      }).eq('id', currentUser.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: theme.colorScheme.secondary,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: const [
          // The save button is now at the bottom
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Center(
                child: ProfilePictureUploader(
                  userId: Supabase.instance.client.auth.currentUser!.id,
                  currentUrl: widget.userProfile['profile_picture_url'],
                  onUploaded: (newUrl) {
                    // This is handled automatically by the widget, but you could
                    // force a state update here if needed.
                  },
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildTextFormField(
                controller: _usernameController,
                labelText: 'Username',
                validator: (val) => val!.isEmpty ? 'Cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _bioController,
                labelText: 'Bio',
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _gameController,
                labelText: 'Preferred Game',
                hintText: 'e.g., Valorant, CS:GO, etc.',
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _gamingIdController,
                labelText: 'Gaming ID',
                hintText: 'e.g., YourRiotID#1234',
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Changes'),
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          labelText,
          style: TextStyle(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
          ),
        ),
      ],
    );
  }
}
