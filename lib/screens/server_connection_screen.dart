import 'package:flutter/material.dart'; // Импорт экрана подключения
import '../services/server_connection.dart'; // Импорт общего адреса сервера
import '../services/session_store.dart'; // Импорт очистки сессии прежнего сервера

// Настраиваю подключение без пересборки приложения.
class ServerConnectionScreen extends StatefulWidget {
  const ServerConnectionScreen({super.key});

  @override
  State<ServerConnectionScreen> createState() => _ServerConnectionScreenState();
}

class _ServerConnectionScreenState extends State<ServerConnectionScreen> {
  final _host = TextEditingController(text: ServerConnection.host);
  final _port = TextEditingController(text: '${ServerConnection.port}');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _host.dispose();
    _port.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final port = int.tryParse(_port.text.trim());
    if (!ServerConnection.valid(_host.text, port)) {
      setState(() => _error = 'Укажи IP или имя компьютера без http:// и порт от 1 до 65535');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      // Убираю прежний токен до переключения, чтобы не отправить его другому серверу.
      await SessionStore.shared.clear();
      await ServerConnection.save(_host.text, port!);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Не удалось сохранить подключение'; });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Подключение к серверу')),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        TextField(controller: _host, enabled: !_saving, autocorrect: false,
          decoration: const InputDecoration(labelText: 'IP или имя компьютера', hintText: '127.0.0.1')),
        TextField(controller: _port, enabled: !_saving, keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Порт')),
        const SizedBox(height: 16),
        Wrap(spacing: 8, children: [
          TextButton(onPressed: _saving ? null : () => _host.text = '127.0.0.1', child: const Text('Телефон по USB')),
          TextButton(onPressed: _saving ? null : () => _host.text = '10.0.2.2', child: const Text('Эмулятор')),
        ]),
        const Text('Для USB на компьютере выполни: adb reverse tcp:50051 tcp:50051. '
          'Для Wi-Fi укажи IP компьютера в общей локальной сети. '
          'Меняй адрес только на доверенный сервер: подключение в учебном приложении без шифрования.'),
        if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Сохраняю…' : 'Сохранить и войти заново')),
      ]),
    ),
  );
}