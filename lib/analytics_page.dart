import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main.dart';

class AnalyticsPage extends StatefulWidget {
  @override
  _AnalyticsPageState createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  List<MoodEntry> allEntries = [];
  bool isLoading = true;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final response = await supabase
          .from('mood_entries')
          .select()
          .order('created_at', ascending: true);

      setState(() {
        allEntries =
            (response as List).map((json) => MoodEntry.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $error')),
      );
    }
  }

  Map<String, int> _getMoodCounts() {
    Map<String, int> counts = {};
    for (var entry in allEntries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    return counts;
  }

  String _getMostFrequentMood() {
    final counts = _getMoodCounts();
    if (counts.isEmpty) return 'No data';

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  int _getCurrentStreak() {
    if (allEntries.isEmpty) return 0;

    int streak = 1;
    DateTime lastDate = allEntries.last.timestamp;

    for (int i = allEntries.length - 2; i >= 0; i--) {
      DateTime currentDate = allEntries[i].timestamp;
      if (lastDate.difference(currentDate).inDays == 1) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  List<MoodEntry> _getLastSevenDays() {
    final sevenDaysAgo = DateTime.now().subtract(Duration(days: 7));
    return allEntries
        .where((entry) => entry.timestamp.isAfter(sevenDaysAgo))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Mood Analytics')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final moodCounts = _getMoodCounts();
    final mostFrequentMood = _getMostFrequentMood();
    final currentStreak = _getCurrentStreak();
    final lastSevenDays = _getLastSevenDays();

    return Scaffold(
      appBar: AppBar(title: Text('Mood Analytics')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Entries',
                    allEntries.length.toString(),
                    Icons.edit_note,
                    Colors.blue,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Current Streak',
                    '$currentStreak days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Most Frequent',
                    mostFrequentMood,
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Last 7 Days',
                    '${lastSevenDays.length} entries',
                    Icons.date_range,
                    Colors.purple,
                  ),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Mood Distribution
            Text(
              'Mood Distribution',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (moodCounts.isNotEmpty)
              ...moodCounts.entries
                  .map(
                    (entry) => _buildMoodBar(
                      entry.key,
                      entry.value,
                      allEntries.length,
                    ),
                  )
                  .toList()
            else
              Text('No mood data available'),

            SizedBox(height: 24),

            // Recent Trend
            Text(
              'Recent Activity (Last 7 Days)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            if (lastSevenDays.isNotEmpty)
              Container(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: lastSevenDays.length,
                  itemBuilder: (context, index) {
                    final entry = lastSevenDays[index];
                    return _buildDayCard(entry);
                  },
                ),
              )
            else
              Text('No recent activity'),
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodBar(String mood, int count, int total) {
    double percentage = count / total;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(mood, style: TextStyle(fontSize: 16)),
          ),
          Expanded(
            child: Container(
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: percentage,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getMoodColor(mood),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Text('$count'),
        ],
      ),
    );
  }

  Widget _buildDayCard(MoodEntry entry) {
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 8),
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.mood.split(' ')[0], // Just the emoji
                style: TextStyle(fontSize: 32),
              ),
              SizedBox(height: 8),
              Text(
                '${entry.timestamp.day}/${entry.timestamp.month}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              if (entry.note.isNotEmpty)
                Expanded(
                  child: Text(
                    entry.note,
                    style: TextStyle(fontSize: 10),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getMoodColor(String mood) {
    if (mood.contains('Happy')) return Colors.green;
    if (mood.contains('Sad')) return Colors.blue;
    if (mood.contains('Angry')) return Colors.red;
    if (mood.contains('Anxious')) return Colors.orange;
    return Colors.grey;
  }
}
