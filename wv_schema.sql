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

-- Création des tables
create table parties (
    id_party int,
    title_party text
);

create table roles (
    id_role int,
    description_role text
);

create table players (
    id_player int,
    pseudo text
);

create table players_in_parties (
    id_party int,
    id_player int,
    id_role int,
    is_alive text
);

create table turns (
    id_turn int,
    id_party int,
    start_time datetime,
    end_time datetime
);

create table players_play (
    id_player int,
    id_turn int,
    start_time datetime,
    end_time datetime,
    action varchar(10),
    origin_position_col text,
    origin_position_row text,
    target_position_col text,
    target_position_row text
);
GO
