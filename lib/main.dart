import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampul_app_v2/l10n/app_localizations.dart';
import 'controllers/theme_controller.dart';
import 'controllers/locale_controller.dart';
import 'controllers/auth_controller.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/update_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_shell.dart';
import 'services/supabase_service.dart';
import 'services/openrouter_service.dart';
import 'services/onesignal_service.dart';
import 'services/analytics_service.dart';
import 'config/analytics_screens.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AnalyticsService.captureException(
      details.exception,
      stackTrace: details.stack,
      properties: <String, Object>{
        'context': 'FlutterError.onError',
      },
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AnalyticsService.captureException(
      error,
      stackTrace: stack,
      properties: <String, Object>{
        'context': 'PlatformDispatcher.onError',
      },
    );
    return false;
  };
  
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

  // Initialize Analytics (safe to skip when not configured)
  await AnalyticsService.initialize();
  
  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize OpenRouter
  try {
    await OpenRouterService.initialize();
  } catch (e) {
    debugPrint('Warning: OpenRouter initialization failed: $e');
    debugPrint('AI chat may not work until OPENROUTER_API_KEY and OPENROUTER_MODEL are configured.');
  }
  
  // Initialize OneSignal (skip on web)
  if (!kIsWeb) {
    try {
      await OneSignalService.initialize();
    } catch (e) {
      debugPrint('Warning: OneSignal initialization failed: $e');
      debugPrint('Push notifications may not work until ONESIGNAL_APP_ID is configured.');
    }
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
            AnalyticsService.setLocale(locale.toLanguageTag());
            return AnalyticsService.wrapApp(
              MaterialApp(
                title: 'Sampul',
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: LocaleController.instance.supportedLocales,
                locale: locale,
                navigatorObservers: AnalyticsService.navigatorObservers(),
                theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(156, 136, 122, 226),
            ).copyWith(
              primary: const Color.fromRGBO(83, 61, 233, 100),
            ),
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color.fromRGBO(250, 250, 250, 1),
            textTheme: GoogleFonts.interTextTheme(),
            iconTheme: const IconThemeData(
              color: Color.fromRGBO(83, 61, 233, 100),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(255, 255, 255, 1),
              elevation: 1,
              iconTheme: IconThemeData(
                color: Color.fromRGBO(83, 61, 233, 100),
              ),
            ),
            cardTheme: const CardThemeData(
              color: Color.fromRGBO(255, 255, 255, 1),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Colors.white,
              selectedItemColor: Color.fromRGBO(83, 61, 233, 100),
              unselectedItemColor: Colors.grey,
            ),
                ),
                darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromRGBO(83, 61, 233, 100),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color.fromRGBO(83, 61, 233, 100),
            ),
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color.fromRGBO(18, 18, 18, 1),
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            iconTheme: const IconThemeData(
              color: Color.fromRGBO(83, 61, 233, 100),
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color.fromRGBO(30, 30, 30, 1),
              elevation: 1,
              iconTheme: IconThemeData(
                color: Color.fromRGBO(83, 61, 233, 100),
              ),
            ),
            cardTheme: const CardThemeData(
              color: Color.fromRGBO(30, 30, 30, 1),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              backgroundColor: Color.fromRGBO(30, 30, 30, 1),
              selectedItemColor: Color.fromRGBO(83, 61, 233, 100),
              unselectedItemColor: Colors.grey,
            ),
                ),
                themeMode: mode,
                initialRoute: '/',
                onGenerateRoute: (RouteSettings settings) {
                  return MaterialPageRoute<void>(
                    settings: const RouteSettings(
                      name: AnalyticsScreens.app,
                    ),
                    builder: (_) => const AuthWrapper(),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  StreamSubscription<AuthState>? _authSubscription;
  bool _hasSetOneSignalUserId = false;
  bool _isNavigatingToPasswordRecovery = false;
  bool _isInitialized = false;
  Session? _currentSession;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Get initial session state
    _currentSession = Supabase.instance.client.auth.currentSession;
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
    }
    
    // Listen to auth state changes
    _authSubscription = AuthController.instance.authStateChanges.listen(
      (authState) async {
        final AuthChangeEvent event = authState.event;
        final user = authState.session?.user;

        // Enable analytics before the shell builds so first screen events are not dropped.
        if (user != null && !_hasSetOneSignalUserId) {
          await AnalyticsService.enableCapture();
          await AnalyticsService.identify(userId: user.id);
          await OneSignalService.instance.setUserId(user.id);
          _hasSetOneSignalUserId = true;
        } else if (user == null && _hasSetOneSignalUserId) {
          await AnalyticsService.resetAndDisableCapture();
          await OneSignalService.instance.clearUserId();
          _hasSetOneSignalUserId = false;
        }

        // Update current session
        if (mounted) {
          setState(() {
            _currentSession = authState.session;
          });
        }

        // Handle password recovery event
        if (event == AuthChangeEvent.passwordRecovery && !_isNavigatingToPasswordRecovery) {
          _isNavigatingToPasswordRecovery = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UpdatePasswordScreen(),
                  settings: const RouteSettings(
                    name: AnalyticsScreens.updatePassword,
                  ),
                ),
              ).then((_) {
                _isNavigatingToPasswordRecovery = false;
              });
            }
          });
        }
        
        // Handle token refresh failure (expired link)
        if (event == AuthChangeEvent.tokenRefreshed && authState.session == null) {
          _showExpiredLinkMessage();
        }
      },
      onError: (error) {
        // Handle auth errors (e.g., expired recovery link)
        debugPrint('Auth error: $error');
        if (mounted) {
          setState(() {
            _currentSession = null;
          });
          _showExpiredLinkMessage();
        }
      },
    );
  }

  void _showExpiredLinkMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.resetLinkExpired ?? 'Reset link expired'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while initializing
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Check if user is authenticated
    if (_currentSession != null) {
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
  }
}

Future<bool> _shouldShowOnboarding() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  // Default to true first run
  return !(prefs.getBool('onboarding_completed') ?? false);
}
 
