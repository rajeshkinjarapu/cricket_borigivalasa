import 'package:flutter/material.dart';
import '../../../players/data/models/player.dart';

Future<dynamic> showOverEndSheet(
  BuildContext context, {
  required int completedOver,
  required List<dynamic> bowlingTeamPlayers,
  required String? excludeBowlerId,
}) {
  return showModalBottomSheet<dynamic>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _OverEndSheetContent(
      over: completedOver,
      players: bowlingTeamPlayers,
      exclude: excludeBowlerId,
    ),
  );
}

class _OverEndSheetContent extends StatefulWidget {
  const _OverEndSheetContent({
    required this.over,
    required this.players,
    required this.exclude,
  });

  final int over;
  final List<dynamic> players;
  final String? exclude;

  @override
  State<_OverEndSheetContent> createState() => _OverEndSheetContentState();
}

class _OverEndSheetContentState extends State<_OverEndSheetContent> {
  dynamic _selectedPlayer;

  @override
  void initState() {
    super.initState();
    // Default to first available bowler if any
    final available = widget.players.where((p) => p.id != widget.exclude).toList();
    if (available.isNotEmpty) {
      _selectedPlayer = available.first;
    } else if (widget.players.isNotEmpty) {
      _selectedPlayer = widget.players.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = widget.players.where((p) => p.id != widget.exclude).toList();
    final listToShow = available.isNotEmpty ? available : widget.players;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sports_baseball_rounded, color: Color(0xFF1E3A8A), size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Over ${widget.over} Complete',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const Text(
                        'Select next bowler to continue',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),

          // Bowlers List
          if (listToShow.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'No bowling team players found. Please add squad members.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.40,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: listToShow.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final p = listToShow[idx];
                  final isSelected = _selectedPlayer != null && _selectedPlayer.id == p.id;
                  final wasPrevious = p.id == widget.exclude;

                  return InkWell(
                    onTap: () => setState(() => _selectedPlayer = p),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isSelected
                                ? const Color(0xFF1E3A8A)
                                : const Color(0xFFE2E8F0),
                            child: Icon(
                              Icons.person_rounded,
                              size: 20,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name as String,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (wasPrevious)
                                  const Text(
                                    'Bowled previous over',
                                    style: TextStyle(fontSize: 11, color: Color(0xFFEA580C), fontWeight: FontWeight.w600),
                                  ),
                              ],
                            ),
                          ),
                          Radio<dynamic>(
                            value: p,
                            groupValue: _selectedPlayer,
                            activeColor: const Color(0xFF1E3A8A),
                            onChanged: (val) => setState(() => _selectedPlayer = val),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 18),

          // Confirm Button
          ElevatedButton.icon(
            onPressed: _selectedPlayer == null
                ? null
                : () => Navigator.pop(context, _selectedPlayer),
            icon: const Icon(Icons.check_circle_rounded, size: 20),
            label: const Text(
              'Confirm Bowler & Continue',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }
}

