import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:file_picker/file_picker.dart';

class FilePreviewScreen extends StatefulWidget {
  @override
  _PDFOutlineExampleState createState() => _PDFOutlineExampleState();
}

class _PDFOutlineExampleState extends State<FilePreviewScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  List<Outline> _outlines = [];
  File? _selectedFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer with Outline'),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book),
            onPressed: _outlines.isNotEmpty ? _showOutlineMenu : null,
          ),
        ],
      ),
      body: _selectedFile == null
          ? Center(
              child: ElevatedButton(
                child: const Text('Select PDF'),
                onPressed: _selectAndLoadPDF,
              ),
            )
          : SfPdfViewer.file(
              _selectedFile!,
              controller: _pdfViewerController,
              pageLayoutMode: PdfPageLayoutMode.single,
              initialZoomLevel: 0.75,
              canShowHyperlinkDialog: true,
              enableTextSelection: true,
              enableHyperlinkNavigation: true,
            ),
    );
  }

  // Method to select a PDF file
  Future<void> _selectAndLoadPDF() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      setState(() {
        _selectedFile = file;
      });

      // Load outlines from the selected PDF
      _loadPDFOutlines(file);
    }
  }

  // Extract outlines (bookmarks) from the PDF
  Future<void> _loadPDFOutlines(File pdfFile) async {
    final document = PdfDocument(inputBytes: pdfFile.readAsBytesSync());
    final bookmarks = document.bookmarks;
    List<Outline> outlines = [];

    // Extract bookmarks recursively
    void extractBookmarks(PdfBookmark bookmark, int level) {
      if (bookmark.title.isNotEmpty && bookmark.destination != null) {
        // Use indexOf to find the page number
        final pageIndex = document.pages.indexOf(bookmark.destination!.page) + 1;
        outlines.add(
          Outline(
            title: bookmark.title,
            pageNumber: pageIndex,
            level: level,
          ),
        );
      }
      if (bookmark.count > 0) {
        for (int i = 0; i < bookmark.count; i++) {
          extractBookmarks(bookmark[i], level + 1);
        }
      }
    }

    for (int i = 0; i < bookmarks.count; i++) {
      extractBookmarks(bookmarks[i], 0);
    }

    setState(() {
      _outlines = outlines;
    });

    document.dispose();
  }

  // Show the outline menu
  void _showOutlineMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: _outlines.length,
          itemBuilder: (context, index) {
            final outline = _outlines[index];
            return ListTile(
              title: Text(outline.title),
              leading: Icon(Icons.bookmark, color: Colors.blueGrey),
              subtitle: Text('Page ${outline.pageNumber}'),
              onTap: () {
                Navigator.pop(context); // Close the menu
                _pdfViewerController.jumpToPage(outline.pageNumber); // Navigate to the page
              },
            );
          },
        );
      },
    );
  }
}

// Outline model for storing bookmarks
class Outline {
  final String title;
  final int pageNumber;
  final int level;

  Outline({required this.title, required this.pageNumber, required this.level});
}
