import 'package:flutter/material.dart';

// Temporary screen body so navigation works before real screens exist.
// Owners: stop using this once you build your real screen.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.owner,
    this.subtitle,
  });

  final String title;
  final String owner;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            if (subtitle != null) Text(subtitle!),
            const SizedBox(height: 8),
            Text('TODO: $owner'),
          ],
        ),
      ),
    );
  }
}
