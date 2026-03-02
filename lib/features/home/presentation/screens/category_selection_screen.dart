import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/services/session_service.dart';
import 'home_screen.dart';

/// Écran de sélection des centres d'intérêt (catégories)
/// Premier écran affiché après la connexion pour personnaliser l'expérience
class CategorySelectionScreen extends StatefulWidget {
  final String userName;
  final String userLevel;
  final int userPoints;
  final int userLives;
  final String? avatarUrl;
  final String? token;

  const CategorySelectionScreen({
    super.key,
    required this.userName,
    this.userLevel = 'Stage 1',
    this.userPoints = 0,
    this.userLives = 5,
    this.avatarUrl,
    this.token,
  });

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String? _error;
  final Set<int> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Charger les catégories depuis l'API
  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.categories)),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _categories = data['data'] ?? [];
          _isLoading = false;
        });
        debugPrint('Catégories chargées: ${_categories.length}');
      } else {
        throw Exception('Erreur lors du chargement des catégories');
      }
    } catch (e) {
      debugPrint('Erreur catégories: $e');
      setState(() {
        _error = 'Impossible de charger les catégories';
        _isLoading = false;
        // Données de test en cas d'erreur réseau
        _categories = [
          {'idCategorie': 1, 'nom': 'Géographie', 'icone': '🌍'},
          {'idCategorie': 2, 'nom': 'Histoire', 'icone': '📚'},
          {'idCategorie': 3, 'nom': 'Arts', 'icone': '🎨'},
          {'idCategorie': 4, 'nom': 'Science', 'icone': '🔬'},
          {'idCategorie': 5, 'nom': 'Biologie', 'icone': '🧬'},
          {'idCategorie': 6, 'nom': 'Politique', 'icone': '⚖️'},
        ];
      });
    }
  }

  void _onCategorySelected(dynamic category) {
    final id = category['idCategorie'] ?? category['id'];
    setState(() {
      if (_selectedCategories.contains(id)) {
        _selectedCategories.remove(id);
      } else {
        _selectedCategories.add(id);
      }
    });
  }

  Future<void> _navigateToHome() async {
    // 🔐 Sauvegarder les catégories sélectionnées
    await SessionService.instance.saveSelectedCategories(_selectedCategories.toList());
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          userName: widget.userName,
          userLevel: widget.userLevel,
          userPoints: widget.userPoints,
          userLives: widget.userLives,
          avatarUrl: widget.avatarUrl,
          token: widget.token,
          selectedCategoryIds: _selectedCategories.toList(),
        ),
      ),
    );
  }

  void _showAllCategories() {
    // TODO: Naviguer vers une page avec toutes les catégories
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voir toutes les catégories')),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        _buildWelcomeSection(),
                        const SizedBox(height: 40),
                        _buildCategoriesSection(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                // Bouton Continuer en bas
                if (_selectedCategories.isNotEmpty)
                  _buildContinueButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return const Column(
      children: [
        Text(
          'Bienvenu(e) sur AFROCARDS !',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 15),
        Text(
          'Selectionnez votre centre d\'interet\npour commencer',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _showAllCategories,
              child: const Text(
                'Voir plus',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.95,
                ),
                itemCount: _categories.length > 6 ? 6 : _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return _buildCategoryCard(category);
                },
              ),
      ],
    );
  }

  Widget _buildCategoryCard(dynamic category) {
    final id = category['idCategorie'] ?? category['id'];
    final isSelected = _selectedCategories.contains(id);

    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8E8FF) : const Color(0xFFF5F5FF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.deepPurple.shade300 : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.deepPurple.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône ou image de la catégorie
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category['icone'] ?? '📚',
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              category['nom'] ?? 'Catégorie',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.deepPurple : Colors.black,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.deepPurple.shade400,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          onPressed: _navigateToHome,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 3,
          ),
          child: Text(
            'Continuer (${_selectedCategories.length} sélectionnée${_selectedCategories.length > 1 ? 's' : ''})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
