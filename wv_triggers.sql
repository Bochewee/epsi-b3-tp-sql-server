-- wv_triggers.sql
USE loupgaroudb;

-- Trigger pour vérifier que le nombre de loups est équilibré
CREATE OR ALTER TRIGGER trg_check_wolf_balance
ON players_in_parties
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @party_id INT;
    DECLARE @wolf_count INT;
    DECLARE @total_players INT;
    DECLARE @wolf_percentage FLOAT;
    DECLARE @wolf_role_id INT;
    
    -- Récupérer l'ID du rôle loup
    SELECT @wolf_role_id = id_role FROM roles WHERE description_role = 'loup';
    
    -- Récupérer party_id de la ligne insérée/mise à jour
    SELECT @party_id = id_party FROM inserted;
    
    -- Calculer le pourcentage de loups dans la partie
    SELECT 
        @wolf_count = COUNT(CASE WHEN id_role = @wolf_role_id THEN 1 END),
        @total_players = COUNT(*)
    FROM players_in_parties
    WHERE id_party = @party_id;
    
    SET @wolf_percentage = CAST(@wolf_count AS FLOAT) / CASE WHEN @total_players = 0 THEN 1 ELSE @total_players END;
    
    -- Vérifier que le pourcentage de loups est entre 20% et 40%
    IF @total_players >= 5 AND (@wolf_percentage < 0.2 OR @wolf_percentage > 0.4)
    BEGIN
        RAISERROR('Le pourcentage de loups doit être entre 20% et 40% pour les parties avec au moins 5 joueurs.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- Trigger pour vérifier que les actions sont faites pendant le tour correspondant
CREATE OR ALTER TRIGGER trg_validate_action_time
ON players_play
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Vérifier que les actions sont soumises pendant le temps alloué au tour
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN turns t ON i.id_turn = t.id_turn
        WHERE i.start_time < t.start_time OR i.end_time > t.end_time
    )
    BEGIN
        RAISERROR('Les actions doivent être soumises pendant le temps alloué au tour.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;

-- Trigger pour mettre à jour l'état "is_alive" des joueurs après une action
CREATE OR ALTER TRIGGER trg_update_player_status
ON players_play
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @tour_id INT;
    DECLARE @party_id INT;
    
    -- Récupérer le tour et la partie concernés
    SELECT TOP 1 @tour_id = i.id_turn 
    FROM inserted i;
    
    SELECT @party_id = id_party 
    FROM turns 
    WHERE id_turn = @tour_id;
    
    -- Exécuter la procédure pour compléter le tour
    EXEC COMPLETE_TOUR @tour_id, @party_id;
END;
