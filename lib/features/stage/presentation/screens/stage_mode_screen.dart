import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../widgets/difficulty_selection_dialog.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Modèle pour un niveau du mode Stage
class StageLevel {
  final int idNiveau;
  final int numero;
  final String nom;
  final String difficulte;
  final int nombreQuestions;
  final int tempsParQuestion;
  final int xpRecompense;
  final int coinsRecompense;
  final int scoreMinimum;
  final bool estDebloque;

  // Progression du joueur (si connecté)
  final bool? estComplete;
  final int? meilleurScore;
  final int? nombreTentatives;
  final int? etoiles;

  StageLevel({
    required this.idNiveau,
    required this.numero,
    required this.nom,
    required this.difficulte,
    required this.nombreQuestions,
    required this.tempsParQuestion,
    required this.xpRecompense,
    required this.coinsRecompense,
    required this.scoreMinimum,
    required this.estDebloque,
    this.estComplete,
    this.meilleurScore,
    this.nombreTentatives,
    this.etoiles,
  });

  factory StageLevel.fromJson(Map<String, dynamic> json) {
    final progression = json['progression'];
    return StageLevel(
      idNiveau: json['id_niveau'] ?? json['idNiveau'],
      numero: json['numero'],
      nom: json['nom'],
      difficulte: json['difficulte'],
      nombreQuestions: json['nombre_questions'] ?? json['nombreQuestions'],
      tempsParQuestion: json['temps_par_question'] ?? json['tempsParQuestion'],
      xpRecompense: json['xp_recompense'] ?? json['xpRecompense'],
      coinsRecompense: json['coins_recompense'] ?? json['coinsRecompense'],
      scoreMinimum: json['score_minimum'] ?? json['scoreMinimum'],
      estDebloque: progression != null
          ? (progression['est_debloque'] ?? progression['estDebloque'] ?? json['est_debloque'] ?? true)
          : (json['est_debloque'] ?? json['estDebloque'] ?? true),
      estComplete: progression?['est_complete'] ?? progression?['estComplete'],
      meilleurScore: progression?['meilleur_score'] ?? progression?['meilleurScore'],
      nombreTentatives: progression?['nombre_tentatives'] ?? progression?['nombreTentatives'],
      etoiles: progression?['etoiles'],
    );
  }
}

/// Écran du mode Stage avec le chemin des niveaux en serpentin
class StageModeScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userPoints;
  final int? userLives;
  final String? avatarUrl;
  final String? token;

  const StageModeScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userPoints,
    this.userLives,
    this.avatarUrl,
    this.token,
  });

  @override
  State<StageModeScreen> createState() => _StageModeScreenState();
}

