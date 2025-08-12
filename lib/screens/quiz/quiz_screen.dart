// lib/screens/quiz/quiz_screen.dart
import 'package:fitsyncgemini/viewmodels/auth_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fitsyncgemini/constants/app_colors.dart';
import 'package:fitsyncgemini/constants/app_data.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fitsyncgemini/widgets/common/gradient_button.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _quizStep = 0;

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
                    : 'Question $_quizStep of ${quizQuestions.length}',
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(width: 48), // For alignment
            ],
          ),
          if (_quizStep > 0 && _quizStep <= quizQuestions.length)
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
    } else if (_quizStep > 0 && _quizStep <= quizQuestions.length) {
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
                        onPressed: _nextStep,
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
                        const Text(
                          'Minimalist',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You appreciate clean lines, neutral colors, and timeless pieces that never go out of style.',
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
                          children:
                              ['Timeless', 'Clean', 'Neutral']
                                  .map(
                                    (trait) => Chip(
                                      label: Text(
                                        trait,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Colors.transparent,
                                      shape: StadiumBorder(
                                        side: BorderSide(
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: () async {
                      // ✅ Get the auth view model
                      final authVM = ref.read(authViewModelProvider.notifier);

                      // 🔐 Mark onboarding as completed
                      await authVM.completeOnboarding();

                      // ✅ Navigate to dashboard
                      context.go('/dashboard');
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Continue to FitSync'),
                        SizedBox(width: 8),
                        Icon(LucideIcons.check, size: 16),
                      ],
                    ),
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
