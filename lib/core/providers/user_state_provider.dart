import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_endpoints.dart';

/// Provider pour gérer l'état global de l'utilisateur
/// Gère : XP, pièces, vies, niveau actuel, progression des stages
class UserStateProvider extends ChangeNotifier {
  // Informations utilisateur
  String? _token;
  String _userName = 'Joueur';
  String? _avatarUrl;
  
  // Progression
  int _pointsXP = 0;
  int _coins = 0;
  int _lives = 5;
  int _maxLives = 5;
  int _currentStageLevel = 1;
  int _maxUnlockedStage = 1;
  
  // Timer de régénération des vies
  Timer? _livesRegenTimer;
  DateTime? _lastLivesUpdate;
  static const int _livesRegenIntervalSeconds = 60; // 1 minute par vie
  
  // Getters
  String? get token => _token;
  String get userName => _userName;
  String? get avatarUrl => _avatarUrl;
  int get pointsXP => _pointsXP;
  int get coins => _coins;
  int get lives => _lives;
  int get maxLives => _maxLives;
  int get currentStageLevel => _currentStageLevel;
  int get maxUnlockedStage => _maxUnlockedStage;
  String get userLevel => 'Stage $_currentStageLevel';
  
  // Calculer le temps restant jusqu'à la prochaine vie
  int get secondsUntilNextLife {
    if (_lives >= _maxLives || _lastLivesUpdate == null) return 0;
    final elapsed = DateTime.now().difference(_lastLivesUpdate!).inSeconds;
    final remaining = _livesRegenIntervalSeconds - (elapsed % _livesRegenIntervalSeconds);
    return remaining;
  }
  
  /// Initialiser le provider avec les données utilisateur
  Future<void> initialize({
    required String token,
    String? userName,
    String? avatarUrl,
  }) async {
    _token = token;
    _userName = userName ?? 'Joueur';
    _avatarUrl = avatarUrl;
    
    // Charger les données locales
    await _loadLocalData();
    
    // Charger les données serveur
    await _loadServerData();
    
    // Démarrer le timer de régénération des vies
    _startLivesRegeneration();
    
    notifyListeners();
  }
  
  /// Charger les données depuis SharedPreferences
  Future<void> _loadLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pointsXP = prefs.getInt('user_xp') ?? 0;
      _coins = prefs.getInt('user_coins') ?? 0;
      _lives = prefs.getInt('user_lives') ?? 5;
      _currentStageLevel = prefs.getInt('user_current_stage') ?? 1;
      _maxUnlockedStage = prefs.getInt('user_max_stage') ?? 1;
      
