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
          .order('created_at', ascending: true);

      setState(() {
        allEntries =
            (response as List).map((json) => MoodEntry.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $error')),
        );
      }
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
        appBar: AppBar(
          title: Text('Analytics'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading your mood insights...'),
            ],
          ),
        ),
      );
    }

    final moodCounts = _getMoodCounts();
    final mostFrequentMood = _getMostFrequentMood();
    final currentStreak = _getCurrentStreak();
    final lastSevenDays = _getLastSevenDays();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Your mood insights',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats Row
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.trending_up,
                        title: 'Total Entries',
                        value: '${allEntries.length}',
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.local_fire_department,
                        title: 'Current Streak',
                        value: '$currentStreak days',
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),

                // Most Frequent Mood
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.favorite,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Most Frequent Mood',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (mostFrequentMood != 'No data')
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  mostFrequentMood.split(' ')[0], // Emoji part
                                  style: TextStyle(fontSize: 32),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mostFrequentMood,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${moodCounts[mostFrequentMood]} times',
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
                          )
                        else
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text('No mood data available'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Mood Distribution
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.pie_chart,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Mood Distribution',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (moodCounts.isNotEmpty)
                          ...moodCounts.entries.map((entry) {
                            final percentage =
                                (entry.value / allEntries.length * 100).round();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text('${entry.value} ($percentage%)'),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: entry.value / allEntries.length,
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getMoodColor(entry.key),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList()
                        else
                          Center(
                            child: Text(
                              'No mood data available',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Recent Activity
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Last 7 Days',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Container(
                          height: 60,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 7,
                            itemBuilder: (context, index) {
                              final date = DateTime.now().subtract(
                                Duration(days: 6 - index),
                              );
                              final dayEntries =
                                  lastSevenDays
                                      .where(
                                        (entry) =>
                                            entry.timestamp.day == date.day &&
                                            entry.timestamp.month == date.month,
                                      )
                                      .toList();

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            dayEntries.isNotEmpty
                                                ? Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child:
                                            dayEntries.isNotEmpty
                                                ? Text(
                                                  dayEntries.last.mood.split(
                                                    ' ',
                                                  )[0], // Emoji
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                  ),
                                                )
                                                : Icon(
                                                  Icons.remove,
                                                  size: 16,
                                                  color:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .onSurfaceVariant,
                                                ),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      [
                                        'S',
                                        'M',
                                        'T',
                                        'W',
                                        'T',
                                        'F',
                                        'S',
                                      ][date.weekday % 7],
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Weekly Summary
                if (lastSevenDays.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
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
                                'Weekly Insights',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          _buildInsightItem(
                            'Entries this week',
                            '${lastSevenDays.length}',
                            Icons.calendar_today,
                          ),
                          _buildInsightItem(
                            'Most active day',
                            _getMostActiveDay(lastSevenDays),
                            Icons.trending_up,
                          ),
                          _buildInsightItem(
                            'Mood consistency',
                            _getMoodConsistency(lastSevenDays),
                            Icons.psychology,
                          ),
                        ],
                      ),
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          SizedBox(width: 12),
          Expanded(child: Text(title)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getMoodColor(String mood) {
    if (mood.contains('Happy') || mood.contains('Excited')) return Colors.green;
    if (mood.contains('Sad') || mood.contains('Tired')) return Colors.blue;
    if (mood.contains('Angry')) return Colors.red;
    if (mood.contains('Anxious')) return Colors.orange;
    if (mood.contains('Calm')) return Colors.purple;
    return Colors.grey;
  }

  String _getMostActiveDay(List<MoodEntry> entries) {
    if (entries.isEmpty) return 'No data';

    Map<int, int> dayCounts = {};
    for (var entry in entries) {
      int day = entry.timestamp.weekday;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
    }

    if (dayCounts.isEmpty) return 'No data';

    int mostActiveDay =
        dayCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[mostActiveDay - 1];
  }

  String _getMoodConsistency(List<MoodEntry> entries) {
    if (entries.length < 2) return 'Not enough data';

    Set<String> uniqueMoods = entries.map((e) => e.mood).toSet();
    double consistency = (7 - uniqueMoods.length) / 6;

    if (consistency > 0.7) return 'Very consistent';
    if (consistency > 0.4) return 'Moderately consistent';
    return 'Varied';
  }
}
