import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/care_team_member.dart';
import '../services/care_team_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/card_decoration_helper.dart';

class AftercareScreen extends StatefulWidget {
  const AftercareScreen({super.key});

  @override
  State<AftercareScreen> createState() => _AftercareScreenState();
}

class _AftercareScreenState extends State<AftercareScreen> {
  bool _isLoading = true;
  List<CareTeamMember> _careTeam = <CareTeamMember>[];

  @override
  void initState() {
    super.initState();
    _loadCareTeam();
  }

  Future<void> _loadCareTeam() async {
    try {
      final members = await CareTeamService.instance.listActiveMembers();
      if (mounted) {
        setState(() {
          _careTeam = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aftercare),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCareTeam,
                child: CustomScrollView(
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // Header Section
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Our Care Team',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'You must have been through a lot. Let\'s start meaningful conversations and find our voice while doing so.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Illustration
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Center(
                              child: Image.asset(
                                'assets/onboard-emotion.png',
                                width: 160,
                                height: 160,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),

                          // Info Box with benefits
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    'What we offer',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Connect with our certified trainers from ImROC UK for post-loss therapy and get guidance from experienced practitioners on administrative matters.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _AftercareFeatureItem(
                                    text: 'Avoid common mistakes with expert guidance',
                                    colorScheme: colorScheme,
                                  ),
                                  const SizedBox(height: 16),
                                  _AftercareFeatureItem(
                                    text: 'Confidential and non-judgmental support',
                                    colorScheme: colorScheme,
                                  ),
                                  const SizedBox(height: 16),
                                  _AftercareFeatureItem(
                                    text: 'Learn from their experiences',
                                    colorScheme: colorScheme,
                                  ),
                                  const SizedBox(height: 16),
                                  _AftercareFeatureItem(
                                    text: 'Follow-ups available for continued care',
                                    colorScheme: colorScheme,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Care Team Section Header
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                            child: Text(
                              'MEET OUR TEAM',
                              style: TextStyle(
                                fontSize: 12,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Care Team Members List
                    if (_careTeam.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Center(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.support_agent_outlined,
                                    size: 48,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No care team members available',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back later for available support',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final member = _careTeam[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == _careTeam.length - 1 ? 24 : 12,
                                ),
                                child: _CareTeamCard(member: member),
                              );
                            },
                            childCount: _careTeam.length,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AftercareFeatureItem extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _AftercareFeatureItem({
    required this.text,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check,
            color: colorScheme.onPrimary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
          ),
        ),
      ],
    );
  }
}

class _CareTeamCard extends StatelessWidget {
  final CareTeamMember member;

  const _CareTeamCard({
    required this.member,
  });

  Future<void> _bookAppointment(BuildContext context) async {
    try {
      final uri = Uri.parse(member.bookingUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not open booking link'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return CardDecorationHelper.styledCard(
      context: context,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Avatar
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: (member.imageUrl != null && member.imageUrl!.isNotEmpty)
                    ? (member.imageUrl!.startsWith('http')
                        ? Image.network(
                            member.imageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )
                        : Image.asset(
                            member.imageUrl!,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              size: 32,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ))
                    : Icon(
                        Icons.person,
                        size: 32,
                        color: colorScheme.onSurfaceVariant,
                      ),
              ),
              const SizedBox(width: 16),
              // Name and Bio
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      member.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      member.bio,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Book Appointment Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () => _bookAppointment(context),
              icon: const Icon(Icons.calendar_today_outlined, size: 18),
              label: const Text('Book Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

