import 'package:flutter_test/flutter_test.dart';
import 'package:romance_club/src/core/validators.dart';

void main() {
  test('Принимаю заполненные данные регистрации', () {
    expect(Validators.validateLogin('Player_123'), isNull);
    expect(Validators.validateEmail('player@example.com'), isNull);
    expect(Validators.validatePassword('Player123!'), isNull);
  });

  test('Не принимаю пустой, короткий логин и пробелы', () {
    for (final login in ['', 'ab', 'player name']) {
      expect(Validators.validateLogin(login), isNotNull);
    }
  });

  test('Не принимаю адрес без имени или домена', () {
    for (final email in ['', '@mail.ru', 'player@', 'player.example.com']) {
      expect(Validators.validateEmail(email), isNotNull);
    }
  });

  test('В пароле нужны буквы, цифры и спецсимвол', () {
    for (final password in ['', 'Ab1!', '12345!', 'Player!', 'Player123']) {
      expect(Validators.validatePassword(password), isNotNull);
    }
  });
}