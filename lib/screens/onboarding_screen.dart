import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPageData> _pages = const <_OnboardingPageData>[
    _OnboardingPageData(
      title: 'Put your wealth in\nwriting',
      subtitle:
          'Without a Wasiat, your wealth could end up in the wrong hands. Get it sorted today—fast, legal, and dispute-free.',
      image: 'assets/intro_safe.png',
    ),
    _OnboardingPageData(
      title: 'Do more with Sampul\nTrust',
      subtitle:
          "Lock in your assets, invest for the future, and ensure your loved ones get what's rightfully theirs.",
      image: 'assets/intro_gift.png',
    ),
    _OnboardingPageData(
      title: "Don't let emotions\ndecide.",
      subtitle:
          'A professional executor ensures your will is followed—no family drama, no legal mess, just a smooth handover.',
      image: 'assets/intro_home.png',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeAndGo(Widget destination) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _completeAndGo(const SignupScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int index) => setState(() => _currentPage = index),
                itemBuilder: (BuildContext context, int index) {
                  final _OnboardingPageData data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 24),
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
                        ),
                        const Spacer(),
                        // Image placeholder; replace with real asset images in assets/
                        Expanded(
                          flex: 0,
                          child: Image.asset(
                            data.image,
                            height: 260,
                            fit: BoxFit.contain,
                            errorBuilder: (context, _, __) => Icon(Icons.image_outlined, size: 140, color: primary),
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(_pages.length, (int i) {
                final bool isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: isActive ? 18 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? primary : primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => _completeAndGo(const LoginScreen()),
                      child: Text(_currentPage == _pages.length - 1 ? 'Log In' : 'Skip'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  final String title;
  final String subtitle;
  final String image;

  const _OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.image,
  });
}


