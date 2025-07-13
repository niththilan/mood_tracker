import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'utils/logger.dart';
import 'analytics_page.dart';
import 'enhanced_analytics_page.dart';
import 'goals_page.dart';
import 'auth_page.dart';
import 'onboarding_screen.dart';
import 'chat_selection_page.dart';
import 'friends_list_page.dart';
import 'quick_mood_entry.dart';
import 'mood_journal.dart';
import 'profile_page.dart';
import 'services/user_profile_service.dart';
import 'services/theme_service.dart';
import 'services/google_auth_service.dart';
import 'widgets/theme_toggle_widget.dart';
import 'widgets/color_theme_button.dart';
import 'widgets/interactive_logo.dart';
import 'widgets/loading_screen.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase without blocking
  _initializeSupabase();

  // Start the app immediately
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: MoodTrackerApp(),
    ),
  );
}

// Non-blocking initialization
void _initializeSupabase() async {
  try {
    await Supabase.initialize(
      url: 'https://xxasezacvotitccxnpaa.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4',
      debug: false, // Disable debug logs for better performance
    );

    // Initialize Google Sign-In for web asynchronously
    GoogleAuthService.initializeForWeb();

    // Initialize Google Sign-In for iOS specifically
    GoogleAuthService.initializeForIOS();
  } catch (e) {
    Logger.error('Initialization error: $e');
    // Continue anyway - we'll handle errors in UI
  }
}

class MoodTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        // Create theme data once to avoid rebuilding
        final lightTheme = ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: themeService.seedColor,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        );

        final darkTheme = ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          colorScheme: ColorScheme.fromSeed(
            seedColor: themeService.seedColor,
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            elevation: 0,
            scrolledUnderElevation: 1,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );

        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'MoodFlow - Daily Mood Tracker',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeService.themeMode,
          home: AuthWrapper(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  bool _onboardingCompleted = false;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Show UI immediately, load data in background
    setState(() {
      _isInitialized = true;
    });

    // Background initialization
    Future.microtask(() async {
      try {
        // Check onboarding status
        final prefs = await SharedPreferences.getInstance();
        _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

        // Get initial session
        _session = Supabase.instance.client.auth.currentSession;

        if (mounted) {
          setState(() {});
        }

        // Listen to auth changes
        Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
          if (mounted) {
            setState(() {
              _session = data.session;
            });

            // Handle sign out event explicitly
            if (data.event == AuthChangeEvent.signedOut) {
              print('User signed out, clearing session...');
              setState(() {
                _session = null;
              });
              return;
            }

            // Only ensure user profile exists for existing logins, not new signups
            if (data.session?.user != null &&
                data.event == AuthChangeEvent.signedIn) {
              print(
                'User signed in (event: ${data.event}), checking if profile exists...',
              );
              // Add a small delay to allow signup profile creation to complete
              await Future.delayed(
                Duration(milliseconds: 500),
              ); // Reduced delay

              // Only create default profile if no profile exists and it's not a new signup
              final existingProfile = await UserProfileService.getUserProfile(
                data.session!.user.id,
              );
              if (existingProfile == null) {
                print(
                  'No profile found for existing user, creating default profile...',
                );
                final profileCreated =
                    await UserProfileService.createUserProfile(
                      userId: data.session!.user.id,
                      name: data.session!.user.email?.split('@')[0] ?? 'User',
                    );
                if (!profileCreated) {
                  print('Failed to create user profile in auth state change');
                }
              } else {
                print(
                  'Profile already exists with name: ${existingProfile['name']}',
                );
              }
            }
          }
        });

        // If there's an existing session, ensure profile exists
        if (_session?.user != null) {
          print('Existing session found, checking if profile exists...');
          final existingProfile = await UserProfileService.getUserProfile(
            _session!.user.id,
          );
          if (existingProfile == null) {
            print(
              'No profile found for existing session, creating default profile...',
            );
            final profileCreated = await UserProfileService.createUserProfile(
              userId: _session!.user.id,
              name: _session!.user.email?.split('@')[0] ?? 'User',
            );
            if (!profileCreated) {
              print('Failed to create user profile for existing session');
            }
          }
        }

        if (mounted) {
          setState(() {});
        }
      } catch (e) {
        print('Auth initialization error: $e');
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return LoadingScreen(message: 'Initializing MoodFlow...');
    }

    // Show onboarding if not completed
    if (!_onboardingCompleted) {
      return OnboardingScreen();
    }

    if (_session != null) {
      return MoodHomePage();
    } else {
      return AuthPage();
    }
  }
}

