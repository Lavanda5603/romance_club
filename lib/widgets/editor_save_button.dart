import 'package:flutter/material.dart'; // Импорт кнопки сохранения

import 'button_sound.dart'; // Импорт звука кнопки

// Сохраняю одинаковое оформление кнопок редактора.
class EditorSaveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  const EditorSaveButton({
    super.key,
    required this.onPressed,
    this.label = 'сохранить',
  });
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: SizedBox(
      width: 200,
      height: 55,
      child: ElevatedButton(
        onPressed: withButtonSound(onPressed),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD30010),
          foregroundColor: const Color(0xFF3F0404),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    ),
  );
}