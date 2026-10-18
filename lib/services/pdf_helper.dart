import 'pdf_helper_web.dart' if (dart.library.io) 'pdf_helper_io.dart' as platform_impl;

class PdfOpener {
  static Future<void> openPdf(String assetPath, String fileName) async {
    await platform_impl.openPdfPlatform(assetPath, fileName);
  }
}
