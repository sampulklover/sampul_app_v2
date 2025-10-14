import 'package:flutter/material.dart';

class TrustInfoScreen extends StatelessWidget {
  const TrustInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About Trusts')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _HeroCard(),
          const SizedBox(height: 16),
          _Section(
            title: 'What is a Trust?',
            children: <Widget>[
              Text('A simple way to have a trustee manage your assets for your beneficiaries based on your instructions.', style: textTheme.bodyMedium),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Why use it',
            children: <Widget>[
              _Bullet(text: 'Clear instructions for your assets'),
              _Bullet(text: 'Trusted person to manage on your behalf'),
              _Bullet(text: 'Less confusion for family'),
            ],
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Statuses',
            children: <Widget>[
              _StatusRow(label: 'Draft', color: scheme.onSurfaceVariant, description: 'Editable'),
              _StatusRow(label: 'Submitted', color: Colors.blue.shade600, description: 'Under review'),
              _StatusRow(label: 'Approved', color: Colors.green.shade700, description: 'Active (read‑only)'),
              _StatusRow(label: 'Rejected', color: Colors.red.shade700, description: 'Fix and resubmit'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[scheme.primary, scheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.gavel_outlined, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Trusts, made simple', style: textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Set instructions for your assets and who manages them.', style: textTheme.bodyMedium?.copyWith(color: Colors.white.withOpacity(0.95))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('• '),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final Color color;
  final String description;
  const _StatusRow({required this.label, required this.color, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Expanded(child: Text(description)),
        ],
      ),
    );
  }
}


