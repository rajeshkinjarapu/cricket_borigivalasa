import 'package:cricket_scoring_app/core/widgets/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders with action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: EmptyState(
      icon: Icons.emoji_events, title: 'Empty',
      actionLabel: 'Add', onAction: () => tapped = true))));
    expect(find.text('Empty'), findsOneWidget);
    await tester.tap(find.text('Add'));
    expect(tapped, true);
  });
  testWidgets('hides action when null', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(
      body: EmptyState(icon: Icons.info, title: 'Empty'))));
    expect(find.byType(FilledButton), findsNothing);
  });
}
