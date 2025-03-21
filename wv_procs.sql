-- wv_procs.sql
USE loupgaroudb;

-- Procédure SEED_DATA : crée autant de tours de jeu que la partie peut en accepter
CREATE OR ALTER PROCEDURE SEED_DATA
    @NB_PLAYERS INT,
    @PARTY_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @max_tours INT = 10; -- Nombre arbitraire de tours
    DECLARE @wolf_role_id INT;
    DECLARE @villager_role_id INT;
    
    -- Obtenir les IDs des rôles
    SELECT @wolf_role_id = id_role FROM roles WHERE description_role = 'loup';
    SELECT @villager_role_id = id_role FROM roles WHERE description_role = 'villageois';
    
    -- Créer des joueurs si nécessaire
    DECLARE @i INT = 1;
    WHILE @i <= @NB_PLAYERS
    BEGIN
        -- Vérifier si le joueur existe déjà
        IF NOT EXISTS (SELECT 1 FROM players WHERE pseudo = 'Player' + CAST(@i AS NVARCHAR(10)))
        BEGIN
            -- Créer un nouveau joueur
            INSERT INTO players (id_player, pseudo)
            VALUES (@i, 'Player' + CAST(@i AS NVARCHAR(10)));
        END
        
        -- Ajouter le joueur à la partie s'il n'y est pas déjà
        IF NOT EXISTS (SELECT 1 FROM players_in_parties WHERE id_party = @PARTY_ID AND id_player = @i)
        BEGIN
            -- Attribuer un rôle en utilisant la fonction random_role
            DECLARE @role_id INT;
            SELECT @role_id = dbo.random_role(@PARTY_ID);
            
            INSERT INTO players_in_parties (id_party, id_player, id_role, is_alive)
            VALUES (@PARTY_ID, @i, @role_id, 'yes');
        END
        
        SET @i = @i + 1;
    END
    
    -- Créer des tours de jeu
    DECLARE @tour_number INT = 1;
    WHILE @tour_number <= @max_tours
    BEGIN
        -- Vérifier si le tour existe déjà
        IF NOT EXISTS (SELECT 1 FROM turns WHERE id_party = @PARTY_ID AND id_turn = @tour_number)
        BEGIN
            -- Créer un nouveau tour
            INSERT INTO turns (id_turn, id_party, start_time, end_time)
            VALUES (@tour_number, @PARTY_ID, 
                   DATEADD(MINUTE, (@tour_number - 1) * 5, GETDATE()), 
                   DATEADD(MINUTE, @tour_number * 5, GETDATE()));
        END
        
        SET @tour_number = @tour_number + 1;
    END
    
    -- Générer des actions aléatoires pour les joueurs
    DECLARE @current_tour INT = 1;
    WHILE @current_tour <= @max_tours
    BEGIN
        DECLARE player_cursor CURSOR FOR 
        SELECT id_player FROM players_in_parties 
        WHERE id_party = @PARTY_ID AND is_alive = 'yes';
        
        DECLARE @current_player_id INT;
        OPEN player_cursor;
        FETCH NEXT FROM player_cursor INTO @current_player_id;
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Vérifier si le joueur a déjà une action pour ce tour
            IF NOT EXISTS (SELECT 1 FROM players_play WHERE id_turn = @current_tour AND id_player = @current_player_id)
            BEGIN
                -- Générer une position aléatoire pour l'origine et la cible
                DECLARE @origin_row INT = CAST(RAND() * 10 AS INT) + 1;
                DECLARE @origin_col INT = CAST(RAND() * 10 AS INT) + 1;
                DECLARE @target_row INT, @target_col INT;
                
                SELECT TOP 1 @target_row = row_pos, @target_col = col_pos 
                FROM dbo.random_position(10, 10, @PARTY_ID);
                
                -- Créer l'action
                INSERT INTO players_play (
                    id_player, id_turn, start_time, end_time, action, 
                    origin_position_row, origin_position_col,
                    target_position_row, target_position_col
                )
                VALUES (
                    @current_player_id, @current_tour, 
                    (SELECT start_time FROM turns WHERE id_turn = @current_tour),
                    DATEADD(SECOND, CAST(RAND() * 240 AS INT), (SELECT start_time FROM turns WHERE id_turn = @current_tour)),
                    'move',
                    CAST(@origin_row AS TEXT), CAST(@origin_col AS TEXT),
                    CAST(@target_row AS TEXT), CAST(@target_col AS TEXT)
                );
            END
            
            FETCH NEXT FROM player_cursor INTO @current_player_id;
        END
        
        CLOSE player_cursor;
        DEALLOCATE player_cursor;
        
        SET @current_tour = @current_tour + 1;
    END
END;

