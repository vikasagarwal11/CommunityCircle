import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/chat_providers.dart';
import '../core/navigation_service.dart';
import '../models/user_model.dart';

class UserSearchScreen extends HookConsumerWidget {
  const UserSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = useState('');
    final results = ref.watch(userSearchOrSuggestedProvider(query.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Find People')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (val) => query.value = val,
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (query.value.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Suggested', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          Expanded(
            child: results.when(
              data: (users) => users.isEmpty
                  ? const Center(child: Text('No users found.'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final user = users[i];
                        return GestureDetector(
                          onTap: () async {
                            final chat = await ref.read(startPersonalChatProvider(user.id).future);
                            NavigationService.navigateToPersonalChat(user.id);
                          },
                          child: ListTile(
                            leading: user.profilePictureUrl != null
                                ? CircleAvatar(backgroundImage: NetworkImage(user.profilePictureUrl!))
                                : CircleAvatar(child: Text(user.displayName?.substring(0, 1) ?? '?')),
                            title: Text(user.displayName ?? user.phoneNumber),
                            subtitle: Text(user.email ?? ''),
                            trailing: IconButton(
                              icon: const Icon(Icons.message),
                              onPressed: () async {
                                final chat = await ref.read(startPersonalChatProvider(user.id).future);
                                NavigationService.navigateToPersonalChat(user.id);
                              },
                            ),
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
} 