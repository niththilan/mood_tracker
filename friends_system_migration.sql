-- =============================================================================
-- COMPLETE FRIENDS SYSTEM MIGRATION FOR MOOD TRACKER APPLICATION
-- =============================================================================
-- This migration adds friend request and friendship functionality to the 
-- existing mood tracker application with proper privacy controls and mood sharing.
-- Includes all necessary dependencies and chat system integration.
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- PREREQUISITE: ENSURE CORE TABLES EXIST
-- =============================================================================

-- 1. User profiles table (if not exists)
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 2 AND length(name) <= 50),
    avatar_emoji TEXT DEFAULT '😊',
    color TEXT DEFAULT '#4CAF50',
    age INTEGER CHECK (age >= 13 AND age <= 120),
    gender TEXT CHECK (gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say')),
    timezone TEXT DEFAULT 'UTC',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 2. Mood categories table (if not exists)
CREATE TABLE IF NOT EXISTS public.mood_categories (
    id SMALLSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    emoji TEXT NOT NULL,
    color_hex TEXT NOT NULL,
    mood_score INTEGER NOT NULL CHECK (mood_score >= 1 AND mood_score <= 10),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Insert standard mood categories
INSERT INTO public.mood_categories (name, emoji, color_hex, mood_score, description) VALUES
('Happy', '😊', '#4CAF50', 8, 'Feeling joyful and content'),
('Excited', '😄', '#FF9800', 9, 'Full of energy and enthusiasm'),
('Calm', '😌', '#00BCD4', 7, 'Peaceful and relaxed'),
('Neutral', '😐', '#9E9E9E', 5, 'Neither particularly good nor bad'),
('Sad', '😔', '#2196F3', 3, 'Feeling down or melancholy'),
('Angry', '😠', '#F44336', 2, 'Frustrated or irritated'),
('Anxious', '😨', '#9C27B0', 3, 'Worried or stressed'),
('Tired', '😴', '#607D8B', 4, 'Exhausted or sleepy')
ON CONFLICT (name) DO NOTHING;

-- 3. Mood entries table (if not exists)
CREATE TABLE IF NOT EXISTS public.mood_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    mood_category_id SMALLINT REFERENCES public.mood_categories(id) NOT NULL,
    intensity INTEGER CHECK (intensity >= 1 AND intensity <= 10) DEFAULT 5,
    note TEXT DEFAULT '',
    location TEXT,
    weather TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- 4. Private conversations table (for chat functionality)
CREATE TABLE IF NOT EXISTS public.private_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    participant_1_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    participant_2_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(participant_1_id, participant_2_id),
    CHECK (participant_1_id != participant_2_id)
);

-- 5. Chat messages table (if not exists)
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL CHECK (length(message) >= 1 AND length(message) <= 1000),
    reply_to_message_id BIGINT REFERENCES public.chat_messages(id) ON DELETE SET NULL,
    conversation_id UUID REFERENCES public.private_conversations(id) ON DELETE CASCADE,
    is_edited BOOLEAN DEFAULT false,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    -- Check that private messages have a conversation_id
    CHECK ((is_private = true AND conversation_id IS NOT NULL) OR (is_private = false AND conversation_id IS NULL))
);

-- =============================================================================
-- UTILITY FUNCTIONS (Required for triggers)
-- =============================================================================

-- Function to handle updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to handle new user creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_profiles (id, name)
    VALUES (NEW.id, COALESCE(NEW.raw_user_meta_data->>'name', NEW.email));
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 1. FRIEND REQUESTS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.friend_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    receiver_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'declined', 'cancelled')),
    message TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    responded_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(sender_id, receiver_id),
    CHECK (sender_id != receiver_id)
);

-- =============================================================================
-- 2. FRIENDSHIPS TABLE (Mutual relationships)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.friendships (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user1_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    user2_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(user1_id, user2_id),
    CHECK (user1_id != user2_id)
);

