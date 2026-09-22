import 'package:flutter/material.dart';
import '../models/episode.dart';
import '../models/scene.dart';

class SceneEditorScreen extends StatefulWidget {
  final Episode episode;
  final Scene scene;

  const SceneEditorScreen({
    super.key,
    required this.episode,
    required this.scene,
  });

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  late TextEditingController _idController;
  late TextEditingController _backgroundController;
  late TextEditingController _characterController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.scene.id.toString());
    _backgroundController = TextEditingController(text: widget.scene.background);
    _characterController = TextEditingController(text: widget.scene.character);
    _textController = TextEditingController(
      text: widget.scene.texts.join('\n'),
    );
  }

  @override
  void dispose() {
    _idController.dispose();
    _backgroundController.dispose();
    _characterController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _saveScene() {
    final newScene = Scene(
      id: int.parse(_idController.text),
      background: _backgroundController.text,
      character: _characterController.text,
      texts: _textController.text.split('\n'),
      choices: widget.scene.choices,
      condition: widget.scene.condition,
    );

    final index = widget.episode.scenes.indexOf(widget.scene);

    setState(() {
      widget.episode.scenes[index] = newScene;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Сцена сохранена')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Сцена ${widget.scene.id}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _backgroundController,
              decoration: const InputDecoration(
                labelText: 'Фон',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _characterController,
              decoration: const InputDecoration(
                labelText: 'Персонаж',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Текст',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveScene,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}