import 'package:flutter/material.dart';
import 'add_asset_screen.dart';
import '../controllers/auth_controller.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'assets_list_screen.dart';
import 'edit_asset_screen.dart';
import 'family_list_screen.dart';
import 'edit_family_member_screen.dart';
import 'add_family_member_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await AuthController.instance.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    }
  }

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
                          _isLoadingProfile
                              ? 'Assalamualaikum...'
                              : 'Assalamualaikum, ${_userProfile?.displayName ?? AuthController.instance.currentUser?.email?.split('@')[0] ?? 'User'}',
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
                  child: _SectionHeader(
                    title: 'My Assets',
                    actionText: 'See All →',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const AssetsListScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const _AssetsList(),
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: _SectionHeader(
                    title: 'My Family',
                    actionText: 'See All →',
                    onAction: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(builder: (_) => const FamilyListScreen()),
                      );
                    },
                  ),
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

class _AssetsList extends StatefulWidget {
  const _AssetsList();

  @override
  State<_AssetsList> createState() => _AssetsListState();
}

class _AssetsListState extends State<_AssetsList> {
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

  Color _badgeBg(String? key, BuildContext context) {
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
        return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
    }
  }

  Color _badgeFg(String? key, BuildContext context) {
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
        return Theme.of(context).colorScheme.onSurfaceVariant;
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
          .select('id,new_service_platform_name,new_service_platform_logo_url,instructions_after_death')
          .eq('uuid', user.id)
          .order('created_at', ascending: false)
          .limit(20);
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
    return SizedBox(
      height: 112,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 1 + (_assets.length),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                final bool? result = await Navigator.of(context).push(
                  MaterialPageRoute<bool>(
                    builder: (_) => const AddAssetScreen(),
                  ),
                );
                if (result == true) {
                  await _loadAssets();
                }
              },
              child: const _AddCircle(label: 'Add'),
            );
          }

          if (_isLoading) {
            return Column(
              children: const <Widget>[
                SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(height: 6),
                SizedBox(width: 76, child: Text('Loading...', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
              ],
            );
          }

          final Map<String, dynamic> asset = _assets[index - 1];
          final int id = (asset['id'] as num).toInt();
          final String name = (asset['new_service_platform_name'] as String?) ?? 'Unknown';
          final String? logoUrl = asset['new_service_platform_logo_url'] as String?;
          final String? category = asset['instructions_after_death'] as String?;
          final String categoryText = _prettyInstruction(category);
          return GestureDetector(
            onTap: () async {
              final bool? updated = await Navigator.of(context).push(
                MaterialPageRoute<bool>(builder: (_) => EditAssetScreen(assetId: id)),
              );
              if (updated == true) {
                await _loadAssets();
              }
            },
            child: Column(
              children: <Widget>[
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: (logoUrl != null && logoUrl.isNotEmpty)
                      ? ClipOval(child: _Logo(url: logoUrl, size: 56, fit: BoxFit.cover))
                      : const Icon(Icons.apps),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 76,
                  child: Column(
                    children: <Widget>[
                      Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                      if (categoryText.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: _badgeBg(category, context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            categoryText,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 9.5, color: _badgeFg(category, context), fontWeight: FontWeight.w600),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FamilyList extends StatefulWidget {
  @override
  State<_FamilyList> createState() => _FamilyListState();
}

class _FamilyListState extends State<_FamilyList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _family = <Map<String, dynamic>>[];

  String _prettyType(String? t) {
    switch ((t ?? '').toLowerCase()) {
      case 'co_sampul':
        return 'Co-sampul';
      case 'future_owner':
        return 'Beneficiary';
      case 'guardian':
        return 'Guardian';
      default:
        return '';
    }
  }

  Color _badgeBg(String? key, BuildContext context) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'co_sampul':
        return Colors.indigo.shade50;
      case 'future_owner':
        return Colors.teal.shade50;
      case 'guardian':
        return Colors.orange.shade50;
      default:
        return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5);
    }
  }

  Color _badgeFg(String? key, BuildContext context) {
    final String k = (key ?? '').toLowerCase();
    switch (k) {
      case 'co_sampul':
        return Colors.indigo.shade700;
      case 'future_owner':
        return Colors.teal.shade800;
      case 'guardian':
        return Colors.orange.shade800;
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFamily();
  }

  Future<void> _loadFamily() async {
    try {
      final user = AuthController.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final List<dynamic> rows = await SupabaseService.instance.client
          .from('beloved')
          .select('id,name,image_path,type')
          .eq('uuid', user.id)
          .order('created_at', ascending: false)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _family = rows.cast<Map<String, dynamic>>();
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
    return SizedBox(
      height: 120,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 1 + _family.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (BuildContext context, int index) {
          if (index == 0) {
            return GestureDetector(
              onTap: () async {
                final bool? created = await Navigator.of(context).push(
                  MaterialPageRoute<bool>(builder: (_) => const AddFamilyMemberScreen()),
                );
                if (created == true) {
                  await _loadFamily();
                }
              },
              child: const _AddCircle(label: 'Add'),
            );
          }
          if (_isLoading) {
            return Column(
              children: const <Widget>[
                SizedBox(width: 56, height: 56, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(height: 6),
                SizedBox(width: 72, child: Text('Loading...', textAlign: TextAlign.center, overflow: TextOverflow.ellipsis)),
              ],
            );
          }
          final Map<String, dynamic> f = _family[index - 1];
          final String name = (f['name'] as String?) ?? 'Unknown';
          final String? imagePath = f['image_path'] as String?;
          final String? type = f['type'] as String?;
          final String typeText = _prettyType(type);
          return GestureDetector(
            onTap: () async {
              final bool? updated = await Navigator.of(context).push(
                MaterialPageRoute<bool>(builder: (_) => EditFamilyMemberScreen(belovedId: (f['id'] as num).toInt())),
              );
              if (updated == true) {
                await _loadFamily();
              }
            },
            child: Column(
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEAEAEA),
                ),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: (imagePath != null && imagePath.isNotEmpty)
                    ? Image.network(
                        SupabaseService.instance.getFullImageUrl(imagePath) ?? '',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person),
                      )
                    : const Icon(Icons.person),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Column(
                  children: <Widget>[
                    Text(name, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                    if (typeText.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _badgeBg(type, context),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          typeText,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9.5, color: _badgeFg(type, context), fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ));
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

class _Logo extends StatelessWidget {
  final String url;
  final double size;
  final BoxFit fit;
  const _Logo({required this.url, required this.size, this.fit = BoxFit.contain});

  bool get _isSvg => url.toLowerCase().endsWith('.svg');

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Icon(Icons.image_outlined, size: size);
    if (_isSvg) {
      return SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: fit,
        placeholderBuilder: (_) => SizedBox(width: size, height: size, child: const CircularProgressIndicator(strokeWidth: 1.5)),
      );
    }
    return Image.network(
      url,
      width: size,
      height: size,
      fit: fit,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}