class MoodEntry {
  final int? id;
  final String mood;
  final String note;
  final DateTime timestamp;
  final int? intensity;

  MoodEntry({
    this.id,
    required this.mood,
    required this.note,
    required this.timestamp,
    this.intensity,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    // Use the joined mood_categories data if available
    String moodDisplay;
    if (json['mood_categories'] != null) {
      final category = json['mood_categories'];
      moodDisplay = '${category['emoji']} ${category['name']}';
    } else {
      // Fallback to hardcoded mapping if join data not available
      final moodCategories = {
        1: {'name': 'Happy', 'emoji': '😊'},
        2: {'name': 'Excited', 'emoji': '😄'},
        3: {'name': 'Calm', 'emoji': '😌'},
        4: {'name': 'Neutral', 'emoji': '😐'},
        5: {'name': 'Sad', 'emoji': '😔'},
        6: {'name': 'Angry', 'emoji': '😠'},
        7: {'name': 'Anxious', 'emoji': '😨'},
        8: {'name': 'Tired', 'emoji': '😴'},
      };

      final categoryId = json['mood_category_id'] as int?;
      final category =
          moodCategories[categoryId] ?? {'name': 'Unknown', 'emoji': '❓'};
      moodDisplay = '${category['emoji']} ${category['name']}';
    }

    return MoodEntry(
      id: json['id'],
      mood: moodDisplay,
      note: json['note'] ?? '',
      timestamp: DateTime.parse(json['created_at']),
      intensity: json['intensity'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'note': note,
      'created_at': timestamp.toIso8601String(),
      'intensity': intensity,
    };
  }
}

class MoodHomePage extends StatefulWidget {
  @override
  _MoodHomePageState createState() => _MoodHomePageState();
}

class _MoodHomePageState extends State<MoodHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String? selectedMood;
  String? selectedMoodEmoji;
  TextEditingController noteController = TextEditingController();
  List<MoodEntry> moodHistory = [];
  bool isLoading = false;
  late AnimationController _animationController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  final supabase = Supabase.instance.client;

  // Message notification variables
  int _unreadMessageCount = 0;
  late RealtimeChannel? _messageChannel;

  // Enhanced mood options with better emojis and descriptions
  final List<Map<String, String>> moods = [
    {
      'emoji': '😊',
      'name': 'Happy',
      'description': 'Feeling great and positive',
    },
    {
      'emoji': '😄',
      'name': 'Excited',
      'description': 'Full of energy and enthusiasm',
    },
    {'emoji': '😌', 'name': 'Calm', 'description': 'Peaceful and relaxed'},
    {
      'emoji': '😐',
      'name': 'Neutral',
      'description': 'Not particularly good or bad',
    },
    {'emoji': '😔', 'name': 'Sad', 'description': 'Feeling down or melancholy'},
    {'emoji': '😠', 'name': 'Angry', 'description': 'Frustrated or irritated'},
    {'emoji': '😨', 'name': 'Anxious', 'description': 'Worried or stressed'},
    {'emoji': '😴', 'name': 'Tired', 'description': 'Exhausted or sleepy'},
  ];

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers with web-optimized durations
    final animationDuration = kIsWeb ? 100 : 200; // Faster on web
    final fabAnimationDuration = kIsWeb ? 75 : 150; // Faster on web

    _animationController = AnimationController(
      duration: Duration(milliseconds: animationDuration),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: fabAnimationDuration),
      vsync: this,
    );

    // Create animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    // Ensure user profile exists and load mood history
    _initializeApp();

    // Initialize message notifications
    _initializeMessageNotifications();

    // Add app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initializeApp() async {
    // Start animations immediately for instant UI response
    if (mounted) {
      _animationController.forward();
      _fabAnimationController.forward();
    }

