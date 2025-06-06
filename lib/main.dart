import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'analytics_page.dart';
import 'goals_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://xxasezacvotitccxnpaa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4YXNlemFjdm90aXRjY3hucGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDg1ODE3MTIsImV4cCI6MjA2NDE1NzcxMn0.aUygIOPiI1HqFwKifXGYIolzeIQGbpjzGCC861LHRS4',
  );

  runApp(MoodTrackerApp());
}

class MoodTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Mood Tracker',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: MoodHomePage(),
      debugShowCheckedModeBanner: false,
    );
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

class _MoodHomePageState extends State<MoodHomePage> {
  String? selectedMood;
  TextEditingController noteController = TextEditingController();
  List<MoodEntry> moodHistory = [];
  bool isLoading = false;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('mood_entries')
          .select()
          .order('created_at', ascending: false);

      setState(() {
        moodHistory =
            (response as List).map((json) => MoodEntry.fromJson(json)).toList();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading mood history: $error')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> addMoodEntry() async {
    if (selectedMood != null) {
      setState(() => isLoading = true);
      try {
        final newEntry = MoodEntry(
          mood: selectedMood!,
          note: noteController.text,
          timestamp: DateTime.now(),
        );

        print('Attempting to save: ${newEntry.toJson()}'); // Debug log
        final response = await supabase
            .from('mood_entries')
            .insert(newEntry.toJson());
        print('Database response: $response'); // Debug log

        setState(() {
          selectedMood = null;
          noteController.clear();
        });

        await _loadMoodHistory(); // Refresh the list
        print('Loaded ${moodHistory.length} entries after insert'); // Debug log

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Mood logged successfully!')));
      } catch (error) {
        print('Error details: $error'); // Debug log
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging mood: $error')));
      } finally {
        setState(() => isLoading = false);
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
    final moods = [
      '😊 Happy',
      '😢 Sad',
      '😠 Angry',
      '😨 Anxious',
      '😐 Neutral',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Daily Mood Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AnalyticsPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select Mood'),
              value: selectedMood,
              items:
                  moods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
              onChanged:
                  isLoading
                      ? null
                      : (val) => setState(() => selectedMood = val),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: 'Add a note (optional)'),
              enabled: !isLoading,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : addMoodEntry,
              child: isLoading ? CircularProgressIndicator() : Text('Log Mood'),
            ),
            Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mood History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (moodHistory.isNotEmpty)
                  TextButton(
                    onPressed: _showDeleteAllConfirmation,
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
            Expanded(
              child:
                  isLoading && moodHistory.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: moodHistory.length,
                        itemBuilder: (context, index) {
                          final entry = moodHistory[index];
                          return ListTile(
                            leading: Text(
                              entry.mood,
                              style: TextStyle(fontSize: 24),
                            ),
                            title: Text(
                              entry.note.isEmpty ? 'No note' : entry.note,
                            ),
                            subtitle: Text(
                              entry.timestamp.toLocal().toString().split(
                                '.',
                              )[0],
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed:
                                  () => _showDeleteConfirmation(entry.id!),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
      // Add this to your navigation drawer or bottom navigation:
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Text(
                'Mood Tracker',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.analytics),
              title: Text('Analytics'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AnalyticsPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.flag),
              title: Text('Goals & Achievements'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GoalsPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
