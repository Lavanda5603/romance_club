// Разбираю условия без выполнения произвольного кода
class SceneCondition {
  final bool Function(Map<String, int>, Map<String, bool>) _evaluate;
  SceneCondition._(this._evaluate);

  factory SceneCondition.parse(String source) {
    if (source.length > 2048) throw const FormatException('Условие длиннее 2048 символов');
    final parser = _ConditionParser(source);
    if (parser.tokens.isEmpty) return SceneCondition._((_, _) => true);
    final expression = parser.expression();
    if (parser.position != parser.tokens.length) parser.fail('Лишний текст');
    return SceneCondition._(expression);
  }

  bool evaluate(Map<String, int> counters, Map<String, bool> flags) => _evaluate(counters, flags);

  static String? error(String source) {
    try { SceneCondition.parse(source); return null; }
    on FormatException catch (error) { return error.message; }
  }
}

typedef _Expression = bool Function(Map<String, int>, Map<String, bool>);
typedef _Number = int Function(Map<String, int>);

class _ConditionParser {
  final List<String> tokens = [];
  int position = 0;
  int depth = 0;
  _ConditionParser(String source) {
    final token = RegExp(r'\s+|>=|<=|==|!=|&&|\|\||[()=<>:]|-?\d+|[A-Za-zА-Яа-яЁё_][A-Za-zА-Яа-яЁё_0-9]*');
    var offset = 0;
    while (offset < source.length) {
      final match = token.matchAsPrefix(source, offset);
      if (match == null) throw FormatException('Недопустимый символ в позиции ${offset + 1}');
      final text = match.group(0)!;
      if (text.trim().isNotEmpty) tokens.add(text);
      offset = match.end;
    }
  }
  Never fail(String message) => throw FormatException('$message: ${position < tokens.length ? tokens[position] : 'конец условия'}');
  bool take(String value) {
    if (position < tokens.length && tokens[position].toUpperCase() == value) { position++; return true; }
    return false;
  }
  String next() { if (position >= tokens.length) fail('Ожидалось значение'); return tokens[position++]; }

  // И связывает сильнее, чем ИЛИ; скобки меняют порядок
  _Expression expression() {
    var result = conjunction();
    while (take('||') || take('OR') || take('ИЛИ')) {
      final left = result, right = conjunction();
      result = (c, f) => left(c, f) || right(c, f);
    }
    return result;
  }
  _Expression conjunction() {
    var result = comparison();
    while (take('&&') || take('AND') || take('И')) {
      final left = result, right = comparison();
      result = (c, f) => left(c, f) && right(c, f);
    }
    return result;
  }
  _Expression comparison() {
    if (take('(')) {
      if (++depth > 32) fail('Слишком много вложенных скобок');
      final result = expression();
      if (!take(')')) fail('Ожидалась закрывающая скобка');
      depth--;
      return result;
    }
    if (take('FLAG')) {
      if (!take(':')) fail('После flag нужно двоеточие');
      final name = next();
      if (!RegExp(r'^[A-Za-zА-Яа-яЁё_][A-Za-zА-Яа-яЁё_0-9]*$').hasMatch(name)) fail('Неверное имя флага');
      final op = next();
      if (!['=', '==', '!='].contains(op)) fail('Для флага нужны = или !=');
      final value = next().toLowerCase();
      if (value != 'true' && value != 'false') fail('Значение флага должно быть true или false');
      return (_, f) => op == '!=' ? (f[name] ?? false) != (value == 'true') : (f[name] ?? false) == (value == 'true');
    }
    final left = number(), op = next(), right = number();
    if (!['=', '==', '!=', '>=', '<=', '>', '<'].contains(op)) fail('Нужен оператор сравнения');
    return (c, _) => switch (op) {
      '=' || '==' => left(c) == right(c), '!=' => left(c) != right(c),
      '>=' => left(c) >= right(c), '<=' => left(c) <= right(c),
      '>' => left(c) > right(c), _ => left(c) < right(c),
    };
  }
  _Number number() {
    final value = next();
    final integer = int.tryParse(value);
    if (integer != null) return (_) => integer;
    if (!RegExp(r'^[A-Za-z_][A-Za-z_0-9]*$').hasMatch(value) ||
        ['AND', 'OR', 'TRUE', 'FALSE', 'FLAG'].contains(value.toUpperCase())) {
      fail('Нужны число или имя счётчика');
    }
    return (c) => c[value] ?? 0;
  }
}