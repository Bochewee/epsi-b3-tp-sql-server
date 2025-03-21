# TP Werewolf Village - SQL Server

## Membres du groupe
- Florian Huguet 
- Nicolas Ravelojaona

## Description du projet
Ce projet implémente une base de données pour un jeu de loup-garou multijoueur tour par tour. L'objectif est de gérer les parties, les joueurs, leurs rôles (loup ou villageois) et leurs actions dans le jeu conformément aux règles spécifiées dans le TP noté "Langage SQL et SGBD SQL Server".

## Structure des fichiers
- `wv_schema.sql` : Schéma initial de la base de données (fourni)
- `wv_index.sql` : Définition et optimisation des index
- `wv_views.sql` : Définition des vues demandées (ALL_PLAYERS, ALL_PLAYERS_ELAPSED_GAME)
- `wv_functions.sql` : Fonctions SQL (random_position, random_role, get_the_winner)
- `wv_procs.sql` : Procédures stockées
- `wv_triggers.sql` : Déclencheurs pour garantir l'intégrité des données
- `wv_data.sql` : Données de test
- `wv_test.sql` : Scripts de test pour valider nos implémentations

## Fonctionnalités implémentées

### Vues
1. `ALL_PLAYERS` : Affiche tous les joueurs ayant participé à au moins une partie, avec le nombre de parties, de tours, et les dates de participation.
2. `ALL_PLAYERS_ELAPSED_GAME` : Calcule le temps passé par chaque joueur dans chaque partie.

### Fonctions
1. `random_position()` : Génère une position aléatoire (ligne, colonne) qui n'a jamais été utilisée dans une partie donnée.
2. `random_role()` : Attribution équilibrée des rôles (loup, villageois) selon les quotas définis.
3. `get_the_winner()` : Renvoie les informations sur le vainqueur d'une partie spécifique.

### Procédures stockées
Des procédures pour gérer les inscriptions, les déplacements et les actions des joueurs.

### Triggers
Triggers pour maintenir l'intégrité des données et automatiser certains processus du jeu.

### Optimisation
Indexes et contraintes pour optimiser les performances de la base de données.
