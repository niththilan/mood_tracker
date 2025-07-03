-- =============================================================================
-- SUPABASE SQL SCHEMA FOR MOOD TRACKER APPLICATION - INTERCONNECTED VERSION
-- =============================================================================
-- This schema creates all the necessary tables with proper relationships and
-- interconnections for the Flutter mood tracker application.
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. USER PROFILES TABLE (Base table for all user data)
-- =============================================================================
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

-- =============================================================================
-- 2. MOOD CATEGORIES TABLE (Standardized mood categories)
-- =============================================================================
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

-- =============================================================================
-- 3. MOOD TAGS TABLE (Predefined tags for mood influences)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mood_tags (
    id SMALLSERIAL PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL CHECK (category IN ('personal', 'social', 'work', 'health', 'environment', 'activity')),
    icon TEXT,
    color_hex TEXT DEFAULT '#666666',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- Insert standard mood tags
INSERT INTO public.mood_tags (name, category, icon, color_hex) VALUES
('Work', 'work', '💼', '#FF9800'),
('Family', 'social', '👨‍👩‍👧‍👦', '#E91E63'),
('Friends', 'social', '👥', '#9C27B0'),
('Health', 'health', '🏥', '#F44336'),
('Exercise', 'health', '🏃‍♂️', '#4CAF50'),
('Sleep', 'health', '😴', '#3F51B5'),
('Weather', 'environment', '🌤️', '#00BCD4'),
('Food', 'personal', '🍽️', '#FF5722'),
('Social', 'social', '🎉', '#E91E63'),
('Alone', 'personal', '🧘‍♀️', '#795548'),
('Stress', 'personal', '😰', '#F44336'),
('Relaxation', 'personal', '🛀', '#00BCD4'),
('Achievement', 'personal', '🏆', '#FFC107'),
('Challenge', 'personal', '⚡', '#FF9800'),
('Creativity', 'activity', '🎨', '#9C27B0'),
('Nature', 'environment', '🌳', '#4CAF50'),
('Music', 'activity', '🎵', '#673AB7'),
('Learning', 'activity', '📚', '#3F51B5')
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- 4. MOOD ENTRIES TABLE (Connected to categories and user profiles)
-- =============================================================================
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

-- =============================================================================
-- 5. MOOD ENTRY TAGS (Many-to-many relationship between entries and tags)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mood_entry_tags (
    id BIGSERIAL PRIMARY KEY,
    mood_entry_id BIGINT REFERENCES public.mood_entries(id) ON DELETE CASCADE NOT NULL,
    mood_tag_id SMALLINT REFERENCES public.mood_tags(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(mood_entry_id, mood_tag_id)
);

-- =============================================================================
-- 6. MOOD GOALS TABLE (Connected to categories and tracking progress)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mood_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL CHECK (length(title) >= 1 AND length(title) <= 100),
    description TEXT DEFAULT '',
    target_mood_category_id SMALLINT REFERENCES public.mood_categories(id) NOT NULL,
    target_days INTEGER NOT NULL CHECK (target_days > 0),
    target_intensity_min INTEGER CHECK (target_intensity_min >= 1 AND target_intensity_min <= 10) DEFAULT 1,
    target_intensity_max INTEGER CHECK (target_intensity_max >= 1 AND target_intensity_max <= 10) DEFAULT 10,
    current_progress INTEGER DEFAULT 0 CHECK (current_progress >= 0),
    is_completed BOOLEAN DEFAULT false,
    start_date DATE,
    target_end_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT valid_intensity_range CHECK (target_intensity_min <= target_intensity_max),
    CONSTRAINT valid_date_range CHECK (target_end_date >= start_date)
);

-- =============================================================================
-- 7. GOAL PROGRESS TRACKING (Track daily progress towards goals)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.goal_progress (
    id BIGSERIAL PRIMARY KEY,
    goal_id UUID REFERENCES public.mood_goals(id) ON DELETE CASCADE NOT NULL,
    mood_entry_id BIGINT REFERENCES public.mood_entries(id) ON DELETE CASCADE NOT NULL,
    progress_date DATE NOT NULL,
    contributes_to_goal BOOLEAN DEFAULT true,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(goal_id, mood_entry_id)
);

-- =============================================================================
-- 8. PRIVATE CONVERSATIONS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.private_conversations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    participant_1_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    participant_2_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(participant_1_id, participant_2_id),
    CHECK (participant_1_id != participant_2_id)
);

