import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class FilePreviewScreen extends StatefulWidget {
  final File file;

  const FilePreviewScreen({Key? key, required this.file}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _FilePreviewScreenState createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  List<Outline> _outlines = [];
  bool _isOutlineLoading = true;
  bool _isOutlineVisible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => _loadPDFOutlinesInBackground());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        // title: const Text('PDF Viewer with Outline'),
        actions: [
          IconButton(
            icon: Icon(_isOutlineVisible ? Icons.close : Icons.menu_book),
            onPressed: _toggleOutlineVisibility,
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isOutlineVisible && !_isOutlineLoading)
            Container(
              width: 250,
              color: Colors.grey.shade200,
              child: _buildCollapsibleOutlineList(),
            ),
          Expanded(
            child: Stack(
              children: [
                SfPdfViewer.file(
                  widget.file,
                  controller: _pdfViewerController,
                  pageLayoutMode: PdfPageLayoutMode.single,
                  initialZoomLevel: 1.0,
                  canShowHyperlinkDialog: true,
                  enableTextSelection: true,
                  enableHyperlinkNavigation: true,
                  canShowPasswordDialog: true,
                ),
                // Zoom controls
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        backgroundColor: Colors.white,
                        heroTag: 'zoomIn',
                        mini: true,
                        onPressed: _zoomIn,
                        child: const Icon(Icons.zoom_in,color: Colors.black,),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton(
                        backgroundColor: Colors.white,
                        heroTag: 'zoomOut',
                        mini: true,
                        onPressed: _zoomOut,
                        child: const Icon(Icons.zoom_out,color: Colors.black,),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleOutlineVisibility() {
    setState(() {
      _isOutlineVisible = !_isOutlineVisible;
    });
  }

  Future<void> _loadPDFOutlinesInBackground() async {
    try {
      final outlines = await _extractPDFOutlines(widget.file);
      setState(() {
        _outlines = outlines;
      });
    } catch (e) {
      print("Error loading outlines: $e");
    } finally {
      setState(() {
        _isOutlineLoading = false;
      });
    }
  }

  Future<List<Outline>> _extractPDFOutlines(File pdfFile) async {
    final document = PdfDocument(inputBytes: await pdfFile.readAsBytes());
    final bookmarks = document.bookmarks;
    List<Outline> outlines = [];

    void extractBookmarks(PdfBookmark bookmark, int level, List<Outline> parentList) {
      if (bookmark.title.isNotEmpty && bookmark.destination != null) {
        final pageIndex = document.pages.indexOf(bookmark.destination!.page) + 1;
        final outline = Outline(
          title: bookmark.title,
          pageNumber: pageIndex,
          level: level,
          children: [],
        );
        parentList.add(outline);

        if (bookmark.count > 0) {
          for (int i = 0; i < bookmark.count; i++) {
            extractBookmarks(bookmark[i], level + 1, outline.children);
          }
        }
      }
    }

    for (int i = 0; i < bookmarks.count; i++) {
      extractBookmarks(bookmarks[i], 0, outlines);
    }

    document.dispose();
    return outlines;
  }

  Widget _buildCollapsibleOutlineList() {
    return ListView(
      children: _outlines.map((outline) => _buildCustomExpansionTile(outline)).toList(),
    );
  }

  Widget _buildCustomExpansionTile(Outline outline) {
    bool isExpanded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            ListTile(
              title: Text(outline.title),
              subtitle: Text('Page ${outline.pageNumber}'),
              trailing: outline.children.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded; // Toggle expansion
                        });
                      },
                      child: Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                    )
                  : null,
              onTap: () {
                _pdfViewerController.jumpToPage(outline.pageNumber);
              },
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Column(
                  children: outline.children
                      .map((child) => _buildCustomExpansionTile(child))
                      .toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  void _zoomIn() {
    _pdfViewerController.zoomLevel += 0.25;
  }

  void _zoomOut() {
    _pdfViewerController.zoomLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(0.5, 4.0);
  }
}

// Outline class for nested bookmarks
class Outline {
  final String title;
  final int pageNumber;
  final int level;
  final List<Outline> children;

  Outline({
    required this.title,
    required this.pageNumber,
    required this.level,
    this.children = const [],
  });
}
