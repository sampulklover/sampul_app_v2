import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_conversation.dart';
import '../models/chat_participant.dart';

class ChatService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Save a message to Supabase
  static Future<void> saveMessage(ChatMessage message, String conversationId) async {
    try {
      final data = {
        'conversation_id': conversationId,
        'sender_id': message.senderId,
        'content': message.content,
        'is_from_user': message.isFromUser,
        'message_type': message.messageType.name,
        'timestamp': message.timestamp.toIso8601String(),
        'is_typing': message.isTyping,
        'is_streaming': message.isStreaming,
        'has_error': message.hasError,
        'error_message': message.errorMessage,
        'is_regenerating': message.isRegenerating,
        'is_edited': message.isEdited,
        'edited_at': message.editedAt?.toIso8601String(),
        'reply_to_message_id': message.replyToMessageId,
        'user_feedback': message.userFeedback,
      };

      // Only include ID if it's not empty (for database-generated UUIDs)
      if (message.id.isNotEmpty) {
        data['id'] = message.id;
      }

      await _supabase.from('chat_messages').insert(data);
    } catch (e) {
      print('Error saving message: $e');
    }
  }

  // Get messages for a conversation
  static Future<List<ChatMessage>> getMessages(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('timestamp', ascending: true);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }

  // Save a conversation
  static Future<void> saveConversation(ChatConversation conversation) async {
    try {
      await _supabase.from('chat_conversations').upsert({
        'id': conversation.id,
        'name': conversation.name,
        'last_message': conversation.lastMessage,
        'last_message_time': conversation.lastMessageTime.toIso8601String(),
        'avatar_url': conversation.avatarUrl,
        'unread_count': conversation.unreadCount,
        'is_online': conversation.isOnline,
        'conversation_type': conversation.conversationType.name,
        'created_by': conversation.createdBy,
        'created_at': conversation.createdAt?.toIso8601String(),
        'updated_at': conversation.updatedAt?.toIso8601String(),
      });
    } catch (e) {
      print('Error saving conversation: $e');
    }
  }

  // Get all conversations
  static Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .order('last_message_time', ascending: false);

      return (response as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting conversations: $e');
      return [];
    }
  }

  // Clear conversation messages
  static Future<void> clearConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('conversation_id', conversationId);
    } catch (e) {
      print('Error clearing conversation: $e');
    }
  }

  // Delete a message
  static Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .delete()
          .eq('id', messageId);
    } catch (e) {
      print('Error deleting message: $e');
    }
  }

  // Update message feedback
  static Future<void> updateMessageFeedback(String messageId, bool feedback) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'user_feedback': feedback})
          .eq('id', messageId);
    } catch (e) {
      print('Error updating message feedback: $e');
    }
  }

  // Create a new user-to-user conversation
  static Future<ChatConversation> createUserConversation({
    required String otherUserId,
    required String otherUserName,
    String? otherUserAvatar,
  }) async {
    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) throw Exception('User not authenticated');

      // Let database generate UUID
      final response = await _supabase
          .from('chat_conversations')
          .insert({
            'name': otherUserName,
            'last_message': 'Conversation started',
            'last_message_time': DateTime.now().toIso8601String(),
            'avatar_url': otherUserAvatar ?? '',
            'conversation_type': 'user',
            'created_by': currentUser.id,
          })
          .select()
          .single();

      final conversation = ChatConversation.fromJson(response);

      // Add participants
      await addParticipant(conversation.id, currentUser.id, ParticipantRole.admin);
      await addParticipant(conversation.id, otherUserId, ParticipantRole.member);

      return conversation;
    } catch (e) {
      print('Error creating user conversation: $e');
      rethrow;
    }
  }

  // Add participant to conversation
  static Future<void> addParticipant(String conversationId, String userId, ParticipantRole role) async {
    try {
      await _supabase.from('chat_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': role.name,
        'joined_at': DateTime.now().toIso8601String(),
        'is_active': true,
      });
    } catch (e) {
      print('Error adding participant: $e');
    }
  }

  // Get participants of a conversation
  static Future<List<ChatParticipant>> getParticipants(String conversationId) async {
    try {
      final response = await _supabase
          .from('chat_participants')
          .select()
          .eq('conversation_id', conversationId)
          .eq('is_active', true);

      return (response as List)
          .map((json) => ChatParticipant.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting participants: $e');
      return [];
    }
  }

  // Check if user is participant in conversation
  static Future<bool> isParticipant(String conversationId, String userId) async {
    try {
      final response = await _supabase
          .from('chat_participants')
          .select('id')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .eq('is_active', true)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      print('Error checking participant: $e');
      return false;
    }
  }

  // Leave conversation
  static Future<void> leaveConversation(String conversationId, String userId) async {
    try {
      await _supabase
          .from('chat_participants')
          .update({'is_active': false})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error leaving conversation: $e');
    }
  }

  // Update last read timestamp
  static Future<void> updateLastRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from('chat_participants')
          .update({'last_read_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error updating last read: $e');
    }
  }

  // Get user's conversations (both AI and user-to-user)
  static Future<List<ChatConversation>> getUserConversations(String userId) async {
    try {
      // Simple query - get all conversations for now
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('created_by', userId)
          .order('last_message_time', ascending: false);

      return (response as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting user conversations: $e');
      return [];
    }
  }
}
