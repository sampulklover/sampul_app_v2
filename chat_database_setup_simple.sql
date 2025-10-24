-- Simple Chat Database Setup for Sampul App
-- Run this in your Supabase SQL editor

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view conversations they participate in" ON chat_conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update conversations they participate in" ON chat_conversations;
DROP POLICY IF EXISTS "Users can delete conversations they created" ON chat_conversations;
DROP POLICY IF EXISTS "Authenticated users can manage conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages in their conversations" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Authenticated users can manage messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can view participants in their conversations" ON chat_participants;
DROP POLICY IF EXISTS "Users can add participants to their conversations" ON chat_participants;
DROP POLICY IF EXISTS "Users can update their own participation" ON chat_participants;
DROP POLICY IF EXISTS "Users can leave conversations" ON chat_participants;
DROP POLICY IF EXISTS "Authenticated users can manage participants" ON chat_participants;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON chat_conversations;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON chat_messages;
DROP POLICY IF EXISTS "Allow all for authenticated users" ON chat_participants;

-- Create chat_conversations table
CREATE TABLE IF NOT EXISTS chat_conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
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

-- Create chat_participants table for user-to-user conversations
CREATE TABLE IF NOT EXISTS chat_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_read_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  role TEXT DEFAULT 'member', -- 'admin', 'member'
  UNIQUE(conversation_id, user_id)
);

-- Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
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
  reply_to_message_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
  user_feedback BOOLEAN, -- true = liked, false = disliked, null = no feedback
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_timestamp ON chat_messages(timestamp);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_time ON chat_conversations(last_message_time);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_type ON chat_conversations(conversation_type);
CREATE INDEX IF NOT EXISTS idx_chat_participants_conversation_id ON chat_participants(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_participants_user_id ON chat_participants(user_id);

-- Enable Row Level Security (RLS)
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_participants ENABLE ROW LEVEL SECURITY;

-- Simple RLS policies - allow all for authenticated users
CREATE POLICY "Authenticated users can manage conversations" ON chat_conversations
  FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can manage messages" ON chat_messages
  FOR ALL USING (auth.uid() IS NOT NULL);

CREATE POLICY "Authenticated users can manage participants" ON chat_participants
  FOR ALL USING (auth.uid() IS NOT NULL);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger for updated_at (drop if exists first)
DROP TRIGGER IF EXISTS update_chat_conversations_updated_at ON chat_conversations;
CREATE TRIGGER update_chat_conversations_updated_at
  BEFORE UPDATE ON chat_conversations
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
