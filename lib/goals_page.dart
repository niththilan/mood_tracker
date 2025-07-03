import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MoodCategory {
  final int id;
  final String name;
  final String emoji;
  final String colorHex;
  final int moodScore;
  final String? description;

  MoodCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorHex,
    required this.moodScore,
    this.description,
  });

  factory MoodCategory.fromJson(Map<String, dynamic> json) {
    return MoodCategory(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      colorHex: json['color_hex'],
      moodScore: json['mood_score'],
      description: json['description'],
    );
  }

  String get displayName => '$emoji $name';
}

class Goal {
  final String id;
  final String title;
  final String description;
  final int targetDays;
  final MoodCategory? targetMoodCategory;
  final int targetMoodCategoryId;
  final int currentProgress;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  Goal({
    required this.id,
    required this.title,
    required this.description,
    required this.targetDays,
    this.targetMoodCategory,
    required this.targetMoodCategoryId,
    required this.currentProgress,
    required this.isCompleted,
    required this.createdAt,
    this.completedAt,
  });

  factory Goal.fromJson(Map<String, dynamic> json) {
    return Goal(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      targetDays: json['target_days'],
      targetMoodCategory:
          json['mood_categories'] != null
              ? MoodCategory.fromJson(json['mood_categories'])
              : null,
      targetMoodCategoryId: json['target_mood_category_id'],
      currentProgress: json['current_progress'] ?? 0,
      isCompleted: json['is_completed'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      completedAt:
          json['completed_at'] != null
              ? DateTime.parse(json['completed_at'])
              : null,
    );
  }
}

class GoalsPage extends StatefulWidget {
  @override
  _GoalsPageState createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> with TickerProviderStateMixin {
  List<Goal> goals = [];
  List<MoodCategory> moodCategories = [];
  bool isLoading = true;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadMoodCategories(), _loadGoals()]);
  }

  Future<void> _loadMoodCategories() async {
    try {
      final response = await supabase
          .from('mood_categories')
          .select()
          .order('name');

      setState(() {
        moodCategories =
            (response as List)
                .map((json) => MoodCategory.fromJson(json))
                .toList();
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading mood categories: $error')),
      );
    }
  }

  Future<void> _loadGoals() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          goals = [];
          isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('mood_goals')
          .select('*, mood_categories(*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        goals = (response as List).map((json) => Goal.fromJson(json)).toList();
        isLoading = false;
      });
    } catch (error) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading goals: $error')));
    }
  }

  Future<void> _createGoal(
    String title,
    String description,
    int targetDays,
    int targetMoodCategoryId,
  ) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please log in to create goals')),
        );
        return;
      }

      await supabase.from('mood_goals').insert({
        'user_id': user.id,
        'title': title,
        'description': description,
        'target_days': targetDays,
        'target_mood_category_id': targetMoodCategoryId,
      });

      _loadGoals(); // Refresh the list
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Goal created successfully!')));
    } catch (error) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating goal: $error')));
    }
  }

  void _showCreateGoalDialog() {
    // Check if user is authenticated
    if (supabase.auth.currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please log in to create goals')));
      return;
    }

    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    MoodCategory? selectedMoodCategory =
        moodCategories.isNotEmpty ? moodCategories.first : null;
    int targetDays = 7;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Create New Goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(labelText: 'Goal Title'),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<MoodCategory>(
                    value: selectedMoodCategory,
                    decoration: InputDecoration(labelText: 'Target Mood'),
                    items:
                        moodCategories
                            .map(
                              (category) => DropdownMenuItem(
                                value: category,
                                child: Text(category.displayName),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => selectedMoodCategory = value,
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: targetDays,
                    decoration: InputDecoration(labelText: 'Target Days'),
                    items:
                        [3, 7, 14, 21, 30]
                            .map(
                              (days) => DropdownMenuItem(
                                value: days,
                                child: Text('$days days'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) => targetDays = value!,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (titleController.text.isNotEmpty &&
                      selectedMoodCategory != null) {
                    _createGoal(
                      titleController.text,
                      descriptionController.text,
                      targetDays,
                      selectedMoodCategory!.id,
                    );
                    Navigator.pop(context);
                  }
                },
                child: Text('Create'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Goals & Achievements')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Goals & Achievements'),
        actions: [
          IconButton(icon: Icon(Icons.add), onPressed: _showCreateGoalDialog),
        ],
      ),
      body:
          goals.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.flag, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No goals yet'),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _showCreateGoalDialog,
                      child: Text('Create Your First Goal'),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  final goal = goals[index];
                  return _buildGoalCard(goal);
                },
              ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    double progress = goal.currentProgress / goal.targetDays;
    if (progress > 1.0) progress = 1.0;

    final targetMoodDisplay =
        goal.targetMoodCategory?.displayName ?? 'Unknown Mood';
    final targetMoodEmoji = goal.targetMoodCategory?.emoji ?? '😐';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(targetMoodEmoji, style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration:
                          goal.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (goal.isCompleted)
                  Icon(Icons.check_circle, color: Colors.green),
              ],
            ),
            if (goal.description.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(goal.description, style: TextStyle(color: Colors.grey[600])),
            ],
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      goal.isCompleted ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text('${goal.currentProgress}/${goal.targetDays}'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Target: $targetMoodDisplay',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  goal.isCompleted
                      ? 'Completed!'
                      : '${(progress * 100).round()}% complete',
                  style: TextStyle(
                    fontSize: 12,
                    color: goal.isCompleted ? Colors.green : Colors.grey[600],
                    fontWeight: goal.isCompleted ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
