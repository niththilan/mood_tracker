# Database Setup Instructions

## IMPORTANT: Run SQL Migration First!

The friends system requires new database tables that don't exist yet. You need to run the SQL migration before using the friends features.

## Steps to Fix the Error:

### 1. Run the SQL Migration
1. Open your Supabase Dashboard
2. Go to the **SQL Editor** tab
3. Copy the entire content from `friends_system_migration.sql`
4. Paste it into the SQL Editor
5. Click **"RUN"** to execute the migration

### 2. Verify Tables Were Created
After running the migration, verify these tables exist in your Database → Tables:
- `friend_requests`
- `friendships` 
- `user_mood_sharing_settings`
- `friend_activity_feed`

### 3. Check Row Level Security (RLS)
Make sure RLS policies were created:
1. Go to Database → Tables
2. Click on each table
3. Check that RLS policies exist for each table

## Common Issues:

### Error: "Could not find a relationship between 'friendships' and 'friend_id'"
- **Cause**: The database migration hasn't been run yet
- **Solution**: Run the SQL migration as described above

### Error: "relation 'public.friend_requests' does not exist"  
- **Cause**: Tables haven't been created
- **Solution**: Run the SQL migration

### Error: "permission denied for table friendships"
- **Cause**: RLS policies not set up correctly
- **Solution**: Re-run the migration to ensure all policies are created

## Migration Content Preview:
The migration creates:
- `friend_requests` table for managing friend requests
- `friendships` table for storing mutual friend relationships  
- `user_mood_sharing_settings` table for privacy controls
- `friend_activity_feed` table for friend activity notifications
- All necessary RLS policies for security
- Database functions for friend management
- Triggers for automatic activity logging

## After Migration:
Once the migration is complete, the friends system should work:
1. Click the Friends button (👥) in the top navigation
2. You should see the friends page with 3 tabs
3. Try searching for users to add as friends
4. Test sending friend requests

If you still get errors after running the migration, check the browser console for additional error details and ensure your Supabase project is properly configured.
