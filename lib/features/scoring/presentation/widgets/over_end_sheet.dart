import 'package:flutter/material.dart';

Future<dynamic> showOverEndSheet(BuildContext context,
    {required int completedOver, required List<dynamic> bowlingTeamPlayers,
    required String? excludeBowlerId}) {
  return showModalBottomSheet<dynamic>(context: context,
    isScrollControlled: true, showDragHandle: true,
    isDismissible: false, enableDrag: false,
    builder: (_) => _O(over: completedOver, players: bowlingTeamPlayers,
      exclude: excludeBowlerId));
}

class _O extends StatefulWidget {
  const _O({required this.over, required this.players, required this.exclude});
  final int over;
  final List<dynamic> players;
  final String? exclude;
  @override
  State<_O> createState() => _OS();
}
class _OS extends State<_O> {
  String? _id;
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 8,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Over ${widget.over} complete',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(value: _id, isExpanded: true,
          decoration: const InputDecoration(labelText: 'Next bowler'),
          items: widget.players.where((p) => p.id != widget.exclude)
            .map((p) => DropdownMenuItem<String>(
              value: p.id as String, child: Text(p.name as String))).toList(),
          onChanged: (v) => setState(() => _id = v)),
        const SizedBox(height: 24),
        FilledButton(onPressed: _id == null ? null : () {
          dynamic b; for (final p in widget.players) if (p.id == _id) b = p;
          Navigator.pop(context, b);
        }, child: const Text('Continue')),
      ]));
  }
}
