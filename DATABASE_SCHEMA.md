# Database Schema for Chat Feature

This document outlines the required database tables for the chat functionality.

## Required Tables

### 1. user_profiles
This table stores user profile information for the chat.

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  avatar_emoji TEXT NOT NULL DEFAULT '😊',
  color TEXT NOT NULL DEFAULT '#4CAF50',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view all profiles" ON user_profiles
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE TO authenticated USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON user_profiles
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = id);
```

### 2. chat_messages
This table stores all chat messages.

```sql
CREATE TABLE chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  message TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Authenticated users can view all messages" ON chat_messages
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can insert messages" ON chat_messages
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own messages" ON chat_messages
  FOR UPDATE TO authenticated USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own messages" ON chat_messages
  FOR DELETE TO authenticated USING (auth.uid() = user_id);
```

### 3. message_reactions
This table stores reactions to chat messages.

```sql
CREATE TABLE message_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id UUID NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(message_id, user_id, emoji)
);

-- Enable RLS
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Authenticated users can view all reactions" ON message_reactions
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Authenticated users can add reactions" ON message_reactions
  FOR INSERT TO authenticated WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own reactions" ON message_reactions
  FOR DELETE TO authenticated USING (auth.uid() = user_id);
```

## How to Set Up

1. Go to your Supabase project dashboard
2. Navigate to the SQL Editor
3. Run each of the above SQL commands to create the tables
4. The Row Level Security (RLS) policies ensure users can only access appropriate data

## Notes

- The chat feature will automatically create user profiles when users first access the chat
- Messages are stored with references to user profiles
- Reactions use a unique constraint to prevent duplicate reactions from the same user
- All tables have proper RLS policies for security
