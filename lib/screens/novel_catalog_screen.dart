import '../widgets/story_header.dart'; // Импорт общей шапки и тонкого заголовка
import '../widgets/button_sound.dart'; // Импорт щелчка новых кнопок

import 'package:flutter/material.dart'; // Импорт карточек каталога

import '../generated/auth_api.pb.dart'; // Импорт роли игрока
import '../generated/novel_api.pb.dart'; // Импорт новеллы
import '../services/active_novel.dart'; // Импорт выбора истории
import '../services/storage_service.dart'; // Импорт текущего игрока
import '../src/data/services/auth_grpc_service.dart'; // Импорт проверки роли
import '../src/data/services/novel_grpc_service.dart'; // Импорт каталога с сервера
import '../widgets/novel_background.dart'; // Импорт обложек
import 'main_menu_screen.dart'; // Импорт меню выбранной истории
import 'novel_editor_screen.dart'; // Импорт редактора новеллы

class NovelCatalogScreen extends StatefulWidget {
  const NovelCatalogScreen({super.key});
  @override
  State<NovelCatalogScreen> createState() => _NovelCatalogScreenState();
}

class _NovelCatalogScreenState extends State<NovelCatalogScreen> {
  final _service = NovelGrpcService();
  List<Novel> _novels = [];
  bool _admin = false, _loading = true, _opening = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = AuthGrpcService();
    try {
      final id = await StorageService.loadPlayerId();
      final result = await Future.wait<Object>([
        _service.listNovels(),
        auth.getPlayer(id),
      ]);
      if (!mounted) return;
      // Роль проверяет сервер, кнопка только показывает доступный редактор.
      final player = result[1] as AuthResponse;
      setState(() {
        _novels = result[0] as List<Novel>;
        _admin = player.isAdmin;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Не удалось загрузить новеллы';
        });
      }
    } finally {
      await auth.close();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _open(Novel novel) async {
    if (_opening) return;
    setState(() {
      _opening = true;
    });
    try {
      await ActiveNovel.shared.select(novel);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MainMenu()),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть новеллу')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _opening = false;
        });
      }
    }
  }

  Future<void> _edit(Novel? novel) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NovelEditorScreen(novel: novel)),
    );
    if (mounted) await _load();
  }

  @override
  void dispose() {
    _service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF1A1A1A),
    appBar: StoryHeader(
      title: 'Новеллы',
      actions: [
        if (_admin)
          IconButton(
            onPressed: withButtonSound(_opening ? null : () => _edit(null)),
            icon: const Icon(Icons.add),
          ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFFA0A0),
              ),
              onPressed: withButtonSound(_load),
              child: Text('$_error. Повторить'),
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _novels.length,
            separatorBuilder: (_, index) => const SizedBox(height: 16),
            itemBuilder: (_, index) {
              final item = _novels[index];
              // Обложка занимает весь баннер, название кладу поверх картинки.
              return AspectRatio(
                aspectRatio: 16 / 7,
                child: Card(
                  margin: EdgeInsets.zero,
                  color: const Color(0xFF3F0404),
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: withButtonSound(_opening ? null : () => _open(item)),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        NovelImage(id: item.coverId, fit: BoxFit.cover),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Color(0xCC000000)],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 18,
                          child: Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFFFA0A0),
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
  );
}