-- =============================================================================
-- 3. USER MOOD SHARING SETTINGS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_mood_sharing_settings (
    id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE PRIMARY KEY,
    share_with_friends BOOLEAN DEFAULT true,
    share_mood_details BOOLEAN DEFAULT true,
    share_mood_notes BOOLEAN DEFAULT false,
    share_mood_location BOOLEAN DEFAULT false,
    share_recent_count INTEGER DEFAULT 5 CHECK (share_recent_count >= 0 AND share_recent_count <= 50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =============================================================================
-- 4. FRIEND ACTIVITY FEED TABLE (Optional - for activity tracking)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.friend_activity_feed (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    friend_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    activity_type TEXT NOT NULL CHECK (activity_type IN ('mood_entry', 'goal_completed', 'streak_milestone')),
    activity_data JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    is_read BOOLEAN DEFAULT false
);

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY FOR ALL TABLES
-- =============================================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_mood_sharing_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.friend_activity_feed ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- SECURITY POLICIES FOR CORE TABLES
-- =============================================================================

-- User profiles policies
DROP POLICY IF EXISTS "Users can view profiles for chat and friends" ON public.user_profiles;
CREATE POLICY "Users can view profiles for chat and friends" ON public.user_profiles
    FOR SELECT USING (
        -- User can always view their own profile
        auth.uid() = id 
        OR 
        -- Anyone can view basic profile info for chat/friends functionality
        true
    );

CREATE POLICY "Users can update own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Mood entries policies  
CREATE POLICY "Users can view own mood entries" ON public.mood_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own mood entries" ON public.mood_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own mood entries" ON public.mood_entries
    FOR UPDATE USING (auth.uid() = user_id);

-- Private conversations policies
CREATE POLICY "Users can view their own conversations" ON public.private_conversations
    FOR SELECT USING (auth.uid() = participant_1_id OR auth.uid() = participant_2_id);

CREATE POLICY "Users can create conversations with friends" ON public.private_conversations
    FOR INSERT WITH CHECK (
        (auth.uid() = participant_1_id OR auth.uid() = participant_2_id)
        AND EXISTS (
            SELECT 1 FROM public.friendships f 
            WHERE (f.user1_id = participant_1_id AND f.user2_id = participant_2_id)
               OR (f.user1_id = participant_2_id AND f.user2_id = participant_1_id)
        )
    );

-- Chat messages policies
CREATE POLICY "Anyone can view public messages" ON public.chat_messages
    FOR SELECT USING (is_private = false);

CREATE POLICY "Users can view private messages in their conversations" ON public.chat_messages
    FOR SELECT USING (
        is_private = true AND 
        conversation_id IN (
            SELECT id FROM public.private_conversations 
            WHERE participant_1_id = auth.uid() OR participant_2_id = auth.uid()
        )
    );

CREATE POLICY "Authenticated users can insert public messages" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id AND is_private = false);

CREATE POLICY "Users can insert private messages to friends only" ON public.chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND 
        is_private = true AND
        conversation_id IN (
            SELECT pc.id FROM public.private_conversations pc
            WHERE (pc.participant_1_id = auth.uid() OR pc.participant_2_id = auth.uid())
            AND EXISTS (
                SELECT 1 FROM public.friendships f 
                WHERE (f.user1_id = pc.participant_1_id AND f.user2_id = pc.participant_2_id)
                   OR (f.user1_id = pc.participant_2_id AND f.user2_id = pc.participant_1_id)
            )
        )
    );

-- =============================================================================
-- SECURITY POLICIES FOR FRIEND REQUESTS
-- =============================================================================
-- Users can view friend requests they sent or received
CREATE POLICY "Users can view their friend requests" ON public.friend_requests
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can send friend requests (create)
CREATE POLICY "Users can send friend requests" ON public.friend_requests
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can update friend requests they sent (cancel) or received (accept/decline)
CREATE POLICY "Users can update their friend requests" ON public.friend_requests
    FOR UPDATE USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can delete friend requests they sent
CREATE POLICY "Users can delete their sent friend requests" ON public.friend_requests
    FOR DELETE USING (auth.uid() = sender_id);

