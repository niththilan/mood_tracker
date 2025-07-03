import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'main.dart';

class EnhancedAnalyticsPage extends StatefulWidget {
  @override
  _EnhancedAnalyticsPageState createState() => _EnhancedAnalyticsPageState();
}

class _EnhancedAnalyticsPageState extends State<EnhancedAnalyticsPage>
    with TickerProviderStateMixin {
  List<MoodEntry> allEntries = [];
  bool isLoading = true;
  final supabase = Supabase.instance.client;
  late AnimationController _chartAnimationController;
  int selectedPeriod = 7; // 7 days default

  final List<int> periodOptions = [7, 30, 90];
  final List<String> periodLabels = ['7 Days', '30 Days', '3 Months'];

  @override
  void initState() {
    super.initState();
    _chartAnimationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadAnalytics();
  }

  @override
  void dispose() {
    _chartAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalytics() async {
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
          .order('created_at', ascending: true);

      setState(() {
        allEntries =
            (response as List).map((json) => MoodEntry.fromJson(json)).toList();
        isLoading = false;
      });

      _chartAnimationController.forward();
    } catch (error) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $error')),
        );
      }
    }
  }

  List<MoodEntry> _getFilteredEntries() {
    final cutoffDate = DateTime.now().subtract(Duration(days: selectedPeriod));
    return allEntries
        .where((entry) => entry.timestamp.isAfter(cutoffDate))
        .toList();
  }

  Map<String, int> _getMoodCounts() {
    final filteredEntries = _getFilteredEntries();
    Map<String, int> counts = {};
    for (var entry in filteredEntries) {
      String mood = entry.mood.split(' ').skip(1).join(' '); // Remove emoji
      counts[mood] = (counts[mood] ?? 0) + 1;
    }
    return counts;
  }

  Map<String, double> _getWeeklyTrend() {
    final filteredEntries = _getFilteredEntries();
    Map<String, List<int>> weeklyScores = {};

    // Define mood scores
    Map<String, int> moodScores = {
      'Happy': 5,
      'Excited': 5,
      'Calm': 4,
      'Neutral': 3,
      'Tired': 2,
      'Sad': 1,
      'Angry': 1,
      'Anxious': 1,
    };

    for (var entry in filteredEntries) {
      String weekKey = DateFormat('MM/dd').format(entry.timestamp);
      String mood = entry.mood.split(' ').skip(1).join(' ');
      int score = moodScores[mood] ?? 3;

      if (!weeklyScores.containsKey(weekKey)) {
        weeklyScores[weekKey] = [];
      }
      weeklyScores[weekKey]!.add(score);
    }

    Map<String, double> weeklyAverages = {};
    weeklyScores.forEach((week, scores) {
      weeklyAverages[week] = scores.reduce((a, b) => a + b) / scores.length;
    });

    return weeklyAverages;
  }

  String _getMostFrequentMood() {
    final counts = _getMoodCounts();
    if (counts.isEmpty) return 'No data';

    String mostFrequent =
        counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    return mostFrequent;
  }

  double _getAverageMoodScore() {
    final filteredEntries = _getFilteredEntries();
    if (filteredEntries.isEmpty) return 0;

    Map<String, int> moodScores = {
      'Happy': 5,
      'Excited': 5,
      'Calm': 4,
      'Neutral': 3,
      'Tired': 2,
      'Sad': 1,
      'Angry': 1,
      'Anxious': 1,
    };

    int totalScore = 0;
    for (var entry in filteredEntries) {
      String mood = entry.mood.split(' ').skip(1).join(' ');
      totalScore += moodScores[mood] ?? 3;
    }

    return totalScore / filteredEntries.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Mood Insights',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver:
                isLoading
                    ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Analyzing your mood patterns...'),
                          ],
                        ),
                      ),
                    )
                    : allEntries.isEmpty
                    ? SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No mood data available',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start logging your moods to see insights!',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    : SliverList(
                      delegate: SliverChildListDelegate([
                        AnimationLimiter(
                          child: Column(
                            children: AnimationConfiguration.toStaggeredList(
                              duration: Duration(milliseconds: 600),
                              childAnimationBuilder:
                                  (widget) => SlideAnimation(
                                    verticalOffset: 50.0,
                                    child: FadeInAnimation(child: widget),
                                  ),
                              children: [
                                _buildPeriodSelector(),
                                SizedBox(height: 16),
                                _buildOverviewCards(),
                                SizedBox(height: 24),
                                _buildMoodDistributionChart(),
                                SizedBox(height: 24),
                                _buildMoodTrendChart(),
                                SizedBox(height: 24),
                                _buildInsightsCard(),
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

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children:
                  periodOptions.asMap().entries.map((entry) {
                    int index = entry.key;
                    int period = entry.value;
                    bool isSelected = selectedPeriod == period;

                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          child: FilledButton(
                            onPressed: () {
                              setState(() {
                                selectedPeriod = period;
                              });
                              _chartAnimationController.reset();
                              _chartAnimationController.forward();
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.surfaceContainerHighest,
                              foregroundColor:
                                  isSelected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                            ),
                            child: Text(periodLabels[index]),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    final filteredEntries = _getFilteredEntries();
    final averageScore = _getAverageMoodScore();
    final mostFrequentMood = _getMostFrequentMood();

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Total Entries',
            value: '${filteredEntries.length}',
            icon: Icons.event_note,
            color: Colors.blue,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Average Score',
            value: '${averageScore.toStringAsFixed(1)}/5',
            icon: Icons.trending_up,
            color: Colors.green,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            title: 'Most Common',
            value: mostFrequentMood,
            icon: Icons.mood,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodDistributionChart() {
    final moodCounts = _getMoodCounts();
    if (moodCounts.isEmpty) return SizedBox.shrink();

    final colors = [
      Colors.green,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Distribution',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 200,
              child: AnimatedBuilder(
                animation: _chartAnimationController,
                builder: (context, child) {
                  return PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(enabled: true),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 2,
                      centerSpaceRadius: 60,
                      sections:
                          moodCounts.entries.map((entry) {
                            final index = moodCounts.keys.toList().indexOf(
                              entry.key,
                            );
                            final color = colors[index % colors.length];
                            final total = moodCounts.values.reduce(
                              (a, b) => a + b,
                            );
                            final percentage =
                                (entry.value / total * 100).round();

                            return PieChartSectionData(
                              color: color,
                              value:
                                  entry.value.toDouble() *
                                  _chartAnimationController.value,
                              title: '$percentage%',
                              radius: 50,
                              titleStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            );
                          }).toList(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children:
                  moodCounts.entries.map((entry) {
                    final index = moodCounts.keys.toList().indexOf(entry.key);
                    final color = colors[index % colors.length];

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${entry.key} (${entry.value})',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodTrendChart() {
    final weeklyTrend = _getWeeklyTrend();
    if (weeklyTrend.isEmpty) return SizedBox.shrink();

    final spots =
        weeklyTrend.entries.map((entry) {
          final index = weeklyTrend.keys.toList().indexOf(entry.key);
          return FlSpot(index.toDouble(), entry.value);
        }).toList();

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mood Trend',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 24),
            Container(
              height: 200,
              child: AnimatedBuilder(
                animation: _chartAnimationController,
                builder: (context, child) {
                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(fontSize: 12),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < weeklyTrend.keys.length) {
                                return Text(
                                  weeklyTrend.keys.elementAt(value.toInt()),
                                  style: TextStyle(fontSize: 10),
                                );
                              }
                              return Text('');
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (spots.length - 1).toDouble(),
                      minY: 1,
                      maxY: 5,
                      lineBarsData: [
                        LineChartBarData(
                          spots:
                              spots.map((spot) {
                                return FlSpot(
                                  spot.x,
                                  spot.y * _chartAnimationController.value +
                                      1 * (1 - _chartAnimationController.value),
                                );
                              }).toList(),
                          isCurved: true,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                          ),
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
    );
  }

  Widget _buildInsightsCard() {
    final filteredEntries = _getFilteredEntries();
    final averageScore = _getAverageMoodScore();

    String insight = '';
    IconData insightIcon = Icons.lightbulb_outline;
    Color insightColor = Colors.blue;

    if (filteredEntries.isEmpty) {
      insight = 'Start logging your moods to get personalized insights!';
    } else if (averageScore >= 4) {
      insight =
          'Great job! Your mood has been consistently positive lately. Keep up the good work!';
      insightIcon = Icons.sentiment_very_satisfied;
      insightColor = Colors.green;
    } else if (averageScore >= 3) {
      insight =
          'Your mood seems stable. Consider activities that bring you joy to boost your wellbeing.';
      insightIcon = Icons.sentiment_neutral;
      insightColor = Colors.orange;
    } else {
      insight =
          'It looks like you\'ve been having some tough days. Remember, it\'s okay to reach out for support.';
      insightIcon = Icons.favorite;
      insightColor = Colors.pink;
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(insightIcon, color: insightColor),
                SizedBox(width: 8),
                Text(
                  'Insight',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: insightColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: insightColor.withValues(alpha: 0.2)),
              ),
              child: Text(insight, style: TextStyle(fontSize: 14, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
