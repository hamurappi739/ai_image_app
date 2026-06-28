import '../widgets/generation_progress_dialog.dart';

/// Hides out-of-order completion: frame [i] cannot show [done] until all
/// previous frames are [done] (e.g. frame 3 stays «создаём» while frame 2 runs).
List<PhotoshootFrameProgress> displayPhotoshootFrameProgress(
  List<PhotoshootFrameProgress> actual,
) {
  if (actual.isEmpty) return actual;

  final sorted = List<PhotoshootFrameProgress>.from(actual)
    ..sort((a, b) => a.index.compareTo(b.index));

  final statusByIndex = {for (final frame in sorted) frame.index: frame.status};

  return [
    for (final frame in sorted)
      PhotoshootFrameProgress(
        index: frame.index,
        status: _displayStatus(
          index: frame.index,
          actualStatus: frame.status,
          statusByIndex: statusByIndex,
        ),
      ),
  ];
}

String _displayStatus({
  required int index,
  required String actualStatus,
  required Map<int, String> statusByIndex,
}) {
  if (actualStatus == 'error') return 'error';

  for (var previous = 0; previous < index; previous++) {
    if (statusByIndex[previous] != 'done') {
      if (actualStatus == 'done') {
        return 'generating';
      }
      break;
    }
  }

  return actualStatus;
}
