import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuickMoodEntry extends StatefulWidget {
  const QuickMoodEntry({super.key});

  @override
  _QuickMoodEntryState createState() => _QuickMoodEntryState();
}

class _QuickMoodEntryState extends State<QuickMoodEntry>
    with TickerProviderStateMixin {
  String? selectedMood;
  String? selectedMoodEmoji;
  int intensity = 5;
  List<String> selectedTags = [];
  TextEditingController noteController = TextEditingController();
  bool isLoading = false;

  late AnimationController _bounceController;
  late AnimationController _intensityController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _intensityAnimation;

  final supabase = Supabase.instance.client;

  final List<Map<String, dynamic>> enhancedMoods = [
    {
      'emoji': '😊',
      'name': 'Happy',
      'description': 'Feeling joyful and content',
      'color': Color(0xFF4CAF50),
      'gradient': [Color(0xFF4CAF50), Color(0xFF8BC34A)],
    },
    {
      'emoji': '😄',
      'name': 'Excited',
      'description': 'Full of energy and enthusiasm',
      'color': Color(0xFFFF9800),
      'gradient': [Color(0xFFFF9800), Color(0xFFFFEB3B)],
    },
    {
      'emoji': '😌',
      'name': 'Calm',
      'description': 'Peaceful and relaxed',
      'color': Color(0xFF00BCD4),
      'gradient': [Color(0xFF00BCD4), Color(0xFF4FC3F7)],
    },
    {
      'emoji': '😐',
      'name': 'Neutral',
      'description': 'Neither good nor bad',
      'color': Color(0xFF9E9E9E),
      'gradient': [Color(0xFF9E9E9E), Color(0xFFBDBDBD)],
    },
    {
      'emoji': '😔',
      'name': 'Sad',
      'description': 'Feeling down or melancholy',
      'color': Color(0xFF2196F3),
      'gradient': [Color(0xFF2196F3), Color(0xFF64B5F6)],
    },
    {
      'emoji': '😠',
      'name': 'Angry',
      'description': 'Frustrated or irritated',
      'color': Color(0xFFF44336),
      'gradient': [Color(0xFFF44336), Color(0xFFE57373)],
    },
    {
      'emoji': '😨',
      'name': 'Anxious',
      'description': 'Worried or stressed',
      'color': Color(0xFF9C27B0),
      'gradient': [Color(0xFF9C27B0), Color(0xFFBA68C8)],
    },
    {
      'emoji': '😴',
      'name': 'Tired',
      'description': 'Exhausted or sleepy',
      'color': Color(0xFF607D8B),
      'gradient': [Color(0xFF607D8B), Color(0xFF90A4AE)],
    },
  ];

  final List<String> moodTags = [
    'Work',
    'Family',
    'Friends',
    'Health',
    'Exercise',
    'Sleep',
    'Weather',
    'Food',
    'Social',
    'Alone',
    'Stress',
    'Relaxation',
    'Achievement',
    'Challenge',
    'Creativity',
    'Nature',
    'Music',
    'Learning',
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );
    _intensityController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.elasticOut),
    );

    _intensityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _intensityController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _intensityController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> _saveMoodEntry() async {
    if (selectedMood == null) return;

    setState(() => isLoading = true);
    HapticFeedback.heavyImpact();

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
        'intensity': intensity,
        'note': noteController.text,
        'created_at': DateTime.now().toIso8601String(),
      };

      await supabase.from('mood_entries').insert(newEntry);

      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Mood saved successfully! 🎉')),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to history or analytics
              },
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
                Expanded(child: Text('Failed to save mood: $error')),
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

  void _selectMood(Map<String, dynamic> mood) {
    HapticFeedback.mediumImpact();
    setState(() {
      selectedMood = mood['name'];
      selectedMoodEmoji = mood['emoji'];
    });

    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    _intensityController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient:
              selectedMood != null
                  ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors:
                        enhancedMoods.firstWhere(
                          (m) => m['name'] == selectedMood,
                        )['gradient'],
                    stops: [0.0, 1.0],
                  )
                  : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                    ],
                  ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(
                        Icons.close,
                        color: selectedMood != null ? Colors.white : null,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor:
                            selectedMood != null
                                ? Colors.white.withValues(alpha: 0.2)
                                : Theme.of(context).colorScheme.surfaceContainerHighest,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'How are you feeling?',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: selectedMood != null ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 48), // Balance for the close button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: AnimationLimiter(
                    child: Column(
                      children: AnimationConfiguration.toStaggeredList(
                        duration: Duration(milliseconds: 600),
                        childAnimationBuilder:
                            (widget) => SlideAnimation(
                              verticalOffset: 50.0,
                              child: FadeInAnimation(child: widget),
                            ),
                        children: [
                          _buildMoodGrid(),
                          if (selectedMood != null) ...[
                            SizedBox(height: 32),
                            _buildIntensitySlider(),
                            SizedBox(height: 32),
                            _buildTagsSection(),
                            SizedBox(height: 32),
                            _buildNotesSection(),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Save button
              if (selectedMood != null)
                Container(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveMoodEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                            enhancedMoods.firstWhere(
                              (m) => m['name'] == selectedMood,
                            )['color'],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 8,
                      ),
                      child:
                          isLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save),
                                  SizedBox(width: 8),
                                  Text(
                                    'Save Mood Entry',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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

  Widget _buildMoodGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemCount: enhancedMoods.length,
      itemBuilder: (context, index) {
        final mood = enhancedMoods[index];
        final isSelected = selectedMood == mood['name'];

        return AnimatedBuilder(
          animation: _bounceAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isSelected ? _bounceAnimation.value : 1.0,
              child: GestureDetector(
                onTap: () => _selectMood(mood),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient:
                        isSelected
                            ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: mood['gradient'],
                            )
                            : null,
                    color: isSelected ? null : Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color:
                            isSelected
                                ? mood['color'].withValues(alpha: 0.4)
                                : Colors.black.withValues(alpha: 0.1),
                        blurRadius: isSelected ? 20 : 10,
                        offset: Offset(0, isSelected ? 8 : 4),
                      ),
                    ],
                    border:
                        isSelected
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood['emoji'], style: TextStyle(fontSize: 48)),
                      SizedBox(height: 8),
                      Text(
                        mood['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          mood['description'],
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isSelected
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildIntensitySlider() {
    return AnimatedBuilder(
      animation: _intensityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _intensityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _intensityAnimation.value)),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                      Icon(Icons.tune, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'Intensity Level',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Text('Mild', style: TextStyle(color: Colors.black54)),
                      Expanded(
                        child: Slider(
                          value: intensity.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: intensity.toString(),
                          activeColor:
                              enhancedMoods.firstWhere(
                                (m) => m['name'] == selectedMood,
                              )['color'],
                          onChanged: (value) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              intensity = value.round();
                            });
                          },
                        ),
                      ),
                      Text('Intense', style: TextStyle(color: Colors.black54)),
                    ],
                  ),
                  Center(
                    child: Text(
                      'Level $intensity/10',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color:
                            enhancedMoods.firstWhere(
                              (m) => m['name'] == selectedMood,
                            )['color'],
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
  }

  Widget _buildTagsSection() {
    return AnimatedBuilder(
      animation: _intensityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _intensityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _intensityAnimation.value)),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                      Icon(Icons.label_outline, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'What influenced this mood?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        moodTags.map((tag) {
                          final isSelected = selectedTags.contains(tag);
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (selected) {
                              HapticFeedback.selectionClick();
                              setState(() {
                                if (selected) {
                                  selectedTags.add(tag);
                                } else {
                                  selectedTags.remove(tag);
                                }
                              });
                            },
                            selectedColor: enhancedMoods
                                .firstWhere(
                                  (m) => m['name'] == selectedMood,
                                )['color']
                                .withValues(alpha: 0.2),
                            checkmarkColor:
                                enhancedMoods.firstWhere(
                                  (m) => m['name'] == selectedMood,
                                )['color'],
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotesSection() {
    return AnimatedBuilder(
      animation: _intensityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _intensityAnimation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - _intensityAnimation.value)),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
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
                      Icon(Icons.edit_note, color: Colors.black87),
                      SizedBox(width: 8),
                      Text(
                        'Add a note (optional)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: noteController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText:
                          'What\'s on your mind? How are you feeling right now?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color:
                              enhancedMoods.firstWhere(
                                (m) => m['name'] == selectedMood,
                              )['color'],
                          width: 2,
                        ),
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
  }
}
