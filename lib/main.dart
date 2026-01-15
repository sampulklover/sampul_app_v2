import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'controllers/theme_controller.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_shell.dart';
import 'services/supabase_service.dart';
import 'services/openrouter_service.dart';
import 'config/stripe_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Override debugPrint to filter out Supabase INFO messages
  final originalDebugPrint = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && 
        (message.contains('supabase.supabase_flutter: INFO') ||
         message.contains('supabase.auth: INFO') ||
         message.contains('DEBUG:'))) {
      return; // Suppress Supabase INFO messages and DEBUG messages
    }
    // Use default behavior for other messages
    originalDebugPrint(message, wrapWidth: wrapWidth);
  };
  
  await dotenv.load(fileName: ".env");
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Stripe (skip on web and when key is missing)
  if (StripeConfig.publishableKey.isNotEmpty && !kIsWeb) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    Stripe.merchantIdentifier = StripeConfig.merchantDisplayName;
    Stripe.urlScheme = StripeConfig.returnUrlScheme;
    try {
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('Stripe applySettings skipped/failed: $e');
    }
  }
  
  // Initialize OpenRouter
  await OpenRouterService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.themeModeNotifier,
      builder: (BuildContext context, ThemeMode mode, Widget? _) {
        return MaterialApp(
          title: 'Sampul',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent),
            brightness: Brightness.light,
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Colors.deepPurpleAccent,
              unselectedItemColor: Colors.grey,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent, brightness: Brightness.dark),
            brightness: Brightness.dark,
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.black87,
              selectedItemColor: Colors.deepPurpleAccent,
              unselectedItemColor: Colors.grey,
            ),
          ),
          themeMode: mode,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: AuthController.instance.authStateChanges,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is authenticated
        final session = snapshot.hasData ? snapshot.data!.session : null;
        
        if (session != null) {
          // User is authenticated, show main app
          return const MainShell();
        } else {
          // User is not authenticated, decide between onboarding and login
          return FutureBuilder<bool>(
            future: _shouldShowOnboarding(),
            builder: (BuildContext context, AsyncSnapshot<bool> snap) {
              if (!snap.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snap.data! ? const OnboardingScreen() : const LoginScreen();
            },
          );
        }
      },
    );
  }
}

Future<bool> _shouldShowOnboarding() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // Default to true first run
  return !(prefs.getBool('onboarding_completed') ?? false);
}
 
