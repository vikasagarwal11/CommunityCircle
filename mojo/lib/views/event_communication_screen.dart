import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants.dart';
import '../core/logger.dart';
import '../core/navigation_service.dart';
import '../models/event_model.dart';
import '../models/message_model.dart';
import '../providers/auth_providers.dart';
import '../providers/database_providers.dart';
import '../services/event_service.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class EventCommunicationScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String? communityId;

  const EventCommunicationScreen({
    super.key,
    required this.eventId,
    this.communityId,
  });

  @override
  ConsumerState<EventCommunicationScreen> createState() => _EventCommunicationScreenState();
}

class _EventCommunicationScreenState extends ConsumerState<EventCommunicationScreen>
    with TickerProviderStateMixin {
  final Logger _logger = Logger('EventCommunicationScreen');
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  
  late TabController _tabController;
  int _currentTabIndex = 0;
  
  bool _isLoading = false;
  String? _error;
  EventModel? _event;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _loadEvent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _loadEvent() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final eventAsync = ref.read(eventProvider(widget.eventId));
      await eventAsync.when(
        data: (event) {
          setState(() {
            _event = event;
          });
        },
        loading: () => null,
        error: (error, _) {
          setState(() {
            _error = error.toString();
          });
        },
      );
    } catch (e) {
      _logger.e('❌ Error loading event: $e');
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _event?.title ?? 'Event Communication',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => NavigationService.goBack(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: 'Chat'),
            Tab(icon: Icon(Icons.question_answer), text: 'Q&A'),
            Tab(icon: Icon(Icons.qr_code), text: 'Check-in'),
            Tab(icon: Icon(Icons.share), text: 'Share'),
          ],
        ),
      ),
      body: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadEvent,
                )
              : _event == null
                  ? const Center(child: Text('Event not found'))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChatTab(),
                        _buildQATab(),
                        _buildCheckInTab(),
                        _buildShareTab(),
                      ],
                    ),
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: _buildEventChat(),
        ),
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildEventChat() {
    // For now, show a placeholder. In a real implementation, this would use
    // event-specific message providers
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Event Chat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chat with other attendees about this event',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showChatComingSoon,
            icon: const Icon(Icons.chat),
            label: const Text('Start Chat'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQATab() {
    return Column(
      children: [
        Expanded(
          child: _buildQASection(),
        ),
        _buildQuestionInput(),
      ],
    );
  }

  Widget _buildQASection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Questions & Answers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.question_answer_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to ask a question about this event',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _askQuestion,
            icon: const Icon(Icons.question_mark),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInTab() {
    final currentUser = ref.read(currentUserProvider).value;
    final isCheckedIn = _event?.isCheckedIn(currentUser?.id ?? '') ?? false;
    final hasRsvped = _event?.isRsvped(currentUser?.id ?? '') ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // QR Code Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Event QR Code',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: 'event:${widget.eventId}',
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Scan this QR code to check in',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Check-in Status
          if (isCheckedIn)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checked In!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'You\'ve successfully checked in to this event',
                          style: TextStyle(
                            color: Colors.green.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (hasRsvped)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to Check In',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'You can check in when you arrive at the event',
                          style: TextStyle(
                            color: Colors.orange.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RSVP Required',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'You need to RSVP to this event before checking in',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShareTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Event',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Column(
              children: [
                _buildShareOption(
                  icon: Icons.copy,
                  title: 'Copy Event Link',
                  subtitle: 'Share the event URL with others',
                  onTap: _copyEventLink,
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.share,
                  title: 'Share via App',
                  subtitle: 'Share through your device\'s share sheet',
                  onTap: _shareViaApp,
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.qr_code,
                  title: 'Generate QR Code',
                  subtitle: 'Create a QR code for easy sharing',
                  onTap: _generateQRCode,
                ),
                const SizedBox(height: 12),
                _buildShareOption(
                  icon: Icons.calendar_today,
                  title: 'Add to Calendar',
                  subtitle: 'Add this event to your calendar',
                  onTap: _addToCalendar,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Details',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildEventDetailRow(Icons.event, 'Title', _event?.title ?? ''),
                      _buildEventDetailRow(Icons.location_on, 'Location', _event?.location ?? ''),
                      _buildEventDetailRow(Icons.access_time, 'Date', _formatEventDate(_event?.date)),
                      _buildEventDetailRow(Icons.people, 'Attendees', '${_event?.goingCount ?? 0} going'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatEventDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    // TODO: Implement message sending
    _logger.i('📝 Sending message: ${_messageController.text}');
    _messageController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message sent!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _askQuestion() {
    if (_questionController.text.trim().isEmpty) return;
    
    // TODO: Implement question asking
    _logger.i('❓ Asking question: ${_questionController.text}');
    _questionController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Question posted!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showChatComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event chat coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _copyEventLink() {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event link copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareViaApp() {
    // TODO: Implement native sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening share sheet...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _generateQRCode() {
    // TODO: Implement QR code generation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR code generated!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _addToCalendar() {
    // TODO: Implement calendar integration
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to calendar!'),
        backgroundColor: Colors.green,
      ),
    );
  }
} 