import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/screens/auth_gate.dart';

void main() {
  testWidgets('authentication screen exposes sign in and farm registration', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AuthScreen()));
    expect(find.text('Welcome to ChickFarm'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('New farm? Create an account'));
    await tester.pump();

    expect(find.text('Create your ChickFarm'), findsOneWidget);
    expect(find.text('Farm name'), findsOneWidget);
  });
}
