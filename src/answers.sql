-- Your answers here:
-- 1
SELECT ac.type, SUM(ac.mount) AS total 
FROM accounts ac
GROUP BY ac.type;
-- 2
SELECT COUNT(*) AS users_with_at_least_two_accounts
FROM (
    SELECT ac.user_id
    FROM accounts ac
    WHERE ac.type = 'CURRENT_ACCOUNT'
    GROUP BY ac.user_id
    HAVING COUNT(ac.type) >= 2
) AS subquery;
-- 3
SELECT ac.id, ac.user_id, ac.type, ac.mount 
FROM accounts ac
ORDER BY ac.mount DESC
LIMIT 5;
-- 4
WITH user_balances AS (
    SELECT
        a.user_id,
        SUM(CASE 
                WHEN m.type = 'IN' THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_to = a.id THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OUT' THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_to = a.id THEN m.mount
                ELSE 0
            END) + a.mount AS total_balance
    FROM
        accounts a
    LEFT JOIN
        movements m ON (m.account_from = a.id OR m.account_to = a.id)
    GROUP BY
        a.user_id, a.mount
)
SELECT 
    ub.user_id, 
    SUM(ub.total_balance) AS total_balance
FROM 
    user_balances ub
GROUP BY
    ub.user_id
ORDER BY
    total_balance DESC
LIMIT 3;
-- 5
-- En este no estoy seguro :{
DO $$
DECLARE
    saldo_origen NUMERIC;
    saldo_despues_transfer NUMERIC;
BEGIN
    BEGIN;
    -- Calcular el saldo actual de la cuenta origen
    WITH user_balances AS (
        SELECT
            a.user_id,
            SUM(CASE 
                    WHEN m.type = 'IN' THEN m.mount
                    WHEN m.type = 'TRANSFER' AND m.account_to = a.id THEN m.mount
                    WHEN m.type = 'TRANSFER' AND m.account_from = a.id THEN -m.mount
                    WHEN m.type = 'OUT' THEN -m.mount
                    WHEN m.type = 'OTHER' AND m.account_from = a.id THEN -m.mount
                    WHEN m.type = 'OTHER' AND m.account_to = a.id THEN m.mount
                    ELSE 0
                END) + a.mount AS total_balance
        FROM
            accounts a
        LEFT JOIN
            movements m ON (m.account_from = a.id OR m.account_to = a.id)
        GROUP BY
            a.user_id, a.mount
    )
    SELECT total_balance INTO saldo_origen
    FROM user_balances
    WHERE user_id = '3b79e403-c788-495a-a8ca-86ad7643afaf';

    IF saldo_origen < 50.75 THEN
        RAISE EXCEPTION 'Saldo insuficiente para la transferencia de 50.75';
    END IF;

    INSERT INTO movements (id, account_from, account_to, type, mount, created_at) 
    VALUES (gen_random_uuid(), '3b79e403-c788-495a-a8ca-86ad7643afaf', 'fd244313-36e5-4a17-a27c-f8265bc46590', 'TRANSFER', 50.75, CURRENT_TIMESTAMP);

    saldo_despues_transfer := saldo_origen - 50.75;

    IF saldo_despues_transfer < 731823.56 THEN
        RAISE EXCEPTION 'Saldo insuficiente para el movimiento OUT de 731823.56';
    END IF;

    INSERT INTO movements (id, account_from, account_to, type, mount, created_at) 
    VALUES (gen_random_uuid(), '3b79e403-c788-495a-a8ca-86ad7643afaf', NULL, 'OUT', 731823.56, CURRENT_TIMESTAMP);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END $$;
    -- e
    -- Cambiar el monto a uno que no exceda el saldo
INSERT INTO movements (id, account_from, account_to, type, mount, created_at) 
VALUES (gen_random_uuid(), '3b79e403-c788-495a-a8ca-86ad7643afaf', NULL, 'OUT', 5000.00, CURRENT_TIMESTAMP);
    -- g
    WITH user_balances AS (
    SELECT
        a.user_id,
        SUM(CASE 
                WHEN m.type = 'IN' THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_to = a.id THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OUT' THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_to = a.id THEN m.mount
                ELSE 0
            END) + a.mount AS total_balance
    FROM
        accounts a
    LEFT JOIN
        movements m ON (m.account_from = a.id OR m.account_to = a.id)
    GROUP BY
        a.user_id, a.mount
)
SELECT total_balance
FROM user_balances
WHERE user_id = 'fd244313-36e5-4a17-a27c-f8265bc46590';

-- 6
SELECT 
    us.id AS user_id,
    us.name AS user_name,
	ac.id AS account_id,
    ac.type AS account_type,
    mov.id AS movement_id,
	mov.type AS movement_type,
    mov.mount,
    mov.account_from,
    mov.account_to
FROM 
    movements mov
INNER JOIN 
    accounts ac ON mov.account_from = ac.id OR mov.account_to = ac.id
INNER JOIN 
    users us ON ac.user_id = us.id
WHERE 
    mov.account_from = '3b79e403-c788-495a-a8ca-86ad7643afaf' 
    OR 
    mov.account_to = '3b79e403-c788-495a-a8ca-86ad7643afaf';
-- 7
SELECT 
	CONCAT (us.name, ' ', us.last_name),
	us.email
FROM accounts ac
INNER JOIN users us ON ac.user_id = us.id
GROUP BY ac.user_id, us.name, us.email, us.last_name
ORDER BY SUM(ac.mount) DESC
LIMIT 1;
-- 8
SELECT 
    us.id AS user_id,
    us.name AS user_name,
	ac.id AS account_id,
    ac.type AS account_type,
    mov.id AS movement_id,
	mov.type AS movement_type,
    mov.mount,
    mov.account_from,
    mov.account_to,
	mov.created_at
FROM 
    movements mov
INNER JOIN 
    accounts ac ON mov.account_from = ac.id OR mov.account_to = ac.id
INNER JOIN 
    users us ON ac.user_id = us.id
WHERE us.email = 'Kaden.Gusikowski@gmail.com'
ORDER BY 
    ac.type,
    mov.created_at;