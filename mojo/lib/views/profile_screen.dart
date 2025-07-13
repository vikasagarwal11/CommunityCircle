import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';
import '../providers/community_providers.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../core/navigation_service.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';

class ProfileScreen extends HookConsumerWidget {
  final String? userId;
  
  const ProfileScreen({
    super.key,
    this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(authNotifierProvider);
    final userCommunitiesAsync = ref.watch(userCommunitiesProvider);
    final ownedCommunitiesAsync = ref.watch(ownedCommunitiesProvider);
    final isEditing = useState(false);
    final isLoading = useState(false);

    // Controllers for profile editing
    TextEditingController? nameController;
    TextEditingController? emailController;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        actions: [
          currentUserAsync.when(
            data: (user) {
              if (user != null && user.role != 'anonymous') {
                nameController ??= useTextEditingController(text: user.displayName ?? '');
                emailController ??= useTextEditingController(text: user.email ?? '');
                return IconButton(
                  icon: Icon(isEditing.value ? Icons.save : Icons.edit),
                  onPressed: () {
                    if (isEditing.value) {
                      _saveProfileChanges(context, ref, isLoading, nameController!, emailController!);
                    }
                    isEditing.value = !isEditing.value;
                  },
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Only show menu for non-anonymous users
          currentUserAsync.when(
            data: (user) => user != null && user.role != 'anonymous'
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'settings':
                          // Navigate to settings
                          break;
                        case 'logout':
                          _showLogoutDialog(context, ref);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'settings',
                        child: Row(
                          children: [
                            Icon(Icons.settings),
                            SizedBox(width: 8),
                            Text('Settings'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout),
                            SizedBox(width: 8),
                            Text('Logout'),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(
              child: Text('User not found'),
            );
          }
          if (user.role == 'anonymous') {
            // Show a sign-in prompt for guests
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Sign up to create your profile and join communities!'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      NavigationService.navigateToPhoneAuth();
                    },
                    child: const Text('Sign Up / Sign In'),
                  ),
                ],
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(context, user, isEditing, nameController!, emailController!),
                const SizedBox(height: AppConstants.largePadding),
                // User Stats
                _buildUserStats(context, user),
                const SizedBox(height: AppConstants.largePadding),
                // My Communities
                _buildMyCommunities(context, userCommunitiesAsync),
                const SizedBox(height: AppConstants.largePadding),
                // Owned Communities
                if (user.role != 'anonymous')
                  _buildOwnedCommunities(context, ownedCommunitiesAsync),
                const SizedBox(height: AppConstants.largePadding),
                // Account Settings
                _buildAccountSettings(context, user),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading profile: $error'),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    BuildContext context,
    UserModel user,
    ValueNotifier<bool> isEditing,
    TextEditingController nameController,
    TextEditingController emailController,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.largePadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: isEditing.value ? () => _pickAvatar(context) : null,
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                  child: user.profilePictureUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(47),
                          child: Image.network(
                            user.profilePictureUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Center(
                          child: Text(
                            (user.displayName?.isNotEmpty == true ? user.displayName![0].toUpperCase() : '?'),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                ),
                if (isEditing.value)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          // User Info
          if (isEditing.value) ...[
            TextField(
              controller: nameController,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            TextField(
              controller: emailController,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'Enter email address',
              ),
            ),
          ] else ...[
            Text(
              user.displayName ?? '',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              user.email ?? user.phoneNumber,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: AppConstants.defaultPadding),
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.smallPadding,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getRoleColor(context, user.role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getRoleColor(context, user.role),
                width: 1,
              ),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getRoleColor(context, user.role),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(BuildContext context, UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Communities',
            '${user.communityIds.length}',
            Icons.people,
            Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: _buildStatCard(
            context,
            'Points',
            '${user.totalPoints}',
            Icons.emoji_events,
            Theme.of(context).colorScheme.secondary,
          ),
        ),
        const SizedBox(width: AppConstants.smallPadding),
        Expanded(
          child: _buildStatCard(
            context,
            'Badges',
            '${user.badges.length}',
            Icons.workspace_premium,
            Theme.of(context).colorScheme.tertiary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCommunities(BuildContext context, AsyncValue<List<CommunityModel>> communitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Communities',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        SizedBox(
          height: 120,
          child: communitiesAsync.when(
            data: (communities) {
              if (communities.isEmpty) {
                return const Center(
                  child: Text('You haven\'t joined any communities yet'),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: AppConstants.smallPadding),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          NavigationService.navigateToCommunityDetails(community.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.smallPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                community.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                community.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${community.memberCount} members',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading communities: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnedCommunities(BuildContext context, AsyncValue<List<CommunityModel>> communitiesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communities I Own',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        SizedBox(
          height: 120,
          child: communitiesAsync.when(
            data: (communities) {
              if (communities.isEmpty) {
                return const Center(
                  child: Text('You haven\'t created any communities yet'),
                );
              }
              
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: communities.length,
                itemBuilder: (context, index) {
                  final community = communities[index];
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: AppConstants.smallPadding),
                    child: Card(
                      child: InkWell(
                        onTap: () {
                          NavigationService.navigateToCommunityDetails(community.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.smallPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      community.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'OWNER',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                community.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  Icon(
                                    Icons.people,
                                    size: 12,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${community.memberCount} members',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Text('Error loading communities: $error'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSettings(BuildContext context, UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Account Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        Card(
          child: Column(
            children: [
              if (user.role == 'anonymous') ...[
                ListTile(
                  leading: Icon(Icons.login, color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Sign Up for Full Access'),
                  subtitle: const Text('Unlock all features and communities'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    NavigationService.navigateToPhoneAuth();
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Guest Mode'),
                  subtitle: const Text('Limited access to public content'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'GUEST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: const Text('Notifications'),
                  subtitle: const Text('Manage notification preferences'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to notifications settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip),
                  title: const Text('Privacy'),
                  subtitle: const Text('Manage your privacy settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to privacy settings
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.security),
                  title: const Text('Security'),
                  subtitle: const Text('Manage account security'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Navigate to security settings
                  },
                ),
                const Divider(height: 1),
              ],
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help and contact support'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // Navigate to help and support
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRoleColor(BuildContext context, String role) {
    switch (role) {
      case 'admin':
        return Theme.of(context).colorScheme.error;
      case 'moderator':
        return Theme.of(context).colorScheme.tertiary;
      case 'member':
        return Theme.of(context).colorScheme.primary;
      case 'business':
        return Theme.of(context).colorScheme.secondary;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  void _pickAvatar(BuildContext context) {
    // TODO: Implement image picker
    NavigationService.showSnackBar(
      message: 'Avatar upload coming soon!',
    );
  }

  void _saveProfileChanges(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isLoading,
    TextEditingController nameController,
    TextEditingController emailController,
  ) async {
    isLoading.value = true;
    final currentUser = ref.read(authNotifierProvider).value;
    if (currentUser == null) return;
    try {
      await ref.read(authNotifierProvider.notifier).updateProfile(
        displayName: nameController.text.trim(),
        email: emailController.text.trim(),
      );
      NavigationService.showSnackBar(
        message: 'Profile updated successfully!',
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );
    } catch (e) {
      NavigationService.showSnackBar(
        message: 'Failed to update profile: $e',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => NavigationService.goBack(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              NavigationService.goBack();
              await ref.read(authNotifierProvider.notifier).signOut();
              NavigationService.navigateToPhoneAuth();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
} 