BEGIN TRANSACTION;
-- Проверяю существование эпизода в той же транзакции, что и оплату
IF $item_type = 'episode' AND !record::exists(type::record('episode', $episode_id)) { THROW 'SHOP_UNKNOWN_SKU'; };
LET $player = type::record($player_id);
LET $wallets = SELECT * FROM player_currency WHERE player_id = $player;
IF array::len($wallets) > 1 { THROW 'SHOP_DUPLICATE_WALLET'; };
LET $wallet = $wallets[0];
LET $balance = $wallet.diamonds ?? 0;
-- Не считаю сумму, пока исходный баланс не проверен
IF !type::is_int($balance) OR $balance < 0 OR $balance > 2147483647 { THROW 'SHOP_INVALID_BALANCE'; };
LET $key = type::record('purchase', [$player, $item_type, IF $item_type = 'currency' { $request_id } ELSE { $item_id }]);
LET $previous = SELECT * FROM ONLY $key;
IF $previous != NONE AND ($previous.item_id != $item_id OR $previous.item_type != $item_type) { THROW 'SHOP_REQUEST_REUSED'; };
LET $owned = SELECT * FROM purchase WHERE player_id = $player AND item_id = $item_id AND item_type = $item_type LIMIT 1;
LET $already = $previous != NONE OR ($item_type != 'currency' AND array::len($owned) > 0);
LET $enough = $balance >= $price;
LET $out = IF $already {
    { success: true, message: 'Уже куплено', diamonds: $balance }
} ELSE IF !$enough {
    { success: false, message: 'Не хватает алмазов', diamonds: $balance }
} ELSE {
    LET $wallet_key = $wallet.id ?? type::record('player_currency', [$player]);
    LET $new_balance = $balance - $price + $amount;
    IF $new_balance < 0 OR $new_balance > 2147483647 { THROW 'SHOP_BALANCE_OVERFLOW'; };
    LET $updated = UPSERT $wallet_key SET player_id = $player, diamonds = $new_balance, updated_at = time::now()
        WHERE (diamonds ?? 0) = $balance RETURN AFTER;
    IF array::len($updated) != 1 { THROW 'SHOP_BALANCE_CONFLICT'; };
    CREATE $key CONTENT { player_id: $player, item_id: $item_id, item_type: $item_type, purchased_at: time::now() };
    RETURN { success: true, message: 'Покупка успешна', diamonds: $new_balance };
};
RETURN $out;
COMMIT TRANSACTION;