-- =============================================================================
-- SUPABASE SQL SCHEMA FOR MOOD TRACKER APPLICATION - CORRECTED VERSION
-- =============================================================================
-- This schema creates all the necessary tables and setup required for the
-- Flutter mood tracker application to work with Supabase.
-- =============================================================================

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- 1. USER PROFILES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 2 AND length(name) <= 50),
    avatar_emoji TEXT DEFAULT '😊',
    color TEXT DEFAULT '#4CAF50',
    age INTEGER CHECK (age >= 13 AND age <= 120),
    gender TEXT CHECK (gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view other profiles for chat" ON public.user_profiles
    FOR SELECT USING (true);

-- =============================================================================
-- 2. MOOD ENTRIES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mood_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    mood TEXT NOT NULL,
    note TEXT DEFAULT '',
    intensity INTEGER CHECK (intensity >= 1 AND intensity <= 10),
    tags TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.mood_entries ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own mood entries" ON public.mood_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood entries" ON public.mood_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood entries" ON public.mood_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own mood entries" ON public.mood_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS mood_entries_user_id_idx ON public.mood_entries(user_id);
CREATE INDEX IF NOT EXISTS mood_entries_created_at_idx ON public.mood_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS mood_entries_mood_idx ON public.mood_entries(mood);

-- =============================================================================
-- 3. MOOD GOALS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.mood_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL CHECK (length(title) >= 1 AND length(title) <= 100),
    description TEXT DEFAULT '',
    target_days INTEGER NOT NULL CHECK (target_days > 0),
    target_mood TEXT NOT NULL,
    current_progress INTEGER DEFAULT 0 CHECK (current_progress >= 0),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS
ALTER TABLE public.mood_goals ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own mood goals" ON public.mood_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood goals" ON public.mood_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood goals" ON public.mood_goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own mood goals" ON public.mood_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS mood_goals_user_id_idx ON public.mood_goals(user_id);
CREATE INDEX IF NOT EXISTS mood_goals_created_at_idx ON public.mood_goals(created_at DESC);

-- =============================================================================
-- 4. CHAT MESSAGES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL CHECK (length(message) >= 1 AND length(message) <= 1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view chat messages" ON public.chat_messages
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert chat messages" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chat messages" ON public.chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chat messages" ON public.chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON public.chat_messages(created_at DESC);

-- =============================================================================
-- 5. MESSAGE REACTIONS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT REFERENCES public.chat_messages(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    emoji TEXT NOT NULL CHECK (length(emoji) >= 1 AND length(emoji) <= 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(message_id, user_id, emoji)
);

-- Enable RLS
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view message reactions" ON public.message_reactions
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can add reactions" ON public.message_reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own reactions" ON public.message_reactions
    FOR DELETE USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS message_reactions_message_id_idx ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS message_reactions_user_id_idx ON public.message_reactions(user_id);

-- =============================================================================
-- 6. USER SETTINGS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
    notification_enabled BOOLEAN DEFAULT true,
    daily_reminder_time TIME,
    weekly_report_enabled BOOLEAN DEFAULT true,
    data_export_format TEXT DEFAULT 'json' CHECK (data_export_format IN ('json', 'csv')),
    privacy_level TEXT DEFAULT 'private' CHECK (privacy_level IN ('public', 'friends', 'private')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Enable RLS
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own settings" ON public.user_settings
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own settings" ON public.user_settings
    FOR UPDATE USING (auth.uid() = id);

-- =============================================================================
-- 7. UPDATED_AT TRIGGER FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply triggers to all tables
CREATE TRIGGER user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER mood_entries_updated_at
    BEFORE UPDATE ON public.mood_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER mood_goals_updated_at
    BEFORE UPDATE ON public.mood_goals
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER chat_messages_updated_at
    BEFORE UPDATE ON public.chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 8. AUTOMATIC PROFILE CREATION FUNCTION
-- =============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    random_avatar TEXT;
    random_color TEXT;
    avatars TEXT[] := ARRAY['😊', '🌟', '🎨', '🚀', '🌈', '⭐', '🎯', '💫', '🌸', '🎪'];
    colors TEXT[] := ARRAY['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', '#00BCD4'];
BEGIN
    -- Select random avatar and color
    random_avatar := avatars[1 + floor(random() * array_length(avatars, 1))::int];
    random_color := colors[1 + floor(random() * array_length(colors, 1))::int];
    
    -- Insert user profile
    INSERT INTO public.user_profiles (id, name, avatar_emoji, color)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'name', 'User'),
        random_avatar,
        random_color
    );
    
    -- Insert default user settings
    INSERT INTO public.user_settings (id)
    VALUES (NEW.id);
    
    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    -- If there's an error, still return NEW to allow user creation
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 9. UTILITY FUNCTIONS
-- =============================================================================

-- Simple mood streak function
CREATE OR REPLACE FUNCTION public.get_mood_streak(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    streak INTEGER := 0;
    check_date DATE;
    has_entry BOOLEAN;
BEGIN
    check_date := CURRENT_DATE;
    
    -- Check if user has entry today, if not start from yesterday
    SELECT EXISTS(
        SELECT 1 FROM public.mood_entries 
        WHERE user_id = user_uuid 
        AND date(created_at) = check_date
    ) INTO has_entry;
    
    IF NOT has_entry THEN
        check_date := check_date - 1;
    END IF;
    
    -- Count consecutive days with entries
    LOOP
        SELECT EXISTS(
            SELECT 1 FROM public.mood_entries 
            WHERE user_id = user_uuid 
            AND date(created_at) = check_date
        ) INTO has_entry;
        
        IF has_entry THEN
            streak := streak + 1;
            check_date := check_date - 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;
    
    RETURN streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Mood statistics function
CREATE OR REPLACE FUNCTION public.get_mood_stats(user_uuid UUID, days_back INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
    result JSON;
    cutoff_date TIMESTAMP WITH TIME ZONE;
BEGIN
    cutoff_date := NOW() - (days_back || ' days')::INTERVAL;
    
    SELECT json_build_object(
        'total_entries', COUNT(*),
        'average_intensity', ROUND(AVG(COALESCE(intensity, 5)), 1),
        'unique_moods', COUNT(DISTINCT mood),
        'entries_this_week', COUNT(*) FILTER (WHERE created_at >= NOW() - INTERVAL '7 days'),
        'current_streak', public.get_mood_streak(user_uuid)
    ) INTO result
    FROM public.mood_entries
    WHERE user_id = user_uuid
    AND created_at >= cutoff_date;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 10. ANALYTICS VIEW
-- =============================================================================
CREATE OR REPLACE VIEW public.mood_analytics AS
SELECT 
    me.user_id,
    me.mood,
    me.intensity,
    me.created_at,
    date(me.created_at) as mood_date,
    EXTRACT(DOW FROM me.created_at)::int as day_of_week,
    EXTRACT(HOUR FROM me.created_at)::int as hour_of_day,
    up.name as user_name
FROM public.mood_entries me
LEFT JOIN public.user_profiles up ON me.user_id = up.id;

-- =============================================================================
-- 11. REAL-TIME SETUP
-- =============================================================================
-- Enable realtime for tables that need it
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;

-- =============================================================================
-- 12. PERMISSIONS
-- =============================================================================
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- =============================================================================
-- SETUP COMPLETE
-- =============================================================================
SELECT 'Mood Tracker database schema setup completed successfully!' as status;
