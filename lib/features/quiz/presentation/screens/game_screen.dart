import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../challenge/presentation/screens/challenge_result_screen.dart';
import '../../../challenge/presentation/screens/friend_challenge_result_screen.dart';
import 'result_screen.dart';

/// Modèle pour une réponse
class Answer {
  final int idReponse;
  final String texte;
  final bool estCorrecte;

  Answer({
    required this.idReponse,
    required this.texte,
    this.estCorrecte = false,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      idReponse: json['idReponse'] ?? json['id_reponse'],
      texte: json['texte'],
      estCorrecte: json['estCorrecte'] ?? json['est_correcte'] ?? false,
    );
  }
}

/// Modèle pour une question
class Question {
  final int idQuestion;
  final String texte;
  final String? mediaURL;
  final String difficulte;
  final int points;
  final int tempsReponse;
  final List<Answer> reponses;
  final String? categorieNom;

  Question({
    required this.idQuestion,
    required this.texte,
    this.mediaURL,
    this.difficulte = 'moyen',
    this.points = 10,
    this.tempsReponse = 30,
    this.reponses = const [],
    this.categorieNom,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final reponsesRaw = json['Reponses'] as List? ?? [];
    return Question(
      idQuestion: json['idQuestion'] ?? json['id_question'],
      texte: json['texte'],
      mediaURL: json['mediaURL'] ?? json['media_u_r_l'],
      difficulte: json['difficulte'] ?? 'moyen',
      points: json['points'] ?? 10,
      tempsReponse: json['tempsReponse'] ?? json['temps_reponse'] ?? 30,
      reponses: reponsesRaw.map((r) => Answer.fromJson(r)).toList(),
      categorieNom: json['categorieDirecte']?['nom'],
    );
  }
}

/// Modèle pour l'explication
class Explication {
  final int idExplication;
  final String texte;
  final String? source;
  final String? lienRessource;

  Explication({
    required this.idExplication,
    required this.texte,
    this.source,
    this.lienRessource,
  });

  factory Explication.fromJson(Map<String, dynamic> json) {
    return Explication(
      idExplication: json['idExplication'] ?? json['id_explication'] ?? 0,
      texte: json['texte'] ?? '',
      source: json['source'],
      lienRessource: json['lienRessource'] ?? json['lien_ressource'],
    );
  }
}

/// Écran de jeu quiz
class GameScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userLives;
  final int? userCoins;
  final String? avatarUrl;
  final String? token;

  // Paramètres de quiz
  final int? idCategorie;
  final int? levelNumber;
  final String? difficute;
  final int nombreQuestions;
  final String mode; // 'stage', 'fiesta', 'challenge', 'random'

  // Paramètres challenge
  final String? challengeId;
  final String? opponentName;
  final int? opponentId;

  const GameScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userLives,
    this.userCoins,
    this.avatarUrl,
    this.token,
    this.idCategorie,
    this.levelNumber,
    this.difficute,
    this.nombreQuestions = 10,
    this.mode = 'random',
    this.challengeId,
    this.opponentName,
    this.opponentId,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int _totalPoints = 0;
  int _livesLost = 0;  // Compteur de vies perdues
  bool _isLoading = true;
  String? _error;

  // Réponse sélectionnée
  int? _selectedAnswerId;
  bool _hasAnswered = false;
  bool? _isCorrect;
  Answer? _correctAnswer;

  // Timer
  late int _timeRemaining;
  Timer? _timer;
  late AnimationController _timerAnimationController;

  // Explication
  Explication? _currentExplication;
  bool _showExplication = false;

