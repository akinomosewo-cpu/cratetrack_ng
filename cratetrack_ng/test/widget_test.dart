import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cratetrack_ng/core/models/crate.dart';
import 'package:cratetrack_ng/presentation/widgets/status_chip.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  testWidgets('StatusChip shows the label for the given custody status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: CustodyStatus.inTransit)),
      ),
    );

    expect(find.text('In Transit'), findsOneWidget);
  });

  testWidgets('StatusChip reflects a different status', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusChip(status: CustodyStatus.damaged)),
      ),
    );

    expect(find.text('Damaged'), findsOneWidget);
  });
}
