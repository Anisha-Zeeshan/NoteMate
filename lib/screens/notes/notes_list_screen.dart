import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/notes_service.dart';
import 'view_note_screen.dart';

class NotesListScreen extends StatefulWidget {
  final String? initialTag;
  const NotesListScreen({super.key, this.initialTag});

  @override
  _NotesListScreenState createState() =>
      _NotesListScreenState();
}

class _NotesListScreenState
    extends State<NotesListScreen> {
  String selectedTag = 'All';
  List<String> tags = ['All'];

  @override
  void initState() {
    super.initState();
    loadTags();
    if (widget.initialTag != null) {
      selectedTag = widget.initialTag!;
    }
  }

  Future<void> loadTags() async {
    List<String> fetchedTags =
    await NotesService.getAllTags();
    if (!mounted) return;
    setState(() {
      tags = ['All', ...fetchedTags];
    });
  }

  // ── Long press options ────────────────────────────
  void _showNoteOptions(
      String noteID, Map<String, dynamic> note) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin:
                const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Share PDF
              ListTile(
                leading: const Icon(Icons.share,
                    color: const Color(0xFFAD1457)),
                title: const Text('Share PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  final pdfPath =
                      note['pdfPath']?.toString() ?? '';
                  if (pdfPath.isNotEmpty &&
                      await File(pdfPath).exists()) {
                    await Share.shareXFiles(
                      [XFile(pdfPath)],
                      text: note['title'] ?? 'Note',
                    );
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                            'PDF not found for this note'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
              ),

              // Delete
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: Colors.red),
                title: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await _confirmDelete(noteID);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(String noteID) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Note'),
        content: const Text(
            'Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text('Delete',
                style:
                TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ??
        false;

    if (confirm) {
      await NotesService.deleteNote(noteID: noteID);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as Timestamp).toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '${date.day}/${date.month}/${date.year}  $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider().isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Bar ───────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Text(
                    'My Notes',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // ── Tag filter row ────────────────────
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                itemCount: tags.length,
                itemBuilder: (context, index) {
                  bool isSelected =
                      tags[index] == selectedTag;
                  return GestureDetector(
                    onTap: () => setState(
                            () => selectedTag = tags[index]),
                    child: Container(
                      margin:
                      const EdgeInsets.only(right: 8),
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFAD1457)
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: Text(
                        tags[index],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.black54,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // ── Notes list ────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: selectedTag == 'All'
                    ? NotesService.getNotes()
                    : NotesService.getNotesByTag(
                    selectedTag),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: const Color(0xFFAD1457)),
                    );
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          Icon(Icons.note_alt_outlined,
                              size: 60,
                              color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text('No notes yet!',
                              style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20),
                    itemCount:
                    snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      Map<String, dynamic> note =
                      snapshot.data!.docs[index]
                          .data()
                      as Map<String, dynamic>;
                      String noteID =
                          snapshot.data!.docs[index].id;
                      List<String> noteTags =
                      List<String>.from(
                          note['tags'] ?? []);
                      final teacherName =
                          note['teacherName']
                              ?.toString() ??
                              '';

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ViewNoteScreen(
                                    noteID: noteID,
                                    note: note,
                                  ),
                            ),
                          );
                        },
                        //  Long press for options
                        onLongPress: () =>
                            _showNoteOptions(
                                noteID, note),
                        child: Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          decoration: BoxDecoration(
                            color: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.white,
                            borderRadius:
                            BorderRadius.circular(
                                16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.05),
                                blurRadius: 10,
                              )
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                const EdgeInsets.all(
                                    16),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    // ── Title + date
                                    Row(
                                      crossAxisAlignment:
                                      CrossAxisAlignment
                                          .start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            note['title'] ??
                                                'Untitled',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: ThemeProvider().isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                            width: 8),
                                        Text(
                                          _formatDate(note[
                                          'createdAt']),
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors
                                                .grey[400],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ── Teacher name
                                    if (teacherName
                                        .isNotEmpty) ...[
                                      const SizedBox(
                                          height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                              Icons.person_outline,
                                              size: 12,
                                              color: Colors
                                                  .grey[400]),
                                          const SizedBox(
                                              width: 4),
                                          Text(
                                            teacherName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors
                                                  .grey[500],
                                              fontStyle:
                                              FontStyle
                                                  .italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    const SizedBox(height: 8),

                                    // ── Tags
                                    if (noteTags
                                        .isNotEmpty)
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children:
                                        noteTags
                                            .map((tag) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal:
                                                8,
                                                vertical:
                                                3),
                                            decoration:
                                            BoxDecoration(
                                              color: const Color(
                                                  0xFFE5D1E8),
                                              borderRadius:
                                              BorderRadius
                                                  .circular(
                                                  20),
                                            ),
                                            child: Text(
                                              '# $tag',
                                              style:
                                              const TextStyle(
                                                fontSize:
                                                11,
                                                color: Color(
                                                    0xFFAD1457),
                                                fontWeight:
                                                FontWeight
                                                    .w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}