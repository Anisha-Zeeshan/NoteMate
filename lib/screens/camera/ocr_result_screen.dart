import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import '../../services/ocr_services.dart';
import '../notes/notes_generation_screen.dart';

class OCRResultScreen extends StatefulWidget {
  final File? imageFile;        // single image (full frame OR cropped selection)
  final List<File>? imageFiles;    // multiple images
  final String? preExtractedText;  // already extracted (PDF/DOCX/offline fallback)
  final bool fromCamera;           // if true, use Gemini Vision

  const OCRResultScreen({
    super.key,
    this.imageFile,
    this.imageFiles,
    this.preExtractedText,
    this.fromCamera = false,
  });

  @override
  _OCRResultScreenState createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen> {
  String extractedText = '';
  bool isLoading = true;
  bool hasError = false;
  int _currentImageIndex = 0;

  List<File> get _allImages {
    if (widget.imageFiles != null) return widget.imageFiles!;
    if (widget.imageFile != null) return [widget.imageFile!];
    return [];
  }

  @override
  void initState() {
    super.initState();

    // PRIORITY 1: pre-extracted text (offline fallback / PDF / DOCX)
    if (widget.preExtractedText != null &&
        widget.preExtractedText!.isNotEmpty) {
      setState(() {
        extractedText = widget.preExtractedText!;
        isLoading = false;
      });
      widget.imageFile?.delete().catchError((_) {});

      // PRIORITY 2: single image (full frame OR cropped selection) — Gemini Vision
    } else if (widget.imageFile != null) {
      _extractWithGeminiVision(widget.imageFile!);

      // PRIORITY 3: multiple images — ML Kit OCR
    } else {
      _extractText();
    }
  }

  // Gemini Vision OCR — handles handwriting and cropped selections
  Future<void> _extractWithGeminiVision(File imageFile) async {
    setState(() {
      isLoading = true;
      hasError = false;
    });
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      final ext = imageFile.path.toLowerCase();
      final mimeType = ext.endsWith('.png') ? 'image/png' : 'image/jpeg';

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=AIzaSyBmiHaqRS8v1Y0vJBIcPsv6kql9aa829XI');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                  'Extract ALL text from this image exactly as written. '
                      'Preserve the original words and sentences. '
                      'Return only the extracted text, nothing else.'
                },
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 4096,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      // Delete temp image file after uploading to free memory
      imageFile.delete().catchError((_) {});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text']
            ?.toString() ??
            '';
        if (text.isNotEmpty) {
          if (mounted) {
            setState(() {
              extractedText = text.trim();
              isLoading = false;
            });
          }
          return;
        }
      }
      // Gemini failed — fallback to ML Kit
      await _extractText();
    } catch (e) {
      debugPrint('Gemini Vision error: $e');
      // Fallback to ML Kit
      await _extractText();
    }
  }

  Future<void> _extractText() async {
    final images = _allImages;
    if (images.isEmpty) {
      setState(() {
        hasError = true;
        extractedText = 'Error: No image or document provided.';
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    if (images.length == 1) {
      // Single image
      final result = await OCRService.extractText(images.first);
      if (result.startsWith('Error')) {
        setState(() {
          hasError = true;
          extractedText = result;
          isLoading = false;
        });
      } else {
        setState(() {
          extractedText = result;
          isLoading = false;
        });
      }
    } else {
      // Multiple images — extract each and combine
      final buffer = StringBuffer();
      bool anyError = false;

      for (int i = 0; i < images.length; i++) {
        if (mounted) {
          setState(() {
            _currentImageIndex = i;
          });
        }
        final result = await OCRService.extractText(images[i]);
        if (result.startsWith('Error')) {
          anyError = true;
          buffer.writeln('--- Image ${i + 1}: extraction failed ---\n');
        } else {
          buffer.writeln('--- Image ${i + 1} ---\n$result\n');
        }
      }

      setState(() {
        extractedText = buffer.toString().trim();
        hasError = anyError && extractedText.isEmpty;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = ThemeProvider().isDark;

    final images = _allImages;
    final isMulti = images.length > 1;

    return Scaffold(
      backgroundColor:
      isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──────────────────────────────────
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    Expanded(
                      child: Text(
                        isMulti
                            ? 'Extracted Text (${images.length} images)'
                            : 'Extracted Text',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Image Preview ──────────────────────────────
              if (images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isMulti
                      ? _buildMultiImagePreview(images)
                      : _buildSingleImagePreview(images.first),
                ),

              // ── Loading progress for multi ──────────────
              if (isLoading && isMulti)
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Processing image ${_currentImageIndex + 1} of ${images.length}...',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ),

              const SizedBox(height: 20),

              // ── Extracted Text Card ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2D0F1C) : Colors.white,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'EXTRACTED TEXT',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white70 : Colors.black54,
                              letterSpacing: 1.1,
                            ),
                          ),
                          if (!isLoading && !hasError)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '✓ Success',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Loading state
                      if (isLoading)
                        Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                  color: Color(0xFFAD1457)),
                              const SizedBox(height: 16),
                              Text(
                                isMulti
                                    ? 'Extracting image ${_currentImageIndex + 1} of ${images.length}...'
                                    : 'Extracting text with Gemini...',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                      // Error state
                      if (hasError && !isLoading)
                        Column(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 40),
                            const SizedBox(height: 8),
                            Text(
                              extractedText,
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _extractText,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFC107),
                              ),
                              child: const Text('Try Again',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),

                      // Success state
                      if (!isLoading && !hasError)
                        SelectableText(
                          extractedText,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black87,
                            height: 1.6,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Action Buttons ──────────────────────────
              if (!isLoading && !hasError)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesGenerationScreen(
                                extractedText: extractedText,
                                generateType: 'summary',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFC107),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.summarize, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Generate Summary',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotesGenerationScreen(
                                extractedText: extractedText,
                                generateType: 'detailed',
                              ),
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFFAD1457).withOpacity(0.8),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notes, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Generate Detailed Notes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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

  // ── Single image preview ──────────────────────────────────
  Widget _buildSingleImagePreview(File image) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(image, fit: BoxFit.cover),
      ),
    );
  }

  // ── Multi image horizontal scroll preview ──────────────────
  Widget _buildMultiImagePreview(List<File> images) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 110,
            margin: EdgeInsets.only(right: index < images.length - 1 ? 10 : 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFAD1457).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(images[index], fit: BoxFit.cover),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}