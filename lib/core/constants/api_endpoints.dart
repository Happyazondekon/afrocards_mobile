/// 🌐 API ENDPOINTS - AFROCARDS
/// Tous les endpoints de l'API Backend

class ApiEndpoints {
  // ========================================
  // 🔧 CONFIGURATION DE BASE
  // ========================================

  /// URL de base de l'API (à mettre dans .env en production)
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  // Pour production, utilisez :
  // static const String baseUrl = 'https://api.afrocards.com/api';

  /// Timeout des requêtes (en millisecondes)
  static const int connectTimeout = 30000; // 30 secondes
  static const int receiveTimeout = 30000; // 30 secondes

  // ========================================
  // 🔐 AUTHENTIFICATION
  // ========================================

  /// POST - Inscription d'un nouvel utilisateur
  static const String register = '/auth/inscription';

  /// POST - Connexion
  static const String login = '/auth/connexion';

  /// GET - Obtenir le profil de l'utilisateur connecté
  static const String profile = '/auth/profil';

  /// POST - Déconnexion
  static const String logout = '/auth/deconnexion';

  // ========================================
  // 🔑 MOT DE PASSE
  // ========================================
  /// POST - Demander réinitialisation mot de passe
  static const String forgotPassword = '/password/forgot-password';

  /// POST - Réinitialiser le mot de passe
  static const String resetPassword = '/password/reset-password';

  /// POST - Changer son mot de passe (utilisateur connecté)
  static const String changePassword = '/password/change-password';

  /// GET - Vérifier la validité d'un token
  static String verifyResetToken(String token) => '/password/verify-token/$token';

  // ========================================
  // 📚 QUIZ
  // ========================================

  /// GET - Liste de tous les quiz
  static const String quizzes = '/quizzes';

  /// GET - Détails d'un quiz spécifique
  static String quizById(int id) => '/quizzes/$id';

  /// POST - Créer un quiz (Admin)
  static const String createQuiz = '/quizzes';

  // ========================================
  // 🎮 GAMEPLAY
  // ========================================

  /// GET - Démarrer une partie de quiz
  static String startQuizGame(int quizId) => '/gameplay/quiz/$quizId/start';

  /// POST - Valider une réponse
  static const String validateAnswer = '/gameplay/validate-answer';

  // ========================================
  // 🎲 PARTIES
  // ========================================

  /// POST - Démarrer une nouvelle partie
  static const String startPartie = '/parties/start';

  /// PUT - Mettre à jour la progression
  static String updateProgress(int partieId) => '/parties/$partieId/progress';

  /// PUT - Terminer une partie
  static String endPartie(int partieId) => '/parties/$partieId/end';

  /// GET - Historique des parties du joueur
  static const String partiesHistory = '/parties/history';

  // ========================================
  // � RÉSULTATS
  // ========================================

  /// POST - Sauvegarder les résultats d'un quiz
  static const String saveResults = '/results/save';

  /// GET - Historique des résultats
  static const String resultsHistory = '/results/history';

  /// GET - Statistiques du joueur
  static const String playerStats = '/results/stats';

  // ========================================
  // �💰 ÉCONOMIE
  // ========================================

  /// GET - Obtenir le portefeuille (Coins + Vies)
  static const String portefeuille = '/economie/portefeuille';

  /// POST - Acheter un item
  static const String acheter = '/economie/acheter';

  /// GET - Historique des transactions
  static const String transactionHistory = '/economie/historique';

  // ========================================
  // 🏆 CLASSEMENT
  // ========================================

  /// GET - Classement global
  static const String classementGlobal = '/classement/global';

  /// GET - Classement par pays
  static String classementPays(String pays) => '/classement/pays/$pays';

  /// GET - Ma position dans le classement
  static const String myRank = '/classement/me';

  // ========================================
  // 🎁 GAMIFICATION
  // ========================================

  /// GET - Mes badges et trophées
  static const String myRewards = '/gamification/my-rewards';

  /// POST - Créer un badge (Admin)
  static const String createBadge = '/gamification/badges';

  // ========================================
  // 💬 SOCIAL
  // ========================================

  /// POST - Envoyer un message
  static const String sendMessage = '/social/messages';

  /// GET - Conversation avec un joueur
  static String getConversation(int joueurId) => '/social/messages/$joueurId';

  /// GET - Mes notifications
  static const String notifications = '/social/notifications';

  /// PUT - Marquer une notification comme lue
  static String markNotificationAsRead(int notifId) => '/social/notifications/$notifId/read';

  /// PUT - Marquer toutes les notifications comme lues
  static const String markAllAsRead = '/social/notifications/read-all';

  /// PUT - Modifier mes préférences de notification
  static const String updateNotificationPrefs = '/social/preferences';

  // ========================================
  // 📁 CATÉGORIES
  // ========================================

  /// GET - Liste des catégories
  static const String categories = '/categories';

  /// GET - Détails d'une catégorie
  static String categoryById(int id) => '/categories/$id';

  // ========================================
  // 🎯 MODES DE JEU
  // ========================================

