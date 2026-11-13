import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habi/shared/widgets/form_widgets.dart';

void main() {
  testWidgets(
    'dropdown ignores stale saved value and removes duplicate options',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              child: habiDropdown(
                label: 'Organization type',
                value: 'Legacy organization type',
                items: const ['Corporation', 'Corporation', 'Non-profit'],
                onChanged: (value) => selected = value,
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Corporation'), findsOneWidget);
      await tester.tap(find.text('Non-profit').last);
      await tester.pumpAndSettle();
      expect(selected, 'Non-profit');
    },
  );
}
