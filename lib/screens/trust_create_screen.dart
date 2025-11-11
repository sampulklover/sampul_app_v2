import 'package:flutter/material.dart';

class TrustCreateScreen extends StatefulWidget {
  const TrustCreateScreen({super.key});

  @override
  State<TrustCreateScreen> createState() => _TrustCreateScreenState();
}

class _TrustCreateScreenState extends State<TrustCreateScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Trust')),
      body: SafeArea(
        child: Stepper(
          currentStep: _currentStep,
          onStepTapped: (int i) => setState(() => _currentStep = i),
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            final bool isLast = _currentStep == _getSteps().length - 1;
            return Row(
              children: <Widget>[
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          if (!isLast) {
                            setState(() => _currentStep = _currentStep + 1);
                          } else {
                            setState(() => _isSubmitting = true);
                            await Future<void>.delayed(const Duration(milliseconds: 200));
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Trust steps scaffolded'), backgroundColor: Colors.green),
                            );
                            setState(() => _isSubmitting = false);
                          }
                        },
                  child: _isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isLast ? 'Save' : 'Next'),
                ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: _isSubmitting ? null : () => setState(() => _currentStep = _currentStep - 1),
                    child: const Text('Back'),
                  ),
              ],
            );
          },
          steps: _getSteps(),
        ),
      ),
    );
  }

  List<Step> _getSteps() {
    return <Step>[
      Step(
        title: const Text('Personal Info'),
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 0,
        content: _placeholderCard('Personal Info', 'We will add fields here later.'),
      ),
      Step(
        title: const Text('Beneficiaries'),
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 1,
        content: _placeholderCard('Beneficiaries', 'We will add beneficiary selection here.'),
      ),
      Step(
        title: const Text('Donation'),
        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
        isActive: _currentStep >= 2,
        content: _placeholderCard('Donation', 'We will add donation allocations here.'),
      ),
      Step(
        title: const Text('Review'),
        state: StepState.indexed,
        isActive: _currentStep >= 3,
        content: _placeholderCard('Review', 'A full summary will appear here.'),
      ),
    ];
  }

  Widget _placeholderCard(String title, String subtitle) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
