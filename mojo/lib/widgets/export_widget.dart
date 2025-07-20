import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/export_service.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/community_model.dart';
import '../core/constants.dart';

class ExportWidget extends HookConsumerWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Future<String?> Function() onExport;
  final VoidCallback? onTap;

  const ExportWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onExport,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExporting = useState(false);
    final exportPath = useState<String?>(null);

    return Card(
      child: InkWell(
        onTap: onTap ?? () async {
          if (isExporting.value) return;
          
          isExporting.value = true;
          try {
            final path = await onExport();
            exportPath.value = path;
            
            if (path != null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Exported successfully to: $path'),
                    action: SnackBarAction(
                      label: 'Share',
                      onPressed: () => _shareFile(context, path),
                    ),
                  ),
                );
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export failed. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Export error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } finally {
            isExporting.value = false;
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isExporting.value)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareFile(BuildContext context, String filePath) {
    // TODO: Implement file sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }
}

// Predefined export widgets
class EventAttendanceExportWidget extends StatelessWidget {
  final EventModel event;
  final List<UserModel> attendees;

  const EventAttendanceExportWidget({
    super.key,
    required this.event,
    required this.attendees,
  });

  @override
  Widget build(BuildContext context) {
    return ExportWidget(
      title: 'Export Attendance',
      description: 'Download attendance data as CSV',
      icon: Icons.people,
      color: Colors.blue,
      onExport: () => ExportService().exportEventAttendance(event, attendees),
    );
  }
}

class CommunityAnalyticsExportWidget extends StatelessWidget {
  final CommunityModel community;
  final Map<String, dynamic> analytics;

  const CommunityAnalyticsExportWidget({
    super.key,
    required this.community,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return ExportWidget(
      title: 'Export Analytics',
      description: 'Download community analytics as CSV',
      icon: Icons.analytics,
      color: Colors.green,
      onExport: () => ExportService().exportCommunityAnalytics(community, analytics),
    );
  }
}

class MemberListExportWidget extends StatelessWidget {
  final CommunityModel community;
  final List<UserModel> members;

  const MemberListExportWidget({
    super.key,
    required this.community,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    return ExportWidget(
      title: 'Export Member List',
      description: 'Download member list as CSV',
      icon: Icons.group,
      color: Colors.orange,
      onExport: () => ExportService().exportMemberList(community, members),
    );
  }
}

class EventSummaryExportWidget extends StatelessWidget {
  final EventModel event;
  final Map<String, dynamic> summary;

  const EventSummaryExportWidget({
    super.key,
    required this.event,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return ExportWidget(
      title: 'Export Event Summary',
      description: 'Download event summary as CSV',
      icon: Icons.summarize,
      color: Colors.purple,
      onExport: () => ExportService().exportEventSummary(event, summary),
    );
  }
} 