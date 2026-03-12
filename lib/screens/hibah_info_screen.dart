import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'hibah_create_screen.dart';

class HibahInfoScreen extends StatefulWidget {
  final bool fromHelpIcon;
  const HibahInfoScreen({super.key, this.fromHelpIcon = false});

  @override
  State<HibahInfoScreen> createState() => _HibahInfoScreenState();
}

class _HibahInfoScreenState extends State<HibahInfoScreen> {
  Future<void> _handleContinue() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hibah_about_seen', true);
    
    if (!mounted) return;
    
    if (widget.fromHelpIcon) {
      Navigator.of(context).pop();
      return;
    }
    
    final bool? created = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => const HibahCreateScreen(),
      ),
    );
    
    if (!mounted) return;
    if (created == true) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About Property Trust'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    // Header Section (mirrors trust style)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Let's plan your Property Trust",
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Decide clearly who should receive your Property Trust assets.",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Optional illustration (reuse same visual language as trust)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: _buildIllustration(context, colorScheme),
                    ),

                    // Simple explanation + benefits (similar to trust)
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
                              "What is Property Trust?",
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "Property Trust is a Shariah-compliant, hibah-based way to transfer ownership of your assets to someone you choose while you are still alive.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _FeatureItem(
                              text: "Choose specific people to receive certain assets (e.g. a home, savings, or investments).",
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _FeatureItem(
                              text: "Reduce future disputes by documenting your intention clearly.",
                              colorScheme: colorScheme,
                            ),
                            const SizedBox(height: 16),
                            _FeatureItem(
                              text: "Complement your will and faraid planning with lifetime gifts.",
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

            // Fixed call-to-action button at bottom (same pattern as trust)
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
                          "Start Property Trust",
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
        'assets/hibah-property-stone.png',
        width: 180,
        height: 180,
        fit: BoxFit.contain,
        cacheWidth: 360,
        cacheHeight: 360,
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final String text;
  final ColorScheme colorScheme;

  const _FeatureItem({
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
