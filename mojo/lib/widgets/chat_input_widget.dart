import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import '../core/constants.dart';
import '../core/theme.dart';

class ChatInputWidget extends HookWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final bool isOffline;

  const ChatInputWidget({
    super.key,
    required this.controller,
    required this.onSendMessage,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final isTyping = useState(false);

    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Offline indicator
          if (isOffline) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.smallPadding,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Offline - Message will send when connected',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
          ],
          // Input row
          Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: isOffline ? null : () {
                  // TODO: Implement attachment functionality
                },
                tooltip: isOffline ? 'Unavailable offline' : 'Attach file',
              ),
              
              // Text input
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (value) {
                    isTyping.value = value.isNotEmpty;
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      onSendMessage(value);
                      controller.clear();
                      isTyping.value = false;
                    }
                  },
                  decoration: InputDecoration(
                    hintText: isOffline ? 'Type message (offline)...' : 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isOffline 
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.defaultPadding,
                      vertical: AppConstants.smallPadding,
                    ),
                    suffixIcon: isTyping.value
                        ? IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: controller.text.trim().isEmpty ? null : () {
                              onSendMessage(controller.text);
                              controller.clear();
                              isTyping.value = false;
                            },
                            style: IconButton.styleFrom(
                              backgroundColor: controller.text.trim().isEmpty 
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.1)
                                  : Theme.of(context).colorScheme.primary,
                              foregroundColor: controller.text.trim().isEmpty 
                                  ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                  : Colors.white,
                            ),
                          )
                        : null,
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: true, // Always allow typing, even offline
                ),
              ),
              
              // Emoji button
              IconButton(
                icon: const Icon(Icons.emoji_emotions),
                onPressed: isOffline ? null : () {
                  // TODO: Implement emoji picker
                },
                tooltip: isOffline ? 'Unavailable offline' : 'Add emoji',
              ),
            ],
          ),
        ],
      ),
    );
  }
} 