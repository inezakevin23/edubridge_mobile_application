import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({this.fallbackPath = '/', super.key});

  final String fallbackPath;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Go back',
      onPressed: () async {
        final didPop = await Navigator.of(context).maybePop();
        if (!didPop && context.mounted) context.go(fallbackPath);
      },
      icon: const Icon(Icons.arrow_back_rounded),
    );
  }
}