-- =============================================================================
-- 9. CHAT MESSAGES TABLE (Updated to support both public and private messages)
-- =============================================================================
-- First drop the existing table if we need to modify its structure
-- Note: This will be handled differently in production - using migrations
CREATE TABLE IF NOT EXISTS public.chat_messages_new (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL CHECK (length(message) >= 1 AND length(message) <= 1000),
    reply_to_message_id BIGINT,
    conversation_id UUID REFERENCES public.private_conversations(id) ON DELETE CASCADE,
    is_edited BOOLEAN DEFAULT false,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    -- Check that private messages have a conversation_id
    CHECK ((is_private = true AND conversation_id IS NOT NULL) OR (is_private = false AND conversation_id IS NULL))
);

-- Copy existing data if the old table exists
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'chat_messages') THEN
        INSERT INTO public.chat_messages_new (id, user_id, message, reply_to_message_id, is_edited, is_private, created_at, updated_at)
        SELECT id, user_id, message, reply_to_message_id, is_edited, false, created_at, updated_at
        FROM public.chat_messages;
        
        -- Drop old table and rename new one
        DROP TABLE public.chat_messages CASCADE;
    END IF;
END $$;

-- Rename the new table
ALTER TABLE public.chat_messages_new RENAME TO chat_messages;

-- Re-add the self-reference constraint for reply_to_message_id
ALTER TABLE public.chat_messages 
ADD CONSTRAINT chat_messages_reply_to_message_id_fkey 
FOREIGN KEY (reply_to_message_id) REFERENCES public.chat_messages(id) ON DELETE SET NULL;

-- =============================================================================
-- 10. MESSAGE REACTIONS TABLE (Connected to messages and users)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT REFERENCES public.chat_messages(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    emoji TEXT NOT NULL CHECK (length(emoji) >= 1 AND length(emoji) <= 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    UNIQUE(message_id, user_id, emoji)
);

-- =============================================================================
-- 11. USER SETTINGS TABLE (Connected to user profiles)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE PRIMARY KEY,
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
    notification_enabled BOOLEAN DEFAULT true,
    daily_reminder_time TIME DEFAULT '20:00:00',
    weekly_report_enabled BOOLEAN DEFAULT true,
    mood_reminder_frequency TEXT DEFAULT 'daily' CHECK (mood_reminder_frequency IN ('none', 'daily', 'twice_daily', 'custom')),
    data_export_format TEXT DEFAULT 'json' CHECK (data_export_format IN ('json', 'csv')),
    privacy_level TEXT DEFAULT 'private' CHECK (privacy_level IN ('public', 'friends', 'private')),
    goal_notifications BOOLEAN DEFAULT true,
    streak_notifications BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL
);

-- =============================================================================
-- 12. USER STREAKS TABLE (Track mood logging streaks)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_streaks (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    streak_type TEXT NOT NULL CHECK (streak_type IN ('daily_mood', 'weekly_goal', 'monthly_consistency')),
    current_count INTEGER DEFAULT 0 CHECK (current_count >= 0),
    best_count INTEGER DEFAULT 0 CHECK (best_count >= 0),
    last_activity_date DATE,
    streak_start_date DATE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(user_id, streak_type)
);

