import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/api_endpoints.dart';

/// Modèle pour un joueur dans le classement
class ClassementPlayer {
  final int rank;
  final String nom;
  final String? avatar;
  final int points;
  final String niveau;
  final bool isCurrentUser;

  ClassementPlayer({
    required this.rank,
    required this.nom,
    this.avatar,
    required this.points,
    required this.niveau,
    this.isCurrentUser = false,
  });

  factory ClassementPlayer.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) {
    return ClassementPlayer(
      rank: json['rank'] ?? json['position'] ?? 0,
      nom: json['nom'] ?? json['pseudo'] ?? 'Joueur',
      avatar: json['avatar'] ?? json['avatarUrl'],
      points: json['points'] ?? json['score'] ?? 0,
      niveau: json['niveau'] ?? 'Stage 1',
      isCurrentUser: isCurrentUser,
    );
  }
}

/// Écran de classement
class ClassementScreen extends StatefulWidget {
  final String? userName;
  final String? userLevel;
  final int? userLives;
  final int? userCoins;
  final String? avatarUrl;
  final String? token;

  const ClassementScreen({
    super.key,
    this.userName,
    this.userLevel,
    this.userLives,
    this.userCoins,
    this.avatarUrl,
    this.token,
  });

  @override
  State<ClassementScreen> createState() => _ClassementScreenState();
}

class _ClassementScreenState extends State<ClassementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClassementPlayer> _globalPlayers = [];
  List<ClassementPlayer> _weeklyPlayers = [];
  ClassementPlayer? _currentUserRank;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClassement();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClassement() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Charger le classement global
      final globalResponse = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.classementGlobal)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (globalResponse.statusCode == 200) {
        final data = jsonDecode(globalResponse.body);
        final playersList = data['data'] as List? ?? [];
        setState(() {
          _globalPlayers = playersList
              .map((p) => ClassementPlayer.fromJson(p))
              .toList();
        });
      }

      // Charger ma position
      if (widget.token != null) {
        final myRankResponse = await http.get(
          Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.myRank)),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${widget.token}',
          },
        );

        if (myRankResponse.statusCode == 200) {
          final data = jsonDecode(myRankResponse.body);
          if (data['data'] != null) {
            setState(() {
              _currentUserRank = ClassementPlayer.fromJson(
                data['data'],
                isCurrentUser: true,
              );
            });
          }
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur chargement classement: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Données de test
        _globalPlayers = _generateTestPlayers();
        _currentUserRank = ClassementPlayer(
          rank: 15,
          nom: widget.userName ?? 'Vous',
          avatar: widget.avatarUrl,
          points: widget.userCoins ?? 2300,
          niveau: widget.userLevel ?? 'Stage 15',
          isCurrentUser: true,
        );
      });
    }
  }

  List<ClassementPlayer> _generateTestPlayers() {
    return [
      ClassementPlayer(rank: 1, nom: 'Amadou', points: 15000, niveau: 'Stage 50'),
      ClassementPlayer(rank: 2, nom: 'Fatou', points: 14500, niveau: 'Stage 48'),
      ClassementPlayer(rank: 3, nom: 'Moussa', points: 14000, niveau: 'Stage 45'),
      ClassementPlayer(rank: 4, nom: 'Aïcha', points: 13500, niveau: 'Stage 44'),
      ClassementPlayer(rank: 5, nom: 'Ibrahim', points: 13000, niveau: 'Stage 42'),
      ClassementPlayer(rank: 6, nom: 'Mariama', points: 12500, niveau: 'Stage 40'),
      ClassementPlayer(rank: 7, nom: 'Oumar', points: 12000, niveau: 'Stage 38'),
      ClassementPlayer(rank: 8, nom: 'Khadija', points: 11500, niveau: 'Stage 35'),
      ClassementPlayer(rank: 9, nom: 'Sékou', points: 11000, niveau: 'Stage 33'),
      ClassementPlayer(rank: 10, nom: 'Aminata', points: 10500, niveau: 'Stage 30'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Classement',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6B4EAA),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6B4EAA),
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Cette semaine'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6B4EAA)),
            )
          : Column(
              children: [
                // Ma position
                if (_currentUserRank != null) _buildMyRankCard(),

                // Liste des joueurs
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPlayersList(_globalPlayers),
                      _buildPlayersList(_weeklyPlayers.isEmpty
                          ? _globalPlayers
                          : _weeklyPlayers),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildMyRankCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6B4EAA), Color(0xFF9B7ED9)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6B4EAA).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Rank
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '#${_currentUserRank!.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.white,
            backgroundImage: widget.avatarUrl != null
                ? NetworkImage(widget.avatarUrl!)
                : null,
            child: widget.avatarUrl == null
                ? const Icon(Icons.person, color: Color(0xFF6B4EAA))
                : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName ?? 'Vous',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  widget.userLevel ?? 'Stage 1',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_currentUserRank!.points}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Text(
                'points',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersList(List<ClassementPlayer> players) {
    if (players.isEmpty) {
      return const Center(
        child: Text('Aucun joueur dans le classement'),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadClassement,
      color: const Color(0xFF6B4EAA),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          return _buildPlayerTile(player, index + 1);
        },
      ),
    );
  }

  Widget _buildPlayerTile(ClassementPlayer player, int displayRank) {
    final isTop3 = displayRank <= 3;
    
    Color getMedalColor() {
      switch (displayRank) {
        case 1:
          return Colors.amber;
        case 2:
          return Colors.grey[400]!;
        case 3:
          return Colors.orange[700]!;
        default:
          return Colors.transparent;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: player.isCurrentUser
            ? const Color(0xFF6B4EAA).withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: player.isCurrentUser
            ? Border.all(color: const Color(0xFF6B4EAA), width: 2)
            : null,
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 40,
            child: isTop3
                ? Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: getMedalColor(),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$displayRank',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                : Text(
                    '$displayRank',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey[200],
            backgroundImage:
                player.avatar != null ? NetworkImage(player.avatar!) : null,
            child: player.avatar == null
                ? Text(
                    player.nom.isNotEmpty ? player.nom[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B4EAA),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.nom,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: player.isCurrentUser
                        ? const Color(0xFF6B4EAA)
                        : Colors.black87,
                  ),
                ),
                Text(
                  player.niveau,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Points
          Text(
            '${player.points}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isTop3 ? getMedalColor() : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
