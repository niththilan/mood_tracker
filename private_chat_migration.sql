-- =====================================================================
-- PRIVATE CHAT DATABASE MIGRATION SCRIPT
-- =====================================================================
-- Run these SQL commands in your Supabase SQL Editor
-- IMPORTANT: Backup your existing data before running these commands!

-- Step 1: Create backup of existing chat messages (IMPORTANT!)
CREATE TABLE chat_messages_backup AS 
SELECT * FROM public.chat_messages;

-- Step 2: Create private conversations table
CREATE TABLE IF NOT EXISTS public.private_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    participant_1_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    participant_2_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(participant_1_id, participant_2_id),
    CHECK (participant_1_id != participant_2_id)
);

-- Step 3: Add new columns to existing chat_messages table
ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES public.private_conversations(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Step 4: Add constraint to ensure private messages have conversation_id
ALTER TABLE public.chat_messages 
ADD CONSTRAINT chat_messages_private_check 
CHECK ((is_private = true AND conversation_id IS NOT NULL) OR (is_private = false AND conversation_id IS NULL));

-- Step 5: Enable Row Level Security for new table
ALTER TABLE public.private_conversations ENABLE ROW LEVEL SECURITY;

-- Step 6: Create RLS policies for private conversations
CREATE POLICY "Users can view their own conversations" ON public.private_conversations
    FOR SELECT USING (auth.uid() = participant_1_id OR auth.uid() = participant_2_id);

CREATE POLICY "Authenticated users can create conversations" ON public.private_conversations
    FOR INSERT WITH CHECK (auth.uid() = participant_1_id OR auth.uid() = participant_2_id);

-- Step 7: Drop existing chat message policies and create new ones
DROP POLICY IF EXISTS "Anyone can view chat messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Authenticated users can insert chat messages" ON public.chat_messages;

-- Create new policies for public messages
CREATE POLICY "Anyone can view public messages" ON public.chat_messages
    FOR SELECT USING (is_private = false);

-- Create new policies for private messages
CREATE POLICY "Users can view private messages in their conversations" ON public.chat_messages
    FOR SELECT USING (
        is_private = true AND 
        conversation_id IN (
            SELECT id FROM public.private_conversations 
            WHERE participant_1_id = auth.uid() OR participant_2_id = auth.uid()
        )
    );

-- Create insert policies
CREATE POLICY "Authenticated users can insert public messages" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id AND is_private = false);

CREATE POLICY "Users can insert private messages in their conversations" ON public.chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND 
        is_private = true AND
        conversation_id IN (
            SELECT id FROM public.private_conversations 
            WHERE participant_1_id = auth.uid() OR participant_2_id = auth.uid()
        )
    );

-- Step 8: Create indexes for better performance
CREATE INDEX IF NOT EXISTS private_conversations_participant_1_idx ON public.private_conversations(participant_1_id);
CREATE INDEX IF NOT EXISTS private_conversations_participant_2_idx ON public.private_conversations(participant_2_id);
CREATE INDEX IF NOT EXISTS private_conversations_participants_idx ON public.private_conversations(participant_1_id, participant_2_id);
CREATE INDEX IF NOT EXISTS chat_messages_conversation_id_idx ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS chat_messages_private_idx ON public.chat_messages(is_private, created_at DESC);

-- Step 9: Add updated_at trigger for private_conversations
CREATE TRIGGER private_conversations_updated_at 
    BEFORE UPDATE ON public.private_conversations 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Step 10: Enable real-time for private conversations
ALTER PUBLICATION supabase_realtime ADD TABLE public.private_conversations;

-- Step 11: Grant permissions
GRANT ALL ON public.private_conversations TO anon, authenticated;

-- =====================================================================
-- VERIFICATION QUERIES
-- =====================================================================
-- Run these to verify the migration worked correctly:

-- Check if new table exists
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' AND table_name = 'private_conversations';

-- Check if new columns exist
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'chat_messages' AND table_schema = 'public'
AND column_name IN ('conversation_id', 'is_private');

-- Check existing messages (should all show is_private = false)
SELECT id, user_id, message, is_private, conversation_id 
FROM public.chat_messages 
LIMIT 5;

-- =====================================================================
-- ROLLBACK SCRIPT (IF NEEDED)
-- =====================================================================
-- ONLY run this if you need to rollback the changes:

/*
-- Remove new columns
ALTER TABLE public.chat_messages DROP COLUMN IF EXISTS conversation_id;
ALTER TABLE public.chat_messages DROP COLUMN IF EXISTS is_private;

-- Drop new table
DROP TABLE IF EXISTS public.private_conversations;

-- Restore original policies (adjust as needed based on your original setup)
DROP POLICY IF EXISTS "Anyone can view public messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Users can view private messages in their conversations" ON public.chat_messages;
DROP POLICY IF EXISTS "Authenticated users can insert public messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Users can insert private messages in their conversations" ON public.chat_messages;

CREATE POLICY "Anyone can view chat messages" ON public.chat_messages FOR SELECT USING (true);
CREATE POLICY "Authenticated users can insert chat messages" ON public.chat_messages FOR INSERT WITH CHECK (auth.uid() = user_id);
*/