      final lastUpdateStr = prefs.getString('user_last_lives_update');
      if (lastUpdateStr != null) {
        _lastLivesUpdate = DateTime.parse(lastUpdateStr);
        // Calculer les vies régénérées depuis la dernière mise à jour
        _regenerateLivesFromLastUpdate();
      }
    } catch (e) {
      debugPrint('Erreur chargement données locales: $e');
    }
  }
  
  /// Sauvegarder les données localement
  Future<void> _saveLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_xp', _pointsXP);
      await prefs.setInt('user_coins', _coins);
      await prefs.setInt('user_lives', _lives);
      await prefs.setInt('user_current_stage', _currentStageLevel);
      await prefs.setInt('user_max_stage', _maxUnlockedStage);
      if (_lastLivesUpdate != null) {
        await prefs.setString('user_last_lives_update', _lastLivesUpdate!.toIso8601String());
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde données locales: $e');
    }
  }
  
  /// Charger les données depuis le serveur
  Future<void> _loadServerData() async {
    if (_token == null) return;
    
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl('/results/stats')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final stats = data['data'];
          _pointsXP = stats['pointsXP'] ?? _pointsXP;
          _coins = stats['coins'] ?? _coins;
          _lives = stats['lives'] ?? _lives;
          _currentStageLevel = _extractStageNumber(stats['niveau'] ?? 'Stage 1');
          _maxUnlockedStage = stats['maxUnlockedStage'] ?? _currentStageLevel;
          
          await _saveLocalData();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement données serveur: $e');
    }
  }
  
  /// Extraire le numéro de stage d'une chaîne comme "Stage 5"
  int _extractStageNumber(String niveau) {
    final match = RegExp(r'\d+').firstMatch(niveau);
    return match != null ? int.parse(match.group(0)!) : 1;
  }
  
  /// Régénérer les vies depuis la dernière mise à jour
  void _regenerateLivesFromLastUpdate() {
    if (_lastLivesUpdate == null || _lives >= _maxLives) return;
    
    final elapsed = DateTime.now().difference(_lastLivesUpdate!).inSeconds;
    final livesToRegen = elapsed ~/ _livesRegenIntervalSeconds;
    
    if (livesToRegen > 0) {
      _lives = (_lives + livesToRegen).clamp(0, _maxLives);
      _lastLivesUpdate = DateTime.now();
      _saveLocalData();
    }
  }
  
  /// Démarrer le timer de régénération des vies
  void _startLivesRegeneration() {
    _livesRegenTimer?.cancel();
    _livesRegenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lives < _maxLives) {
        _lastLivesUpdate ??= DateTime.now();
        final elapsed = DateTime.now().difference(_lastLivesUpdate!).inSeconds;
        
        if (elapsed >= _livesRegenIntervalSeconds) {
          _lives = (_lives + 1).clamp(0, _maxLives);
          _lastLivesUpdate = DateTime.now();
          _saveLocalData();
          _syncLivesToServer();
          notifyListeners();
        }
      }
    });
  }
  
  /// Synchroniser les vies avec le serveur
  Future<void> _syncLivesToServer() async {
    if (_token == null) return;
    
    try {
      await http.post(
        Uri.parse(ApiEndpoints.buildUrl('/results/sync-lives')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'lives': _lives,
          'lastUpdate': _lastLivesUpdate?.toIso8601String(),
        }),
      );
    } catch (e) {
      debugPrint('Erreur sync vies: $e');
    }
  }
  
  /// Perdre une vie (appelé quand l'utilisateur se trompe)
  void loseLife() {
    if (_lives > 0) {
      _lives--;
      _lastLivesUpdate ??= DateTime.now();
      _saveLocalData();
      _syncLivesToServer();
      notifyListeners();
    }
  }
  
  /// Vérifier si l'utilisateur a des vies
  bool get hasLives => _lives > 0;
  
  /// Ajouter des XP
  void addXP(int amount) {
    _pointsXP += amount;
    _saveLocalData();
    notifyListeners();
  }
  
  /// Ajouter des pièces
  void addCoins(int amount) {
    _coins += amount;
    _saveLocalData();
    notifyListeners();
  }
  
  /// Dépenser des pièces
  bool spendCoins(int amount) {
    if (_coins >= amount) {
      _coins -= amount;
      _saveLocalData();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Acheter des vies avec des pièces
  bool buyLives(int livesToBuy, int cost) {
    if (spendCoins(cost)) {
      _lives = (_lives + livesToBuy).clamp(0, _maxLives);
      _saveLocalData();
      notifyListeners();
      return true;
    }
    return false;
  }
  
  /// Compléter un stage et débloquer le suivant
  Future<void> completeStage(int stageNumber) async {
    if (stageNumber >= _maxUnlockedStage) {
      _maxUnlockedStage = stageNumber + 1;
      _currentStageLevel = stageNumber + 1;
      await _saveLocalData();
      await _syncProgressToServer();
      notifyListeners();
    }
  }
  
  /// Mettre à jour après un quiz terminé
  Future<void> updateAfterQuiz({
    required int xpGained,
    required int coinsGained,
    required int livesLost,
    int? completedStage,
  }) async {
    _pointsXP += xpGained;
    _coins += coinsGained;
    _lives = (_lives - livesLost).clamp(0, _maxLives);
    
    if (completedStage != null && completedStage >= _maxUnlockedStage) {
      _maxUnlockedStage = completedStage + 1;
      _currentStageLevel = completedStage + 1;
    }
    
    if (_lives < _maxLives) {
      _lastLivesUpdate ??= DateTime.now();
    }
    
    await _saveLocalData();
    await _syncProgressToServer();
    notifyListeners();
  }
  
  /// Synchroniser la progression avec le serveur
  Future<void> _syncProgressToServer() async {
    if (_token == null) return;
    
    try {
      await http.post(
        Uri.parse(ApiEndpoints.buildUrl('/results/sync-progress')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'pointsXP': _pointsXP,
          'coins': _coins,
          'lives': _lives,
          'currentStageLevel': _currentStageLevel,
          'maxUnlockedStage': _maxUnlockedStage,
        }),
      );
    } catch (e) {
      debugPrint('Erreur sync progression: $e');
    }
  }
  
  /// Rafraîchir les données depuis le serveur
  Future<void> refresh() async {
    await _loadServerData();
  }
  
  @override
  void dispose() {
    _livesRegenTimer?.cancel();
    super.dispose();
  }
}
