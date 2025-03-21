-- wv_functions.sql
USE loupgaroudb;

-- Fonction random_position : renvoie un couple aléatoire de position non déjà utilisé
CREATE OR ALTER FUNCTION random_position(@rows INT, @cols INT, @party_id INT)
RETURNS TABLE
AS
RETURN
    SELECT TOP 1
        r.row_num AS row_pos,
        c.col_num AS col_pos
    FROM
        (SELECT TOP (@rows) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS row_num
         FROM sys.objects) r
    CROSS JOIN
        (SELECT TOP (@cols) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS col_num
         FROM sys.objects) c
    WHERE
        NOT EXISTS (
            SELECT 1
            FROM players_play pp
            JOIN turns t ON pp.id_turn = t.id_turn
            WHERE 
                t.id_party = @party_id 
                AND (pp.target_position_row = CAST(r.row_num AS TEXT)
                     AND pp.target_position_col = CAST(c.col_num AS TEXT))
        )
    ORDER BY NEWID();

-- Fonction random_role : renvoie le prochain rôle à affecter en respectant les quotas
CREATE OR ALTER FUNCTION random_role(@party_id INT)
RETURNS INT
AS
BEGIN
    DECLARE @wolf_count INT;
    DECLARE @villager_count INT;
    DECLARE @total_count INT;
    DECLARE @wolf_quota FLOAT;
    DECLARE @wolf_role_id INT;
    DECLARE @villager_role_id INT;
    
    -- Obtenir les IDs des rôles loup et villageois
    SELECT @wolf_role_id = id_role FROM roles WHERE description_role = 'loup';
    SELECT @villager_role_id = id_role FROM roles WHERE description_role = 'villageois';
    
    -- Obtenir le nombre actuel de loups et de villageois dans la partie
    SELECT 
        @wolf_count = COUNT(CASE WHEN id_role = @wolf_role_id THEN 1 END),
        @villager_count = COUNT(CASE WHEN id_role = @villager_role_id THEN 1 END),
        @total_count = COUNT(*)
    FROM 
        players_in_parties
    WHERE 
        id_party = @party_id;

    -- Si aucun joueur, commencer par un rôle aléatoire
    IF @total_count = 0
    BEGIN
        RETURN CASE WHEN RAND() > 0.7 THEN @wolf_role_id ELSE @villager_role_id END;
    END

    -- Calculer le quota actuel de loups
    SET @wolf_quota = CAST(@wolf_count AS FLOAT) / CAST(@total_count AS FLOAT);

    -- Déterminer le prochain rôle en fonction du quota
    -- Idéalement, on veut ~30% de loups, donc:
    IF @wolf_quota < 0.3
    BEGIN
        RETURN @wolf_role_id;
    END
    ELSE
    BEGIN
        RETURN @villager_role_id;
    END
END;

-- Fonction get_the_winner : renvoie les informations sur le vainqueur de la partie
CREATE OR ALTER FUNCTION get_the_winner(@party_id INT)
RETURNS TABLE
AS
RETURN
    SELECT TOP 1
        p.pseudo AS 'nom du joueur',
        r.description_role AS 'role',
        pa.title_party AS 'nom de la partie',
        COUNT(DISTINCT pp.id_turn) AS 'nb de tours joués par le joueur',
        (SELECT COUNT(DISTINCT id_turn) FROM turns WHERE id_party = @party_id) AS 'nb total de tours de la partie',
        AVG(DATEDIFF(SECOND, pp.start_time, pp.end_time)) AS 'temps moyen de prise de décision du joueur'
    FROM
        players p
    JOIN
        players_in_parties pip ON p.id_player = pip.id_player
    JOIN
        roles r ON pip.id_role = r.id_role
    JOIN
        parties pa ON pip.id_party = pa.id_party
    JOIN
        players_play pp ON p.id_player = pp.id_player
    JOIN
        turns t ON pp.id_turn = t.id_turn
    WHERE
        pip.id_party = @party_id
        AND pip.is_alive = 'yes'
        AND t.id_party = @party_id
        -- Supposons que le gagnant est déterminé par le joueur qui a survécu et joué le plus de tours
        -- Dans un vrai jeu, cela dépendrait de la logique du jeu (loups vs villageois)
    GROUP BY
        p.pseudo, r.description_role, pa.title_party
    ORDER BY
        COUNT(DISTINCT pp.id_turn) DESC, -- Le joueur ayant joué le plus de tours en premier
        p.pseudo; -- Tri alphabétique en cas d'égalité
