import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/cricket_enums.dart';
import '../../data/models/match.dart';
import '../providers/match_providers.dart';

Future<bool> showTossSheet(BuildContext context, WidgetRef ref,
    {required String tournamentId, required Match match}) async {
  final r = await showModalBottomSheet<bool>(context: context,
    isScrollControlled: true, showDragHandle: true,
    builder: (_) => _Toss(tournamentId: tournamentId, match: match, ref: ref));
  return r ?? false;
}

class _Toss extends StatefulWidget {
  const _Toss({required this.tournamentId, required this.match,
    required this.ref});
  final String tournamentId;
  final Match match;
  final WidgetRef ref;
  @override
  State<_Toss> createState() => _S();
}
class _S extends State<_Toss> {
  String? _w;
  TossDecision _d = TossDecision.bat;
  bool _s = false;
  Future<void> _ok() async {
    if (_w == null) return;
    setState(() => _s = true);
    final ok = await widget.ref.read(matchControllerProvider.notifier).setToss(
      tournamentId: widget.tournamentId, matchId: widget.match.id,
      tossWinnerTeamId: _w!, tossDecision: _d);
    if (mounted) { setState(() => _s = false);
      if (ok) Navigator.pop(context, true); }
  }
  @override
  Widget build(BuildContext context) {
    final m = widget.match;
    return Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 8,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Toss', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text('Who won the toss?'),
        const SizedBox(height: 8),
        ..._team(m.teamAId, m.teamAName, m.teamAShort),
        ..._team(m.teamBId, m.teamBName, m.teamBShort),
        const SizedBox(height: 16),
        const Text('Decision'),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: ChoiceChip(label: const Text('Bat first'),
            selected: _d == TossDecision.bat,
            onSelected: (_) => setState(() => _d = TossDecision.bat))),
          const SizedBox(width: 12),
          Expanded(child: ChoiceChip(label: const Text('Bowl first'),
            selected: _d == TossDecision.bowl,
            onSelected: (_) => setState(() => _d = TossDecision.bowl))),
        ]),
        const SizedBox(height: 24),
        FilledButton(onPressed: (_w == null || _s) ? null : _ok,
          child: _s ? const SizedBox(height: 20, width: 20,
            child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Start match')),
      ]));
  }
  List<Widget> _team(String id, String n, String s) => [Card(
    elevation: 0,
    color: _w == id ? Theme.of(context).colorScheme.primaryContainer
      : Theme.of(context).colorScheme.surfaceContainerHighest,
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      title: Text(n),
      leading: CircleAvatar(child: Text(s, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.bold))),
      trailing: Radio<String>(value: id, groupValue: _w,
        onChanged: (v) => setState(() => _w = v)),
      onTap: () => setState(() => _w = id)))];
}