  /// GET - Liste des modes de jeu
  static const String modes = '/modes';

  /// GET - Détails d'un mode de jeu
  static String modeById(int id) => '/modes/$id';

  // ========================================
  // 🎮 NIVEAUX (MODE STAGE)
  // ========================================

  /// GET - Liste des niveaux du mode Stage avec progression
  static const String stagesNiveaux = '/niveaux/stages';

  /// GET - Niveaux par mode de jeu
  static String niveauxByMode(int idMode) => '/niveaux/mode/$idMode';

  /// GET - Détails d'un niveau
  static String niveauById(int id) => '/niveaux/$id';

  /// PUT - Mettre à jour la progression d'un niveau
  static String updateNiveauProgression(int idNiveau) =>
      '/niveaux/$idNiveau/progression';

  // ========================================
  // 🎉 MODE FIESTA
  // ========================================

  /// GET - Liste des sous-modes Fiesta (Challenges, Aléatoire, Défier des amis)
  static const String fiestaSousModes = '/sous-modes/fiesta';

  /// GET - Détails d'un sous-mode
  static String sousModeById(int id) => '/sous-modes/$id';

  /// GET - Liste des challenges disponibles
  static const String challenges = '/fiesta/challenges';

  /// GET - Détails d'un challenge
  static String challengeById(int id) => '/fiesta/challenges/$id';

  /// POST - Participer à un challenge
  static String joinChallenge(int id) => '/fiesta/challenges/$id/join';

  /// GET - Quiz aléatoire
  static const String randomQuiz = '/fiesta/random';

  /// POST - Démarrer un quiz aléatoire
  static const String startRandomQuiz = '/fiesta/random/start';

  /// GET - Liste des amis pour défier
  static const String friendsToChallenge = '/fiesta/friends';

  /// POST - Envoyer un défi à un ami
  static String challengeFriend(int friendId) => '/fiesta/friends/$friendId/challenge';

  /// GET - Défis reçus / en attente
  static const String pendingChallenges = '/fiesta/challenges/pending';

  // ========================================
  // ❓ QUESTIONS
  // ========================================

  /// GET - Questions aléatoires
  static const String randomQuestions = '/questions/random';

  /// GET - Questions par catégorie
  static String questionsByCategory(int idCategorie) =>
      '/questions/category/$idCategorie';

  /// GET - Questions pour un niveau (mode Stage)
  static String questionsForLevel(int levelNumber) =>
      '/questions/level/$levelNumber';

  /// GET - Une question par son ID
  static String questionById(int idQuestion) => '/questions/$idQuestion';

  /// GET - Explication d'une question
  static String questionExplication(int idQuestion) =>
      '/questions/$idQuestion/explication';

  /// POST - Vérifier une réponse
  static String verifyAnswer(int idQuestion) => '/questions/$idQuestion/verify';

  /// GET - Statistiques des questions
  static const String questionsStats = '/questions/stats';

  // ========================================
  // 📤 UPLOAD
  // ========================================

  /// POST - Upload avatar
  static const String uploadAvatar = '/upload/avatar';

  /// POST - Upload média pour question (Admin)
  static const String uploadQuestionMedia = '/upload/question-media';

  // ========================================
  // 👤 PROFIL JOUEUR
  // ========================================

  /// GET - Mon profil complet
  static const String myProfile = '/auth/profil';

  /// PUT - Modifier mon profil
  static const String updateProfile = '/auth/profil';

  // ========================================
  // 🛠️ ADMIN
  // ========================================

  /// GET - Statistiques du dashboard admin
  static const String adminDashboard = '/admin/dashboard';

  /// GET - Liste de tous les utilisateurs
  static const String adminUsers = '/admin/users';

  /// PUT - Modifier le statut d'un utilisateur
  static String adminUpdateUserStatus(int userId) => '/admin/users/$userId/status';

  /// PUT - Modifier le rôle d'un utilisateur
  static String adminUpdateUserRole(int userId) => '/admin/users/$userId/role';

  // ========================================
  // 🤝 PARTENAIRES
  // ========================================

  /// POST - Mettre à jour profil partenaire
  static const String partnerProfile = '/partenaires/profil';

  /// POST - Créer un challenge
  static const String createChallenge = '/partenaires/challenges';

  /// GET - Mes challenges
  static const String myChallenges = '/partenaires/challenges';

  /// POST - Créer une promotion
  static const String createPromotion = '/partenaires/promotions';

  /// POST - Créer une publicité
  static const String createPublicite = '/partenaires/publicites';

  // ========================================
  // 🔍 HELPERS
  // ========================================

  /// Construit l'URL complète
  static String buildUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Ajoute des query parameters à une URL
  static String addQueryParams(String url, Map<String, dynamic> params) {
    if (params.isEmpty) return url;

    final uri = Uri.parse(url);
    final newUri = uri.replace(queryParameters: params.map(
          (key, value) => MapEntry(key, value.toString()),
    ));

    return newUri.toString();
  }
}