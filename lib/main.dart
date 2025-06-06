import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        final response = await supabase.from('mood_entries').insert(newEntry.toJson());
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
      appBar: AppBar(title: Text('Daily Mood Tracker')),
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
            Text(
              'Mood History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
