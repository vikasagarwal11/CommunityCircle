import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/community_model.dart';
import '../core/constants.dart';

class AdminManagementModerationTab extends HookConsumerWidget {
  final CommunityModel community;
  final ValueNotifier<bool> isLoading;

  const AdminManagementModerationTab({
    super.key,
    required this.community,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFilter = useState('all');
    final showResolved = useState(false);

    return Column(
      children: [
        // Filter bar
        _buildFilterBar(context, selectedFilter, showResolved),
        
        // Moderation tools
        _buildModerationTools(context),
        
        // Reports list
        Expanded(
          child: _buildReportsList(context, selectedFilter, showResolved),
        ),
      ],
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    ValueNotifier<String> selectedFilter,
    ValueNotifier<bool> showResolved,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(context, 'All', 'all', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Spam', 'spam', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Inappropriate', 'inappropriate', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Harassment', 'harassment', selectedFilter),
                const SizedBox(width: 8),
                _buildFilterChip(context, 'Other', 'other', selectedFilter),
              ],
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          
          // Toggle resolved reports
          Row(
            children: [
              Checkbox(
                value: showResolved.value,
                onChanged: (value) => showResolved.value = value ?? false,
              ),
              const Text('Show resolved reports'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    String value,
    ValueNotifier<String> selectedFilter,
  ) {
    final isSelected = selectedFilter.value == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        selectedFilter.value = value;
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildModerationTools(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moderation Tools',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  context,
                  'Auto-Moderation',
                  'Automatically filter content',
                  Icons.auto_fix_high,
                  Colors.blue,
                  () => _toggleAutoModeration(context),
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildToolCard(
                  context,
                  'Word Filter',
                  'Block specific words',
                  Icons.block,
                  Colors.red,
                  () => _manageWordFilter(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: _buildToolCard(
                  context,
                  'User Bans',
                  'Manage banned users',
                  Icons.person_off,
                  Colors.orange,
                  () => _manageBans(context),
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: _buildToolCard(
                  context,
                  'Report Settings',
                  'Configure reporting',
                  Icons.settings,
                  Colors.purple,
                  () => _configureReports(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsList(
    BuildContext context,
    ValueNotifier<String> selectedFilter,
    ValueNotifier<bool> showResolved,
  ) {
    // Mock reports data
    final reports = [
      {
        'id': '1',
        'type': 'spam',
        'status': 'pending',
        'reporter': 'John Doe',
        'reportedUser': 'Jane Smith',
        'content': 'This is spam content',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
        'severity': 'medium',
      },
      {
        'id': '2',
        'type': 'inappropriate',
        'status': 'resolved',
        'reporter': 'Mike Johnson',
        'reportedUser': 'Sarah Wilson',
        'content': 'Inappropriate message',
        'timestamp': DateTime.now().subtract(const Duration(days: 1)),
        'severity': 'high',
      },
      {
        'id': '3',
        'type': 'harassment',
        'status': 'pending',
        'reporter': 'Alex Brown',
        'reportedUser': 'Tom Davis',
        'content': 'Harassment report',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)),
        'severity': 'high',
      },
    ];

    final filteredReports = reports.where((report) {
      // Filter by type
      if (selectedFilter.value != 'all' && report['type'] != selectedFilter.value) {
        return false;
      }
      
      // Filter by status
      if (!showResolved.value && report['status'] == 'resolved') {
        return false;
      }
      
      return true;
    }).toList();

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.report_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'No reports found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'All clear! No moderation needed.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: filteredReports.length,
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        return _buildReportCard(context, report);
      },
    );
  }

  Widget _buildReportCard(BuildContext context, Map<String, dynamic> report) {
    final severity = report['severity'] as String;
    final status = report['status'] as String;
    
    Color severityColor;
    switch (severity) {
      case 'high':
        severityColor = Colors.red;
        break;
      case 'medium':
        severityColor = Colors.orange;
        break;
      case 'low':
        severityColor = Colors.yellow;
        break;
      default:
        severityColor = Colors.grey;
    }

    Color statusColor;
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'dismissed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    severity.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: severityColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatTimestamp(report['timestamp'] as DateTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'Reported by ${report['reporter']}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Against ${report['reportedUser']}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Container(
              padding: const EdgeInsets.all(AppConstants.smallPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                report['content'] as String,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewDetails(context, report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _takeAction(context, report),
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('Take Action'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
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

  void _toggleAutoModeration(BuildContext context) {
    // TODO: Implement auto-moderation toggle
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-moderation settings coming soon!')),
    );
  }

  void _manageWordFilter(BuildContext context) {
    // TODO: Implement word filter management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Word filter management coming soon!')),
    );
  }

  void _manageBans(BuildContext context) {
    // TODO: Implement ban management
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ban management coming soon!')),
    );
  }

  void _configureReports(BuildContext context) {
    // TODO: Implement report configuration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report configuration coming soon!')),
    );
  }

  void _viewDetails(BuildContext context, Map<String, dynamic> report) {
    // TODO: Implement view report details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View details for report ${report['id']}')),
    );
  }

  void _takeAction(BuildContext context, Map<String, dynamic> report) {
    // TODO: Implement take action on report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Take action on report ${report['id']}')),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
} 