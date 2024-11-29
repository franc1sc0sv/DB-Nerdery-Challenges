-- Your answers here:
-- 1
SELECT ac.type, SUM(ac.mount) AS total 
FROM accounts ac
GROUP BY ac.type;

--------------------------------------------------------------------------------------------------------------

-- 2
SELECT COUNT(*) AS users_with_at_least_two_accounts
FROM (
    SELECT ac.user_id
    FROM accounts ac
    WHERE ac.type = 'CURRENT_ACCOUNT'
    GROUP BY ac.user_id
    HAVING COUNT(ac.type) >= 2
) AS subquery;

--------------------------------------------------------------------------------------------------------------

-- 3
SELECT ac.id, ac.user_id, ac.type, ac.mount 
FROM accounts ac
ORDER BY ac.mount DESC
LIMIT 5;

--------------------------------------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------------------------------------

-- 5

-- a. First, get the ammount for the account `3b79e403-c788-495a-a8ca-86ad7643afaf` and `fd244313-36e5-4a17-a27c-f8265bc46590` after all their movements.
-- b. Add a new movement with the information:
--     from: `3b79e403-c788-495a-a8ca-86ad7643afaf` make a transfer to `fd244313-36e5-4a17-a27c-f8265bc46590`
--     mount: 50.75

-- c. Add a new movement with the information:
--     from: `3b79e403-c788-495a-a8ca-86ad7643afaf`
--     type: OUT
--     mount: 731823.56

CREATE OR REPLACE FUNCTION obtener_saldo_usuario(user_id_input UUID)
RETURNS NUMERIC AS $$
DECLARE
    total_balance NUMERIC;
BEGIN
    SELECT 
        SUM(
            CASE
                WHEN m.type = 'IN' THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_to = a.id THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OUT' THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_to = a.id THEN m.mount
                ELSE 0
            END
        ) + a.mount
    INTO total_balance
    FROM 
        accounts a
    LEFT JOIN 
        movements m ON (m.account_from = a.id OR m.account_to = a.id)
    WHERE 
        a.user_id = user_id_input
    GROUP BY 
        a.user_id, a.mount;
 
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    saldo_1 NUMERIC;
    saldo_2 NUMERIC;
    cuenta_1 UUID := '3b79e403-c788-495a-a8ca-86ad7643afaf';
    cuenta_2 UUID := 'fd244313-36e5-4a17-a27c-f8265bc46590';
    monto_transferencia NUMERIC := 50.75;
    monto_out NUMERIC := 731823.56;
BEGIN
    BEGIN        
        saldo_1 := calcular_saldo(cuenta_1);
        saldo_2 := calcular_saldo(cuenta_2);

        RAISE NOTICE 'Saldo inicial cuenta 1: %, saldo inicial cuenta 2: %', saldo_1, saldo_2;

        INSERT INTO movements (id, account_from, account_to, type, mount)
        VALUES (gen_random_uuid(), cuenta_1, cuenta_2, 'TRANSFER', monto_transferencia);

        saldo_1 := saldo_1 - monto_transferencia;
        saldo_2 := saldo_2 + monto_transferencia;

        IF saldo_2 < monto_out THEN
            RAISE EXCEPTION 'Saldo insuficiente para realizar el movimiento tipo OUT. Saldo disponible: %, monto requerido: %', saldo_2, monto_out;
        END IF;

        INSERT INTO movements (id, account_from, type, mount)
        VALUES (gen_random_uuid(), cuenta_1, 'OUT', monto_out);

        saldo_1 := calcular_saldo(cuenta_1);
        saldo_2 := calcular_saldo(cuenta_2);

        RAISE NOTICE 'Movimientos insertados correctamente. Saldo final cuenta 1: %, saldo final cuenta 2: %', saldo_1, saldo_2;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error durante la transacción: %', SQLERRM;
            RAISE;
    END;
END $$;

-- e. If the transaction fails, make the correction on step _c_ to avoid the failure:
-- If the balance is not sufficient, reduce the amount_out amount so that it does not cause an error.
CREATE OR REPLACE FUNCTION obtener_saldo_usuario(user_id_input UUID)
RETURNS NUMERIC AS $$
DECLARE
    total_balance NUMERIC;
