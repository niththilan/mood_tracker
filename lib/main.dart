import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_page.dart';
import 'goals_page.dart';
import 'auth_page.dart';
import 'feature_showcase.dart';

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

  runApp(MoodTrackerApp());
}

class MoodTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodFlow - Daily Mood Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
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
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6750A4),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(elevation: 0, scrolledUnderElevation: 1),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      themeMode: ThemeMode.system,
      home: AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isInitialized = false;
  Session? _session;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Get initial session
    _session = Supabase.instance.client.auth.currentSession;

    // Listen to auth changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _session = data.session;
        });
      }
    });

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

  MoodEntry({
    this.id,
    required this.mood,
    required this.note,
    required this.timestamp,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> json) {
    return MoodEntry(
      id: json['id'],
      mood: json['mood'],
      note: json['note'] ?? '',
      timestamp: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mood': mood,
      'note': note,
      'created_at': timestamp.toIso8601String(),
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
  late Animation<double> _fadeAnimation;
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadMoodHistory();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodHistory() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('mood_entries')
          .select()
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
        final newEntry = {
          'mood': '$selectedMoodEmoji $selectedMood',
          'note': noteController.text,
          'created_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('mood_entries').insert(newEntry);

        if (mounted) {
          setState(() {
            selectedMood = null;
            selectedMoodEmoji = null;
            noteController.clear();
          });

          await _loadMoodHistory();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Mood logged successfully!'),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(child: Text('Error logging mood: $error')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
      await supabase.auth.signOut();
      // Navigation will be handled automatically by AuthWrapper
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error signing out: $error')));
      }
    }
  }

  Future<void> _deleteMoodEntry(int entryId) async {
    try {
      await supabase.from('mood_entries').delete().eq('id', entryId);
      await _loadMoodHistory(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mood entry deleted successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting entry: $error')));
    }
  }

  Future<void> _deleteAllHistory() async {
    try {
      await supabase.from('mood_entries').delete().neq('id', 0);
      await _loadMoodHistory(); // Refresh the list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All mood history deleted successfully!')),
      );
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting history: $error')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MoodFlow',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'How are you feeling today?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.analytics_outlined),
                tooltip: 'Analytics',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AnalyticsPage()),
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.logout),
                tooltip: 'Sign Out',
                onPressed: isLoading ? null : _signOut,
              ),
            ],
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Mood Selection Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.mood,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Select Your Mood',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 1,
                              ),
                          itemCount: moods.length,
                          itemBuilder: (context, index) {
                            final mood = moods[index];
                            final isSelected = selectedMood == mood['name'];

                            return AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              child: InkWell(
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
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primaryContainer
                                            : Theme.of(
                                              context,
                                            ).colorScheme.surfaceVariant,
                                    borderRadius: BorderRadius.circular(16),
                                    border:
                                        isSelected
                                            ? Border.all(
                                              color:
                                                  Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                              width: 2,
                                            )
                                            : null,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        mood['emoji']!,
                                        style: TextStyle(fontSize: 28),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        mood['name']!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall?.copyWith(
                                          color:
                                              isSelected
                                                  ? Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                          fontWeight:
                                              isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        if (selectedMood != null) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  selectedMoodEmoji!,
                                  style: TextStyle(fontSize: 24),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        selectedMood!,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        moods.firstWhere(
                                          (m) => m['name'] == selectedMood,
                                        )['description']!,
                                        style:
                                            Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: 20),
                        TextField(
                          controller: noteController,
                          enabled: !isLoading,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Add a note (optional)',
                            hintText: 'What\'s on your mind?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.edit_note),
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed:
                                (selectedMood != null && !isLoading)
                                    ? addMoodEntry
                                    : null,
                            icon:
                                isLoading
                                    ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Icon(Icons.add_circle_outline),
                            label: Text(isLoading ? 'Logging...' : 'Log Mood'),
                            style: FilledButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Mood History Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.history,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Mood History',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    if (moodHistory.isNotEmpty)
                      TextButton.icon(
                        onPressed: _showDeleteAllConfirmation,
                        icon: Icon(Icons.delete_sweep, size: 20),
                        label: Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.error,
                        ),
                      ),
                  ],
                ),

                SizedBox(height: 12),

                // Mood History List
                if (isLoading && moodHistory.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading your mood history...'),
                          ],
                        ),
                      ),
                    ),
                  )
                else if (moodHistory.isEmpty)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.sentiment_neutral,
                              size: 48,
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No mood entries yet',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start by logging your first mood above!',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...moodHistory
                      .map(
                        (entry) => Card(
                          margin: EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: CircleAvatar(
                              backgroundColor:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              child: Text(
                                entry.mood.split(' ')[0], // Get emoji part
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                            title: Text(
                              entry.mood,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.note.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Text(entry.note),
                                  SizedBox(height: 4),
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
                                    SizedBox(width: 4),
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
                              icon: Icon(Icons.delete_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed:
                                  () => _showDeleteConfirmation(entry.id!),
                            ),
                          ),
                        ),
                      )
                      .toList(),
              ]),
            ),
          ),
        ],
      ),
      // Modern floating action button for quick access
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "showcase",
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => FeatureShowcasePage()),
              );
            },
            child: Icon(Icons.star),
            tooltip: 'Features',
          ),
          SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: "goals",
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GoalsPage()),
              );
            },
            icon: Icon(Icons.flag_outlined),
            label: Text('Goals'),
          ),
        ],
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
