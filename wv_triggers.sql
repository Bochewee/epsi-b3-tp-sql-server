-- ===============================================================================================
-- TRIGGER 1 : Déclencher la procédure COMPLETE_TOUR quand un tour est marqué comme terminé
-- ===============================================================================================
CREATE TRIGGER TR_COMPLETE_TOUR_ON_END
ON turns
AFTER UPDATE
AS
BEGIN
    -- Vérifier si le champ end_time a été mis à jour et n'était pas déjà renseigné
    IF UPDATE(end_time)
    BEGIN
        -- Récupérer les tours qui viennent d'être marqués comme terminés
        DECLARE @id_turn INT
        
        -- Parcourir tous les tours qui viennent d'être fermés
        DECLARE tour_cursor CURSOR FOR
            SELECT i.id_turn
            FROM inserted i
            JOIN deleted d ON i.id_turn = d.id_turn
            WHERE i.end_time IS NOT NULL 
            AND d.end_time IS NULL;
            
        OPEN tour_cursor
        FETCH NEXT FROM tour_cursor INTO @id_turn
        
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Exécuter la procédure COMPLETE_TOUR pour chaque tour marqué comme terminé
            EXEC COMPLETE_TOUR @id_turn
            
            FETCH NEXT FROM tour_cursor INTO @id_turn
        END
        
        CLOSE tour_cursor
        DEALLOCATE tour_cursor
    END
END;
GO

-- ===============================================================================================
-- TRIGGER 2 : Déclencher la procédure USERNAME_TO_LOWER quand un joueur s'inscrit
-- ===============================================================================================
CREATE TRIGGER TR_USERNAME_TO_LOWER_ON_INSERT
ON players
AFTER INSERT
AS
BEGIN
    -- Récupérer les IDs des joueurs qui viennent d'être insérés
    DECLARE @id_player INT
    
    -- Parcourir tous les joueurs nouvellement inscrits
    DECLARE player_cursor CURSOR FOR
        SELECT id_player FROM inserted;
        
    OPEN player_cursor
    FETCH NEXT FROM player_cursor INTO @id_player
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Exécuter la procédure USERNAME_TO_LOWER pour chaque joueur inséré
        EXEC USERNAME_TO_LOWER @id_player
        
        FETCH NEXT FROM player_cursor INTO @id_player
    END
    
    CLOSE player_cursor
    DEALLOCATE player_cursor
END;
GO

-- ===============================================================================================
-- TRIGGER 3 : Vérifier qu'un joueur n'est pas dans plusieurs parties actives simultanément
-- ===============================================================================================
CREATE TRIGGER TR_CHECK_PLAYER_NOT_IN_MULTIPLE_ACTIVE_GAMES
ON players_in_parties
FOR INSERT
AS
BEGIN
    -- Vérifier si un des joueurs insérés est déjà dans une partie active
    IF EXISTS (
        SELECT 1 
        FROM inserted i
        JOIN players_in_parties pip ON i.id_player = pip.id_player
        JOIN parties p ON pip.id_party = p.id_party
        WHERE p.end_time IS NULL 
        AND p.id_party <> i.id_party
    )
    BEGIN
        RAISERROR('Un joueur ne peut pas participer à plusieurs parties actives simultanément.', 16, 1)
        ROLLBACK TRANSACTION
    END
END;
GO
