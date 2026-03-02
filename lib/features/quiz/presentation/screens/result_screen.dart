import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../classement/presentation/screens/classement_screen.dart';

/// Écran de résultat après un quiz
class ResultScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userLives;
  final int? userCoins;
  final String? avatarUrl;
  final String? token;

  // Résultats du quiz
  final int score;
  final int totalQuestions;
  final int totalPoints;
  final int? levelNumber;
  final String mode;
  final int livesLost;

  const ResultScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userLives,
    this.userCoins,
    this.avatarUrl,
    this.token,
    required this.score,
    required this.totalQuestions,
    required this.totalPoints,
    this.levelNumber,
    this.mode = 'random',
    this.livesLost = 0,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;
  
  // Points gagnés et bonus XP
  int _xpGained = 0;
  int _coinsGained = 0;
  bool _isLevelUp = false;
  String? _newLevel;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _animationController.forward();
    _calculateRewards();
    _saveResults();
    _updateUserState();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _calculateRewards() {
    // Calcul des XP selon le score
    double percentage = widget.score / widget.totalQuestions;
    
    if (percentage >= 0.9) {
      _xpGained = 100;
      _coinsGained = 50;
    } else if (percentage >= 0.7) {
      _xpGained = 75;
      _coinsGained = 30;
    } else if (percentage >= 0.5) {
      _xpGained = 50;
      _coinsGained = 20;
    } else {
      _xpGained = 25;
      _coinsGained = 10;
    }

    // Bonus pour mode stage
    if (widget.mode == 'stage' && widget.levelNumber != null) {
      _xpGained += widget.levelNumber! * 10;
      _coinsGained += widget.levelNumber! * 5;
    }

    // Ajouter les points du quiz
    _coinsGained += widget.totalPoints ~/ 10;
  }

  void _updateUserState() {
    final userState = context.read<UserStateProvider>();
    
    // Déterminer si le stage est validé (score >= 50%)
    double percentage = widget.score / widget.totalQuestions;
    int? completedStage;
    
    if (widget.mode == 'stage' && widget.levelNumber != null && percentage >= 0.5) {
      completedStage = widget.levelNumber;
      _isLevelUp = widget.levelNumber! >= userState.maxUnlockedStage;
      if (_isLevelUp) {
        _newLevel = 'Stage ${widget.levelNumber! + 1}';
      }
    }
    
    // Mettre à jour l'état utilisateur
    userState.updateAfterQuiz(
      xpGained: _xpGained,
      coinsGained: _coinsGained,
      livesLost: widget.livesLost,
      completedStage: completedStage,
    );
  }

  Future<void> _saveResults() async {
    if (widget.token == null) return;

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl('/results/save')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.token}',
        },
        body: jsonEncode({
          'score': widget.score,
          'totalQuestions': widget.totalQuestions,
          'totalPoints': widget.totalPoints,
          'xpGained': _xpGained,
          'coinsGained': _coinsGained,
          'mode': widget.mode,
          'levelNumber': widget.levelNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['levelUp'] == true) {
          setState(() {
            _isLevelUp = true;
            _newLevel = data['newLevel'];
          });
        }
      }
    } catch (e) {
      debugPrint('Erreur sauvegarde résultats: $e');
    }
  }

  String _getResultTitle() {
    double percentage = widget.score / widget.totalQuestions;
    if (percentage >= 0.9) return 'Excellent !';
    if (percentage >= 0.7) return 'Félicitations !';
    if (percentage >= 0.5) return 'Bien joué !';
    return 'Continue !';
  }

  String _getResultMessage() {
    double percentage = widget.score / widget.totalQuestions;
    if (percentage >= 0.9) {
      return 'Incroyable ! Tu as maîtrisé ce quiz avec brio. Tu es un vrai champion de la culture africaine !';
    }
    if (percentage >= 0.7) {
      return 'Bravo ! Tu as très bien réussi ce quiz. Continue à explorer et apprendre !';
    }
    if (percentage >= 0.5) {
      return 'Pas mal ! Tu progresses bien. Entraîne-toi encore pour devenir un expert !';
    }
    return 'Ne te décourage pas ! Chaque erreur est une occasion d\'apprendre. Réessaie !';
  }

  IconData _getResultIcon() {
    double percentage = widget.score / widget.totalQuestions;
    if (percentage >= 0.9) return Icons.emoji_events;
    if (percentage >= 0.7) return Icons.star;
    if (percentage >= 0.5) return Icons.thumb_up;
    return Icons.school;
  }

  Color _getResultColor() {
    double percentage = widget.score / widget.totalQuestions;
    if (percentage >= 0.9) return Colors.amber;
    if (percentage >= 0.7) return const Color(0xFF6B4EAA);
    if (percentage >= 0.5) return Colors.blue;
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Header with user info
                _buildHeader(),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),

                        // Result circle with animation
                        _buildResultCircle(),

                        const SizedBox(height: 32),

                        // Title
                        Text(
                          _getResultTitle(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _getResultColor().withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${widget.score} / ${widget.totalQuestions}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _getResultColor(),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Message
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _getResultMessage(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Rewards section
                        _buildRewardsSection(),

                        const SizedBox(height: 32),

                        // Level up notification
                        if (_isLevelUp) _buildLevelUpNotification(),

                        const SizedBox(height: 24),

                        // Voir Classement button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _goToClassement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE8D44D),
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Voir Classement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Continuer button
                        TextButton(
                          onPressed: _continuer,
                          child: const Text(
                            'Continuer',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar and user info
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6B4EAA), width: 2),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey[200],
              backgroundImage: widget.avatarUrl != null
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'Joueur',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.userLevel ?? 'Stage 1',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Stats
          Row(
            children: [
              // Hearts
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.userLives ?? 5}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Coins
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${(widget.userCoins ?? 0) + _coinsGained}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Decorative elements
        ..._buildDecorativeElements(),

        // Main circle with animation
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotateAnimation.value * 0.1,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: _getResultColor().withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      _getResultIcon(),
                      size: 80,
                      color: _getResultColor(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  List<Widget> _buildDecorativeElements() {
    return [
      // Top dot
      Positioned(
        top: 0,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF6B4EAA),
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Bottom dot
      Positioned(
        bottom: 0,
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.pink,
            shape: BoxShape.circle,
          ),
        ),
      ),
      // Plus signs
      const Positioned(
        top: 30,
        left: 20,
        child: Text(
          '+',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black26,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      const Positioned(
        bottom: 30,
        right: 20,
        child: Text(
          '+',
          style: TextStyle(
            fontSize: 20,
            color: Colors.black26,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      // X signs
      const Positioned(
        top: 30,
        right: 30,
        child: Text(
          '×',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black26,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
      const Positioned(
        bottom: 40,
        left: 30,
        child: Text(
          '×',
          style: TextStyle(
            fontSize: 18,
            color: Colors.black26,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    ];
  }

  Widget _buildRewardsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // XP gained
          _buildRewardItem(
            icon: Icons.star,
            iconColor: Colors.purple,
            value: '+$_xpGained',
            label: 'XP',
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          // Points
          _buildRewardItem(
            icon: Icons.bolt,
            iconColor: Colors.orange,
            value: '${widget.totalPoints}',
            label: 'Points',
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.grey[300],
          ),
          // Coins gained
          _buildRewardItem(
            icon: Icons.monetization_on,
            iconColor: Colors.amber,
            value: '+$_coinsGained',
            label: 'Pièces',
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildLevelUpNotification() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EAA), Color(0xFF9B7ED9)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_upward, color: Colors.white, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Niveau supérieur !',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Tu es maintenant $_newLevel',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.celebration, color: Colors.amber, size: 32),
        ],
      ),
    );
  }

  void _goToClassement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClassementScreen(
          userName: widget.userName,
          userLevel: widget.userLevel,
          userLives: widget.userLives,
          userCoins: (widget.userCoins ?? 0) + _coinsGained,
          avatarUrl: widget.avatarUrl,
          token: widget.token,
        ),
      ),
    );
  }

  void _continuer() {
    // Retourner à l'écran précédent (mode de jeu)
    Navigator.pop(context);
    Navigator.pop(context);
  }
}
