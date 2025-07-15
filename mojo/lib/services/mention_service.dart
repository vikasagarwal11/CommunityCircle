import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logger/logger.dart';

class MentionService {
  final Logger _logger = Logger();

  // Extract mentions from text using @ symbol
  List<String> extractMentions(String text) {
    final mentions = <String>[];
    final regex = RegExp(r'@(\w+)');
    final matches = regex.allMatches(text);
    
    for (final match in matches) {
      final username = match.group(1);
      if (username != null) {
        mentions.add(username);
      }
    }
    
    return mentions;
  }

  // Extract user IDs from mentions in text
  List<String> extractMentionedUserIds(String text, List<UserModel> communityMembers) {
    final mentions = extractMentions(text);
    final mentionedUserIds = <String>[];
    
    for (final mention in mentions) {
      // Find user by display name or email
      final user = communityMembers.firstWhere(
        (user) => 
          user.displayName?.toLowerCase() == mention.toLowerCase() ||
          user.displayName?.toLowerCase().contains(mention.toLowerCase()) == true ||
          user.email?.toLowerCase().contains(mention.toLowerCase()) == true,
        orElse: () => UserModel(
          id: '',
          phoneNumber: '',
          displayName: '',
          email: '',
          profilePictureUrl: '',
          role: 'user',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: false,
        ),
      );
      
      if (user.id.isNotEmpty) {
        mentionedUserIds.add(user.id);
      }
    }
    
    return mentionedUserIds;
  }

  // Check if text contains @ symbol for mention suggestions
  bool shouldShowMentionSuggestions(String text, int cursorPosition) {
    if (cursorPosition == 0) return false;
    
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtSymbol = beforeCursor.lastIndexOf('@');
    
    if (lastAtSymbol == -1) return false;
    
    // Check if there's a space before @ or if it's at the beginning
    final beforeAt = beforeCursor.substring(0, lastAtSymbol);
    if (beforeAt.isNotEmpty && !beforeAt.endsWith(' ')) return false;
    
    // Check if we're still typing the username (no space after @)
    final afterAt = beforeCursor.substring(lastAtSymbol + 1);
    if (afterAt.contains(' ')) return false;
    
    return true;
  }

  // Get the current mention query (text after @)
  String getMentionQuery(String text, int cursorPosition) {
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtSymbol = beforeCursor.lastIndexOf('@');
    
    if (lastAtSymbol == -1) return '';
    
    return beforeCursor.substring(lastAtSymbol + 1);
  }

  // Filter community members based on mention query
  List<UserModel> filterMembersForMention(
    List<UserModel> members,
    String query,
    String currentUserId,
  ) {
    if (query.isEmpty) {
      // Return all members except current user
      return members.where((member) => member.id != currentUserId).toList();
    }
    
    final lowercaseQuery = query.toLowerCase();
    
    return members
        .where((member) => 
          member.id != currentUserId &&
          (member.displayName?.toLowerCase().contains(lowercaseQuery) == true ||
           member.email?.toLowerCase().contains(lowercaseQuery) == true))
        .toList();
  }

  // Replace mention query with selected user
  String replaceMentionQuery(String text, int cursorPosition, UserModel selectedUser) {
    final beforeCursor = text.substring(0, cursorPosition);
    final afterCursor = text.substring(cursorPosition);
    
    final lastAtSymbol = beforeCursor.lastIndexOf('@');
    if (lastAtSymbol == -1) return text;
    
    final beforeAt = beforeCursor.substring(0, lastAtSymbol);
    final replacement = '@${selectedUser.displayName ?? selectedUser.email ?? 'User'} ';
    
    return beforeAt + replacement + afterCursor;
  }

  // Get cursor position after mention replacement
  int getCursorPositionAfterMention(String text, int cursorPosition, UserModel selectedUser) {
    final beforeCursor = text.substring(0, cursorPosition);
    final lastAtSymbol = beforeCursor.lastIndexOf('@');
    if (lastAtSymbol == -1) return cursorPosition;
    
    final beforeAt = beforeCursor.substring(0, lastAtSymbol);
    final replacement = '@${selectedUser.displayName ?? selectedUser.email ?? 'User'} ';
    
    return beforeAt.length + replacement.length;
  }

  // Format text with mention highlights
  List<TextSpan> formatTextWithMentions(
    String text,
    List<UserModel> communityMembers,
    TextStyle? defaultStyle,
    TextStyle? mentionStyle,
  ) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'@(\w+)');
    int lastIndex = 0;
    
    for (final match in regex.allMatches(text)) {
      // Add text before the mention
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: defaultStyle,
        ));
      }
      
      // Find the mentioned user
      final username = match.group(1)!;
      final user = communityMembers.firstWhere(
        (user) => 
          user.displayName?.toLowerCase() == username.toLowerCase() ||
          user.displayName?.toLowerCase().contains(username.toLowerCase()) == true ||
          user.email?.toLowerCase().contains(username.toLowerCase()) == true,
        orElse: () => UserModel(
          id: '',
          phoneNumber: '',
          displayName: '',
          email: '',
          profilePictureUrl: '',
          role: 'user',
          createdAt: DateTime.now(),
          lastSeen: DateTime.now(),
          isOnline: false,
        ),
      );
      
      // Add the mention span
      spans.add(TextSpan(
        text: match.group(0),
        style: mentionStyle?.copyWith(
          color: user.id.isNotEmpty ? mentionStyle.color : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      lastIndex = match.end;
    }
    
    // Add remaining text
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: defaultStyle,
      ));
    }
    
    return spans;
  }
}

// Provider for mention service
final mentionServiceProvider = Provider<MentionService>((ref) {
  return MentionService();
}); 