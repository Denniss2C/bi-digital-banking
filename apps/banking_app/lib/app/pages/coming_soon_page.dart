import 'package:banking_app/l10n/l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Temporary tab content until the feature that owns it is implemented.
class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AppEmptyView(
        icon: icon,
        title: title,
        message: context.l10n.comingSoonMessage,
      ),
    );
  }
}
