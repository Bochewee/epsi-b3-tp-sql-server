-- wv_views.sql
USE loupgaroudb;

-- Vue ALL_PLAYERS
CREATE OR ALTER VIEW ALL_PLAYERS AS
SELECT 
    p.pseudo AS 'nom du joueur',
    COUNT(DISTINCT pip.id_party) AS 'nombre de parties jouées',
    COUNT(DISTINCT pp.id_turn) AS 'nombre de tours joués',
    MIN(t.start_time) AS 'date et heure de la première participation',
    MAX(pp.end_time) AS 'date et heure de la dernière action'
FROM 
    players p
    JOIN players_in_parties pip ON p.id_player = pip.id_player
    JOIN players_play pp ON p.id_player = pp.id_player
    JOIN turns t ON pp.id_turn = t.id_turn
GROUP BY 
    p.id_player, p.pseudo
ORDER BY 
    COUNT(DISTINCT pip.id_party) DESC,
    MIN(t.start_time) ASC,
    MAX(pp.end_time) DESC,
    p.pseudo ASC;

-- Vue ALL_PLAYERS_ELAPSED_GAME
CREATE OR ALTER VIEW ALL_PLAYERS_ELAPSED_GAME AS
SELECT 
    p.pseudo AS 'nom du joueur',
    party.title_party AS 'nom de la partie',
    (SELECT COUNT(*) FROM players_in_parties WHERE id_party = pip.id_party) AS 'nombre de participants',
    MIN(pp.start_time) AS 'date et heure de la première action du joueur dans la partie',
    MAX(pp.end_time) AS 'date et heure de la dernière action du joueur dans la partie',
    DATEDIFF(SECOND, MIN(pp.start_time), MAX(pp.end_time)) AS 'nb de secondes passées dans la partie pour le joueur'
FROM 
    players p
    JOIN players_in_parties pip ON p.id_player = pip.id_player
    JOIN parties party ON pip.id_party = party.id_party
    JOIN players_play pp ON p.id_player = pp.id_player
    JOIN turns t ON pp.id_turn = t.id_turn AND t.id_party = pip.id_party
GROUP BY 
    p.id_player, p.pseudo, party.id_party, party.title_party, pip.id_party;