-- =============================================================================
-- 13. MOOD INSIGHTS TABLE (Store calculated insights and patterns)
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mood_insights (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE NOT NULL,
    insight_type TEXT NOT NULL CHECK (insight_type IN ('pattern', 'trend', 'correlation', 'achievement')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    data_points JSONB,
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    is_active BOOLEAN DEFAULT true,
    generated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- =============================================================================
-- ENABLE ROW LEVEL SECURITY
-- =============================================================================
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_entry_tags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.goal_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.private_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_streaks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.mood_insights ENABLE ROW LEVEL SECURITY;

-- =============================================================================
-- SECURITY POLICIES
-- =============================================================================

-- User Profiles Policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can view other profiles for chat" ON public.user_profiles
    FOR SELECT USING (true);

-- Mood Categories (Public read-only)
CREATE POLICY "Anyone can view mood categories" ON public.mood_categories
    FOR SELECT USING (true);

-- Mood Tags (Public read-only)
CREATE POLICY "Anyone can view mood tags" ON public.mood_tags
    FOR SELECT USING (true);

-- Mood Entries Policies
CREATE POLICY "Users can view their own mood entries" ON public.mood_entries
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own mood entries" ON public.mood_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own mood entries" ON public.mood_entries
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own mood entries" ON public.mood_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Mood Entry Tags Policies
CREATE POLICY "Users can view their own mood entry tags" ON public.mood_entry_tags
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.mood_entries me 
        WHERE me.id = mood_entry_id AND me.user_id = auth.uid()
    ));
CREATE POLICY "Users can insert their own mood entry tags" ON public.mood_entry_tags
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM public.mood_entries me 
        WHERE me.id = mood_entry_id AND me.user_id = auth.uid()
    ));
CREATE POLICY "Users can delete their own mood entry tags" ON public.mood_entry_tags
    FOR DELETE USING (EXISTS (
        SELECT 1 FROM public.mood_entries me 
        WHERE me.id = mood_entry_id AND me.user_id = auth.uid()
    ));

-- Mood Goals Policies
CREATE POLICY "Users can view their own mood goals" ON public.mood_goals
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own mood goals" ON public.mood_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own mood goals" ON public.mood_goals
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own mood goals" ON public.mood_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Goal Progress Policies
CREATE POLICY "Users can view their own goal progress" ON public.goal_progress
    FOR SELECT USING (EXISTS (
        SELECT 1 FROM public.mood_goals mg 
        WHERE mg.id = goal_id AND mg.user_id = auth.uid()
    ));
CREATE POLICY "Users can insert their own goal progress" ON public.goal_progress
    FOR INSERT WITH CHECK (EXISTS (
        SELECT 1 FROM public.mood_goals mg 
        WHERE mg.id = goal_id AND mg.user_id = auth.uid()
    ));

-- Private Conversations Policies
CREATE POLICY "Users can view their own conversations" ON public.private_conversations
    FOR SELECT USING (auth.uid() = participant_1_id OR auth.uid() = participant_2_id);
CREATE POLICY "Authenticated users can create conversations" ON public.private_conversations
    FOR INSERT WITH CHECK (auth.uid() = participant_1_id OR auth.uid() = participant_2_id);

-- Chat Messages Policies (Updated for private/public messages)
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
CREATE POLICY "Users can insert private messages in their conversations" ON public.chat_messages
    FOR INSERT WITH CHECK (
        auth.uid() = user_id AND 
        is_private = true AND
        conversation_id IN (
            SELECT id FROM public.private_conversations 
            WHERE participant_1_id = auth.uid() OR participant_2_id = auth.uid()
        )
    );
CREATE POLICY "Users can update their own chat messages" ON public.chat_messages
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own chat messages" ON public.chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Message Reactions Policies
CREATE POLICY "Anyone can view message reactions" ON public.message_reactions
    FOR SELECT USING (true);
CREATE POLICY "Authenticated users can add reactions" ON public.message_reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can remove their own reactions" ON public.message_reactions
    FOR DELETE USING (auth.uid() = user_id);

-- User Settings Policies
CREATE POLICY "Users can view their own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can insert their own settings" ON public.user_settings
    FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own settings" ON public.user_settings
    FOR UPDATE USING (auth.uid() = id);

-- User Streaks Policies
CREATE POLICY "Users can view their own streaks" ON public.user_streaks
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own streaks" ON public.user_streaks
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own streaks" ON public.user_streaks
    FOR UPDATE USING (auth.uid() = user_id);

-- Mood Insights Policies
CREATE POLICY "Users can view their own insights" ON public.mood_insights
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "System can insert insights" ON public.mood_insights
    FOR INSERT WITH CHECK (true);
