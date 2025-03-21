-- wv_funcs.sql
USE loupgaroudb;

-- Fonction pour générer une position aléatoire non utilisée
CREATE OR ALTER FUNCTION random_position(
    @rows INT,
    @cols INT,
    @party_id INT
)
RETURNS TABLE
AS
RETURN
(
    -- Sélectionne une position aléatoire qui n'a jamais été utilisée dans cette partie
    WITH UsedPositions AS (
        -- Positions d'origine utilisées
        SELECT origin_position_row AS row, origin_position_col AS col
        FROM players_play pp
        JOIN turns t ON pp.id_turn = t.id_turn
        WHERE t.id_party = @party_id
        
        UNION
        
        -- Positions cibles utilisées
        SELECT target_position_row AS row, target_position_col AS col
        FROM players_play pp
        JOIN turns t ON pp.id_turn = t.id_turn
        WHERE t.id_party = @party_id
    ),
    AllPositions AS (
        -- Générer toutes les positions possibles
        SELECT 
            ROW_NUMBER() OVER (ORDER BY a.number) AS row_num,
            (a.number % @rows) + 1 AS row,
            (a.number / @rows) + 1 AS col
        FROM (
            SELECT TOP (@rows * @cols) 
                ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1 AS number
            FROM sys.objects a
            CROSS JOIN sys.objects b
        ) a
        WHERE (a.number % @rows) + 1 <= @rows AND (a.number / @rows) + 1 <= @cols
    )
    -- Sélectionner une position aléatoire non utilisée
    SELECT TOP(1) row, col
    FROM AllPositions
    WHERE NOT EXISTS (
        SELECT 1 FROM UsedPositions
        WHERE UsedPositions.row = AllPositions.row
        AND UsedPositions.col = AllPositions.col
    )
    ORDER BY NEWID()
);

-- Fonction pour attribuer aléatoirement un rôle en respectant les quotas
CREATE OR ALTER FUNCTION random_role(
    @party_id INT
)
RETURNS INT
AS
BEGIN
    DECLARE @role_id INT;
    DECLARE @total_players INT;
    DECLARE @total_wolves INT;
    DECLARE @wolf_ratio FLOAT;
    
    -- Compter le nombre total de joueurs et de loups
    SELECT @total_players = COUNT(*) 
    FROM players_in_parties
    WHERE id_party = @party_id;
    
    SELECT @total_wolves = COUNT(*)
    FROM players_in_parties pip
    JOIN roles r ON pip.id_role = r.id_role
    WHERE pip.id_party = @party_id AND r.description_role = 'loup';
    
    -- Calculer le ratio de loups
    IF @total_players = 0 
        SET @wolf_ratio = 0;
    ELSE 
        SET @wolf_ratio = CAST(@total_wolves AS FLOAT) / CAST(@total_players AS FLOAT);
    
    -- Attribuer un rôle en fonction du ratio (max 40% de loups)
    IF @wolf_ratio < 0.4 -- Si moins de 40% de loups
        SET @role_id = 2; -- Loup (si votre ID pour loup est 2)
    ELSE
        SET @role_id = 1; -- Villageois (si votre ID pour villageois est 1)
    
    RETURN @role_id;
END;

-- Fonction pour récupérer les informations du vainqueur d'une partie
CREATE OR ALTER FUNCTION get_the_winner(@party_id INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        p.pseudo AS 'nom du joueur',
        r.description_role AS 'role',
        party.title_party AS 'nom de la partie',
        COUNT(DISTINCT pp.id_turn) AS 'nb de tours joués par le joueur',
        (SELECT COUNT(*) FROM turns WHERE id_party = @party_id) AS 'nb total de tours de la partie',
        AVG(DATEDIFF(SECOND, pp.start_time, pp.end_time)) AS 'temps moyen de prise de décision du joueur'
    FROM 
        players p
        JOIN players_in_parties pip ON p.id_player = pip.id_player
        JOIN roles r ON pip.id_role = r.id_role
        JOIN parties party ON pip.id_party = party.id_party
        JOIN players_play pp ON p.id_player = pp.id_player
        JOIN turns t ON pp.id_turn = t.id_turn AND t.id_party = pip.id_party
    WHERE 
        pip.id_party = @party_id
        AND pip.is_alive = 'yes'
        AND (
            -- Condition de victoire: 
            -- Si winner est 'loup' dans parties, alors on sélectionne les loups
            -- sinon on sélectionne les villageois
            (party.winner = 'loup' AND r.description_role = 'loup')
            OR 
            (party.winner = 'villageois' AND r.description_role = 'villageois')
        )
    GROUP BY 
        p.id_player, p.pseudo, r.description_role, party.title_party
);
