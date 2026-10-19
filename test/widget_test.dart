import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modelbank/main.dart';
import 'package:modelbank/src/screens/model_bank_gateway_screen.dart';

void main() {
  testWidgets('ModelBankGatewayApp renders successfully with splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ModelBankGatewayApp());
    expect(find.text('Model Bank Gateway'), findsOneWidget);
    expect(
      find.text('Open Finance AE • OAuth Authorization Gateway'),
      findsOneWidget,
    );
  });

  testWidgets('ModelBankGatewayScreen renders header and control sections',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ModelBankGatewayScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('MODEL BANK'), findsOneWidget);
    expect(find.text('Open Finance AE Gateway'), findsOneWidget);
  });
}
