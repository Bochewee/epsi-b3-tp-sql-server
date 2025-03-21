-- Requêtes de test pour TP_WerewolfVillage
-- wv_test.sql
USE loupgaroudb;

-- Réinitialisation complète des tables
DELETE FROM players_play;
DELETE FROM players_in_parties;
DELETE FROM turns;
DELETE FROM parties;
DELETE FROM players;
DELETE FROM roles;

-- Insertion des rôles de base
INSERT INTO roles (id_role, description_role) VALUES 
(1, 'villageois'),
(2, 'loup');

-- Insertion de joueurs de test
INSERT INTO players (id_player, pseudo) VALUES
(1, 'Alice'),
(2, 'Bob'),
(3, 'Charlie'),
(4, 'David'),
(5, 'Eve'),
(6, 'Frank'),
(7, 'Grace'),
(8, 'Heidi');

-- Création d'une partie de test
INSERT INTO parties (id_party, title_party) VALUES
(1, 'Partie de test 1');

-- Insertion manuelle de joueurs dans la partie avec des rôles équilibrés
INSERT INTO players_in_parties (id_party, id_player, id_role, is_alive) VALUES
-- 2 loups (25%)
(1, 1, 2, 'yes'), -- Alice est un loup
(1, 2, 2, 'yes'), -- Bob est un loup
-- 6 villageois (75%)
(1, 3, 1, 'yes'), -- Charlie est un villageois
(1, 4, 1, 'yes'), -- David est un villageois
(1, 5, 1, 'yes'), -- Eve est un villageois
(1, 6, 1, 'yes'), -- Frank est un villageois
(1, 7, 1, 'yes'), -- Grace est un villageois
(1, 8, 1, 'yes'); -- Heidi est un villageois

-- Création des tours pour cette partie
INSERT INTO turns (id_turn, id_party, start_time, end_time) VALUES
(1, 1, '2023-11-01 10:00:00', '2023-11-01 10:10:00'),
(2, 1, '2023-11-01 10:10:00', '2023-11-01 10:20:00'),
(3, 1, '2023-11-01 10:20:00', '2023-11-01 10:30:00');

PRINT 'Environnement de test préparé avec succès!';

-- =========================================================================
-- TEST DES FONCTIONS
-- =========================================================================

PRINT '---Test de random_position---';
SELECT * FROM dbo.random_position(10, 10, 1);

PRINT '---Test de random_role---';
PRINT 'Role aléatoire: ';
SELECT description_role FROM roles WHERE id_role = dbo.random_role(2);

-- =========================================================================
-- TEST DES PROCEDURES
-- =========================================================================

PRINT '---Test de USERNAME_TO_LOWER---';
UPDATE players SET pseudo = 'UPPERCASE_USER' WHERE id_player = 1;
EXEC USERNAME_TO_LOWER;
SELECT pseudo FROM players WHERE id_player = 1;

PRINT '---Test de SEED_DATA pour une nouvelle partie---';
INSERT INTO parties (id_party, title_party) VALUES (2, 'Partie générée automatiquement');
EXEC SEED_DATA 6, 2;

-- Vérification des données générées
SELECT COUNT(*) AS 'Nombre de joueurs dans la partie 2' FROM players_in_parties WHERE id_party = 2;
SELECT COUNT(*) AS 'Nombre de tours dans la partie 2' FROM turns WHERE id_party = 2;

-- Distribution des rôles
SELECT r.description_role, COUNT(*) AS 'Nombre'
FROM players_in_parties pip
JOIN roles r ON pip.id_role = r.id_role
WHERE pip.id_party = 2
GROUP BY r.description_role;

PRINT '---Test de COMPLETE_TOUR---';
-- Générons des actions pour la première partie

