import 'package:flutter/material.dart';
import '../models/trust.dart';
import 'trust_create_screen.dart';
import 'trust_dashboard_screen.dart';

class TrustInfoScreen extends StatelessWidget {
  const TrustInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Family Trust Fund'),
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
                            "Let's set up your family account",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Clear wishes, for the people you love.",
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
                          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Why set up a Family Trust Fund?",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "A Family Trust Fund lets you decide how your money is used for your family, even when you're not around.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureItem(
                              context,
                              "Choose how your money is spent (healthcare, school fees, donations)",
                              colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              context,
                              "Change your plans anytime you want",
                              colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _buildFeatureItem(
                              context,
                              "Your family knows exactly what to do — no confusion",
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
                                  const TextSpan(
                                    text: 'Sampul partner with Rakyat Trustee and Halogen Capital ',
                                  ),
                                  const TextSpan(
                                    text: 'to process your fund. ',
                                  ),
                                  WidgetSpan(
                                    child: GestureDetector(
                                      onTap: () {
                                        // TODO: Navigate to learn more page or open URL
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Learn more about our partners'),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'Learn more',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: colorScheme.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: colorScheme.primary,
                                        ),
                                      ),
                                    ),
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
                    color: Colors.black.withOpacity(0.05),
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
                    onPressed: () async {
                      final Trust? createdTrust = await Navigator.of(context).push<Trust>(
                        MaterialPageRoute<Trust>(
                          builder: (context) => const TrustCreateScreen(),
                        ),
                      );
                      if (createdTrust != null) {
                        // Replace this info screen with the dashboard so the user
                        // doesn't briefly see the trust list in between.
                        await Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (context) => TrustDashboardScreen(
                              trust: createdTrust,
                              showWelcome: true,
                            ),
                          ),
                        );
                      }
                    },
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
                          "Start setting up",
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
        'assets/3-colour-coins.png',
        fit: BoxFit.contain,
        height: 120,
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
