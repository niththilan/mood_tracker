import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'main.dart';

class MoodJournal extends StatefulWidget {
  @override
  _MoodJournalState createState() => _MoodJournalState();
}

class _MoodJournalState extends State<MoodJournal>
    with TickerProviderStateMixin {
  List<MoodEntry> entries = [];
  List<MoodEntry> filteredEntries = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  TextEditingController searchController = TextEditingController();
  late AnimationController _listAnimationController;

  final supabase = Supabase.instance.client;
  final List<String> filterOptions = [
    'All',
    'Happy',
    'Sad',
    'Angry',
    'Calm',
    'Excited',
    'Anxious',
    'Tired',
    'Neutral',
  ];

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadEntries();
    searchController.addListener(_filterEntries);
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
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

      setState(() {
        entries =
            (response as List).map((json) => MoodEntry.fromJson(json)).toList();
        _filterEntries();
        isLoading = false;
      });

      _listAnimationController.forward();
    } catch (error) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading journal: $error')),
        );
      }
    }
  }

  void _filterEntries() {
    List<MoodEntry> filtered = entries;

    // Filter by mood type
    if (selectedFilter != 'All') {
      filtered =
          filtered
              .where(
                (entry) => entry.mood.toLowerCase().contains(
                  selectedFilter.toLowerCase(),
                ),
              )
              .toList();
    }

    // Filter by search text
    if (searchController.text.isNotEmpty) {
      filtered =
          filtered
              .where(
                (entry) =>
                    entry.mood.toLowerCase().contains(
                      searchController.text.toLowerCase(),
                    ) ||
                    entry.note.toLowerCase().contains(
                      searchController.text.toLowerCase(),
                    ),
              )
              .toList();
    }

    setState(() {
      filteredEntries = filtered;
    });
  }

  Map<String, List<MoodEntry>> _groupEntriesByDate() {
    Map<String, List<MoodEntry>> grouped = {};
    for (var entry in filteredEntries) {
      String dateKey = DateFormat('EEEE, MMMM d, y').format(entry.timestamp);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(entry);
    }
    return grouped;
  }

  Color _getMoodColor(String mood) {
    if (mood.contains('Happy') || mood.contains('Excited')) return Colors.green;
    if (mood.contains('Sad')) return Colors.blue;
    if (mood.contains('Angry')) return Colors.red;
    if (mood.contains('Calm')) return Colors.teal;
    if (mood.contains('Anxious')) return Colors.purple;
    if (mood.contains('Tired')) return Colors.grey;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final groupedEntries = _groupEntriesByDate();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Mood Journal',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: MoodSearchDelegate(entries),
                  );
                },
              ),
            ],
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              selectedFilter: selectedFilter,
              filterOptions: filterOptions,
              onFilterChanged: (filter) {
                setState(() {
                  selectedFilter = filter;
                });
                _filterEntries();
              },
              searchController: searchController,
            ),
          ),
          if (isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading your mood journal...'),
                  ],
                ),
              ),
            )
          else if (filteredEntries.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.book_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No entries found',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Try adjusting your filters or start logging moods!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final dateKeys = groupedEntries.keys.toList();
                final dateKey = dateKeys[index];
                final dayEntries = groupedEntries[dateKey]!;

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: Duration(milliseconds: 600),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: _buildDaySection(dateKey, dayEntries),
                    ),
                  ),
                );
              }, childCount: groupedEntries.length),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySection(String date, List<MoodEntry> dayEntries) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              date,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          SizedBox(height: 12),
          ...dayEntries.map((entry) => _buildJournalEntry(entry)),
        ],
      ),
    );
  }

  Widget _buildJournalEntry(MoodEntry entry) {
    final moodColor = _getMoodColor(entry.mood);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [moodColor.withValues(alpha: 0.05), moodColor.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: moodColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: moodColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.mood.split(' ')[0], // Emoji
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.mood.split(' ').skip(1).join(' '), // Mood name
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: moodColor,
                        ),
                      ),
                      Text(
                        DateFormat('h:mm a').format(entry.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (entry.note.isNotEmpty) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.note,
                  style: TextStyle(fontSize: 14, height: 1.4),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String selectedFilter;
  final List<String> filterOptions;
  final Function(String) onFilterChanged;
  final TextEditingController searchController;

  _FilterHeaderDelegate({
    required this.selectedFilter,
    required this.filterOptions,
    required this.onFilterChanged,
    required this.searchController,
  });

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search your moods and notes...',
              prefixIcon: Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          SizedBox(height: 8),
          // Filter chips
          SizedBox(
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: filterOptions.length,
              itemBuilder: (context, index) {
                final filter = filterOptions[index];
                final isSelected = selectedFilter == filter;

                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter, style: TextStyle(fontSize: 12)),
                    selected: isSelected,
                    onSelected: (selected) => onFilterChanged(filter),
                    selectedColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 100;

  @override
  double get minExtent => 100;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) {
    return true;
  }
}

class MoodSearchDelegate extends SearchDelegate<MoodEntry?> {
  final List<MoodEntry> entries;

  MoodSearchDelegate(this.entries);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredEntries =
        entries
            .where(
              (entry) =>
                  entry.mood.toLowerCase().contains(query.toLowerCase()) ||
                  entry.note.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    return ListView.builder(
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return ListTile(
          leading: CircleAvatar(child: Text(entry.mood.split(' ')[0])),
          title: Text(entry.mood),
          subtitle: Text(
            entry.note.isEmpty ? 'No note' : entry.note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            DateFormat('MMM d').format(entry.timestamp),
            style: TextStyle(fontSize: 12),
          ),
          onTap: () => close(context, entry),
        );
      },
    );
  }
}
