import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Per-frame photoshoot progress for UI display.
class PhotoshootFrameProgress {
  const PhotoshootFrameProgress({
    required this.index,
    required this.status,
  });

  final int index;
  final String status;

  String get label {
    final photoNumber = index + 1;
    switch (status) {
      case 'done':
        return 'Фото $photoNumber — готово';
      case 'generating':
        return 'Фото $photoNumber — создаём';
      case 'error':
        return 'Фото $photoNumber — ошибка';
      case 'queued':
      default:
        return 'Фото $photoNumber — в очереди';
    }
  }
}

/// Блокирующее окно ожидания с обратным отсчётом во время генерации.
class GenerationProgressDialog extends StatefulWidget {
  const GenerationProgressDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.totalSeconds,
    required this.task,
    this.frameProgressListenable,
  });

  final String title;
  final String subtitle;
  final int totalSeconds;
  final Future<dynamic> Function() task;
  final ValueListenable<List<PhotoshootFrameProgress>>? frameProgressListenable;

  /// Показывает modal, выполняет [task], возвращает результат или пробрасывает ошибку.
  static Future<T> run<T>({
    required BuildContext context,
    required String title,
    required String subtitle,
    required int totalSeconds,
    required Future<T> Function() task,
    ValueListenable<List<PhotoshootFrameProgress>>? frameProgressListenable,
  }) async {
    final result = await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (dialogContext) => GenerationProgressDialog(
        title: title,
        subtitle: subtitle,
        totalSeconds: totalSeconds,
        frameProgressListenable: frameProgressListenable,
        task: () async => task(),
      ),
    );

    if (result is Exception) {
      throw result;
    }
    return result as T;
  }

  @override
  State<GenerationProgressDialog> createState() =>
      _GenerationProgressDialogState();
}

class _GenerationProgressDialogState extends State<GenerationProgressDialog> {
  static const _accentColor = Color(0xFF5B6CFF);

  Timer? _timer;
  late int _secondsLeft;
  bool _taskFinished = false;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _taskFinished) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        }
      });
    });
    unawaited(_runTask());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _runTask() async {
    try {
      final result = await widget.task();
      _taskFinished = true;
      _timer?.cancel();
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (error) {
      _taskFinished = true;
      _timer?.cancel();
      if (!mounted) return;
      final exception = error is Exception
          ? error
          : Exception(error.toString());
      Navigator.of(context).pop(exception);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countdownText = _secondsLeft > 0
        ? 'Осталось примерно: $_secondsLeft сек.'
        : 'Почти готово, ждём результат...';

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
                    height: 1.4,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                if (widget.frameProgressListenable != null) ...[
                  const SizedBox(height: 18),
                  ValueListenableBuilder<List<PhotoshootFrameProgress>>(
                    valueListenable: widget.frameProgressListenable!,
                    builder: (context, frames, _) {
                      if (frames.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          for (final frame in frames)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  frame.label,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 15,
                                    fontWeight: frame.status == 'generating'
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: frame.status == 'done'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF374151),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
                const SizedBox(height: 16),
                if (widget.frameProgressListenable == null)
                  Text(
                    countdownText,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _accentColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
