-- wv_views.sql
USE loupgaroudb;

-- Vue ALL_PLAYERS qui affiche l'ensemble des joueurs ayant participé à au moins une partie
CREATE OR ALTER VIEW ALL_PLAYERS AS
SELECT
    p.pseudo AS 'nom du joueur',
    COUNT(DISTINCT pip.id_party) AS 'nombre de parties jouées',
    COUNT(pp.id_player) AS 'nombre de tours joués',
    MIN(pp.start_time) AS 'date et heure de la première participation',
    MAX(pp.end_time) AS 'date et heure de la dernière action'
FROM
    players p
JOIN 
    players_in_parties pip ON p.id_player = pip.id_player
JOIN 
    players_play pp ON p.id_player = pp.id_player
GROUP BY
    p.pseudo
ORDER BY
    COUNT(DISTINCT pip.id_party) DESC,
    MIN(pp.start_time),
    MAX(pp.end_time),
    p.pseudo;

-- Vue ALL_PLAYERS_ELAPSED_GAME : nombre de secondes écoulées pour chaque partie jouée par joueur
CREATE OR ALTER VIEW ALL_PLAYERS_ELAPSED_GAME AS
SELECT
    p.pseudo AS 'nom du joueur',
    pa.title_party AS 'nom de la partie',
    (SELECT COUNT(*) FROM players_in_parties WHERE id_party = pa.id_party) AS 'nombre de participants',
    (SELECT MIN(pp2.start_time) 
     FROM players_play pp2 
     JOIN turns t2 ON pp2.id_turn = t2.id_turn 
     WHERE pp2.id_player = p.id_player AND t2.id_party = pa.id_party) AS 'date et heure de la première action du joueur',
    (SELECT MAX(pp3.end_time) 
     FROM players_play pp3 
     JOIN turns t3 ON pp3.id_turn = t3.id_turn 
     WHERE pp3.id_player = p.id_player AND t3.id_party = pa.id_party) AS 'date et heure de la dernière action du joueur',
    DATEDIFF(SECOND, 
        (SELECT MIN(pp4.start_time) 
         FROM players_play pp4 
         JOIN turns t4 ON pp4.id_turn = t4.id_turn 
         WHERE pp4.id_player = p.id_player AND t4.id_party = pa.id_party),
        (SELECT MAX(pp5.end_time) 
         FROM players_play pp5 
         JOIN turns t5 ON pp5.id_turn = t5.id_turn 
         WHERE pp5.id_player = p.id_player AND t5.id_party = pa.id_party)
    ) AS 'nb de secondes passées dans la partie pour le joueur'
FROM
    players p
JOIN
    players_in_parties pip ON p.id_player = pip.id_player
JOIN
    parties pa ON pip.id_party = pa.id_party
WHERE
    EXISTS (
        SELECT 1 
        FROM players_play pp 
        JOIN turns t ON pp.id_turn = t.id_turn 
        WHERE pp.id_player = p.id_player AND t.id_party = pa.id_party
    );
