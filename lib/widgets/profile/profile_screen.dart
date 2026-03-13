import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';
import '../../core/haptics/haptic_manager.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/achievement_service.dart';
import '../../providers/diary_provider.dart';
import '../common/glass_container.dart';
import '../analytics/weekly_chart_widget.dart';

/// Premium profile screen
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _caloriesController;
  UserGoal? _selectedGoal;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthService>().currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _caloriesController = TextEditingController(
      text: (user?.dailyCalorieTarget ?? 2000).toInt().toString(),
    );
    _selectedGoal = user?.goal;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    HapticManager.light();

    final authService = context.read<AuthService>();
    await authService.updateProfile(
      displayName: _nameController.text.trim(),
      goal: _selectedGoal,
      dailyCalorieTarget: double.tryParse(_caloriesController.text) ?? 2000,
    );

    HapticManager.success();
    setState(() => _isEditing = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Профиль обновлён'),
            ],
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _logout() async {
    HapticManager.light();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(borderRadius: AppSpacing.radiusXL),
        title: Text(
          'Выйти из аккаунта?',
          style:
              AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Выйти', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthService>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;

        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: AppColors.backgroundPrimary,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'Профиль',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            actions: [
              if (_isEditing)
                IconButton(
                  icon: const Icon(Icons.check, color: AppColors.success),
                  onPressed: _saveProfile,
                )
              else
                IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.textSecondary),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: AppSpacing.allLG,
            child: Column(
              children: [
                // Avatar
                _buildAvatar(user)
                    .animate()
                    .fadeIn(duration: AppAnimations.medium)
                    .scale(begin: const Offset(0.9, 0.9)),

                AppSpacing.verticalSpaceLG,

                // User info card
                _buildInfoCard(user)
                    .animate()
                    .fadeIn(
                      duration: AppAnimations.medium,
                      delay: const Duration(milliseconds: 100),
                    )
                    .slideY(begin: 0.1),

                AppSpacing.verticalSpaceMD,

                // Weekly Chart
                const WeeklyChartWidget()
                    .animate()
                    .fadeIn(
                      duration: AppAnimations.medium,
                      delay: const Duration(milliseconds: 150),
                    )
                    .slideY(begin: 0.1),

                AppSpacing.verticalSpaceLG,

                // Goals card
                _buildGoalsCard()
                    .animate()
                    .fadeIn(
                      duration: AppAnimations.medium,
                      delay: const Duration(milliseconds: 200),
                    )
                    .slideY(begin: 0.1),

                AppSpacing.verticalSpaceMD,

                // Stats card
                _buildStatsCard(user)
                    .animate()
                    .fadeIn(
                      duration: AppAnimations.medium,
                      delay: const Duration(milliseconds: 300),
                    )
                    .slideY(begin: 0.1),

                AppSpacing.verticalSpaceMD,

                // Achievements card
                _buildAchievementsCard()
                    .animate()
                    .fadeIn(
                      duration: AppAnimations.medium,
                      delay: const Duration(milliseconds: 350),
                    )
                    .slideY(begin: 0.1),

                AppSpacing.verticalSpaceLG,

                // Logout button
                _buildLogoutButton().animate().fadeIn(
                      duration: AppAnimations.medium,
                      delay: const Duration(milliseconds: 400),
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

// ... (in _buildAvatar)
  Widget _buildAvatar(UserModel user) {
    // Calculate progress to next level (assuming 100 XP per level)
    const xpForNextLevel = 100;
    final currentLevelXp = user.xp % xpForNextLevel;
    final progress = currentLevelXp / xpForNextLevel;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Glow
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppColors.getNeonGlow(AppColors.primary),
              ),
            ),

            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : 'U',
                  style: AppTypography.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Level Badge
            Positioned(
              bottom: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: AppSpacing.radiusFull,
                  border: Border.all(color: AppColors.primary),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Text(
                  'LVL ${user.level}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),

        AppSpacing.verticalSpaceMD,

        // XP Bar
        SizedBox(
          width: 200,
          child: Column(
            children: [
              ClipRRect(
                borderRadius: AppSpacing.radiusFull,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.surfaceVariant,
                  color: AppColors.primary,
                  minHeight: 6,
                ),
              ),
              AppSpacing.verticalSpaceXS,
              Text(
                '$currentLevelXp / $xpForNextLevel XP',
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

  Widget _buildInfoCard(UserModel user) {
    return GlassContainer(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Информация',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalSpaceMD,

          // Name
          _buildField(
            icon: Icons.person,
            label: 'Имя',
            value: user.displayName,
            controller: _nameController,
            editable: _isEditing,
          ),

          const Divider(color: AppColors.glassBorder),

          // Email
          _buildField(
            icon: Icons.email,
            label: 'Email',
            value: user.email,
            editable: false,
          ),

          const Divider(color: AppColors.glassBorder),

          // Member since
          _buildField(
            icon: Icons.calendar_today,
            label: 'С нами с',
            value: _formatDate(user.createdAt),
            editable: false,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard() {
    return GlassContainer(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Цели',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalSpaceMD,

          // Goal selection
          if (_isEditing)
            ...UserGoal.values.map((goal) => _buildGoalOption(goal))
          else
            _buildField(
              icon: Icons.track_changes,
              label: 'Цель',
              value: _selectedGoal?.displayName ?? 'Не указано',
              editable: false,
            ),

          if (_isEditing) AppSpacing.verticalSpaceMD,

          // Daily calories
          _buildField(
            icon: Icons.local_fire_department,
            label: 'Дневная норма',
            value: '${_caloriesController.text} ккал',
            controller: _caloriesController,
            editable: _isEditing,
            keyboardType: TextInputType.number,
            suffix: 'ккал',
          ),
        ],
      ),
    );
  }

  Widget _buildGoalOption(UserGoal goal) {
    final isSelected = _selectedGoal == goal;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: () {
          HapticManager.selection();
          setState(() => _selectedGoal = goal);
        },
        child: AnimatedContainer(
          duration: AppAnimations.fast,
          padding: AppSpacing.allSM,
          decoration: BoxDecoration(
            gradient: isSelected ? AppColors.primaryGradient : null,
            color: isSelected ? null : AppColors.backgroundSecondary,
            borderRadius: AppSpacing.radiusMD,
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                size: 20,
              ),
              AppSpacing.horizontalSpaceSM,
              Text(
                goal.displayName,
                style: AppTypography.bodyMedium.copyWith(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(UserModel user) {
    final diary = context.watch<DiaryProvider>();
    final achievements = context.watch<AchievementService>();
    final xpProgress = (user.xp % 100) / 100;

    return GlassContainer(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.bar_chart_rounded,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'Статистика',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Main stats row
          Row(
            children: [
              _buildStatPill('${diary.currentStreak}', '🔥', 'дней',
                  AppColors.caloriesNeon),
              const SizedBox(width: 8),
              _buildStatPill('${diary.entries.length}', '📝', 'записей',
                  AppColors.proteinNeon),
              const SizedBox(width: 8),
              _buildStatPill('${achievements.unlockedCount}', '🏆', 'ачивок',
                  AppColors.success),
            ],
          ),

          const SizedBox(height: 16),

          // XP Progress section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(14),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'LVL ${user.level}',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${user.xp} XP',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${user.xp % 100}/100',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: xpProgress,
                    backgroundColor: AppColors.surfaceVariant,
                    color: AppColors.primary,
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String value, String emoji, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
    return Consumer<AchievementService>(
      builder: (context, service, _) {
        final all = service.achievements;

        return GlassContainer(
          padding: AppSpacing.allLG,
          borderRadius: AppSpacing.radiusXL,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('🏅', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Достижения',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${service.unlockedCount} / ${service.totalCount}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: service.totalCount > 0
                      ? service.unlockedCount / service.totalCount
                      : 0,
                  backgroundColor: AppColors.surfaceVariant,
                  color: Colors.amber,
                  minHeight: 4,
                ),
              ),
              const SizedBox(height: 16),

              // Grid of achievements
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.8,
                ),
                itemCount: all.length,
                itemBuilder: (context, index) {
                  final a = all[index];
                  final unlocked = a.isUnlocked;

                  return GestureDetector(
                    onTap: () {
                      HapticManager.light();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Text(a.icon,
                                  style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(a.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    Text(a.description,
                                        style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: AppColors.surface,
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: AppAnimations.fast,
                      decoration: BoxDecoration(
                        gradient: unlocked
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.2),
                                  AppColors.primary.withValues(alpha: 0.05),
                                ],
                              )
                            : null,
                        color: unlocked ? null : AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: unlocked
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : AppColors.glassBorder.withValues(alpha: 0.3),
                          width: unlocked ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            a.icon,
                            style: TextStyle(
                              fontSize: 26,
                              color: unlocked ? null : AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              a.title,
                              style: AppTypography.labelSmall.copyWith(
                                color: unlocked
                                    ? AppColors.textPrimary
                                    : AppColors.textTertiary,
                                fontSize: 9,
                                fontWeight: unlocked
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildField({
    required IconData icon,
    required String label,
    required String value,
    required bool editable,
    TextEditingController? controller,
    TextInputType? keyboardType,
    String? suffix,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          AppSpacing.horizontalSpaceMD,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                if (editable && controller != null)
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      suffix: suffix != null
                          ? Text(suffix,
                              style: const TextStyle(
                                  color: AppColors.textSecondary))
                          : null,
                    ),
                  )
                else
                  Text(
                    value,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _logout,
      child: Container(
        width: double.infinity,
        padding: AppSpacing.allMD,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.radiusMD,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: AppColors.error),
            AppSpacing.horizontalSpaceSM,
            Text(
              'Выйти из аккаунта',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
