import 'package:flutter/material.dart';

/// Enum pour les niveaux de difficulté
enum Difficulty { facile, moyen, difficile }

/// Extension pour obtenir le label de chaque difficulté
extension DifficultyExtension on Difficulty {
  String get label {
    switch (this) {
      case Difficulty.facile:
        return 'Facile';
      case Difficulty.moyen:
        return 'Moyen';
      case Difficulty.difficile:
        return 'Difficile';
    }
  }
}

/// Widget de sélection du niveau de difficulté
/// S'affiche comme un dialog modal avec 3 options: Facile, Moyen, Difficile
class DifficultySelectionDialog extends StatefulWidget {
  final Difficulty? initialDifficulty;
  final Function(Difficulty)? onDifficultySelected;
  final bool isChangeMode; // true = mode "changer", false = mode "sélectionner"

  const DifficultySelectionDialog({
    super.key,
    this.initialDifficulty,
    this.onDifficultySelected,
    this.isChangeMode = false,
  });

  /// Affiche le dialog et retourne la difficulté sélectionnée (mode initial)
  static Future<Difficulty?> show(
    BuildContext context, {
    Difficulty? initialDifficulty,
  }) {
    return showDialog<Difficulty>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => DifficultySelectionDialog(
        initialDifficulty: initialDifficulty,
        isChangeMode: false,
      ),
    );
  }

  /// Affiche le dialog en mode "changer" avec deux boutons
  static Future<Difficulty?> showChangeMode(
    BuildContext context, {
    Difficulty? initialDifficulty,
  }) {
    return showDialog<Difficulty>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (context) => DifficultySelectionDialog(
        initialDifficulty: initialDifficulty,
        isChangeMode: true,
      ),
    );
  }

  @override
  State<DifficultySelectionDialog> createState() =>
      _DifficultySelectionDialogState();
}

class _DifficultySelectionDialogState extends State<DifficultySelectionDialog> {
  late Difficulty _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedDifficulty = widget.initialDifficulty ?? Difficulty.facile;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Titre du dialog
            Text(
              widget.isChangeMode
                  ? 'Vous pouvez changer de niveau\nde jeu avant de continuer'
                  : 'Selectionnez votre niveau de jeu\n(vous pouvez changer apres)',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Options de difficulté
            ...Difficulty.values.map(
              (difficulty) => _buildDifficultyOption(difficulty),
            ),

            const SizedBox(height: 24),

            // Boutons
            if (widget.isChangeMode)
              _buildChangeModeButtons()
            else
              _buildOkButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOkButton() {
    return SizedBox(
      width: 120,
      child: ElevatedButton(
        onPressed: () {
          widget.onDifficultySelected?.call(_selectedDifficulty);
          Navigator.of(context).pop(_selectedDifficulty);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8E4A8), // Jaune/crème
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 0,
        ),
        child: const Text(
          'Ok',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildChangeModeButtons() {
    return Row(
      children: [
        // Bouton "Non, ça va"
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: const Text(
              'Non, ça va',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Bouton "Changer"
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              widget.onDifficultySelected?.call(_selectedDifficulty);
              Navigator.of(context).pop(_selectedDifficulty);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8E4A8), // Jaune/crème
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Changer',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(Difficulty difficulty) {
    final isSelected = _selectedDifficulty == difficulty;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedDifficulty = difficulty);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
        ),
        child: Text(
          difficulty.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? Colors.black : Colors.black54,
          ),
        ),
      ),
    );
  }
}
