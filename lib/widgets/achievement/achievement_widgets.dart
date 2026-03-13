import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/achievement.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../common/glass_container.dart';

/// Overlay widget shown when achievement is unlocked
class AchievementUnlockedOverlay extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;
  
  const AchievementUnlockedOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementUnlockedOverlay> createState() => _AchievementUnlockedOverlayState();
}

class _AchievementUnlockedOverlayState extends State<AchievementUnlockedOverlay> {
  late ConfettiController _confettiController;
  
  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(milliseconds: 1500),
    );
    
    // Start confetti immediately
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confettiController.play();
    });
    
    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) widget.onDismiss();
    });
  }
  
  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Confetti
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.03,
                numberOfParticles: 30,
                gravity: 0.2,
                colors: const [
                  AppColors.primary,
                  AppColors.proteinNeon,
                  AppColors.fatsNeon,
                  AppColors.carbsNeon,
                  AppColors.caloriesNeon,
                ],
              ),
            ),
            
            // Achievement Card
            Padding(
              padding: AppSpacing.allLG,
              child: GlassContainer(
                padding: AppSpacing.allXL,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Text(
                      widget.achievement.icon,
                      style: const TextStyle(fontSize: 80),
                    ),
                    
                    AppSpacing.verticalSpaceMD,
                    
                    // Title
                    Text(
                      'Достижение разблокировано!',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    AppSpacing.verticalSpaceSM,
                    
                    Text(
                      widget.achievement.title,
                      style: AppTypography.headlineMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    AppSpacing.verticalSpaceXS,
                    
                    Text(
                      widget.achievement.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    AppSpacing.verticalSpaceMD,
                    
                    // Dismiss hint
                    Text(
                      'Нажмите в любом месте',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: const Duration(milliseconds: 300)),
            ),
          ],
        ),
      ),
    );
  }
}

/// Achievement badge widget for display in list
class AchievementBadge extends StatelessWidget {
  final Achievement achievement;
  final bool compact;
  
  const AchievementBadge({
    super.key,
    required this.achievement,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompact();
    }
    
    return GlassContainer(
      padding: AppSpacing.allMD,
      child: Row(
        children: [
          // Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: achievement.isUnlocked 
                  ? AppColors.primaryGradient 
                  : null,
              color: achievement.isUnlocked 
                  ? null 
                  : AppColors.surfaceVariant,
              borderRadius: AppSpacing.radiusMD,
            ),
            child: Center(
              child: Text(
                achievement.icon,
                style: TextStyle(
                  fontSize: 32,
                  color: achievement.isUnlocked 
                      ? null 
                      : Colors.white.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          
          AppSpacing.horizontalSpaceMD,
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: achievement.isUnlocked 
                        ? AppColors.textPrimary 
                        : AppColors.textSecondary,
                  ),
                ),
                Text(
                  achievement.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          
          // Locked/Unlocked indicator
          if (!achievement.isUnlocked)
            const Icon(
              Icons.lock_outline,
              color: AppColors.textTertiary,
              size: 20,
            )
          else
            const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 20,
            ),
        ],
      ),
    );
  }
  
  Widget _buildCompact() {
    return Container(
      padding: AppSpacing.allSM,
      decoration: BoxDecoration(
        color: achievement.isUnlocked 
            ? AppColors.primary.withValues(alpha: 0.1) 
            : AppColors.surfaceVariant,
        borderRadius: AppSpacing.radiusSM,
        border: Border.all(
          color: achievement.isUnlocked 
              ? AppColors.primary 
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            achievement.icon,
            style: const TextStyle(fontSize: 16),
          ),
          AppSpacing.horizontalSpaceXS,
          Text(
            achievement.title,
            style: AppTypography.labelSmall.copyWith(
              color: achievement.isUnlocked 
                  ? AppColors.textPrimary 
                  : AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
