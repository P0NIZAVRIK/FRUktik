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
import '../common/glass_container.dart';

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
        SnackBar(
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
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusXL),
        title: Text(
          'Выйти из аккаунта?',
          style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти', style: TextStyle(color: AppColors.error)),
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
                  icon: Icon(Icons.check, color: AppColors.success),
                  onPressed: _saveProfile,
                )
              else
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors.textSecondary),
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
                
                AppSpacing.verticalSpaceLG,
                
                // Logout button
                _buildLogoutButton()
                    .animate()
                    .fadeIn(
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
  
  Widget _buildAvatar(UserModel user) {
    return Stack(
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
          decoration: BoxDecoration(
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
          
          Divider(color: AppColors.glassBorder),
          
          // Email
          _buildField(
            icon: Icons.email,
            label: 'Email',
            value: user.email,
            editable: false,
          ),
          
          Divider(color: AppColors.glassBorder),
          
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
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
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
    return GlassContainer(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статистика',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.verticalSpaceMD,
          
          Row(
            children: [
              _buildStatItem('0', 'дней подряд', AppColors.caloriesNeon),
              _buildStatItem('0', 'записей', AppColors.proteinNeon),
              _buildStatItem('0', 'достижений', AppColors.success),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: AppTypography.displaySmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                          ? Text(suffix, style: TextStyle(color: AppColors.textSecondary))
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
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: AppColors.error),
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
      'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
      'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
