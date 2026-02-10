import 'package:flutter/material.dart';

/// Standardized fixed-footer controls for multi-step flows that use [Stepper].
///
/// This widget keeps the primary action (Continue/Submit/etc.) pinned to the
/// bottom of the screen, with an optional secondary "Back" button.
///
/// It is intentionally presentation-only: the parent widget owns all state
/// (current step, validation, submit) and passes callbacks in.
class StepperFooterControls extends StatelessWidget {
  final int currentStep;
  final int lastStep;
  final bool isBusy;

  /// Called when the primary button is pressed.
  final VoidCallback onPrimaryPressed;

  /// Called when the back button is pressed. If null, the back button is hidden.
  final VoidCallback? onBackPressed;

  /// Optional override for the primary button label.
  /// When null, it defaults to "Continue" or "Submit" on the last step.
  final String? primaryLabel;

  /// Optional override for the back button label. Defaults to "Back".
  final String? backLabel;

  /// Optional additional padding around the footer contents.
  final EdgeInsetsGeometry padding;

  const StepperFooterControls({
    super.key,
    required this.currentStep,
    required this.lastStep,
    required this.isBusy,
    required this.onPrimaryPressed,
    this.onBackPressed,
    this.primaryLabel,
    this.backLabel,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    final bool isLast = currentStep >= lastStep;
    final String effectivePrimaryLabel =
        primaryLabel ?? (isLast ? 'Submit' : 'Next');
    final String effectiveBackLabel = backLabel ?? 'Back';

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    // Match primary CTA styling used by the "Start setting up" button,
    // but allow a success color on the final submit step.
    final Color primaryBgColor =
        isLast ? Colors.green.shade600 : scheme.primary;
    final Color primaryFgColor = scheme.onPrimary;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: scheme.outlineVariant.withOpacity(0.4),
              width: 1,
            ),
          ),
        ),
        padding: padding,
        child: Row(
          children: <Widget>[
            if (onBackPressed != null && currentStep > 0)
              SizedBox(
                height: 56,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    foregroundColor: scheme.onSurfaceVariant,
                  ),
                  onPressed: isBusy ? null : onBackPressed,
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    effectiveBackLabel,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            if (onBackPressed != null && currentStep > 0)
              const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBgColor,
                    foregroundColor: primaryFgColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  onPressed: isBusy ? null : onPrimaryPressed,
                  icon: isLast
                      ? const Icon(Icons.check_circle)
                      : const Icon(Icons.arrow_forward),
                  label: isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          effectivePrimaryLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryFgColor,
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

