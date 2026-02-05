import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_auth/local_auth.dart';
import '../background/particle_background.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../../design_system/animations.dart';
import '../../core/haptics/haptic_manager.dart';
import '../common/glass_container.dart';

/// Premium login screen with particle background and biometric auth
class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  
  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> 
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;
  bool _showLockDissolve = false;
  bool _isMobilePlatform = false;
  
  late AnimationController _lockController;
  
  @override
  void initState() {
    super.initState();
    
    _lockController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Check if we're on a mobile platform that supports biometrics
    _isMobilePlatform = defaultTargetPlatform == TargetPlatform.android ||
                        defaultTargetPlatform == TargetPlatform.iOS;
    
    if (_isMobilePlatform) {
      _checkBiometrics();
    }
    // On desktop, just show the login screen without biometrics
  }
  
  @override
  void dispose() {
    _lockController.dispose();
    super.dispose();
  }
  
  Future<void> _checkBiometrics() async {
    if (!_isMobilePlatform) return;
    
    try {
      _canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final available = await _localAuth.getAvailableBiometrics();
      
      if (mounted) {
        setState(() {
          _canCheckBiometrics = available.isNotEmpty;
        });
      }
      
      // Auto-trigger biometric authentication on mobile
      if (_canCheckBiometrics && mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) _authenticate();
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException checking biometrics: $e');
    } catch (e) {
      debugPrint('Error checking biometrics: $e');
    }
  }
  
  Future<void> _authenticate() async {
    if (_isAuthenticating || !_isMobilePlatform) return;
    
    setState(() => _isAuthenticating = true);
    HapticManager.light();
    
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Войдите в FRUktik',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      
      if (!mounted) return;
      
      if (authenticated) {
        HapticManager.success();
        _onAuthSuccess();
      } else {
        HapticManager.error();
        setState(() => _isAuthenticating = false);
      }
    } on PlatformException catch (e) {
      debugPrint('PlatformException authenticating: $e');
      if (mounted) setState(() => _isAuthenticating = false);
    } catch (e) {
      debugPrint('Error authenticating: $e');
      if (mounted) setState(() => _isAuthenticating = false);
    }
  }
  
  void _onAuthSuccess() {
    setState(() => _showLockDissolve = true);
    _lockController.forward();
    
    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onLoginSuccess();
    });
  }
  
  void _skipToMain() {
    // Skip authentication (for desktop or testing)
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ParticleBackground(
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: AppSpacing.allLG,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  _buildLogo()
                      .animate()
                      .fadeIn(duration: AppAnimations.slow)
                      .scale(
                        begin: const Offset(0.5, 0.5),
                        duration: AppAnimations.slow,
                        curve: AppAnimations.spring,
                      ),
                  
                  AppSpacing.verticalSpaceXL,
                  AppSpacing.verticalSpaceXL,
                  
                  // Welcome Text
                  Text(
                    'FRUktik',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: AppAnimations.medium,
                        delay: const Duration(milliseconds: 200),
                      )
                      .slideY(begin: 0.3),
                  
                  AppSpacing.verticalSpaceSM,
                  
                  Text(
                    'Дневник питания',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: AppAnimations.medium,
                        delay: const Duration(milliseconds: 400),
                      ),
                  
                  AppSpacing.verticalSpaceXL,
                  AppSpacing.verticalSpaceXL,
                  
                  // Auth Button
                  _buildAuthButton()
                      .animate()
                      .fadeIn(
                        duration: AppAnimations.medium,
                        delay: const Duration(milliseconds: 600),
                      )
                      .slideY(begin: 0.5),
                  
                  AppSpacing.verticalSpaceLG,
                  
                  // Skip button (for desktop)
                  TextButton(
                    onPressed: _skipToMain,
                    child: Text(
                      'Пропустить',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(
                        duration: AppAnimations.normal,
                        delay: const Duration(milliseconds: 800),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _lockController,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Glow effect
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(
                      0.5 * (1 - _lockController.value),
                    ),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
            
            // Lock icon that dissolves
            if (!_showLockDissolve)
              GlassContainer(
                padding: AppSpacing.allLG,
                borderRadius: AppSpacing.radiusFull,
                child: Icon(
                  _canCheckBiometrics ? Icons.fingerprint : Icons.restaurant,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            
            // Dissolve effect
            if (_showLockDissolve)
              Opacity(
                opacity: 1 - _lockController.value,
                child: Transform.scale(
                  scale: 1 + _lockController.value * 0.5,
                  child: GlassContainer(
                    padding: AppSpacing.allLG,
                    borderRadius: AppSpacing.radiusFull,
                    child: Icon(
                      Icons.check_circle,
                      size: 80,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildAuthButton() {
    return GestureDetector(
      onTap: _canCheckBiometrics ? _authenticate : _skipToMain,
      child: GlassContainer(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl,
          vertical: AppSpacing.lg,
        ),
        borderRadius: AppSpacing.radiusFull,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isAuthenticating)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              )
            else
              Icon(
                _canCheckBiometrics ? Icons.fingerprint : Icons.arrow_forward,
                color: AppColors.primary,
                size: 24,
              ),
            AppSpacing.horizontalSpaceMD,
            Text(
              _canCheckBiometrics ? 'Войти по отпечатку' : 'Начать',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
