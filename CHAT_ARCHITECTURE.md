# Chat Architecture Documentation

## Overview
The chat system is designed to support both AI conversations and future user-to-user messaging. The database schema is built to be scalable and flexible for various conversation types.

## Database Schema

### 1. `chat_conversations` Table
Stores conversation metadata and supports multiple conversation types.

```sql
CREATE TABLE chat_conversations (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE,
  avatar_url TEXT,
  unread_count INTEGER DEFAULT 0,
  is_online BOOLEAN DEFAULT false,
  conversation_type TEXT NOT NULL DEFAULT 'ai', -- 'ai', 'user', 'group'
  created_by UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Conversation Types:**
- `ai`: AI assistant conversations (current implementation)
- `user`: One-on-one user conversations (future feature)
- `group`: Group conversations (future feature)

### 2. `chat_participants` Table
Manages user participation in conversations.

```sql
CREATE TABLE chat_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id TEXT NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_read_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  UNIQUE(conversation_id, user_id)
);
```

**Roles:**
- `admin`: Can manage conversation (add/remove participants, delete conversation)
- `member`: Regular participant

### 3. `chat_messages` Table
Stores all messages with support for various message types and features.

```sql
CREATE TABLE chat_messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES auth.users(id) ON DELETE SET NULL, -- NULL for AI messages
  content TEXT NOT NULL,
  is_from_user BOOLEAN NOT NULL,
  message_type TEXT DEFAULT 'text', -- 'text', 'image', 'file', 'system'
  timestamp TIMESTAMP WITH TIME ZONE NOT NULL,
  is_typing BOOLEAN DEFAULT false,
  is_streaming BOOLEAN DEFAULT false,
  has_error BOOLEAN DEFAULT false,
  error_message TEXT,
  is_regenerating BOOLEAN DEFAULT false,
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMP WITH TIME ZONE,
  reply_to_message_id TEXT REFERENCES chat_messages(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Message Types:**
- `text`: Regular text messages
- `image`: Image attachments (future feature)
- `file`: File attachments (future feature)
- `system`: System messages (user joined, left, etc.)

## Data Models

### ChatConversation
```dart
enum ConversationType { ai, user, group }

class ChatConversation {
  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String avatarUrl;
  final int unreadCount;
  final bool isOnline;
  final ConversationType conversationType;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
```

### ChatMessage
```dart
enum MessageType { text, image, file, system }

class ChatMessage {
  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final bool isTyping;
  final bool isStreaming;
  final bool hasError;
  final String? errorMessage;
  final bool isRegenerating;
  final String? senderId;
  final MessageType messageType;
  final bool isEdited;
  final DateTime? editedAt;
  final String? replyToMessageId;
}
```

### ChatParticipant
```dart
enum ParticipantRole { admin, member }

class ChatParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final DateTime joinedAt;
  final DateTime? lastReadAt;
  final bool isActive;
  final ParticipantRole role;
}
```

## Security (Row Level Security)

### Conversation Access
- Users can view conversations they created or participate in
- Users can only create conversations they own
- Users can update conversations they participate in
- Only conversation creators can delete conversations

### Message Access
- Users can view messages in their conversations
- Users can send messages in their conversations
- Users can only update/delete their own messages

### Participant Management
- Users can view participants in their conversations
- Conversation creators can add participants
- Users can update their own participation status
- Users can leave conversations

## Current Implementation

### AI Chat Features
- ✅ Streaming text responses
- ✅ Markdown rendering
- ✅ Message animations
- ✅ Typing indicators
- ✅ Error handling with retry
- ✅ Message actions (copy, regenerate, feedback)
- ✅ Persistent chat history
- ✅ Auto-scroll and smooth animations

### Database Features
- ✅ Row Level Security (RLS) policies
- ✅ Optimized indexes for performance
- ✅ Automatic timestamp updates
- ✅ Cascade delete for data integrity

## Future User-to-User Features

### Planned Implementation
1. **User Discovery**: Find and add other users
2. **Direct Messages**: One-on-one conversations
3. **Group Chats**: Multi-user conversations
4. **Message Features**:
   - Image/file attachments
   - Message replies
   - Message editing
   - Message reactions
   - Read receipts
5. **Real-time Features**:
   - Live typing indicators
   - Online status
   - Push notifications
   - Message delivery status

### API Endpoints (Future)
```dart
// Create user conversation
ChatService.createUserConversation(
  otherUserId: 'user123',
  otherUserName: 'John Doe',
  otherUserAvatar: 'avatar_url'
);

// Add user to group
ChatService.addParticipant(
  conversationId: 'group_123',
  userId: 'user456',
  role: ParticipantRole.member
);

// Get user's conversations
ChatService.getUserConversations(userId);

// Check if user is participant
ChatService.isParticipant(conversationId, userId);
```

## Migration Strategy

### Phase 1: Current (AI Chat)
- ✅ Basic AI conversation functionality
- ✅ Database schema with user support
- ✅ RLS policies for security
- ✅ Message persistence

### Phase 2: User-to-User (Future)
- 🔄 User discovery and friend system
- 🔄 Direct message creation
- 🔄 Real-time message delivery
- 🔄 Enhanced message features

### Phase 3: Advanced Features (Future)
- 🔄 Group conversations
- 🔄 File/image sharing
- 🔄 Voice/video calls
- 🔄 Advanced moderation

## Performance Considerations

### Indexes
- `idx_chat_messages_conversation_id`: Fast message retrieval
- `idx_chat_messages_timestamp`: Chronological ordering
- `idx_chat_messages_sender_id`: User message filtering
- `idx_chat_conversations_last_message_time`: Recent conversations
- `idx_chat_conversations_type`: Conversation type filtering
- `idx_chat_participants_conversation_id`: Participant lookup
- `idx_chat_participants_user_id`: User conversation lookup

### Optimization
- Pagination for large message histories
- Lazy loading for conversation lists
- Efficient RLS policies
- Proper foreign key constraints

## Testing Strategy

### Unit Tests
- Model serialization/deserialization
- Service method functionality
- Data validation

### Integration Tests
- Database operations
- RLS policy enforcement
- Real-time updates

### End-to-End Tests
- Complete chat flows
- User permission scenarios
- Error handling

This architecture provides a solid foundation for both current AI chat functionality and future user-to-user messaging features while maintaining security, performance, and scalability.
