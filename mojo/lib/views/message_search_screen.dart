import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/personal_message_model.dart';
import '../models/user_model.dart';
import '../providers/chat_providers.dart';
import '../providers/user_providers.dart';
import '../core/theme.dart';
import '../core/logger.dart';
import '../core/constants.dart';
import '../core/navigation_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/mention_suggestions_widget.dart';
import '../widgets/swipe_to_reply_message.dart';
import '../widgets/read_receipt_widget.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/chat_input_widget.dart';
import '../widgets/animated_reaction_button.dart';
import '../services/chat_service.dart';
import '../services/mention_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import 'chat_screen.dart';
import 'personal_chat_screen.dart';
import 'community_details_screen.dart';
import 'event_details_screen.dart';

class MessageSearchScreen extends HookConsumerWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  
  const MessageSearchScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchQuery = useState('');
    final searchResults = useState<List<PersonalMessageModel>>([]);
    final isSearching = useState(false);
    final searchController = useTextEditingController();

    // Debounce search
    useEffect(() {
      final timer = Timer(const Duration(milliseconds: 500), () {
        if (searchQuery.value.isNotEmpty) {
          _performSearch(searchQuery.value, searchResults, isSearching);
        } else {
          searchResults.value = [];
        }
      });
      return timer.cancel;
    }, [searchQuery.value]);

    return Scaffold(
      appBar: AppBar(
        title: Text('Search in ${otherUserName}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Search input
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: TextField(
              controller: searchController,
              onChanged: (value) => searchQuery.value = value,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          searchQuery.value = '';
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          
          // Search results
          Expanded(
            child: searchQuery.value.isEmpty
                ? _buildEmptyState(context)
                : isSearching.value
                    ? const LoadingWidget()
                    : searchResults.value.isEmpty
                        ? _buildNoResultsState(context, searchQuery.value)
                        : _buildSearchResults(context, searchResults.value),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.search,
              size: 60,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'Search Messages',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Type to search through your conversation with $otherUserName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context, String query) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppConstants.largePadding),
          Text(
            'No results for "$query"',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Try searching with different keywords',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, List<PersonalMessageModel> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final message = results[index];
        return _buildSearchResultTile(context, message);
      },
    );
  }

  Widget _buildSearchResultTile(BuildContext context, PersonalMessageModel message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOwnMessage = message.senderId != otherUserId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: AppConstants.smallPadding),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            isOwnMessage ? 'You' : otherUserName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          isOwnMessage ? 'You' : otherUserName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.5),
        ),
        onTap: () {
          // TODO: Navigate to the specific message in the chat
          NavigationService.showSnackBar(message: 'Jump to message coming soon!');
        },
      ),
    );
  }

  Future<void> _performSearch(
    String query,
    ValueNotifier<List<PersonalMessageModel>> results,
    ValueNotifier<bool> isSearching,
  ) async {
    if (query.trim().isEmpty) {
      results.value = [];
      return;
    }

    isSearching.value = true;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('personal_chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .get();

      final allMessages = snapshot.docs
          .map((doc) => PersonalMessageModel.fromMap(doc.data(), doc.id))
          .toList();

      // Filter messages that contain the search query
      final filteredMessages = allMessages.where((message) {
        final text = message.text.toLowerCase();
        final searchTerm = query.toLowerCase();
        return text.contains(searchTerm);
      }).toList();

      results.value = filteredMessages;
    } catch (e) {
      NavigationService.showSnackBar(message: 'Error searching messages: $e');
      results.value = [];
    } finally {
      isSearching.value = false;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return '${time.day}/${time.month}/${time.year}';
    } else if (difference.inHours > 0) {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }
} 