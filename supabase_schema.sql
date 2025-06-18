-- =====================================================
-- Mood Tracker Application - Complete Database Schema
-- For Supabase PostgreSQL Database
-- Created: June 18, 2025
-- =====================================================

-- Enable Row Level Security
ALTER DATABASE postgres SET "app.jwt_secret" TO 'your-jwt-secret';

-- Create extension for UUID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- TABLE DEFINITIONS
-- =====================================================

-- 1. User Profiles Table
-- Stores user profile information including avatar, colors, and preferences
CREATE TABLE user_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    age INTEGER,
    gender VARCHAR(20),
    avatar_emoji VARCHAR(10) NOT NULL DEFAULT '😊',
    color VARCHAR(7) NOT NULL DEFAULT '#4CAF50',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Mood Entries Table
-- Stores individual mood entries with notes
-- NOTE: user_id will be automatically populated by RLS/triggers, not required in INSERT
CREATE TABLE mood_entries (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    mood VARCHAR(50) NOT NULL,
    note TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Mood Goals Table
-- Stores user-defined mood goals and tracks progress
-- NOTE: user_id will be automatically populated by RLS/triggers, not required in INSERT
CREATE TABLE mood_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    description TEXT DEFAULT '',
    target_days INTEGER NOT NULL,
    target_mood VARCHAR(50) NOT NULL,
    current_progress INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

-- 4. Chat Messages Table
-- Stores chat messages for community features
-- NOTE: user_id will be automatically populated by RLS/triggers, not required in INSERT
CREATE TABLE chat_messages (
    id SERIAL PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Message Reactions Table
-- Stores emoji reactions to chat messages
CREATE TABLE message_reactions (
    id SERIAL PRIMARY KEY,
    message_id INTEGER NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    emoji VARCHAR(10) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(message_id, user_id, emoji)
);

-- =====================================================
-- INDEXES FOR PERFORMANCE
-- =====================================================

-- Mood Entries Indexes
CREATE INDEX idx_mood_entries_user_id ON mood_entries(user_id);
CREATE INDEX idx_mood_entries_created_at ON mood_entries(created_at);
CREATE INDEX idx_mood_entries_mood ON mood_entries(mood);
CREATE INDEX idx_mood_entries_user_date ON mood_entries(user_id, created_at);

-- Mood Goals Indexes
CREATE INDEX idx_mood_goals_user_id ON mood_goals(user_id);
CREATE INDEX idx_mood_goals_is_completed ON mood_goals(is_completed);
CREATE INDEX idx_mood_goals_target_mood ON mood_goals(target_mood);

-- Chat Messages Indexes
CREATE INDEX idx_chat_messages_user_id ON chat_messages(user_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at);

-- Message Reactions Indexes
CREATE INDEX idx_message_reactions_message_id ON message_reactions(message_id);
CREATE INDEX idx_message_reactions_user_id ON message_reactions(user_id);

-- =====================================================
-- ROW LEVEL SECURITY (RLS) SETUP
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE mood_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE message_reactions ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- RLS POLICIES
-- =====================================================

-- User Profiles Policies
CREATE POLICY "Users can view all profiles" ON user_profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON user_profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON user_profiles
    FOR UPDATE USING (auth.uid() = id);

-- Mood Entries Policies
CREATE POLICY "Users can view their own mood entries" ON mood_entries
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own mood entries" ON mood_entries
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own mood entries" ON mood_entries
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own mood entries" ON mood_entries
    FOR DELETE USING (auth.uid() = user_id);

-- Mood Goals Policies
CREATE POLICY "Users can view their own goals" ON mood_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own goals" ON mood_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own goals" ON mood_goals
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own goals" ON mood_goals
    FOR DELETE USING (auth.uid() = user_id);

-- Chat Messages Policies
CREATE POLICY "Users can view all chat messages" ON chat_messages
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Message Reactions Policies
CREATE POLICY "Users can view all reactions" ON message_reactions
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own reactions" ON message_reactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own reactions" ON message_reactions
    FOR DELETE USING (auth.uid() = user_id);

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger for user_profiles updated_at
CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to update goal progress based on mood entries
CREATE OR REPLACE FUNCTION update_goal_progress()
RETURNS TRIGGER AS $$
DECLARE
    goal_record RECORD;
BEGIN
    -- Update progress for all active goals of the user
    FOR goal_record IN 
        SELECT * FROM mood_goals 
        WHERE user_id = NEW.user_id 
        AND is_completed = FALSE
        AND target_mood = NEW.mood
    LOOP
        -- Count mood entries for this goal since creation
        UPDATE mood_goals 
        SET current_progress = (
            SELECT COUNT(*) 
            FROM mood_entries 
            WHERE user_id = goal_record.user_id 
            AND mood = goal_record.target_mood
            AND created_at >= goal_record.created_at
        ),
        is_completed = (
            SELECT COUNT(*) 
            FROM mood_entries 
            WHERE user_id = goal_record.user_id 
            AND mood = goal_record.target_mood
            AND created_at >= goal_record.created_at
        ) >= goal_record.target_days,
        completed_at = CASE 
            WHEN (
                SELECT COUNT(*) 
                FROM mood_entries 
                WHERE user_id = goal_record.user_id 
                AND mood = goal_record.target_mood
                AND created_at >= goal_record.created_at
            ) >= goal_record.target_days THEN NOW()
            ELSE NULL
        END
        WHERE id = goal_record.id;
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically set user_id for mood entries
CREATE OR REPLACE FUNCTION set_user_id_mood_entries()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id = auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically set user_id for mood goals
CREATE OR REPLACE FUNCTION set_user_id_mood_goals()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id = auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to automatically set user_id for chat messages
CREATE OR REPLACE FUNCTION set_user_id_chat_messages()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.user_id IS NULL THEN
        NEW.user_id = auth.uid();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically set user_id for mood entries
CREATE TRIGGER set_user_id_mood_entries_trigger
    BEFORE INSERT ON mood_entries
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id_mood_entries();

-- Trigger to automatically set user_id for mood goals
CREATE TRIGGER set_user_id_mood_goals_trigger
    BEFORE INSERT ON mood_goals
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id_mood_goals();

-- Trigger to automatically set user_id for chat messages
CREATE TRIGGER set_user_id_chat_messages_trigger
    BEFORE INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION set_user_id_chat_messages();

-- Trigger to update goal progress when mood entry is inserted
CREATE TRIGGER update_mood_goal_progress
    AFTER INSERT ON mood_entries
    FOR EACH ROW
    EXECUTE FUNCTION update_goal_progress();

-- =====================================================
-- REAL-TIME SUBSCRIPTIONS
-- =====================================================

-- Enable real-time for chat messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- Enable real-time for message reactions
ALTER PUBLICATION supabase_realtime ADD TABLE message_reactions;

-- Enable real-time for mood entries (optional - for live analytics)
ALTER PUBLICATION supabase_realtime ADD TABLE mood_entries;

-- =====================================================
-- ANALYTICS VIEWS
-- =====================================================

-- View for mood statistics by day
CREATE VIEW mood_stats AS
SELECT 
    user_id,
    mood,
    COUNT(*) as count,
    DATE_TRUNC('day', created_at) as date
FROM mood_entries
GROUP BY user_id, mood, DATE_TRUNC('day', created_at)
ORDER BY date DESC;

-- View for user activity summary
CREATE VIEW user_activity_summary AS
SELECT 
    u.id as user_id,
    u.name,
    u.avatar_emoji,
    u.color,
    COUNT(me.id) as total_mood_entries,
    COUNT(DISTINCT DATE_TRUNC('day', me.created_at)) as active_days,
    MAX(me.created_at) as last_entry_date,
    COUNT(mg.id) as total_goals,
    COUNT(CASE WHEN mg.is_completed THEN 1 END) as completed_goals
FROM user_profiles u
LEFT JOIN mood_entries me ON u.id = me.user_id
LEFT JOIN mood_goals mg ON u.id = mg.user_id
GROUP BY u.id, u.name, u.avatar_emoji, u.color;

-- View for weekly mood trends
CREATE VIEW weekly_mood_trends AS
SELECT 
    user_id,
    DATE_TRUNC('week', created_at) as week_start,
    mood,
    COUNT(*) as mood_count,
    AVG(CASE 
        WHEN mood LIKE '%Happy%' OR mood LIKE '%Excited%' THEN 5
        WHEN mood LIKE '%Calm%' THEN 4
        WHEN mood LIKE '%Neutral%' THEN 3
        WHEN mood LIKE '%Tired%' THEN 2
        WHEN mood LIKE '%Sad%' OR mood LIKE '%Angry%' OR mood LIKE '%Anxious%' THEN 1
        ELSE 3
    END) as avg_mood_score
FROM mood_entries
GROUP BY user_id, DATE_TRUNC('week', created_at), mood
ORDER BY week_start DESC;

-- =====================================================
-- STORAGE BUCKET SETUP (Optional - for future features)
-- =====================================================

-- Create storage bucket for user avatars (if you plan to add image uploads)
-- Run this in Supabase dashboard SQL editor after creating the bucket
/*
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- Policy for avatar uploads
CREATE POLICY "Users can upload their own avatar" ON storage.objects
    FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can view all avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');
*/

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Sample mood options that match your Flutter app
/*
-- These would be inserted after user registration in your app
INSERT INTO mood_entries (user_id, mood, note, created_at) VALUES
('00000000-0000-0000-0000-000000000001', '😊 Happy', 'Had a great day at work!', NOW() - INTERVAL '1 day'),
('00000000-0000-0000-0000-000000000001', '😄 Excited', 'Looking forward to the weekend', NOW() - INTERVAL '2 days'),
('00000000-0000-0000-0000-000000000001', '😌 Calm', 'Peaceful evening with family', NOW() - INTERVAL '3 days');
*/

-- =====================================================
-- CRITICAL FIXES FOR FLUTTER APP COMPATIBILITY
-- =====================================================

/*
IMPORTANT: Your Flutter app has some inconsistencies that need to be addressed:

1. MOOD ENTRIES INSERT ISSUE:
   Your app sends: { 'mood': '😊 Happy', 'note': 'text', 'created_at': 'timestamp' }
   But doesn't include user_id. The triggers above automatically add auth.uid().

2. CHAT MESSAGES INSERT ISSUE:
   Your app sends: { 'user_id': user.id, 'message': 'text', 'created_at': 'timestamp' }
   This is correctly handled.

3. GOALS INSERT ISSUE:
   Your app sends: { 'title': 'title', 'description': 'desc', 'target_days': 7, 'target_mood': 'Happy' }
   But doesn't include user_id. The triggers above automatically add auth.uid().

4. USER PROFILES:
   The schema correctly handles all user profile operations.

ALTERNATIVE SOLUTION (if triggers don't work):
If you prefer to modify your Flutter code instead of using triggers, change these:

In main.dart (addMoodEntry function), add:
final user = supabase.auth.currentUser;
final newEntry = {
  'user_id': user?.id,  // Add this line
  'mood': '$selectedMoodEmoji $selectedMood',
  'note': noteController.text,
  'created_at': DateTime.now().toIso8601String(),
};

In goals_page.dart (_createGoal function), add:
final user = supabase.auth.currentUser;
await supabase.from('mood_goals').insert({
  'user_id': user?.id,  // Add this line
  'title': title,
  'description': description,
  'target_days': targetDays,
  'target_mood': targetMood,
});
*/

-- =====================================================
-- SETUP INSTRUCTIONS
-- =====================================================

/*
SETUP INSTRUCTIONS FOR SUPABASE:

1. Copy this entire SQL file content
2. Go to your Supabase project dashboard
3. Navigate to SQL Editor
4. Paste and run this script
5. Verify all tables are created in the Table Editor
6. Configure your Flutter app with:
   - Supabase URL
   - Supabase Anonymous Key
   - Enable email authentication in Auth settings

IMPORTANT NOTES:
- Replace 'your-jwt-secret' with your actual JWT secret
- Test RLS policies thoroughly before production
- Consider adding more indexes based on your query patterns
- Monitor performance and adjust as needed
- Set up proper backup strategies for production

SECURITY CHECKLIST:
✓ RLS enabled on all tables
✓ Policies restrict access to user's own data
✓ Foreign key constraints maintain data integrity
✓ Unique constraints prevent duplicate reactions
✓ Indexes optimize query performance
*/
