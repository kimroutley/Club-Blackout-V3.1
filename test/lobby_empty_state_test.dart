import 'package:club_blackout/data/role_repository.dart';
import 'package:club_blackout/logic/game_engine.dart';
import 'package:club_blackout/ui/screens/lobby_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Lobby: Empty state shows action buttons', (tester) async {
    // Set a reasonable screen size to avoid overflow
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final engine = GameEngine(roleRepository: RoleRepository());
    // No players initially

    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(gameEngine: engine),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No Guests Yet'), findsOneWidget);

    // Buttons exist in both empty state and bottom bar
    expect(find.text('Paste List'), findsAtLeastNWidgets(2));
    expect(find.text('From History'), findsAtLeastNWidgets(2));
  });
}
