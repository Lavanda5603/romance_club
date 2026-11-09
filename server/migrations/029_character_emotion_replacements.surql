-- Заменяю пять отсутствующих эмоций похожими картинками тех же персонажей.
UPDATE scene SET character_emotion = 'worried' WHERE character = 'alya' AND character_emotion = 'sad';
UPDATE scene SET character_emotion = 'sly' WHERE character = 'ladybug' AND character_emotion = 'mysterious';
-- Сохраняю написание shoked из существующего каталога картинок.
UPDATE scene SET character_emotion = 'shoked' WHERE character = 'marinet' AND character_emotion = 'surprised';
UPDATE scene SET character_emotion = 'sleeping' WHERE character = 'marinet' AND character_emotion = 'tired';
UPDATE scene SET character_emotion = 'focused' WHERE character = 'renarouge' AND character_emotion = 'normal';