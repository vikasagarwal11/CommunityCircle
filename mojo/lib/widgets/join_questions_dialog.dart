import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class JoinQuestionsDialog extends HookWidget {
  final List<String> questions;
  final Function(List<String>) onSubmit;
  final VoidCallback onCancel;

  const JoinQuestionsDialog({
    super.key,
    required this.questions,
    required this.onSubmit,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final answerControllers = useState<List<TextEditingController>>([]);
    final isLoading = useState(false);
    final errors = useState<List<String?>>([]);

    // Initialize controllers
    useEffect(() {
      final controllers = List.generate(
        questions.length,
        (index) => TextEditingController(),
      );
      answerControllers.value = controllers;
      errors.value = List.filled(questions.length, null);
      
      return () {
        for (final controller in controllers) {
          controller.dispose();
        }
      };
    }, [questions.length]);

    void validateAndSubmit() {
      final newErrors = <String?>[];
      final answers = <String>[];
      bool hasErrors = false;

      for (int i = 0; i < questions.length; i++) {
        final answer = answerControllers.value[i].text.trim();
        answers.add(answer);
        
        if (answer.isEmpty) {
          newErrors.add('Please answer this question');
          hasErrors = true;
        } else if (answer.length < 3) {
          newErrors.add('Answer must be at least 3 characters');
          hasErrors = true;
        } else {
          newErrors.add(null);
        }
      }

      errors.value = newErrors;

      if (!hasErrors) {
        isLoading.value = true;
        onSubmit(answers);
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.question_answer,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Join Questions',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Please answer the following questions to join this community',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Questions List
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(questions.length, (index) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  questions[index],
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: answerControllers.value[index],
                            maxLines: 3,
                            decoration: InputDecoration(
                              hintText: 'Type your answer here...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: errors.value[index] != null
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.outline,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: errors.value[index] != null
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorText: errors.value[index],
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            onChanged: (value) {
                              // Clear error when user starts typing
                              if (errors.value[index] != null) {
                                final newErrors = List<String?>.from(errors.value);
                                newErrors[index] = null;
                                errors.value = newErrors;
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading.value ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                                      child: ElevatedButton(
                      onPressed: isLoading.value ? null : validateAndSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Submit & Join',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 