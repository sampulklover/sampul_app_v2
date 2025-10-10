import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/supabase_service.dart';
import '../controllers/auth_controller.dart';
import 'edit_asset_screen.dart';

class AssetsListScreen extends StatefulWidget {
  const AssetsListScreen({super.key});

  @override
  State<AssetsListScreen> createState() => _AssetsListScreenState();
}

class _AssetsListScreenState extends State<AssetsListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _assets = <Map<String, dynamic>>[];

  String _prettyInstruction(String? key) {
    switch ((key ?? '').toLowerCase()) {
      case 'faraid':
        return 'Faraid';
      case 'terminate':
        return 'Terminate Subscriptions';
      case 'transfer_as_gift':
        return 'Transfer as Gift';
      case 'settle':
        return 'Settle Debts';
      default:
        return '';
    }
  }

  Color _badgeBg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade50;
      case 'terminate':
        return Colors.red.shade50;
      case 'transfer_as_gift':
        return Colors.teal.shade50;
      case 'settle':
        return Colors.orange.shade50;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _badgeFg(String? key) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'faraid':
        return Colors.indigo.shade700;
      case 'terminate':
        return Colors.red.shade700;
      case 'transfer_as_gift':
        return Colors.teal.shade800;
      case 'settle':
        return Colors.orange.shade800;
      default:
        return Colors.black87;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('digital_assets')
          .select('id,new_service_platform_name,new_service_platform_logo_url,new_service_platform_url,declared_value_myr,created_at,instructions_after_death')
          .eq('uuid', user.id)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _assets = rows.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Assets')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAssets,
              child: _assets.isEmpty
                  ? ListView(children: const <Widget>[SizedBox(height: 200), Center(child: Text('No assets yet'))])
                  : ListView.separated(
                      itemCount: _assets.length + 1,
                      separatorBuilder: (BuildContext context, int index) => index == 0 ? const SizedBox.shrink() : const Divider(height: 1),
                      itemBuilder: (BuildContext context, int index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: _AssetsSummaryCard(data: _assets),
                          );
                        }
                        final Map<String, dynamic> a = _assets[index - 1];
                        final int id = (a['id'] as num).toInt();
                        final String name = (a['new_service_platform_name'] as String?) ?? 'Unknown';
                        final String? logo = a['new_service_platform_logo_url'] as String?;
                        final String? url = a['new_service_platform_url'] as String?;
                        final double? value = (a['declared_value_myr'] as num?)?.toDouble();
                        final String? category = a['instructions_after_death'] as String?;
                        final String categoryText = _prettyInstruction(category);
                        return ListTile(
                          onTap: () async {
                            final bool? updated = await Navigator.of(context).push(
                              MaterialPageRoute<bool>(builder: (_) => EditAssetScreen(assetId: id)),
                            );
                            if (updated == true) {
                              await _loadAssets();
                            }
                          },
                          leading: _Logo(url: logo, size: 40),
                          title: Text(name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (url != null && url.isNotEmpty) Text(url),
                              if (categoryText.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _badgeBg(category),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(categoryText, style: TextStyle(fontSize: 11, color: _badgeFg(category), fontWeight: FontWeight.w600)),
                                ),
                            ],
                          ),
                          trailing: value != null ? Text('RM ${value.toStringAsFixed(2)}') : null,
                        );
                      },
                    ),
            ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  final double size;
  const _Logo({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAEAEA)),
        alignment: Alignment.center,
        child: const Icon(Icons.apps),
      );
    }
    final String u = url!;
    final bool isSvg = u.toLowerCase().endsWith('.svg');
    final Widget fallback = Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEAEAEA)),
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined),
    );
    if (isSvg) {
      return ClipOval(
        child: SvgPicture.network(
          u,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        u,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}

class _AssetsSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  const _AssetsSummaryCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Map<String, double> totals = <String, double>{};
    double grandTotal = 0;
    for (final Map<String, dynamic> a in data) {
      final String raw = ((a['instructions_after_death'] as String?) ?? 'unspecified').toLowerCase();
      final String category = _prettyCategory(raw);
      final double value = (a['declared_value_myr'] as num?)?.toDouble() ?? (a['value'] as num?)?.toDouble() ?? 0.0;
      totals[category] = (totals[category] ?? 0.0) + value;
      grandTotal += value;
    }
    // Fallback to avoid divide-by-zero
    if (grandTotal <= 0) grandTotal = 1;

    final List<_Slice> slices = <_Slice>[];
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final e in entries) {
      slices.add(_Slice(
        label: e.key,
        value: e.value,
        color: _categoryColor(e.key, theme),
      ));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Distribution by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Total Assets: RM ${grandTotal == 1 ? '0.00' : grandTotal.toStringAsFixed(2)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  width: 110,
                  height: 110,
                  child: CustomPaint(
                    painter: _PieChartPainter(slices: slices, total: grandTotal),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: slices
                        .map((s) {
                          final double pct = (s.value / grandTotal * 100);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _LegendLine(
                              color: s.color,
                              label: '${s.label}: RM ${s.value.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                              maxLines: 3,
                              style: theme.textTheme.bodySmall,
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  final Color color;
  final String label;
  final int? maxLines;
  final TextStyle? style;
  const _LegendLine({required this.color, required this.label, this.maxLines, this.style});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
            maxLines: maxLines,
            style: style,
          ),
        ),
      ],
    );
  }
}

class _Slice {
  final String label;
  final double value;
  final Color color;
  _Slice({required this.label, required this.value, required this.color});
}

class _PieChartPainter extends CustomPainter {
  final List<_Slice> slices;
  final double total;
  _PieChartPainter({required this.slices, required this.total});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final double strokeWidth = size.width * 0.24;
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    double startRadian = -3.14159 / 2; // start at top
    for (final _Slice s in slices) {
      final double sweep = (s.value / total) * 6.28318; // 2*pi
      paint.color = s.color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), startRadian, sweep, false, paint);
      startRadian += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.slices != slices || oldDelegate.total != total;
  }
}

String _prettyCategory(String key) {
  switch (key) {
    case 'faraid':
      return 'Faraid';
    case 'terminate':
      return 'Terminate Subscriptions';
    case 'transfer_as_gift':
      return 'Transfer as Gift';
    case 'settle':
      return 'Settle Debts';
    case 'unspecified':
    case '':
    default:
      return 'Unspecified';
  }
}

Color _categoryColor(String prettyLabel, ThemeData theme) {
  switch (prettyLabel) {
    case 'Faraid':
      return Colors.indigo.shade700;
    case 'Terminate Subscriptions':
      return Colors.red.shade700;
    case 'Transfer as Gift':
      return Colors.teal.shade800;
    case 'Settle Debts':
      return Colors.orange.shade800;
    default:
      return theme.colorScheme.onSurfaceVariant;
  }
}
