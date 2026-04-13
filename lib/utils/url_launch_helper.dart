import 'package:url_launcher/url_launcher.dart';

/// Opens http(s) in an in-app browser (SFSafariViewController / Chrome Custom Tabs).
/// Other schemes (e.g. mailto, tel) use the platform external handler.
Future<bool> launchUriPreferInAppBrowser(Uri uri) async {
  if (!await canLaunchUrl(uri)) {
    return false;
  }
  final bool isHttp = uri.scheme == 'http' || uri.scheme == 'https';
  return launchUrl(
    uri,
    mode: isHttp ? LaunchMode.inAppBrowserView : LaunchMode.externalApplication,
  );
}
