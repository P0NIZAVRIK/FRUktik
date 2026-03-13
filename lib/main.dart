import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/globals.dart'; // Import global navigator key
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/diary_provider.dart';
import 'services/auth_service.dart';
import 'services/achievement_service.dart';
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
import 'widgets/gamification/streak_indicator.dart';
import 'screens/camera_screen.dart';
import 'screens/mistral_chat_screen.dart';
import 'services/n8n_service.dart';
import 'design_system/colors.dart';
import 'design_system/typography.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'services/local_cache_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:uuid/uuid.dart';
import 'models/food_item.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting
  await initializeDateFormatting('ru', null);

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

  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

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
        ChangeNotifierProvider(
            create: (_) => AchievementService(
                  client: SupabaseConfig.isConfigured
                      ? Supabase.instance.client
                      : null,
                )),
        ChangeNotifierProxyProvider2<AuthService, AchievementService,
            DiaryProvider>(
          create: (_) => DiaryProvider(cacheService),
          update: (_, auth, achievement, diary) => diary!
            ..updateAuth(auth)
            ..updateAchievements(achievement),
        ),
      ],
      child: MaterialApp(
        title: 'FRUktik - Дневник РїРёС‚Р°РЅРёСЏ',
        navigatorKey: navigatorKey, // Added global key
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
            (_currentState == AppFlowState.main ||
                _currentState == AppFlowState.onboarding)) {
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
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
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
            body:
                isMobile ? _buildMobileLayout() : _buildDesktopLayout(context),
            bottomNavigationBar: isMobile ? _buildBottomNav() : null,
          ),
        );
      },
    );
  }

  Future<void> _openCamera() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );

    if (result != null && mounted) {
      if (result is String) {
        setState(() => _selectedIndex = 1);
        context.read<DiaryProvider>().setSearchQuery(result);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Поиск: $result'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      } else if (result is Map && result['type'] == 'image') {
        final path = result['path'] as String;
        context.read<DiaryProvider>().addProcessingEntry(path);
        setState(() => _selectedIndex = 2);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Фото отправлено ИИ. Обработка...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primary,
          ),
        );
      } else if (result is Map && result['type'] == 'n8n_image') {
        final path = result['path'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Отправка в n8n...'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.blueAccent,
          ),
        );

        Future.microtask(() async {
          try {
            final n8nService = N8nService();
            final dynamic response =
                await n8nService.sendImageQuery(path, action: 'ocr');

            if (mounted) {
              List<dynamic> items = [];
              if (response is List) {
                items = response;
              } else if (response is Map) {
                if (response.containsKey('items') &&
                    response['items'] is List) {
                  items = List<dynamic>.from(response['items']);
                } else {
                  items = [response];
                }
              }

              if (items.isNotEmpty && mounted) {
                final provider = context.read<DiaryProvider>();
                int addedCount = 0;

                for (var itemData in items) {
                  if (itemData is Map) {
                    final name =
                        itemData['name']?.toString() ?? 'Неизвестный продукт';
                    final calories =
                        (itemData['calories'] as num?)?.toDouble() ?? 0.0;
                    final proteins =
                        (itemData['proteins'] as num?)?.toDouble() ?? 0.0;
                    final fats = (itemData['fats'] as num?)?.toDouble() ?? 0.0;
                    final carbs =
                        (itemData['carbs'] as num?)?.toDouble() ?? 0.0;

                    final foodItem = FoodItem(
                      id: const Uuid().v4(),
                      name: name,
                      calories: calories,
                      proteins: proteins,
                      fats: fats,
                      carbohydrates: carbs,
                      category: 'other',
                    );

                    provider.addEntry(foodItem, 100);
                    addedCount++;
                  }
                }

                if (addedCount > 0 && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Добавлено продуктов: $addedCount'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  setState(() => _selectedIndex = 2);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Не удалось найти продукты в ответе'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Не удалось распознать продукты'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка n8n: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        });
      }
    }
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
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
            child: const Icon(Icons.restaurant_menu,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'FRUktik',
            style: AppTypography.titleLarge.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),
          // Streak Indicator
          Consumer<DiaryProvider>(
            builder: (context, provider, _) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: StreakIndicator(
                    streak: provider.currentStreak, compact: true),
              );
            },
          ),
          _buildAIButton(context),
          _buildProfileButton(context),
        ],
      ),
    );
  }

  Widget _buildMobileHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nutrition summary
          const NutritionSummaryPanel(),

          const SizedBox(height: 16),

          // Quick add section
          Text(
            'Быстрое добавление',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
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
                      margin: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () {
                          provider.addEntry(item, 100);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${item.name} добавлен'),
                              backgroundColor: AppColors.success,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
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
                                child:
                                    const Icon(Icons.add, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
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

          const SizedBox(height: 24),

          // Today's entries
          Text(
            'Сегодня',
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Consumer<DiaryProvider>(
            builder: (context, provider, _) {
              final entries = provider.entries;
              if (entries.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant,
                            size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: 8),
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
                children: entries
                    .take(5)
                    .map((entry) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
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
                                  gradient:
                                      AppColors.primaryGradient.scale(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.restaurant,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
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
                        ))
                    .toList(),
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
        // Top panel: РљР‘Р–РЈ statistics with profile button
        Stack(
          children: [
            const NutritionSummaryPanel(),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Consumer<DiaryProvider>(
                    builder: (context, provider, _) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: StreakIndicator(streak: provider.currentStreak),
                      );
                    },
                  ),
                  _buildAIButton(context),
                  _buildProfileButton(context),
                ],
              ),
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
              const Expanded(
                child: DiaryPanel(),
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
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home, 'Главная'),
              _buildNavItem(1, Icons.restaurant_menu, 'Продукты'),
              _buildCameraNavButton(),
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

    return Expanded(
        child: GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            const SizedBox(height: 4),
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCameraNavButton() {
    return GestureDetector(
      onTap: _openCamera,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildAIButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MistralChatScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.primaryGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.auto_awesome,
          color: Colors.white,
          size: 20,
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
              color: AppColors.primary.withValues(alpha: 0.3),
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
