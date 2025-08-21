// lib/screens/quiz/quiz_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_data.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/widgets/common/gradient_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fitsyncgemini/providers/providers.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _quizStep = 0;
  Map<String, String> _quizAnswers = {};

  void _nextStep() {
    setState(() {
      _quizStep++;
    });
  }

  void _previousStep() {
    if (_quizStep > 0) {
      setState(() {
        _quizStep--;
      });
    } else {
      context.go('/onboarding');
    }
  }

  void _selectAnswer(String answer) {
    // Store the answer based on current question
    // _quizStep is 1-based for questions, so subtract 1 to get 0-based index
    final question = quizQuestions[_quizStep - 1];
    final questionKey = _getQuestionKey(question.question);
    _quizAnswers[questionKey] = answer;

    // Move to next question
    _nextStep();
  }

  String _getQuestionKey(String question) {
    // Map questions to backend keys
    if (question.contains('weekend outfit')) return 'weekend_outfit';
    if (question.contains('color palette')) return 'color_palette';
    if (question.contains('shoe style')) return 'shoe_style';
    if (question.contains('accessories')) return 'accessories';
    if (question.contains('print')) return 'print_preference';
    return 'question_${_quizStep + 1}';
  }

  String _getAssignedArchetype() {
    // Simple logic to determine archetype based on answers
    // This is a simplified version - the backend will do the actual analysis
    int minimalistScore = 0;
    int classicScore = 0;
    int bohemianScore = 0;
    int streetwearScore = 0;
    int romanticScore = 0;
    int naturalScore = 0;
    int dramaticScore = 0;
    int elegantScore = 0;
    int gamineScore = 0;
    int creativeScore = 0;

    // Analyze answers
    _quizAnswers.forEach((key, value) {
      if (value.toLowerCase().contains('comfortable jeans')) {
        naturalScore += 2;
        minimalistScore += 1;
      } else if (value.toLowerCase().contains('flowy dress')) {
        romanticScore += 2;
        bohemianScore += 1;
      } else if (value.toLowerCase().contains('tailored pants')) {
        classicScore += 2;
        elegantScore += 1;
      } else if (value.toLowerCase().contains('athleisure')) {
        streetwearScore += 2;
        naturalScore += 1;
      } else if (value.toLowerCase().contains('neutral tones')) {
        minimalistScore += 2;
        classicScore += 1;
      } else if (value.toLowerCase().contains('earthy and warm')) {
        naturalScore += 2;
        bohemianScore += 1;
      } else if (value.toLowerCase().contains('bright and bold')) {
        dramaticScore += 2;
        creativeScore += 1;
      } else if (value.toLowerCase().contains('pastels and soft')) {
        romanticScore += 2;
        elegantScore += 1;
      } else if (value.toLowerCase().contains('classic leather')) {
        classicScore += 2;
        elegantScore += 1;
      } else if (value.toLowerCase().contains('strappy sandals')) {
        romanticScore += 2;
        bohemianScore += 1;
      } else if (value.toLowerCase().contains('minimalist sneakers')) {
        minimalistScore += 2;
        streetwearScore += 1;
      } else if (value.toLowerCase().contains('statement heels')) {
        dramaticScore += 2;
        creativeScore += 1;
      } else if (value.toLowerCase().contains('less is more')) {
        minimalistScore += 2;
        classicScore += 1;
      } else if (value.toLowerCase().contains('layered and eclectic')) {
        bohemianScore += 2;
        creativeScore += 1;
      } else if (value.toLowerCase().contains('bold architectural')) {
        dramaticScore += 2;
        elegantScore += 1;
      } else if (value.toLowerCase().contains('no accessories')) {
        minimalistScore += 2;
        naturalScore += 1;
      } else if (value.toLowerCase().contains('solid colors')) {
        minimalistScore += 2;
        classicScore += 1;
      } else if (value.toLowerCase().contains('floral or paisley')) {
        romanticScore += 2;
        bohemianScore += 1;
      } else if (value.toLowerCase().contains('geometric or abstract')) {
        creativeScore += 2;
        dramaticScore += 1;
      } else if (value.toLowerCase().contains('animal print')) {
        dramaticScore += 2;
        streetwearScore += 1;
      }
    });

    // Find the archetype with the highest score
    final scores = {
      'minimalist': minimalistScore,
      'classic': classicScore,
      'bohemian': bohemianScore,
      'streetwear': streetwearScore,
      'romantic': romanticScore,
      'natural': naturalScore,
      'dramatic': dramaticScore,
      'elegant': elegantScore,
      'gamine': gamineScore,
      'creative': creativeScore,
    };

    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  Map<String, dynamic> _getArchetypeInfo(String archetype) {
    final archetypeData = {
      'minimalist': {
        'name': 'Minimalist',
        'description':
            'You appreciate clean lines, neutral colors, and timeless pieces that never go out of style.',
        'traits': ['Timeless', 'Clean', 'Neutral'],
      },
      'classic': {
        'name': 'Classic',
        'description':
            'You prefer sophisticated, well-tailored pieces that exude elegance and professionalism.',
        'traits': ['Sophisticated', 'Tailored', 'Elegant'],
      },
      'bohemian': {
        'name': 'Bohemian',
        'description':
            'You love free-spirited, artistic pieces with rich textures and eclectic patterns.',
        'traits': ['Free-spirited', 'Artistic', 'Eclectic'],
      },
      'streetwear': {
        'name': 'Streetwear',
        'description':
            'You embrace urban culture with comfortable, trendy pieces that make a statement.',
        'traits': ['Urban', 'Trendy', 'Comfortable'],
      },
      'romantic': {
        'name': 'Romantic',
        'description':
            'You gravitate toward soft, feminine pieces with delicate details and flowing silhouettes.',
        'traits': ['Feminine', 'Soft', 'Delicate'],
      },
      'natural': {
        'name': 'Natural',
        'description':
            'You prefer comfortable, earthy pieces that reflect your relaxed and down-to-earth personality.',
        'traits': ['Comfortable', 'Earthy', 'Relaxed'],
      },
      'dramatic': {
        'name': 'Dramatic',
        'description':
            'You love bold, statement-making pieces that command attention and express confidence.',
        'traits': ['Bold', 'Confident', 'Statement'],
      },
      'elegant': {
        'name': 'Elegant',
        'description':
            'You choose refined, sophisticated pieces that showcase your polished and refined taste.',
        'traits': ['Refined', 'Sophisticated', 'Polished'],
      },
      'gamine': {
        'name': 'Gamine',
        'description':
            'You prefer playful, youthful pieces with a mix of classic and trendy elements.',
        'traits': ['Playful', 'Youthful', 'Versatile'],
      },
      'creative': {
        'name': 'Creative',
        'description':
            'You love unique, artistic pieces that showcase your individuality and creative spirit.',
        'traits': ['Unique', 'Artistic', 'Individual'],
      },
    };

    return archetypeData[archetype] ?? archetypeData['minimalist']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.quizGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: _buildQuizContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  LucideIcons.chevronLeft,
                  color: Colors.white70,
                ),
                onPressed: _previousStep,
              ),
              Text(
                _quizStep == 0
                    ? 'Style Quiz'
                    : _quizStep > 0 && _quizStep <= quizQuestions.length
                    ? 'Question $_quizStep of ${quizQuestions.length}'
                    : 'Quiz Complete',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(width: 48), // For alignment
            ],
          ),
          if (_quizStep > 0 && _quizStep < quizQuestions.length + 1)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                value: _quizStep / quizQuestions.length,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 5,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizContent() {
    if (_quizStep == 0) {
      return _buildIntroCard();
    } else if (_quizStep > 0 && _quizStep < quizQuestions.length + 1) {
      return _buildQuestionCard();
    } else {
      return _buildResultCard();
    }
  }

  Widget _buildIntroCard() {
    return Center(
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: AppColors.fitsyncGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.sparkles,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Discover Your Style DNA',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Answer a few questions to unlock personalized fashion recommendations tailored just for you.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              GradientButton(
                onPressed: _nextStep,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Start Style Quiz'),
                    SizedBox(width: 8),
                    Icon(LucideIcons.arrowRight, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildQuestionCard() {
    final question = quizQuestions[_quizStep - 1];
    return Center(
      child: Card(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                question.question,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ...question.options
                  .map(
                    (option) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: OutlinedButton(
                        onPressed: () => _selectAnswer(option),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Text(
                          option,
                          style: const TextStyle(fontWeight: FontWeight.normal),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildResultCard() {
    return Consumer(
      builder: (context, ref, child) {
        // Get the assigned archetype from quiz answers (default to minimalist)
        final assignedArchetype = _getAssignedArchetype();
        final archetypeInfo = _getArchetypeInfo(assignedArchetype);

        return Center(
          child: Card(
            color: Colors.white.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    'Your Style Archetype',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          archetypeInfo['name'],
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          archetypeInfo['description'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List<Widget>.from(
                            (archetypeInfo['traits'] as List).map(
                              (trait) => Chip(
                                label: Text(
                                  trait.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: Colors.transparent,
                                shape: StadiumBorder(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: () async {
                      print('🎯 Quiz completion button pressed');

                      // ✅ Get the auth view model
                      final authVM = ref.read(authViewModelProvider.notifier);
                      final currentAuthState = ref.read(authViewModelProvider);

                      print('🔍 Current auth state before completion:');
                      print(
                        '  - isAuthenticated: ${currentAuthState.isAuthenticated}',
                      );
                      print(
                        '  - hasCompletedOnboarding: ${currentAuthState.hasCompletedOnboarding}',
                      );

                      try {
                        // Simulate quiz completion delay
                        print('⏳ Simulating quiz completion delay...');
                        await Future.delayed(
                          const Duration(milliseconds: 1500),
                        );

                        // Show success message with archetype
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✨ You\'re a ${archetypeInfo['name']}! Your style preferences have been saved.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // 🔐 Mark onboarding as completed
                        print('📝 Marking onboarding as completed...');
                        await authVM.completeOnboarding();
                        print('✅ Onboarding marked as completed');

                        // Debug: Check auth service state
                        final authService = ref.read(authServiceProvider);
                        await authService.debugAuthStatus();

                        // Check state after completion
                        final newAuthState = ref.read(authViewModelProvider);
                        print('🔍 Auth state after completion:');
                        print(
                          '  - isAuthenticated: ${newAuthState.isAuthenticated}',
                        );
                        print(
                          '  - hasCompletedOnboarding: ${newAuthState.hasCompletedOnboarding}',
                        );

                        // Wait a moment for state to propagate
                        print('⏳ Waiting for state propagation...');
                        await Future.delayed(const Duration(milliseconds: 500));

                        // ✅ Navigate to dashboard - simplified approach
                        print('🚀 Navigating to dashboard...');
                        if (mounted) {
                          print('✅ Widget is still mounted, navigating...');
                          context.go('/dashboard');
                          print('✅ Navigation command sent');
                        } else {
                          print('❌ Widget is not mounted, cannot navigate');
                        }
                      } catch (e) {
                        print('❌ Error completing quiz: $e');

                        // If there's an error, still complete onboarding locally
                        print(
                          '📝 Completing onboarding locally due to error...',
                        );
                        await authVM.completeOnboarding();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '⚠️ Quiz completed locally. Some features may be limited.',
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );

                        // Navigate to dashboard anyway
                        if (mounted) {
                          print('🚀 Navigating to dashboard after error...');
                          context.go('/dashboard');
                        }
                      }
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Complete Quiz'),
                        SizedBox(width: 8),
                        Icon(LucideIcons.check, size: 16),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Test navigation button
                  OutlinedButton(
                    onPressed: () {
                      print('🧪 Test navigation button pressed');
                      context.go('/dashboard');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: const Text('Test Navigation to Dashboard'),
                  ),
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9));
      },
    );
  }
}
