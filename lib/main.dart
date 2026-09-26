import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/widgets/global_notification_listener.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://qlphckdozxtqhwnpokec.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFscGhja2Rvenh0cWh3bnBva2VjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk5MDcwNTQsImV4cCI6MjEwNTQ4MzA1NH0.J4I7nbtYXPTzM0FO2eA_7k32g9j-TU1gk3LPBnGsp1c',
  );
  runApp(const ProviderScope(child: CricketApp()));
}

class CricketApp extends ConsumerWidget {
  const CricketApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Cricket BV',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        return GlobalNotificationListener(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
