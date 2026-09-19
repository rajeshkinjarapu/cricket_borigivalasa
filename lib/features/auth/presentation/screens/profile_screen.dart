import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 10),
                Text('Change Password',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: newCtrl,
                    label: 'New Password',
                    obscure: obscureNew,
                    onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _dialogField(
                    controller: confirmCtrl,
                    label: 'Confirm New Password',
                    obscure: obscureConfirm,
                    onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
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
                          setDialogState(
                              () => errorMsg = 'New password must be at least 6 characters');
                          return;
                        }
                        if (newCtrl.text != confirmCtrl.text) {
                          setDialogState(
                              () => errorMsg = 'New passwords do not match');
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
                          if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Password changed successfully!'),
                                  ],
                                ),
                                backgroundColor: Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image') || !photoUrl.startsWith('http')) {
        final base64String = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(photoUrl);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickAndUploadPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);
    final bytes = await pickedFile.readAsBytes();
    final ext = pickedFile.name.split('.').last.toLowerCase();

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(imageBytes: bytes, fileExtension: ext);

    if (mounted) {
      setState(() => _isUploadingPhoto = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update photo.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E3A8A),
          foregroundColor: Colors.white,
          title: const Text('My Profile'),
        ),
        body: const Center(child: Text('Not logged in')),
      );
    }

    final bool isAdmin = user.role == UserRole.admin;
    final imageProvider = _getImageProvider(user.photoUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        children: [
          // ── Profile Photo & Name Card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Avatar with Camera Picker
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isAdmin ? const Color(0xFFFFB300) : const Color(0xFF1E3A8A),
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isAdmin ? const Color(0xFFFFB300) : const Color(0xFF1E3A8A)).withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _isUploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E3A8A)),
                              )
                            : (imageProvider != null)
                                ? Image(
                                    image: imageProvider,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildAvatarFallback(user.displayName),
                                  )
                                : _buildAvatarFallback(user.displayName),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4),
                            ],
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Name with Edit Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      user.displayName.isNotEmpty ? user.displayName : 'Administrator',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)),
                      onPressed: () => _showEditNameDialog(context, user.displayName),
                    ),
                  ],
                ),

                // Email
                Text(
                  user.email,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    gradient: isAdmin
                        ? const LinearGradient(
                            colors: [Color(0xFFFFE082), Color(0xFFFFB300), Color(0xFFFFA000)],
                          )
                        : null,
                    color: !isAdmin ? const Color(0xFFE2E8F0) : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isAdmin
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFB300).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAdmin ? Icons.workspace_premium_rounded : Icons.sports_cricket_rounded,
                        size: 14,
                        color: const Color(0xFF0F172A),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isAdmin ? 'ADMINISTRATOR' : 'MEMBER',
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Admin Privileges & System Access (Shown ONLY for Admins) ──
          if (isAdmin) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Administrator Access & Privileges',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
            ),
            _buildCard([
              _buildListTile(Icons.admin_panel_settings_rounded, 'Access Level', 'Full Administrative Access', iconColor: const Color(0xFFD97706)),
              const Divider(height: 1),
              _buildListTile(Icons.emoji_events_rounded, 'Tournament Manager', 'Create, edit & manage tournaments', iconColor: const Color(0xFF2563EB)),
              const Divider(height: 1),
              _buildListTile(Icons.sports_cricket_rounded, 'Live Match Scorer', 'Full live match scoring controls', iconColor: const Color(0xFF16A34A)),
              const Divider(height: 1),
              _buildListTile(Icons.manage_accounts_rounded, 'Member Management', 'Promote, demote & manage members', iconColor: const Color(0xFF7C3AED)),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Player Details (Shown ONLY for Members) ──
          if (!isAdmin) ...[
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Player Information',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
              ),
            ),
            _buildCard([
              _buildListTile(Icons.sports_cricket, 'Batting Style', 'Right-hand bat'),
              const Divider(height: 1),
              _buildListTile(Icons.sports_baseball, 'Bowling Style', 'Right-arm medium'),
              const Divider(height: 1),
              _buildListTile(Icons.group_rounded, 'Current Team', 'Borigivalasa Blasters'),
            ]),
            const SizedBox(height: 20),
          ],

          // ── Settings & Security Section ──
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Settings & Security',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF475569)),
            ),
          ),
          _buildCard([
            _buildListTile(
              Icons.lock_outline_rounded,
              'Change Password',
              'Update your account password',
              onTap: _showChangePasswordDialog,
            ),
            const Divider(height: 1),
            _buildListTile(
              Icons.notifications_active_outlined,
              'Push Notifications',
              'Match alerts & scoring updates',
              trailing: Switch(
                value: true,
                activeColor: const Color(0xFF1E3A8A),
                onChanged: (_) {},
              ),
            ),
            const Divider(height: 1),
            _buildListTile(
              Icons.info_outline_rounded,
              'App Version',
              'Borigivalasa Cricket App v1.0.0',
            ),
          ]),
          const SizedBox(height: 24),

          // ── Sign Out Button ──
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
              label: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 1,
              ),
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'A';
    return Container(
      color: const Color(0xFF1E3A8A),
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

  Future<void> _showEditNameDialog(BuildContext context, String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (c, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Display Name', style: TextStyle(fontWeight: FontWeight.bold)),
            content: TextField(
              controller: ctrl,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(),
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
                        if (ctrl.text.trim().isEmpty) return;
                        setState(() => isUpdating = true);
                        final success = await ref
                            .read(authControllerProvider.notifier)
                            .updateProfile(displayName: ctrl.text.trim());
                        if (success && ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name updated successfully!')),
                          );
                        } else {
                          setState(() => isUpdating = false);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to update name.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(children: children),
        ),
      ),
    );
  }

  Widget _buildListTile(
    IconData icon,
    String title,
    String subtitle, {
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF1E3A8A)).withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFF1E3A8A), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: Color(0xFF0F172A)),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20)
              : null),
      onTap: onTap,
    );
  }
}