class _StageModeScreenState extends State<StageModeScreen> {
  List<StageLevel> _levels = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.stagesNiveaux)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final levelsList = data['data'] as List? ?? [];
        setState(() {
          _levels = levelsList.map((l) => StageLevel.fromJson(l)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur chargement niveaux: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Données de test en cas d'erreur
        _levels = _generateTestLevels();
      });
    }
  }

  List<StageLevel> _generateTestLevels() {
    final userState = context.read<UserStateProvider>();
    final maxUnlocked = userState.maxUnlockedStage;
    
    return List.generate(10, (index) {
      final numero = index + 1;
      String difficulte;
      if (numero <= 3) {
        difficulte = 'facile';
      } else if (numero <= 7) {
        difficulte = 'moyen';
      } else {
        difficulte = 'difficile';
      }

      return StageLevel(
        idNiveau: numero,
        numero: numero,
        nom: 'Niveau $numero',
        difficulte: difficulte,
        nombreQuestions: 10 + (numero * 2),
        tempsParQuestion: 30 - (numero ~/ 4),
        xpRecompense: numero * 100,
        coinsRecompense: numero * 50,
        scoreMinimum: 60 + (numero * 2),
        estDebloque: numero <= maxUnlocked, // Utiliser maxUnlockedStage du provider
        estComplete: numero < maxUnlocked ? true : null,
        meilleurScore: null,
        nombreTentatives: null,
        etoiles: null,
      );
    });
  }

  void _onLevelTap(StageLevel level) async {
    final userState = context.read<UserStateProvider>();
    final isUnlocked = level.numero <= userState.maxUnlockedStage;
    
    if (!isUnlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce niveau est verrouillé ! Terminez le niveau précédent.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Afficher le dialog de sélection de difficulté
    final difficulty = await DifficultySelectionDialog.show(
      context,
      initialDifficulty: _getDifficultyFromString(level.difficulte),
    );

    if (difficulty != null) {
      _startLevel(level, difficulty);
    }
  }

  Difficulty _getDifficultyFromString(String difficulte) {
    switch (difficulte.toLowerCase()) {
      case 'facile':
        return Difficulty.facile;
      case 'moyen':
        return Difficulty.moyen;
      case 'difficile':
        return Difficulty.difficile;
      default:
        return Difficulty.facile;
    }
  }

  void _startLevel(StageLevel level, Difficulty difficulty) {
    debugPrint('Démarrage niveau ${level.numero} en difficulté ${difficulty.label}');
    
    // Naviguer vers l'écran de quiz
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: widget.userName,
          userLevel: widget.userLevel,
          userLives: widget.userLives,
          userCoins: widget.userPoints,
          avatarUrl: widget.avatarUrl,
          token: widget.token,
          levelNumber: level.numero,
          difficute: difficulty.name,
          nombreQuestions: level.nombreQuestions,
          mode: 'stage',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/stage.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : _buildLevelPath(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<UserStateProvider>(
      builder: (context, userState, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  // Avatar utilisateur
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey.shade300,
                    backgroundImage: userState.avatarUrl != null
                        ? NetworkImage(userState.avatarUrl!)
                        : widget.avatarUrl != null
                            ? NetworkImage(widget.avatarUrl!)
                            : null,
                    child: (userState.avatarUrl == null && widget.avatarUrl == null)
                        ? const Icon(Icons.person, color: Colors.white, size: 24)
                        : null,
                  ),
                  const SizedBox(width: 10),

                  // Nom et niveau
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userState.userName.isNotEmpty ? userState.userName : (widget.userName ?? 'Joueur'),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          userState.userLevel,
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Stats: Vies
                  _buildStatBadge(
                    icon: Icons.favorite,
                    value: '${userState.lives.toString().padLeft(2, '0')}/${userState.maxLives.toString().padLeft(2, '0')}',
                    color: Colors.red,
                    bgColor: Colors.red.shade50,
                  ),
                  const SizedBox(width: 8),

                  // Stats: Coins
                  _buildStatBadge(
                    icon: Icons.monetization_on,
                    value: userState.coins.toString(),
                    color: Colors.orange,
                    bgColor: Colors.orange.shade50,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Titre avec bouton retour
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Bienvenu(e) au mode Stage',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Icon(icon, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _buildLevelPath() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // Afficher les niveaux de haut en bas (du plus élevé au plus bas)
          ..._buildLevelRows(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _buildLevelRows() {
    final List<Widget> rows = [];
    final reversedLevels = _levels.reversed.toList();

    for (int i = 0; i < reversedLevels.length; i++) {
      final level = reversedLevels[i];
      final isLeftAligned = (reversedLevels.length - 1 - i) % 2 == 0;

      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            mainAxisAlignment:
                isLeftAligned ? MainAxisAlignment.start : MainAxisAlignment.end,
            children: [
              if (!isLeftAligned) _buildPathLine(i, reversedLevels.length),
              _buildLevelNode(level),
              if (isLeftAligned) _buildPathLine(i, reversedLevels.length),
            ],
          ),
        ),
      );
    }

    return rows;
  }

  Widget _buildPathLine(int index, int total) {
    if (index == total - 1) return const SizedBox(width: 80);

    return CustomPaint(
      size: const Size(80, 80),
      painter: PathLinePainter(
        isReversed: index % 2 == 1,
      ),
    );
  }

  Widget _buildLevelNode(StageLevel level) {
    final userState = context.watch<UserStateProvider>();
    final isLocked = level.numero > userState.maxUnlockedStage;
    final isCompleted = level.numero < userState.maxUnlockedStage || level.estComplete == true;
    final stars = level.etoiles ?? (isCompleted ? 3 : 0);

    // Couleurs conformes à la maquette
    const Color lockColor = Color(0xFFE57373); // Orange/coral pour le cadenas
    const Color nodeBaseColor = Color(0xFFFAF5F0); // Beige/crème
    const Color nodeBorderColor = Color(0xFFE8E0D5); // Bordure beige foncé

    return GestureDetector(
      onTap: () => _onLevelTap(level),
      child: Column(
        children: [
          // Étoiles (si complété)
          if (isCompleted && stars > 0) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => Icon(
                  i < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],

          // Cercle externe (ombre/halo)
          Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: nodeBorderColor.withOpacity(0.5),
            ),
            child: Center(
              // Noeud du niveau
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: nodeBaseColor,
                  border: Border.all(
                    color: nodeBorderColor,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: isLocked
                      ? Icon(
                          Icons.lock,
                          color: lockColor,
                          size: 26,
                        )
                      : Text(
                          level.numero.toString().padLeft(2, '0'),
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter pour dessiner les lignes de connexion entre les niveaux
class PathLinePainter extends CustomPainter {
  final bool isReversed;

  PathLinePainter({this.isReversed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Dessiner une ligne simple
    final path = Path();
    if (isReversed) {
      path.moveTo(0, size.height * 0.3);
      path.lineTo(size.width * 0.8, size.height * 0.7);
    } else {
      path.moveTo(size.width, size.height * 0.3);
      path.lineTo(size.width * 0.2, size.height * 0.7);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
