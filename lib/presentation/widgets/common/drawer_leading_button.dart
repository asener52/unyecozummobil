import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/drawer_provider.dart';

class DrawerLeadingButton extends StatelessWidget {
  const DrawerLeadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu_rounded),
      onPressed: () {
        try {
          context.read<DrawerProvider>().openDrawer();
        } catch (_) {
          Scaffold.of(context).openDrawer();
        }
      },
    );
  }
}
