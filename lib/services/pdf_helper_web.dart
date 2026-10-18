// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<void> openPdfPlatform(String assetPath, String fileName) async {
  // In Flutter Web, assets are served under the assets folder in the build package
  final url = assetPath.startsWith('assets/') ? assetPath : 'assets/$assetPath';
  html.window.open(url, '_blank');
}
