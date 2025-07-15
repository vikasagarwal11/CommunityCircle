import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';
import '../services/mention_service.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../providers/chat_providers.dart';
import '../widgets/mention_suggestions_widget.dart';
import '../core/constants.dart';

class ChatInputWidget extends HookConsumerWidget {
  final String communityId;
  final MessageModel? replyToMessage;
  final Function(String text, List<String> mentions) onSendMessage;
  final VoidCallback onCancelReply;
  final VoidCallback onAttachmentPressed;

  const ChatInputWidget({
    super.key,
    required this.communityId,
    this.replyToMessage,
    required this.onSendMessage,
    required this.onCancelReply,
    required this.onAttachmentPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageController = useTextEditingController();
    final focusNode = useFocusNode();
    final showEmojiPicker = useState(false);
    final showMentionSuggestions = useState(false);
    final cursorPosition = useState(0);
    
    final mentionService = ref.watch(mentionServiceProvider);
    final communityMembersAsync = ref.watch(communityMembersProvider(communityId));

    // Listen to text changes for mention detection
    useEffect(() {
      void onTextChanged() {
        final text = messageController.text;
        final position = messageController.selection.baseOffset;
        cursorPosition.value = position;
        
        // Check if we should show mention suggestions
        if (mentionService.shouldShowMentionSuggestions(text, position)) {
          showMentionSuggestions.value = true;
        } else {
          showMentionSuggestions.value = false;
        }
      }
      
      messageController.addListener(onTextChanged);
      return () => messageController.removeListener(onTextChanged);
    }, [messageController]);

    // Handle mention selection
    void onUserSelected(UserModel user) {
      final text = messageController.text;
      final position = messageController.selection.baseOffset;
      
      // Replace the mention query with the selected user
      final newText = mentionService.replaceMentionQuery(text, position, user);
      final newPosition = mentionService.getCursorPositionAfterMention(text, position, user);
      
      messageController.text = newText;
      messageController.selection = TextSelection.collapsed(offset: newPosition);
      
      // Hide suggestions
      showMentionSuggestions.value = false;
      
      // Focus back on the input
      focusNode.requestFocus();
    }

    // Handle send message
    void sendMessage() {
      final text = messageController.text.trim();
      if (text.isEmpty) return;

      // Extract mentions from text
      final mentions = communityMembersAsync.when(
        data: (members) => mentionService.extractMentionedUserIds(text, members),
        loading: () => <String>[],
        error: (_, __) => <String>[],
      );

      onSendMessage(text, mentions);
      messageController.clear();
      showMentionSuggestions.value = false;
    }

    return Column(
      children: [
        // Reply preview
        if (replyToMessage != null) _buildReplyPreview(context, replyToMessage!, onCancelReply),
        
        // Mention suggestions
        if (showMentionSuggestions.value) 
          communityMembersAsync.when(
            data: (members) => MentionSuggestionsWidget(
              text: messageController.text,
              cursorPosition: cursorPosition.value,
              communityMembers: members,
              onUserSelected: onUserSelected,
              onDismiss: () => showMentionSuggestions.value = false,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        
        // Chat input
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: onAttachmentPressed,
              ),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: messageController,
                  focusNode: focusNode,
                  onChanged: (value) {
                    // Typing indicator logic can be added here
                  },
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                      vertical: AppConstants.smallPadding,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
              
              // Emoji button
              IconButton(
                icon: Icon(showEmojiPicker.value ? Icons.keyboard : Icons.emoji_emotions),
                onPressed: () {
                  showEmojiPicker.value = !showEmojiPicker.value;
                  // TODO: Implement emoji picker
                },
              ),
              
              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: messageController.text.trim().isEmpty ? null : sendMessage,
                style: IconButton.styleFrom(
                  backgroundColor: messageController.text.trim().isEmpty 
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
                      : Theme.of(context).colorScheme.primary,
                  foregroundColor: messageController.text.trim().isEmpty 
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReplyPreview(BuildContext context, MessageModel replyTo, VoidCallback onCancel) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
        vertical: AppConstants.smallPadding,
      ),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(
            color: colorScheme.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to message',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  replyTo.text,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
} 