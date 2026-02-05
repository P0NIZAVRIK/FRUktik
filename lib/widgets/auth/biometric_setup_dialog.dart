import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../design_system/colors.dart';
import '../../design_system/typography.dart';
import '../../design_system/spacing.dart';
import '../common/glass_container.dart';
import '../../core/haptics/haptic_manager.dart';

/// Biometric setup dialog shown after onboarding (optional)
class BiometricSetupDialog extends StatefulWidget {
  final VoidCallback onComplete;
  
  const BiometricSetupDialog({
    super.key,
    required this.onComplete,
  });

  @override
  State<BiometricSetupDialog> createState() => _BiometricSetupDialogState();
}

class _BiometricSetupDialogState extends State<BiometricSetupDialog> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;

  Future<void> _setupBiometric() async {
    setState(() => _isLoading = true);
    
    try {
      // Check if biometric is available
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      
      if (!canCheckBiometrics || !isDeviceSupported) {
        if (mounted) {
          _showError('Биометрия не поддерживается на этом устройстве');
        }
        return;
      }

      // Authenticate to setup
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Подтвердите биометрию для быстрого входа',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        // Save biometric preference
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        
        HapticManager.success();
        if (mounted) {
          widget.onComplete();
        }
      }
    } catch (e) {
      if (mounted) {
        _showError('Ошибка настройки биометрии');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
    // Still complete - user can try again later
    widget.onComplete();
  }

  void _skipSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', false);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: AppSpacing.allLG,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fingerprint,
                size: 40,
                color: Colors.white,
              ),
            ),
            
            AppSpacing.verticalSpaceLG,
            
            // Title
            Text(
              'Быстрый вход',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            AppSpacing.verticalSpaceSM,
            
            // Description
            Text(
              'Хотите использовать отпечаток пальца или Face ID для быстрого входа в приложение?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            
            AppSpacing.verticalSpaceLG,
            
            // Buttons
            if (_isLoading)
              CircularProgressIndicator(color: AppColors.primary)
            else ...[
              // Enable button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _setupBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: AppSpacing.allMD,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.radiusMD,
                    ),
                  ),
                  child: Text(
                    'Включить биометрию',
                    style: AppTypography.labelLarge,
                  ),
                ),
              ),
              
              AppSpacing.verticalSpaceSM,
              
              // Skip button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _skipSetup,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: AppSpacing.allMD,
                  ),
                  child: Text(
                    'Позже',
                    style: AppTypography.labelMedium,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