CREATE POLICY "System can update insights" ON public.mood_insights
    FOR UPDATE USING (true);

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================
CREATE INDEX IF NOT EXISTS mood_entries_user_id_idx ON public.mood_entries(user_id);
CREATE INDEX IF NOT EXISTS mood_entries_created_at_idx ON public.mood_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS mood_entries_category_idx ON public.mood_entries(mood_category_id);
CREATE INDEX IF NOT EXISTS mood_entries_intensity_idx ON public.mood_entries(intensity);

CREATE INDEX IF NOT EXISTS mood_entry_tags_entry_idx ON public.mood_entry_tags(mood_entry_id);
CREATE INDEX IF NOT EXISTS mood_entry_tags_tag_idx ON public.mood_entry_tags(mood_tag_id);

CREATE INDEX IF NOT EXISTS mood_goals_user_id_idx ON public.mood_goals(user_id);
CREATE INDEX IF NOT EXISTS mood_goals_category_idx ON public.mood_goals(target_mood_category_id);
CREATE INDEX IF NOT EXISTS mood_goals_active_idx ON public.mood_goals(is_completed, start_date);

CREATE INDEX IF NOT EXISTS goal_progress_goal_idx ON public.goal_progress(goal_id);
CREATE INDEX IF NOT EXISTS goal_progress_date_idx ON public.goal_progress(progress_date);

CREATE INDEX IF NOT EXISTS private_conversations_participant_1_idx ON public.private_conversations(participant_1_id);
CREATE INDEX IF NOT EXISTS private_conversations_participant_2_idx ON public.private_conversations(participant_2_id);
CREATE INDEX IF NOT EXISTS private_conversations_participants_idx ON public.private_conversations(participant_1_id, participant_2_id);

CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON public.chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS chat_messages_conversation_id_idx ON public.chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS chat_messages_private_idx ON public.chat_messages(is_private, created_at DESC);

CREATE INDEX IF NOT EXISTS user_streaks_user_id_idx ON public.user_streaks(user_id);
CREATE INDEX IF NOT EXISTS user_streaks_type_idx ON public.user_streaks(streak_type);
CREATE INDEX IF NOT EXISTS user_streaks_active_idx ON public.user_streaks(is_active, last_activity_date);

CREATE INDEX IF NOT EXISTS mood_insights_user_id_idx ON public.mood_insights(user_id);
CREATE INDEX IF NOT EXISTS mood_insights_type_idx ON public.mood_insights(insight_type);
CREATE INDEX IF NOT EXISTS mood_insights_active_idx ON public.mood_insights(is_active, generated_at);

-- =============================================================================
-- UPDATED_AT TRIGGER FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables with updated_at
CREATE TRIGGER user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER mood_entries_updated_at BEFORE UPDATE ON public.mood_entries FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER mood_goals_updated_at BEFORE UPDATE ON public.mood_goals FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER private_conversations_updated_at BEFORE UPDATE ON public.private_conversations FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER chat_messages_updated_at BEFORE UPDATE ON public.chat_messages FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER user_streaks_updated_at BEFORE UPDATE ON public.user_streaks FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- AUTOMATIC PROFILE CREATION FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    random_avatar TEXT;
    random_color TEXT;
    avatars TEXT[] := ARRAY['😊', '🌟', '🎨', '🚀', '🌈', '⭐', '🎯', '💫', '🌸', '🎪'];
    colors TEXT[] := ARRAY['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', '#00BCD4'];
