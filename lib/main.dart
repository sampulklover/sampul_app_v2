import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'controllers/theme_controller.dart';
import 'controllers/locale_controller.dart';
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
  
  // Override debugPrint in debug mode to filter out noisy Supabase INFO logs
  if (kDebugMode) {
    final DebugPrintCallback originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null &&
          (message.contains('supabase.supabase_flutter: INFO') ||
           message.contains('supabase.auth: INFO') ||
           message.contains('DEBUG:'))) {
        return; // Suppress Supabase INFO and DEBUG messages in debug builds
      }
      // Use default behavior for other messages
      originalDebugPrint(message, wrapWidth: wrapWidth);
    };
  }
  
  await dotenv.load(fileName: ".env");
  
  // Initialize Locale Controller
  await LocaleController.instance.initialize();
  
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
  try {
    await OpenRouterService.initialize();
  } catch (e) {
    debugPrint('Warning: OpenRouter initialization failed: $e');
    debugPrint('AI chat may not work until OPENROUTER_API_KEY and OPENROUTER_MODEL are configured.');
  }
  
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
        return ValueListenableBuilder<Locale>(
          valueListenable: LocaleController.instance.localeNotifier,
          builder: (BuildContext context, Locale locale, Widget? _) {
            return MaterialApp(
              title: 'Sampul',
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: LocaleController.instance.supportedLocales,
              locale: locale,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(83, 61, 233, 1)),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color.fromRGBO(250, 250, 250, 1),
            textTheme: GoogleFonts.interTextTheme(),
            iconTheme: const IconThemeData(
              color: Color.fromRGBO(83, 61, 233, 1),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(255, 255, 255, 1),
              elevation: 1,
              iconTheme: IconThemeData(
                color: Color.fromRGBO(83, 61, 233, 1),
              ),
            ),
            cardTheme: const CardThemeData(
              color: Color.fromRGBO(255, 255, 255, 1),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color.fromRGBO(83, 61, 233, 1),
              unselectedItemColor: Colors.grey,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromRGBO(83, 61, 233, 1), brightness: Brightness.dark),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color.fromRGBO(18, 18, 18, 1),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            iconTheme: const IconThemeData(
              color: Color.fromRGBO(83, 61, 233, 1),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(30, 30, 30, 1),
              elevation: 1,
              iconTheme: IconThemeData(
                color: Color.fromRGBO(83, 61, 233, 1),
              ),
            ),
            cardTheme: const CardThemeData(
              color: Color.fromRGBO(30, 30, 30, 1),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color.fromRGBO(30, 30, 30, 1),
              selectedItemColor: Color.fromRGBO(83, 61, 233, 1),
              unselectedItemColor: Colors.grey,
            ),
          ),
              themeMode: mode,
              home: const AuthWrapper(),
            );
          },
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
 
