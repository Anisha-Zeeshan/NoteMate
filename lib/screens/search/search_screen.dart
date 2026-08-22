import 'package:flutter/material.dart';
import '../../services/notes_service.dart';
import '../../services/theme_provider.dart';
import '../notes/view_note_screen.dart';
import '../home/home_screen.dart';

class SearchScreen extends StatefulWidget {
  final bool isTab;
  const SearchScreen({super.key, this.isTab = false});

  @override
  _SearchScreenState createState() =>
      _SearchScreenState();
}

class _SearchScreenState
    extends State<SearchScreen> {
  final searchController = TextEditingController();
  List<Map<String, dynamic>> results = [];
  bool isSearching = false;
  bool hasSearched = false;
  String currentQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        results = [];
        hasSearched = false;
        currentQuery = '';
      });
      return;
    }
    setState(() {
      isSearching = true;
      hasSearched = true;
      currentQuery = query.trim();
    });
    final searchResults =
    await NotesService.searchNotes(query: query);
    if (!mounted) return;
    setState(() {
      results = searchResults;
      isSearching = false;
    });
  }

  void _goBack() {
    if (widget.isTab) return;
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  // ✅ Find the SPECIFIC paragraph containing the query
  String _findMatchingParagraph(
      String content, String query) {
    if (query.isEmpty || content.isEmpty) return '';
    final lower = query.toLowerCase();
    // Split into sentences/paragraphs
    final paragraphs = content
        .split(RegExp(r'\n+'))
        .where((p) => p.trim().isNotEmpty)
        .toList();

    for (final para in paragraphs) {
      if (para.toLowerCase().contains(lower)) {
        // Return the paragraph trimmed
        return para.trim().length > 200
            ? '${para.trim().substring(0, 200)}...'
            : para.trim();
      }
    }

    // Fallback: search sentence by sentence
    final sentences = content.split(RegExp(r'[.!?]+'));
    for (final sentence in sentences) {
      if (sentence.toLowerCase().contains(lower)) {
        final s = sentence.trim();
        return s.length > 200
            ? '${s.substring(0, 200)}...'
            : s;
      }
    }

    // Last fallback: find the word and show context around it
    final idx = content.toLowerCase().indexOf(lower);
    if (idx != -1) {
      final start = (idx - 60).clamp(0, content.length);
      final end =
      (idx + lower.length + 80).clamp(0, content.length);
      String excerpt = content.substring(start, end).trim();
      if (start > 0) excerpt = '...$excerpt';
      if (end < content.length) excerpt = '$excerpt...';
      return excerpt;
    }
    return '';
  }

  // ✅ Highlight matching text with pink background
  Widget _buildHighlightedText(
      String text,
      String query, {
        int maxLines = 3,
        double fontSize = 13,
        Color baseColor = Colors.black87,
        bool bold = false,
      }) {
    if (query.isEmpty) {
      return Text(text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: fontSize,
              color: baseColor,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal));
    }

    final spans = <TextSpan>[];
    final lower = text.toLowerCase();
    final lowerQ = query.toLowerCase();
    int start = 0;

    while (true) {
      final idx = lower.indexOf(lowerQ, start);
      if (idx == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: TextStyle(
              fontSize: fontSize,
              color: baseColor,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal),
        ));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: TextStyle(
              fontSize: fontSize,
              color: baseColor,
              fontWeight: bold
                  ? FontWeight.bold
                  : FontWeight.normal),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          fontSize: fontSize,
          color: const Color(0xFFAD1457),
          fontWeight: FontWeight.bold,
          backgroundColor:
          const Color(0xFFFFC107).withOpacity(0.35),
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDark;
    final bg = isDark
        ? const Color(0xFF1A0A12)
        : const Color(0xFFFCE4EC);
    final cardBg =
    isDark ? const Color(0xFF2D0F1C) : Colors.white;
    final searchBg =
    isDark ? const Color(0xFF2D0F1C) : Colors.white;

    return WillPopScope(
      onWillPop: () async {
        _goBack();
        return false;
      },
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ── Search bar ────────────────────
              Container(
                color: searchBg,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    if (!widget.isTab)
                      IconButton(
                        onPressed: _goBack,
                        icon: Icon(Icons.arrow_back,
                            color: isDark
                                ? Colors.white
                                : Colors.black87),
                      ),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        autofocus: !widget.isTab,
                        style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : Colors.black87),
                        onChanged: (v) {
                          // ✅ Search from 1 character
                          if (v.length >= 1) {
                            search(v);
                          } else if (v.isEmpty) {
                            setState(() {
                              results = [];
                              hasSearched = false;
                              currentQuery = '';
                            });
                          }
                        },
                        onSubmitted: search,
                        decoration: InputDecoration(
                          hintText:
                          'Search notes, keywords...',
                          hintStyle: TextStyle(
                              color: Colors.grey[400]),
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.search,
                              color: Colors.grey[400]),
                          suffixIcon: searchController
                              .text.isNotEmpty
                              ? IconButton(
                            onPressed: () {
                              searchController
                                  .clear();
                              setState(() {
                                results = [];
                                hasSearched =
                                false;
                                currentQuery = '';
                              });
                            },
                            icon: const Icon(
                                Icons.clear),
                          )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Results count ─────────────────
              if (hasSearched && !isSearching)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      20, 10, 20, 4),
                  child: Text(
                    '${results.length} result${results.length == 1 ? '' : 's'} for "$currentQuery"',
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12),
                  ),
                ),

              // ── Results ───────────────────────
              Expanded(
                child: isSearching
                    ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFAD1457)))
                    : !hasSearched
                    ? Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(Icons.search,
                          size: 72,
                          color:
                          Colors.grey[300]),
                      const SizedBox(
                          height: 16),
                      Text('Search your notes',
                          style: TextStyle(
                              color: Colors
                                  .grey[400],
                              fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                          'Results appear as you type',
                          style: TextStyle(
                              color: Colors
                                  .grey[300],
                              fontSize: 13)),
                    ],
                  ),
                )
                    : results.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                    children: [
                      Icon(Icons.search_off,
                          size: 72,
                          color: Colors
                              .grey[300]),
                      const SizedBox(
                          height: 16),
                      Text(
                          'No results for "$currentQuery"',
                          style: TextStyle(
                              color: Colors
                                  .grey[400],
                              fontSize: 15)),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding:
                  const EdgeInsets.all(
                      16),
                  itemCount: results.length,
                  itemBuilder: (ctx, i) {
                    final note =
                    results[i];
                    final content =
                        note['content']
                            ?.toString() ??
                            '';
                    final title =
                        note['title']
                            ?.toString() ??
                            'Untitled';
                    final List<String>
                    tags =
                    List<String>.from(
                        note['tags'] ??
                            []);

                    // ✅ Find the specific
                    // paragraph with the word
                    final matchPara =
                    _findMatchingParagraph(
                        content,
                        currentQuery);

                    return GestureDetector(
                      onTap: () =>
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ViewNoteScreen(
                                    noteID:
                                    note['id'] ??
                                        '',
                                    note: note,
                                    searchQuery:
                                    currentQuery,
                                  ),
                            ),
                          ),
                      child: Container(
                        margin: const EdgeInsets
                            .only(
                            bottom: 12),
                        decoration:
                        BoxDecoration(
                          color: cardBg,
                          borderRadius:
                          BorderRadius
                              .circular(
                              16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                  0.06),
                              blurRadius:
                              10,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                          children: [
                            // ✅ MATCHING PARAGRAPH shown at top
                            // with highlighted word — before user
                            // even opens the note
                            if (matchPara
                                .isNotEmpty)
                              Container(
                                width: double
                                    .infinity,
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                    horizontal:
                                    14,
                                    vertical:
                                    10),
                                decoration:
                                BoxDecoration(
                                  color: const Color(
                                      0xFFFFC107)
                                      .withOpacity(
                                      0.12),
                                  borderRadius:
                                  const BorderRadius
                                      .vertical(
                                    top: Radius
                                        .circular(
                                        16),
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: const Color(
                                          0xFFFFC107)
                                          .withOpacity(
                                          0.3),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                            Icons
                                                .format_quote_rounded,
                                            size:
                                            12,
                                            color: Color(
                                                0xFFAD1457)),
                                        const SizedBox(
                                            width:
                                            4),
                                        Text(
                                          'Matching paragraph',
                                          style: TextStyle(
                                              fontSize:
                                              10,
                                              color: Colors
                                                  .grey[500],
                                              fontWeight:
                                              FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                        height:
                                        5),
                                    // ✅ Highlighted paragraph text
                                    _buildHighlightedText(
                                      matchPara,
                                      currentQuery,
                                      maxLines:
                                      4,
                                      fontSize:
                                      13,
                                      baseColor: isDark
                                          ? Colors
                                          .white70
                                          : Colors
                                          .black87,
                                    ),
                                  ],
                                ),
                              ),

                            // ── Note title + tags ──
                            Padding(
                              padding:
                              const EdgeInsets
                                  .all(14),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                                children: [
                                  _buildHighlightedText(
                                    title,
                                    currentQuery,
                                    maxLines:
                                    1,
                                    fontSize:
                                    15,
                                    bold:
                                    true,
                                    baseColor: isDark
                                        ? Colors
                                        .white
                                        : Colors
                                        .black87,
                                  ),
                                  if (tags
                                      .isNotEmpty) ...[
                                    const SizedBox(
                                        height:
                                        8),
                                    Wrap(
                                      spacing:
                                      6,
                                      runSpacing:
                                      4,
                                      children: tags
                                          .map((t) =>
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal:
                                                8,
                                                vertical:
                                                3),
                                            decoration: BoxDecoration(
                                                color: const Color(0xFFAD1457).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(20)),
                                            child: Text(
                                                t,
                                                style: const TextStyle(fontSize: 11, color: Color(0xFFAD1457))),
                                          ))
                                          .toList(),
                                    ),
                                  ],
                                  const SizedBox(
                                      height:
                                      4),
                                  Row(
                                    children: [
                                      Icon(
                                          Icons
                                              .touch_app_outlined,
                                          size:
                                          11,
                                          color: Colors
                                              .grey[400]),
                                      const SizedBox(
                                          width:
                                          3),
                                      Text(
                                          'Tap to open full note',
                                          style: TextStyle(
                                              fontSize:
                                              10,
                                              color: Colors
                                                  .grey[400])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}