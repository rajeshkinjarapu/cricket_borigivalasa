import 'package:flutter/material.dart';
import '../../../../core/constants/cricket_enums.dart';

class WicketResult {
  final WicketType type;
  final String dismissedPlayerId, dismissedPlayerName;
  final String? fielderId, fielderName;
  final String newBatsmanId, newBatsmanName;
  const WicketResult({required this.type, required this.dismissedPlayerId,
    required this.dismissedPlayerName, required this.newBatsmanId,
    required this.newBatsmanName, this.fielderId, this.fielderName});
}

Future<WicketResult?> showWicketSheet(BuildContext context, {
    required String strikerId, required String strikerName,
    required String nonStrikerId, required String nonStrikerName,
    required List<dynamic> bowlingTeamPlayers,
    required List<dynamic> availableBatsmen}) {
  return showModalBottomSheet<WicketResult>(context: context,
    isScrollControlled: true, showDragHandle: true,
    builder: (_) => _W(strikerId: strikerId, strikerName: strikerName,
      nonStrikerId: nonStrikerId, nonStrikerName: nonStrikerName,
      bowling: bowlingTeamPlayers, batsmen: availableBatsmen));
}

class _W extends StatefulWidget {
  const _W({required this.strikerId, required this.strikerName,
    required this.nonStrikerId, required this.nonStrikerName,
    required this.bowling, required this.batsmen});
  final String strikerId, strikerName, nonStrikerId, nonStrikerName;
  final List<dynamic> bowling, batsmen;
  @override
  State<_W> createState() => _WS();
}
class _WS extends State<_W> {
  late String _outId;
  WicketType _type = WicketType.bowled;
  String? _fielderId, _newId;
  @override
  void initState() { super.initState(); _outId = widget.strikerId; }
  void _ok() {
    if (_newId == null) return;
    final name = _outId == widget.strikerId
      ? widget.strikerName : widget.nonStrikerName;
    dynamic nb; for (final p in widget.batsmen) if (p.id == _newId) nb = p;
    dynamic f; if (_fielderId != null) for (final p in widget.bowling)
      if (p.id == _fielderId) f = p;
    Navigator.pop(context, WicketResult(type: _type,
      dismissedPlayerId: _outId, dismissedPlayerName: name,
      fielderId: f?.id as String?, fielderName: f?.name as String?,
      newBatsmanId: nb.id as String, newBatsmanName: nb.name as String));
  }
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 8,
      bottom: MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Wicket', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const Text('Who is out?'),
        const SizedBox(height: 8),
        RadioListTile<String>(value: widget.strikerId, groupValue: _outId,
          title: Text('${widget.strikerName} (striker)'),
          onChanged: (v) => setState(() => _outId = v!)),
        RadioListTile<String>(value: widget.nonStrikerId,
          groupValue: _outId,
          title: Text('${widget.nonStrikerName} (non-striker)'),
          onChanged: (v) => setState(() => _outId = v!)),
        const SizedBox(height: 12),
        const Text('How out?'),
        const SizedBox(height: 8),
        DropdownButtonFormField<WicketType>(value: _type, isExpanded: true,
          items: WicketType.values.map((t) => DropdownMenuItem(
            value: t, child: Text(t.label))).toList(),
          onChanged: (v) { if (v != null) setState(() {
            _type = v; if (!v.needsFielder) _fielderId = null; }); }),
        if (_type.needsFielder) ...[const SizedBox(height: 12),
          DropdownButtonFormField<String>(value: _fielderId, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Fielder'),
            items: widget.bowling.map((p) => DropdownMenuItem<String>(
              value: p.id as String, child: Text(p.name as String))).toList(),
            onChanged: (v) => setState(() => _fielderId = v))],
        const SizedBox(height: 12),
        const Text('Next batsman'),
        const SizedBox(height: 8),
        if (widget.batsmen.isEmpty)
          Container(padding: const EdgeInsets.all(12),
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Text('No batsmen left'))
        else DropdownButtonFormField<String>(value: _newId, isExpanded: true,
          items: widget.batsmen.map((p) => DropdownMenuItem<String>(
            value: p.id as String, child: Text(p.name as String))).toList(),
          onChanged: (v) => setState(() => _newId = v)),
        const SizedBox(height: 20),
        FilledButton(onPressed: _ok, child: const Text('Confirm wicket')),
      ])));
  }
}
