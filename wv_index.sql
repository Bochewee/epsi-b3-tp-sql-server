USE loupgaroudb;
GO

-- Ajout des clés primaires
ALTER TABLE players ADD CONSTRAINT PK_players PRIMARY KEY (id_player);
ALTER TABLE roles ADD CONSTRAINT PK_roles PRIMARY KEY (id_role);
ALTER TABLE parties ADD CONSTRAINT PK_parties PRIMARY KEY (id_party);
ALTER TABLE turns ADD CONSTRAINT PK_turns PRIMARY KEY (id_turn);
ALTER TABLE players_in_parties ADD CONSTRAINT PK_players_in_parties PRIMARY KEY (id_player, id_party);
ALTER TABLE players_play ADD CONSTRAINT PK_players_play PRIMARY KEY (id_player, id_turn);

-- Ajout des clés étrangères
ALTER TABLE players_in_parties 
ADD CONSTRAINT FK_players_in_parties_players 
FOREIGN KEY (id_player) REFERENCES players(id_player);

ALTER TABLE players_in_parties 
ADD CONSTRAINT FK_players_in_parties_parties 
FOREIGN KEY (id_party) REFERENCES parties(id_party);

ALTER TABLE players_in_parties 
ADD CONSTRAINT FK_players_in_parties_roles 
FOREIGN KEY (id_role) REFERENCES roles(id_role);

ALTER TABLE turns 
ADD CONSTRAINT FK_turns_parties 
FOREIGN KEY (id_party) REFERENCES parties(id_party);

ALTER TABLE players_play 
ADD CONSTRAINT FK_players_play_players 
FOREIGN KEY (id_player) REFERENCES players(id_player);

ALTER TABLE players_play 
ADD CONSTRAINT FK_players_play_turns 
FOREIGN KEY (id_turn) REFERENCES turns(id_turn);

-- Création d'index pour optimiser les requêtes
CREATE INDEX IDX_players_pseudo ON players(pseudo);
CREATE INDEX IDX_parties_status ON parties(end_time);
CREATE INDEX IDX_turns_times ON turns(start_time, end_time);
CREATE INDEX IDX_players_in_parties_status ON players_in_parties(is_alive);
CREATE INDEX IDX_players_play_action ON players_play(action);
CREATE INDEX IDX_players_play_position ON players_play(target_position_row, target_position_col);

-- Contraintes d'intégrité supplémentaires
ALTER TABLE parties ADD CONSTRAINT CHK_parties_winner CHECK (winner IN ('werewolf', 'villager', NULL));
ALTER TABLE players_in_parties ADD CONSTRAINT CHK_players_in_parties_is_alive CHECK (is_alive IN (0, 1));
ALTER TABLE players_play ADD CONSTRAINT CHK_players_play_action CHECK (action IN ('move', 'vote'));

-- Contraintes temporelles
ALTER TABLE turns ADD CONSTRAINT CHK_turns_times 
CHECK (end_time IS NULL OR start_time < end_time);

ALTER TABLE players_play ADD CONSTRAINT CHK_players_play_times 
CHECK (end_time IS NULL OR start_time < end_time);
GO
