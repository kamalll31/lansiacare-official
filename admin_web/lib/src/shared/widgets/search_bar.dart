import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onClear; // TAMBAHKAN INI

  const CustomSearchBar({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.onSearchPressed,
    this.onClear, // TAMBAHKAN INI
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  onChanged?.call('');
                  onClear?.call(); // PANGGIL onClear
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
      ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
    );
  }
}