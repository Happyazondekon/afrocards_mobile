import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../home/presentation/screens/home_screen.dart';

/// Écran de résultat du défi entre amis
/// Affiche les deux joueurs avec leurs scores et le vainqueur
class FriendChallengeResultScreen extends StatefulWidget {
  final String? userName;
  final String? token;
  final int playerScore;
  final int opponentScore;
  final int totalQuestions;
  final String? opponentName;
  final String? opponentAvatarUrl;
  final String? playerAvatarUrl;
  final int xpGained;
  final int coinsGained;
  final bool isWinner;

  const FriendChallengeResultScreen({
    super.key,
    this.userName,
    this.token,
    required this.playerScore,
    required this.opponentScore,
    required this.totalQuestions,
    this.opponentName,
    this.opponentAvatarUrl,
    this.playerAvatarUrl,
    this.xpGained = 0,
    this.coinsGained = 0,
    required this.isWinner,
  });

  @override
  State<FriendChallengeResultScreen> createState() =>
      _FriendChallengeResultScreenState();
}

class _FriendChallengeResultScreenState
    extends State<FriendChallengeResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _scaleController.forward();

    // Mettre à jour les stats utilisateur
    _updateUserStats();
  }

  void _updateUserStats() {
    final userState = context.read<UserStateProvider>();
    userState.addXP(widget.xpGained);
    userState.addCoins(widget.coinsGained);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _close() {
    final userState = context.read<UserStateProvider>();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userPoints: userState.coins,
          userLives: userState.lives,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
        ),
      ),
      (route) => false,
    );
  }

  void _share() {
    final message = widget.isWinner
        ? 'Je viens de battre ${widget.opponentName ?? 'mon ami'} ${widget.playerScore}-${widget.opponentScore} sur AFROCARDS! 🏆'
        : 'Belle partie contre ${widget.opponentName ?? 'mon ami'} sur AFROCARDS! Score: ${widget.playerScore}-${widget.opponentScore}';
    
    Share.share(message);
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
                // Logo AFROCARDS
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
                  child: _buildContent(),
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

  Widget _buildContent() {
    final userState = context.read<UserStateProvider>();
    final winnerName = widget.isWinner
        ? (widget.userName ?? userState.userName)
        : (widget.opponentName ?? 'Adversaire');
    final winnerAvatar = widget.isWinner
        ? (widget.playerAvatarUrl ?? userState.avatarUrl)
        : widget.opponentAvatarUrl;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cercle du vainqueur avec décorations
          ScaleTransition(
            scale: _scaleAnimation,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Décorations autour du cercle
                ..._buildDecorations(),

                // Cercle principal avec avatar du vainqueur
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[300],
                    border: Border.all(
                      color: Colors.grey[400]!,
                      width: 4,
                    ),
                    image: winnerAvatar != null
                        ? DecorationImage(
                            image: NetworkImage(winnerAvatar),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: winnerAvatar == null
                      ? const Icon(Icons.person, size: 70, color: Colors.grey)
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Titre
          Text(
            widget.isWinner ? 'Felicitation!!!' : 'Dommage...',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // Message
          Text(
            widget.isWinner
                ? 'Vous avez remporté ce defi'
                : '${widget.opponentName ?? 'Votre ami'} a remporté ce défi',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Scores des joueurs
          _buildScoresSection(userState),

          const SizedBox(height: 40),

          // Boutons d'action
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildScoresSection(UserStateProvider userState) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Joueur (moi)
        _buildPlayerScore(
          avatarUrl: widget.playerAvatarUrl ?? userState.avatarUrl,
          score: widget.playerScore,
          isWinner: widget.isWinner,
        ),

        // Séparateur
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '-',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[400],
            ),
          ),
        ),

        // Adversaire
        _buildPlayerScore(
          avatarUrl: widget.opponentAvatarUrl,
          score: widget.opponentScore,
          isWinner: !widget.isWinner,
        ),
      ],
    );
  }

  Widget _buildPlayerScore({
    String? avatarUrl,
    required int score,
    required bool isWinner,
  }) {
    return Column(
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(
              color: isWinner ? const Color(0xFFE8D44D) : Colors.grey[300]!,
              width: 2,
            ),
            image: avatarUrl != null
                ? DecorationImage(
                    image: NetworkImage(avatarUrl),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: avatarUrl == null
              ? const Icon(Icons.person, color: Colors.grey, size: 25)
              : null,
        ),
        const SizedBox(height: 8),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            '$score',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Bouton Fermé
        OutlinedButton(
          onPressed: _close,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[600],
            side: BorderSide(color: Colors.grey[300]!),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: const Text(
            'Fermé',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Bouton Partager
        ElevatedButton.icon(
          onPressed: _share,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.share, size: 18),
          label: const Text(
            'Partager',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDecorations() {
    return [
      // Croix +
      Positioned(
        top: 0,
        left: 20,
        child: Text(
          '+',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
      ),
      Positioned(
        top: 40,
        right: 10,
        child: Text(
          '+',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
      ),
      // X
      Positioned(
        bottom: 30,
        left: 10,
        child: Text(
          '×',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
      ),
      Positioned(
        bottom: 10,
        right: 30,
        child: Text(
          '×',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[400],
          ),
        ),
      ),
    ];
  }
}
