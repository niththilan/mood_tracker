-- =============================================================================
-- SUPABASE SQL SCHEMA FOR MOOD TRACKER APPLICATION
-- =============================================================================
-- This schema creates all the necessary tables and setup required for the
-- Flutter mood tracker application to work with Supabase.
-- =============================================================================

-- Enable Row Level Security (RLS) for all tables
-- This ensures users can only access their own data

-- =============================================================================
-- 1. USER PROFILES TABLE
-- =============================================================================
-- Stores user profile information including name, avatar, and preferences
CREATE TABLE IF NOT EXISTS public.user_profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL CHECK (length(name) >= 2 AND length(name) <= 50),
    avatar_emoji TEXT DEFAULT '😊',
    color TEXT DEFAULT '#4CAF50',
    age INTEGER CHECK (age >= 13 AND age <= 120),
    gender TEXT CHECK (gender IN ('male', 'female', 'non-binary', 'prefer-not-to-say')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on user_profiles
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies for user_profiles
CREATE POLICY "Users can view their own profile" ON public.user_profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view other profiles for chat" ON public.user_profiles
    FOR SELECT USING (true); -- Allow viewing other profiles for chat functionality

-- Create updated_at trigger for user_profiles
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_profiles_updated_at
    BEFORE UPDATE ON public.user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 2. MOOD ENTRIES TABLE
-- =============================================================================
-- Stores all mood entries with optional intensity, tags, and notes
CREATE TABLE IF NOT EXISTS public.mood_entries (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    mood TEXT NOT NULL,
    note TEXT DEFAULT '',
    intensity INTEGER CHECK (intensity >= 1 AND intensity <= 10),
    tags TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on mood_entries
ALTER TABLE public.mood_entries ENABLE ROW LEVEL SECURITY;

-- Create policies for mood_entries
CREATE POLICY "Users can view their own mood entries" ON public.mood_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood entries" ON public.mood_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood entries" ON public.mood_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own mood entries" ON public.mood_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger for mood_entries
CREATE TRIGGER mood_entries_updated_at
    BEFORE UPDATE ON public.mood_entries
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS mood_entries_user_id_idx ON public.mood_entries(user_id);
CREATE INDEX IF NOT EXISTS mood_entries_created_at_idx ON public.mood_entries(created_at DESC);
CREATE INDEX IF NOT EXISTS mood_entries_mood_idx ON public.mood_entries(mood);

-- =============================================================================
-- 3. MOOD GOALS TABLE
-- =============================================================================
-- Stores user-defined mood goals and tracks their progress
CREATE TABLE IF NOT EXISTS public.mood_goals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    title TEXT NOT NULL CHECK (length(title) >= 1 AND length(title) <= 100),
    description TEXT DEFAULT '',
    target_days INTEGER NOT NULL CHECK (target_days > 0),
    target_mood TEXT NOT NULL,
    current_progress INTEGER DEFAULT 0 CHECK (current_progress >= 0),
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    completed_at TIMESTAMP WITH TIME ZONE
);

-- Enable RLS on mood_goals
ALTER TABLE public.mood_goals ENABLE ROW LEVEL SECURITY;

-- Create policies for mood_goals
CREATE POLICY "Users can view their own mood goals" ON public.mood_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood goals" ON public.mood_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood goals" ON public.mood_goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own mood goals" ON public.mood_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger for mood_goals
CREATE TRIGGER mood_goals_updated_at
    BEFORE UPDATE ON public.mood_goals
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for mood_goals
CREATE INDEX IF NOT EXISTS mood_goals_user_id_idx ON public.mood_goals(user_id);
CREATE INDEX IF NOT EXISTS mood_goals_created_at_idx ON public.mood_goals(created_at DESC);
CREATE INDEX IF NOT EXISTS mood_goals_is_completed_idx ON public.mood_goals(is_completed);

-- =============================================================================
-- 4. CHAT MESSAGES TABLE
-- =============================================================================
-- Stores chat messages for the community chat feature
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    message TEXT NOT NULL CHECK (length(message) >= 1 AND length(message) <= 1000),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on chat_messages
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Create policies for chat_messages
CREATE POLICY "Anyone can view chat messages" ON public.chat_messages
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can insert chat messages" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own chat messages" ON public.chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own chat messages" ON public.chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Create updated_at trigger for chat_messages
CREATE TRIGGER chat_messages_updated_at
    BEFORE UPDATE ON public.chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create indexes for chat_messages
CREATE INDEX IF NOT EXISTS chat_messages_user_id_idx ON public.chat_messages(user_id);
CREATE INDEX IF NOT EXISTS chat_messages_created_at_idx ON public.chat_messages(created_at DESC);

-- =============================================================================
-- 5. MESSAGE REACTIONS TABLE
-- =============================================================================
-- Stores reactions to chat messages (emoji reactions)
CREATE TABLE IF NOT EXISTS public.message_reactions (
    id BIGSERIAL PRIMARY KEY,
    message_id BIGINT REFERENCES public.chat_messages(id) ON DELETE CASCADE NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    emoji TEXT NOT NULL CHECK (length(emoji) >= 1 AND length(emoji) <= 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(message_id, user_id, emoji)
);

-- Enable RLS on message_reactions
ALTER TABLE public.message_reactions ENABLE ROW LEVEL SECURITY;

-- Create policies for message_reactions
CREATE POLICY "Anyone can view message reactions" ON public.message_reactions
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can add reactions" ON public.message_reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their own reactions" ON public.message_reactions
    FOR DELETE USING (auth.uid() = user_id);

-- Create indexes for message_reactions
CREATE INDEX IF NOT EXISTS message_reactions_message_id_idx ON public.message_reactions(message_id);
CREATE INDEX IF NOT EXISTS message_reactions_user_id_idx ON public.message_reactions(user_id);
CREATE INDEX IF NOT EXISTS message_reactions_emoji_idx ON public.message_reactions(emoji);

-- =============================================================================
-- 6. USER SETTINGS TABLE (OPTIONAL - FOR FUTURE FEATURES)
-- =============================================================================
-- Stores user preferences and settings
CREATE TABLE IF NOT EXISTS public.user_settings (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    theme_preference TEXT DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
    notification_enabled BOOLEAN DEFAULT true,
    daily_reminder_time TIME,
    weekly_report_enabled BOOLEAN DEFAULT true,
    data_export_format TEXT DEFAULT 'json' CHECK (data_export_format IN ('json', 'csv')),
    privacy_level TEXT DEFAULT 'private' CHECK (privacy_level IN ('public', 'friends', 'private')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on user_settings
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- Create policies for user_settings
CREATE POLICY "Users can view their own settings" ON public.user_settings
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own settings" ON public.user_settings
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own settings" ON public.user_settings
    FOR UPDATE USING (auth.uid() = id);

-- Create updated_at trigger for user_settings
CREATE TRIGGER user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- =============================================================================
-- 7. MOOD ANALYTICS VIEW (OPTIONAL - FOR ENHANCED ANALYTICS)
-- =============================================================================
-- Create a view for easier mood analytics queries
CREATE OR REPLACE VIEW public.mood_analytics AS
SELECT 
    me.user_id,
    me.mood,
    me.intensity,
    me.created_at,
    DATE(me.created_at) as mood_date,
    EXTRACT(DOW FROM me.created_at) as day_of_week,
    EXTRACT(HOUR FROM me.created_at) as hour_of_day,
    up.name as user_name
FROM public.mood_entries me
LEFT JOIN public.user_profiles up ON me.user_id = up.id;

-- =============================================================================
-- 8. FUNCTIONS FOR AUTOMATIC PROFILE CREATION
-- =============================================================================
-- Function to automatically create a user profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    avatars TEXT[] := ARRAY['😊', '🌟', '🎨', '🚀', '🌈', '⭐', '🎯', '💫', '🌸', '🎪', '🌺', '🎭', '🔥', '✨', '🦋', '🌻', '🎈', '🦄', '🌙', '☀️'];
    colors TEXT[] := ARRAY['#4CAF50', '#2196F3', '#FF9800', '#9C27B0', '#F44336', '#00BCD4', '#795548', '#607D8B', '#E91E63', '#3F51B5', '#009688', '#FF5722', '#8BC34A', '#FFC107', '#673AB7'];
    random_avatar TEXT;
    random_color TEXT;
BEGIN
    -- Select random avatar and color
    random_avatar := avatars[floor(random() * array_length(avatars, 1)) + 1];
    random_color := colors[floor(random() * array_length(colors, 1)) + 1];
    
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
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for new user signup
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 9. HELPFUL FUNCTIONS FOR MOOD TRACKING
-- =============================================================================

-- Function to get mood streak for a user
CREATE OR REPLACE FUNCTION public.get_mood_streak(user_uuid UUID)
RETURNS INTEGER AS $$
DECLARE
    streak INTEGER := 0;
    current_date DATE := CURRENT_DATE;
    check_date DATE;
BEGIN
    -- Check if user logged mood today
    IF NOT EXISTS (
        SELECT 1 FROM public.mood_entries 
        WHERE user_id = user_uuid 
        AND DATE(created_at) = current_date
    ) THEN
        current_date := current_date - INTERVAL '1 day';
    END IF;
    
    -- Count consecutive days
    check_date := current_date;
    WHILE EXISTS (
        SELECT 1 FROM public.mood_entries 
        WHERE user_id = user_uuid 
        AND DATE(created_at) = check_date
    ) LOOP
        streak := streak + 1;
        check_date := check_date - INTERVAL '1 day';
    END LOOP;
    
    RETURN streak;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get mood statistics for a user
CREATE OR REPLACE FUNCTION public.get_mood_stats(user_uuid UUID, days_back INTEGER DEFAULT 30)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'total_entries', COUNT(*),
        'average_intensity', ROUND(AVG(intensity), 1),
        'most_common_mood', mode() WITHIN GROUP (ORDER BY mood),
        'unique_moods', COUNT(DISTINCT mood),
        'entries_this_week', COUNT(*) FILTER (WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'),
        'current_streak', public.get_mood_streak(user_uuid)
    ) INTO result
    FROM public.mood_entries
    WHERE user_id = user_uuid
    AND created_at >= CURRENT_DATE - INTERVAL '1 day' * days_back;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================================================
-- 10. REAL-TIME SUBSCRIPTIONS SETUP
-- =============================================================================
-- Enable real-time for chat messages
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE public.message_reactions;
ALTER PUBLICATION supabase_realtime ADD TABLE public.user_profiles;

-- =============================================================================
-- 11. SAMPLE DATA (OPTIONAL - FOR TESTING)
-- =============================================================================
-- Uncomment the following section if you want to insert sample data for testing

/*
-- Sample mood entries (replace with actual user IDs)
INSERT INTO public.mood_entries (user_id, mood, note, intensity, tags) VALUES
    ('00000000-0000-0000-0000-000000000000', '😊 Happy', 'Had a great day at work!', 8, 'work,achievement'),
    ('00000000-0000-0000-0000-000000000000', '😌 Calm', 'Relaxing evening with family', 7, 'family,relaxation'),
    ('00000000-0000-0000-0000-000000000000', '😔 Sad', 'Missing old friends', 4, 'social,nostalgia');

-- Sample goals
INSERT INTO public.mood_goals (user_id, title, description, target_days, target_mood) VALUES
    ('00000000-0000-0000-0000-000000000000', 'Stay Happy for a Week', 'Try to maintain a positive mood for 7 consecutive days', 7, '😊 Happy'),
    ('00000000-0000-0000-0000-000000000000', 'Reduce Anxiety', 'Work on managing anxiety through mindfulness', 14, '😌 Calm');
*/

-- =============================================================================
-- SCHEMA SETUP COMPLETE
-- =============================================================================
-- Your mood tracker application should now work with this database schema.
-- Make sure to:
-- 1. Run this SQL in your Supabase SQL editor
-- 2. Verify that all tables were created successfully
-- 3. Test the authentication flow
-- 4. Verify that RLS policies are working correctly
-- =============================================================================

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO anon, authenticated;

-- Final message
SELECT 'Mood Tracker database schema setup completed successfully!' as status;
