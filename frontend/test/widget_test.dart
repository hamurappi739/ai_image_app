import 'package:ai_image_generator/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AiImageGeneratorApp());

    expect(find.text('AI Image Generator'), findsOneWidget);
    expect(find.text('Backend connection will be added next'), findsOneWidget);
  });
}