BEGIN
    random_avatar := avatars[1 + floor(random() * array_length(avatars, 1))::int];
    random_color := colors[1 + floor(random() * array_length(colors, 1))::int];
    
    -- Insert user profile
    INSERT INTO public.user_profiles (id, name, avatar_emoji, color, age, gender)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
        random_avatar,
        random_color,
        CASE 
            WHEN NEW.raw_user_meta_data->>'age' IS NOT NULL 
            THEN (NEW.raw_user_meta_data->>'age')::INTEGER 
            ELSE NULL 
        END,
        NEW.raw_user_meta_data->>'gender'
    );
    
    -- Insert default user settings
    INSERT INTO public.user_settings (id) VALUES (NEW.id);
    
    -- Initialize user streaks
    INSERT INTO public.user_streaks (user_id, streak_type) VALUES 
        (NEW.id, 'daily_mood'),
        (NEW.id, 'weekly_goal'),
        (NEW.id, 'monthly_consistency');
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- GOAL PROGRESS TRACKING FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.update_goal_progress()
RETURNS TRIGGER AS $$
DECLARE
    goal_record RECORD;
    matching_goals CURSOR FOR
        SELECT g.id, g.target_mood_category_id, g.target_intensity_min, g.target_intensity_max, g.target_days
        FROM public.mood_goals g
        WHERE g.user_id = NEW.user_id 
        AND g.is_completed = false
        AND g.target_mood_category_id = NEW.mood_category_id
        AND NEW.intensity BETWEEN g.target_intensity_min AND g.target_intensity_max;
BEGIN
    -- Update goal progress for matching active goals
    FOR goal_record IN matching_goals LOOP
        INSERT INTO public.goal_progress (goal_id, mood_entry_id, progress_date, contributes_to_goal)
        VALUES (goal_record.id, NEW.id, NEW.created_at::date, true)
        ON CONFLICT (goal_id, mood_entry_id) DO NOTHING;
        
        -- Update current progress count
        UPDATE public.mood_goals 
        SET current_progress = (
            SELECT COUNT(DISTINCT me.created_at::date)
            FROM public.mood_entries me
            JOIN public.goal_progress gp ON gp.mood_entry_id = me.id
            WHERE gp.goal_id = goal_record.id
            AND gp.contributes_to_goal = true
        )
        WHERE id = goal_record.id;
        
        -- Check if goal is completed
        UPDATE public.mood_goals 
        SET is_completed = true, completed_at = CURRENT_TIMESTAMP
        WHERE id = goal_record.id 
        AND current_progress >= target_days
        AND is_completed = false;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER mood_entry_goal_progress
    AFTER INSERT ON public.mood_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.update_goal_progress();

-- =============================================================================
-- STREAK TRACKING FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.update_user_streaks()
RETURNS TRIGGER AS $$
DECLARE
    yesterday DATE := (CURRENT_TIMESTAMP::date - 1);
    today DATE := CURRENT_TIMESTAMP::date;
    had_entry_yesterday BOOLEAN;
    streak_record RECORD;
BEGIN
    -- Check if user had an entry yesterday
    SELECT EXISTS(
        SELECT 1 FROM public.mood_entries 
        WHERE user_id = NEW.user_id 
        AND created_at::date = yesterday
    ) INTO had_entry_yesterday;
    
    -- Get current streak record
    SELECT * INTO streak_record 
    FROM public.user_streaks 
    WHERE user_id = NEW.user_id AND streak_type = 'daily_mood';
    
    IF streak_record.last_activity_date = today THEN
        -- Already logged today, no change needed
        RETURN NEW;
    ELSIF streak_record.last_activity_date = yesterday OR had_entry_yesterday THEN
        -- Continue streak
        UPDATE public.user_streaks 
        SET current_count = current_count + 1,
            best_count = GREATEST(best_count, current_count + 1),
            last_activity_date = today,
            is_active = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id AND streak_type = 'daily_mood';
    ELSE
        -- Reset streak
        UPDATE public.user_streaks 
        SET current_count = 1,
            last_activity_date = today,
            streak_start_date = today,
            is_active = true,
            updated_at = CURRENT_TIMESTAMP
        WHERE user_id = NEW.user_id AND streak_type = 'daily_mood';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER mood_entry_streak_update
    AFTER INSERT ON public.mood_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_streaks();

-- =============================================================================
-- UTILITY FUNCTIONS WITH PROPER RELATIONSHIPS
-- =============================================================================

