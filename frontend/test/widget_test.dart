import 'package:ai_image_generator/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows generate screen', (WidgetTester tester) async {
    await tester.pumpWidget(const AiImageGeneratorApp());

    expect(find.text('AI Фотогенератор'), findsOneWidget);
    expect(
      find.text('Создавайте изображения по вашему описанию'),
      findsOneWidget,
    );
    expect(find.text('Статус генераций'), findsOneWidget);
    expect(find.text('Готово к созданию'), findsOneWidget);
    expect(find.text('Например: портрет в деловом стиле'), findsOneWidget);
    expect(find.text('Создать изображение'), findsOneWidget);
    expect(find.text('Попробуйте идею'), findsOneWidget);
    expect(find.text('Создать'), findsOneWidget);
  });
}
