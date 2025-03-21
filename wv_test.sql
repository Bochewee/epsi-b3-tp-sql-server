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
INSERT INTO parties (id_party, title_party, start_time) VALUES
(1, 'Partie de test 1', GETDATE());

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

-- Ajout des actions des joueurs pour le tour 1
INSERT INTO players_play (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
-- Les loups se déplacent vers les villageois
(1, 1, '2023-11-01 10:01:00', '2023-11-01 10:02:00', 'move', 1, 1, 2, 2),
(2, 1, '2023-11-01 10:01:30', '2023-11-01 10:02:30', 'move', 1, 3, 2, 4),
-- Les villageois se déplacent
(3, 1, '2023-11-01 10:02:00', '2023-11-01 10:03:00', 'move', 3, 1, 4, 1),
(4, 1, '2023-11-01 10:02:30', '2023-11-01 10:03:30', 'move', 3, 3, 4, 3),
(5, 1, '2023-11-01 10:03:00', '2023-11-01 10:04:00', 'move', 5, 1, 6, 1),
(6, 1, '2023-11-01 10:03:30', '2023-11-01 10:04:30', 'move', 5, 3, 6, 3),
(7, 1, '2023-11-01 10:04:00', '2023-11-01 10:05:00', 'move', 7, 1, 8, 1),
(8, 1, '2023-11-01 10:04:30', '2023-11-01 10:05:30', 'move', 7, 3, 8, 3);

-- Ajout des actions des joueurs pour le tour 2
INSERT INTO players_play (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
-- Le loup Alice se déplace vers Charlie (un villageois)
(1, 2, '2023-11-01 10:11:00', '2023-11-01 10:12:00', 'move', 2, 2, 4, 1),
-- Le loup Bob se déplace
(2, 2, '2023-11-01 10:11:30', '2023-11-01 10:12:30', 'move', 2, 4, 3, 5),
-- Les villageois se déplacent
(3, 2, '2023-11-01 10:12:00', '2023-11-01 10:13:00', 'move', 4, 1, 4, 2), -- Charlie s'échappe
(4, 2, '2023-11-01 10:12:30', '2023-11-01 10:13:30', 'move', 4, 3, 5, 4),
(5, 2, '2023-11-01 10:13:00', '2023-11-01 10:14:00', 'move', 6, 1, 7, 2),
(6, 2, '2023-11-01 10:13:30', '2023-11-01 10:14:30', 'move', 6, 3, 7, 4),
(7, 2, '2023-11-01 10:14:00', '2023-11-01 10:15:00', 'hide', 8, 1, 8, 1), -- Grace reste cachée
(8, 2, '2023-11-01 10:14:30', '2023-11-01 10:15:30', 'move', 8, 3, 9, 4);

-- Ajout des actions des joueurs pour le tour 3
-- Dans ce tour, un loup va rencontrer un villageois
INSERT INTO players_play (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
-- Le loup Alice se déplace vers la position de Charlie
(1, 3, '2023-11-01 10:21:00', '2023-11-01 10:22:00', 'attack', 4, 1, 4, 2),
-- Le loup Bob se déplace vers la position d'Eve
(2, 3, '2023-11-01 10:21:30', '2023-11-01 10:22:30', 'attack', 3, 5, 5, 4),
-- Les villageois se déplacent
(3, 3, '2023-11-01 10:22:00', '2023-11-01 10:23:00', 'move', 4, 2, 4, 2), -- Charlie reste sur place (pas de chance)
(4, 3, '2023-11-01 10:22:30', '2023-11-01 10:23:30', 'move', 5, 4, 6, 5),
(5, 3, '2023-11-01 10:23:00', '2023-11-01 10:24:00', 'move', 7, 2, 8, 2),
(6, 3, '2023-11-01 10:23:30', '2023-11-01 10:24:30', 'move', 7, 4, 8, 5),
(7, 3, '2023-11-01 10:24:00', '2023-11-01 10:25:00', 'defend', 8, 1, 8, 1), -- Grace est toujours cachée
(8, 3, '2023-11-01 10:24:30', '2023-11-01 10:25:30', 'move', 9, 4, 10, 5);

PRINT 'Environnement de test préparé avec succès!';

-- =========================================================================
-- TEST DES VUES
-- =========================================================================

PRINT '---Test de la vue ALL_PLAYERS---';
SELECT * FROM ALL_PLAYERS;

PRINT '---Test de la vue ALL_PLAYERS_ELAPSED_GAME---';
SELECT * FROM ALL_PLAYERS_ELAPSED_GAME;

-- =========================================================================
-- TEST DES FONCTIONS
-- =========================================================================

PRINT '---Test de random_position---';
SELECT * FROM dbo.random_position(10, 10, 1);

PRINT '---Test de random_role---';
PRINT 'Role aléatoire: ';
SELECT description_role FROM roles WHERE id_role = dbo.random_role(1);

PRINT '---Test de get_the_winner---';
-- D'abord, on simule une fin de partie (victoire des loups)
UPDATE players_in_parties
SET is_alive = 'no'
WHERE id_party = 1 AND id_role = 1;

UPDATE parties
SET end_time = GETDATE(),
    winner = 'loup'
WHERE id_party = 1;

-- Afficher les vainqueurs
SELECT * FROM dbo.get_the_winner(1);

-- =========================================================================
-- TEST DES PROCEDURES
-- =========================================================================

PRINT '---Test de USERNAME_TO_LOWER---';
UPDATE players SET pseudo = 'UPPERCASE_USER' WHERE id_player = 1;
EXEC USERNAME_TO_LOWER;
SELECT pseudo FROM players WHERE id_player = 1;

PRINT '---Test de SEED_DATA pour une nouvelle partie---';
INSERT INTO parties (id_party, title_party, start_time) VALUES (2, 'Partie générée automatiquement', GETDATE());
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
-- Créons une nouvelle partie pour tester COMPLETE_TOUR

INSERT INTO parties (id_party, title_party, start_time) VALUES
(3, 'Partie pour tester COMPLETE_TOUR', GETDATE());

-- Ajoutons 4 joueurs: 1 loup et 3 villageois
INSERT INTO players_in_parties (id_party, id_player, id_role, is_alive) VALUES
(3, 1, 2, 'yes'), -- Alice est un loup
(3, 3, 1, 'yes'), -- Charlie est un villageois
(3, 4, 1, 'yes'), -- David est un villageois
(3, 5, 1, 'yes'); -- Eve est un villageois

-- Créons un tour
INSERT INTO turns (id_turn, id_party, start_time, end_time) VALUES
(4, 3, GETDATE(), NULL); -- Tour non terminé

-- Ajoutons des actions où le loup et un villageois finissent au même endroit
INSERT INTO players_play (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
(1, 4, DATEADD(MINUTE, 1, GETDATE()), DATEADD(MINUTE, 2, GETDATE()), 'move', 1, 1, 5, 5), -- Le loup va en (5,5)
(3, 4, DATEADD(MINUTE, 1, GETDATE()), DATEADD(MINUTE, 2, GETDATE()), 'move', 2, 2, 5, 5); -- Charlie va aussi en (5,5) - il va mourir

-- Maintenant terminons le tour pour déclencher COMPLETE_TOUR via le
-- Maintenant terminons le tour pour déclencher COMPLETE_TOUR via le trigger
UPDATE turns 
SET end_time = DATEADD(MINUTE, 10, GETDATE())
WHERE id_turn = 4;

-- Vérifions si Charlie (id_player = 3) est bien marqué comme mort
SELECT id_player, pseudo, is_alive 
FROM players_in_parties pip
JOIN players p ON pip.id_player = p.id_player
WHERE pip.id_party = 3;

-- =========================================================================
-- TEST DES TRIGGERS
-- =========================================================================

PRINT '---Test de trg_username_to_lower---';
-- On a déjà vu ce trigger en action plus haut

PRINT '---Test de trg_complete_tour---';
-- Créons un autre tour pour tester encore le trigger
INSERT INTO turns (id_turn, id_party, start_time, end_time) VALUES
(5, 3, DATEADD(MINUTE, 10, GETDATE()), NULL); -- Tour suivant non terminé

-- Ajoutons des actions où le loup et un autre villageois finissent au même endroit
INSERT INTO players_play (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
(1, 5, DATEADD(MINUTE, 11, GETDATE()), DATEADD(MINUTE, 12, GETDATE()), 'move', 5, 5, 7, 7), -- Le loup va en (7,7)
(4, 5, DATEADD(MINUTE, 11, GETDATE()), DATEADD(MINUTE, 12, GETDATE()), 'move', 3, 3, 7, 7); -- David va aussi en (7,7) - il va mourir

-- Terminons ce tour 
UPDATE turns 
SET end_time = DATEADD(MINUTE, 20, GETDATE())
WHERE id_turn = 5;

-- Vérifions si David (id_player = 4) est bien marqué comme mort
SELECT id_player, pseudo, is_alive 
FROM players_in_parties pip
JOIN players p ON pip.id_player = p.id_player
WHERE pip.id_party = 3;

-- Créons un dernier tour pour éliminer le dernier villageois
INSERT INTO turns (id_turn, id_party, start_time, end_time) VALUES
(6, 3, DATEADD(MINUTE, 20, GETDATE()), NULL);

INSERT INTO players_play (id_player, id_turn, start_time, end_time, action, origin_position_row, origin_position_col, target_position_row, target_position_col) VALUES
(1, 6, DATEADD(MINUTE, 21, GETDATE()), DATEADD(MINUTE, 22, GETDATE()), 'move', 7, 7, 9, 9), -- Le loup va en (9,9)
(5, 6, DATEADD(MINUTE, 21, GETDATE()), DATEADD(MINUTE, 22, GETDATE()), 'move', 4, 4, 9, 9); -- Eve va aussi en (9,9) - dernier villageois

-- Terminons ce dernier tour
UPDATE turns 
SET end_time = DATEADD(MINUTE, 30, GETDATE())
WHERE id_turn = 6;

-- Vérifions si tous les villageois sont morts et que la partie est marquée comme terminée
SELECT id_player, pseudo, is_alive 
FROM players_in_parties pip
JOIN players p ON pip.id_player = p.id_player
WHERE pip.id_party = 3;

-- Vérifier si la partie est marquée comme terminée avec la victoire des loups
SELECT id_party, title_party, winner, end_time 
FROM parties
WHERE id_party = 3;

PRINT 'Tous les tests ont été exécutés avec succès!';
