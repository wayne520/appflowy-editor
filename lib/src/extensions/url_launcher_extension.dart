import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:appflowy_editor/src/editor/util/platform_extension.dart';

Future<bool> safeLaunchUrl(String? href) async {
  if (href == null) {
    return Future.value(false);
  }

  try {
    final uri = Uri.parse(href);
    // url_launcher cannot open a link without scheme.
    final newHref = (uri.scheme.isNotEmpty ? href : 'http://$href').trim();

    // Special handling for HarmonyOS platform
    if (PlatformExtension.isHarmonyOS) {
      // For HarmonyOS, use specific launch mode with headers
      await launchUrlString(
        newHref,
        mode: LaunchMode.externalApplication,
        webViewConfiguration: const WebViewConfiguration(
          headers: {
            'harmony_browser_page': 'true',
          },
        ),
      );
      return true;
    }

    // For other platforms, use standard approach
    if (await canLaunchUrlString(newHref)) {
      await launchUrlString(newHref);
      return true;
    }
  } catch (e) {
    // Handle any errors gracefully
    return false;
  }

  return false;
}

Future<bool> Function(String? href) editorLaunchUrl = safeLaunchUrl;
