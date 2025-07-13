import 'package:flutter/material.dart';
import '../core/constants.dart';

class AnimatedReactionButton extends StatefulWidget {
  final String emoji;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showCount;

  const AnimatedReactionButton({
    super.key,
    required this.emoji,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.showCount = true,
  });

  @override
  State<AnimatedReactionButton> createState() => _AnimatedReactionButtonState();
}

class _AnimatedReactionButtonState extends State<AnimatedReactionButton>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _scaleController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _bounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _scaleController.forward(),
      onTapUp: (_) => _scaleController.reverse(),
      onTapCancel: () => _scaleController.reverse(),
      onTap: () {
        _bounceController.forward().then((_) {
          _bounceController.reverse();
        });
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_bounceController, _scaleController]),
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value * _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: widget.isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (widget.showCount && widget.count > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '${widget.count}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: widget.isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 