  @override
  void initState() {
    super.initState();
    _timerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      String endpoint;

      // Déterminer l'endpoint selon le mode
      if (widget.mode == 'stage' && widget.levelNumber != null) {
        endpoint = ApiEndpoints.questionsForLevel(widget.levelNumber!);
        if (widget.idCategorie != null) {
          endpoint += '?idCategorie=${widget.idCategorie}';
        }
      } else if (widget.idCategorie != null) {
        endpoint = ApiEndpoints.questionsByCategory(widget.idCategorie!);
        endpoint += '?limit=${widget.nombreQuestions}';
        if (widget.difficute != null) {
          endpoint += '&difficulte=${widget.difficute}';
        }
      } else {
        endpoint = ApiEndpoints.randomQuestions;
        endpoint += '?limit=${widget.nombreQuestions}';
        if (widget.difficute != null) {
          endpoint += '&difficulte=${widget.difficute}';
        }
      }

      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(endpoint)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questionsList = data['data'] as List? ?? [];

        setState(() {
          _questions =
              questionsList.map((q) => Question.fromJson(q)).toList();
          _isLoading = false;
        });

        if (_questions.isNotEmpty) {
          _startTimer();
        }
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur chargement questions: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Données de test
        _questions = _generateTestQuestions();
      });
      if (_questions.isNotEmpty) {
        _startTimer();
      }
    }
  }

  List<Question> _generateTestQuestions() {
    return [
      Question(
        idQuestion: 1,
        texte: 'Quel est le plus grand pays d\'Afrique en superficie ?',
        mediaURL: 'https://images.unsplash.com/photo-1489749798305-4fea3ae63d43?w=400',
        difficulte: 'facile',
        points: 10,
        tempsReponse: 30,
        reponses: [
          Answer(idReponse: 1, texte: 'Algérie', estCorrecte: true),
          Answer(idReponse: 2, texte: 'Soudan', estCorrecte: false),
          Answer(idReponse: 3, texte: 'RDC', estCorrecte: false),
          Answer(idReponse: 4, texte: 'Libye', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 2,
        texte: 'Quelle est la plus haute montagne d\'Afrique ?',
        mediaURL: 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=400',
        difficulte: 'facile',
        points: 10,
        tempsReponse: 30,
        reponses: [
          Answer(idReponse: 5, texte: 'Mont Kenya', estCorrecte: false),
          Answer(idReponse: 6, texte: 'Mont Kilimandjaro', estCorrecte: true),
          Answer(idReponse: 7, texte: 'Mont Stanley', estCorrecte: false),
          Answer(idReponse: 8, texte: 'Mont Cameroun', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 3,
        texte: 'Quel fleuve traverse l\'Égypte ?',
        mediaURL: 'https://images.unsplash.com/photo-1539768942893-daf53e448371?w=400',
        difficulte: 'facile',
        points: 10,
        tempsReponse: 30,
        reponses: [
          Answer(idReponse: 9, texte: 'Le Congo', estCorrecte: false),
          Answer(idReponse: 10, texte: 'Le Niger', estCorrecte: false),
          Answer(idReponse: 11, texte: 'Le Nil', estCorrecte: true),
          Answer(idReponse: 12, texte: 'Le Zambèze', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 4,
        texte: 'Quelle est la capitale du Sénégal ?',
        mediaURL: 'https://images.unsplash.com/photo-1591198619986-978815c8c3c5?w=400',
        difficulte: 'facile',
        points: 10,
        tempsReponse: 30,
        reponses: [
          Answer(idReponse: 13, texte: 'Saint-Louis', estCorrecte: false),
          Answer(idReponse: 14, texte: 'Dakar', estCorrecte: true),
          Answer(idReponse: 15, texte: 'Thiès', estCorrecte: false),
          Answer(idReponse: 16, texte: 'Ziguinchor', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 5,
        texte: 'Qui est considéré comme le père de l\'indépendance du Ghana ?',
        mediaURL: 'https://images.unsplash.com/photo-1580746738629-5e0b4ae1e9f4?w=400',
        difficulte: 'moyen',
        points: 15,
        tempsReponse: 25,
        reponses: [
          Answer(idReponse: 17, texte: 'Nelson Mandela', estCorrecte: false),
          Answer(idReponse: 18, texte: 'Kwame Nkrumah', estCorrecte: true),
          Answer(idReponse: 19, texte: 'Jomo Kenyatta', estCorrecte: false),
          Answer(idReponse: 20, texte: 'Patrice Lumumba', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 6,
        texte: 'En quelle année Nelson Mandela a-t-il été libéré de prison ?',
        mediaURL: 'https://images.unsplash.com/photo-1577495508048-b635879837f1?w=400',
        difficulte: 'moyen',
        points: 15,
        tempsReponse: 25,
        reponses: [
          Answer(idReponse: 21, texte: '1985', estCorrecte: false),
          Answer(idReponse: 22, texte: '1988', estCorrecte: false),
          Answer(idReponse: 23, texte: '1990', estCorrecte: true),
          Answer(idReponse: 24, texte: '1994', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 7,
        texte: 'Quel artiste a chanté "Pata Pata" ?',
        mediaURL: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400',
        difficulte: 'moyen',
        points: 15,
        tempsReponse: 25,
        reponses: [
          Answer(idReponse: 25, texte: 'Fela Kuti', estCorrecte: false),
          Answer(idReponse: 26, texte: 'Miriam Makeba', estCorrecte: true),
          Answer(idReponse: 27, texte: 'Youssou N\'Dour', estCorrecte: false),
          Answer(idReponse: 28, texte: 'Salif Keita', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 8,
        texte: 'Quel pays africain n\'a jamais été colonisé ?',
        mediaURL: 'https://images.unsplash.com/photo-1523906834658-6e24ef2386f9?w=400',
        difficulte: 'moyen',
        points: 15,
        tempsReponse: 25,
        reponses: [
          Answer(idReponse: 29, texte: 'Maroc', estCorrecte: false),
          Answer(idReponse: 30, texte: 'Éthiopie', estCorrecte: true),
          Answer(idReponse: 31, texte: 'Égypte', estCorrecte: false),
          Answer(idReponse: 32, texte: 'Tunisie', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 9,
        texte: 'Quel est le plus grand lac d\'Afrique ?',
        mediaURL: 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=400',
        difficulte: 'facile',
        points: 10,
        tempsReponse: 30,
        reponses: [
          Answer(idReponse: 33, texte: 'Lac Tchad', estCorrecte: false),
          Answer(idReponse: 34, texte: 'Lac Victoria', estCorrecte: true),
          Answer(idReponse: 35, texte: 'Lac Tanganyika', estCorrecte: false),
          Answer(idReponse: 36, texte: 'Lac Malawi', estCorrecte: false),
        ],
      ),
      Question(
        idQuestion: 10,
        texte: 'Quel pays a pour capitale Addis-Abeba ?',
        mediaURL: 'https://images.unsplash.com/photo-1580746738629-5e0b4ae1e9f4?w=400',
        difficulte: 'facile',
        points: 10,
        tempsReponse: 30,
        reponses: [
          Answer(idReponse: 37, texte: 'Kenya', estCorrecte: false),
          Answer(idReponse: 38, texte: 'Éthiopie', estCorrecte: true),
          Answer(idReponse: 39, texte: 'Somalie', estCorrecte: false),
          Answer(idReponse: 40, texte: 'Érythrée', estCorrecte: false),
        ],
      ),
    ];
  }

  void _startTimer() {
    final currentQuestion = _questions[_currentQuestionIndex];
    _timeRemaining = currentQuestion.tempsReponse;

    _timerAnimationController.duration = Duration(seconds: _timeRemaining);
    _timerAnimationController.reset();
    _timerAnimationController.forward();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0 && !_hasAnswered) {
        setState(() {
          _timeRemaining--;
        });
      } else if (_timeRemaining <= 0 && !_hasAnswered) {
        _onTimeUp();
      }
    });
  }

  void _onTimeUp() {
    _timer?.cancel();
    setState(() {
      _hasAnswered = true;
      _isCorrect = false;
      _correctAnswer = _questions[_currentQuestionIndex]
          .reponses
          .firstWhere((a) => a.estCorrecte, orElse: () => _questions[_currentQuestionIndex].reponses.first);
    });
  }

  void _selectAnswer(Answer answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswerId = answer.idReponse;
    });
  }

  Future<void> _confirmAnswer() async {
    if (_selectedAnswerId == null || _hasAnswered) return;

    _timer?.cancel();
    _timerAnimationController.stop();

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = currentQuestion.reponses
        .firstWhere((a) => a.idReponse == _selectedAnswerId);

    setState(() {
      _hasAnswered = true;
      _isCorrect = selectedAnswer.estCorrecte;
      _correctAnswer = currentQuestion.reponses
          .firstWhere((a) => a.estCorrecte, orElse: () => selectedAnswer);
    });

    if (_isCorrect == true) {
      // Calculer les points avec bonus temps
      int pointsGagnes = currentQuestion.points;
      int tempsUtilise = currentQuestion.tempsReponse - _timeRemaining;
      if (tempsUtilise < 5) {
        pointsGagnes = (pointsGagnes * 1.5).round();
      } else if (tempsUtilise < 10) {
        pointsGagnes = (pointsGagnes * 1.2).round();
      }

      setState(() {
        _score++;
        _totalPoints += pointsGagnes;
      });
    } else {
      // Mauvaise réponse - perdre une vie
      _livesLost++;
      final userState = context.read<UserStateProvider>();
      userState.loseLife();
      
      // Vérifier si plus de vies
      if (!userState.hasLives) {
        _showGameOverDialog();
        return;
      }
    }

    // Charger l'explication
    _loadExplication(currentQuestion.idQuestion);
  }

  Future<void> _loadExplication(int idQuestion) async {
    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(
            ApiEndpoints.questionExplication(idQuestion))),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['data']?['explication'] != null) {
          setState(() {
            _currentExplication =
                Explication.fromJson(data['data']['explication']);
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement explication: $e');
      // Explication de test
      setState(() {
        _currentExplication = Explication(
          idExplication: 1,
          texte:
              'L\'Algérie est le plus grand pays d\'Afrique avec une superficie de 2 381 741 km². Après la sécession du Soudan du Sud en 2011, l\'Algérie est devenue le plus grand pays du continent.',
          source: 'Nations Unies',
        );
      });
    }
  }

  void _skipQuestion() {
    _timer?.cancel();
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswerId = null;
        _hasAnswered = false;
        _isCorrect = null;
        _correctAnswer = null;
        _currentExplication = null;
        _showExplication = false;
      });
      _startTimer();
    } else {
      // Fin du quiz
      _showResults();
    }
  }

  void _showResults() {
    // Mode challenge : naviguer vers ChallengeResultScreen
    if (widget.mode == 'challenge') {
      final opponentScore = _generateOpponentScore();
      final isWinner = _score > opponentScore;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeResultScreen(
            userName: widget.userName,
            token: widget.token,
            playerScore: _score,
            opponentScore: opponentScore,
            opponentName: widget.opponentName ?? 'Adversaire',
            totalQuestions: _questions.length,
            xpGained: _totalPoints,
            coinsGained: _score * 5,
            isWinner: isWinner,
          ),
        ),
      );
      return;
    }

    // Mode défi ami : naviguer vers FriendChallengeResultScreen
    if (widget.mode == 'friend_challenge') {
      final opponentScore = _generateOpponentScore();
      final isWinner = _score > opponentScore;
      final userState = context.read<UserStateProvider>();
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => FriendChallengeResultScreen(
            userName: widget.userName,
            token: widget.token,
            playerScore: _score,
            opponentScore: opponentScore,
            opponentName: widget.opponentName ?? 'Ami',
            playerAvatarUrl: userState.avatarUrl,
            totalQuestions: _questions.length,
            xpGained: _totalPoints,
            coinsGained: _score * 5,
            isWinner: isWinner,
          ),
        ),
      );
      return;
    }
    
    // Mode normal : naviguer vers ResultScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ResultScreen(
          userName: widget.userName,
          userLevel: widget.userLevel,
          userLives: widget.userLives,
          userCoins: widget.userCoins,
          avatarUrl: widget.avatarUrl,
          token: widget.token,
          score: _score,
          totalQuestions: _questions.length,
          totalPoints: _totalPoints,
          levelNumber: widget.levelNumber,
          mode: widget.mode,
          livesLost: _livesLost,
        ),
      ),
    );
  }
  
  /// Génère un score aléatoire pour l'adversaire (simulation)
  int _generateOpponentScore() {
    // Simuler un score d'adversaire basé sur la difficulté
    final random = DateTime.now().millisecondsSinceEpoch % 100;
    final maxScore = _questions.length;
    
    if (random < 30) {
      // 30% chance: adversaire fait moins bien
      return (_score * 0.5).round().clamp(0, maxScore);
    } else if (random < 70) {
      // 40% chance: scores proches
      return (_score + (random % 3) - 1).clamp(0, maxScore);
    } else {
      // 30% chance: adversaire fait mieux
      return ((_score + 1) + (random % 2)).clamp(0, maxScore);
    }
  }
  
  void _showGameOverDialog() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.heart_broken, color: Colors.red[400], size: 32),
            const SizedBox(width: 8),
            const Text('Game Over'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Tu n\'as plus de vies !',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $_score / ${_questions.length}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Points: $_totalPoints',
              style: TextStyle(
                fontSize: 16,
                color: Colors.orange[700],
              ),
            ),
            const SizedBox(height: 16),
            Consumer<UserStateProvider>(
              builder: (context, userState, child) {
                return Text(
                  'Prochaine vie dans ${userState.secondsUntilNextLife}s',
                  style: TextStyle(color: Colors.grey[600]),
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context); // Retourner en arrière
            },
            child: const Text('Quitter'),
          ),
          ElevatedButton(
            onPressed: () {
              final userState = context.read<UserStateProvider>();
              if (userState.buyLives(1, 50)) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('+1 vie ! Continue à jouer !'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pas assez de pièces'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B4EAA),
            ),
            child: const Text('Acheter 1 vie (50 🪙)', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExplicationDialog() {
    setState(() {
      _showExplication = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF6B4EAA)),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Aucune question disponible'),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadQuestions,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_showExplication && _currentExplication != null) {
      return _buildExplicationScreen();
    }

    return _buildQuizScreen();
  }

  Widget _buildQuizScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header avec infos utilisateur
                const AppHeader(),

                // Question counter et timer
                _buildQuestionHeader(currentQuestion),

                // Contenu de la question
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Image de la question
                        if (currentQuestion.mediaURL != null) _buildQuestionImage(currentQuestion),

                        const SizedBox(height: 20),

                        // Texte de la question
                        _buildQuestionText(currentQuestion),

                        const SizedBox(height: 24),

                        // Options de réponse
                        _buildAnswerOptions(currentQuestion),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Boutons d'action
                _buildActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(Question question) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              // Bouton retour
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
              const SizedBox(width: 16),

              // Question counter
              Expanded(
                child: Text(
                  'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),

              // Bouton aide (?)
              GestureDetector(
                onTap: _hasAnswered && _currentExplication != null
                    ? _showExplicationDialog
                    : null,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _hasAnswered && _currentExplication != null
                        ? const Color(0xFF6B4EAA).withOpacity(0.1)
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.help_outline,
                    color: _hasAnswered && _currentExplication != null
                        ? const Color(0xFF6B4EAA)
                        : Colors.grey,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Score actuel
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_totalPoints',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.star, color: Colors.amber.shade700, size: 16),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Timer bar
          if (!_hasAnswered) _buildTimerBar(),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = _timeRemaining / currentQuestion.tempsReponse;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.grey.shade200,
      ),
      child: Stack(
        children: [
          // Progress
          FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: progress > 0.3
                      ? [const Color(0xFFE8B931), const Color(0xFFD4A422)]
                      : [Colors.red.shade400, Colors.red.shade600],
                ),
              ),
            ),
          ),

          // Timer text
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_timeRemaining}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, color: Colors.white, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionImage(Question question) {
    return Stack(
      children: [
        // Décorations autour de l'image
        Positioned(
          left: 0,
          top: 20,
          child: _buildDecorDot(Colors.blue, 8),
        ),
        Positioned(
          right: 40,
          top: 0,
          child: _buildDecorDot(Colors.green, 6),
        ),
        Positioned(
          right: 0,
          bottom: 30,
          child: _buildDecorStar(Colors.purple),
        ),
        Positioned(
          left: 30,
          bottom: 0,
          child: _buildDecorDot(Colors.pink, 10),
        ),

        // Image
        Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                question.mediaURL!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 200,
                    height: 150,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image_not_supported, size: 48),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDecorDot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildDecorStar(Color color) {
    return Icon(Icons.star_border, color: color, size: 16);
  }

  Widget _buildQuestionText(Question question) {
    return Text(
      question.texte,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  Widget _buildAnswerOptions(Question question) {
    return Column(
      children: question.reponses.map((answer) {
        final isSelected = _selectedAnswerId == answer.idReponse;
        final isCorrectAnswer = answer.estCorrecte;

        Color backgroundColor = Colors.white;
        Color borderColor = Colors.grey.shade200;
        Color textColor = Colors.black87;

        if (_hasAnswered) {
          if (isCorrectAnswer) {
            backgroundColor = Colors.green.shade50;
            borderColor = Colors.green;
            textColor = Colors.green.shade700;
          } else if (isSelected && !isCorrectAnswer) {
            backgroundColor = Colors.red.shade50;
            borderColor = Colors.red;
            textColor = Colors.red.shade700;
          }
        } else if (isSelected) {
          backgroundColor = const Color(0xFF6B4EAA).withOpacity(0.1);
          borderColor = const Color(0xFF6B4EAA);
          textColor = const Color(0xFF6B4EAA);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: _hasAnswered ? null : () => _selectAnswer(answer),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      answer.texte,
                      style: TextStyle(
                        fontSize: 15,
                        color: textColor,
                        fontWeight:
                            isSelected || (_hasAnswered && isCorrectAnswer)
                                ? FontWeight.w600
                                : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (_hasAnswered && isCorrectAnswer)
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                  if (_hasAnswered && isSelected && !isCorrectAnswer)
                    Icon(Icons.cancel, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Bouton Passer
          Expanded(
            child: TextButton(
              onPressed: _hasAnswered ? null : _skipQuestion,
              child: Text(
                'Passer',
                style: TextStyle(
                  fontSize: 16,
                  color: _hasAnswered ? Colors.grey : Colors.black54,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Bouton Confirmer / Continuer
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _hasAnswered
                  ? _nextQuestion
                  : (_selectedAnswerId != null ? _confirmAnswer : null),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8DFA0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                _hasAnswered ? 'Continuer' : 'Confirmer',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Bouton aide / indice
          GestureDetector(
            onTap: _hasAnswered && _currentExplication != null
                ? _showExplicationDialog
                : null,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasAnswered ? Icons.help_outline : Icons.lightbulb_outline,
                color: _hasAnswered && _currentExplication != null
                    ? const Color(0xFF6B4EAA)
                    : Colors.grey,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplicationScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                const AppHeader(),

                // Question number
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showExplication = false;
                      });
                    },
                    child: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showExplication = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B4EAA).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.help,
                        color: Color(0xFF6B4EAA),
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Score
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$_totalPoints',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.star, color: Colors.amber.shade700, size: 18),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    if (currentQuestion.mediaURL != null)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            currentQuestion.mediaURL!,
                            height: 180,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Icônes d'action
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 24),
                        const SizedBox(width: 16),
                        const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 22),
                        const SizedBox(width: 16),
                        const Icon(Icons.share, color: Colors.grey, size: 22),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Texte d'explication
                    Text(
                      _currentExplication!.texte,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),

                    if (_currentExplication!.source != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Source: ${_currentExplication!.source}',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Voir plus',
                        style: TextStyle(color: Color(0xFF6B4EAA)),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton Continuer
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showExplication = false;
                    });
                    _nextQuestion();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8DFA0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Continuer',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
