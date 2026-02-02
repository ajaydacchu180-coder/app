import 'package:flutter/material.dart';
import '../core/design_system.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? height;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.height = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonRadius)),
          elevation: 3,
        ),
        child: Text(label, style: DesignSystem.textTheme.labelLarge),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const SecondaryButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: DesignSystem.secondaryBlue,
          foregroundColor: DesignSystem.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonRadius)),
        ),
        child: Text(label, style: TextStyle(color: DesignSystem.primaryBlue, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const DangerButton({super.key, required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignSystem.danger,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignSystem.buttonRadius)),
        ),
        child: Text(label, style: DesignSystem.textTheme.labelLarge),
      ),
    );
  }
}
