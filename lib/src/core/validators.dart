// Класс для валидации полей
class Validators {
  // Проверка логина
  static String? validateLogin(String login) {
    // Проверяю, что логин не пустой
    if (login.isEmpty) {
      return 'Введите логин';
    }
    // Проверяю, что логин >= 3 символов
    if (login.length < 3) {
      return 'Логин должен быть не менее 3 символов';
    }
    // Проверяю, что логин только из английских букв и цифр
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(login)) {
      return 'Логин: только английские буквы, цифры и _';
    }
    return null; // Всё ок
  }

  // Проверка email
  static String? validateEmail(String email) {
    // Проверяю, что email не пустой
    if (email.isEmpty) {
      return 'Введите email';
    }
    // Проверяю, что email содержит @ и точку после @
    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      return 'Email: английские буквы, @ и . (пример: user@mail.ru)';
    }
    return null; // Всё ок
  }

  // Проверка пароля
  static String? validatePassword(String password) {
    // Проверяю, что пароль не пустой
    if (password.isEmpty) {
      return 'Введите пароль';
    }
    // Проверяю, что пароль >= 5 символов
    if (password.length < 5) {
      return 'Пароль должен быть не менее 5 символов';
    }
    // Проверяю, что пароль содержит английскую букву
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      return 'Пароль должен содержать английскую букву';
    }
    // Проверяю, что пароль содержит цифру
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Пароль должен содержать цифру';
    }
    // Проверяю, что пароль содержит спецсимвол
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/~`]').hasMatch(password)) {
      return 'Пароль должен содержать спецсимвол (!@#\$%^&* и т.п.)';
    }
    return null; // Всё ок
  }
}