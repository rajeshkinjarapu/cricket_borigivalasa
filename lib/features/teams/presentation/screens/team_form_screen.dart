import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../../players/data/models/player.dart';
import '../../../players/presentation/providers/player_providers.dart';
import '../../../tournaments/presentation/providers/tournament_providers.dart';
import '../providers/team_providers.dart';
import '../../data/models/team.dart';

class TeamFormScreen extends ConsumerStatefulWidget {
  const TeamFormScreen({super.key, this.teamId, this.tournamentId});
  final String? teamId;
  final String? tournamentId;
  
  bool get isEdit => teamId != null;

  @override
  ConsumerState<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends ConsumerState<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shortNameController = TextEditingController();
  final _captainNameController = TextEditingController();
  String? _captainId;
  String? _logoUrl;
  String? _selectedTournamentId;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedTournamentId = widget.tournamentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortNameController.dispose();
    _captainNameController.dispose();
    super.dispose();
  }

  void _hydrate(Team t) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameController.text = t.name;
    _shortNameController.text = t.shortName;
    _captainNameController.text = t.captainName ?? '';
    _captainId = t.captainId;
    _logoUrl = t.logoUrl;
    if (t.tournamentIds.isNotEmpty && _selectedTournamentId == null) {
      _selectedTournamentId = t.tournamentIds.first;
    }
  }

  ImageProvider? _getImageProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      if (url.startsWith('data:image') || url.length > 500) {
        final base64String = url.contains(',') ? url.split(',').last : url;
        return MemoryImage(base64Decode(base64String));
      }
      return NetworkImage(url);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickLogo() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      final base64String = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      setState(() => _logoUrl = base64String);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick logo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final controller = ref.read(teamControllerProvider.notifier);
    final targetTournamentId = _selectedTournamentId ?? widget.tournamentId;

    if (widget.isEdit) {
      final existing = ref.read(teamDetailProvider(widget.teamId!)).value;
      if (existing == null) {
        setState(() => _isSaving = false);
        return;
      }
      
      List<String> tIds = List.from(existing.tournamentIds);
      if (targetTournamentId != null && !tIds.contains(targetTournamentId)) {
        tIds.add(targetTournamentId);
      }

      final success = await controller.update(existing.copyWith(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().toUpperCase(),
        captainName: _captainNameController.text.trim().isEmpty ? null : _captainNameController.text.trim(),
        captainId: _captainId,
        logoUrl: _logoUrl,
        tournamentIds: tIds,
      ));
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Team updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ));
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update team'), backgroundColor: Colors.red));
        }
      }
    } else {
      final id = await controller.create(Team(
        id: '',
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().toUpperCase(),
        captainName: _captainNameController.text.trim().isEmpty ? null : _captainNameController.text.trim(),
        captainId: _captainId,
        logoUrl: _logoUrl,
        tournamentIds: targetTournamentId != null ? [targetTournamentId] : [],
      ));
      if (mounted) {
        setState(() => _isSaving = false);
        if (id != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Team created successfully!'),
            backgroundColor: Color(0xFF16A34A),
          ));
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to create team'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final t = ref.watch(teamDetailProvider(widget.teamId!)).value;
      if (t != null) _hydrate(t);
    }

    final tournamentsAsync = ref.watch(allTournamentsProvider);
    final allPlayersAsync = ref.watch(allPlayersProvider);
    final imageProvider = _getImageProvider(_logoUrl);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isEdit ? 'Edit Team' : 'Create New Team',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Team Logo Upload Picker ──
              Center(
                child: GestureDetector(
                  onTap: _pickLogo,
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF1E3A8A), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          image: imageProvider != null
                              ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                              : null,
                        ),
                        child: imageProvider == null
                            ? const Center(
                                child: Icon(Icons.shield_outlined, size: 48, color: Color(0xFF1E3A8A)),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: const BoxDecoration(
                            color: Color(0xFF1E3A8A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text(
                  'Tap to upload team logo / photo',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 20),

              // ── Card 1: Team Basic Info ──
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Information',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Team Full Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Team Full Name *',
                          hintText: 'e.g. Borigivalasa Warriors',
                          prefixIcon: const Icon(Icons.groups_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().length < 2) {
                            return 'Please enter a valid team name (at least 2 characters)';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          if (!widget.isEdit && _shortNameController.text.isEmpty) {
                            final words = val.trim().split(RegExp(r'\s+'));
                            if (words.length >= 2) {
                              _shortNameController.text = (words[0][0] + words[1][0]).toUpperCase();
                            } else if (words.isNotEmpty && words[0].length >= 3) {
                              _shortNameController.text = words[0].substring(0, 3).toUpperCase();
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // Short Name
                      TextFormField(
                        controller: _shortNameController,
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 5,
                        decoration: InputDecoration(
                          labelText: 'Short Code / Acronym *',
                          hintText: 'e.g. BW',
                          prefixIcon: const Icon(Icons.tag_rounded),
                          counterText: '',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter short code (e.g. BW, CSK, RCB)';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Card 2: Captain Selection ──
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Team Captain',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Captain Selection Dropdown (from registered players)
                      allPlayersAsync.when(
                        data: (players) {
                          if (players.isNotEmpty) {
                            return DropdownButtonFormField<String>(
                              value: _captainId,
                              decoration: InputDecoration(
                                labelText: 'Select Captain from Players',
                                prefixIcon: const Icon(Icons.person_pin_rounded),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: [
                                const DropdownMenuItem<String>(
                                  value: null,
                                  child: Text('Type custom captain name below'),
                                ),
                                ...players.map((p) => DropdownMenuItem<String>(
                                      value: p.id,
                                      child: Text('${p.name} (${p.role.label})'),
                                    )),
                              ],
                              onChanged: (selectedId) {
                                setState(() {
                                  _captainId = selectedId;
                                  if (selectedId != null) {
                                    final p = players.firstWhere((e) => e.id == selectedId);
                                    _captainNameController.text = p.name;
                                    // Default team logo to captain's photo if no logo is selected yet
                                    if (_logoUrl == null && p.profilePicUrl != null) {
                                      _logoUrl = p.profilePicUrl;
                                    }
                                  }
                                });
                              },
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 14),

                      // Manual Captain Name
                      TextFormField(
                        controller: _captainNameController,
                        decoration: InputDecoration(
                          labelText: 'Captain Name (Optional)',
                          hintText: 'e.g. Rajesh Kinjarapu',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Card 3: Assign to Tournament ──
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tournament Assignment',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 14),

                      tournamentsAsync.when(
                        data: (tournaments) {
                          if (tournaments.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'No tournaments available. You can add the team to a tournament later.',
                                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            );
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedTournamentId,
                            decoration: InputDecoration(
                              labelText: 'Assign to Tournament (Optional)',
                              prefixIcon: const Icon(Icons.emoji_events_outlined),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: [
                              const DropdownMenuItem<String>(
                                value: null,
                                child: Text('No Tournament / Standalone Club'),
                              ),
                              ...tournaments.map((t) => DropdownMenuItem<String>(
                                    value: t.id,
                                    child: Text(t.name),
                                  )),
                            ],
                            onChanged: (val) => setState(() => _selectedTournamentId = val),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error loading tournaments: $err', style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Submit Button ──
              SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A), // Emerald Green Action
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          widget.isEdit ? 'SAVE CHANGES' : 'CREATE TEAM',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 1),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
