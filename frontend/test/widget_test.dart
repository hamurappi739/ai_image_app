import 'package:ai_image_generator/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const AiImageGeneratorApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
