import 'package:ai_image_generator/utils/photoshoot_frame_progress_display.dart';
import 'package:ai_image_generator/widgets/generation_progress_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

List<PhotoshootFrameProgress> _frames(List<String> statuses) {
  return [
    for (var i = 0; i < statuses.length; i++)
      PhotoshootFrameProgress(index: i, status: statuses[i]),
  ];
}

void main() {
  test('frame 0 shows actual status', () {
    final display = displayPhotoshootFrameProgress(
      _frames(['generating', 'queued', 'queued']),
    );
    expect(display[0].status, 'generating');
  });

  test('frame 3 done before frame 2 stays generating', () {
    final display = displayPhotoshootFrameProgress(
      _frames(['done', 'generating', 'done']),
    );
    expect(display.map((f) => f.status).toList(), [
      'done',
      'generating',
      'generating',
    ]);
    expect(display[2].label, 'Фото 3 — создаём');
  });

  test('all frames done shows all ready', () {
    final display = displayPhotoshootFrameProgress(
      _frames(['done', 'done', 'done']),
    );
    expect(display.every((f) => f.status == 'done'), isTrue);
    expect(display[1].label, 'Фото 2 — готово');
    expect(display[2].label, 'Фото 3 — готово');
  });

  test('frame 2 reveals done only after frame 1 is done', () {
    final step1 = displayPhotoshootFrameProgress(
      _frames(['done', 'done', 'generating']),
    );
    expect(step1[2].status, 'generating');

    final step2 = displayPhotoshootFrameProgress(
      _frames(['done', 'done', 'done']),
    );
    expect(step2[2].status, 'done');
    expect(step2[2].label, 'Фото 3 — готово');
  });

  test('errors are not masked', () {
    final display = displayPhotoshootFrameProgress(
      _frames(['done', 'error', 'generating']),
    );
    expect(display[1].status, 'error');
    expect(display[1].label, 'Фото 2 — ошибка');
  });
}
