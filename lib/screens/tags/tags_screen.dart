import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import '../../services/notes_service.dart';
import '../notes/notes_list_screen.dart';

class TagsScreen extends StatefulWidget {
  const TagsScreen({super.key});

  @override
  _TagsScreenState createState() =>
      _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  List<String> tags = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTags();
  }

  Future<void> loadTags() async {
    List<String> fetchedTags =
    await NotesService.getAllTags();
    setState(() {
      tags = fetchedTags;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeProvider().isDark ? const Color(0xFF1A0A12) : const Color(0xFFFCE4EC),
      body: SafeArea(
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
                        Icons.arrow_back),
                  ),
                  const Text(
                    'My Tags',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            isLoading
                ? const Center(
              child: CircularProgressIndicator(
                color: const Color(0xFFAD1457),
              ),
            )
                : tags.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment
                    .center,
                children: [
                  Icon(
                    Icons.label_off_outlined,
                    size: 60,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No tags yet!\nCreate notes with AI tags.',
                    textAlign:
                    TextAlign.center,
                    style: TextStyle(
                      color:
                      Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
                : Padding(
              padding:
              const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children:
                tags.map((tag) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                              NotesListScreen(
                                initialTag:
                                tag,
                              ),
                        ),
                      );
                    },
                    child: Container(
                      padding:
                      const EdgeInsets
                          .symmetric(
                          horizontal:
                          16,
                          vertical: 10),
                      decoration:
                      BoxDecoration(
                        color: ThemeProvider().isDark ? const Color(0xFF2D0F1C) : Colors.white,
                        borderRadius:
                        BorderRadius
                            .circular(
                            20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors
                                .black
                                .withOpacity(
                                0.05),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize:
                        MainAxisSize
                            .min,
                        children: [
                          const Icon(
                            Icons.label,
                            size: 16,
                            color: Color(
                                0xFFAD1457),
                          ),
                          const SizedBox(
                              width: 6),
                          Text(
                            tag,
                            style:
                            const TextStyle(
                              fontWeight:
                              FontWeight
                                  .w500,
                              color: Color(
                                  0xFFAD1457),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}