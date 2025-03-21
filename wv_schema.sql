USE loupgaroudb;
GO

-- Suppression des tables existantes (dans l'ordre inverse des dépendances)
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'players_play')
    DROP TABLE players_play;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'turns')
    DROP TABLE turns;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'players_in_parties')
    DROP TABLE players_in_parties;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'players')
    DROP TABLE players;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'roles')
    DROP TABLE roles;
IF EXISTS (SELECT * FROM sys.tables WHERE name = 'parties')
    DROP TABLE parties;
GO

-- Création des tables avec types corrects
CREATE TABLE parties (
    id_party INT,
    title_party VARCHAR(255),
    winner VARCHAR(20),  -- Ajouté pour la contrainte CHK_parties_winner
    end_time DATETIME    -- Ajouté pour l'index IDX_parties_status
);

CREATE TABLE roles (
    id_role INT,
    description_role VARCHAR(255)
);

CREATE TABLE players (
    id_player INT,
    pseudo VARCHAR(100)  -- Changé de TEXT à VARCHAR pour pouvoir l'indexer
);

CREATE TABLE players_in_parties (
    id_party INT,
    id_player INT,
    id_role INT,
    is_alive BIT         -- Changé de TEXT à BIT pour la contrainte
);

CREATE TABLE turns (
    id_turn INT,
    id_party INT,
    start_time DATETIME,
    end_time DATETIME
);

CREATE TABLE players_play (
    id_player INT,
    id_turn INT,
    start_time DATETIME,
    end_time DATETIME,
    action VARCHAR(10),
    origin_position_col INT,  -- Changé de TEXT à INT
    origin_position_row INT,  -- Changé de TEXT à INT
    target_position_col INT,  -- Changé de TEXT à INT
    target_position_row INT   -- Changé de TEXT à INT pour l'index
);
GO
