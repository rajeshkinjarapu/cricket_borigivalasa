import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cricket_scoring_app/main.dart';
import 'package:cricket_scoring_app/features/auth/presentation/providers/auth_providers.dart';

class FakeAuthController extends StateNotifier<AsyncValue<void>> implements AuthController {
  FakeAuthController() : super(const AsyncValue.data(null));

  @override
  Future<bool> signIn({required String email, required String password}) async => true;

  @override
  Future<bool> signUp({required String email, required String password, required String displayName}) async => true;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> updateProfile({
    String? displayName,
    Uint8List? imageBytes,
    String? fileExtension,
  }) async => true;
}

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(null)),
          authControllerProvider.overrideWith((ref) => FakeAuthController()),
        ],
        child: const CricketApp(),
      ),
    );
    await tester.pump();
    expect(find.byType(CricketApp), findsOneWidget);
  });
}
