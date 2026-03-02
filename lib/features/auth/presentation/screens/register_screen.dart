import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Contrôleurs
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  int _age = 19;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentStep = page;
    });
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Étape 1 : Valider le nom et l'âge
      if (_nameController.text.trim().isEmpty) {
        _showError("Veuillez entrer votre nom");
        return;
      }
      if (_nameController.text.trim().length < 2) {
        _showError("Le nom doit contenir au moins 2 caractères");
        return;
      }

      // Passer à l'étape 2
      _goToPage(1);
    } else {
      // Étape 2 : Valider email et mot de passe puis enregistrer
      _handleRegister();
    }
  }

  Future<void> _handleRegister() async {
    // Validation des champs
    if (_emailController.text.trim().isEmpty) {
      _showError("Veuillez entrer votre email");
      return;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showError("Email invalide");
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError("Veuillez entrer un mot de passe");
      return;
    }

    if (_passwordController.text.length < 8) {
      _showError("Le mot de passe doit contenir au moins 8 caractères");
      return;
    }

    if (!_hasUpperCase(_passwordController.text) || !_hasDigit(_passwordController.text)) {
      _showError("Le mot de passe doit contenir au moins une majuscule et un chiffre");
      return;
    }

    if (_confirmPasswordController.text.isEmpty) {
      _showError("Veuillez confirmer votre mot de passe");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Les mots de passe ne correspondent pas");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.register)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': _nameController.text.trim(),
          'age': _age,
          'email': _emailController.text.trim(),
          'motDePasse': _passwordController.text,
          'typeUtilisateur': 'joueur',
          'pseudo': _generatePseudoFromName(_nameController.text.trim()),
          'pays': 'Bénin',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        debugPrint('Inscription réussie: ${response.body}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Inscription réussie !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        try {
          final error = jsonDecode(response.body);
          _showError(error['message'] ?? 'Erreur lors de l\'inscription');
        } catch (e) {
          _showError('Erreur lors de l\'inscription (Code: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Erreur d\'inscription: $e');
      _showError('Impossible de contacter le serveur. Vérifiez votre connexion internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Helper pour générer un pseudo à partir du nom
  String _generatePseudoFromName(String name) {
    final cleanName = name.replaceAll(' ', '');
    final random = DateTime.now().millisecondsSinceEpoch % 1000;
    return '$cleanName$random';
  }

  // Validation de l'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Vérification majuscule
  bool _hasUpperCase(String text) {
    return RegExp(r'[A-Z]').hasMatch(text);
  }

  // Vérification chiffre
  bool _hasDigit(String text) {
    return RegExp(r'[0-9]').hasMatch(text);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Background img_4
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img_4.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/logos/logo_1.png',
                width: 180,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, size: 100);
                },
              ),
            ),
          ),

          // 2. Carte de formulaire
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9FF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('Inscription', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      _currentStep == 0 ? 'Veuillez entrer vos données' : 'Créez votre compte',
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 25),

                    // Zone coulissante pour les 2 étapes (SWIPE ACTIVÉ)
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        physics: _isLoading
                            ? const NeverScrollableScrollPhysics()
                            : const BouncingScrollPhysics(), // Active le swipe
                        children: [
                          _buildStep1(), // Nom + Âge
                          _buildStep2(), // Email + Password + Confirm Password
                        ],
                      ),
                    ),

                    // Indicateurs de progression CLIQUABLES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildIndicator(0, _currentStep == 0),
                        const SizedBox(width: 8),
                        _buildIndicator(1, _currentStep == 1),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Bouton "Suivant" / "S'inscrire"
                    ElevatedButton(
                      onPressed: _isLoading ? null : _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : Text(
                        _currentStep == 0 ? 'Suivant' : 'S\'inscrire',
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("ou", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 20),

                    // Bouton Google
                    OutlinedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () {
                        _showError("Connexion Google non disponible pour le moment");
                      },
                      icon: const Icon(Icons.g_mobiledata, size: 30, color: Colors.black),
                      label: const Text('Continuer avec Google', style: TextStyle(color: Colors.black)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE6E6AD),
                        minimumSize: const Size(double.infinity, 50),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),

                    const SizedBox(height: 15),
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Déjà inscrit(e)? Se connecter', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Indicateur CLIQUABLE
  Widget _buildIndicator(int index, bool isActive) {
    return GestureDetector(
      onTap: _isLoading ? null : () => _goToPage(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isActive ? 30 : 25,
        height: 5,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFD1C4E9) : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nom', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: _inputStyle('Entrez votre nom ici'),
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 20),
          const Text('Âge', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    if (_age > 13) {
                      setState(() => _age--);
                    }
                  },
                  icon: const Icon(Icons.remove),
                ),
                Text('$_age', style: const TextStyle(fontSize: 18)),
                IconButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                    if (_age < 120) {
                      setState(() => _age++);
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            decoration: _inputStyle('Entrez votre email'),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 20),

          const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: _inputStyle('Minimum 8 caractères').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ),
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 20),

          const Text('Confirmer le mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _confirmPasswordController,
            obscureText: _obscureConfirmPassword,
            decoration: _inputStyle('Confirmez votre mot de passe').copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
            ),
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 10),

          const Text(
            'Doit contenir au moins 8 caractères, une majuscule et un chiffre',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
    );
  }
}