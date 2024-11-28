<p align="center" style="background-color:white">
 <a href="https://www.ravn.co/" rel="noopener">
 <img src="src/ravn_logo.png" alt="RAVN logo" width="150px"></a>
</p>
<p align="center">
 <a href="https://www.postgresql.org/" rel="noopener">
 <img src="https://www.postgresql.org/media/img/about/press/elephant.png" alt="Postgres logo" width="150px"></a>
</p>

---

<p align="center">A project to show off your skills on databases & SQL using a real database</p>

## 📝 Table of Contents

- [Case](#case)
- [Installation](#installation)
- [Data Recovery](#data_recovery)
- [Excersises](#excersises)

## 🤓 Case <a name = "case"></a>

As a developer and expert on SQL, you were contacted by a company that needs your help to manage their database which runs on PostgreSQL. The database provided contains four entities: Employee, Office, Countries and States. The company has different headquarters in various places around the world, in turn, each headquarters has a group of employees of which it is hierarchically organized and each employee may have a supervisor. You are also provided with the following Entity Relationship Diagram (ERD)

#### ERD - Diagram <br>

![Comparison](src/ERD.png) <br>

---

## 🛠️ Docker Installation <a name = "installation"></a>

1. Install [docker](https://docs.docker.com/engine/install/)

---

## 📚 Recover the data to your machine <a name = "data_recovery"></a>

Open your terminal and run the follows commands:

1. This will create a container for postgresql:

```
docker run --name nerdery-container -e POSTGRES_PASSWORD=password123 -p 5432:5432 -d --rm postgres:15.2
```

2. Now, we access the container:

```
docker exec -it -u postgres nerdery-container psql
```

3. Create the database:

```
create database nerdery_challenge;
```

5. Close the database connection:

```
\q
```

4. Restore de postgres backup file

```
cat /.../dump.sql | docker exec -i nerdery-container psql -U postgres -d nerdery_challenge
```

- Note: The `...` mean the location where the src folder is located on your computer
- Your data is now on your database to use for the challenge

---

## 📊 Excersises <a name = "excersises"></a>

Now it's your turn to write SQL queries to achieve the following results (You need to write the query in the section `Your query here` on each question):

1. Total money of all the accounts group by types.

```
SELECT ac.type, SUM(ac.mount) AS total
FROM accounts ac
GROUP BY ac.type;
```

2. How many users with at least 2 `CURRENT_ACCOUNT`.

```
SELECT COUNT(*) AS users_with_at_least_two_accounts
FROM (
    SELECT ac.user_id
    FROM accounts ac
    WHERE ac.type = 'CURRENT_ACCOUNT'
    GROUP BY ac.user_id
    HAVING COUNT(ac.type) >= 2
) AS subquery;
```

3. List the top five accounts with more money.

```
SELECT ac.id, ac.user_id, ac.type, ac.mount
FROM accounts ac
ORDER BY ac.mount DESC
LIMIT 5;
```

4. Get the three users with the most money after making movements.

```
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
```

5.  In this part you need to create a transaction with the following steps:

        a. First, get the ammount for the account `3b79e403-c788-495a-a8ca-86ad7643afaf` and `fd244313-36e5-4a17-a27c-f8265bc46590` after all their movements.
        b. Add a new movement with the information:
            from: `3b79e403-c788-495a-a8ca-86ad7643afaf` make a transfer to `fd244313-36e5-4a17-a27c-f8265bc46590`
            mount: 50.75

        c. Add a new movement with the information:
            from: `3b79e403-c788-495a-a8ca-86ad7643afaf`
            type: OUT
            mount: 731823.56

            * Note: if the account does not have enough money you need to reject this insert and make a rollback for the entire transaction

            ```
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
    ```

        d. Put your answer here if the transaction fails(YES/NO):
        ```
           YES
        ```

        e. If the transaction fails, make the correction on step _c_ to avoid the failure:
        ```
        -- Cambiar el monto a uno que no exceda el saldo
        INSERT INTO movements (id, account_from, account_to, type, mount, created_at)
        VALUES (gen_random_uuid(), '3b79e403-c788-495a-a8ca-86ad7643afaf', NULL, 'OUT', 5000.00, CURRENT_TIMESTAMP);
        ```

        f. Once the transaction is correct, make a commit
        ```
        IF saldo_despues_transfer < 731823.56 THEN
            RAISE EXCEPTION 'Saldo insuficiente para el movimiento OUT de 731823.56';
        END IF;

        INSERT INTO movements (id, account_from, account_to, type, mount, created_at)
        VALUES (gen_random_uuid(), '3b79e403-c788-495a-a8ca-86ad7643afaf', NULL, 'OUT', 5000.00, CURRENT_TIMESTAMP);

        COMMIT;
        ```

        e. How much money the account `fd244313-36e5-4a17-a27c-f8265bc46590` have:
        ```
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
    ```

6.  All the movements and the user information with the account `3b79e403-c788-495a-a8ca-86ad7643afaf`

```
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
```

7. The name and email of the user with the highest money in all his/her accounts

```
SELECT
	CONCAT (us.name, ' ', us.last_name),
	us.email
FROM accounts ac
INNER JOIN users us ON ac.user_id = us.id
GROUP BY ac.user_id, us.name, us.email, us.last_name
ORDER BY SUM(ac.mount) DESC
LIMIT 1;
```

8. Show all the movements for the user `Kaden.Gusikowski@gmail.com` order by account type and created_at on the movements table

```
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
```
