import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/chat.dart';
import 'package:nepal_care/repositories/chat_repository.dart';
import 'package:nepal_care/screens/chat/chat_screen.dart';

class MessagesListScreen extends StatefulWidget {
  const MessagesListScreen({
    super.key,
    required this.currentUserId,
    this.repository,
  });

  final String currentUserId;
  final ChatRepository? repository;

  @override
  State<MessagesListScreen> createState() => _MessagesListScreenState();
}

class _MessagesListScreenState extends State<MessagesListScreen> {
  late final ChatRepository _repository = widget.repository ?? ChatRepository();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _matches(Conversation c) =>
      c.otherUserName.toLowerCase().contains(_query.toLowerCase()) ||
      c.otherUserRole.toLowerCase().contains(_query.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Text('Messages', style: AppTextTheme.textTheme.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search conversations...',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder<List<Conversation>>(
                stream: _repository.streamConversations(widget.currentUserId),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _EmptyState(
                      icon: Icons.cloud_off_outlined,
                      text: 'Unable to load messages right now.',
                    );
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final conversations = (snapshot.data ?? const <Conversation>[])
                      .where(_matches)
                      .toList();

                  if (conversations.isEmpty) {
                    return _EmptyState(
                      icon: Icons.chat_bubble_outline_rounded,
                      text: _query.isNotEmpty
                          ? 'No conversations match your search.'
                          : 'No conversations yet.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: conversations.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return _ConversationTile(
                        conversation: conversation,
                        onTap: () async {
                          await _repository.markConversationRead(
                            conversationId: conversation.id,
                            currentUserId: widget.currentUserId,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                conversationId: conversation.id,
                                currentUserId: widget.currentUserId,
                                otherUserId: conversation.otherUserId,
                                otherUserName: conversation.otherUserName,
                                otherUserRole: conversation.otherUserRole,
                                repository: _repository,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conversation, required this.onTap});

  final Conversation conversation;
  final VoidCallback onTap;

  String get _initials => conversation.otherUserName
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  Color get _avatarColor {
    // Deterministic pastel color from the name, so the same person
    // always gets the same avatar color across the app.
    const palette = [
      Color(0xFFF7C6C7),
      Color(0xFFC7E3F7),
      Color(0xFFC9EDCB),
      Color(0xFF2B2B2B),
      Color(0xFFF7D9C4),
    ];
    return palette[conversation.otherUserName.hashCode.abs() % palette.length];
  }

  String get _timeLabel {
    final now = DateTime.now();
    final diff = now.difference(conversation.lastMessageAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) {
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[conversation.lastMessageAt.weekday - 1];
    }
    return '${conversation.lastMessageAt.day}/${conversation.lastMessageAt.month}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _avatarColor.computeLuminance() < 0.4;
    final hasUnread = conversation.unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEEE)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: _avatarColor, borderRadius: BorderRadius.circular(13)),
              child: Text(
                _initials.isEmpty ? '?' : _initials,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversation.otherUserName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(_timeLabel, style: AppTextTheme.textTheme.bodySmall),
                    ],
                  ),
                  Text(
                    conversation.otherUserRole,
                    style: AppTextTheme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (!hasUnread)
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 5),
                          decoration: const BoxDecoration(color: Color(0xFF43A85F), shape: BoxShape.circle),
                        ),
                      Expanded(
                        child: Text(
                          conversation.lastMessage.isEmpty
                              ? 'Say hello 👋'
                              : conversation.lastMessage,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextTheme.textTheme.bodySmall?.copyWith(
                            color: hasUnread ? AppColors.textDark : AppColors.textMuted,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${conversation.unreadCount}',
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center, style: AppTextTheme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}