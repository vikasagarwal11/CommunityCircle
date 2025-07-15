import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/personal_message_model.dart';
import '../core/constants.dart';

class SwipeToReplyPersonalMessage extends HookConsumerWidget {
  final PersonalMessageModel message;
  final Widget child;
  final VoidCallback? onReply;

  const SwipeToReplyPersonalMessage({
    super.key,
    required this.message,
    required this.child,
    this.onReply,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );
    final slideAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: animationController, curve: Curves.easeOut),
      ),
    );

    final isDragging = useState(false);
    final dragOffset = useState(0.0);
    final hasTriggeredReply = useState(false);

    // Reset animation when message changes
    useEffect(() {
      animationController.reset();
      dragOffset.value = 0.0;
      hasTriggeredReply.value = false;
      return null;
    }, [message.id]);

    void _handleDragStart(DragStartDetails details) {
      isDragging.value = true;
    }

    void _handleDragUpdate(DragUpdateDetails details) {
      if (hasTriggeredReply.value) return;
      
      // Only allow right swipe for reply (left-to-right)
      if (details.delta.dx > 0) {
        dragOffset.value += details.delta.dx;
        // Limit the drag distance
        dragOffset.value = dragOffset.value.clamp(0.0, 100.0);
      }
    }

    void _handleDragEnd(DragEndDetails details) {
      isDragging.value = false;
      
      // If dragged more than 60 pixels, trigger reply
      if (dragOffset.value > 60 && !hasTriggeredReply.value) {
        hasTriggeredReply.value = true;
        
        // Animate back to original position
        animationController.forward().then((_) {
          dragOffset.value = 0.0;
          animationController.reset();
        });
        
        // Call onReply callback if provided
        onReply?.call();
        
        // Show feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.reply,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Replying to message'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Animate back to original position
        animationController.forward().then((_) {
          dragOffset.value = 0.0;
          animationController.reset();
        });
      }
    }

    return GestureDetector(
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onPanEnd: _handleDragEnd,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(dragOffset.value * slideAnimation, 0),
            child: Stack(
              children: [
                // Reply indicator background
                if (dragOffset.value > 0)
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.reply,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Reply',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                // Main message content
                child!,
              ],
            ),
          );
        },
        child: child,
      ),
    );
  }
} 