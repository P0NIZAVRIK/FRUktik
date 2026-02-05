import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../background/particle_background.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';
import '../../core/haptics/haptic_manager.dart';
import '../common/glass_container.dart';
import '../../services/auth_service.dart';

/// Premium auth screen with login/register forms and biometric auth
class AuthScreen extends StatefulWidget {
  final VoidCallback onAuthSuccess;
  
  const AuthScreen({
    super.key,
    required this.onAuthSuccess,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> 
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _canCheckBiometrics = false;
  bool _isMobilePlatform = false;
  bool _showSuccess = false;
  
  late AnimationController _successController;
  
  @override
  void initState() {
    super.initState();
    
    _successController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS;
    
    if (_isMobilePlatform) {
      _checkBiometrics();
    }
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _successController.dispose();
    super.dispose();
  }
  
  Future<void> _checkBiometrics() async {
    if (!_isMobilePlatform) return;
    
    try {
      // Check if user has enabled biometric in settings
      final prefs = await SharedPreferences.getInstance();
      final biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      if (!biometricEnabled) {
        setState(() => _canCheckBiometrics = false);
        return;
      }
      
      // Check device support
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      if (mounted) {
        setState(() => _canCheckBiometrics = available.isNotEmpty);
      }
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }
  
  Future<void> _authenticateBiometric() async {
    if (!_isMobilePlatform || !_canCheckBiometrics) return;
    
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Войдите в FRUktik',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (authenticated && mounted) {
        HapticManager.success();
        _onAuthSuccess();
      }
    } catch (e) {
      debugPrint('Biometric auth error: $e');
    }
  }
  
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    HapticManager.light();
    
    final authService = context.read<AuthService>();
    bool success;
    
    if (_isLogin) {
      success = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } else {
      success = await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        HapticManager.success();
        _onAuthSuccess();
      } else {
        HapticManager.error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authService.error ?? 'Ошибка авторизации'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
  
  void _onAuthSuccess() {
    setState(() => _showSuccess = true);
    _successController.forward();
    
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) widget.onAuthSuccess();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        particleCount: 40,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: AppSpacing.allLG,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo()
                        .animate()
                        .fadeIn(duration: AppAnimations.medium)
                        .scale(begin: const Offset(0.8, 0.8)),
                    
                    AppSpacing.verticalSpaceXL,
                    
                    // Title
                    _buildTitle()
                        .animate()
                        .fadeIn(
                          duration: AppAnimations.medium,
                          delay: const Duration(milliseconds: 100),
                        ),
                    
                    AppSpacing.verticalSpaceLG,
                    
                    // Form
                    _buildForm()
                        .animate()
                        .fadeIn(
                          duration: AppAnimations.medium,
                          delay: const Duration(milliseconds: 200),
                        )
                        .slideY(begin: 0.1),
                    
                    AppSpacing.verticalSpaceMD,
                    
                    // Biometric button
                    if (_canCheckBiometrics && _isLogin)
                      _buildBiometricButton()
                          .animate()
                          .fadeIn(
                            duration: AppAnimations.medium,
                            delay: const Duration(milliseconds: 300),
                          ),
                    
                    AppSpacing.verticalSpaceLG,
                    
                    // Toggle login/register
                    _buildToggle()
                        .animate()
                        .fadeIn(
                          duration: AppAnimations.medium,
                          delay: const Duration(milliseconds: 400),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Glow
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        
        // Icon
        if (!_showSuccess)
          GlassContainer(
            padding: AppSpacing.allLG,
            borderRadius: AppSpacing.radiusFull,
            child: Icon(
              Icons.restaurant_menu,
              size: 60,
              color: AppColors.primary,
            ),
          ),
        
        // Success icon
        if (_showSuccess)
          AnimatedBuilder(
            animation: _successController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + _successController.value * 0.3,
                child: Opacity(
                  opacity: (1 - _successController.value * 0.5).clamp(0.0, 1.0),
                  child: GlassContainer(
                    padding: AppSpacing.allLG,
                    borderRadius: AppSpacing.radiusFull,
                    child: Icon(
                      Icons.check_circle,
                      size: 60,
                      color: AppColors.success,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
  
  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'FRUktik',
          style: AppTypography.displayLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: AppColors.primary.withOpacity(0.5),
                blurRadius: 20,
              ),
            ],
          ),
        ),
        AppSpacing.verticalSpaceXS,
        Text(
          _isLogin ? 'Войдите в аккаунт' : 'Создайте аккаунт',
          style: AppTypography.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildForm() {
    return GlassContainer(
      padding: AppSpacing.allLG,
      borderRadius: AppSpacing.radiusXL,
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Name field (register only)
            if (!_isLogin) ...[
              _buildTextField(
                controller: _nameController,
                label: 'Имя',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя';
                  }
                  return null;
                },
              ),
              AppSpacing.verticalSpaceMD,
            ],
            
            // Email field
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите email';
                }
                if (!value.contains('@')) {
                  return 'Введите корректный email';
                }
                return null;
              },
            ),
            
            AppSpacing.verticalSpaceMD,
            
            // Password field
            _buildTextField(
              controller: _passwordController,
              label: 'Пароль',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Введите пароль';
                }
                if (value.length < 6) {
                  return 'Пароль минимум 6 символов';
                }
                return null;
              },
            ),
            
            AppSpacing.verticalSpaceLG,
            
            // Submit button
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTypography.bodyLarge.copyWith(
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        border: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMD,
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMD,
          borderSide: BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMD,
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppSpacing.radiusMD,
          borderSide: BorderSide(color: AppColors.error),
        ),
      ),
      validator: validator,
    );
  }
  
  Widget _buildSubmitButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _submitForm,
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        width: double.infinity,
        padding: AppSpacing.allMD,
        decoration: BoxDecoration(
          gradient: _isLoading ? null : AppColors.primaryGradient,
          color: _isLoading ? AppColors.surface : null,
          borderRadius: AppSpacing.radiusMD,
          boxShadow: _isLoading ? null : AppColors.getNeonGlow(AppColors.primary),
        ),
        child: Center(
          child: _isLoading
              ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                )
              : Text(
                  _isLogin ? 'Войти' : 'Зарегистрироваться',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildBiometricButton() {
    return GestureDetector(
      onTap: _authenticateBiometric,
      child: Container(
        padding: AppSpacing.allMD,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppSpacing.radiusMD,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              color: AppColors.primary,
            ),
            AppSpacing.horizontalSpaceSM,
            Text(
              'Войти с биометрией',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildToggle() {
    return GestureDetector(
      onTap: () {
        HapticManager.light();
        setState(() => _isLogin = !_isLogin);
        _formKey.currentState?.reset();
      },
      child: RichText(
        text: TextSpan(
          style: AppTypography.bodyMedium,
          children: [
            TextSpan(
              text: _isLogin ? 'Нет аккаунта? ' : 'Уже есть аккаунт? ',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            TextSpan(
              text: _isLogin ? 'Зарегистрироваться' : 'Войти',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
