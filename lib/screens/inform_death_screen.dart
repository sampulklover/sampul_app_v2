import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';

import 'inform_death_form_screen.dart';

class InformDeathScreen extends StatefulWidget {
  const InformDeathScreen({super.key});

  @override
  State<InformDeathScreen> createState() => _InformDeathScreenState();
}

class _InformDeathScreenState extends State<InformDeathScreen> {
  Future<void> _handleContinue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('inform_death_about_seen', true);

    if (!mounted) return;

    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const InformDeathFormScreen(),
      ),
    );

    if (!mounted) return;
    if (created == true) {
      // Return to caller; parent decides whether to show management/status screen.
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.informDeathTitle),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l10n.informDeathHeroTitle,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.informDeathHeroBody,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Center(
                        child: Image.asset(
                          'assets/inform-death.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                          cacheWidth: 360,
                          cacheHeight: 360,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.informDeathWhatYoullShareTitle,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.informDeathWhatYoullShareBody,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _InformDeathFeatureItem(
                              text: l10n.informDeathFeatureOwner,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _InformDeathFeatureItem(
                              text: l10n.informDeathFeatureCertNumber,
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _InformDeathFeatureItem(
                              text: l10n.informDeathFeatureCertImage,
                              colorScheme: colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          l10n.informDeathStartCta,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: colorScheme.onPrimary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InformDeathFeatureItem extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _InformDeathFeatureItem({
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
