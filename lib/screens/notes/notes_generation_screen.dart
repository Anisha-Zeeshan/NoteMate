import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/notes_service.dart';
import '../../services/online_ai_services.dart';
import '../../services/offline_ai_service.dart';
import '../../services/pdf_generator_service.dart';
import '../notes/notes_list_screen.dart';

class NotesGenerationScreen extends StatefulWidget {
  final String extractedText;
  final String generateType;

  const NotesGenerationScreen({
    super.key,
    required this.extractedText,
    required this.generateType,
  });

  @override
  _NotesGenerationScreenState createState() =>
      _NotesGenerationScreenState();
}

class _NotesGenerationScreenState
    extends State<NotesGenerationScreen> {
  String generatedNotes = '';
  bool isLoading = true;
  bool isSaving = false;
  List<String> tags = [];

  //  Single instance
  final OfflineAIService _offlineAI =
  OfflineAIService();

  @override
  void initState() {
    super.initState();
    generateNotes();
  }

  Future<void> generateNotes() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    //  Single connectivity check
    final online = await OnlineAIService.isOnline();
    debugPrint('NotesGen: online=$online');

    String result;
    List<String> generatedTags;

    if (online) {
      //  Online — use Gemini
      try {
        if (widget.generateType == 'summary') {
          result =
          await OnlineAIService.generateSummary(
              widget.extractedText);
        } else {
          result = await OnlineAIService
              .generateDetailedNotes(
              widget.extractedText);
        }
        generatedTags =
        await OnlineAIService.generateTags(
            widget.extractedText);
      } catch (e) {
        debugPrint(
            'NotesGen: Gemini failed — $e, '
                'falling back to offline');
        // Gemini failed — use Qwen
        result = await _generateOffline();
        generatedTags = [
          'note',
          'offline',
          widget.generateType
        ];
      }
    } else {
      //  Offline — use Qwen directly
      debugPrint('NotesGen: Using Qwen offline');
      result = await _generateOffline();
      generatedTags = [
        'note',
        'offline',
        widget.generateType
      ];
    }

    if (!mounted) return;
    setState(() {
      generatedNotes = result;
      tags = generatedTags;
      isLoading = false;
    });
  }

  //  Qwen generation — clean separation
  Future<String> _generateOffline() async {
    if (widget.generateType == 'summary') {
      return await _offlineAI
          .generateSummary(widget.extractedText);
    } else {
      return await _offlineAI.generateDetailedNotes(
          widget.extractedText);
    }
  }

  // ── Save popup ────────────────────────────────────
  void _showSaveDialog() {
    final titleController = TextEditingController(
      text: widget.generateType == 'summary'
          ? 'Summary Note'
          : 'Detailed Notes',
    );
    final teacherController = TextEditingController();
    final tagController = TextEditingController();

    // Selected tags (starts with AI suggestions)
    List<String> selectedTags = List.from(tags);
    // All suggested tags (for chips row)
    final List<String> suggestedTags = List.from(tags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom:
                MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // ── Header ──────────────────────
                    const Text('Save Note',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    Text('PDF will be saved inside app',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500])),

                    const SizedBox(height: 20),

                    // ── Note title ───────────────────
                    _label('Note Title *'),
                    const SizedBox(height: 6),
                    TextField(
                        controller: titleController,
                        decoration: _inputDeco(
                            'Enter note title...')),

                    const SizedBox(height: 16),

                    // ── Teacher name ─────────────────
                    _label('Teacher Name (optional)'),
                    const SizedBox(height: 6),
                    TextField(
                        controller: teacherController,
                        decoration:
                        _inputDeco('E.g. Mr. Ahmed...')),

                    const SizedBox(height: 16),

                    // ── Tags section ─────────────────
                    _label('Tags'),
                    const SizedBox(height: 8),

                    //  Suggested tags row — tap to toggle
                    if (suggestedTags.isNotEmpty) ...[
                      Text('Suggested:',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500])),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children:
                        suggestedTags.map((tag) {
                          final isSelected =
                          selectedTags.contains(tag);
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                if (isSelected) {
                                  selectedTags
                                      .remove(tag);
                                } else {
                                  selectedTags.add(tag);
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets
                                  .symmetric(
                                  horizontal: 12,
                                  vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(
                                    0xFFAD1457)
                                    : const Color(
                                    0xFFAD1457)
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(
                                    20),
                                border: Border.all(
                                    color: const Color(
                                        0xFFAD1457)),
                              ),
                              child: Text(
                                '# $tag',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(
                                      0xFFAD1457),
                                  fontSize: 12,
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    //  Show currently selected custom tags
                    // (ones added manually, not in suggested)
                    Builder(builder: (_) {
                      final customTags = selectedTags
                          .where((t) =>
                      !suggestedTags.contains(t))
                          .toList();
                      if (customTags.isEmpty)
                        return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Added:',
                              style: TextStyle(
                                  fontSize: 11,
                                  color:
                                  Colors.grey[500])),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: customTags
                                .map((tag) =>
                                GestureDetector(
                                  onTap: () =>
                                      setModalState(
                                              () => selectedTags
                                              .remove(
                                              tag)),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6),
                                    decoration: BoxDecoration(
                                        color: Colors
                                            .orange
                                            .withOpacity(
                                            0.1),
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                            20),
                                        border: Border.all(
                                            color: Colors
                                                .orange)),
                                    child: Row(
                                      mainAxisSize:
                                      MainAxisSize
                                          .min,
                                      children: [
                                        Text(
                                            '# $tag',
                                            style: const TextStyle(
                                                color: Colors
                                                    .orange,
                                                fontSize:
                                                12,
                                                fontWeight:
                                                FontWeight
                                                    .w500)),
                                        const SizedBox(
                                            width: 4),
                                        const Icon(
                                            Icons.close,
                                            size: 12,
                                            color: Colors
                                                .orange),
                                      ],
                                    ),
                                  ),
                                ))
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                        ],
                      );
                    }),

                    //  Manual tag input with + button
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: _inputDeco(
                              'Write a custom tag...'),
                          onSubmitted: (val) {
                            final t = val.trim();
                            if (t.isNotEmpty &&
                                !selectedTags
                                    .contains(t)) {
                              setModalState(() {
                                selectedTags.add(t);
                                tagController.clear();
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final t =
                          tagController.text.trim();
                          if (t.isNotEmpty &&
                              !selectedTags.contains(t)) {
                            setModalState(() {
                              selectedTags.add(t);
                              tagController.clear();
                            });
                          }
                        },
                        child: Container(
                          padding:
                          const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                            const Color(0xFFAD1457),
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add,
                              color: Colors.white,
                              size: 20),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ── Save button ──────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                          if (titleController.text
                              .trim()
                              .isEmpty) {
                            ScaffoldMessenger.of(
                                ctx)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a title'),
                                backgroundColor:
                                Colors.red,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          await _saveNote(
                            title: titleController
                                .text
                                .trim(),
                            teacherName:
                            teacherController
                                .text
                                .trim(),
                            finalTags: selectedTags,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFFFC107),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  16)),
                        ),
                        child: const Text(
                            'Save & Generate PDF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold)),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveNote({
    required String title,
    required String teacherName,
    required List<String> finalTags,
  }) async {
    if (!mounted) return;
    setState(() => isSaving = true);

    final pdfPath =
    await PdfGeneratorService.generateNotePdf(
      title: title,
      content: generatedNotes,
      tags: finalTags,
      teacherName: teacherName,
      noteType: widget.generateType,
    );

    final result = await NotesService.saveNote(
      title: title,
      content: generatedNotes,
      tags: finalTags,
      type: widget.generateType,
      teacherName: teacherName,
      pdfPath: pdfPath,
    );

    if (!mounted) return;
    setState(() => isSaving = false);

    if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pdfPath.isNotEmpty
              ? 'Note saved with PDF ✓'
              : 'Note saved ✓'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => NotesListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $result'),
            backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400]),
      filled: true,
      fillColor: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
              color: const Color(0xFFAD1457))),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider().isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        icon: const Icon(
                            Icons.arrow_back)),
                    Text(
                      widget.generateType == 'summary'
                          ? 'Summary'
                          : 'Detailed Notes',
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              if (tags.isNotEmpty && !isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: tags.map((tag) {
                      return Container(
                        padding:
                        const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFAD1457)
                              .withOpacity(0.1),
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(
                                  0xFFAD1457)),
                        ),
                        child: Text('# $tag',
                            style: const TextStyle(
                                color:
                                const Color(0xFFAD1457),
                                fontSize: 12,
                                fontWeight:
                                FontWeight.w500)),
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.white,
                    borderRadius:
                    BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black
                              .withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 5)
                    ],
                  ),
                  child: isLoading
                      ? Column(children: [
                    const CircularProgressIndicator(
                        color: const Color(0xFFAD1457)),
                    const SizedBox(height: 16),
                    Text(
                      widget.generateType ==
                          'summary'
                          ? 'Generating summary...'
                          : 'Generating detailed notes...',
                      style: const TextStyle(
                          color: Colors.grey),
                    ),
                  ])
                      : Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                        children: [
                          Text(
                            widget.generateType ==
                                'summary'
                                ? 'SUMMARY'
                                : 'DETAILED NOTES',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                FontWeight.w800,
                                color:
                                Colors.black54,
                                letterSpacing:
                                1.1),
                          ),
                          IconButton(
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(
                                      text:
                                      generatedNotes));
                              ScaffoldMessenger.of(
                                  context)
                                  .showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'Copied!')),
                              );
                            },
                            icon: const Icon(
                                Icons.copy,
                                size: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      MarkdownBody(
                        data: generatedNotes,
                        styleSheet:
                        MarkdownStyleSheet(
                          h1: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Colors.black87),
                          h2: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                              color: Color(
                                  0xFFAD1457)),
                          h3: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Colors.black87),
                          p: const TextStyle(
                              fontSize: 14,
                              height: 1.6,
                              color:
                              Colors.black87),
                          listBullet:
                          const TextStyle(
                              fontSize: 14,
                              color: Color(
                                  0xFFAD1457)),
                          strong: const TextStyle(
                              fontWeight:
                              FontWeight.bold,
                              color:
                              Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              if (!isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : _showSaveDialog,
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFFFFC107),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    16)),
                          ),
                          child: isSaving
                              ? const CircularProgressIndicator(
                              color: Colors.white)
                              : const Text('Save Note',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight
                                      .bold)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: generateNotes,
                          style:
                          OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color:
                                const Color(0xFFAD1457)),
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                    16)),
                          ),
                          child: const Text('Regenerate',
                              style: TextStyle(
                                  color:
                                  const Color(0xFFAD1457),
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold)),
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
}