import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
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
      // Mode Challenges - quiz avec défis quotidiens
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
            mode: 'fiesta',
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
      // Mode Défier des amis - bientôt disponible
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode "Défier des amis" bientôt disponible !'),
          backgroundColor: Color(0xFF6B4EAA),
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
                _buildHeader(),
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
                    'Bienvenu(e) au mode Fiesta',
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

    return GestureDetector(
      onTap: () => _onSubModeSelected(subMode),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFF5F0FF)
                  : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF6B4EAA)
                    : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF6B4EAA).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                // Icône placeholder (cercle gris comme la maquette)
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  subMode.nom,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? const Color(0xFF6B4EAA)
                        : Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
          // Bouton info en bas à droite
          Positioned(
            right: 10,
            bottom: 10,
            child: GestureDetector(
              onTap: () => _showSubModeInfo(subMode),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
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
