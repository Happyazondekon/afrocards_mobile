import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/services/session_service.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../../../home/presentation/screens/category_selection_screen.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
    _checkSessionAndNavigate();
  }

  /// Vérifie la session et navigue vers l'écran approprié
  Future<void> _checkSessionAndNavigate() async {
    // Attendre un minimum de 2 secondes pour l'animation du splash
    await Future.delayed(const Duration(seconds: 2));

    // Initialiser le service de session
    final session = SessionService.instance;
    await session.init();

    if (!mounted) return;

    // Vérifier si l'utilisateur est connecté
    if (session.isLoggedIn) {
      debugPrint('✅ Utilisateur connecté: ${session.userName}');
      
      // 🔄 Initialiser le UserStateProvider avec les données de session
      if (mounted) {
        final userState = context.read<UserStateProvider>();
        await userState.initialize(
          token: session.token ?? '',
          userName: session.userName,
          avatarUrl: session.avatarUrl,
        );
      }
      
      // Vérifier si des catégories sont sélectionnées
      final hasCategories = await session.hasSelectedCategories();
      
      if (hasCategories) {
        // Aller directement au Home
        final selectedCategories = await session.getSelectedCategories();
        _navigateTo(
          HomeScreen(
            userName: session.userName,
            userLevel: session.userLevel,
            userPoints: session.userPoints,
            userLives: session.userLives,
            avatarUrl: session.avatarUrl,
            token: session.token,
            selectedCategoryIds: selectedCategories,
          ),
        );
      } else {
        // Aller à la sélection des catégories
        _navigateTo(
          CategorySelectionScreen(
            userName: session.userName,
            userLevel: session.userLevel,
            userPoints: session.userPoints,
            userLives: session.userLives,
            avatarUrl: session.avatarUrl,
            token: session.token,
          ),
        );
      }
    } else {
      // Vérifier si l'onboarding a été fait
      final onboardingDone = await session.isOnboardingCompleted();
      
      if (onboardingDone) {
        // Aller directement au login (importer LoginScreen si nécessaire)
        _navigateTo(const OnboardingScreen()); // TODO: Remplacer par LoginScreen
      } else {
        // Aller à l'onboarding
        _navigateTo(const OnboardingScreen());
      }
      
      debugPrint('👤 Utilisateur non connecté - Navigation vers onboarding/login');
    }
  }

  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. L'image de fond (Background)
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/img.png', // Ton image de motifs blancs
              fit: BoxFit.cover,
            ),
          ),

          // 2. Le Logo au milieu
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _fadeAnimation,
                child: Image.asset(
                  'assets/images/logos/logo_afc.png', // Ton logo AfroCards
                  width: MediaQuery.of(context).size.width * 0.7,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),

          // 3. Optionnel : Un indicateur de chargement discret en bas
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}