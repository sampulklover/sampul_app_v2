import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

class AnalyticsService {
  static bool _enabled = false;
  static bool _captureEnabled = false;
  static String? _lastLocale;

  static bool get isEnabled => _enabled;
  static bool get isCaptureEnabled => _enabled && _captureEnabled;

  static Future<void> initialize() async {
    final apiKey = dotenv.env['POSTHOG_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('Analytics: POSTHOG_API_KEY not set. Skipping analytics.');
      _enabled = false;
      return;
    }

    final host = (dotenv.env['POSTHOG_HOST']?.trim().isNotEmpty ?? false)
        ? dotenv.env['POSTHOG_HOST']!.trim()
        : 'https://us.i.posthog.com';

    try {
      final config = PostHogConfig(apiKey);
      config.host = host;
      config.debug = kDebugMode;
      config.personProfiles = PostHogPersonProfiles.identifiedOnly;

      await Posthog().setup(config);
      _enabled = true;
      _captureEnabled = true;
      debugPrint('Analytics: PostHog initialized ($host)');
    } catch (e) {
      _enabled = false;
      _captureEnabled = false;
      debugPrint('Analytics: Failed to initialize: $e');
    }
  }

  static List<NavigatorObserver> navigatorObservers() {
    if (!isCaptureEnabled) return const <NavigatorObserver>[];
    return <NavigatorObserver>[PosthogObserver()];
  }

  static Widget wrapApp(Widget child) {
    if (!_enabled) return child;
    return PostHogWidget(child: child);
  }

  static Future<void> enableCapture() async {
    if (!_enabled) return;
    try {
      await Posthog().enable();
      _captureEnabled = true;
    } catch (e) {
      debugPrint('Analytics: enable failed: $e');
    }
  }

  static Future<void> disableCapture() async {
    if (!_enabled) return;
    try {
      await Posthog().disable();
      _captureEnabled = false;
    } catch (e) {
      debugPrint('Analytics: disable failed: $e');
    }
  }

  static Future<void> identify({
    required String userId,
    Map<String, Object>? userProperties,
  }) async {
    if (!_enabled) return;
    try {
      await Posthog().identify(
        userId: userId,
        userProperties: userProperties,
      );
    } catch (e) {
      debugPrint('Analytics: identify failed: $e');
    }
  }

  static Future<void> reset() async {
    if (!_enabled) return;
    try {
      await Posthog().reset();
    } catch (e) {
      debugPrint('Analytics: reset failed: $e');
    }
  }

  /// Reset identity and stop capturing to avoid creating a new anonymous
  /// "person" after sign-out.
  static Future<void> resetAndDisableCapture() async {
    if (!_enabled) return;
    await reset();
    await disableCapture();
  }

  static Future<void> capture(
    String eventName, {
    Map<String, Object>? properties,
  }) async {
    if (!isCaptureEnabled) return;
    try {
      await Posthog().capture(
        eventName: eventName,
        properties: properties,
      );
    } catch (e) {
      debugPrint('Analytics: capture failed ($eventName): $e');
    }
  }

  /// Manual screen view (typical for bottom-nav tabs — no new [Route]).
  static Future<void> logScreen(
    String screenName, {
    Map<String, Object>? properties,
  }) async {
    if (!isCaptureEnabled) return;
    try {
      await Posthog().screen(
        screenName: screenName,
        properties: properties,
      );
    } catch (e) {
      debugPrint('Analytics: screen failed ($screenName): $e');
    }
  }

  static Future<void> captureException(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object>? properties,
  }) async {
    if (!isCaptureEnabled) return;
    try {
      await Posthog().captureException(
        error: error,
        stackTrace: stackTrace,
        properties: properties,
      );
    } catch (e) {
      debugPrint('Analytics: captureException failed: $e');
    }
  }

  static Future<void> setLocale(String locale) async {
    if (!isCaptureEnabled) return;
    if (_lastLocale == locale) return;
    _lastLocale = locale;
    try {
      await Posthog().register('locale', locale);
    } catch (e) {
      debugPrint('Analytics: setLocale failed: $e');
    }
  }
}

