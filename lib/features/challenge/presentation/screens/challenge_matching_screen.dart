import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import 'challenge_matched_screen.dart';

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
          final opponent = ChallengeOpponent.fromJson(data['data']['opponent']);
          final challengeId = data['data']['challengeId']?.toString();
          _navigateToMatchedScreen(opponent, challengeId);
          return;
        }
      }
    } catch (e) {
      debugPrint('Erreur recherche adversaire: $e');
    }

    // Fallback: générer un adversaire fictif
    final opponent = _generateRandomOpponent();
    final challengeId = 'challenge_${DateTime.now().millisecondsSinceEpoch}';
    _navigateToMatchedScreen(opponent, challengeId);
  }

  void _navigateToMatchedScreen(ChallengeOpponent opponent, String? challengeId) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeMatchedScreen(
          opponent: opponent,
          challengeId: challengeId,
          questionCount: widget.questionCount,
          token: widget.token,
        ),
      ),
    );
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
                  child: _buildSearchingView(),
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
}
