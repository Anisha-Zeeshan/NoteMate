import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import 'package:flutter/services.dart';
import '../../services/notes_service.dart';
import '../../services/pdf_service.dart';
import '../notes/notepad_editor_screen.dart';

class ViewNoteScreen extends StatefulWidget {
  final String noteID;
  final Map<String, dynamic> note;
  final String searchQuery;

  const ViewNoteScreen({
    super.key,
    required this.noteID,
    required this.note,
    this.searchQuery = '',
  });

  @override
  _ViewNoteScreenState createState() => _ViewNoteScreenState();
}

class _ViewNoteScreenState extends State<ViewNoteScreen> {
  late DateTime _startTime;

  // Add these state variables
  File? _pdfFile;
  bool _isGeneratingPdf = false;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    int secondsSpent = DateTime.now().difference(_startTime).inSeconds;
    if (secondsSpent > 5) {
      NotesService.trackSession(
        noteID: widget.noteID,
        timeSpentSeconds: secondsSpent,
      );
    }
    super.dispose();
  }

  // Add this method
  Future<void> _saveAsPdf() async {
    setState(() => _isGeneratingPdf = true);
    try {
      // Safely check if tags contain any descriptive metadata
      List<String> tags = List<String>.from(widget.note['tags'] ?? []);
      String determinedType = 'Detailed';
      if (tags.any((tag) => tag.toLowerCase().contains('summary'))) {
        determinedType = 'Summary';
      }

      final pdf = await PdfService.generateNotesPdf(
        title: widget.note['title'] ?? 'My Notes',
        content: widget.note['content'] ?? '',
        noteType: determinedType,
      );
      setState(() {
        _pdfFile = pdf;
        _isGeneratingPdf = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF saved successfully! ✓'),
          backgroundColor: const Color(0xFFAD1457),
        ),
      );
    } catch (e) {
      setState(() => _isGeneratingPdf = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Highlight searched word in content
  Widget _buildHighlightedContent(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 15,
          height: 1.8,
          color: ThemeProvider().isDark ? Colors.white : Colors.black87,
        ),
      );
    }

    List<TextSpan> spans = [];
    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(
            fontSize: 15,
            height: 1.8,
            color: ThemeProvider().isDark ? Colors.white : Colors.black87,
          ),
        ));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(
            fontSize: 15,
            height: 1.8,
            color: ThemeProvider().isDark ? Colors.white : Colors.black87,
          ),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          fontSize: 15,
          height: 1.8,
          color: const Color(0xFFAD1457),
          fontWeight: FontWeight.bold,
          backgroundColor: const Color(0xFFFFC107).withOpacity(0.4),
        ),
      ));
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> tags = List<String>.from(widget.note['tags'] ?? []);

    return Scaffold(
      backgroundColor: ThemeProvider().isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Row(
                      children: [
                        // Search word banner
                        if (widget.searchQuery.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFC107).withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.search,
                                  size: 12,
                                  color: const Color(0xFFAD1457),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '"${widget.searchQuery}"',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: const Color(0xFFAD1457),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => NotepadEditorScreen(
                                  existingNoteID: widget.noteID,
                                  existingNote: widget.note,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: const Color(0xFFAD1457),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(
                              ClipboardData(
                                text: widget.note['content'] ?? '',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Copied to clipboard!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Note Content Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        spreadRadius: 5,
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with highlight
                      _buildHighlightedContent(
                        widget.note['title'] ?? 'Untitled',
                        widget.searchQuery,
                      ),
                      const SizedBox(height: 8),

                      // Date
                      Text(
                        _formatDate(widget.note['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      if (tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          children: tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFCE4EC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '# $tag',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFFAD1457),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Content with highlighted search word
                      _buildHighlightedContent(
                        widget.note['content'] ?? '',
                        widget.searchQuery,
                      ),
                    ],
                  ),
                ),
              ),

              // PDF Export Action Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Save as PDF button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isGeneratingPdf ? null : _saveAsPdf,
                            icon: _isGeneratingPdf
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(
                              Icons.picture_as_pdf,
                              color: Colors.white,
                            ),
                            label: Text(
                              _isGeneratingPdf ? 'Saving...' : 'Save as PDF',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFAD1457),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Share PDF button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pdfFile == null
                                ? null
                                : () => PdfService.sharePdf(_pdfFile!),
                            icon: const Icon(
                              Icons.share,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Share PDF',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _pdfFile == null
                                  ? Colors.grey
                                  : const Color(0xFF7B5EA7),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Preview button (Shows dynamically up after PDF generation finishes)
                    if (_pdfFile != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => PdfService.previewPdf(_pdfFile!),
                            icon: const Icon(
                              Icons.visibility,
                              color: const Color(0xFFAD1457),
                            ),
                            label: const Text(
                              'Preview PDF',
                              style: TextStyle(
                                color: const Color(0xFFAD1457),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: const Color(0xFFAD1457)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}