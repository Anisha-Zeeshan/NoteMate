import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_services.dart';
import '../../services/theme_provider.dart';
import '../../widgets/avatar_picker.dart';
import '../auth/welcome_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  _SettingsScreenState createState() =>
      _SettingsScreenState();
}

class _SettingsScreenState
    extends State<SettingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool notificationsEnabled = true;
  String _selectedAvatarId = 'f1';
  AvatarOption _selectedAvatar = kAvatars.first;

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

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarPickerSheet(
        selectedId: _selectedAvatarId,
        onSelected: (av) async {
          //  Save to SharedPreferences immediately
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('selected_avatar_id', av.id);
          if (mounted) {
            setState(() {
              _selectedAvatarId = av.id;
              _selectedAvatar = av;
            });
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avatar updated! ✓'),
                backgroundColor: Color(0xFFAD1457),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameCtrl = TextEditingController(
        text: user?.displayName
            ?.split('av:')
            .first
            .trim() ??
            '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile'),
        content: TextField(
          controller: nameCtrl,
          decoration: InputDecoration(
            labelText: 'Display Name',
            border: OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await user?.updateDisplayName(
                  '${nameCtrl.text.trim()} av:$_selectedAvatarId');
              if (!mounted) return;
              Navigator.pop(ctx);
              setState(() {});
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(
                content: Text('Profile updated!'),
                backgroundColor: Colors.green,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor:
                const Color(0xFFAD1457)),
            child: const Text('Save',
                style:
                TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20)),
          title: const Text('Notifications'),
          content: SwitchListTile(
            title: const Text('Study reminders'),
            value: notificationsEnabled,
            activeColor: const Color(0xFFAD1457),
            onChanged: (v) {
              set(() => notificationsEnabled = v);
              setState(
                      () => notificationsEnabled = v);
            },
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFFAD1457)),
              child: const Text('Done',
                  style: TextStyle(
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivacyDialog() => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(20)),
      title: const Text('Privacy'),
      content: const SingleChildScrollView(
        child: Text(
          '• Notes stored securely in Firebase\n\n'
              '• Images processed for OCR only\n\n'
              '• Data never shared with third parties\n\n'
              '• Delete account removes all data\n\n'
              '• Offline AI keeps data on device',
          style:
          TextStyle(fontSize: 13, height: 1.7),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFFAD1457)),
          child: const Text('Got it',
              style: TextStyle(
                  color: Colors.white)),
        ),
      ],
    ),
  );

  void _showHelpDialog() => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(20)),
      title: const Text('Help & Support'),
      content: const SingleChildScrollView(
        child: Text(
          '📷 Capture — Photo of notes\n\n'
              '📁 Import — PDF, DOCX, images\n\n'
              '✏️ Create — Write manually\n\n'
              '🔍 Search — Find by keyword\n\n'
              '📊 Dashboard — Study stats\n\n'
              '📴 Offline — Uses Qwen AI locally',
          style:
          TextStyle(fontSize: 13, height: 1.7),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx),
          style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFFAD1457)),
          child: const Text('Got it',
              style: TextStyle(
                  color: Colors.white)),
        ),
      ],
    ),
  );

  void _showDeleteDialog() => showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(20)),
      title: const Text('Delete Account',
          style: TextStyle(color: Colors.red)),
      content: const Text(
          'All your notes will be permanently deleted. This cannot be undone.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            try {
              await user?.delete();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        WelcomeScreen()),
                    (r) => false,
              );
            } catch (_) {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(
                content: Text(
                    'Please re-login first'),
                backgroundColor: Colors.red,
              ));
            }
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red),
          child: const Text('Delete',
              style: TextStyle(
                  color: Colors.white)),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeProvider().isDark;
    final bg = isDark
        ? const Color(0xFF1A0A12)
        : const Color(0xFFFCE4EC);
    final cardBg = isDark
        ? const Color(0xFF2D0F1C)
        : Colors.white;
    final textColor =
    isDark ? Colors.white : Colors.black87;
    final sub =
    isDark ? Colors.grey[400] : Colors.grey[600];

    // Get clean display name
    final displayName =
    (user?.displayName ?? 'User')
        .split('av:')
        .first
        .trim();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    20, 20, 20, 4),
                child: Text('Settings',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),

              const SizedBox(height: 12),

              // ── Profile card ─────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius:
                    BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.07),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar with tap
                      GestureDetector(
                        onTap: _showAvatarPicker,
                        child: Stack(children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: _selectedAvatar
                                  .outfitColor
                                  .withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(
                                    0xFFAD1457),
                                width: 2.5,
                              ),
                            ),
                            child: ClipOval(
                              child: AvatarWidget(
                                avatar:
                                _selectedAvatar,
                                size: 72,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration:
                              const BoxDecoration(
                                color: Color(0xFFAD1457),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.edit,
                                  size: 13,
                                  color: Colors.white),
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: sub),
                              overflow:
                              TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(children: [
                              _profileChip(
                                'Edit Profile',
                                Icons.edit_outlined,
                                _showEditProfileDialog,
                              ),
                              const SizedBox(width: 8),
                              _profileChip(
                                'Avatar',
                                Icons.face_outlined,
                                _showAvatarPicker,
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Preferences', sub),
              const SizedBox(height: 8),

              // ── Dark Mode ────────────────────
              _card(
                cardBg: cardBg,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _icon(
                      isDark
                          ? Icons.dark_mode
                          : Icons.light_mode_outlined,
                      const Color(0xFFAD1457)),
                  title: Text('Dark Mode',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  subtitle: Text(
                    isDark
                        ? 'Dark theme enabled'
                        : 'Light theme enabled',
                    style: TextStyle(
                        fontSize: 12, color: sub),
                  ),
                  trailing: Switch(
                    value: isDark,
                    activeColor:
                    const Color(0xFFAD1457),
                    onChanged: (_) async {
                      await ThemeProvider()
                          .toggleTheme();
                      setState(() {});
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Notifications ────────────────
              _card(
                cardBg: cardBg,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _icon(
                      Icons.notifications_outlined,
                      Colors.orange),
                  title: Text('Notifications',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  subtitle: Text(
                    notificationsEnabled
                        ? 'Study reminders on'
                        : 'Reminders off',
                    style: TextStyle(
                        fontSize: 12, color: sub),
                  ),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey),
                  onTap: _showNotificationsDialog,
                ),
              ),

              const SizedBox(height: 24),
              _sectionLabel('Account', sub),
              const SizedBox(height: 8),

              // ── Privacy ──────────────────────
              _card(
                cardBg: cardBg,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _icon(
                      Icons.lock_outline,
                      Colors.blue),
                  title: Text('Privacy',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  subtitle: Text('Data & privacy policy',
                      style: TextStyle(
                          fontSize: 12, color: sub)),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey),
                  onTap: _showPrivacyDialog,
                ),
              ),

              const SizedBox(height: 10),

              // ── Help ─────────────────────────
              _card(
                cardBg: cardBg,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _icon(
                      Icons.help_outline,
                      Colors.green),
                  title: Text('Help & Support',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  subtitle: Text('How to use NoteMate',
                      style: TextStyle(
                          fontSize: 12, color: sub)),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey),
                  onTap: _showHelpDialog,
                ),
              ),

              const SizedBox(height: 10),

              // ── About ────────────────────────
              _card(
                cardBg: cardBg,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _icon(
                      Icons.info_outline,
                      Colors.purple),
                  title: Text('About NoteMate',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: textColor)),
                  subtitle: Text('Version 1.0.0',
                      style: TextStyle(
                          fontSize: 12, color: sub)),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'NoteMate',
                    applicationVersion: '1.0.0',
                    applicationLegalese:
                    '© 2026 NoteMate',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Delete Account ───────────────
              _card(
                cardBg: cardBg,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: _icon(
                      Icons.delete_forever_outlined,
                      Colors.red),
                  title: const Text('Delete Account',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.red)),
                  subtitle: Text(
                      'Remove account permanently',
                      style: TextStyle(
                          fontSize: 12, color: sub)),
                  trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey),
                  onTap: _showDeleteDialog,
                ),
              ),

              const SizedBox(height: 30),

              // ── Sign Out Button ──────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20),
                child: GestureDetector(
                  onTap: () async {
                    await AuthService.logout();
                    if (!mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              WelcomeScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFAD1457),
                          Color(0xFFE91E63),
                        ],
                      ),
                      borderRadius:
                      BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFAD1457)
                              .withOpacity(0.45),
                          blurRadius: 20,
                          spreadRadius: 2,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout_rounded,
                            color: Colors.white,
                            size: 22),
                        SizedBox(width: 10),
                        Text('Sign Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.bold,
                              letterSpacing: 0.5,
                            )),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              Center(
                child: Text('NoteMate v1.0.0',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400])),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileChip(
      String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFAD1457)
              .withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: const Color(0xFFAD1457),
              width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 11,
                color: const Color(0xFFAD1457)),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFAD1457),
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, Color? sub) =>
      Padding(
        padding:
        const EdgeInsets.fromLTRB(24, 0, 20, 0),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: sub,
            letterSpacing: 1.2,
          ),
        ),
      );

  Widget _icon(IconData icon, Color color) =>
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      );

  Widget _card(
      {required Color cardBg,
        required Widget child}) =>
      Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: child,
        ),
      );
}