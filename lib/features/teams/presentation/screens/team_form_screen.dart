import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  bool _isSaving = false;
  bool _isLoaded = false;

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
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    final controller = ref.read(teamControllerProvider.notifier);
    
    if (widget.isEdit) {
      final existing = ref.read(teamDetailProvider(widget.teamId!)).value;
      if (existing == null) {
        setState(() => _isSaving = false);
        return;
      }
      
      // Keep existing tournamentIds, add new one if it exists
      List<String> tIds = List.from(existing.tournamentIds);
      if (widget.tournamentId != null && !tIds.contains(widget.tournamentId)) {
        tIds.add(widget.tournamentId!);
      }

      await controller.update(existing.copyWith(
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().toUpperCase(),
        captainName: _captainNameController.text.trim().isEmpty ? null : _captainNameController.text.trim(),
        tournamentIds: tIds,
      ));
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team updated!')));
        context.pop();
      }
    } else {
      final id = await controller.create(Team(
        id: '',
        name: _nameController.text.trim(),
        shortName: _shortNameController.text.trim().toUpperCase(),
        captainName: _captainNameController.text.trim().isEmpty ? null : _captainNameController.text.trim(),
        tournamentIds: widget.tournamentId != null ? [widget.tournamentId!] : [],
      ));
      if (mounted && id != null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Team created successfully!')));
        context.pop();
      } else if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final t = ref.watch(teamDetailProvider(widget.teamId!)).value;
      if (t != null) _hydrate(t);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Team' : 'Create Team', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      child: Icon(Icons.shield, size: 50, color: Theme.of(context).primaryColor),
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
                      const Text('Team Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Team Name (e.g. Borigivalasa Blasters)',
                          prefixIcon: const Icon(Icons.sports_cricket),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _shortNameController,
                        decoration: InputDecoration(
                          labelText: 'Short Name (e.g. BB)',
                          prefixIcon: const Icon(Icons.short_text),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        maxLength: 4,
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _captainNameController,
                        decoration: InputDecoration(
                          labelText: 'Captain Name (Optional)',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
                      : Text(widget.isEdit ? 'Update Team' : 'Create Team', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
