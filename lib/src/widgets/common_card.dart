import 'package:flutter/material.dart';
import '../core/design_system.dart';

class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CommonCard({super.key, required this.child, this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignSystem.cardRadius),
        boxShadow: [BoxShadow(color: DesignSystem.alpha(Colors.black, 0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
