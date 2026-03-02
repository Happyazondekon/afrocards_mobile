import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/providers/user_state_provider.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

/// 🚀 MAIN.DART - AFROCARDS
/// Point d'entrée de l'application

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 Configuration de l'orientation (Portrait uniquement)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 🎨 Configuration de la barre de statut
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const AfroCardsApp());
}

class AfroCardsApp extends StatelessWidget {
  const AfroCardsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UserStateProvider(),
      child: MaterialApp(
        title: 'AFROCARDS',
        debugShowCheckedModeBanner: false,

        // 🏠 Route de démarrage
        home: const SplashScreen(),
      ),
    );
  }
}