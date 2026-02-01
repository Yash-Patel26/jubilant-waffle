import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart' as legacy;
import 'package:gamer_flick/models/community/community_role.dart';
import 'package:gamer_flick/providers/community/community_role_provider.dart';
import 'package:gamer_flick/services/community/community_member_service.dart';
import 'package:gamer_flick/repositories/user/user_repository.dart';
import 'package:gamer_flick/models/core/profile.dart';

// Allowed roles for assignment
const List<String> allowedRoles = ['admin', 'moderator', 'member'];

class CommunityRolesScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CommunityRolesScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityRolesScreen> createState() => _CommunityRolesScreenState();
}

class _CommunityRolesScreenState extends ConsumerState<CommunityRolesScreen> {
  List<Profile> _memberProfiles = [];
  bool _loadingMembers = true;

  @override
  void initState() {
    super.initState();
    _fetchMembersAndProfiles();
  }

  Future<void> _fetchMembersAndProfiles() async {
    setState(() => _loadingMembers = true);
    final members =
        await CommunityMemberService().fetchMembers(widget.communityId);
    final userIds = members.map((m) => m.userId).toList();
    final profiles = await ref.read(userRepositoryProvider).getProfilesByUserIds(userIds);
    setState(() {
      _memberProfiles = profiles;
      _loadingMembers = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return legacy.ChangeNotifierProvider(
      create: (_) => CommunityRoleProvider()..loadRoles(widget.communityId),
      child: Scaffold(
        appBar: AppBar(title: const Text('Roles & Permissions')),
        body: legacy.Consumer<CommunityRoleProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading || _loadingMembers) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: ${provider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        provider.loadRoles(widget.communityId);
                        _fetchMembersAndProfiles();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Roles',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add Role'),
                      onPressed: () async {
                        // Show dialog to add role
                        String name = '';
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Add Role'),
                            content: TextField(
                              autofocus: true,
                              decoration:
                                  const InputDecoration(labelText: 'Role Name'),
                              onChanged: (val) => name = val,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  if (name.trim().isNotEmpty) {
                                    provider.addRole(CommunityRole(
                                      id: DateTime.now()
                                          .millisecondsSinceEpoch
                                          .toString(),
                                      communityId: widget.communityId,
                                      name: name.trim(),
                                    ));
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text('Add'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...provider.roles.map((role) => Card(
                      child: ExpansionTile(
                        title: Text(role.name),
                        subtitle: Text(role.isDefault ? 'Default' : ''),
                        children: [
                          Wrap(
                            spacing: 8,
                            children: [
                              _PermissionCheckbox(
                                  role: role,
                                  permission: 'can_pin_posts',
                                  label: 'Pin Posts'),
                              _PermissionCheckbox(
                                  role: role,
                                  permission: 'can_ban_members',
                                  label: 'Ban Members'),
                              _PermissionCheckbox(
                                  role: role,
                                  permission: 'can_edit_settings',
                                  label: 'Edit Settings'),
                              _PermissionCheckbox(
                                  role: role,
                                  permission: 'can_create_events',
                                  label: 'Create Events'),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!role.isDefault)
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => provider.deleteRole(role.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 32),
                const Text('Assign Roles to Members',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ..._memberProfiles.map((profile) => ListTile(
                      title: Text(profile.displayName.isNotEmpty
                          ? profile.displayName
                          : (profile.username.isNotEmpty
                              ? profile.username
                              : profile.id)),
                      trailing: DropdownButton<String>(
                        value: provider.getMemberRole(profile.id),
                        items: allowedRoles
                            .map((role) => DropdownMenuItem(
                                value: role,
                                child: Text(
                                    role[0].toUpperCase() + role.substring(1))))
                            .toList(),
                        onChanged: (role) async {
                          if (role != null) {
                            try {
                              await provider.assignRoleToMember(
                                  widget.communityId, profile.id, role);

                              // Refresh the roles to ensure UI is updated
                              await provider.refresh(widget.communityId);

                              // Show success feedback
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Role updated to ${role[0].toUpperCase() + role.substring(1)}'),
                                    backgroundColor: Colors.green,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              // Show error feedback
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed to update role: ${e.toString()}'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                    )),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PermissionCheckbox extends StatelessWidget {
  final CommunityRole role;
  final String permission;
  final String label;
  const _PermissionCheckbox(
      {required this.role, required this.permission, required this.label});

  @override
  Widget build(BuildContext context) {
    final provider = legacy.Provider.of<CommunityRoleProvider>(context, listen: false);
    final hasPermission = role.permissions.contains(permission);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: hasPermission,
          onChanged: (val) {
            final updated = CommunityRole(
              id: role.id,
              communityId: role.communityId,
              name: role.name,
              description: role.description,
              isDefault: role.isDefault,
              permissions: val == true
                  ? [...role.permissions, permission]
                  : role.permissions.where((p) => p != permission).toList(),
            );
            provider.updateRole(updated);
          },
        ),
        Text(label),
      ],
    );
  }
}
