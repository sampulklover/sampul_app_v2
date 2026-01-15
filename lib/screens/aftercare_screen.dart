import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/care_team_member.dart';
import '../services/care_team_service.dart';

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

    // Care type benefits
    final List<String> careTypes = [
      'Avoid common mistakes',
      'Listens Without Judgement',
      'Confidential',
      'Friendly Casual Support',
      'Learn From Their Experiences',
      'Follow-Ups Available',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aftercare'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadCareTeam,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Header Section
                    Text(
                      'Our Care Team',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You must have been through a lot. Let\'s start meaningful conversations and find our voice while doing so.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Connect with our certified trainers from ImROC UK for post-loss therapy and get guidance from experienced practitioners on administrative matters.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Care Type Benefits
                    ...careTypes.map((type) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    )),
                    
                    const SizedBox(height: 24),
                    
                    // Care Team Members List
                    if (_careTeam.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.support_agent_outlined,
                                size: 64,
                                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No care team members available',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._careTeam.map((member) => _CareTeamCard(
                            member: member,
                            theme: theme,
                          )),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CareTeamCard extends StatelessWidget {
  final CareTeamMember member;
  final ThemeData theme;

  const _CareTeamCard({
    required this.member,
    required this.theme,
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar
                ClipOval(
                  child: Container(
                    width: 64,
                    height: 64,
                    color: theme.colorScheme.surfaceContainerHighest,
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
                                  color: theme.colorScheme.onSurfaceVariant,
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
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ))
                        : Icon(
                            Icons.person,
                            size: 32,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                // Name and Bio
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.bio,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
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
              child: FilledButton(
                onPressed: () => _bookAppointment(context),
                child: const Text('Book Appointment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

