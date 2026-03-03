import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../quiz/presentation/screens/game_screen.dart';
import 'challenge_matching_screen.dart';

/// Écran affiché quand un adversaire a été trouvé pour le challenge
class ChallengeMatchedScreen extends StatelessWidget {
  final ChallengeOpponent opponent;
  final String? challengeId;
  final int questionCount;
  final String? token;

  const ChallengeMatchedScreen({
    super.key,
    required this.opponent,
    this.challengeId,
    required this.questionCount,
    this.token,
  });

  void _startChallenge(BuildContext context) {
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
          token: token,
          mode: 'challenge',
          nombreQuestions: questionCount,
          challengeId: challengeId,
          opponentName: opponent.nom,
          opponentId: opponent.id,
        ),
      ),
    );
  }

  void _findAnotherPartner(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChallengeMatchingScreen(
          questionCount: questionCount,
          token: token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/backgrounds/img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
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

              // Contenu principal centré
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
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
                              image: opponent.avatarUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(opponent.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: opponent.avatarUrl == null
                                ? const Icon(Icons.person, size: 70, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(height: 24),

                          // Nom de l'adversaire
                          Text(
                            opponent.nom,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Niveau et XP
                          Text(
                            '${opponent.niveau}-${opponent.xp}XP',
                            textAlign: TextAlign.center,
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
                            'Super! Notre algorithme vous a connecté avec ${opponent.nom}',
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
                            width: 200,
                            child: ElevatedButton(
                              onPressed: () => _startChallenge(context),
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
                            onPressed: () => _findAnotherPartner(context),
                            child: Text(
                              'Me trouver un autre partenaire',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigation handled by nav bar
        },
      ),
    );
  }
}
