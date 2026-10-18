import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;

Future<void> openPdfPlatform(String assetPath, String fileName) async {
  try {
    final bytes = await rootBundle.load(assetPath);
    final tempDir = Platform.environment['TEMP'] ?? Platform.environment['TMP'] ?? '.';
    final file = File('$tempDir/$fileName');
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    
    if (Platform.isWindows) {
      await Process.run('explorer.exe', [file.path]);
    } else {
      // General fall-back for other platforms
      debugPrint('PDF copied to temporary path: ${file.path}');
    }
  } catch (e) {
    debugPrint('Error opening PDF on IO platform: $e');
  }
}
