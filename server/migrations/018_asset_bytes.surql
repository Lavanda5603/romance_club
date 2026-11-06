BEGIN TRANSACTION;
DEFINE FIELD OVERWRITE file_data ON asset TYPE option<string | bytes>;
DEFINE FIELD OVERWRITE preview_data ON asset TYPE option<string | bytes>;
FOR $row IN (SELECT id, file_data, preview_data FROM asset) {
    IF type::is_string($row.file_data) {
        LET $bytes = encoding::base64::decode($row.file_data);
        IF encoding::base64::encode($bytes) != string::replace($row.file_data, '=', '') { THROW 'ASSET_ORIGINAL_INVALID'; };
        UPDATE $row.id SET file_data = $bytes;
    };
    IF type::is_string($row.preview_data) {
        LET $bytes = encoding::base64::decode($row.preview_data);
        IF encoding::base64::encode($bytes) != string::replace($row.preview_data, '=', '') { THROW 'ASSET_PREVIEW_INVALID'; };
        UPDATE $row.id SET preview_data = $bytes;
    };
};
DEFINE FIELD OVERWRITE file_data ON asset TYPE option<bytes>;
DEFINE FIELD OVERWRITE preview_data ON asset TYPE option<bytes>;
COMMIT TRANSACTION;
