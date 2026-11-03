import 'package:flutter/material.dart'; // Импорт оформления верхней панели

import 'button_sound.dart'; // Импорт звука стрелки назад

// Показываю название экрана под общей шапкой приложения.
class StoryHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color color;
  final List<Widget> actions;
  const StoryHeader({
    super.key,
    required this.title,
    this.color = const Color(0xFFFFA0A0),
    this.actions = const [],
  });
  @override
  Size get preferredSize => const Size.fromHeight(112);
  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: Column(
      children: [
        SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Center(
                child: Text(
                  'Клуб романтики',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
              if (Navigator.canPop(context))
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFFD30010),
                      size: 28,
                    ),
                    onPressed: withButtonSound(
                      () => Navigator.maybePop(context),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: actions),
              ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}