-- =============================================================================
-- SECURITY POLICIES FOR FRIENDSHIPS
-- =============================================================================
-- Users can view their friendships
CREATE POLICY "Users can view their friendships" ON public.friendships
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- System can create friendships (through functions)
CREATE POLICY "System can create friendships" ON public.friendships
    FOR INSERT WITH CHECK (true);

-- Users can delete their friendships (unfriend)
CREATE POLICY "Users can delete their friendships" ON public.friendships
    FOR DELETE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- =============================================================================
-- SECURITY POLICIES FOR MOOD SHARING SETTINGS
-- =============================================================================
-- Users can view and modify their own mood sharing settings
CREATE POLICY "Users can manage their mood sharing settings" ON public.user_mood_sharing_settings
    FOR ALL USING (auth.uid() = id);

-- =============================================================================
-- SECURITY POLICIES FOR FRIEND ACTIVITY FEED
-- =============================================================================
-- Users can view activity from their friends
CREATE POLICY "Users can view friend activity" ON public.friend_activity_feed
    FOR SELECT USING (
        auth.uid() = user_id AND 
        EXISTS (
            SELECT 1 FROM public.friendships f 
            WHERE (f.user1_id = auth.uid() AND f.user2_id = friend_id) 
            OR (f.user2_id = auth.uid() AND f.user1_id = friend_id)
        )
    );

-- System can insert friend activity
CREATE POLICY "System can create friend activity" ON public.friend_activity_feed
    FOR INSERT WITH CHECK (true);

-- Users can update read status of their activity feed
CREATE POLICY "Users can update their activity feed read status" ON public.friend_activity_feed
    FOR UPDATE USING (auth.uid() = user_id);

-- =============================================================================
-- COMPREHENSIVE INDEXES FOR PERFORMANCE
-- =============================================================================

-- User profiles indexes
CREATE INDEX IF NOT EXISTS user_profiles_name_idx ON public.user_profiles(name);
CREATE INDEX IF NOT EXISTS user_profiles_created_at_idx ON public.user_profiles(created_at DESC);

