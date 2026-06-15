import 'package:flutter/material.dart';

class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onLogout;
  const AdminAppBar({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        'Административная панель',
        style: theme.textTheme.titleLarge,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.logout, color: theme.iconTheme.color),
          tooltip: 'Выйти',
          onPressed: onLogout,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
