import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';

class WellnessCenter extends StatefulWidget {
  @override
  _WellnessCenterState createState() => _WellnessCenterState();
}

class _WellnessCenterState extends State<WellnessCenter>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  int selectedCategoryIndex = 0;

  final List<WellnessCategory> categories = [
    WellnessCategory(
      name: 'Daily Quotes',
      icon: Icons.format_quote,
      color: Color(0xFF6366F1),
      content: dailyQuotes,
    ),
    WellnessCategory(
      name: 'Breathing Exercises',
      icon: Icons.air,
      color: Color(0xFF10B981),
      content: breathingExercises,
    ),
    WellnessCategory(
      name: 'Mindfulness Tips',
      icon: Icons.self_improvement,
      color: Color(0xFFF59E0B),
      content: mindfulnessTips,
    ),
    WellnessCategory(
      name: 'Mood Boosters',
      icon: Icons.favorite,
      color: Color(0xFFEC4899),
      content: moodBoosters,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Wellness Center',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            actions: [
              IconButton(
                icon: Icon(Icons.shuffle),
                onPressed: () {
                  setState(() {
                    // Shuffle content for random inspiration
                  });
                },
                tooltip: 'Shuffle Content',
              ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
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
                        _buildCategorySelector(),
                        SizedBox(height: 24),
                        _buildContentGrid(),
                        SizedBox(height: 24),
                        _buildResourcesSection(),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_pulseController.value * 0.1),
            child: FloatingActionButton(
              onPressed: () => _showRandomInspiration(),
              child: AnimatedBuilder(
                animation: _rotationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationController.value * 2 * pi,
                    child: Icon(Icons.auto_awesome),
                  );
                },
              ),
              tooltip: 'Random Inspiration',
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = selectedCategoryIndex == index;

          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            margin: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedCategoryIndex = index;
                });
              },
              child: Container(
                width: 100,
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              category.color,
                              category.color.withOpacity(0.7),
                            ],
                          )
                          : null,
                  color:
                      isSelected
                          ? null
                          : Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: category.color.withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ]
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      category.icon,
                      size: 32,
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(height: 8),
                    Text(
                      category.name,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isSelected
                                ? Colors.white
                                : Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
    );
  }

  Widget _buildContentGrid() {
    final selectedCategory = categories[selectedCategoryIndex];

    return AnimationLimiter(
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 2.5,
          mainAxisSpacing: 16,
        ),
        itemCount: selectedCategory.content.length,
        itemBuilder: (context, index) {
          final item = selectedCategory.content[index];

          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: Duration(milliseconds: 600),
            columnCount: 1,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildContentCard(item, selectedCategory.color),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentCard(WellnessContent content, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(content.icon, color: color, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    content.title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Expanded(
              child: Text(
                content.description,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            if (content.action != null) ...[
              SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: content.action,
                  icon: Icon(Icons.play_arrow, size: 16),
                  label: Text('Try It'),
                  style: TextButton.styleFrom(foregroundColor: color),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_library,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Text(
                  'Additional Resources',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...wellnessResources.map(
              (resource) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: resource.color.withOpacity(0.2),
                  child: Icon(resource.icon, color: resource.color),
                ),
                title: Text(resource.title),
                subtitle: Text(resource.description),
                trailing: Icon(Icons.open_in_new),
                onTap: () => _launchURL(resource.url),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRandomInspiration() {
    final allContent = categories.expand((cat) => cat.content).toList();
    final randomContent = allContent[Random().nextInt(allContent.length)];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.amber),
                SizedBox(width: 8),
                Text('Random Inspiration'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  randomContent.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Text(randomContent.description),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
              if (randomContent.action != null)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    randomContent.action!();
                  },
                  child: Text('Try It'),
                ),
            ],
          ),
    );
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class WellnessCategory {
  final String name;
  final IconData icon;
  final Color color;
  final List<WellnessContent> content;

  WellnessCategory({
    required this.name,
    required this.icon,
    required this.color,
    required this.content,
  });
}

class WellnessContent {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback? action;

  WellnessContent({
    required this.title,
    required this.description,
    required this.icon,
    this.action,
  });
}

class WellnessResource {
  final String title;
  final String description;
  final String url;
  final IconData icon;
  final Color color;

  WellnessResource({
    required this.title,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
  });
}

// Content data
final List<WellnessContent> dailyQuotes = [
  WellnessContent(
    title: "Mindful Moments",
    description:
        "\"The present moment is the only time over which we have dominion.\" - Thích Nhất Hạnh",
    icon: Icons.psychology,
  ),
  WellnessContent(
    title: "Growth Mindset",
    description:
        "\"What we plant in the soil of contemplation, we shall reap in the harvest of action.\" - Meister Eckhart",
    icon: Icons.emoji_nature,
  ),
  WellnessContent(
    title: "Self-Compassion",
    description:
        "\"Be kind to yourself. You're doing the best you can with what you have right now.\"",
    icon: Icons.favorite_outline,
  ),
  WellnessContent(
    title: "Resilience",
    description:
        "\"You are braver than you believe, stronger than you seem, and smarter than you think.\" - A.A. Milne",
    icon: Icons.security,
  ),
];

final List<WellnessContent> breathingExercises = [
  WellnessContent(
    title: "4-7-8 Breathing",
    description:
        "Inhale for 4 counts, hold for 7 counts, exhale for 8 counts. This technique helps reduce anxiety and promotes relaxation.",
    icon: Icons.air,
    action: () {
      // Could implement a breathing exercise timer
    },
  ),
  WellnessContent(
    title: "Box Breathing",
    description:
        "Inhale for 4, hold for 4, exhale for 4, hold for 4. Used by Navy SEALs for stress management.",
    icon: Icons.crop_square,
    action: () {
      // Could implement a breathing exercise timer
    },
  ),
  WellnessContent(
    title: "Belly Breathing",
    description:
        "Place one hand on chest, one on belly. Breathe so only the belly hand moves. This activates the parasympathetic nervous system.",
    icon: Icons.monitor_heart,
  ),
];

final List<WellnessContent> mindfulnessTips = [
  WellnessContent(
    title: "5-4-3-2-1 Grounding",
    description:
        "Notice 5 things you see, 4 things you can touch, 3 things you hear, 2 things you smell, 1 thing you taste.",
    icon: Icons.psychology,
  ),
  WellnessContent(
    title: "Mindful Walking",
    description:
        "Focus on each step, the feeling of your feet touching the ground, and your surroundings.",
    icon: Icons.directions_walk,
  ),
  WellnessContent(
    title: "Body Scan",
    description:
        "Slowly focus on each part of your body from head to toe, noticing any sensations without judgment.",
    icon: Icons.accessibility_new,
  ),
];

final List<WellnessContent> moodBoosters = [
  WellnessContent(
    title: "Gratitude Practice",
    description:
        "Write down 3 things you're grateful for today, no matter how small they may seem.",
    icon: Icons.favorite,
  ),
  WellnessContent(
    title: "Movement Therapy",
    description:
        "Even 5 minutes of dancing, stretching, or walking can boost endorphins and improve your mood.",
    icon: Icons.fitness_center,
  ),
  WellnessContent(
    title: "Connect with Nature",
    description:
        "Spend time outdoors, tend to plants, or even look at nature photos to reduce stress hormones.",
    icon: Icons.nature,
  ),
  WellnessContent(
    title: "Creative Expression",
    description:
        "Draw, write, sing, or create something. Creative activities activate the brain's reward center.",
    icon: Icons.palette,
  ),
];

final List<WellnessResource> wellnessResources = [
  WellnessResource(
    title: "Crisis Text Line",
    description: "Text HOME to 741741 for free, 24/7 crisis support",
    url: "https://www.crisistextline.org/",
    icon: Icons.chat,
    color: Colors.red,
  ),
  WellnessResource(
    title: "Headspace",
    description: "Guided meditation and mindfulness app",
    url: "https://www.headspace.com/",
    icon: Icons.self_improvement,
    color: Colors.orange,
  ),
  WellnessResource(
    title: "Mental Health America",
    description: "Mental health resources and screening tools",
    url: "https://www.mhanational.org/",
    icon: Icons.health_and_safety,
    color: Colors.green,
  ),
];