-- Get user's mood streak
CREATE OR REPLACE FUNCTION public.get_mood_streak(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    streak_count INTEGER;
BEGIN
    SELECT current_count INTO streak_count
    FROM public.user_streaks
    WHERE user_id = user_uuid AND streak_type = 'daily_mood' AND is_active = true;
    
    RETURN COALESCE(streak_count, 0);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Get comprehensive mood statistics with relationships
CREATE OR REPLACE FUNCTION public.get_mood_stats(user_uuid UUID, days_back INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    WITH mood_data AS (
        SELECT 
            me.id,
            me.intensity,
            mc.name as mood_name,
            mc.mood_score,
            me.created_at,
            array_agg(mt.name) as tags
        FROM public.mood_entries me
        JOIN public.mood_categories mc ON me.mood_category_id = mc.id
        LEFT JOIN public.mood_entry_tags met ON me.id = met.mood_entry_id
        LEFT JOIN public.mood_tags mt ON met.mood_tag_id = mt.id
        WHERE me.user_id = user_uuid
        AND me.created_at >= CURRENT_TIMESTAMP - (days_back || ' days')::INTERVAL
        GROUP BY me.id, me.intensity, mc.name, mc.mood_score, me.created_at
    )
    SELECT json_build_object(
        'total_entries', COUNT(*),
        'average_intensity', ROUND(AVG(intensity), 1),
        'average_mood_score', ROUND(AVG(mood_score), 1),
        'most_common_mood', mode() WITHIN GROUP (ORDER BY mood_name),
        'unique_moods', COUNT(DISTINCT mood_name),
        'entries_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '7 days'),
        'current_streak', public.get_mood_streak(user_uuid)
    ) INTO result
    FROM mood_data;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- =============================================================================
-- INTERCONNECTED VIEWS
-- =============================================================================

-- Comprehensive mood analytics view
CREATE OR REPLACE VIEW public.mood_analytics AS
SELECT 
    me.id,
    me.user_id,
    up.name as user_name,
    mc.name as mood_name,
    mc.emoji as mood_emoji,
    mc.mood_score,
    me.intensity,
    me.note,
    me.location,
    me.weather,
    me.created_at,
    me.created_at::date as mood_date,
    EXTRACT(DOW FROM me.created_at)::int as day_of_week,
    EXTRACT(HOUR FROM me.created_at)::int as hour_of_day,
    array_agg(DISTINCT mt.name) FILTER (WHERE mt.name IS NOT NULL) as tags,
    array_agg(DISTINCT mt.category) FILTER (WHERE mt.category IS NOT NULL) as tag_categories
FROM public.mood_entries me
JOIN public.user_profiles up ON me.user_id = up.id
JOIN public.mood_categories mc ON me.mood_category_id = mc.id
LEFT JOIN public.mood_entry_tags met ON me.id = met.mood_entry_id
LEFT JOIN public.mood_tags mt ON met.mood_tag_id = mt.id
GROUP BY me.id, me.user_id, up.name, mc.name, mc.emoji, mc.mood_score, 
         me.intensity, me.note, me.location, me.weather, me.created_at;

-- Goal progress view
CREATE OR REPLACE VIEW public.goal_progress_view AS
SELECT 
    mg.id as goal_id,
    mg.user_id,
    mg.title,
    mg.description,
    mc.name as target_mood,
    mc.emoji as target_mood_emoji,
    mg.target_days,
    mg.current_progress,
    mg.is_completed,
    mg.start_date,
    mg.target_end_date,
    ROUND((mg.current_progress::DECIMAL / mg.target_days) * 100, 1) as completion_percentage,
    CASE 
        WHEN mg.is_completed THEN 'completed'
        WHEN CURRENT_DATE > mg.target_end_date THEN 'overdue'
        WHEN mg.current_progress > 0 THEN 'in_progress'
        ELSE 'not_started'
    END as status
FROM public.mood_goals mg
JOIN public.mood_categories mc ON mg.target_mood_category_id = mc.id;

-- =============================================================================
-- REAL-TIME SETUP
-- =============================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.private_conversations;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE public.mood_entries;
ALTER PUBLICATION supabase_realtime ADD TABLE public.goal_progress;

-- =============================================================================
-- PERMISSIONS
-- =============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- =============================================================================
-- SETUP COMPLETE
-- =============================================================================
SELECT 'Interconnected Mood Tracker database schema setup completed successfully!' as status;
