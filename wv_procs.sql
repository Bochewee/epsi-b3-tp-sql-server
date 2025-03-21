-- wv_procs.sql
USE loupgaroudb;

-- Procédure pour terminer un tour et appliquer les règles du jeu
CREATE OR ALTER PROCEDURE COMPLETE_TOUR
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Récupération du dernier tour modifié
    DECLARE @turn_id INT, @party_id INT, @turn_end_time DATETIME;
    
    SELECT TOP 1 
        @turn_id = id_turn,
        @party_id = id_party,
        @turn_end_time = end_time
    FROM turns
    WHERE end_time IS NOT NULL
    ORDER BY end_time DESC;
    
    IF @turn_id IS NULL RETURN;
    
    -- Mettre à jour les joueurs éliminés
    -- Un villageois est éliminé s'il se trouve sur la même case qu'un loup à la fin du tour
    WITH LastPositions AS (
        SELECT 
            pp.id_player,
            pp.target_position_row,
            pp.target_position_col
        FROM players_play pp
        WHERE pp.id_turn = @turn_id
    ),
    WolfPositions AS (
        SELECT 
            lp.target_position_row,
            lp.target_position_col
        FROM LastPositions lp
        JOIN players_in_parties pip ON lp.id_player = pip.id_player
        JOIN roles r ON pip.id_role = r.id_role
        WHERE pip.id_party = @party_id
          AND r.description_role = 'loup'
          AND pip.is_alive = 'yes'
    )
    UPDATE pip
    SET is_alive = 'no'
    FROM players_in_parties pip
    JOIN roles r ON pip.id_role = r.id_role
    JOIN LastPositions lp ON pip.id_player = lp.id_player
    WHERE pip.id_party = @party_id
      AND r.description_role = 'villageois'
      AND pip.is_alive = 'yes'
      AND EXISTS (
        SELECT 1 FROM WolfPositions wp
        WHERE wp.target_position_row = lp.target_position_row
          AND wp.target_position_col = lp.target_position_col
      );
    
    -- Vérifier si la partie est terminée (tous les villageois morts)
    DECLARE @villageois_vivants INT;
    
    SELECT @villageois_vivants = COUNT(*)
    FROM players_in_parties pip
    JOIN roles r ON pip.id_role = r.id_role
    WHERE pip.id_party = @party_id
      AND r.description_role = 'villageois'
      AND pip.is_alive = 'yes';
    
    -- Si tous les villageois sont morts, marquer la partie comme terminée
    IF @villageois_vivants = 0
    BEGIN
        UPDATE parties
        SET 
            end_time = @turn_end_time,
            winner = 'loup'
        WHERE id_party = @party_id;
        
        PRINT 'Partie ' + CAST(@party_id AS VARCHAR) + ' terminée. Victoire des loups!';
    END
    
    -- Pour les tests, afficher un message sur les joueurs éliminés
    PRINT 'Tour ' + CAST(@turn_id AS VARCHAR) + ' de la partie ' + CAST(@party_id AS VARCHAR) + ' terminé.';
    PRINT 'Villageois restants: ' + CAST(@villageois_vivants AS VARCHAR);
END;

-- Procédure pour convertir le pseudo du joueur en minuscules
CREATE OR ALTER PROCEDURE USERNAME_TO_LOWER
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE players
    SET pseudo = LOWER(pseudo);
    
    PRINT 'Les pseudos de tous les joueurs ont été convertis en minuscules.';
END;

-- Procédure pour générer des données de test
CREATE OR ALTER PROCEDURE SEED_DATA
    @nb_players INT,
    @party_id INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Création de tours pour la partie
    DECLARE @start_time DATETIME = GETDATE();
    DECLARE @nb_turns INT = 5; -- Nombre de tours à créer
    DECLARE @i INT = 1;
    
    WHILE @i <= @nb_turns
    BEGIN
        INSERT INTO turns (id_turn, id_party, start_time, end_time)
        VALUES (
            (SELECT ISNULL(MAX(id_turn), 0) FROM turns) + @i,
            @party_id,
            DATEADD(MINUTE, (@i-1)*10, @start_time),
            DATEADD(MINUTE, @i*10, @start_time)
        );
        
        SET @i = @i + 1;
    END;
    
    -- Création des joueurs s'il n'y en a pas assez
    DECLARE @nb_existing_players INT;
    SELECT @nb_existing_players = COUNT(*) FROM players;
    
    IF @nb_existing_players < @nb_players
    BEGIN
        DECLARE @j INT = @nb_existing_players + 1;
        
        WHILE @j <= @nb_players
        BEGIN
            INSERT INTO players (id_player, pseudo)
            VALUES (
                (SELECT ISNULL(MAX(id_player), 0) FROM players) + 1,
                'Player' + CAST(@j AS VARCHAR)
            );
            
            SET @j = @j + 1;
        END;
    END;
    
    -- Ajouter des joueurs à la partie avec des rôles équilibrés
    DECLARE @player_id INT;
    
    -- Identifier les joueurs qui ne sont pas déjà dans la partie
    DECLARE player_cursor CURSOR FOR
    SELECT p.id_player
    FROM players p
    WHERE NOT EXISTS (
        SELECT 1 FROM players_in_parties
        WHERE id_party = @party_id AND id_player = p.id_player
    )
    ORDER BY NEWID()
    OFFSET 0 ROWS FETCH NEXT @nb_players ROWS ONLY;
    
    OPEN player_cursor;
    FETCH NEXT FROM player_cursor INTO @player_id;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Attribuer un rôle aléatoirement en utilisant la fonction random_role
        INSERT INTO players_in_parties (id_party, id_player, id_role, is_alive)
        VALUES (@party_id, @player_id, dbo.random_role(@party_id), 'yes');
        
        FETCH NEXT FROM player_cursor INTO @player_id;
    END;
    
    CLOSE player_cursor;
    DEALLOCATE player_cursor;
    
    PRINT 'Données générées pour la partie ' + CAST(@party_id AS VARCHAR) + ' avec ' + CAST(@nb_players AS VARCHAR) + ' joueurs';
END;