BEGIN
    SELECT 
        SUM(
            CASE
                WHEN m.type = 'IN' THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_to = a.id THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OUT' THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_to = a.id THEN m.mount
                ELSE 0
            END
        ) + a.mount
    INTO total_balance
    FROM 
        accounts a
    LEFT JOIN 
        movements m ON (m.account_from = a.id OR m.account_to = a.id)
    WHERE 
        a.user_id = user_id_input
    GROUP BY 
        a.user_id, a.mount;
 
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    saldo_1 NUMERIC;
    saldo_2 NUMERIC;
    cuenta_1 UUID := '3b79e403-c788-495a-a8ca-86ad7643afaf';
    cuenta_2 UUID := 'fd244313-36e5-4a17-a27c-f8265bc46590';
    monto_transferencia NUMERIC := 50.75;
    monto_out NUMERIC := 731823.56;
BEGIN
    BEGIN        
        saldo_1 := calcular_saldo(cuenta_1);
        saldo_2 := calcular_saldo(cuenta_2);

        RAISE NOTICE 'Saldo inicial cuenta 1: %, saldo inicial cuenta 2: %', saldo_1, saldo_2;
        
        INSERT INTO movements (id, account_from, account_to, type, mount)
        VALUES (gen_random_uuid(), cuenta_1, cuenta_2, 'TRANSFER', monto_transferencia);
        
        saldo_1 := saldo_1 - monto_transferencia;
        saldo_2 := saldo_2 + monto_transferencia;
        
        IF saldo_2 < monto_out THEN
            RAISE NOTICE 'Saldo insuficiente. Ajustando monto OUT de % a %', monto_out, saldo_2;
            monto_out := saldo_2;
        END IF;
        
        INSERT INTO movements (id, account_from, type, mount)
        VALUES (gen_random_uuid(), cuenta_1, 'OUT', monto_out);
        
        saldo_1 := calcular_saldo(cuenta_1);
        saldo_2 := calcular_saldo(cuenta_2);

        RAISE NOTICE 'Movimientos realizados correctamente. Saldo final cuenta 1: %, saldo final cuenta 2: %', saldo_1, saldo_2;

    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'Error durante la transacción: %', SQLERRM;
            RAISE;
    END;
END $$;

-- f. Once the transaction is correct, make a commit
-- Within the context of the DO block, PostgreSQL performs an implicit commit if the block completes successfully. If you want to make sure of an explicit commit

-- e. How much money the account `fd244313-36e5-4a17-a27c-f8265bc46590` have:
CREATE OR REPLACE FUNCTION obtener_saldo_usuario(user_id_input UUID)
RETURNS NUMERIC AS $$
DECLARE
    total_balance NUMERIC;
BEGIN
    SELECT 
        SUM(
            CASE
                WHEN m.type = 'IN' THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_to = a.id THEN m.mount
                WHEN m.type = 'TRANSFER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OUT' THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_from = a.id THEN -m.mount
                WHEN m.type = 'OTHER' AND m.account_to = a.id THEN m.mount
                ELSE 0
            END
        ) + a.mount
    INTO total_balance
    FROM 
        accounts a
    LEFT JOIN 
        movements m ON (m.account_from = a.id OR m.account_to = a.id)
    WHERE 
        a.user_id = user_id_input
    GROUP BY 
        a.user_id, a.mount;
 
    RETURN total_balance;
END;
$$ LANGUAGE plpgsql;


SELECT calcular_saldo('fd244313-36e5-4a17-a27c-f8265bc46590');

--------------------------------------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------------------------------------

-- 7
SELECT 
	CONCAT (us.name, ' ', us.last_name),
	us.email
FROM accounts ac
INNER JOIN users us ON ac.user_id = us.id
GROUP BY ac.user_id, us.name, us.email, us.last_name
ORDER BY SUM(ac.mount) DESC
LIMIT 1;

--------------------------------------------------------------------------------------------------------------

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