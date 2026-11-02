import 'dart:async'; // Импорт времени показа реакции
import 'package:flutter/material.dart'; // Импорт бордовой плашки

// Показываю одно сообщение поверх игры, не перехватывая касания кнопок.
class ConsequenceNotice {
  OverlayEntry? _entry;
  Timer? _timer;

  void hide() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  void show(BuildContext context, String message) {
    hide();
    final text = message.trim();
    if (text.isEmpty) return;
    _entry = OverlayEntry(builder: (context) => Positioned(
      top: MediaQuery.paddingOf(context).top + 80,
      left: 20, right: 20,
      child: IgnorePointer(child: Material(
        color: Colors.transparent,
        child: Semantics(liveRegion: true, child: Container(
          key: const ValueKey('consequence-notice'),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(color: const Color(0xFF3F0404),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFFFA0A0))),
          child: Text(text, maxLines: 4, overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFFFA0A0), fontSize: 16, height: 1.3)),
        )),
      )),
    ));
    Overlay.of(context).insert(_entry!);
    _timer = Timer(const Duration(seconds: 4), hide);
  }
}