import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';
import '../../core/haptics/haptic_manager.dart';
import '../common/glass_container.dart';
import '../background/particle_background.dart';

/// Typeform-style onboarding flow
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // User preferences to collect
  String? _selectedGoal;
  double _targetCalories = 2000;
  
  final List<OnboardingStep> _steps = [
    OnboardingStep(
      icon: Icons.restaurant_menu,
      title: 'Добро пожаловать!',
      subtitle: 'FRUktik поможет контролировать питание',
      type: StepType.welcome,
    ),
    OnboardingStep(
      icon: Icons.track_changes,
      title: 'Какова ваша цель?',
      subtitle: 'Выберите основную цель',
      type: StepType.goalSelection,
      options: ['Снижение веса', 'Набор массы', 'Поддержание'],
    ),
    OnboardingStep(
      icon: Icons.local_fire_department,
      title: 'Дневная норма',
      subtitle: 'Сколько калорий вам нужно?',
      type: StepType.calorieSlider,
    ),
    OnboardingStep(
      icon: Icons.check_circle,
      title: 'Готово!',
      subtitle: 'Начнём отслеживать питание',
      type: StepType.complete,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _nextPage() {
    HapticManager.light();
    
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: AppAnimations.medium,
        curve: AppAnimations.spring,
      );
    } else {
      HapticManager.success();
      widget.onComplete();
    }
  }
  
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }
  
  bool _canProceed() {
    final step = _steps[_currentPage];
    switch (step.type) {
      case StepType.goalSelection:
        return _selectedGoal != null;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        particleCount: 30,
        child: SafeArea(
          child: Column(
            children: [
              // Progress indicator
              _buildProgressIndicator()
                  .animate()
                  .fadeIn(duration: AppAnimations.normal),
              
              // Page content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_steps[index], index);
                  },
                ),
              ),
              
              // Navigation button
              _buildBottomButton(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProgressIndicator() {
    return Padding(
      padding: AppSpacing.allLG,
      child: Row(
        children: List.generate(_steps.length, (index) {
          final isActive = index <= _currentPage;
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: isActive
                    ? AppColors.primaryGradient
                    : null,
                color: isActive ? null : AppColors.glassBorder,
              ),
            ),
          );
        }),
      ),
    );
  }
  
  Widget _buildPage(OnboardingStep step, int index) {
    return Padding(
      padding: AppSpacing.allLG,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            padding: AppSpacing.allXL,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: AppColors.getNeonGlow(AppColors.primary),
            ),
            child: Icon(
              step.icon,
              size: 64,
              color: Colors.white,
            ),
          )
              .animate(key: ValueKey('icon_$index'))
              .fadeIn(duration: AppAnimations.medium)
              .scale(
                begin: const Offset(0.5, 0.5),
                duration: AppAnimations.medium,
                curve: AppAnimations.spring,
              ),
          
          AppSpacing.verticalSpaceXL,
          
          // Title
          Text(
            step.title,
            style: AppTypography.displaySmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('title_$index'))
              .fadeIn(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 100),
              )
              .slideY(begin: 0.2),
          
          AppSpacing.verticalSpaceSM,
          
          // Subtitle
          Text(
            step.subtitle,
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          )
              .animate(key: ValueKey('subtitle_$index'))
              .fadeIn(
                duration: AppAnimations.medium,
                delay: const Duration(milliseconds: 200),
              ),
          
          AppSpacing.verticalSpaceXL,
          
          // Type-specific content
          _buildStepContent(step, index),
        ],
      ),
    );
  }
  
  Widget _buildStepContent(OnboardingStep step, int index) {
    switch (step.type) {
      case StepType.goalSelection:
        return _buildGoalOptions(step.options!, index);
      case StepType.calorieSlider:
        return _buildCalorieSlider(index);
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildGoalOptions(List<String> options, int pageIndex) {
    return Column(
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final isSelected = _selectedGoal == option;
        
        return Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () {
              HapticManager.selection();
              setState(() => _selectedGoal = option);
            },
            child: AnimatedContainer(
              duration: AppAnimations.fast,
              padding: AppSpacing.allMD,
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.surface,
                borderRadius: AppSpacing.radiusLG,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.glassBorder,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? AppColors.getNeonGlow(AppColors.primary)
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected 
                        ? Colors.white 
                        : AppColors.textSecondary,
                  ),
                  AppSpacing.horizontalSpaceMD,
                  Text(
                    option,
                    style: AppTypography.titleMedium.copyWith(
                      color: isSelected 
                          ? Colors.white 
                          : AppColors.textPrimary,
                      fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
            .animate(key: ValueKey('option_${pageIndex}_$index'))
            .fadeIn(
              duration: AppAnimations.normal,
              delay: Duration(milliseconds: 300 + index * 100),
            )
            .slideX(begin: 0.2);
      }).toList(),
    );
  }
  
  Widget _buildCalorieSlider(int index) {
    return Column(
      children: [
        // Current value
        Text(
          '${_targetCalories.toInt()} ккал',
          style: AppTypography.displayMedium.copyWith(
            color: AppColors.caloriesNeon,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.caloriesNeon.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        )
            .animate(key: ValueKey('calories_$index'))
            .fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 300),
            ),
        
        AppSpacing.verticalSpaceLG,
        
        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.surface,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 14,
              elevation: 4,
            ),
            trackHeight: 8,
          ),
          child: Slider(
            value: _targetCalories,
            min: 1200,
            max: 4000,
            divisions: 28,
            onChanged: (value) {
              HapticManager.selection();
              setState(() => _targetCalories = value);
            },
          ),
        )
            .animate(key: ValueKey('slider_$index'))
            .fadeIn(
              duration: AppAnimations.normal,
              delay: const Duration(milliseconds: 400),
            ),
        
        // Range labels
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1200',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
              Text(
                '4000',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomButton() {
    final isLastPage = _currentPage == _steps.length - 1;
    final canProceed = _canProceed();
    
    return Padding(
      padding: AppSpacing.allLG,
      child: GestureDetector(
        onTap: canProceed ? _nextPage : null,
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          width: double.infinity,
          padding: AppSpacing.allMD,
          decoration: BoxDecoration(
            gradient: canProceed ? AppColors.primaryGradient : null,
            color: canProceed ? null : AppColors.surface,
            borderRadius: AppSpacing.radiusLG,
            boxShadow: canProceed
                ? AppColors.getNeonGlow(AppColors.primary)
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLastPage ? 'Начать' : 'Продолжить',
                style: AppTypography.titleMedium.copyWith(
                  color: canProceed 
                      ? Colors.white 
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppSpacing.horizontalSpaceSM,
              Icon(
                isLastPage ? Icons.check : Icons.arrow_forward,
                color: canProceed 
                    ? Colors.white 
                    : AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: AppAnimations.normal,
          delay: const Duration(milliseconds: 500),
        )
        .slideY(begin: 0.5);
  }
}

/// Onboarding step data class
class OnboardingStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final StepType type;
  final List<String>? options;
  
  const OnboardingStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.type,
    this.options,
  });
}

enum StepType {
  welcome,
  goalSelection,
  calorieSlider,
  complete,
}
