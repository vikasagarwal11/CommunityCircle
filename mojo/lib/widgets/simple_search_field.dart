import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../core/constants.dart';

class SimpleSearchField extends HookConsumerWidget {
  final String hintText;
  final String? initialValue;
  final Function(String) onChanged;
  final Function(String)? onSubmitted;
  final bool showClearButton;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SimpleSearchField({
    super.key,
    required this.hintText,
    this.initialValue,
    required this.onChanged,
    this.onSubmitted,
    this.showClearButton = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: initialValue ?? '');
    final hasText = useState(initialValue?.isNotEmpty ?? false);

    // Update hasText when controller changes
    useEffect(() {
      void listener() {
        hasText.value = controller.text.isNotEmpty;
      }
      controller.addListener(listener);
      return () => controller.removeListener(listener);
    }, [controller]);

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon ?? const Icon(Icons.search),
        suffixIcon: showClearButton && hasText.value
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
          vertical: AppConstants.smallPadding,
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
    );
  }
} 