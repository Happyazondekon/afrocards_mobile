import 'package:shared_preferences/shared_preferences.dart';

/// 💾 Service de stockage local pour les données non sensibles
/// Utilise shared_preferences pour stocker les préférences
class LocalStorage {
  static SharedPreferences? _prefs;

  // Clés de stockage
  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _selectedCategoriesKey = 'selected_categories';
  static const String _lastLoginKey = 'last_login';
  static const String _themeKey = 'app_theme';
  static const String _notificationsEnabledKey = 'notifications_enabled';

  /// Initialiser SharedPreferences
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Obtenir l'instance (avec initialisation si nécessaire)
  static Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ========================================
  // 🎯 ONBOARDING
  // ========================================

  /// Marquer l'onboarding comme terminé
  static Future<void> setOnboardingCompleted(bool completed) async {
    final prefs = await _instance;
    await prefs.setBool(_onboardingCompletedKey, completed);
  }

  /// Vérifier si l'onboarding est terminé
  static Future<bool> isOnboardingCompleted() async {
    final prefs = await _instance;
    return prefs.getBool(_onboardingCompletedKey) ?? false;
  }

  // ========================================
  // 📚 CATÉGORIES SÉLECTIONNÉES
  // ========================================

  /// Sauvegarder les catégories sélectionnées
  static Future<void> saveSelectedCategories(List<int> categoryIds) async {
    final prefs = await _instance;
    final stringList = categoryIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_selectedCategoriesKey, stringList);
  }

  /// Récupérer les catégories sélectionnées
  static Future<List<int>> getSelectedCategories() async {
    final prefs = await _instance;
    final stringList = prefs.getStringList(_selectedCategoriesKey) ?? [];
    return stringList.map((s) => int.tryParse(s) ?? 0).where((id) => id > 0).toList();
  }

  /// Vérifier si des catégories sont sélectionnées
  static Future<bool> hasSelectedCategories() async {
    final categories = await getSelectedCategories();
    return categories.isNotEmpty;
  }

  // ========================================
  // 🕐 DERNIÈRE CONNEXION
  // ========================================

  /// Sauvegarder la date de dernière connexion
  static Future<void> saveLastLogin() async {
    final prefs = await _instance;
    await prefs.setString(_lastLoginKey, DateTime.now().toIso8601String());
  }

  /// Récupérer la date de dernière connexion
  static Future<DateTime?> getLastLogin() async {
    final prefs = await _instance;
    final dateString = prefs.getString(_lastLoginKey);
    if (dateString == null) return null;
    return DateTime.tryParse(dateString);
  }

  // ========================================
  // 🎨 THÈME
  // ========================================

  /// Sauvegarder le thème choisi
  static Future<void> saveTheme(String theme) async {
    final prefs = await _instance;
    await prefs.setString(_themeKey, theme);
  }

  /// Récupérer le thème choisi
  static Future<String> getTheme() async {
    final prefs = await _instance;
    return prefs.getString(_themeKey) ?? 'light';
  }

  // ========================================
  // 🔔 NOTIFICATIONS
  // ========================================

  /// Activer/désactiver les notifications
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await _instance;
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// Vérifier si les notifications sont activées
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await _instance;
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  // ========================================
  // 🧹 NETTOYAGE
  // ========================================

  /// Effacer toutes les données locales
  static Future<void> clearAll() async {
    final prefs = await _instance;
    await prefs.clear();
  }
}