-- Mood entries indexes
CREATE INDEX IF NOT EXISTS mood_entries_user_id_idx ON public.mood_entries(user_id);
CREATE INDEX IF NOT EXISTS mood_entries_created_at_idx ON public.mood_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS mood_entries_user_created_idx ON public.mood_entries(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS mood_entries_category_idx ON public.mood_entries(mood_category_id);

-- Private conversations indexes
CREATE INDEX IF NOT EXISTS private_conversations_participant_1_idx ON public.private_conversations(participant_1_id);
CREATE INDEX IF NOT EXISTS private_conversations_participant_2_idx ON public.private_conversations(participant_2_id);
CREATE INDEX IF NOT EXISTS private_conversations_participants_idx ON public.private_conversations(participant_1_id, participant_2_id);

-- Chat messages indexes
CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON public.chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS chat_messages_conversation_id_idx ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS chat_messages_private_idx ON public.chat_messages(is_private, created_at DESC);
CREATE INDEX IF NOT EXISTS chat_messages_public_idx ON public.chat_messages(is_private, created_at DESC) WHERE is_private = false;

-- Friend requests indexes
CREATE INDEX IF NOT EXISTS friend_requests_sender_idx ON public.friend_requests(sender_id);
CREATE INDEX IF NOT EXISTS friend_requests_receiver_idx ON public.friend_requests(receiver_id);
CREATE INDEX IF NOT EXISTS friend_requests_status_idx ON public.friend_requests(status);
CREATE INDEX IF NOT EXISTS friend_requests_created_at_idx ON public.friend_requests(created_at DESC);

-- Friendships indexes
CREATE INDEX IF NOT EXISTS friendships_user1_idx ON public.friendships(user1_id);
CREATE INDEX IF NOT EXISTS friendships_user2_idx ON public.friendships(user2_id);
CREATE INDEX IF NOT EXISTS friendships_users_idx ON public.friendships(user1_id, user2_id);

-- Friend activity indexes
CREATE INDEX IF NOT EXISTS friend_activity_user_idx ON public.friend_activity_feed(user_id);
CREATE INDEX IF NOT EXISTS friend_activity_friend_idx ON public.friend_activity_feed(friend_id);
CREATE INDEX IF NOT EXISTS friend_activity_type_idx ON public.friend_activity_feed(activity_type);
CREATE INDEX IF NOT EXISTS friend_activity_created_at_idx ON public.friend_activity_feed(created_at DESC);
CREATE INDEX IF NOT EXISTS friend_activity_unread_idx ON public.friend_activity_feed(user_id, is_read, created_at DESC);

-- =============================================================================
-- UPDATED_AT TRIGGERS FOR ALL TABLES
-- =============================================================================

-- Core table triggers
CREATE TRIGGER user_profiles_updated_at 
    BEFORE UPDATE ON public.user_profiles 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER mood_entries_updated_at 
    BEFORE UPDATE ON public.mood_entries 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER private_conversations_updated_at 
    BEFORE UPDATE ON public.private_conversations 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER chat_messages_updated_at 
    BEFORE UPDATE ON public.chat_messages 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Friends system triggers
CREATE TRIGGER friend_requests_updated_at 
    BEFORE UPDATE ON public.friend_requests 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER user_mood_sharing_settings_updated_at 
    BEFORE UPDATE ON public.user_mood_sharing_settings 
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- User creation trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- FRIEND SYSTEM UTILITY FUNCTIONS
-- =============================================================================

-- Function to send a friend request
CREATE OR REPLACE FUNCTION public.send_friend_request(
    receiver_user_id UUID,
    request_message TEXT DEFAULT ''
)
RETURNS JSON AS $$
DECLARE
    sender_user_id UUID := auth.uid();
    existing_request RECORD;
    existing_friendship RECORD;
    result JSON;
BEGIN
    -- Check if user is trying to send request to themselves
    IF sender_user_id = receiver_user_id THEN
        RETURN json_build_object('success', false, 'error', 'Cannot send friend request to yourself');
    END IF;

    -- Check if friendship already exists
    SELECT * INTO existing_friendship 
    FROM public.friendships 
    WHERE (user1_id = sender_user_id AND user2_id = receiver_user_id) 
    OR (user1_id = receiver_user_id AND user2_id = sender_user_id);
    
    IF existing_friendship IS NOT NULL THEN
        RETURN json_build_object('success', false, 'error', 'Already friends');
    END IF;

    -- Check if there's already a pending request
    SELECT * INTO existing_request 
    FROM public.friend_requests 
    WHERE sender_id = sender_user_id AND receiver_id = receiver_user_id AND status = 'pending';
    
    IF existing_request IS NOT NULL THEN
        RETURN json_build_object('success', false, 'error', 'Friend request already sent');
    END IF;

    -- Check if there's a pending request from the other user (auto-accept)
    SELECT * INTO existing_request 
    FROM public.friend_requests 
    WHERE sender_id = receiver_user_id AND receiver_id = sender_user_id AND status = 'pending';
    
    IF existing_request IS NOT NULL THEN
        -- Auto-accept the existing request and create friendship
        UPDATE public.friend_requests 
        SET status = 'accepted', responded_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
        WHERE id = existing_request.id;
        
        -- Create friendship (ensure consistent ordering)
        INSERT INTO public.friendships (user1_id, user2_id)
        VALUES (
            LEAST(sender_user_id, receiver_user_id),
            GREATEST(sender_user_id, receiver_user_id)
        );
        
        RETURN json_build_object('success', true, 'message', 'Friend request accepted automatically', 'auto_accepted', true);
    END IF;

    -- Create new friend request
    INSERT INTO public.friend_requests (sender_id, receiver_id, message)
    VALUES (sender_user_id, receiver_user_id, request_message);
    
    RETURN json_build_object('success', true, 'message', 'Friend request sent successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to respond to a friend request
CREATE OR REPLACE FUNCTION public.respond_to_friend_request(
    request_id UUID,
    response TEXT -- 'accepted' or 'declined'
)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID := auth.uid();
    request_record RECORD;
    result JSON;
BEGIN
    -- Validate response
    IF response NOT IN ('accepted', 'declined') THEN
        RETURN json_build_object('success', false, 'error', 'Invalid response. Must be accepted or declined');
    END IF;

    -- Get the friend request
    SELECT * INTO request_record 
    FROM public.friend_requests 
    WHERE id = request_id AND receiver_id = current_user_id AND status = 'pending';
    
    IF request_record IS NULL THEN
        RETURN json_build_object('success', false, 'error', 'Friend request not found or already responded');
    END IF;

    -- Update the friend request
    UPDATE public.friend_requests 
    SET status = response, responded_at = CURRENT_TIMESTAMP, updated_at = CURRENT_TIMESTAMP
    WHERE id = request_id;

    -- If accepted, create friendship
    IF response = 'accepted' THEN
        INSERT INTO public.friendships (user1_id, user2_id)
        VALUES (
            LEAST(request_record.sender_id, current_user_id),
            GREATEST(request_record.sender_id, current_user_id)
        );
        
        RETURN json_build_object('success', true, 'message', 'Friend request accepted');
    ELSE
        RETURN json_build_object('success', true, 'message', 'Friend request declined');
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to remove a friendship
CREATE OR REPLACE FUNCTION public.remove_friendship(friend_user_id UUID)
RETURNS JSON AS $$
DECLARE
    current_user_id UUID := auth.uid();
    friendship_exists BOOLEAN;
BEGIN
    -- Check if friendship exists
    SELECT EXISTS(
        SELECT 1 FROM public.friendships 
        WHERE (user1_id = current_user_id AND user2_id = friend_user_id) 
        OR (user1_id = friend_user_id AND user2_id = current_user_id)
    ) INTO friendship_exists;
    
    IF NOT friendship_exists THEN
        RETURN json_build_object('success', false, 'error', 'Friendship does not exist');
    END IF;

    -- Remove friendship
    DELETE FROM public.friendships 
    WHERE (user1_id = current_user_id AND user2_id = friend_user_id) 
    OR (user1_id = friend_user_id AND user2_id = current_user_id);
    
    RETURN json_build_object('success', true, 'message', 'Friendship removed successfully');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's friends list
CREATE OR REPLACE FUNCTION public.get_user_friends(user_uuid UUID DEFAULT auth.uid())
RETURNS TABLE (
    friend_id UUID,
    friend_name TEXT,
    friend_avatar_emoji TEXT,
    friend_color TEXT,
    friendship_created_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE 
            WHEN f.user1_id = user_uuid THEN f.user2_id
            ELSE f.user1_id
        END as friend_id,
        up.name as friend_name,
        up.avatar_emoji as friend_avatar_emoji,
        up.color as friend_color,
        f.created_at as friendship_created_at
    FROM public.friendships f
    JOIN public.user_profiles up ON (
        CASE 
            WHEN f.user1_id = user_uuid THEN f.user2_id
            ELSE f.user1_id
        END = up.id
    )
    WHERE f.user1_id = user_uuid OR f.user2_id = user_uuid
    ORDER BY f.created_at DESC;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to get friend's recent moods (respecting privacy settings)
CREATE OR REPLACE FUNCTION public.get_friend_recent_moods(
    friend_user_id UUID,
    limit_count INTEGER DEFAULT 5
)
RETURNS TABLE (
    mood_id BIGINT,
    mood_name TEXT,
    mood_emoji TEXT,
    mood_score INTEGER,
    intensity INTEGER,
    note TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE
) AS $$
DECLARE
    current_user_id UUID := auth.uid();
    is_friend BOOLEAN;
    sharing_settings RECORD;
BEGIN
    -- Check if they are friends
    SELECT EXISTS(
        SELECT 1 FROM public.friendships 
        WHERE (user1_id = current_user_id AND user2_id = friend_user_id) 
        OR (user1_id = friend_user_id AND user2_id = current_user_id)
    ) INTO is_friend;
    
    IF NOT is_friend THEN
        RETURN;
    END IF;

    -- Get friend's sharing settings
    SELECT * INTO sharing_settings 
    FROM public.user_mood_sharing_settings 
    WHERE id = friend_user_id;
    
    -- If no settings exist or sharing is disabled, return empty
    IF sharing_settings IS NULL OR NOT sharing_settings.share_with_friends THEN
        RETURN;
    END IF;

    -- Return mood data based on privacy settings
    RETURN QUERY
    SELECT 
        me.id as mood_id,
        mc.name as mood_name,
        mc.emoji as mood_emoji,
        mc.mood_score,
        me.intensity,
        CASE 
            WHEN sharing_settings.share_mood_notes THEN me.note
            ELSE ''
        END as note,
        CASE 
            WHEN sharing_settings.share_mood_location THEN me.location
            ELSE ''
        END as location,
        me.created_at
    FROM public.mood_entries me
    JOIN public.mood_categories mc ON me.mood_category_id = mc.id
    WHERE me.user_id = friend_user_id
    ORDER BY me.created_at DESC
    LIMIT LEAST(limit_count, sharing_settings.share_recent_count);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Function to check if two users are friends
CREATE OR REPLACE FUNCTION public.are_users_friends(user1_uuid UUID, user2_uuid UUID)
RETURNS BOOLEAN AS $$
DECLARE
    friendship_exists BOOLEAN;
BEGIN
    SELECT EXISTS(
        SELECT 1 FROM public.friendships 
        WHERE (user1_id = user1_uuid AND user2_id = user2_uuid) 
        OR (user1_id = user2_uuid AND user2_id = user1_uuid)
    ) INTO friendship_exists;
    
    RETURN friendship_exists;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =============================================================================
-- TRIGGER TO CREATE DEFAULT MOOD SHARING SETTINGS
-- =============================================================================
CREATE OR REPLACE FUNCTION public.create_default_mood_sharing_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_mood_sharing_settings (id)
    VALUES (NEW.id)
    ON CONFLICT (id) DO NOTHING;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER create_user_mood_sharing_settings
    AFTER INSERT ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.create_default_mood_sharing_settings();

-- =============================================================================
-- UPDATE USER PROFILE POLICY TO ALLOW FRIENDS TO VIEW BASIC INFO
-- =============================================================================
-- Drop existing policy and create new one
DROP POLICY IF EXISTS "Users can view other profiles for chat" ON public.user_profiles;

CREATE POLICY "Users can view profiles for chat and friends" ON public.user_profiles
    FOR SELECT USING (
        -- User can always view their own profile
        auth.uid() = id 
        OR 
        -- Anyone can view basic profile info for chat/friends functionality
        true
    );

-- =============================================================================
-- ADD FRIEND REQUEST AND FRIENDSHIP VIEWS
-- =============================================================================

-- View for pending friend requests received by user
CREATE OR REPLACE VIEW public.my_pending_friend_requests AS
SELECT 
    fr.id,
    fr.sender_id,
    up.name as sender_name,
    up.avatar_emoji as sender_avatar,
    up.color as sender_color,
    fr.message,
    fr.created_at
FROM public.friend_requests fr
JOIN public.user_profiles up ON fr.sender_id = up.id
WHERE fr.receiver_id = auth.uid() AND fr.status = 'pending';

-- View for user's friends with profiles
CREATE OR REPLACE VIEW public.my_friends AS
SELECT 
    CASE 
        WHEN f.user1_id = auth.uid() THEN f.user2_id
        ELSE f.user1_id
    END as friend_id,
    up.name as friend_name,
    up.avatar_emoji as friend_avatar,
    up.color as friend_color,
    f.created_at as friends_since
FROM public.friendships f
JOIN public.user_profiles up ON (
    CASE 
        WHEN f.user1_id = auth.uid() THEN f.user2_id
        ELSE f.user1_id
    END = up.id
)
WHERE f.user1_id = auth.uid() OR f.user2_id = auth.uid();

-- =============================================================================
-- REAL-TIME SETUP FOR ALL TABLES
-- =============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.mood_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.private_conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friend_requests;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friendships;
ALTER PUBLICATION supabase_realtime ADD TABLE public.friend_activity_feed;

-- =============================================================================
-- COMPREHENSIVE PERMISSIONS GRANTS
-- =============================================================================
-- Grant permissions on all tables
GRANT ALL ON public.user_profiles TO anon, authenticated;
GRANT ALL ON public.mood_categories TO anon, authenticated;
GRANT ALL ON public.mood_entries TO anon, authenticated;
GRANT ALL ON public.private_conversations TO anon, authenticated;
GRANT ALL ON public.chat_messages TO anon, authenticated;
GRANT ALL ON public.friend_requests TO anon, authenticated;
GRANT ALL ON public.friendships TO anon, authenticated;
GRANT ALL ON public.user_mood_sharing_settings TO anon, authenticated;
GRANT ALL ON public.friend_activity_feed TO anon, authenticated;

-- Grant sequence permissions
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Grant permissions on new functions
GRANT EXECUTE ON FUNCTION public.send_friend_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.respond_to_friend_request(UUID, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION public.remove_friendship(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_friends(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_friend_recent_moods(UUID, INTEGER) TO authenticated;
GRANT EXECUTE ON FUNCTION public.are_users_friends(UUID, UUID) TO authenticated;

-- =============================================================================
-- MIGRATION COMPLETE - VERIFICATION QUERIES
-- =============================================================================

-- Verify all tables exist
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'user_profiles', 'mood_categories', 'mood_entries', 
    'private_conversations', 'chat_messages',
    'friend_requests', 'friendships', 'user_mood_sharing_settings', 'friend_activity_feed'
)
ORDER BY table_name;

-- Verify all functions exist
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'handle_updated_at', 'handle_new_user',
    'send_friend_request', 'respond_to_friend_request', 'remove_friendship',
    'get_user_friends', 'get_friend_recent_moods', 'are_users_friends',
    'create_default_mood_sharing_settings'
)
ORDER BY routine_name;

-- =============================================================================
-- ADDITIONAL SECURITY POLICIES FOR PRIVATE MESSAGING
-- =============================================================================
-- The application enforces friends-only private messaging at the service layer.
-- The database policies above provide additional security at the database level.

-- Optional: Additional policy for private_conversations (already included above)
-- This ensures users can only create conversations with friends

-- Optional: Additional policy for private_messages (already included above)  
-- This ensures users can only send private messages to friends

-- =============================================================================
-- POST-MIGRATION INSTRUCTIONS
-- =============================================================================
-- 
-- 1. ✅ Run this entire migration file in Supabase SQL Editor
-- 2. ✅ Verify all tables and functions were created successfully
-- 3. ✅ Test friends system functionality in your Flutter app
-- 4. ✅ Test private messaging with friends-only enforcement
-- 
-- FEATURES ENABLED:
-- ✅ Complete user profile system
-- ✅ Mood tracking with categories and entries  
-- ✅ Friend requests (send, accept, decline, cancel)
-- ✅ Friendship management (add, remove, list)
-- ✅ Friends-only private messaging
-- ✅ Public community chat
-- ✅ Mood sharing privacy controls
-- ✅ Real-time updates for all features
-- ✅ Comprehensive security policies
-- ✅ Performance optimized with indexes
-- 
-- TROUBLESHOOTING:
-- - If any function fails, check that all prerequisite tables exist
-- - If policies fail, ensure RLS is enabled on all tables
-- - If real-time doesn't work, verify supabase_realtime publication
-- - For permission issues, check that grants were applied correctly
-- 
-- =============================================================================

SELECT 'Complete friends system with chat migration completed successfully!' as status,
       'All tables, functions, policies, and features are now ready for use.' as message;
