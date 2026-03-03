import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../challenge/presentation/screens/challenge_question_count_screen.dart';
import '../../../challenge/presentation/screens/friend_selection_screen.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Modèle pour un sous-mode Fiesta
class FiestaSubMode {
  final int idSousMode;
  final String nom;
  final String? description;
  final String? icone;
  final int ordre;
  final Map<String, dynamic>? configuation;

  FiestaSubMode({
    required this.idSousMode,
    required this.nom,
    this.description,
    this.icone,
    this.ordre = 1,
    this.configuation,
  });

  factory FiestaSubMode.fromJson(Map<String, dynamic> json) {
    return FiestaSubMode(
      idSousMode: json['idSousMode'] ?? json['id_sous_mode'],
      nom: json['nom'],
      description: json['description'],
      icone: json['icone'],
      ordre: json['ordre'] ?? 1,
      configuation: json['configuation'],
    );
  }
}

/// Écran du mode Fiesta avec sélection des sous-modes
class FiestaModeScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userPoints;
  final int? userLives;
  final String? avatarUrl;
  final String? token;

  const FiestaModeScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userPoints,
    this.userLives,
    this.avatarUrl,
    this.token,
  });

  @override
  State<FiestaModeScreen> createState() => _FiestaModeScreenState();
}

class _FiestaModeScreenState extends State<FiestaModeScreen> {
  List<FiestaSubMode> _subModes = [];
  bool _isLoading = true;
  String? _error;
  FiestaSubMode? _selectedSubMode;

  @override
  void initState() {
    super.initState();
    _loadSubModes();
  }

  Future<void> _loadSubModes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.fiestaSousModes)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final subModesList = data['data'] as List? ?? [];
        setState(() {
          _subModes = subModesList.map((s) => FiestaSubMode.fromJson(s)).toList();
          _isLoading = false;
        });
        debugPrint('Sous-modes Fiesta chargés: ${_subModes.length}');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Erreur chargement sous-modes: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Données de test en cas d'erreur
        _subModes = _generateTestSubModes();
      });
    }
  }

  List<FiestaSubMode> _generateTestSubModes() {
    return [
      FiestaSubMode(
        idSousMode: 1,
        nom: 'Challenges',
        description: 'Relevez des défis quotidiens et hebdomadaires pour gagner des récompenses spéciales !',
        icone: 'trophy',
        ordre: 1,
      ),
      FiestaSubMode(
        idSousMode: 2,
        nom: 'Aleatoire',
        description: 'Questions aléatoires de toutes catégories. Testez vos connaissances générales !',
        icone: 'shuffle',
        ordre: 2,
      ),
      FiestaSubMode(
        idSousMode: 3,
        nom: 'Defier des amis',
        description: 'Défiez vos amis en duel et prouvez que vous êtes le meilleur !',
        icone: 'people',
        ordre: 3,
      ),
    ];
  }

  void _onSubModeSelected(FiestaSubMode subMode) {
    setState(() {
      _selectedSubMode = subMode;
    });
  }

  void _showSubModeInfo(FiestaSubMode subMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(subMode.nom),
        content: Text(subMode.description ?? 'Aucune description disponible'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _onSuivantPressed() {
    if (_selectedSubMode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de jeu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    debugPrint('Sous-mode sélectionné: ${_selectedSubMode!.nom}');
    
    final subModeName = _selectedSubMode!.nom.toLowerCase();
    
    if (subModeName.contains('challenge')) {
      // Mode Challenges - naviguer vers sélection nombre de questions
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChallengeQuestionCountScreen(
            token: widget.token,
          ),
        ),
      );
    } else if (subModeName.contains('aleatoire') || subModeName.contains('aléatoire')) {
      // Mode Aléatoire - questions de toutes catégories
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
            nombreQuestions: 10,
            mode: 'random',
          ),
        ),
      );
    } else if (subModeName.contains('defier') || subModeName.contains('amis')) {
      // Mode Défier des amis - naviguer vers sélection d'ami
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FriendSelectionScreen(
            token: widget.token,
          ),
        ),
      );
    } else {
      // Autres modes - quiz aléatoire par défaut
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
            nombreQuestions: 10,
            mode: 'random',
          ),
        ),
      );
    }
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
                image: AssetImage('assets/images/backgrounds/img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                AppHeader(
                  title: 'Bienvenu(e) au mode Fiesta',
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.black),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              _buildSubtitle(),
                              const SizedBox(height: 30),
                              _buildSubModesGrid(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                ),
                _buildSuivantButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle() {
    return const Text(
      'Selectionnez le mode de jeu qui vous\ny convient',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 16,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  Widget _buildSubModesGrid() {
    if (_subModes.isEmpty) {
      return const Center(
        child: Text(
          'Aucun mode disponible',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Disposition: 2 premières cartes côte à côte, la 3ème centrée en dessous
    final List<Widget> rows = [];
    
    if (_subModes.length >= 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildSubModeCard(_subModes[0])),
            const SizedBox(width: 15),
            Expanded(child: _buildSubModeCard(_subModes[1])),
          ],
        ),
      );
    } else if (_subModes.length == 1) {
      rows.add(
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: _buildSubModeCard(_subModes[0]),
          ),
        ),
      );
    }

    // Ajouter les modes restants (à partir du 3ème) centrés
    for (int i = 2; i < _subModes.length; i++) {
      rows.add(const SizedBox(height: 15));
      rows.add(
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.45,
            child: _buildSubModeCard(_subModes[i]),
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildSubModeCard(FiestaSubMode subMode) {
    final isSelected = _selectedSubMode?.idSousMode == subMode.idSousMode;
    final subModeName = subMode.nom.toLowerCase();
    
    // Définir l'icône et les couleurs selon le sous-mode
    IconData modeIcon;
    List<Color> gradientColors;
    
    if (subModeName.contains('challenge')) {
      modeIcon = Icons.emoji_events_rounded;
      gradientColors = [const Color(0xFFFF9800), const Color(0xFFFF5722)];
    } else if (subModeName.contains('aleatoire') || subModeName.contains('aléatoire')) {
      modeIcon = Icons.casino_rounded;
      gradientColors = [const Color(0xFF00BCD4), const Color(0xFF0097A7)];
    } else if (subModeName.contains('defier') || subModeName.contains('amis')) {
      modeIcon = Icons.people_alt_rounded;
      gradientColors = [const Color(0xFFE91E63), const Color(0xFF9C27B0)];
    } else {
      modeIcon = Icons.star_rounded;
      gradientColors = [const Color(0xFF6B4EAA), const Color(0xFF9C27B0)];
    }

    return GestureDetector(
      onTap: () => _onSubModeSelected(subMode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: gradientColors[0], width: 2.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? gradientColors[0].withOpacity(0.3)
                  : Colors.black.withOpacity(0.08),
              blurRadius: isSelected ? 20 : 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône avec gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSelected ? 85 : 75,
              height: isSelected ? 85 : 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradientColors[0].withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                modeIcon,
                size: isSelected ? 40 : 35,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            // Nom du mode
            Text(
              subMode.nom,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected ? gradientColors[0] : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Indicateur de sélection
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? gradientColors[0] : Colors.grey.shade200,
                border: Border.all(
                  color: isSelected ? gradientColors[0] : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuivantButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _onSuivantPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8DFA0), // Jaune/doré comme la maquette
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Suivant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
