// Связываю сохранённое название концовки с картинкой её пары.
const endingArtwork = <String, String>{
  'МариАдриан': 'assets/images/endings/ending_marinette_adrian.png',
  'МариКот': 'assets/images/endings/ending_marinette_cat.png',
  'АдриБаг': 'assets/images/endings/ending_ladybug_adrian.png',
  'СуперБаг': 'assets/images/endings/ending_ladybug_cat.png',
  'Лука': 'assets/images/endings/ending_marinette_luka.png',
};

// Для старых ссылок сцены использую ту же точную картинку пары, что и в финале.
String? endingSceneArtwork(String background) {
  const endings = <String, String>{
    'ep1/kiss_marinet_adrian': 'МариАдриан',
    'ep1/kiss_marinet_catnoir': 'МариКот',
    'ep1/kiss_ladybug_adrian': 'АдриБаг',
    'ep1/kiss_ladybug_catnoir': 'СуперБаг',
    'ep1/kiss_marinet_luka': 'Лука',
  };
  return endingArtwork[endings[background]];
}