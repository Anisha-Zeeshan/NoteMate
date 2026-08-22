import 'package:flutter/material.dart';
import '../../services/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../camera/camera_screen.dart';
import '../notes/notes_list_screen.dart';
import '../notes/notepad_editor_screen.dart';
import '../search/search_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';
import '../camera/ocr_result_screen.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/avatar_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../gemini/gemini_chat_screen.dart';
import '../../services/document_extraction_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();
  AvatarOption _selectedAvatar = kAvatars.first;
  String _selectedAvatarId = 'f1';

  @override
  void initState() {
    super.initState();
    _loadSavedAvatar();
  }

  Future<void> _loadSavedAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('selected_avatar_id') ?? 'f1';
    final found = kAvatars.firstWhere(
          (a) => a.id == savedId,
      orElse: () => kAvatars.first,
    );
    if (mounted) {
      setState(() {
        _selectedAvatarId = found.id;
        _selectedAvatar = found;
      });
    }
  }

  // ── Avatar picker ────────────────────────────
  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPickerSheet(
        selectedId: _selectedAvatarId,
        onSelected: (av) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selected_avatar_id', av.id);
          if (mounted) {
            setState(() {
              _selectedAvatar = av;
              _selectedAvatarId = av.id;
            });
          }
        },
      ),
    );
  }

  // ── Import bottom sheet ───────────────────────
  void _showImportOptions() {
    final isDark = ThemeProvider().isDark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark
          ? const Color(0xFF2D0F1C)
          : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                'Import Document',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose where to import from',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              _buildImportOption(
                icon: Icons.photo_library,
                color: Colors.purple,
                title: 'Photo Gallery',
                subtitle:
                'Select one or multiple photos',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickMultipleImages();
                },
              ),
              const SizedBox(height: 12),
              _buildImportOption(
                icon: Icons.folder_outlined,
                color: Colors.orange,
                title: 'Files',
                subtitle:
                'PDF, Word docs, images from Files',
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromFiles();
                },
              ),
              const SizedBox(height: 12),
              _buildImportOption(
                icon: Icons.camera_alt_outlined,
                color: const Color(0xFFAD1457),
                title: 'Camera',
                subtitle: 'Take a new photo right now',
                onTap: () async {
                  Navigator.pop(context);
                  if (!mounted) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            CameraScreen()),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images =
      await _picker.pickMultiImage(
          imageQuality: 100);
      if (!mounted) return;
      if (images.isEmpty) return;
      if (images.length == 1) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OCRResultScreen(
                imageFile: File(images.first.path)),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OCRResultScreen(
                imageFiles: images
                    .map((x) => File(x.path))
                    .toList()),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Could not open gallery: $e')),
      );
    }
  }

  Future<void> _pickFromFiles() async {
    try {
      final result =
      await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'docx', 'doc',
          'jpg', 'jpeg', 'png', 'webp',
        ],
      );
      if (!mounted) return;
      if (result == null ||
          result.files.isEmpty) return;
      final files = result.files
          .where((f) => f.path != null)
          .map((f) => File(f.path!))
          .toList();
      if (files.isEmpty) return;
      final hasDocument = files.any((f) {
        final ext = f.path.toLowerCase();
        return ext.endsWith('.pdf') ||
            ext.endsWith('.docx') ||
            ext.endsWith('.doc');
      });
      if (hasDocument) {
        _showExtractionLoading();
        final text = await DocumentExtractionService
            .extractFromFiles(files);
        if (!mounted) return;
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OCRResultScreen(
                preExtractedText: text),
          ),
        );
      } else {
        if (files.length == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OCRResultScreen(
                  imageFile: files.first),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OCRResultScreen(
                  imageFiles: files),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Could not open files: $e')),
      );
    }
  }

  void _showExtractionLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(
                color: Color(0xFFAD1457)),
            SizedBox(width: 20),
            Text('Extracting text...'),
          ],
        ),
      ),
    );
  }

  Widget _buildImportOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeProvider().isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ── Floating nav bar ──────────────────────────
  Widget _buildFloatingNav() {
    final isDark = ThemeProvider().isDark;
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.camera_alt_rounded, 'label': 'Camera'},
      {'icon': Icons.search_rounded, 'label': 'Search'},
      {'icon': Icons.bar_chart_rounded, 'label': 'Stats'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D0F1C)
            : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.5)
                : const Color(0xFFAD1457)
                .withOpacity(0.15),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : const Color(0xFFAD1457)
              .withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment:
        MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final isSelected = _currentIndex == i;
          final icon =
          items[i]['icon'] as IconData;
          final label =
          items[i]['label'] as String;
          return GestureDetector(
            onTap: () =>
                setState(() => _currentIndex = i),
            child: AnimatedContainer(
              duration: const Duration(
                  milliseconds: 250),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 16 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFAD1457)
                    : Colors.transparent,
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? Colors.white
                        : isDark
                        ? Colors.grey[500]
                        : Colors.grey[400],
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1A0A12)
          : const Color(0xFFFCE4EC),
      body: Stack(
        children: [
          // Main content with bottom padding
          Padding(
            padding:
            const EdgeInsets.only(bottom: 80),
            child: _buildBody(),
          ),

          // ✅ Floating nav bar - above phone nav bar
          Positioned(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 12,
            child: _buildFloatingNav(),
          ),

          // ✅ FABs only on home tab
          if (_currentIndex == 0)
            Positioned(
              right: 20,
              bottom: MediaQuery.of(context).padding.bottom + 88,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Gemini AI
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                          const GeminiChatScreen()),
                    ),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFAD1457),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFAD1457).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Create note
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              NotepadEditorScreen()),
                    ),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC107),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFC107).withOpacity(0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ],
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return CameraScreen();
      case 2:
        return const SearchScreen();
      case 3:
        return DashboardScreen();
      case 4:
        return SettingsScreen();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    final isDark = ThemeProvider().isDark;
    final textColor =
    isDark ? Colors.white : Colors.black87;

    // Clean display name (remove avatar id suffix)
    final rawName =
        user?.displayName ?? 'Student';
    final displayName = rawName.contains('av:')
        ? rawName.split('av:').first.trim()
        : rawName;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const ConnectivityBanner(),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello! 👋',
                        style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white70
                                : Colors.black54),
                      ),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight:
                          FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showAvatarPicker(),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFAD1457), width: 2),
                        color: _selectedAvatar.outfitColor.withOpacity(0.12),
                      ),
                      child: ClipOval(
                        child: AvatarWidget(avatar: _selectedAvatar, size: 48),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Actions
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text('Quick Actions ✏️',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics:
                    const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildActionCard(
                        icon: Icons.camera_alt,
                        title: 'Capture',
                        subtitle:
                        'Take photo of notes',
                        color:
                        const Color(0xFFFFC107),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CameraScreen()),
                        ),
                      ),
                      _buildActionCard(
                        icon: Icons.upload_file,
                        title: 'Import',
                        subtitle:
                        'Gallery, PDF, Files',
                        color: Colors.cyan
                            .withOpacity(0.8),
                        onTap: _showImportOptions,
                      ),
                      _buildActionCard(
                        icon: Icons.edit_note,
                        title: 'Create',
                        subtitle: 'Write new note',
                        color: const Color(0xFFAD1457)
                            .withOpacity(0.8),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NotepadEditorScreen()),
                        ),
                      ),
                      _buildActionCard(
                        icon: Icons.notes,
                        title: 'My Notes',
                        subtitle: 'View all notes',
                        color: Colors.purple
                            .withOpacity(0.7),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  NotesListScreen()),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Notes header
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20),
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Notes',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              NotesListScreen()),
                    ),
                    child: const Text('See All',
                        style: TextStyle(
                          color: Color(0xFFAD1457),
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notes')
                  .where('userID',
                  isEqualTo: FirebaseAuth
                      .instance.currentUser!.uid)
                  .orderBy('createdAt',
                  descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                          color: Color(0xFFAD1457)),
                    ),
                  );
                }
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding:
                      const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          Icon(
                              Icons.note_alt_outlined,
                              size: 60,
                              color:
                              Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No notes yet!\nCapture or create your first note.',
                            textAlign:
                            TextAlign.center,
                            style: TextStyle(
                                color:
                                Colors.grey[500],
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final notes = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics:
                  const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index].data()
                    as Map<String, dynamic>;
                    return _buildNoteCard(note);
                  },
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = ThemeProvider().isDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2D0F1C)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
              Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: Icon(icon,
                  color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark
                    ? Colors.white
                    : Colors.black87,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(
      Map<String, dynamic> note) {
    final isDark = ThemeProvider().isDark;
    final List<String> tags =
    List<String>.from(note['tags'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2D0F1C)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  note['title'] ?? 'Untitled',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? Colors.white
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _formatDate(note['createdAt']),
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            note['content'] ?? '',
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (tags.isNotEmpty)
            Wrap(
              spacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFFAD1457)
                        .withOpacity(0.15)
                        : const Color(0xFFFCE4EC),
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFFAD1457),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}