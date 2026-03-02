import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// 🔐 Service de stockage sécurisé pour les données sensibles
/// Utilise flutter_secure_storage pour chiffrer les données
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Clés de stockage
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _profileDataKey = 'profile_data';

  // ========================================
  // 🔑 TOKEN
  // ========================================

  /// Sauvegarder le token d'authentification
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Récupérer le token d'authentification
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Supprimer le token
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Vérifier si un token existe
  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ========================================
  // 👤 DONNÉES UTILISATEUR
  // ========================================

  /// Sauvegarder les données utilisateur (JSON)
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final jsonString = jsonEncode(userData);
    await _storage.write(key: _userDataKey, value: jsonString);
  }

  /// Récupérer les données utilisateur
  static Future<Map<String, dynamic>?> getUserData() async {
    final jsonString = await _storage.read(key: _userDataKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Supprimer les données utilisateur
  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userDataKey);
  }

  // ========================================
  // 🎮 DONNÉES PROFIL JOUEUR
  // ========================================

  /// Sauvegarder les données du profil joueur (JSON)
  static Future<void> saveProfileData(Map<String, dynamic> profileData) async {
    final jsonString = jsonEncode(profileData);
    await _storage.write(key: _profileDataKey, value: jsonString);
  }

  /// Récupérer les données du profil joueur
  static Future<Map<String, dynamic>?> getProfileData() async {
    final jsonString = await _storage.read(key: _profileDataKey);
    if (jsonString == null || jsonString.isEmpty) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Supprimer les données du profil
  static Future<void> deleteProfileData() async {
    await _storage.delete(key: _profileDataKey);
  }

  // ========================================
  // 🧹 NETTOYAGE COMPLET
  // ========================================

  /// Effacer toutes les données stockées (déconnexion)
  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /// Effacer les données de session uniquement
  static Future<void> clearSession() async {
    await deleteToken();
    await deleteUserData();
    await deleteProfileData();
  }
}
