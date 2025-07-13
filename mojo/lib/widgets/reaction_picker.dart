import 'package:flutter/material.dart';
import '../core/constants.dart';

class ReactionPicker extends StatefulWidget {
  final Function(String emoji) onReactionSelected;
  final VoidCallback onClose;
  final String? selectedReaction;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    required this.onClose,
    this.selectedReaction,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<String> _reactions = [
    '👍', '❤️', '😄', '😢', '🎉', '🔥', '👏', '🙏',
    '😍', '🤔', '😱', '😴', '🤮', '💯', '💪', '👀'
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Text(
                        'Add Reaction',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _animationController.reverse().then((_) {
                            widget.onClose();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  
                  // Reaction grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _reactions.length,
                    itemBuilder: (context, index) {
                      final emoji = _reactions[index];
                      final isSelected = widget.selectedReaction == emoji;
                      
                      return _buildReactionButton(emoji, isSelected, index);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReactionButton(String emoji, bool isSelected, int index) {
    return GestureDetector(
      onTap: () {
        widget.onReactionSelected(emoji);
        _animationController.reverse().then((_) {
          widget.onClose();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected 
            ? Border.all(
                color: Theme.of(context).colorScheme.onSurface,
                width: 2,
              )
            : null,
        ),
        child: Center(
          child: Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
} 