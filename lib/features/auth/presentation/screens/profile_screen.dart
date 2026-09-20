import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/auth_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  bool _isUploadingPhoto = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.lock_reset_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 10),
                Text('Change Password',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                          style:
                              const TextStyle(color: Colors.red, fontSize: 13)),
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
                onPressed:
                    isLoading ? null : () => Navigator.of(dialogCtx).pop(),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        if (currentCtrl.text.isEmpty ||
                            newCtrl.text.isEmpty ||
                            confirmCtrl.text.isEmpty) {
                          setDialogState(
                              () => errorMsg = 'All fields are required');
                          return;
                        }
                        if (newCtrl.text.length < 6) {
                          setDialogState(() => errorMsg =
                              'New password must be at least 6 characters');
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
                          await ref
                              .read(authRepositoryProvider)
                              .changePassword(
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
                            msg =
                                'Please sign out and sign in again to change password';
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Change Password'),
              ),
            ],
          );
        });
      },
    );
  }

  // ─── Edit Name Dialog ───
  Future<void> _showEditNameDialog(String currentName) async {
    final ctrl = TextEditingController(text: currentName);
    bool isUpdating = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (c, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.person_outline_rounded, color: Color(0xFF1E3A8A)),
                SizedBox(width: 10),
                Text('Edit Name',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: TextField(
              controller: ctrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: const Icon(Icons.badge_outlined,
                    color: Color(0xFF1E3A8A)),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final newName = ctrl.text.trim();
                        if (newName.isEmpty) return;
                        setDialogState(() => isUpdating = true);
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .updateProfile(displayName: newName);
                          // Invalidate so UI refreshes immediately
                          ref.invalidate(authStateProvider);
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  // ─── Edit Email Dialog ───
  Future<void> _showEditEmailDialog(String currentEmail) async {
    final emailCtrl = TextEditingController(text: currentEmail);
    final passCtrl = TextEditingController();
    bool isUpdating = false;
    bool obscurePass = true;
    String? errorMsg;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(builder: (c, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.email_outlined, color: Color(0xFF1E3A8A)),
                SizedBox(width: 10),
                Text('Change Email',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            content: Column(
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
                        style:
                            const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'New Email Address',
                    prefixIcon: const Icon(Icons.alternate_email_rounded,
                        color: Color(0xFF1E3A8A)),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Current Password (to confirm)',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        color: Color(0xFF1E3A8A)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          obscurePass
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                          size: 20),
                      onPressed: () =>
                          setDialogState(() => obscurePass = !obscurePass),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Color(0xFF1E3A8A), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '⚠️ A verification link will be sent to your new email.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isUpdating ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                        final newEmail = emailCtrl.text.trim();
                        final pass = passCtrl.text;
                        if (newEmail.isEmpty || pass.isEmpty) {
                          setDialogState(
                              () => errorMsg = 'All fields are required');
                          return;
                        }
                        if (!newEmail.contains('@')) {
                          setDialogState(
                              () => errorMsg = 'Enter a valid email address');
                          return;
                        }
                        setDialogState(() {
                          isUpdating = true;
                          errorMsg = null;
                        });
                        try {
                          await ref
                              .read(authRepositoryProvider)
                              .updateEmail(
                                newEmail: newEmail,
                                currentPassword: pass,
                              );
                          ref.invalidate(authStateProvider);
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            _showSuccessSnack(
                                'Verification email sent! Please check your inbox.');
                          }
                        } catch (e) {
                          String msg = 'Failed to update email. Try again.';
                          final err = e.toString();
                          if (err.contains('wrong-password') ||
                              err.contains('invalid-credential')) {
                            msg = 'Incorrect password';
                          } else if (err.contains('email-already-in-use')) {
                            msg = 'This email is already in use';
                          }
                          setDialogState(() {
                            errorMsg = msg;
                            isUpdating = false;
                          });
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Send Verification'),
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
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF1E3A8A), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
    );
  }

  ImageProvider? _getImageProvider(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image') ||
          !photoUrl.startsWith('http')) {
        final base64String = photoUrl.contains(',')
            ? photoUrl.split(',').last
            : photoUrl;
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

    try {
      await ref
          .read(authRepositoryProvider)
          .updateProfile(imageBytes: bytes, fileExtension: ext);
      ref.invalidate(authStateProvider);
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showSuccessSnack('Profile photo updated!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
        _showErrorSnack('Failed to update photo.');
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
    final Color brandColor =
        isAdmin ? const Color(0xFFD97706) : const Color(0xFF1E3A8A);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // ── Sliver App Bar with gradient ──
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F2464), Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Decorative circles
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.04),
                        ),
                      ),
                    ),
                    // Avatar at bottom center
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white, width: 3.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _isUploadingPhoto
                                    ? Container(
                                        color: const Color(0xFF1E3A8A),
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: Colors.white),
                                        ),
                                      )
                                    : (imageProvider != null)
                                        ? Image(
                                            image: imageProvider,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildAvatarFallback(
                                                    user.displayName),
                                          )
                                        : _buildAvatarFallback(
                                            user.displayName),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _pickAndUploadPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: brandColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 6),
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body Content ──
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  children: [
                    // ── Name & Role Card ──
                    _ProfileCard(
                      child: Column(
                        children: [
                          const SizedBox(height: 4),
                          // Name with edit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName
                                      : 'Member',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () =>
                                    _showEditNameDialog(user.displayName),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E3A8A)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                      Icons.edit_rounded,
                                      size: 16,
                                      color: Color(0xFF1E3A8A)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Email with edit
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.alternate_email_rounded,
                                  size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  user.email,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () =>
                                    _showEditEmailDialog(user.email),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Role Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: isAdmin
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFFFFE082),
                                        Color(0xFFFFB300),
                                        Color(0xFFFFA000)
                                      ],
                                    )
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFFDBEAFE),
                                        Color(0xFFBFD9FE)
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: brandColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isAdmin
                                      ? Icons.workspace_premium_rounded
                                      : Icons.sports_cricket_rounded,
                                  size: 15,
                                  color: isAdmin
                                      ? const Color(0xFF78350F)
                                      : const Color(0xFF1E3A8A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isAdmin ? 'ADMINISTRATOR' : 'MEMBER',
                                  style: TextStyle(
                                    color: isAdmin
                                        ? const Color(0xFF78350F)
                                        : const Color(0xFF1E3A8A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Admin Privileges ──
                    if (isAdmin) ...[
                      _SectionHeader(title: 'Administrator Access'),
                      _ProfileCard(
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.admin_panel_settings_rounded,
                              title: 'Access Level',
                              subtitle: 'Full Administrative Access',
                              iconColor: const Color(0xFFD97706),
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.emoji_events_rounded,
                              title: 'Tournament Manager',
                              subtitle: 'Create, edit & manage tournaments',
                              iconColor: const Color(0xFF2563EB),
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.sports_cricket_rounded,
                              title: 'Live Match Scorer',
                              subtitle: 'Full live match scoring controls',
                              iconColor: const Color(0xFF16A34A),
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.manage_accounts_rounded,
                              title: 'Member Management',
                              subtitle:
                                  'Promote, demote & manage members',
                              iconColor: const Color(0xFF7C3AED),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Player Information (Members only) ──
                    if (!isAdmin) ...[
                      _SectionHeader(title: 'Player Information'),
                      _ProfileCard(
                        child: Column(
                          children: [
                            _ActionTile(
                              icon: Icons.sports_cricket,
                              title: 'Batting Style',
                              subtitle: 'Right-hand bat',
                              iconColor: const Color(0xFF1E3A8A),
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.sports_baseball,
                              title: 'Bowling Style',
                              subtitle: 'Right-arm medium',
                              iconColor: const Color(0xFF059669),
                            ),
                            const _Divider(),
                            _ActionTile(
                              icon: Icons.group_rounded,
                              title: 'Current Team',
                              subtitle: 'Borigivalasa Blasters',
                              iconColor: const Color(0xFFD97706),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Settings & Security ──
                    _SectionHeader(title: 'Settings & Security'),
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
                    const SizedBox(height: 28),

                    // ── Sign Out Button ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout_rounded,
                            color: Colors.white, size: 18),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                          shadowColor:
                              const Color(0xFFDC2626).withOpacity(0.4),
                        ),
                        onPressed: () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signOut();
                          if (context.mounted) context.go('/login');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
