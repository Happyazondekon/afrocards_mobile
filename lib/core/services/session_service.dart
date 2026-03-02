import 'package:flutter/material.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';

/// 🔐 Service de gestion de session utilisateur
/// Centralise toutes les opérations liées à l'authentification
class SessionService {
  static SessionService? _instance;
  
  // Données en cache pour éviter les lectures répétées
  String? _cachedToken;
  Map<String, dynamic>? _cachedUserData;
  Map<String, dynamic>? _cachedProfileData;
  bool _isInitialized = false;

  SessionService._();

  /// Obtenir l'instance singleton
  static SessionService get instance {
    _instance ??= SessionService._();
    return _instance!;
  }

  /// Initialiser le service (charger les données depuis le stockage)
  Future<void> init() async {
    if (_isInitialized) return;
    
    await LocalStorage.init();
    _cachedToken = await SecureStorage.getToken();
    _cachedUserData = await SecureStorage.getUserData();
    _cachedProfileData = await SecureStorage.getProfileData();
    _isInitialized = true;
    
    debugPrint('🔐 SessionService initialisé - Token: ${_cachedToken != null ? 'Présent' : 'Absent'}');
  }

  /// Vérifier si l'utilisateur est connecté
  bool get isLoggedIn => _cachedToken != null && _cachedToken!.isNotEmpty;

  /// Obtenir le token
  String? get token => _cachedToken;

  /// Obtenir les données utilisateur
  Map<String, dynamic>? get userData => _cachedUserData;

  /// Obtenir les données du profil
  Map<String, dynamic>? get profileData => _cachedProfileData;

  // ========================================
  // 👤 DONNÉES UTILISATEUR PRATIQUES
  // ========================================

  /// Nom de l'utilisateur
  String get userName {
    return _cachedUserData?['nom'] ?? 
           _cachedProfileData?['pseudo'] ?? 
           'Joueur';
  }

  /// Niveau de l'utilisateur (ex: "Stage 1-98XP")
  String get userLevel {
    final niveau = _cachedProfileData?['niveau'] ?? 1;
    final xp = _cachedProfileData?['xpActuel'] ?? 0;
    return 'Stage $niveau-${xp}XP';
  }

  /// Score total
  int get userPoints => _cachedProfileData?['scoreTotal'] ?? 0;

  /// Nombre de vies (par défaut 5)
  int get userLives => _cachedProfileData?['vies'] ?? 5;

  /// URL de l'avatar
  String? get avatarUrl => _cachedProfileData?['avatarURL'];

  // ========================================
  // 🔑 CONNEXION / DÉCONNEXION
  // ========================================

  /// Sauvegarder la session après connexion
  Future<void> saveSession({
    required String token,
    required Map<String, dynamic> utilisateur,
    Map<String, dynamic>? profil,
  }) async {
    // Sauvegarder dans le stockage sécurisé
    await SecureStorage.saveToken(token);
    await SecureStorage.saveUserData(utilisateur);
    if (profil != null) {
      await SecureStorage.saveProfileData(profil);
    }

    // Sauvegarder la date de connexion
    await LocalStorage.saveLastLogin();

    // Mettre à jour le cache
    _cachedToken = token;
    _cachedUserData = utilisateur;
    _cachedProfileData = profil;

    debugPrint('✅ Session sauvegardée pour: ${utilisateur['nom'] ?? utilisateur['email']}');
  }

  /// Mettre à jour les données du profil
  Future<void> updateProfile(Map<String, dynamic> profil) async {
    await SecureStorage.saveProfileData(profil);
    _cachedProfileData = profil;
  }

  /// Déconnexion
  Future<void> logout() async {
    await SecureStorage.clearSession();
    _cachedToken = null;
    _cachedUserData = null;
    _cachedProfileData = null;
    
    debugPrint('👋 Utilisateur déconnecté');
  }

  /// Effacer toutes les données (réinitialisation complète)
  Future<void> clearAllData() async {
    await SecureStorage.clearAll();
    await LocalStorage.clearAll();
    _cachedToken = null;
    _cachedUserData = null;
    _cachedProfileData = null;
    _isInitialized = false;
    
    debugPrint('🧹 Toutes les données effacées');
  }

  // ========================================
  // 🎯 CATÉGORIES
  // ========================================

  /// Sauvegarder les catégories sélectionnées
  Future<void> saveSelectedCategories(List<int> categoryIds) async {
    await LocalStorage.saveSelectedCategories(categoryIds);
  }

  /// Récupérer les catégories sélectionnées
  Future<List<int>> getSelectedCategories() async {
    return await LocalStorage.getSelectedCategories();
  }

  /// Vérifier si des catégories sont sélectionnées
  Future<bool> hasSelectedCategories() async {
    return await LocalStorage.hasSelectedCategories();
  }

  // ========================================
  // 🎯 ONBOARDING
  // ========================================

  /// Marquer l'onboarding comme terminé
  Future<void> completeOnboarding() async {
    await LocalStorage.setOnboardingCompleted(true);
  }

  /// Vérifier si l'onboarding est terminé
  Future<bool> isOnboardingCompleted() async {
    return await LocalStorage.isOnboardingCompleted();
  }
}
