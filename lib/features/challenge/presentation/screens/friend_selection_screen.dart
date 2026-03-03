import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../../shared/widgets/bottom_nav_bar.dart';
import '../../../quiz/presentation/screens/game_screen.dart';

/// Modèle pour un ami
class Friend {
  final int id;
  final String nom;
  final String niveau;
  final int xp;
  final String? avatarUrl;

  Friend({
    required this.id,
    required this.nom,
    required this.niveau,
    required this.xp,
    this.avatarUrl,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['idJoueur'] ?? json['id'] ?? 0,
      nom: json['pseudo'] ?? json['nom'] ?? 'Ami',
      niveau: json['niveau'] ?? 'Stage 1',
      xp: json['xpTotal'] ?? json['xp'] ?? 0,
      avatarUrl: json['avatarURL'] ?? json['avatar'],
    );
  }
}

/// Écran de sélection d'ami pour le mode "Défier un ami"
class FriendSelectionScreen extends StatefulWidget {
  final String? token;

  const FriendSelectionScreen({
    super.key,
    this.token,
  });

  @override
  State<FriendSelectionScreen> createState() => _FriendSelectionScreenState();
}

class _FriendSelectionScreenState extends State<FriendSelectionScreen> {
  List<Friend> _friends = [];
  bool _isLoading = true;
  int? _selectedFriendId;
  int _questionCount = 10;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.friendsToChallenge}'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final friendsList = data['data'] as List;
          setState(() {
            _friends = friendsList.map((f) => Friend.fromJson(f)).toList();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement amis: $e');
    }

    // Fallback: générer des amis fictifs
    setState(() {
      _friends = _generateMockFriends();
      _isLoading = false;
    });
  }

  List<Friend> _generateMockFriends() {
    return [
      Friend(id: 1, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
      Friend(id: 2, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
      Friend(id: 3, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
      Friend(id: 4, nom: 'Tunde Gabriel', niveau: 'Stage 5-Emeraude', xp: 120),
    ];
  }

  void _inviteFriend() {
    // TODO: Implémenter l'invitation d'ami
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité bientôt disponible'),
        backgroundColor: Color(0xFF6B4EAA),
      ),
    );
  }

  void _onValidate() {
    if (_selectedFriendId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un ami'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final selectedFriend = _friends.firstWhere((f) => f.id == _selectedFriendId);
    final userState = context.read<UserStateProvider>();

    // Naviguer vers le jeu avec l'ami sélectionné
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(
          userName: userState.userName,
          userLevel: userState.userLevel,
          userLives: userState.lives,
          userCoins: userState.coins,
          avatarUrl: userState.avatarUrl,
          token: widget.token,
          mode: 'friend_challenge',
          nombreQuestions: _questionCount,
          opponentName: selectedFriend.nom,
          opponentId: selectedFriend.id,
        ),
      ),
    );
  }

  void _returnToMainMenu() {
    Navigator.pop(context);
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
                AppHeader(
                  title: 'Selectionnez un ami',
                  onBackTap: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6B4EAA),
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              const SizedBox(height: 10),
                              // Sous-titre
                              const Text(
                                'ou',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Bouton Inviter un ami
                              _buildInviteButton(),

                              const SizedBox(height: 30),

                              // Liste des amis
                              ..._friends.map((friend) => _buildFriendCard(friend)),

                              const SizedBox(height: 30),

                              // Bouton Valider
                              _buildValidateButton(),

                              const SizedBox(height: 16),

                              // Lien Retour au menu principal
                              TextButton(
                                onPressed: _returnToMainMenu,
                                child: const Text(
                                  'Retour au menu principal',
                                  style: TextStyle(
                                    fontSize: 14,
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
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // Navigation handled by nav bar
        },
      ),
    );
  }

  Widget _buildInviteButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _inviteFriend,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFB74D),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Inviter un ami',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(Friend friend) {
    final isSelected = _selectedFriendId == friend.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFriendId = friend.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF5F0FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF6B4EAA) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey[200],
              backgroundImage:
                  friend.avatarUrl != null ? NetworkImage(friend.avatarUrl!) : null,
              child: friend.avatarUrl == null
                  ? const Icon(Icons.person, color: Colors.grey, size: 30)
                  : null,
            ),
            const SizedBox(width: 12),

            // Nom et niveau
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.nom,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.niveau,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // XP
            Text(
              '${friend.xp}XP',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValidateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _selectedFriendId != null ? _onValidate : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8D44D),
          foregroundColor: Colors.black87,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Valider',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
