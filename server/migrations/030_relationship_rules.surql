-- Храню общие подписи и пороги карточек, не меняя баллы и сюжетные условия.
DEFINE TABLE IF NOT EXISTS relationship_rules SCHEMAFULL PERMISSIONS NONE;
DEFINE FIELD IF NOT EXISTS json ON relationship_rules TYPE string;
DEFINE FIELD IF NOT EXISTS revision ON relationship_rules TYPE int;