import 'package:afrocards_mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'dart:convert';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/providers/user_state_provider.dart';
import '../../../../core/services/session_service.dart';
import '../../../home/presentation/screens/category_selection_screen.dart';
import 'forgot_password_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Fonction de connexion reliée à l'API
  Future<void> _handleLogin() async {
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
      _showError("Veuillez entrer votre mot de passe");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.buildUrl(ApiEndpoints.login)),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': _emailController.text.trim(),
          'motDePasse': _passwordController.text,
        }),
      );

      if (response.statusCode == 200) {
        // Succès : Parser la réponse
        final data = jsonDecode(response.body);

        debugPrint('Connexion réussie: ${response.body}');

        // Extraire les données utilisateur
        final token = data['data']?['token'];
        final utilisateur = data['data']?['utilisateur'];
        final profil = data['data']?['profil'];

        // 🔐 Sauvegarder la session (token + données utilisateur)
        await SessionService.instance.saveSession(
          token: token ?? '',
          utilisateur: utilisateur ?? {},
          profil: profil,
        );

        if (mounted) {
          // 🔄 Initialiser le UserStateProvider avec les données utilisateur
          final userState = context.read<UserStateProvider>();
          await userState.initialize(
            token: token ?? '',
            userName: utilisateur?['nom'] ?? profil?['pseudo'] ?? 'Joueur',
            avatarUrl: profil?['avatarURL'],
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connexion réussie !'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Naviguer vers l'écran de sélection des catégories
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CategorySelectionScreen(
                userName: utilisateur?['nom'] ?? profil?['pseudo'] ?? 'Joueur',
                userLevel: userState.userLevel,
                userPoints: userState.coins,
                userLives: userState.lives,
                avatarUrl: profil?['avatarURL'],
                token: token,
              ),
            ),
          );
        }
      } else {
        // Erreur API
        try {
          final error = jsonDecode(response.body);
          _showError(error['message'] ?? 'Erreur de connexion');
        } catch (e) {
          _showError('Erreur de connexion (Code: ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      _showError('Impossible de contacter le serveur. Vérifiez votre connexion internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Validation de l'email
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
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
          // 1. Background (img_5) - Partie haute
          Container(
            height: MediaQuery.of(context).size.height * 0.4,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/backgrounds/img_5.png'),
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

          // 2. Formulaire dans une Card blanche arrondie
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
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Connexion',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Connectez-vous pour accéder à votre espace de jeu',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 30),

                      // Email
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

                      // Password
                      const Text('Mot de passe', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: _inputStyle('Entrez votre mot de passe').copyWith(
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
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _handleLogin(),
                      ),

                      const SizedBox(height: 30),

                      // Bouton Connexion
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            : const Text(
                          'Connexion',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),

                      const SizedBox(height: 15),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),

                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text("ou"),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bouton Google
                      OutlinedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                          _showError("Connexion Google non disponible pour le moment");
                        },
                        icon: Image.asset(
                          'assets/images/icons/google.png',
                          width: 24,
                          errorBuilder: (c, e, s) => const Icon(Icons.g_mobiledata, size: 30),
                        ),
                        label: const Text(
                          'Continuer avec Google',
                          style: TextStyle(color: Colors.black),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFE6E6AD),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Lien vers l'inscription
                      Center(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Nouveau sur AFROCARDS? S\'inscrire',
                            style: TextStyle(color: Colors.black54),
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
    );
  }

  InputDecoration _inputStyle(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }
}