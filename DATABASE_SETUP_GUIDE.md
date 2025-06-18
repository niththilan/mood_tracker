# Supabase Database Schema Setup Guide

## Overview

This document provides the complete SQL schema and setup instructions for the Flutter mood tracker application to work with Supabase. The schema includes all necessary tables, security policies, and functions required for the app's functionality.

## Tables Created

### 1. `user_profiles`
Stores user profile information including personal details and customization preferences.

**Columns:**
- `id` (UUID) - Primary key, references auth.users(id)
- `name` (TEXT) - User's display name (2-50 characters)
- `avatar_emoji` (TEXT) - Selected emoji avatar
- `color` (TEXT) - Profile color in hex format
- `age` (INTEGER) - User's age (13-120, optional)
- `gender` (TEXT) - User's gender (optional)
- `created_at` (TIMESTAMP) - Profile creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Features:**
- Automatic profile creation on user signup
- Random avatar and color assignment
- Age and gender validation
- Row Level Security (RLS) enabled

### 2. `mood_entries`
Stores all mood entries with detailed information about user's emotional state.

**Columns:**
- `id` (BIGSERIAL) - Primary key
- `user_id` (UUID) - References auth.users(id)
- `mood` (TEXT) - Mood with emoji (e.g., "😊 Happy")
- `note` (TEXT) - Optional note about the mood
- `intensity` (INTEGER) - Mood intensity level (1-10, optional)
- `tags` (TEXT) - Comma-separated tags (optional)
- `created_at` (TIMESTAMP) - Entry creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Features:**
- User can only access their own entries
- Indexed for performance (user_id, created_at, mood)
- Support for intensity levels and tags

### 3. `mood_goals`
Stores user-defined mood goals and tracks progress towards achieving them.

**Columns:**
- `id` (UUID) - Primary key
- `user_id` (UUID) - References auth.users(id)
- `title` (TEXT) - Goal title (1-100 characters)
- `description` (TEXT) - Optional goal description
- `target_days` (INTEGER) - Number of days to achieve the goal
- `target_mood` (TEXT) - Target mood to achieve
- `current_progress` (INTEGER) - Current progress count
- `is_completed` (BOOLEAN) - Whether goal is completed
- `created_at` (TIMESTAMP) - Goal creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp
- `completed_at` (TIMESTAMP) - Goal completion timestamp (optional)

**Features:**
- Progress tracking functionality
- Completion status management
- User-specific goal isolation

### 4. `chat_messages`
Stores community chat messages for the social features.

**Columns:**
- `id` (BIGSERIAL) - Primary key
- `user_id` (UUID) - References auth.users(id)
- `message` (TEXT) - Chat message content (1-1000 characters)
- `created_at` (TIMESTAMP) - Message creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Features:**
- Public read access for all authenticated users
- Users can only edit/delete their own messages
- Real-time subscriptions enabled

### 5. `message_reactions`
Stores emoji reactions to chat messages.

**Columns:**
- `id` (BIGSERIAL) - Primary key
- `message_id` (BIGINT) - References chat_messages(id)
- `user_id` (UUID) - References auth.users(id)
- `emoji` (TEXT) - Reaction emoji (1-10 characters)
- `created_at` (TIMESTAMP) - Reaction creation timestamp

**Features:**
- Unique constraint (one reaction per user per message per emoji)
- Public read access
- Users can only manage their own reactions

### 6. `user_settings` (Optional)
Stores user preferences and application settings.

**Columns:**
- `id` (UUID) - Primary key, references auth.users(id)
- `theme_preference` (TEXT) - Theme setting (light/dark/system)
- `notification_enabled` (BOOLEAN) - Notification preferences
- `daily_reminder_time` (TIME) - Daily reminder time
- `weekly_report_enabled` (BOOLEAN) - Weekly report setting
- `data_export_format` (TEXT) - Export format preference
- `privacy_level` (TEXT) - Privacy setting
- `created_at` (TIMESTAMP) - Settings creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

**Features:**
- Default settings applied automatically
- User-specific privacy controls
- Extensible for future features

## Security Features

### Row Level Security (RLS)
All tables have RLS enabled with appropriate policies:

- **user_profiles**: Users can view their own profile and see others for chat
- **mood_entries**: Users can only access their own mood data
- **mood_goals**: Users can only access their own goals
- **chat_messages**: Public read, users edit own messages
- **message_reactions**: Public read, users manage own reactions
- **user_settings**: Users can only access their own settings

