import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../data/models/tournament.dart';
import '../providers/tournament_providers.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class TournamentFormScreen extends ConsumerStatefulWidget {
  const TournamentFormScreen({super.key, this.tournamentId});
  final String? tournamentId;
  bool get isEdit => tournamentId != null;

  @override
  ConsumerState<TournamentFormScreen> createState() => _TournamentFormScreenState();
}

class _TournamentFormScreenState extends ConsumerState<TournamentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _venueController = TextEditingController();
  TournamentFormat _format = TournamentFormat.t20;
  TournamentStatus _status = TournamentStatus.upcoming;
  DateTime? _startDate, _endDate;
  bool _isSaving = false;
  bool _isLoaded = false;

  @override
  void dispose() {
    _nameController.dispose();
    _venueController.dispose();
    super.dispose();
  }

  void _hydrate(Tournament t) {
    if (_isLoaded) return;
    _isLoaded = true;
    _nameController.text = t.name;
    _venueController.text = t.venue ?? '';
    _format = t.format;
    _status = t.status;
    _startDate = t.startDate;
    _endDate = t.endDate;
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startDate = picked;
        else _endDate = picked;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a start date')));
      return;
    }

    setState(() => _isSaving = true);
    final controller = ref.read(tournamentControllerProvider.notifier);
    final user = ref.read(currentUserProvider);

    if (widget.isEdit) {
      final existing = ref.read(tournamentDetailProvider(widget.tournamentId!)).value;
      if (existing == null) {
        setState(() => _isSaving = false);
        return;
      }
      await controller.update(existing.copyWith(
        name: _nameController.text.trim(),
        format: _format,
        status: _status,
        startDate: _startDate,
        endDate: _endDate,
        venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
      ));
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament updated')));
        context.pop();
      }
    } else {
      final id = await controller.create(Tournament(
        id: '',
        name: _nameController.text.trim(),
        format: _format,
        status: _status,
        organizerId: user?.uid ?? '',
        startDate: _startDate!,
        endDate: _endDate,
        venue: _venueController.text.trim().isEmpty ? null : _venueController.text.trim(),
      ));
      if (mounted && id != null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tournament created successfully!')));
        context.pop();
      } else if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final t = ref.watch(tournamentDetailProvider(widget.tournamentId!)).value;
      if (t != null) _hydrate(t);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Tournament' : 'Create Tournament', style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                      const Text('Basic Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Tournament Name',
                          prefixIcon: const Icon(Icons.emoji_events_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Name must be at least 2 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _venueController,
                        decoration: InputDecoration(
                          labelText: 'Venue / Ground (Optional)',
                          prefixIcon: const Icon(Icons.place_outlined),
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
                      const Text('Format & Dates', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TournamentFormat>(
                              value: _format,
                              decoration: InputDecoration(
                                labelText: 'Format',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: TournamentFormat.values.map((f) => DropdownMenuItem(value: f, child: Text(f.label))).toList(),
                              onChanged: (v) => setState(() => _format = v!),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<TournamentStatus>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: TournamentStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                              onChanged: (v) => setState(() => _status = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Text(_startDate == null ? 'Start Date' : DateFormat('MMM d, yyyy').format(_startDate!), style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade400),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 20, color: Colors.black54),
                                    const SizedBox(width: 8),
                                    Text(_endDate == null ? 'End Date' : DateFormat('MMM d, yyyy').format(_endDate!), style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      : Text(widget.isEdit ? 'Update Tournament' : 'Create Tournament', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
