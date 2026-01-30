import 'package:flutter/material.dart';
import '../core/design_system.dart';

class CompanyLogo extends StatelessWidget {
  final double size;
  const CompanyLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: DesignSystem.primaryBlue, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('AC', style: TextStyle(color: Colors.white, fontSize: size / 2.5, fontWeight: FontWeight.w700))),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('Acme Corp', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        SizedBox(height: 2),
        Text('Attendance', style: TextStyle(fontSize: 12, color: DesignSystem.lightText)),
      ])
    ]);
  }
}
