import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../providers/player_providers.dart';
import '../../data/models/player.dart';

class PlayerFormScreen extends ConsumerStatefulWidget {
  const PlayerFormScreen({super.key, required this.teamId, required this.tournamentId, this.playerId});
  final String teamId;
  final String tournamentId;
  final String? playerId;

  bool get isEdit => playerId != null;

  @override
  ConsumerState<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends ConsumerState<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _jerseyController = TextEditingController();
  
  PlayerRole _role = PlayerRole.batter;
  BattingStyle _battingStyle = BattingStyle.rightHand;
  BowlingStyle _bowlingStyle = BowlingStyle.none;

  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    super.dispose();
  }

  void _hydrate(Player p) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameController.text = p.name;
    _jerseyController.text = p.jerseyNumber?.toString() ?? '';
    _role = p.role;
    _battingStyle = p.battingStyle;
    _bowlingStyle = p.bowlingStyle;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final controller = ref.read(playerControllerProvider.notifier);
    final jerseyNo = int.tryParse(_jerseyController.text.trim());

    if (widget.isEdit) {
      final existing = ref.read(playerDetailProvider(widget.playerId!)).value;
      if (existing == null) {
        setState(() => _isSaving = false);
        return;
      }
      await controller.update(existing.copyWith(
        name: _nameController.text.trim(),
        role: _role,
        battingStyle: _battingStyle,
        bowlingStyle: _bowlingStyle,
        jerseyNumber: jerseyNo,
      ));
    } else {
      await controller.create(Player(
        id: '',
        name: _nameController.text.trim(),
        teamId: widget.teamId,
        role: _role,
        battingStyle: _battingStyle,
        bowlingStyle: _bowlingStyle,
        jerseyNumber: jerseyNo,
      ));
    }

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.isEdit ? 'Player updated!' : 'Player added to squad!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final p = ref.watch(playerDetailProvider(widget.playerId!)).value;
      if (p != null) _hydrate(p);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Player' : 'Add Player', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, size: 50, color: Theme.of(context).primaryColor),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Theme.of(context).primaryColor,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image upload coming soon!')));
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Player Info', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Player Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jerseyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jersey Number (Optional)',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cricket Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<PlayerRole>(
                        value: _role,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: const Icon(Icons.sports_cricket),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: PlayerRole.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<BattingStyle>(
                        value: _battingStyle,
                        decoration: InputDecoration(
                          labelText: 'Batting Style',
                          prefixIcon: const Icon(Icons.sports),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: BattingStyle.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _battingStyle = v!),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<BowlingStyle>(
                        value: _bowlingStyle,
                        decoration: InputDecoration(
                          labelText: 'Bowling Style',
                          prefixIcon: const Icon(Icons.sports_baseball),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: BowlingStyle.values
                            .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                            .toList(),
                        onChanged: (v) => setState(() => _bowlingStyle = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(widget.isEdit ? 'Save Changes' : 'Add Player', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
