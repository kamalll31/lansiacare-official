import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            )
          : null,
      actions: actions,
      elevation: 1,
    );
  }
}