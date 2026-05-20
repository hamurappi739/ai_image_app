import 'package:ai_image_generator/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows generate screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AiImageGeneratorApp());

    expect(find.text('AI Image Generator'), findsOneWidget);
    expect(find.text('Create images from your ideas'), findsOneWidget);
    expect(find.text('Generation status'), findsOneWidget);
    expect(find.text('Ready to create'), findsOneWidget);
    expect(find.text('Describe your image...'), findsOneWidget);
    expect(find.text('Generate image'), findsOneWidget);
    expect(find.text('Try an idea'), findsOneWidget);
    expect(find.text('Cyberpunk cat'), findsOneWidget);
  });
}
