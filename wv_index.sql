-- wv_index.sql
USE loupgaroudb;

-- Ajout des clés primaires
ALTER TABLE parties ADD CONSTRAINT PK_parties PRIMARY KEY (id_party);
ALTER TABLE roles ADD CONSTRAINT PK_roles PRIMARY KEY (id_role);
ALTER TABLE players ADD CONSTRAINT PK_players PRIMARY KEY (id_player);
ALTER TABLE turns ADD CONSTRAINT PK_turns PRIMARY KEY (id_turn);

-- Ajout des clés étrangères pour players_in_parties
ALTER TABLE players_in_parties ADD CONSTRAINT PK_players_in_parties PRIMARY KEY (id_party, id_player);
ALTER TABLE players_in_parties ADD CONSTRAINT FK_players_in_parties_party FOREIGN KEY (id_party) REFERENCES parties (id_party);
ALTER TABLE players_in_parties ADD CONSTRAINT FK_players_in_parties_player FOREIGN KEY (id_player) REFERENCES players (id_player);
ALTER TABLE players_in_parties ADD CONSTRAINT FK_players_in_parties_role FOREIGN KEY (id_role) REFERENCES roles (id_role);

-- Ajout des clés étrangères pour turns
ALTER TABLE turns ADD CONSTRAINT FK_turns_party FOREIGN KEY (id_party) REFERENCES parties (id_party);

-- Ajout des clés étrangères et primaires pour players_play
ALTER TABLE players_play ADD CONSTRAINT PK_players_play PRIMARY KEY (id_player, id_turn);
ALTER TABLE players_play ADD CONSTRAINT FK_players_play_player FOREIGN KEY (id_player) REFERENCES players (id_player);
ALTER TABLE players_play ADD CONSTRAINT FK_players_play_turn FOREIGN KEY (id_turn) REFERENCES turns (id_turn);

-- Ajout d'index pour améliorer les performances
CREATE INDEX idx_players_pseudo ON players(pseudo);
CREATE INDEX idx_players_in_parties_role ON players_in_parties(id_role);
CREATE INDEX idx_players_in_parties_alive ON players_in_parties(is_alive);
CREATE INDEX idx_turns_party ON turns(id_party);
CREATE INDEX idx_turns_times ON turns(start_time, end_time);
CREATE INDEX idx_players_play_times ON players_play(start_time, end_time);
CREATE INDEX idx_players_play_positions ON players_play(origin_position_col, origin_position_row, target_position_col, target_position_row);

-- Ajout de contraintes pour garantir la validité des données
-- Contrainte pour que is_alive soit 'yes' ou 'no'
ALTER TABLE players_in_parties ADD CONSTRAINT CHK_players_in_parties_alive CHECK (is_alive IN ('yes', 'no'));

-- Contrainte pour que l'action soit valide (supposons que les actions valides sont 'move', 'attack', 'defend', etc.)
ALTER TABLE players_play ADD CONSTRAINT CHK_players_play_action CHECK (action IN ('move', 'attack', 'defend', 'hide', 'vote'));

-- Contrainte pour assurer que les temps de fin sont après les temps de début
ALTER TABLE turns ADD CONSTRAINT CHK_turns_times CHECK (end_time > start_time);
ALTER TABLE players_play ADD CONSTRAINT CHK_players_play_times CHECK (end_time > start_time);

-- Contrainte pour assurer que les actions des joueurs se déroulent pendant leur tour
ALTER TABLE players_play ADD CONSTRAINT CHK_players_play_in_turn 
CHECK (NOT EXISTS (
    SELECT 1 FROM turns t 
    WHERE players_play.id_turn = t.id_turn 
    AND (players_play.start_time < t.start_time OR players_play.end_time > t.end_time)
));