### Data Validation
- Age validation (13-120 years)
- Gender validation (predefined options)
- Text length constraints
- Intensity level validation (1-10)
- Message length limits

## Automatic Features

### Profile Creation
When a new user signs up, the system automatically:
1. Creates a user profile with provided name (or default "User")
2. Assigns a random avatar emoji from curated list
3. Assigns a random color from curated palette
4. Creates default user settings

### Timestamps
All tables automatically manage:
- `created_at` timestamps on insert
- `updated_at` timestamps on update

### Real-time Subscriptions
Real-time functionality is enabled for:
- Chat messages
- Message reactions
- User profiles

## Utility Functions

### `get_mood_streak(user_uuid UUID)`
Returns the current mood logging streak for a user.

### `get_mood_stats(user_uuid UUID, days_back INTEGER)`
Returns comprehensive mood statistics including:
- Total entries
- Average intensity
- Most common mood
- Unique moods count
- Entries this week
- Current streak

### `mood_analytics` View
Provides enhanced analytics data combining mood entries with user profiles.

## Setup Instructions

### 1. Create Database Schema
1. Open your Supabase project dashboard
2. Go to the SQL Editor
3. Copy and paste the entire `supabase_schema.sql` file
4. Execute the SQL script
5. Verify all tables were created successfully

### 2. Verify Setup
1. Check that all tables exist in the Table Editor
2. Verify that RLS is enabled on all tables
3. Test user registration flow
4. Verify automatic profile creation

### 3. Configure Flutter App
1. Ensure your Supabase URL and anon key are correct in `main.dart`
2. Test authentication flow
3. Test mood entry creation
4. Test chat functionality

## Testing the Schema

### 1. User Registration Test
```sql
-- This should automatically create a profile
-- Test through your Flutter app's signup process
```

### 2. Mood Entry Test
```sql
-- Insert a test mood entry (replace with actual user ID)
INSERT INTO public.mood_entries (user_id, mood, note, intensity, tags) 
VALUES ('your-user-id', '😊 Happy', 'Test mood entry', 8, 'test,demo');
```

### 3. Chat Message Test
```sql
-- Insert a test chat message (replace with actual user ID)
INSERT INTO public.chat_messages (user_id, message) 
VALUES ('your-user-id', 'Hello, this is a test message!');
```

### 4. Goal Creation Test
```sql
-- Insert a test goal (replace with actual user ID)
INSERT INTO public.mood_goals (user_id, title, description, target_days, target_mood) 
VALUES ('your-user-id', 'Test Goal', 'This is a test goal', 7, '😊 Happy');
```

## Performance Considerations

### Indexes Created
- `mood_entries_user_id_idx` - Fast user mood lookups
- `mood_entries_created_at_idx` - Fast date-based queries
- `mood_entries_mood_idx` - Fast mood-based filtering
- `mood_goals_user_id_idx` - Fast user goal lookups
- `chat_messages_created_at_idx` - Fast message ordering

### Query Optimization
- Use the provided analytics view for complex queries
- Leverage the utility functions for common calculations
- Use appropriate date ranges in queries to limit data

## Maintenance

### Data Cleanup
```sql
-- Delete old mood entries (older than 2 years)
DELETE FROM public.mood_entries 
WHERE created_at < CURRENT_DATE - INTERVAL '2 years';

-- Delete completed goals older than 6 months
DELETE FROM public.mood_goals 
WHERE is_completed = true 
AND completed_at < CURRENT_DATE - INTERVAL '6 months';
```

### Backup Recommendations
- Regular automated backups through Supabase
- Export user data upon request
- Monitor database size and performance

## Troubleshooting

### Common Issues

1. **Profile not created automatically**
   - Check if the trigger `on_auth_user_created` exists
   - Verify the `handle_new_user()` function is working

2. **RLS blocking legitimate access**
   - Verify user is authenticated
   - Check policy conditions match your use case

3. **Real-time not working**
   - Ensure real-time is enabled in Supabase settings
   - Verify publications are set up correctly

4. **Performance issues**
   - Check if indexes are being used
   - Consider adding additional indexes for specific query patterns

### Support
For issues specific to this schema:
1. Check Supabase logs for error messages
2. Verify all policies are correctly configured
3. Test individual table operations in SQL editor
4. Ensure Flutter app has correct permissions

## Future Enhancements

The schema is designed to be extensible for future features:
- Mood pattern analysis
- Social features expansion
- Advanced analytics
- Data export functionality
- Notification systems
- Integrations with external services

This schema provides a solid foundation for the mood tracker application while maintaining security, performance, and scalability.
