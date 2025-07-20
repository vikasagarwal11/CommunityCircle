import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class CreateCommunityDialogs {
  static void showAddQuestionDialog(BuildContext context, ValueNotifier<List<String>> joinQuestions) {
    final questionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Join Question'),
        content: TextField(
          controller: questionController,
          decoration: const InputDecoration(
            hintText: 'Enter your question...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final question = questionController.text.trim();
              if (question.isNotEmpty) {
                final newQuestions = List<String>.from(joinQuestions.value);
                newQuestions.add(question);
                joinQuestions.value = newQuestions;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  static void showAddRuleDialog(BuildContext context, ValueNotifier<List<String>> rules) {
    final ruleController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Community Rule'),
        content: TextField(
          controller: ruleController,
          decoration: const InputDecoration(
            hintText: 'Enter your rule/guideline...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final rule = ruleController.text.trim();
              if (rule.isNotEmpty) {
                final newRules = List<String>.from(rules.value);
                newRules.add(rule);
                rules.value = newRules;
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
} 