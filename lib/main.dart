import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'analytics_page.dart';
import 'enhanced_analytics_page.dart';
import 'goals_page.dart';
import 'auth_page.dart';
import 'onboarding_screen.dart';
import 'chat_selection_page.dart';
import 'quick_mood_entry.dart';
import 'mood_journal.dart';
import 'profile_page.dart';
import 'services/user_profile_service.dart';
import 'services/theme_service.dart';
import 'widgets/theme_toggle_widget.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://xxasezacvotitccxnpaa.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4',
      debug: true,
    );
  } catch (e) {
    print('Supabase initialization error: $e');
    // Continue anyway - we'll handle errors in UI
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeService(),
      child: MoodTrackerApp(),
    ),
  );
}

class MoodTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'MoodFlow - Daily Mood Tracker',
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            fontFamily: GoogleFonts.poppins().fontFamily,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6750A4),
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
          ),
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
    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

    // Get initial session
    _session = Supabase.instance.client.auth.currentSession;

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
          await Future.delayed(Duration(milliseconds: 500));

          // Only create default profile if no profile exists and it's not a new signup
          final existingProfile = await UserProfileService.getUserProfile(
            data.session!.user.id,
          );
          if (existingProfile == null) {
            print(
              'No profile found for existing user, creating default profile...',
            );
            await UserProfileService.ensureUserProfile(data.session!.user.id);
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
        await UserProfileService.ensureUserProfile(_session!.user.id);
      }
    }

    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing...'),
            ],
          ),
        ),
      );
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
    with TickerProviderStateMixin {
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

    // Initialize animation controllers
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
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
  }

  Future<void> _initializeApp() async {
    // Load mood history and start animations
    _loadMoodHistory();

    // Start animations with a slight delay for better UX
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
        _fabAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fabAnimationController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodHistory() async {
    setState(() => isLoading = true);
    try {
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
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          moodHistory =
              (response as List)
                  .map((json) => MoodEntry.fromJson(json))
                  .toList();
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading mood history: $error')),
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
          'user_id': supabase.auth.currentUser?.id,
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
      // Immediately sign out and navigate
      await supabase.auth.signOut();

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
      await supabase.from('mood_entries').delete().eq('id', entryId);

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
      await supabase.from('mood_entries').delete().neq('id', 0);

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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
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
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.mood_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
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
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      MediaQuery.of(context).orientation ==
                      Orientation.landscape;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isLandscape ? 6 : 4,
                      crossAxisSpacing: isLandscape ? 8 : 12,
                      mainAxisSpacing: isLandscape ? 8 : 12,
                      childAspectRatio: isLandscape ? 0.8 : 0.9,
                    ),
                    itemCount: moods.length,
                    itemBuilder: (context, index) {
                      final mood = moods[index];
                      final isSelected = selectedMood == mood['name'];

                      return GestureDetector(
                        onTap:
                            isLoading
                                ? null
                                : () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    selectedMood = mood['name'];
                                    selectedMoodEmoji = mood['emoji'];
                                  });
                                },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          transform:
                              Matrix4.identity()..scale(
                                isSelected ? 1.02 : 1.0,
                              ), // Reduced scale to prevent overflow
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer
                                    : Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border:
                                isSelected
                                    ? Border.all(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                    : Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline.withOpacity(0.2),
                                      width: 1,
                                    ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                    : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                          ),
                          child: Container(
                            padding: EdgeInsets.all(isLandscape ? 4 : 8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Emoji with constrained size
                                Flexible(
                                  flex: 3,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      style: TextStyle(
                                        fontSize:
                                            isLandscape
                                                ? (isSelected ? 24 : 22)
                                                : (isSelected ? 30 : 28),
                                      ),
                                      child: Text(
                                        mood['emoji']!,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),

                                // Spacing
                                SizedBox(height: isLandscape ? 2 : 4),

                                // Mood name with constrained size
                                Flexible(
                                  flex: 2,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      mood['name']!,
                                      style: GoogleFonts.poppins(
                                        fontSize: isLandscape ? 10 : 12,
                                        fontWeight:
                                            isSelected
                                                ? FontWeight.bold
                                                : FontWeight.w500,
                                        color:
                                            isSelected
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.onPrimaryContainer
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
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
                      );
                    },
                  );
                },
              ),
              if (selectedMood != null) ...[
                const SizedBox(height: 20),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.8),
                        Theme.of(
                          context,
                        ).colorScheme.secondaryContainer.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          selectedMoodEmoji!,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'You selected: $selectedMood',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                              ),
                            ),
                            Text(
                              moods.firstWhere(
                                (m) => m['name'] == selectedMood,
                              )['description']!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.3),
                  ),
                ),
                child: TextField(
                  controller: noteController,
                  enabled: !isLoading,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Add a note (optional)',
                    hintText: 'What\'s on your mind today?',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(16),
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.edit_note_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  child: FilledButton.icon(
                    onPressed:
                        (selectedMood != null && !isLoading)
                            ? addMoodEntry
                            : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon:
                        isLoading
                            ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : Icon(Icons.add_circle_outline_rounded),
                    label: Text(
                      isLoading ? 'Logging...' : 'Log Mood Entry',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
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
    String greeting;
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Good Morning! ☀️';
      greetingIcon = Icons.wb_sunny_rounded;
    } else if (hour < 17) {
      greeting = 'Good Afternoon! 🌤️';
      greetingIcon = Icons.wb_cloudy_rounded;
    } else {
      greeting = 'Good Evening! 🌙';
      greetingIcon = Icons.nightlight_round;
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                greetingIcon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 28,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  greeting,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Ready to track your mood and connect with your inner self?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(
                context,
              ).colorScheme.onPrimaryContainer.withOpacity(0.8),
              height: 1.4,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.emoji_events_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${moodHistory.length} entries logged',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_rounded,
                  size: 16,
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
        SizedBox(width: 12),
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
        SizedBox(width: 12),
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

  Widget _buildQuickActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            expandedHeight: 140,
            floating: true,
            snap: true,
            pinned: false,
            centerTitle: false,
            flexibleSpace: FlexibleSpaceBar(
              title:
                  null, // Remove title from FlexibleSpaceBar to avoid overlap
              titlePadding: EdgeInsets.zero,
              background: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  top: 80,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoodFlow',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'How are you feeling today?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 8, top: 8),
                child: IconButton(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.book_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  tooltip: 'Mood Journal',
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(right: 8, top: 8),
                child: IconButton(
                  icon: Container(
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
                  tooltip: 'Chat Options',
                  onPressed: () {
                    HapticFeedback.lightImpact();
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
                margin: EdgeInsets.only(right: 8, top: 8),
                child: ThemeToggleWidget(isCompact: true),
              ),
              Container(
                margin: EdgeInsets.only(right: 16, top: 8),
                child: PopupMenuButton<String>(
                  icon: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        padding: EdgeInsets.only(bottom: 16, right: 8),
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
                margin: EdgeInsets.only(bottom: 16),
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
                  elevation: 6,
                  child: Container(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.add_reaction_rounded, size: 28),
                  ),
                  tooltip: 'Quick Mood Entry',
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
                elevation: 4,
                icon: Icon(Icons.flag_rounded),
                label: Text(
                  'Goals',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
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
