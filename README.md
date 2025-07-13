# MoodFlow - Daily Mood Tracker

A Flutter-based mood tracking application with friends system and private messaging.

## Features

- 🎭 **Mood Tracking**: Log your daily moods with notes and intensity levels
- 👥 **Friends System**: Send friend requests, manage friendships
- 💬 **Private Messaging**: Chat privately with friends
- 🔔 **Message Notifications**: Real-time notification badges for unread messages
- 🏠 **Community Chat**: Join public conversations
- 📊 **Analytics**: Track mood patterns and insights
- 🎯 **Goals**: Set and track personal goals
- 🎨 **Customizable Themes**: Personalize your experience

## Technology Stack

- **Frontend**: Flutter (Web, iOS, Android, Desktop)
- **Backend**: Supabase (PostgreSQL, Authentication, Real-time)
- **Authentication**: Email/Password + Google OAuth
- **Database**: PostgreSQL with Row Level Security

## Getting Started

1. **Prerequisites**:
   - Flutter SDK (latest stable)
   - Dart SDK
   - Supabase account

2. **Installation**:
   ```bash
   git clone <repository-url>
   cd mood_tracker
   flutter pub get
   ```

3. **Database Setup**:
   - Create a new Supabase project
   - Run the migration: `friends_system_migration.sql`
   - Update Supabase credentials in `lib/main.dart`

4. **Run the app**:
   ```bash
   flutter run -d chrome --web-port=3000
   ```

## Database Migration

The project includes a complete database migration file: `friends_system_migration.sql`

This migration sets up:
- User profiles and authentication
- Mood categories and entries
- Friends system (requests, friendships)
- Private conversations and messaging
- Privacy controls and settings
- All necessary indexes and security policies

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── auth_page.dart           # Authentication
├── mood_journal.dart        # Mood tracking
├── friends_list_page.dart   # Friends management
├── chat_page.dart           # Messaging
├── analytics_page.dart      # Mood analytics
├── goals_page.dart          # Goal tracking
├── profile_page.dart        # User profile
├── services/                # Business logic services
├── widgets/                 # Reusable UI components
└── utils/                   # Utilities and helpers
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License.