-- Procédure COMPLETE_TOUR : applique toutes les demandes de déplacement
CREATE OR ALTER PROCEDURE COMPLETE_TOUR
    @TOUR_ID INT,
    @PARTY_ID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Vérifier que le tour appartient à la partie spécifiée
    IF NOT EXISTS (SELECT 1 FROM turns WHERE id_turn = @TOUR_ID AND id_party = @PARTY_ID)
    BEGIN
        RAISERROR('Le tour spécifié n''appartient pas à la partie indiquée.', 16, 1);
        RETURN;
    END
    
    -- Détecter et résoudre les conflits de déplacement (deux joueurs voulant aller sur la même case)
    -- En cas de conflit, nous gardons la première action soumise
    WITH ConflictingMoves AS (
        SELECT 
            pp.id_player,
            pp.target_position_row,
            pp.target_position_col,
            ROW_NUMBER() OVER (
                PARTITION BY pp.target_position_row, pp.target_position_col 
                ORDER BY pp.end_time
            ) AS move_rank
        FROM 
            players_play pp
        WHERE 
            pp.id_turn = @TOUR_ID
    )
    -- Mettre à jour les positions des joueurs dans les tours suivants
    -- Les joueurs dont les mouvements causent des conflits restent à leur position d'origine
    UPDATE pp
    SET 
        target_position_row = pp.origin_position_row,
        target_position_col = pp.origin_position_col
    FROM 
        players_play pp
    JOIN 
        ConflictingMoves cm ON pp.id_player = cm.id_player
                            AND pp.target_position_row = cm.target_position_row
                            AND pp.target_position_col = cm.target_position_col
    WHERE 
        pp.id_turn = @TOUR_ID
        AND cm.move_rank > 1;
    
    -- Identifier les villageois qui se retrouvent sur la même case qu'un loup
    WITH PlayerPositions AS (
        SELECT 
            pp.id_player,
            pip.id_role,
            pp.target_position_row,
            pp.target_position_col
        FROM 
            players_play pp
        JOIN 
            players_in_parties pip ON pp.id_player = pip.id_player
        JOIN
            turns t ON pp.id_turn = t.id_turn AND pip.id_party = t.id_party
        WHERE 
            pp.id_turn = @TOUR_ID
            AND t.id_party = @PARTY_ID
            AND pip.is_alive = 'yes'
    ),
    WolfPositions AS (
        SELECT 
            target_position_row,
            target_position_col
        FROM 
            PlayerPositions
        JOIN
            roles r ON PlayerPositions.id_role = r.id_role
        WHERE 
            r.description_role = 'loup'
    ),
    EliminatedVillagers AS (
        SELECT DISTINCT
            vp.id_player
        FROM 
            PlayerPositions vp
        JOIN
            WolfPositions wp ON vp.target_position_row = wp.target_position_row
                            AND vp.target_position_col = wp.target_position_col
        JOIN
            roles r ON vp.id_role = r.id_role
        WHERE 
            r.description_role = 'villageois'
    )
    -- Marquer les villageois éliminés
    UPDATE players_in_parties
    SET is_alive = 'no'
    FROM players_in_parties pip
    JOIN EliminatedVillagers ev ON pip.id_player = ev.id_player
    WHERE pip.id_party = @PARTY_ID;
    
    -- Vérifier s'il reste des villageois vivants
    IF NOT EXISTS (
        SELECT 1 
        FROM players_in_parties pip
        JOIN roles r ON pip.id_role = r.id_role
        WHERE pip.id_party = @PARTY_ID 
              AND r.description_role = 'villageois' 
              AND pip.is_alive = 'yes'
    )
    BEGIN
        -- Tous les villageois sont éliminés, les loups gagnent
        PRINT 'Les loups gagnent!';
    END
    ELSE
    BEGIN
        -- Vérifier si c'est le dernier tour
        IF NOT EXISTS (SELECT 1 FROM turns WHERE id_party = @PARTY_ID AND id_turn > @TOUR_ID)
        BEGIN
            -- C'est le dernier tour et il reste des villageois, les villageois gagnent
            PRINT 'Les villageois gagnent!';
        END
    END
END;

-- Procédure USERNAME_TO_LOWER : met les noms des joueurs en minuscule
CREATE OR ALTER PROCEDURE USERNAME_TO_LOWER
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Mise à jour de tous les noms de joueurs en minuscule
    UPDATE players
    SET pseudo = LOWER(pseudo)
    WHERE pseudo != LOWER(pseudo);
    
    -- Affiche le nombre de noms mis à jour
    DECLARE @updated_count INT = @@ROWCOUNT;
    PRINT CAST(@updated_count AS NVARCHAR(10)) + ' noms de joueurs ont été convertis en minuscules.';
END;
