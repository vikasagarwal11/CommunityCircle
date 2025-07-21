import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/logger.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final Logger _logger = Logger('ExportService');

  // Export attendance data for an event
  Future<String?> exportEventAttendance(EventModel event, List<UserModel> attendees) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _logger.w('Storage permission not granted for export');
        return null;
      }

      // Create CSV data
      final csvData = _generateAttendanceCSV(event, attendees);
      
      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'attendance_${event.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      // Write CSV to file
      await file.writeAsString(csvData);
      
      _logger.i('Exported attendance data to: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Failed to export attendance data: $e');
      return null;
    }
  }

  // Export community analytics
  Future<String?> exportCommunityAnalytics(CommunityModel community, Map<String, dynamic> analytics) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _logger.w('Storage permission not granted for export');
        return null;
      }

      final csvData = _generateAnalyticsCSV(community, analytics);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'analytics_${community.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvData);
      
      _logger.i('Exported analytics data to: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Failed to export analytics data: $e');
      return null;
    }
  }

  // Export member list
  Future<String?> exportMemberList(CommunityModel community, List<UserModel> members) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _logger.w('Storage permission not granted for export');
        return null;
      }

      final csvData = _generateMemberListCSV(community, members);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'members_${community.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvData);
      
      _logger.i('Exported member list to: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Failed to export member list: $e');
      return null;
    }
  }

  // Export event summary
  Future<String?> exportEventSummary(EventModel event, Map<String, dynamic> summary) async {
    try {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        _logger.w('Storage permission not granted for export');
        return null;
      }

      final csvData = _generateEventSummaryCSV(event, summary);
      
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'event_summary_${event.id}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');
      
      await file.writeAsString(csvData);
      
      _logger.i('Exported event summary to: ${file.path}');
      return file.path;
    } catch (e) {
      _logger.e('Failed to export event summary: $e');
      return null;
    }
  }

  // Generate CSV for attendance data
  String _generateAttendanceCSV(EventModel event, List<UserModel> attendees) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Event Attendance Report');
    buffer.writeln('Event: ${event.title}');
    buffer.writeln('Date: ${_formatDate(event.date)}');
    buffer.writeln('Location: ${event.location}');
    buffer.writeln('Total Attendees: ${attendees.length}');
    buffer.writeln('');
    
    // CSV headers
    buffer.writeln('Name,Email,Phone,RSVP Status,Check-in Time,Check-out Time,Notes');
    
    // Attendee data
    for (final attendee in attendees) {
      final rsvpStatus = event.rsvps[attendee.id] ?? 'Unknown';
      final checkInTime = event.checkIns[attendee.id]?.toString() ?? '';
      final checkOutTime = ''; // Not implemented in current model
      
      buffer.writeln('"${attendee.displayName ?? 'Unknown'}","${attendee.email ?? ''}","${attendee.phoneNumber}","$rsvpStatus","$checkInTime","$checkOutTime",""');
    }
    
    return buffer.toString();
  }

  // Generate CSV for analytics data
  String _generateAnalyticsCSV(CommunityModel community, Map<String, dynamic> analytics) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Community Analytics Report');
    buffer.writeln('Community: ${community.name}');
    buffer.writeln('Generated: ${_formatDate(DateTime.now())}');
    buffer.writeln('');
    
    // Analytics data
    buffer.writeln('Metric,Value,Change');
    buffer.writeln('Total Members,${analytics['member_count'] ?? 0},${analytics['member_growth'] ?? 0}%');
    buffer.writeln('Active Members,${analytics['active_members'] ?? 0},${analytics['active_growth'] ?? 0}%');
    buffer.writeln('Events Created,${analytics['events_created'] ?? 0},${analytics['events_growth'] ?? 0}%');
    buffer.writeln('Messages Sent,${analytics['messages_sent'] ?? 0},${analytics['messages_growth'] ?? 0}%');
    buffer.writeln('Engagement Rate,${analytics['engagement_rate'] ?? 0}%,${analytics['engagement_change'] ?? 0}%');
    
    return buffer.toString();
  }

  // Generate CSV for member list
  String _generateMemberListCSV(CommunityModel community, List<UserModel> members) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Community Member List');
    buffer.writeln('Community: ${community.name}');
    buffer.writeln('Generated: ${_formatDate(DateTime.now())}');
    buffer.writeln('Total Members: ${members.length}');
    buffer.writeln('');
    
    // CSV headers
    buffer.writeln('Name,Email,Phone,Role,Join Date,Last Active,Status');
    
    // Member data
    for (final member in members) {
      final role = member.role;
      final joinDate = _formatDate(member.createdAt);
      final lastActive = _formatDate(member.lastSeen);
      final status = member.isOnline ? 'Online' : 'Offline';
      
      buffer.writeln('"${member.displayName ?? 'Unknown'}","${member.email ?? ''}","${member.phoneNumber}","$role","$joinDate","$lastActive","$status"');
    }
    
    return buffer.toString();
  }

  // Generate CSV for event summary
  String _generateEventSummaryCSV(EventModel event, Map<String, dynamic> summary) {
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Event Summary Report');
    buffer.writeln('Event: ${event.title}');
    buffer.writeln('Date: ${_formatDate(event.date)}');
    buffer.writeln('Location: ${event.location}');
    buffer.writeln('');
    
    // Summary data
    buffer.writeln('Metric,Value');
    buffer.writeln('Total RSVPs,${summary['total_rsvps'] ?? 0}');
    buffer.writeln('Confirmed,${summary['confirmed'] ?? 0}');
    buffer.writeln('Maybe,${summary['maybe'] ?? 0}');
    buffer.writeln('Declined,${summary['declined'] ?? 0}');
    buffer.writeln('Checked In,${summary['checked_in'] ?? 0}');
    buffer.writeln('No Shows,${summary['no_shows'] ?? 0}');
    buffer.writeln('Attendance Rate,${summary['attendance_rate'] ?? 0}%');
    
    return buffer.toString();
  }

  // Format date for CSV
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Get export directory
  Future<String?> getExportDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      return exportDir.path;
    } catch (e) {
      _logger.e('Failed to get export directory: $e');
      return null;
    }
  }

  // List exported files
  Future<List<FileSystemEntity>> listExportedFiles() async {
    try {
      final exportDir = await getExportDirectory();
      if (exportDir == null) return [];
      
      final directory = Directory(exportDir);
      final files = await directory.list().toList();
      
      // Sort by modification time (newest first)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      _logger.e('Failed to list exported files: $e');
      return [];
    }
  }

  // Delete exported file
  Future<bool> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        _logger.i('Deleted exported file: $filePath');
        return true;
      }
      return false;
    } catch (e) {
      _logger.e('Failed to delete exported file: $e');
      return false;
    }
  }

  // Share exported file (platform-specific)
  Future<bool> shareExportedFile(String filePath) async {
    try {
      // This would integrate with platform-specific sharing
      // For now, just log the action
      _logger.i('Sharing exported file: $filePath');
      return true;
    } catch (e) {
      _logger.e('Failed to share exported file: $e');
      return false;
    }
  }
} 