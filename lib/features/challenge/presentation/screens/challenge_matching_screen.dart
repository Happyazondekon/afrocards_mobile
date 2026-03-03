import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Modèle pour un adversaire de challenge
class ChallengeOpponent {
  final int id;
  final String nom;
  final String niveau;
  final int xp;
  final String? avatarUrl;

  ChallengeOpponent({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.xp,
    this.avatarUrl,
  });

  factory ChallengeOpponent.fromJson(Map<String, dynamic> json) {
    return ChallengeOpponent(
      id: json['idJoueur'] ?? json['id'] ?? 0,
      nom: json['pseudo'] ?? json['nom'] ?? 'Adversaire',
      niveau: json['niveau'] ?? 'Stage 1',
      xp: json['xpTotal'] ?? json['xp'] ?? 0,
      avatarUrl: json['avatarURL'] ?? json['avatar'],
    );
  }
}

/// Écran de matching avec un adversaire pour le mode Challenge
/// Affiche l'animation de recherche puis le partenaire trouvé
class ChallengeMatchingScreen extends StatefulWidget {
  final int questionCount;
  final String? token;

  const ChallengeMatchingScreen({
    super.key,
    required this.questionCount,
    this.token,
  });

  @override
  State<ChallengeMatchingScreen> createState() =>
      _ChallengeMatchingScreenState();
}

class _ChallengeMatchingScreenState extends State<ChallengeMatchingScreen>
    with SingleTickerProviderStateMixin {
  bool _isSearching = true;
  ChallengeOpponent? _opponent;
  String? _challengeId;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _findOpponent();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _findOpponent() async {
    // Simuler une recherche de 2-3 secondes
    await Future.delayed(Duration(milliseconds: 2000 + Random().nextInt(1500)));

    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.challengeFindOpponent}'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'nombreQuestions': widget.questionCount,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            _opponent = ChallengeOpponent.fromJson(data['data']['opponent']);
            _challengeId = data['data']['challengeId']?.toString();
            _isSearching = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Erreur recherche adversaire: $e');
    }

    // Fallback: générer un adversaire fictif
    setState(() {
      _opponent = _generateRandomOpponent();
      _challengeId = 'challenge_${DateTime.now().millisecondsSinceEpoch}';
      _isSearching = false;
    });
  }

  ChallengeOpponent _generateRandomOpponent() {
    final names = ['Aminata', 'Kofi', 'Fatou', 'Mamadou', 'Aisha', 'Kwame', 'Nadia', 'Ibrahim'];
    final random = Random();
    final name = names[random.nextInt(names.length)];
    final stage = random.nextInt(10) + 1;
    final xp = random.nextInt(500) + 50;

    return ChallengeOpponent(
      id: random.nextInt(1000),
      nom: name,
      niveau: 'Stage $stage',
      xp: xp,
      avatarUrl: null,
    );
  }

  void _startChallenge() {
    final userState = context.read<UserStateProvider>();
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userLives: userState.lives,
          userCoins: userState.coins,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
          mode: 'challenge',
          nombreQuestions: widget.questionCount,
          challengeId: _challengeId,
          opponentName: _opponent?.nom,
          opponentId: _opponent?.id,
        ),
      ),
    );
  }

  void _findAnotherPartner() {
    setState(() {
      _isSearching = true;
      _opponent = null;
    });
    _findOpponent();
  }

  @override
  Widget build(BuildContext context) {
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
                // Logo en haut
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Image.asset(
                    'assets/images/logos/logo_afc.png',
                    height: 50,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text(
                        'AFROCARDS',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6B4EAA),
                        ),
                      );
                    },
                  ),
                ),

                Expanded(
                  child: _isSearching ? _buildSearchingView() : _buildMatchedView(),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigation handled by nav bar
        },
      ),
    );
  }

  Widget _buildSearchingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation de recherche
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6B4EAA).withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.person_search,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 40),
          const Text(
            'Recherche d\'un adversaire...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B4EAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchedView() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Avatar de l'adversaire
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: Colors.grey[300]!,
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
              image: _opponent?.avatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_opponent!.avatarUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: _opponent?.avatarUrl == null
                ? const Icon(Icons.person, size: 70, color: Colors.grey)
                : null,
          ),
          const SizedBox(height: 24),

          // Nom de l'adversaire
          Text(
            _opponent?.nom ?? 'Adversaire',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Niveau et XP
          Text(
            '${_opponent?.niveau ?? 'Stage 1'}-${_opponent?.xp ?? 0}XP',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),

          // Ligne de séparation
          Container(
            margin: const EdgeInsets.symmetric(vertical: 24),
            width: 60,
            height: 2,
            color: Colors.grey[300],
          ),

          // Message de match
          Text(
            'Super! Notre algorithme got you\npaired with ${_opponent?.nom ?? 'un adversaire'}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // Bouton Continuer
          SizedBox(
            width: 180,
            child: ElevatedButton(
              onPressed: _startChallenge,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8E4A8),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lien trouver un autre partenaire
          TextButton(
            onPressed: _findAnotherPartner,
            child: Text(
              'Me trouver un autre partenaire',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
