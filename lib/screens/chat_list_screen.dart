import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';
import 'enhanced_chat_conversation_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final List<ChatConversation> _conversations = [];

  @override
  void initState() {
    super.initState();
    _initializeChats();
  }

  void _initializeChats() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return;

    try {
      // Load conversations from database
      final conversations = await ChatService.getUserConversations(currentUser.id);
      
      // Add Sampul AI if not exists
      final hasAIChat = conversations.any((conv) => conv.conversationType == ConversationType.ai);
      if (!hasAIChat) {
        // Create AI conversation with database-generated UUID
        final response = await Supabase.instance.client
            .from('chat_conversations')
            .insert({
              'name': 'Sampul AI',
              'last_message': 'Hello! I\'m your estate planning assistant. How can I help you today?',
              'last_message_time': DateTime.now().toIso8601String(),
              'avatar_url': '',
              'unread_count': 0,
              'is_online': true,
              'conversation_type': 'ai',
              'created_by': currentUser.id,
            })
            .select()
            .single();

        final aiConversation = ChatConversation.fromJson(response);
        
        // Add welcome message to the conversation
        final welcomeMessage = ChatMessage(
          id: '', // Let database generate UUID
          content: "Hello! I'm Sampul AI, your estate planning assistant. How can I help you today?",
          isFromUser: false,
          timestamp: DateTime.now(),
        );
        
        await ChatService.saveMessage(welcomeMessage, aiConversation.id);
        conversations.insert(0, aiConversation);
      }

      setState(() {
        _conversations.addAll(conversations);
      });
    } catch (e) {
      print('Error loading conversations: $e');
      // Fallback to just AI chat (temporary, won't be saved to DB)
      _conversations.add(ChatConversation(
        id: 'temp_ai_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Sampul AI',
        lastMessage: 'Hello! I\'m your estate planning assistant. How can I help you today?',
        lastMessageTime: DateTime.now(),
        avatarUrl: '',
        unreadCount: 0,
        isOnline: true,
        conversationType: ConversationType.ai,
      ));
    }
  }

  void _navigateToChat(ChatConversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedChatConversationScreen(
          conversation: conversation,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chats',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Add more options
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final conversation = _conversations[index];
          return _buildChatItem(conversation);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Add new chat functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New chat feature coming soon!'),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildChatItem(ChatConversation conversation) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: conversation.conversationType == ConversationType.ai
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.secondary,
              child: conversation.conversationType == ConversationType.ai
                  ? const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    )
                  : Text(
                      conversation.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            if (conversation.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.surface,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                conversation.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                conversation.lastMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatTime(conversation.lastMessageTime),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => _navigateToChat(conversation),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${timestamp.day}/${timestamp.month}';
    } else if (difference.inHours > 0) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }
}
