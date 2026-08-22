import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import '../../services/notes_service.dart';
import '../../services/online_ai_services.dart';
import '../../services/pdf_generator_service.dart';
import '../notes/notes_list_screen.dart';

class NotepadEditorScreen extends StatefulWidget {
  final String? existingNoteID;
  final Map<String, dynamic>? existingNote;

  const NotepadEditorScreen({
    super.key,
    this.existingNoteID,
    this.existingNote,
  });

  @override
  _NotepadEditorScreenState createState() =>
      _NotepadEditorScreenState();
}

class _NotepadEditorScreenState
    extends State<NotepadEditorScreen> {
  final titleController = TextEditingController();
  final QuillController _quillController =
  QuillController.basic();
  final FocusNode _focusNode = FocusNode();
  bool isSaving = false;
  bool isGeneratingTags = false;
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      titleController.text =
          widget.existingNote!['title'] ?? '';
      tags = List<String>.from(
          widget.existingNote!['tags'] ?? []);
      if (widget.existingNote!['content'] != null) {
        final doc = Document()
          ..insert(0, widget.existingNote!['content']);
        _quillController.document = doc;
      }
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    _quillController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String get _plainText {
    return _quillController.document
        .toPlainText()
        .trim();
  }

  Future<void> generateTags() async {
    if (_plainText.isEmpty) return;
    if (!mounted) return;
    setState(() => isGeneratingTags = true);

    List<String> generated =
    await OnlineAIService.generateTags(_plainText);

    // ✅ Guard after await
    if (!mounted) return;
    setState(() {
      tags = generated;
      isGeneratingTags = false;
    });
  }

  Future<void> saveNote() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _showSaveDialog();
  }

  void _showSaveDialog() {
    final teacherController = TextEditingController();
    final tagController = TextEditingController();
    List<String> dialogTags = List.from(tags);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20, right: 20, top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Save Note',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    Text('A PDF will be saved inside the app',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 20),

                    const Text('Teacher Name (optional)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: teacherController,
                      decoration: InputDecoration(
                        hintText: 'E.g. Mr. Ahmed...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        filled: true,
                        fillColor: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.grey[50],
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey[200]!)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: const Color(0xFFAD1457))),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Tags',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),

                    if (dialogTags.isNotEmpty)
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: dialogTags.map((tag) {
                          return GestureDetector(
                            onTap: () => setModalState(() => dialogTags.remove(tag)),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFAD1457).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFAD1457)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                Text('# \$tag', style: const TextStyle(
                                    color: const Color(0xFFAD1457), fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 4),
                                const Icon(Icons.close, size: 12, color: const Color(0xFFAD1457)),
                              ]),
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 10),

                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: tagController,
                          decoration: InputDecoration(
                            hintText: 'Add a tag...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true, fillColor: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey[200]!)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide(color: Colors.grey[200]!)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(color: const Color(0xFFAD1457))),
                          ),
                          onSubmitted: (val) {
                            final t = val.trim();
                            if (t.isNotEmpty && !dialogTags.contains(t)) {
                              setModalState(() { dialogTags.add(t); tagController.clear(); });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          final t = tagController.text.trim();
                          if (t.isNotEmpty && !dialogTags.contains(t)) {
                            setModalState(() { dialogTags.add(t); tagController.clear(); });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAD1457),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 20),
                        ),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity, height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _doSave(
                            teacherName: teacherController.text.trim(),
                            finalTags: dialogTags,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC107),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Save & Generate PDF',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<void> _doSave({
    required String teacherName,
    required List<String> finalTags,
  }) async {
    if (!mounted) return;
    setState(() => isSaving = true);

    // Generate PDF
    final pdfPath = await PdfGeneratorService.generateNotePdf(
      title: titleController.text.trim(),
      content: _plainText,
      tags: finalTags,
      teacherName: teacherName,
      noteType: 'manual',
    );

    String result;
    if (widget.existingNoteID != null) {
      result = await NotesService.editNote(
        noteID: widget.existingNoteID!,
        title: titleController.text.trim(),
        content: _plainText,
        tags: finalTags,
        teacherName: teacherName,
      );
    } else {
      result = await NotesService.saveNote(
        title: titleController.text.trim(),
        content: _plainText,
        tags: finalTags,
        teacherName: teacherName,
        pdfPath: pdfPath,
      );
    }

    if (!mounted) return;
    setState(() => isSaving = false);

    if (result == 'success') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(pdfPath.isNotEmpty ? 'Note saved with PDF ✓' : 'Note saved!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NotesListScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \$result'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back,
            color: ThemeProvider().isDark ? Colors.white : Colors.black87,
          ),
        ),
        title: TextField(
          controller: titleController,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ThemeProvider().isDark ? Colors.white : Colors.black87,
          ),
          decoration: const InputDecoration(
            hintText: 'Note title...',
            hintStyle: TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.normal,
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () =>
                _showTagsBottomSheet(context),
            icon: const Icon(
              Icons.label_outline,
              color: const Color(0xFFAD1457),
            ),
            tooltip: 'Tags',
          ),
          isSaving
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(0xFFAD1457),
              ),
            ),
          )
              : TextButton(
            onPressed: saveNote,
            child: const Text(
              'Save',
              style: TextStyle(
                color: const Color(0xFFAD1457),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          // Tags display
          if (tags.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              color: const Color(0xFFFCE4EC)
                  .withOpacity(0.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.label,
                    size: 14,
                    color: const Color(0xFFAD1457),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: tags.map((tag) {
                          return Container(
                            margin: const EdgeInsets
                                .only(right: 6),
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFAD1457)
                                  .withOpacity(0.1),
                              borderRadius:
                              BorderRadius.circular(20),
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
                    ),
                  ),
                ],
              ),
            ),

          // ── Offline AI Status Banner ─────────────────

          // Toolbar
          Container(
            decoration: BoxDecoration(
              color: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey[200]!,
                ),
              ),
            ),
            child: QuillSimpleToolbar(
              controller: _quillController,
              config: const QuillSimpleToolbarConfig(
                showBoldButton: true,
                showItalicButton: true,
                showUnderLineButton: true,
                showStrikeThrough: true,
                showColorButton: true,
                showBackgroundColorButton: true,
                showListNumbers: true,
                showListBullets: true,
                showQuote: true,
                showIndent: true,
                showLink: false,
                showSearchButton: false,
                showFontFamily: false,
                showFontSize: true,
                showAlignmentButtons: true,
                showHeaderStyle: true,
                showClearFormat: true,
                showCodeBlock: false,
                showInlineCode: false,
                showDividers: true,
                toolbarIconAlignment: WrapAlignment.start,
                toolbarIconCrossAlignment:
                WrapCrossAlignment.center,
              ),
            ),
          ),

          // Editor
          Expanded(
            child: Container(
              color: Colors.white,
              child: QuillEditor.basic(
                controller: _quillController,
                focusNode: _focusNode,
                config: const QuillEditorConfig(
                  placeholder:
                  'Start writing your note here...',
                  padding: EdgeInsets.all(16),
                  autoFocus: false,
                  expands: true,
                  scrollable: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTagsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            Navigator.pop(context);
                            await generateTags();
                          },
                          icon: isGeneratingTags
                              ? const SizedBox(
                            width: 14,
                            height: 14,
                            child:
                            CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Icon(
                            Icons.auto_awesome,
                            size: 14,
                          ),
                          label: const Text('Auto Generate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                            const Color(0xFFAD1457),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (tags.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: tags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(
                              Icons.close,
                              size: 14,
                            ),
                            onDeleted: () {
                              setState(() {
                                tags.remove(tag);
                              });
                              setModalState(() {});
                            },
                            backgroundColor: ThemeProvider().isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC),
                            labelStyle: const TextStyle(
                              color: const Color(0xFFAD1457),
                            ),
                          );
                        }).toList(),
                      )
                    else
                      Text(
                        'No tags yet. Tap Auto Generate!',
                        style: TextStyle(
                            color: Colors.grey[400]),
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}