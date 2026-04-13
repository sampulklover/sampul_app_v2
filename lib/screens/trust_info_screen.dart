import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import '../models/trust.dart';
import 'trust_create_screen.dart';
import 'trust_dashboard_screen.dart';

class TrustInfoScreen extends StatefulWidget {
  final bool fromHelpIcon;
  const TrustInfoScreen({super.key, this.fromHelpIcon = false});

  @override
  State<TrustInfoScreen> createState() => _TrustInfoScreenState();
}

class _TrustInfoScreenState extends State<TrustInfoScreen> {
  Future<void> _handleContinue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('trust_about_seen', true);
    
    if (!mounted) return;
    
    if (widget.fromHelpIcon) {
      Navigator.of(context).pop();
      return;
    }
    
    final Trust? createdTrust = await Navigator.of(context).push<Trust>(
      MaterialPageRoute<Trust>(
        builder: (context) => const TrustCreateScreen(),
      ),
    );
    
    if (!mounted) return;
    if (createdTrust != null) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => TrustDashboardScreen(
            trust: createdTrust,
            showWelcome: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aboutFamilyTrustFund),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.letsSetUpYourFamilyAccount,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.trustDescription,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Illustrative Graphic
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: _buildIllustration(context, colorScheme),
                    ),

                    // Benefits section - simplified language
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
                          children: [
                            Text(
                              l10n.whySetUpFamilyTrustFund,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.familyTrustFundDescription,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureItem(
                              context,
                              l10n.chooseHowMoneySpent,
                              colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              context,
                              l10n.changePlansAnytime,
                              colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              context,
                              l10n.familyKnowsExactly,
                              colorScheme,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer Section - more compact
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        children: [
                          // Partner Logos Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Rakyat Trustee logo
                              Image.asset(
                                'assets/rakyat-trustee.png',
                                width: 100,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.account_balance,
                                    color: Colors.teal.shade700,
                                    size: 24,
                                  );
                                },
                              ),
                              const SizedBox(width: 24),
                              // Halogen Capital logo
                              Image.asset(
                                'assets/halogen-capital.png',
                                width: 100,
                                height: 50,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.shield,
                                    color: Colors.blue.shade700,
                                    size: 24,
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Standardized partner information text
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                children: [
                                  TextSpan(
                                    text: l10n.sampulPartnerWithRakyat.trimRight(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Fixed button at bottom
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
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
                      children: [
                        Text(
                          l10n.startSettingUp,
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

  Widget _buildIllustration(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Image.asset(
        'assets/trust-family-card.png',
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        cacheWidth: 360,
        cacheHeight: 360,
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String text,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
