import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sociohub/main.dart';

void main() {
  testWidgets('App renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SocioHubApp());
    expect(find.text('INVESTMENTS'), findsOneWidget);
    expect(find.text('CREATE'), findsOneWidget);
    expect(find.text('INSIGHTS'), findsOneWidget);
    expect(find.text('PROFILE'), findsOneWidget);
  });
}
