import 'package:flutter/material.dart';

void main() {
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
  final String mood;
  final String note;
  final DateTime timestamp;

  MoodEntry({required this.mood, required this.note, required this.timestamp});
}

class MoodHomePage extends StatefulWidget {
  @override
  _MoodHomePageState createState() => _MoodHomePageState();
}

class _MoodHomePageState extends State<MoodHomePage> {
  String? selectedMood;
  TextEditingController noteController = TextEditingController();
  List<MoodEntry> moodHistory = [];

  void addMoodEntry() {
    if (selectedMood != null) {
      setState(() {
        moodHistory.insert(
          0,
          MoodEntry(
            mood: selectedMood!,
            note: noteController.text,
            timestamp: DateTime.now(),
          ),
        );
        selectedMood = null;
        noteController.clear();
      });
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
              onChanged: (val) => setState(() => selectedMood = val),
            ),
            TextField(
              controller: noteController,
              decoration: InputDecoration(labelText: 'Add a note (optional)'),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: addMoodEntry, child: Text('Log Mood')),
            Divider(height: 32),
            Text(
              'Mood History',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: moodHistory.length,
                itemBuilder: (context, index) {
                  final entry = moodHistory[index];
                  return ListTile(
                    leading: Text(entry.mood, style: TextStyle(fontSize: 24)),
                    title: Text(entry.note.isEmpty ? 'No note' : entry.note),
                    subtitle: Text(
                      entry.timestamp.toLocal().toString().split('.')[0],
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
