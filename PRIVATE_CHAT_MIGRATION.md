# Private Chat Migration Guide

## Overview
This guide will help you add private chat functionality to your existing mood tracker application.

## Database Migration

### Step 1: Run the Updated Schema
Execute the updated `supabase_schema.sql` file in your Supabase SQL editor. This will:

1. Create a new `private_conversations` table
2. Update the `chat_messages` table to support both public and private messages
3. Add proper indexes and Row Level Security (RLS) policies
4. Enable real-time subscriptions for the new tables

### Step 2: Backup Existing Data (Important!)
Before running the migration, make sure to backup your existing chat messages:

```sql
-- Create a backup of existing messages
CREATE TABLE chat_messages_backup AS 
SELECT * FROM chat_messages;
```

### Step 3: Verify Migration
After running the schema, verify that:

1. Your existing public messages are still accessible
2. The new private conversation functionality works
3. Real-time updates work for both public and private chats

## Features Added

### Private Conversations
- Users can start private conversations with other users
- Private messages are only visible to the conversation participants
- Real-time updates for private messages

### Updated Chat Interface
- Public chat remains unchanged for existing functionality
- New "Private messages" button in the public chat header
- Dedicated conversations list page
- Private chat interface with other user's name in the header

### Database Structure
- `private_conversations` table for managing 1-on-1 conversations
- Updated `chat_messages` table with `is_private` and `conversation_id` fields
- Proper RLS policies to ensure privacy and security

## Usage

### Starting a Private Conversation
1. Go to the public chat
2. Tap the "Private messages" button (message icon in header)
3. Select "Start New Conversation"
4. Choose a user from the list
5. Start chatting privately!

### Accessing Existing Conversations
1. Go to the public chat
2. Tap the "Private messages" button
3. Select any existing conversation from the list

## Security Notes

- Private messages are protected by Row Level Security (RLS)
- Users can only see conversations they are participants in
- Private messages are completely separate from public chat
- All data is encrypted in transit and at rest by Supabase

## Troubleshooting

If you encounter issues:

1. Check that the schema migration completed successfully
2. Verify that RLS policies are properly applied
3. Ensure real-time subscriptions are working
4. Check the Flutter app logs for any errors

## Rollback (If Needed)

If you need to rollback the changes:

```sql
-- Restore from backup (only if you created one)
DROP TABLE chat_messages;
ALTER TABLE chat_messages_backup RENAME TO chat_messages;

-- Remove private conversations table
DROP TABLE private_conversations;
```

Note: This will remove all private conversations and messages sent after the migration.
