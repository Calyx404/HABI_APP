import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/backend/logout_flow.dart';
import 'package:habi/features/auth/login_screen.dart';

void main() {
  testWidgets('logout clears the route stack and returns to login', (
    tester,
  ) async {
    var signedOut = false;
    await tester.pumpWidget(
      MaterialApp(home: _LogoutPage(signOut: () async => signedOut = true)),
    );

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(signedOut, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Protected employer screen'), findsNothing);
  });

  testWidgets('failed sign out keeps the current page and explains the error', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: _LogoutPage(signOut: () async => throw StateError('offline')),
      ),
    );

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Protected employer screen'), findsOneWidget);
    expect(find.text('Could not log out. Please try again.'), findsOneWidget);
  });
}

class _LogoutPage extends StatelessWidget {
  const _LogoutPage({required this.signOut});

  final Future<void> Function() signOut;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Protected employer screen'),
          TextButton(
            onPressed: () => logoutAndReturnToLogin(context, signOut: signOut),
            child: const Text('Log Out'),
          ),
        ],
      ),
    ),
  );
}