-- Actions du premier tour: un loup et un villageois sur la même case
INSERT INTO players_play 
(id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
-- Alice (loup) se déplace vers (5,5)
(1, 1, '2023-11-01 10:01:00', '2023-11-01 10:02:00', 'move', '1', '1', '5', '5'),
-- Charlie (villageois) se déplace aussi vers (5,5) -> devrait être éliminé
(3, 1, '2023-11-01 10:03:00', '2023-11-01 10:04:00', 'move', '2', '2', '5', '5'),
-- Autres joueurs à des positions différentes
(2, 1, '2023-11-01 10:02:00', '2023-11-01 10:03:00', 'move', '1', '2', '6', '6'),
(4, 1, '2023-11-01 10:04:00', '2023-11-01 10:05:00', 'move', '2', '3', '7', '7'),
(5, 1, '2023-11-01 10:05:00', '2023-11-01 10:06:00', 'move', '3', '3', '8', '8');

-- Exécution de COMPLETE_TOUR pour le premier tour
EXEC COMPLETE_TOUR 1, 1;

-- Vérification: Charlie devrait être éliminé
PRINT 'État après le premier tour (Charlie devrait être éliminé):';
SELECT p.id_player, p.pseudo, r.description_role, pip.is_alive 
FROM players p 
JOIN players_in_parties pip ON p.id_player = pip.id_player 
JOIN roles r ON pip.id_role = r.id_role
WHERE pip.id_party = 1
ORDER BY p.id_player;

-- =========================================================================
-- TEST DES TRIGGERS
-- =========================================================================

PRINT '---Test du trigger d''équilibre loup/villageois---';
PRINT 'Tentative de créer une partie avec trop de loups:';

BEGIN TRY
    -- Créer une nouvelle partie
    INSERT INTO parties (id_party, title_party) VALUES (3, 'Partie déséquilibrée');
    
    -- Ajouter trop de loups (>40%)
    INSERT INTO players_in_parties (id_party, id_player, id_role, is_alive) VALUES
    (3, 1, 2, 'yes'), -- loup
    (3, 2, 2, 'yes'), -- loup
    (3, 3, 2, 'yes'), -- loup
    (3, 4, 1, 'yes'), -- villageois
    (3, 5, 1, 'yes'); -- villageois
    
    PRINT 'ÉCHEC: Le trigger n''a pas empêché le déséquilibre!';
END TRY
BEGIN CATCH
    PRINT 'SUCCÈS: Le trigger a correctement empêché le déséquilibre: ' + ERROR_MESSAGE();
END CATCH;

-- Test du trigger de validation des temps d'action
PRINT '---Test du trigger de validation temporelle des actions---';
PRINT 'Tentative de créer une action en dehors du temps du tour:';

BEGIN TRY
    -- Créer une action hors limites temporelles
    INSERT INTO players_play 
    (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col)
    VALUES 
    (6, 1, '2023-11-01 09:55:00', '2023-11-01 10:01:00', 'move', '4', '4', '9', '9');
    
    PRINT 'ÉCHEC: Le trigger n''a pas empêché l''action hors limites!';
END TRY
BEGIN CATCH
    PRINT 'SUCCÈS: Le trigger a correctement empêché l''action hors limites: ' + ERROR_MESSAGE();
END CATCH;

-- =========================================================================
-- TEST DES VUES ET COMPLÉTION DE PARTIE
-- =========================================================================

-- Ajout d'actions supplémentaires pour tester les vues
INSERT INTO players_play 
(id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
-- Tour 2 - Un loup (Alice) et un villageois (David) sur la même case (6,7)
(1, 2, '2023-11-01 10:11:00', '2023-11-01 10:12:00', 'move', '5', '5', '6', '7'),
(2, 2, '2023-11-01 10:12:00', '2023-11-01 10:13:00', 'move', '6', '6', '6', '8'),
(4, 2, '2023-11-01 10:13:00', '2023-11-01 10:14:00', 'move', '7', '7', '6', '7'), -- David rencontre Alice (loup)
(5, 2, '2023-11-01 10:14:00', '2023-11-01 10:15:00', 'move', '8', '8', '7', '8'),
-- Tour 3 - Loups Alice et Bob sur même case (7,7) où se trouve Eve (villageoise)
(1, 3, '2023-11-01 10:21:00', '2023-11-01 10:22:00', 'move', '6', '7', '7', '7'),
(2, 3, '2023-11-01 10:22:00', '2023-11-01 10:23:00', 'move', '6', '8', '7', '7'),
(5, 3, '2023-11-01 10:23:00', '2023-11-01 10:24:00', 'move', '7', '8', '7', '7');

-- Exécution de COMPLETE_TOUR pour les tours 2 et 3
EXEC COMPLETE_TOUR 2, 1;
PRINT 'État après le deuxième tour (David devrait être éliminé):';
SELECT p.id_player, p.pseudo, r.description_role, pip.is_alive 
FROM players p 
JOIN players_in_parties pip ON p.id_player = pip.id_player 
JOIN roles r ON pip.id_role = r.id_role
WHERE pip.id_party = 1
ORDER BY p.id_player;

EXEC COMPLETE_TOUR 3, 1;
PRINT 'État après le troisième tour (Eve devrait être éliminée):';
SELECT p.id_player, p.pseudo, r.description_role, pip.is_alive 
FROM players p 
JOIN players_in_parties pip ON p.id_player = pip.id_player 
JOIN roles r ON pip.id_role = r.id_role
WHERE pip.id_party = 1
ORDER BY p.id_player;

-- Test de la vue ALL_PLAYERS
PRINT '---Test de ALL_PLAYERS---';
SELECT * FROM ALL_PLAYERS;

-- Test de la vue ALL_PLAYERS_ELAPSED_GAME
PRINT '---Test de ALL_PLAYERS_ELAPSED_GAME---';
SELECT * FROM ALL_PLAYERS_ELAPSED_GAME;

-- Maintenant que la partie est bien avancée, testons get_the_winner
PRINT '---Test de get_the_winner---';
SELECT * FROM get_the_winner(1);

-- =========================================================================
-- TEST D'UN SCÉNARIO COMPLET AUTOMATIQUE
-- =========================================================================

PRINT '---Test d''un scénario complet avec SEED_DATA---';

-- Nettoyage pour un nouveau scénario
DELETE FROM players_play WHERE id_turn IN (SELECT id_turn FROM turns WHERE id_party = 4);
DELETE FROM players_in_parties WHERE id_party = 4;
DELETE FROM turns WHERE id_party = 4;
DELETE FROM parties WHERE id_party = 4;

-- Nouvelle partie complètement automatisée
INSERT INTO parties (id_party, title_party) VALUES (4, 'Partie automatique complète');

-- Génération de la partie avec SEED_DATA - 8 joueurs
EXEC SEED_DATA 8, 4;

-- Affichage des joueurs et leurs rôles
PRINT 'Joueurs et rôles dans la partie automatique:';
SELECT p.id_player, p.pseudo, r.description_role
FROM players p 
JOIN players_in_parties pip ON p.id_player = pip.id_player
JOIN roles r ON pip.id_role = r.id_role
WHERE pip.id_party = 4
ORDER BY p.id_player;

-- Création de quelques mouvements aléatoires pour la simulation
-- Note: Dans un vrai test, il faudrait générer des actions plus complexes

-- Récupération du nombre de tours
DECLARE @max_tour INT;
SELECT @max_tour = MAX(id_turn) FROM turns WHERE id_party = 4;

-- Simulation de l'exécution de tous les tours
DECLARE @current_tour INT = 1;
WHILE @current_tour <= @max_tour
BEGIN
    PRINT '---Tour ' + CAST(@current_tour AS NVARCHAR(2)) + ' de la partie automatique---';
    
    -- Génération d'actions aléatoires pour le tour courant 
    -- (version simplifiée pour l'exemple - vous pourriez implémenter une logique plus complexe)
    INSERT INTO players_play 
    (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col)
    SELECT pip.id_player, @current_tour, 
           DATEADD(MINUTE, pip.id_player, (SELECT start_time FROM turns WHERE id_turn = @current_tour)),
           DATEADD(MINUTE, pip.id_player + 1, (SELECT start_time FROM turns WHERE id_turn = @current_tour)),
           'move', 
           pip.id_player % 5 + 1,     -- position d'origine ligne (1-5)
           pip.id_player % 4 + 1,     -- position d'origine colonne (1-4)
           (pip.id_player * 3) % 10 + 1, -- position cible ligne (1-10)
           (pip.id_player * 2) % 10 + 1  -- position cible colonne (1-10)
    FROM players_in_parties pip
    WHERE pip.id_party = 4 AND pip.is_alive = 'yes';
    
    -- Exécution de COMPLETE_TOUR pour le tour courant
    EXEC COMPLETE_TOUR @current_tour, 4;
    
    -- Affichage de l'état après chaque tour
    PRINT 'État après le tour ' + CAST(@current_tour AS NVARCHAR(2)) + ':';
    SELECT p.id_player, p.pseudo, r.description_role, pip.is_alive
    FROM players p 
    JOIN players_in_parties pip ON p.id_player = pip.id_player
    JOIN roles r ON pip.id_role = r.id_role
    WHERE pip.id_party = 4
    ORDER BY p.id_player;
    
    -- Comptage des joueurs restants
    DECLARE @remaining_villagers INT, @remaining_wolves INT;
    SELECT @remaining_villagers = COUNT(*) 
    FROM players_in_parties 
    WHERE id_party = 4 AND is_alive = 'yes' AND id_role = 1;
    
    SELECT @remaining_wolves = COUNT(*) 
    FROM players_in_parties 
    WHERE id_party = 4 AND is_alive = 'yes' AND id_role = 2;
    
    PRINT 'Villageois restants: ' + CAST(@remaining_villagers AS NVARCHAR(2)) + 
          ' / Loups restants: ' + CAST(@remaining_wolves AS NVARCHAR(2));
    
    -- Vérifier si la partie est finie
    IF (@remaining_villagers = 0 OR @remaining_wolves = 0)
    BEGIN
        PRINT 'La partie est terminée au tour ' + CAST(@current_tour AS NVARCHAR(2));
        BREAK;
    END
    
    SET @current_tour = @current_tour + 1;
END

-- Affichage du vainqueur
PRINT '---Vainqueur de la partie automatique---';
SELECT * FROM get_the_winner(4);

-- Test final des vues après la partie complète
PRINT '---Statistiques des joueurs après la partie automatique---';
SELECT * FROM ALL_PLAYERS 
WHERE [nom du joueur] IN (
    SELECT pseudo FROM players
    JOIN players_in_parties ON players.id_player = players_in_parties.id_player
    WHERE id_party = 4
);

PRINT '---Temps de jeu par joueur pour la partie automatique---';
SELECT * FROM ALL_PLAYERS_ELAPSED_GAME 
WHERE [nom du joueur] IN (
    SELECT pseudo FROM players
    JOIN players_in_parties ON players.id_player = players_in_parties.id_player
    WHERE id_party = 4
);

PRINT 'Tests terminés avec succès!';
