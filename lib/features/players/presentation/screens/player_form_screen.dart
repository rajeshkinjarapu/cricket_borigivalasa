import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../auth/data/models/app_user.dart';
import '../../data/models/player.dart';
import '../providers/player_providers.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({
    super.key,
    this.player,
    this.playerId,
    this.teamId,
    this.tournamentId,
  });

  final Player? player;
  final String? playerId;
  final String? teamId;
  final String? tournamentId;

  bool get isEdit => player != null || playerId != null;

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _jerseyController;
  late TextEditingController _phoneController;

  PlayerRole _role = PlayerRole.batter;
  BattingStyle _battingStyle = BattingStyle.rightHand;
  BowlingStyle _bowlingStyle = BowlingStyle.none;
  String? _profilePicUrl;

  bool _isSaving = false;
  bool _isLoaded = false;
  Player? _resolvedPlayer;

  @override
  void initState() {
    super.initState();
    _resolvedPlayer = widget.player;
    _nameController = TextEditingController(text: _resolvedPlayer?.name ?? '');
    _jerseyController = TextEditingController(text: _resolvedPlayer?.jerseyNumber?.toString() ?? '');
    _phoneController = TextEditingController(text: _resolvedPlayer?.phoneNumber ?? '');
    if (_resolvedPlayer != null) {
      _role = _resolvedPlayer!.role;
      _battingStyle = _resolvedPlayer!.battingStyle;
      _bowlingStyle = _resolvedPlayer!.bowlingStyle;
      _profilePicUrl = _resolvedPlayer!.profilePicUrl;
      _isLoaded = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _hydrate(Player p) {
    if (_isLoaded) return;
    _isLoaded = true;
    _resolvedPlayer = p;
    _nameController.text = p.name;
    _jerseyController.text = p.jerseyNumber?.toString() ?? '';
    _phoneController.text = p.phoneNumber ?? '';
    _role = p.role;
    _battingStyle = p.battingStyle;
    _bowlingStyle = p.bowlingStyle;
    _profilePicUrl = p.profilePicUrl;
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() => _profilePicUrl = base64String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick photo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  ImageProvider? _previewImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      if (photoUrl.startsWith('data:image') || photoUrl.length > 500) {
        final base64String = photoUrl.contains(',') ? photoUrl.split(',').last : photoUrl;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(photoUrl);
    } catch (_) {
      return null;
    }
  }

  /// Automatically provisions login credentials if mobile number is provided
  Future<void> _provisionUserAccount({
    required String name,
    required String phoneNumber,
    String? photoUrl,
  }) async {
    final cleanPhone = phoneNumber.trim().replaceAll(' ', '').replaceAll('-', '');
    if (cleanPhone.length < 5) return;

    final authEmail = '$cleanPhone@member.cricket.com';
    final password = cleanPhone; // Default password is mobile number

    try {
      // 1. Create in Firebase Auth using temporary app so Admin is NOT signed out
      final tempApp = await Firebase.initializeApp(
        name: 'temp_create_player_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      String? createdUid;
      try {
        final cred = await FirebaseAuth.instanceFor(app: tempApp)
            .createUserWithEmailAndPassword(email: authEmail, password: password);
        final u = cred.user!;
        await u.updateDisplayName(name.trim());
        createdUid = u.uid;
      } catch (e) {
        debugPrint('Note: Auth creation info ($authEmail): $e');
      } finally {
        await tempApp.delete();
      }

      // 2. Add / Update in Firestore `users` collection
      final firestore = FirebaseFirestore.instance;
      if (createdUid != null) {
        final appUser = AppUser(
          uid: createdUid,
          email: authEmail,
          displayName: name.trim(),
          role: UserRole.member,
          photoUrl: photoUrl,
          createdAt: DateTime.now(),
        );
        await firestore
            .collection(AppConstants.usersCollection)
            .doc(createdUid)
            .set(appUser.toJson()..remove('uid'), SetOptions(merge: true));
      } else {
        // Query if user doc already exists with this email
        final existing = await firestore
            .collection(AppConstants.usersCollection)
            .where('email', isEqualTo: authEmail)
            .limit(1)
            .get();

        if (existing.docs.isEmpty) {
          await firestore.collection(AppConstants.usersCollection).add({
            'email': authEmail,
            'displayName': name.trim(),
            'role': UserRole.member.name,
            'photoUrl': photoUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      debugPrint('Error provisioning user record: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final controller = ref.read(playerControllerProvider.notifier);
    final name = _nameController.text.trim();
    final jerseyNo = int.tryParse(_jerseyController.text.trim());
    final phone = _phoneController.text.trim();

    try {
      if (widget.isEdit && _resolvedPlayer != null) {
        // Update existing player
        await controller.update(_resolvedPlayer!.copyWith(
          name: name,
          teamId: '', // Players are global club players, can play in any team
          role: _role,
          battingStyle: _battingStyle,
          bowlingStyle: _bowlingStyle,
          jerseyNumber: jerseyNo,
          phoneNumber: phone.isNotEmpty ? phone : null,
          profilePicUrl: _profilePicUrl,
        ));

        // If phone number is updated, provision/sync credentials
        if (phone.isNotEmpty) {
          await _provisionUserAccount(
            name: name,
            phoneNumber: phone,
            photoUrl: _profilePicUrl,
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Player updated successfully!'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Create new player
        await controller.create(Player(
          id: '',
          name: name,
          teamId: '', // Players belong to club, can play in any team
          role: _role,
          battingStyle: _battingStyle,
          bowlingStyle: _bowlingStyle,
          jerseyNumber: jerseyNo,
          phoneNumber: phone.isNotEmpty ? phone : null,
          profilePicUrl: _profilePicUrl,
        ));

        // Auto-provision login credentials if mobile number is provided
        if (phone.isNotEmpty) {
          await _provisionUserAccount(
            name: name,
            phoneNumber: phone,
            photoUrl: _profilePicUrl,
          );
        }

        if (mounted) {
          if (phone.isNotEmpty) {
            // Show Success Dialog with Login Credentials
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Player Registered!',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$name has been added to the club.',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🔑 Auto-Created Login Details:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Text('Mobile / ID: ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              Text(phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Text('Password: ', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              Text(phone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Player registered successfully!'),
                backgroundColor: Color(0xFF16A34A),
              ),
            );
          }

          if (mounted) Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving player: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.playerId != null && !_isLoaded) {
      final p = ref.watch(playerDetailProvider(widget.playerId!)).value;
      if (p != null) _hydrate(p);
    }

    final isEditMode = widget.isEdit || _resolvedPlayer != null;
    final imageProvider = _previewImage(_profilePicUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // Uniform Royal Blue Header
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isEditMode ? 'Edit Player' : 'Add New Player',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19, color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Player Photo Section ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                      GestureDetector(
                        onTap: _pickPhoto,
                        child: Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22), // Modern Squircle
                                color: const Color(0xFFEFF6FF),
                                border: Border.all(color: const Color(0xFF1E3A8A), width: 2.5),
                                image: imageProvider != null
                                    ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                                    : null,
                              ),
                              child: imageProvider == null
                                  ? const Icon(Icons.person_rounded, size: 54, color: Color(0xFF94A3B8))
                                  : null,
                            ),
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1E3A8A),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to choose profile photo',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Basic Info Card ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.badge_outlined, color: Color(0xFF1E3A8A), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Player Information',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Player Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Player Name *',
                          hintText: 'Enter full name',
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
                      ),
                      const SizedBox(height: 14),

                      // Mobile Number Field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: 'e.g. 9876543210',
                          prefixIcon: const Icon(Icons.phone_android_rounded, color: Color(0xFF64748B)),
                          helperText: '💡 Used as automatic Login ID & Password',
                          helperStyle: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 11.5, fontWeight: FontWeight.w600),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Jersey Number Field
                      TextFormField(
                        controller: _jerseyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jersey Number (Optional)',
                          hintText: 'e.g. 7 or 18',
                          prefixIcon: const Icon(Icons.tag_rounded, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Cricket Roles & Styles Card ──
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.sports_cricket_rounded, color: Color(0xFF1E3A8A), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cricket Playing Style',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Role Dropdown (Batter, Bowler, All-Rounder, Wicket Keeper)
                      DropdownButtonFormField<PlayerRole>(
                        value: _role,
                        decoration: InputDecoration(
                          labelText: 'Role *',
                          prefixIcon: const Icon(Icons.sports_cricket_outlined, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: PlayerRole.batter,
                            child: Row(
                              children: [
                                Icon(Icons.sports_cricket, size: 18, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text('🏏 Batter'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PlayerRole.bowler,
                            child: Row(
                              children: [
                                Icon(Icons.sports_baseball, size: 18, color: Color(0xFF16A34A)),
                                SizedBox(width: 8),
                                Text('🎳 Bowler'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PlayerRole.allRounder,
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, size: 18, color: Color(0xFF9333EA)),
                                SizedBox(width: 8),
                                Text('⭐ All-Rounder'),
                              ],
                            ),
                          ),
                          DropdownMenuItem(
                            value: PlayerRole.wicketKeeper,
                            child: Row(
                              children: [
                                Icon(Icons.pan_tool_rounded, size: 18, color: Color(0xFFD97706)),
                                SizedBox(width: 8),
                                Text('🧤 Wicket Keeper / Batter'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                      const SizedBox(height: 14),

                      // Batting Style
                      DropdownButtonFormField<BattingStyle>(
                        value: _battingStyle,
                        decoration: InputDecoration(
                          labelText: 'Batting Style',
                          prefixIcon: const Icon(Icons.sports, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: BattingStyle.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _battingStyle = v!),
                      ),
                      const SizedBox(height: 14),

                      // Bowling Style
                      DropdownButtonFormField<BowlingStyle>(
                        value: _bowlingStyle,
                        decoration: InputDecoration(
                          labelText: 'Bowling Style',
                          prefixIcon: const Icon(Icons.sports_baseball_outlined, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                        items: BowlingStyle.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _bowlingStyle = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Save Button ──
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A), // Emerald Green
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: const Color(0xFF16A34A).withOpacity(0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            isEditMode ? 'SAVE CHANGES' : 'REGISTER PLAYER',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.8),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
