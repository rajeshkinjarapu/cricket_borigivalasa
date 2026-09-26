import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../../core/utils/avatar_helper.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;
  Uint8List? _localPhotoBytes;

  // ─── Change Password Dialog ───
  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 10),
                Text('Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (errorMsg != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(errorMsg!,
                          style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  _dialogField(
                    controller: currentCtrl,
                    label: 'Current Password',
                    obscure: obscureCurrent,
                    onToggle: () =>
                        setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: newCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: () =>
                        setDialogState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConfirm,
                    onToggle: () =>
                        setDialogState(() => obscureConfirm = !obscureConfirm),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (currentCtrl.text.isEmpty ||
                            newCtrl.text.isEmpty ||
                            confirmCtrl.text.isEmpty) {
                          setDialogState(() => errorMsg = 'All fields are required');
                          return;
                        }
                        if (newCtrl.text.length < 6) {
                          setDialogState(() =>
                              errorMsg = 'New password must be at least 6 characters');
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          setDialogState(() => errorMsg = 'New passwords do not match');
                          return;
                        }
                        setDialogState(() {
                          isLoading = true;
                          errorMsg = null;
                        });
                        try {
                          await ref.read(authRepositoryProvider).changePassword(
                                currentPassword: currentCtrl.text,
                                newPassword: newCtrl.text,
                              );
                          if (dialogCtx.mounted) {
                            Navigator.of(dialogCtx).pop();
                          }
                          if (mounted) {
                            _showSuccessSnack('Password changed successfully!');
                          }
                        } catch (e) {
                          String msg = 'Something went wrong. Try again.';
                          final err = e.toString();
                          if (err.contains('wrong-password') ||
                              err.contains('invalid-credential')) {
                            msg = 'Current password is incorrect';
                          } else if (err.contains('weak-password')) {
                            msg = 'Password is too weak';
                          } else if (err.contains('requires-recent-login')) {
                            msg = 'Please sign out and sign in again to change password';
                          }
                          setDialogState(() {
                            errorMsg = msg;
                            isLoading = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Change Password'),
              ),
            ],
          );
        });
      },
    );
  }

  // ─── Edit Name Dialog (Admin only) ───
  Future<void> _showEditNameDialog(String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (c, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_outline_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 10),
                Text('Edit Name', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter name',
                prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF1E3A8A)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final newName = ctrl.text.trim();
                        if (newName.isEmpty) return;
                        setDialogState(() => isUpdating = true);
                        try {
                          await ref.read(authRepositoryProvider).updateProfile(displayName: newName);
                          ref.invalidate(authStateProvider);
                          ref.invalidate(currentUserProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            _showSuccessSnack('Name updated successfully!');
                          }
                        } catch (e) {
                          setDialogState(() => isUpdating = false);
                          if (ctx.mounted) {
                            _showErrorSnack('Failed to update name. Try again.');
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  void _showSuccessSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey, size: 20),
          onPressed: onToggle,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 70,
    );
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final ext = pickedFile.name.split('.').last.toLowerCase();

    setState(() {
      _isUploadingPhoto = true;
      _localPhotoBytes = bytes;
    });

    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(imageBytes: bytes, fileExtension: ext.isNotEmpty ? ext : 'jpg');
      await ref.read(authRepositoryProvider).refreshProfile();
      ref.invalidate(authStateProvider);
      ref.invalidate(currentUserProvider);
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSuccessSnack('Profile photo updated successfully!');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingPhoto = false;
          _localPhotoBytes = null;
        });
        _showErrorSnack('Failed to update photo: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          foregroundColor: Colors.white,
          title: const Text('My Profile'),
        ),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final bool isAdmin = user.role == UserRole.admin;
    final bool isScorer = user.role == UserRole.scorer;

    // Check if member has played at least 1 match
    final loggedInPlayer = ref.watch(loggedInPlayerProvider).value;
    final bool hasPlayed = loggedInPlayer != null &&
        (loggedInPlayer.stats.matchesPlayed > 0 ||
            loggedInPlayer.stats.runsScored > 0 ||
            loggedInPlayer.stats.wicketsTaken > 0);

    // Determine Role Badge attributes
    final String roleTitle;
    final IconData roleIcon;
    final List<Color> roleGradient;
    final Color roleTextColor;
    final Color avatarBorderColor;

    if (isAdmin) {
      roleTitle = 'ADMINISTRATOR';
      roleIcon = Icons.workspace_premium_rounded;
      roleGradient = const [Color(0xFFFEF3C7), Color(0xFFFDE68A)];
      roleTextColor = const Color(0xFF92400E);
      avatarBorderColor = const Color(0xFFF59E0B);
    } else if (isScorer) {
      roleTitle = 'SCORER';
      roleIcon = Icons.sports_score_rounded;
      roleGradient = const [Color(0xFFD1FAE5), Color(0xFFA7F3D0)];
      roleTextColor = const Color(0xFF065F46);
      avatarBorderColor = const Color(0xFF10B981);
    } else if (hasPlayed) {
      roleTitle = 'PLAYER';
      roleIcon = Icons.sports_cricket_rounded;
      roleGradient = const [Color(0xFFDBEAFE), Color(0xFFBFDBFE)];
      roleTextColor = const Color(0xFF1E40AF);
      avatarBorderColor = const Color(0xFF2563EB);
    } else {
      roleTitle = 'MEMBER';
      roleIcon = Icons.badge_rounded;
      roleGradient = const [Color(0xFFF1F5F9), Color(0xFFE2E8F0)];
      roleTextColor = const Color(0xFF475569);
      avatarBorderColor = const Color(0xFF94A3B8);
    }

    final imageProvider = _localPhotoBytes != null
        ? MemoryImage(_localPhotoBytes!)
        : getAppAvatarProvider(user.photoUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => context.pop(),
              )
            : null,
        title: const Text(
          'My Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 19,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // ── Main Profile Header Card ──
          _ProfileCard(
            child: Column(
              children: [
                const SizedBox(height: 6),

                // ── Squircle Profile Photo ──
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: avatarBorderColor,
                            width: 2.5,
                          ),
                          color: const Color(0xFF0F172A),
                          boxShadow: [
                            BoxShadow(
                              color: avatarBorderColor.withOpacity(0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(19.5),
                          child: _isUploadingPhoto
                              ? Container(
                                  color: const Color(0xFF1E3A8A),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : (imageProvider != null)
                                  ? Image(
                                      image: imageProvider,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          _buildAvatarFallback(user.displayName),
                                    )
                                  : _buildAvatarFallback(user.displayName),
                        ),
                      ),
                      Positioned(
                        bottom: -4,
                        right: -4,
                        child: GestureDetector(
                          onTap: _pickAndUploadPhoto,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isAdmin
                                    ? const [Color(0xFFF59E0B), Color(0xFFD97706)]
                                    : const [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Name (No edit icon for members; only admin can edit if needed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName.isNotEmpty ? user.displayName : 'Member',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showEditNameDialog(user.displayName),
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.edit_rounded,
                              size: 15, color: Color(0xFF1E3A8A)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),

                // Dynamic Role Badge (ADMIN / SCORER / PLAYER / MEMBER)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: roleGradient),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: roleTextColor.withOpacity(0.12),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(roleIcon, size: 14, color: roleTextColor),
                      const SizedBox(width: 6),
                      Text(
                        roleTitle,
                        style: TextStyle(
                          color: roleTextColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Mini Player Stats Ribbon (if player has played) ──
                if (hasPlayed && loggedInPlayer != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _miniStatItem('Matches', '${loggedInPlayer.stats.matchesPlayed}'),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        _miniStatItem('Runs', '${loggedInPlayer.stats.runsScored}'),
                        Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                        _miniStatItem('Wickets', '${loggedInPlayer.stats.wicketsTaken}'),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ── Admin Privileges ──
          if (isAdmin) ...[
            const _SectionHeader(title: 'Administrator Access'),
            _ProfileCard(
              child: Column(
                children: [
                  const _ActionTile(
                    icon: Icons.admin_panel_settings_rounded,
                    title: 'Access Level',
                    subtitle: 'Full Administrative Access',
                    iconColor: Color(0xFFD97706),
                  ),
                  const _Divider(),
                  const _ActionTile(
                    icon: Icons.emoji_events_rounded,
                    title: 'Tournament Manager',
                    subtitle: 'Create, edit & manage tournaments',
                    iconColor: Color(0xFF2563EB),
                  ),
                  const _Divider(),
                  const _ActionTile(
                    icon: Icons.sports_cricket_rounded,
                    title: 'Live Match Scorer',
                    subtitle: 'Full live match scoring controls',
                    iconColor: Color(0xFF16A34A),
                  ),
                  const _Divider(),
                  const _ActionTile(
                    icon: Icons.manage_accounts_rounded,
                    title: 'Member Management',
                    subtitle: 'Promote, demote & manage members',
                    iconColor: Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Player Information (Without Current Team) ──
          if (!isAdmin) ...[
            const _SectionHeader(title: 'Player Information'),
            _ProfileCard(
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.sports_cricket,
                    title: 'Batting Style',
                    subtitle: loggedInPlayer?.battingStyle.label ?? 'Right hand',
                    iconColor: const Color(0xFF1E3A8A),
                  ),
                  const _Divider(),
                  _ActionTile(
                    icon: Icons.sports_baseball,
                    title: 'Bowling Style',
                    subtitle: loggedInPlayer?.bowlingStyle.label ?? 'Right-arm medium',
                    iconColor: const Color(0xFF059669),
                  ),
                  const _Divider(),
                  _ActionTile(
                    icon: Icons.shield_rounded,
                    title: 'Playing Role',
                    subtitle: loggedInPlayer?.role.label ?? 'All-rounder',
                    iconColor: const Color(0xFF2563EB),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // ── Settings & Security ──
          const _SectionHeader(title: 'Settings & Security'),
          _ProfileCard(
            child: Column(
              children: [
                _ActionTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  iconColor: const Color(0xFF7C3AED),
                  onTap: _showChangePasswordDialog,
                ),
                const _Divider(),
                _ActionTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Push Notifications',
                  subtitle: 'Match alerts & scoring updates',
                  iconColor: const Color(0xFF2563EB),
                  trailing: Switch(
                    value: true,
                    activeColor: const Color(0xFF1E3A8A),
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Sign Out Button ──
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Sign Out',
                style: TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                shadowColor: const Color(0xFFDC2626).withOpacity(0.35),
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Row(
                      children: [
                        Icon(Icons.logout_rounded, color: Color(0xFFDC2626), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Sign Out',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    content: const Text(
                      'Are you sure you want to sign out of your account?',
                      style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          await ref.read(authControllerProvider.notifier).signOut();
                          ref.invalidate(authStateProvider);
                          ref.invalidate(currentUserProvider);
                          if (context.mounted) {
                            context.go('/login');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1E3A8A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 38,
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──

class _ProfileCard extends StatelessWidget {
  final Widget child;
  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EEF9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E3A8A),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8), size: 22)
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      color: Color(0xFFF1F5F9),
      indent: 44,
    );
  }
}
