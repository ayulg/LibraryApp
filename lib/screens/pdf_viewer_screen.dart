import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String title;
  final String assetPath;

  const PdfViewerScreen({
    super.key,
    required this.title,
    required this.assetPath,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  String? _errorMessage;
  bool _documentLoadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _documentLoadFailed = false;
      _pdfBytes = null;
    });

    try {
      final ByteData data = await rootBundle.load(widget.assetPath);
      final bytes = data.buffer.asUint8List();
      
      if (bytes.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'PDF file is empty.';
        });
        return;
      }

      setState(() {
        _pdfBytes = bytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load PDF file.\n\nAsset path: ${widget.assetPath}\n\nError: $e';
      });
    }
  }

  void _retryLoading() {
    // Re-create the key so SfPdfViewer rebuilds from scratch
    _loadPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161626),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Digital Copy Reader',
              style: TextStyle(
                color: Color(0xFF9090B0),
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded, color: Colors.white),
            tooltip: 'Zoom In',
            onPressed: () {
              setState(() {
                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(1.0, 3.0);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded, color: Colors.white),
            tooltip: 'Zoom Out',
            onPressed: () {
              setState(() {
                _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(1.0, 3.0);
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Reload',
            onPressed: _retryLoading,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // State 1: Loading
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(color: Color(0xFF9090B0), fontSize: 14),
            ),
          ],
        ),
      );
    }

    // State 2: Asset loading error
    if (_errorMessage != null) {
      return _buildErrorWidget(_errorMessage!);
    }

    // State 3: Document failed to render (set by onDocumentLoadFailed)
    if (_documentLoadFailed) {
      return _buildErrorWidget('The PDF document could not be rendered.\nThe file may be corrupted or in an unsupported format.');
    }

    // State 4: PDF bytes loaded successfully — show viewer
    if (_pdfBytes != null) {
      return SfPdfViewer.memory(
        _pdfBytes!,
        key: _pdfViewerKey,
        controller: _pdfViewerController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoaded: (PdfDocumentLoadedDetails details) {
          // PDF loaded successfully
          debugPrint('PDF loaded: ${details.document.pages.count} pages');
        },
        onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
          debugPrint('PDF load failed: ${details.error} - ${details.description}');
          setState(() {
            _documentLoadFailed = true;
          });
        },
      );
    }

    // State 5: Fallback
    return _buildErrorWidget('No PDF data available.');
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to Load PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF9090B0), fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
