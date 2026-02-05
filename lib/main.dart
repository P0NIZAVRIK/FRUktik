import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/diary_provider.dart';
import 'services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'data/mock_data.dart';
import 'widgets/food_list_panel.dart';
import 'widgets/diary_panel.dart';
import 'widgets/nutrition_summary_panel.dart';
import 'widgets/celebration/achievement_celebration.dart';
import 'widgets/auth/auth_screen.dart';
import 'widgets/onboarding/onboarding_screen.dart';
import 'widgets/profile/profile_screen.dart';
import 'widgets/auth/biometric_setup_dialog.dart';
import 'design_system/colors.dart';
import 'design_system/typography.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'services/local_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local cache first (for offline access)
  final cacheService = LocalCacheService();
  await cacheService.init();
  
  // Initialize Supabase if configured
  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }
  
  // Set status bar style
  AppTheme.setStatusBarStyle(isDark: true);
  
  runApp(MyApp(cacheService: cacheService));
}

class MyApp extends StatelessWidget {
  final LocalCacheService cacheService;
  
  const MyApp({super.key, required this.cacheService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, DiaryProvider>(
          create: (_) => DiaryProvider(cacheService),
          update: (_, auth, diary) => diary!..updateAuth(auth),
        ),
      ],
      child: MaterialApp(
        title: 'FRUktik - Дневник питания',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const AppWrapper(),
      ),
    );
  }
}

/// App flow states
enum AppFlowState {
  loading,
  auth,
  onboarding,
  main,
}

/// Wrapper that handles auth and onboarding flow
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  AppFlowState _currentState = AppFlowState.loading;
  bool _onboardingCompleted = false;
  
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }
  
  Future<void> _checkAuthState() async {
    // Load onboarding state from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    
    // Small delay to let AuthService initialize
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    final authService = context.read<AuthService>();
    
    if (authService.isAuthenticated) {
      setState(() => _currentState = AppFlowState.main);
    } else {
      setState(() => _currentState = AppFlowState.auth);
    }
  }
  
  void _onAuthSuccess() {
    if (_onboardingCompleted) {
      setState(() => _currentState = AppFlowState.main);
    } else {
      setState(() => _currentState = AppFlowState.onboarding);
    }
  }
  
  Future<void> _onOnboardingComplete() async {
    _onboardingCompleted = true;
    
    // Persist onboarding completion
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    
    // Show biometric setup dialog (optional)
    if (mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BiometricSetupDialog(
          onComplete: () {
            Navigator.of(context).pop();
            if (mounted) {
              setState(() => _currentState = AppFlowState.main);
            }
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen for auth changes
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Handle logout - if not authenticated and not in auth/loading state
        if (!authService.isAuthenticated && 
            !authService.isLoading &&
            (_currentState == AppFlowState.main || _currentState == AppFlowState.onboarding)) {
          // Defer state change to avoid build-time setState
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() => _currentState = AppFlowState.auth);
            }
          });
        }
        
        // Handle initial load complete
        if (_currentState == AppFlowState.loading && !authService.isLoading) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _currentState = authService.isAuthenticated 
                    ? AppFlowState.main 
                    : AppFlowState.auth;
              });
            }
          });
        }
        
        switch (_currentState) {
          case AppFlowState.loading:
            return Scaffold(
              backgroundColor: AppColors.backgroundPrimary,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 16),
                    Text(
                      'FRUktik',
                      style: AppTypography.displayMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          case AppFlowState.auth:
            return AuthScreen(onAuthSuccess: _onAuthSuccess);
          case AppFlowState.onboarding:
            return OnboardingScreen(onComplete: _onOnboardingComplete);
          case AppFlowState.main:
            return const MainScreen();
        }
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        return AchievementCelebration(
          provider: provider,
          child: Scaffold(
            body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(context),
            bottomNavigationBar: isMobile ? _buildBottomNav() : null,
          ),
        );
      },
    );
  }
  
  Widget _buildMobileLayout() {
    return SafeArea(
      child: Column(
        children: [
          // Top bar with profile
          _buildMobileAppBar(),
          
          // Content based on selected tab
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Home - Nutrition Summary + Quick Stats
                _buildMobileHome(),
                // Food catalog
                const FoodListPanel(),
                // Diary
                const DiaryPanel(),
                // Profile
                const ProfileScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.restaurant_menu, color: Colors.white, size: 20),
          ),
          SizedBox(width: 12),
          Text(
            'FRUktik',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          _buildProfileButton(context),
        ],
      ),
    );
  }
  
  Widget _buildMobileHome() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition summary
          const NutritionSummaryPanel(),
          
          SizedBox(height: 16),
          
          // Quick add section
          Text(
            'Быстрое добавление',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: Builder(
              builder: (context) {
                final provider = context.read<DiaryProvider>();
                final items = mockFoodItems.take(5).toList();
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Container(
                      width: 100,
                      margin: EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          provider.addEntry(item, 100);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} добавлен'),
                              backgroundColor: AppColors.success,
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                              SizedBox(height: 8),
                              Text(
                                item.name,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          SizedBox(height: 24),
          
          // Today's entries
          Text(
            'Сегодня',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Consumer<DiaryProvider>(
            builder: (context, provider, _) {
              final entries = provider.entries;
              if (entries.isEmpty) {
                return Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.restaurant, size: 48, color: AppColors.textTertiary),
                        SizedBox(height: 8),
                        Text(
                          'Добавьте первый приём пищи',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              return Column(
                children: entries.take(5).map((entry) => Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient.scale(0.5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.restaurant, color: AppColors.primary, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.foodItem.name,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              '${entry.weight.toInt()}г • ${entry.calories.toInt()} ккал',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        // Top panel: КБЖУ statistics with profile button
        Stack(
          children: [
            const NutritionSummaryPanel(),
            Positioned(
              top: 8,
              right: 8,
              child: _buildProfileButton(context),
            ),
          ],
        ),
        // Main content: left and right panels
        Expanded(
          child: Row(
            children: [
              // Left panel (30%): food list with search
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.3,
                child: const FoodListPanel(),
              ),
              // Right panel (70%): Diary
              Expanded(
                child: const DiaryPanel(),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Главная'),
              _buildNavItem(1, Icons.restaurant_menu, 'Продукты'),
              _buildNavItem(2, Icons.book, 'Дневник'),
              _buildNavItem(3, Icons.person, 'Профиль'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.textSecondary,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileButton(BuildContext context) {
    final authService = context.watch<AuthService>();
    final user = authService.currentUser;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Text(
            user?.displayName.isNotEmpty == true 
                ? user!.displayName[0].toUpperCase()
                : 'U',
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

