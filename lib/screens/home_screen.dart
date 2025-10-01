import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            automaticallyImplyLeading: false,
            pinned: true,
            expandedHeight: 110,
            title: const Text('Sampul'),
            actions: <Widget>[
              IconButton(onPressed: () {}, icon: const Icon(Icons.calendar_month_outlined)),
              IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
              const SizedBox(width: 8),
            ],
            // Keep the app bar standard (no rounded bottom) for a clean Material look
            flexibleSpace: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                const double expanded = 140;
                final double t = ((constraints.maxHeight - kToolbarHeight) / (expanded - kToolbarHeight)).clamp(0.0, 1.0);
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        theme.colorScheme.primary,
                        theme.colorScheme.primaryContainer,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8, top: 48),
                  child: Offstage(
                    offstage: t < 0.15,
                    child: Opacity(
                      opacity: t,
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          'Assalamualaikum, hafiz TEST3',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SummaryCard(),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _ActionsGrid(),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(title: 'My Assets', actionText: 'See All →', onAction: null),
                ),
                const SizedBox(height: 8),
                _AssetsList(),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(title: 'My Family', actionText: 'See All →', onAction: null),
                ),
                const SizedBox(height: 8),
                _FamilyList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'My total assets value',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RM 2,578.17',
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('details'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionsGrid extends StatelessWidget {
  final List<_ActionItem> items = const <_ActionItem>[
    _ActionItem(Icons.inventory_2_outlined, 'Wasiat'),
    _ActionItem(Icons.gavel_outlined, 'Trust'),
    _ActionItem(Icons.task_alt_outlined, 'Execution'),
    _ActionItem(Icons.group_outlined, 'Hibah'),
    _ActionItem(Icons.favorite_border, 'Khairat'),
    _ActionItem(Icons.health_and_safety_outlined, 'Health'),
    _ActionItem(Icons.account_balance_wallet_outlined, 'Assets'),
    _ActionItem(Icons.more_horiz, 'Others'),
  ];

  const _ActionsGrid();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GridView.builder(
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemBuilder: (BuildContext context, int index) {
        final _ActionItem item = items[index];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: theme.colorScheme.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(item.label, style: const TextStyle(fontSize: 12)),
          ],
        );
      },
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  const _ActionItem(this.icon, this.label);
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;
  const _SectionHeader({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      children: <Widget>[
        Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const Spacer(),
        if (actionText != null)
          TextButton(onPressed: onAction, child: Text(actionText!)),
      ],
    );
  }
}

class _AssetsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _AddCircle(label: 'Add');
          }
          final List<String> names = <String>['Amazon', 'Grammarly', 'Getty Images', 'Daily Mail'];
          final String name = names[(index - 1) % names.length];
          return Column(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.apps),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 76,
                child: Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FamilyList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return _AddCircle(label: 'Add');
          }
          final List<String> names = <String>['Aida', 'Adib', 'Akhlan', 'Kalsom', 'Anas'];
          final String name = names[(index - 1) % names.length];
          return Column(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAEAEA),
                ),
                child: const Icon(Icons.person),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AddCircle extends StatelessWidget {
  final String label;
  const _AddCircle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.purple, style: BorderStyle.solid, width: 2),
          ),
          child: const Icon(Icons.add, color: Colors.purple),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 60,
          child: Text(label, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}