    // Load data in background without blocking UI
    _loadMoodHistoryInBackground();
  }

  void _loadMoodHistoryInBackground() {
    // Use microtask to defer heavy operations until after the next frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadMoodHistory();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    noteController.dispose();
    _messageChannel?.unsubscribe();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadMoodHistory() async {
    // Show loading only if we don't have data yet
    if (moodHistory.isEmpty && mounted) {
      setState(() => isLoading = true);
    }

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            moodHistory = [];
            isLoading = false;
          });
        }
        return;
      }

      // Skip profile check if we already have mood data (user likely exists)
      if (moodHistory.isEmpty) {
        final userProfile = await UserProfileService.getUserProfile(
          currentUser.id,
        );
        if (userProfile == null) {
          print('No user profile found, creating one...');
          final profileCreated = await UserProfileService.createUserProfile(
            userId: currentUser.id,
            name: currentUser.email?.split('@')[0] ?? 'User',
          );

          if (!profileCreated) {
            print('Failed to create user profile');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Error: User profile not found. Please update your profile.',
                  ),
                ),
              );
              setState(() => isLoading = false);
            }
            return;
          }
        }
      }

      // Load only recent entries first for faster initial load
      final response = await supabase
          .from('mood_entries')
          .select('''
            id,
            mood_category_id,
            intensity,
            note,
            created_at,
            mood_categories (
              id,
              name,
              emoji,
              color_hex,
              mood_score,
              description
            )
          ''')
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(50); // Limit to 50 recent entries for faster loading

      if (mounted) {
        setState(() {
          moodHistory =
              (response as List)
                  .map((json) => MoodEntry.fromJson(json))
                  .toList();
        });
      }
    } catch (error) {
      print('Error loading mood history: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading mood history: $error'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> addMoodEntry() async {
    if (selectedMood != null && !isLoading) {
      setState(() => isLoading = true);

      try {
        final currentUser = supabase.auth.currentUser;
        if (currentUser == null) {
          throw Exception('User not authenticated');
        }

        // Ensure user profile exists before creating mood entry
        final userProfile = await UserProfileService.getUserProfile(
          currentUser.id,
        );
        if (userProfile == null) {
          throw Exception(
            'User profile not found. Please update your profile.',
          );
        }

        // Find the mood category ID based on the selected mood name
        int? moodCategoryId;
        final moodCategories = {
          'Happy': 1,
          'Excited': 2,
          'Calm': 3,
          'Neutral': 4,
          'Sad': 5,
          'Angry': 6,
          'Anxious': 7,
          'Tired': 8,
        };

        moodCategoryId = moodCategories[selectedMood];

        if (moodCategoryId == null) {
          throw Exception('Invalid mood selected');
        }

        final newEntry = {
          'user_id': currentUser.id,
          'mood_category_id': moodCategoryId,
          'intensity': 5, // Default intensity, can be made customizable later
          'note': noteController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('mood_entries').insert(newEntry);

        if (mounted) {
          // Reset form with smooth animation
          setState(() {
            selectedMood = null;
            selectedMoodEmoji = null;
            noteController.clear();
          });

          // Reload mood history
          await _loadMoodHistory();

          // Restart animations for new content
          _animationController.reset();
          _animationController.forward();

          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text('Mood logged successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (error) {
        print('Error adding mood entry: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text('Error logging mood: $error')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  Future<void> _signOut() async {
    try {
      // Sign out from Google first (if signed in with Google)
      if (await GoogleAuthService.isSignedIn()) {
        await GoogleAuthService.signOut();
      } else {
        // Regular Supabase sign out for email/password users
        await supabase.auth.signOut();
      }

      // Use the global navigator to immediately navigate to auth page
      // This ensures immediate UI update
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AuthPage()),
          (route) => false,
        );
      } else {
        // Fallback: restart the entire app if navigator is not available
        runApp(MoodTrackerApp());
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteMoodEntry(int entryId) async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await supabase
          .from('mood_entries')
          .delete()
          .eq('id', entryId)
          .eq('user_id', currentUser.id);

      // Reload with animation
      await _loadMoodHistory();
      _animationController.reset();
      _animationController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Mood entry deleted successfully!'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting entry: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteAllHistory() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await supabase
          .from('mood_entries')
          .delete()
          .eq('user_id', currentUser.id);

      // Reload with animation
      await _loadMoodHistory();
      _animationController.reset();
      _animationController.forward();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('All mood history deleted successfully!'),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting history: $error'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(int entryId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Entry'),
          content: Text('Are you sure you want to delete this mood entry?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMoodEntry(entryId);
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteAllConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete All History'),
          content: Text(
            'Are you sure you want to delete ALL mood entries? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAllHistory();
              },
              child: Text('Delete All', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickStats() {
    final recentEntries = moodHistory.take(7).toList(); // Last 7 entries
    final moodCounts = <String, int>{};

    for (var entry in recentEntries) {
      String mood = entry.mood.split(' ').skip(1).join(' '); // Remove emoji
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    String mostFrequentMood = 'None';
    if (moodCounts.isNotEmpty) {
      mostFrequentMood =
          moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Quick Insights',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Entries',
                    '${moodHistory.length}',
                    Icons.event_note,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'This Week',
                    '${recentEntries.length}',
                    Icons.calendar_today,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Most Common',
                    mostFrequentMood,
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMoodSelectionCard() {
    return Card(
      elevation: 8,
      shadowColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(
                context,
              ).colorScheme.primaryContainer.withValues(alpha: 0.1),
              Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ],
          ),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.mood_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling?',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Select your current mood',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Transform.translate(
                offset: const Offset(0, -8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    final isTablet = screenWidth > 600;
                    final isLargeScreen = screenWidth > 900;
                    final isLandscape =
                        MediaQuery.of(context).orientation ==
                        Orientation.landscape;

                    // Responsive grid configuration
                    int crossAxisCount;
                    double childAspectRatio;
                    double spacing;

                    if (isLargeScreen) {
                      crossAxisCount = 8;
                      childAspectRatio = 0.85;
                      spacing = 16;
                    } else if (isTablet) {
                      crossAxisCount = isLandscape ? 8 : 6;
                      childAspectRatio = isLandscape ? 0.75 : 0.8;
                      spacing = 14;
                    } else {
                      crossAxisCount = isLandscape ? 6 : 4;
                      childAspectRatio = isLandscape ? 0.7 : 0.85;
                      spacing = isLandscape ? 10 : 12;
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: moods.length,
                      itemBuilder: (context, index) {
                        final mood = moods[index];
                        final isSelected = selectedMood == mood['name'];
                        final screenWidth = MediaQuery.of(context).size.width;
                        final isCompact = screenWidth < 600;

                        return Container(
                          margin: EdgeInsets.all(
                            1.5,
                          ), // Small margin to prevent overflow
                          child: GestureDetector(
                            onTap:
                                isLoading
                                    ? null
                                    : () {
                                      HapticFeedback.mediumImpact();
                                      setState(() {
                                        selectedMood = mood['name'];
                                        selectedMoodEmoji = mood['emoji'];
                                      });
                                    },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient:
                                    isSelected
                                        ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer,
                                            Theme.of(
                                              context,
                                            ).colorScheme.secondaryContainer,
                                          ],
                                        )
                                        : LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.6),
                                            Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                          ],
                                        ),
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 16 : 20,
                                ),
                                border:
                                    isSelected
                                        ? Border.all(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                          width: 2.0,
                                        )
                                        : Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                            spreadRadius: 0,
                                          ),
                                        ]
                                        : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.08,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                            spreadRadius: 0,
                                          ),
                                        ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isCompact ? 16 : 20,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(isCompact ? 8 : 10),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Responsive emoji sizing
                                      Flexible(
                                        flex: 3,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            mood['emoji']!,
                                            style: TextStyle(
                                              fontSize: _getResponsiveEmojiSize(
                                                screenWidth,
                                                isSelected,
                                              ),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: isCompact ? 4 : 6),
                                      // Responsive text sizing
                                      Flexible(
                                        flex: 2,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            mood['name']!,
                                            style: GoogleFonts.poppins(
                                              fontSize: _getResponsiveTextSize(
                                                screenWidth,
                                              ),
                                              fontWeight:
                                                  isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w600,
                                              color:
                                                  isSelected
                                                      ? Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                              letterSpacing: 0.5,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (selectedMood != null) ...[
                const SizedBox(height: 24),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOutBack,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.9),
                        Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withValues(alpha: 0.9),
                        Theme.of(
                          context,
                        ).colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          selectedMoodEmoji!,
                          style: const TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 300),
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                              child: Text('You selected: $selectedMood'),
                            ),
                            SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: Duration(milliseconds: 300),
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.85),
                                height: 1.3,
                              ),
                              child: Text(
                                moods.firstWhere(
                                  (m) => m['name'] == selectedMood,
                                )['description']!,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add a subtle pulse animation
                      AnimatedContainer(
                        duration: Duration(milliseconds: 1000),
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: noteController,
                  enabled: !isLoading,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 14, height: 1.4),
                  decoration: InputDecoration(
                    labelText: 'Add a note (optional)',
                    hintText:
                        'What\'s on your mind today? Share your thoughts...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(20),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    labelStyle: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                    hintStyle: GoogleFonts.poppins(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient:
                        (selectedMood != null && !isLoading)
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.secondary,
                              ],
                            )
                            : null,
                    boxShadow:
                        (selectedMood != null && !isLoading)
                            ? [
                              BoxShadow(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: Offset(0, 6),
                              ),
                            ]
                            : null,
                  ),
                  child: FilledButton.icon(
                    onPressed:
                        (selectedMood != null && !isLoading)
                            ? addMoodEntry
                            : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    icon:
                        isLoading
                            ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                            : Icon(Icons.add_circle_outline_rounded, size: 24),
                    label: Text(
                      isLoading ? 'Logging your mood...' : 'Log Mood Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoodHistorySection() {
    return Column(
      children: [
        // History Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mood History',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (moodHistory.isNotEmpty)
              TextButton.icon(
                onPressed: _showDeleteAllConfirmation,
                icon: const Icon(Icons.delete_sweep, size: 20),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // History Content
        if (isLoading && moodHistory.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Loading your mood history...',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          )
        else if (moodHistory.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.sentiment_neutral,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No mood entries yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by logging your first mood above!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: moodHistory.length,
            itemBuilder: (context, index) {
              final entry = moodHistory[index];
              return AnimatedContainer(
                duration: Duration(milliseconds: 200 + (index * 50)),
                curve: Curves.easeOutBack,
                child: Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        entry.mood.split(' ')[0], // Get emoji part
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    title: Text(
                      entry.mood,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (entry.note.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(entry.note),
                          const SizedBox(height: 4),
                        ],
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDateTime(entry.timestamp),
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _showDeleteConfirmation(entry.id!),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildWelcomeSection() {
    final hour = DateTime.now().hour;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final responsivePadding = _getResponsivePadding(screenWidth);

    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning! ☀️';
    } else if (hour < 17) {
      greeting = 'Good Afternoon! 🌤️';
    } else {
      greeting = 'Good Evening! 🌙';
    }

    return AnimatedContainer(
      duration: Duration(milliseconds: 200), // Reduced from 600ms
      width: double.infinity,
      padding: EdgeInsets.all(responsivePadding),
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 0, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
            Theme.of(
              context,
            ).colorScheme.tertiaryContainer.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(isTablet ? 28 : 24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.15),
            blurRadius: isTablet ? 25 : 20,
            offset: Offset(0, isTablet ? 10 : 8),
            spreadRadius: isTablet ? 3 : 2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: isTablet ? 10 : 8,
            offset: Offset(0, isTablet ? -3 : -2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Responsive header row
          Flex(
            direction: isTablet ? Axis.horizontal : Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Interactive Logo instead of static icon
              InteractiveLogo(
                size: isTablet ? 80 : 70,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  // Show a fun message when logo is tapped
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Text('😊'),
                          SizedBox(width: 8),
                          Text('Welcome to MoodFlow!'),
                        ],
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: Duration(milliseconds: 100), // Reduced from 300ms
                  style: GoogleFonts.poppins(
                    fontSize: isTablet ? 26 : 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    letterSpacing: 0.5,
                  ),
                  child: Text(greeting),
                ),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 20 : 16),
          // Responsive description
          AnimatedDefaultTextStyle(
            duration: Duration(milliseconds: 100), // Reduced from 300ms
            style: GoogleFonts.poppins(
              fontSize: isTablet ? 17 : 15,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
            child: Text(
              'Ready to track your mood and connect with your inner self? Let\'s make today amazing!',
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),
          // Responsive stats row
          Flex(
            direction: isTablet ? Axis.horizontal : Axis.horizontal,
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18 : 14,
                    vertical: isTablet ? 12 : 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: isTablet ? 22 : 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: isTablet ? 10 : 8),
                      Flexible(
                        child: Text(
                          '${moodHistory.length} entries logged',
                          style: GoogleFonts.poppins(
                            fontSize: isTablet ? 15 : 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: isTablet ? 16 : 12),
              AnimatedContainer(
                duration: Duration(milliseconds: 400),
                padding: EdgeInsets.all(isTablet ? 14 : 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.2),
                      blurRadius: isTablet ? 10 : 8,
                      offset: Offset(0, isTablet ? 4 : 3),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: isTablet ? 22 : 18,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final spacing = isTablet ? 16.0 : 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // For large screens, we can use a more expanded layout
        if (screenWidth > 900) {
          return Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Quick Entry',
                  'Log mood fast',
                  Icons.add_reaction_rounded,
                  Theme.of(context).colorScheme.primary,
                  () async {
                    HapticFeedback.mediumImpact();
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                QuickMoodEntry(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 1.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    if (result == true) {
                      await _loadMoodHistory();
                    }
                  },
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildQuickActionCard(
                  'Analytics',
                  'View insights',
                  Icons.analytics_rounded,
                  Theme.of(context).colorScheme.secondary,
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                EnhancedAnalyticsPage(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildQuickActionCard(
                  'Goals',
                  'Set targets',
                  Icons.flag_rounded,
                  Theme.of(context).colorScheme.tertiary,
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GoalsPage()),
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildQuickActionCard(
                  'Journal',
                  'Write thoughts',
                  Icons.book_rounded,
                  Theme.of(context).colorScheme.tertiary,
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MoodJournal()),
                    );
                  },
                ),
              ),
            ],
          );
        } else {
          // Standard 3-column layout for tablets and phones
          return Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Quick Entry',
                  'Log mood fast',
                  Icons.add_reaction_rounded,
                  Theme.of(context).colorScheme.primary,
                  () async {
                    HapticFeedback.mediumImpact();
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                QuickMoodEntry(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 1.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    if (result == true) {
                      await _loadMoodHistory();
                    }
                  },
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildQuickActionCard(
                  'Analytics',
                  'View insights',
                  Icons.analytics_rounded,
                  Theme.of(context).colorScheme.secondary,
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                EnhancedAnalyticsPage(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: spacing),
              Expanded(
                child: _buildQuickActionCard(
                  'Goals',
                  'Set targets',
                  Icons.flag_rounded,
                  Theme.of(context).colorScheme.tertiary,
                  () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GoalsPage()),
                    );
                  },
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 150), // Reduced from 300ms
        curve: Curves.easeInOutBack,
        padding: EdgeInsets.all(
          isLargeScreen
              ? 22
              : isTablet
              ? 20
              : 18,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: isLargeScreen ? 0.18 : 0.15),
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(
            isLargeScreen
                ? 24
                : isTablet
                ? 22
                : 20,
          ),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: isTablet ? 1.5 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius:
                  isLargeScreen
                      ? 16
                      : isTablet
                      ? 14
                      : 12,
              offset: Offset(
                0,
                isLargeScreen
                    ? 6
                    : isTablet
                    ? 5
                    : 4,
              ),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.1),
              blurRadius: isTablet ? 8 : 6,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              padding: EdgeInsets.all(
                isLargeScreen
                    ? 16
                    : isTablet
                    ? 15
                    : 14,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.2),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: isTablet ? 10 : 8,
                    offset: Offset(0, isTablet ? 4 : 3),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: color,
                size:
                    isLargeScreen
                        ? 32
                        : isTablet
                        ? 30
                        : 28,
              ),
            ),
            SizedBox(
              height:
                  isLargeScreen
                      ? 16
                      : isTablet
                      ? 14
                      : 12,
            ),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize:
                    isLargeScreen
                        ? 16
                        : isTablet
                        ? 15
                        : 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isTablet ? 6 : 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize:
                    isLargeScreen
                        ? 13
                        : isTablet
                        ? 12
                        : 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Message notification methods
  Future<void> _initializeMessageNotifications() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Get initial unread message count
      await _updateUnreadMessageCount();

      // Set up real-time subscription for new chat messages
      _messageChannel =
          supabase
              .channel('message_notifications_${currentUser.id}')
              .onPostgresChanges(
                event: PostgresChangeEvent.insert,
                schema: 'public',
                table: 'chat_messages',
                callback: (payload) {
                  // Increment unread count when new private message is received
                  // We'll check if it's for the current user in the database query instead
                  if (mounted) {
                    // Refresh the unread count from database to be safe
                    _updateUnreadMessageCount();
                  }
                },
              )
              .subscribe();
    } catch (error) {
      print('Error initializing message notifications: $error');
    }
  }

  Future<void> _updateUnreadMessageCount() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      // Get count of unread private messages
      final response = await supabase
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', currentUser.id)
          .eq('is_private', true)
          .eq('is_read', false);

      if (mounted) {
        setState(() {
          _unreadMessageCount = (response as List).length;
        });
      }
    } catch (error) {
      print('Error updating unread message count: $error');
      // Fallback: set count to 0 if there's an error
      if (mounted) {
        setState(() {
          _unreadMessageCount = 0;
        });
      }
    }
  }

  // Refresh notification count (can be called when app resumes from background)
  Future<void> refreshNotificationCount() async {
    await _updateUnreadMessageCount();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh notification count when app comes back to foreground
      refreshNotificationCount();
    }
  }

  void _markMessagesAsRead() async {
    // Reset the local count immediately for instant UI feedback
    if (mounted) {
      setState(() {
        _unreadMessageCount = 0;
      });
    }

    // Mark messages as read in the database
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      await supabase
          .from('chat_messages')
          .update({'is_read': true})
          .eq('receiver_id', currentUser.id)
          .eq('is_private', true)
          .eq('is_read', false);
    } catch (error) {
      print('Error marking messages as read: $error');
    }
  }

  // Build notification badge widget
  Widget _buildNotificationBadge({required Widget child}) {
    if (_unreadMessageCount == 0) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            padding: EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1),
            ),
            constraints: BoxConstraints(minWidth: 16, minHeight: 16),
            child: Text(
              _unreadMessageCount > 99 ? '99+' : _unreadMessageCount.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods for responsive design
  double _getResponsiveEmojiSize(double screenWidth, bool isSelected) {
    if (screenWidth > 900) {
      return isSelected ? 42 : 38;
    } else if (screenWidth > 600) {
      return isSelected ? 36 : 32;
    } else {
      return isSelected ? 32 : 28;
    }
  }

  double _getResponsiveTextSize(double screenWidth) {
    if (screenWidth > 900) {
      return 14;
    } else if (screenWidth > 600) {
      return 13;
    } else {
      return 12;
    }
  }

  double _getResponsivePadding(double screenWidth) {
    if (screenWidth > 900) {
      return 32;
    } else if (screenWidth > 600) {
      return 28;
    } else {
      return 24;
    }
  }

  double _getResponsiveHorizontalPadding() {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) {
      return 32;
    } else if (screenWidth > 900) {
      return 24;
    } else if (screenWidth > 600) {
      return 20;
    } else {
      return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            snap: true,
            pinned: false,
            centerTitle: false,
            toolbarHeight: 80,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InteractiveLogo(
                size: 60,
                onTap: () {
                  HapticFeedback.lightImpact();
                  // Add any special action when logo is tapped
                },
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: _buildNotificationBadge(
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  tooltip:
                      _unreadMessageCount > 0
                          ? 'Chat Options (${_unreadMessageCount} unread)'
                          : 'Chat Options',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    // Mark messages as read when navigating to chat
                    _markMessagesAsRead();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                ChatSelectionPage(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  tooltip: 'Friends',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                FriendsListPage(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(1.0, 0.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: ColorThemeButton(),
              ),
              Container(
                margin: EdgeInsets.only(right: 8),
                child: ThemeToggleWidget(isCompact: true),
              ),
              Container(
                margin: EdgeInsets.only(right: 16),
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onSelected: (value) {
                    HapticFeedback.lightImpact();
                    switch (value) {
                      case 'journal':
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    MoodJournal(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeInOut,
                                  ),
                                ),
                                child: child,
                              );
                            },
                          ),
                        );
                        break;
                      case 'profile':
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    ProfilePage(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          ),
                        );
                        break;
                      case 'analytics':
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AnalyticsPage(),
                          ),
                        );
                        break;
                      case 'enhanced_analytics':
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    EnhancedAnalyticsPage(),
                            transitionsBuilder: (
                              context,
                              animation,
                              secondaryAnimation,
                              child,
                            ) {
                              return SlideTransition(
                                position: Tween<Offset>(
                                  begin: Offset(1.0, 0.0),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              );
                            },
                          ),
                        );
                        break;
                      case 'logout':
                        _signOut();
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'journal',
                          child: ListTile(
                            leading: Icon(Icons.book_outlined),
                            title: Text('Mood Journal'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'profile',
                          child: ListTile(
                            leading: Icon(Icons.person),
                            title: Text('Profile'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'analytics',
                          child: ListTile(
                            leading: Icon(Icons.bar_chart),
                            title: Text('Basic Analytics'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'enhanced_analytics',
                          child: ListTile(
                            leading: Icon(Icons.analytics),
                            title: Text('Enhanced Analytics'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'logout',
                          child: ListTile(
                            leading: Icon(Icons.logout),
                            title: Text('Sign Out'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                ),
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveHorizontalPadding(),
              vertical: 16,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome Section
                _buildWelcomeSection(),
                const SizedBox(height: 20),

                // Quick Actions Row
                _buildQuickActionsRow(),
                const SizedBox(height: 24),

                // Wrap main content with animations
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      children: [
                        // Mood Selection Section
                        _buildMoodSelectionCard(),

                        const SizedBox(height: 20),

                        // Quick Stats Section
                        if (moodHistory.isNotEmpty)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                            child: _buildQuickStats(),
                          ),

                        const SizedBox(height: 20),

                        // Mood History Section
                        _buildMoodHistorySection(),

                        // Add bottom padding for FAB
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      // Enhanced floating action buttons with better positioning
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 20, right: 12),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 2),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: _fabAnimationController,
              curve: Curves.elasticOut,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Quick mood entry button
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: FloatingActionButton(
                  heroTag: "quick_mood",
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final result = await Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder:
                            (context, animation, secondaryAnimation) =>
                                QuickMoodEntry(),
                        transitionsBuilder: (
                          context,
                          animation,
                          secondaryAnimation,
                          child,
                        ) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 1.0),
                              end: Offset.zero,
                            ).animate(
                              CurvedAnimation(
                                parent: animation,
                                curve: Curves.easeInOut,
                              ),
                            ),
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 300),
                      ),
                    );
                    if (result == true) {
                      await _loadMoodHistory();
                    }
                  },
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  elevation: 8,
                  child: Container(
                    padding: EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Icon(Icons.add_reaction_rounded, size: 32),
                  ),
                  tooltip: 'Quick Mood Entry',
                ),
              ),
              // Color theme button
              Container(
                margin: EdgeInsets.only(bottom: 16),
                child: ColorThemeButton(
                  isFloating: true,
                  tooltipMessage: 'Change color theme',
                ),
              ),
              // Goals button
              FloatingActionButton.extended(
                heroTag: "goals",
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder:
                          (context, animation, secondaryAnimation) =>
                              GoalsPage(),
                      transitionsBuilder: (
                        context,
                        animation,
                        secondaryAnimation,
                        child,
                      ) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                          child: child,
                        );
                      },
                    ),
                  );
                },
                backgroundColor:
                    Theme.of(context).colorScheme.secondaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onSecondaryContainer,
                elevation: 6,
                icon: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Icon(Icons.flag_rounded),
                ),
                label: Text(
                  'Goals',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
