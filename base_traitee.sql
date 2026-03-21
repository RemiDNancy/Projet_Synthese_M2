-- Création de la base
CREATE DATABASE IF NOT EXISTS base_traitee;
USE base_traitee;
DROP TABLE IF EXISTS Fait_projet_snapshot;
DROP TABLE IF EXISTS Fait_commentaire;
DROP TABLE IF EXISTS Createur;
DROP TABLE IF EXISTS Categorie;
DROP TABLE IF EXISTS Localisation;
DROP TABLE IF EXISTS Date_dim;
DROP TABLE IF EXISTS Projet;
DROP TABLE IF EXISTS Reward;

-- =========================
-- TABLE DIMENSIONS
-- =========================

CREATE TABLE Categorie (
    nom_categorie VARCHAR(255) NOT NULL PRIMARY KEY,
    nom_categorie_mere VARCHAR(255)
);

CREATE TABLE Createur (
    id_createur VARCHAR(50) PRIMARY KEY,
    nom_createur VARCHAR(255),
    nb_projets INT,
    biographie TEXT,
    est_fb_connected BOOLEAN,
    nb_sites_web INT,
    dernier_login DATETIME
);

CREATE TABLE Localisation (
    id_localisation VARCHAR(255) PRIMARY KEY,
    pays VARCHAR(100),
    region VARCHAR(100),
    ville VARCHAR(100)
);

CREATE TABLE Date_dim (
    id_date INT PRIMARY KEY,
    date_complete DATE,
    annee INT,
    mois INT,
    jour INT,
    semaine INT
);

CREATE TABLE Projet (
    id_projet INT PRIMARY KEY,
    titre_projet VARCHAR(255),
    devise VARCHAR(4),
    objectif_financement DECIMAL(15,2),
    description TEXT,
    url VARCHAR(500),
    url_image VARCHAR(500),
    is_project_we_love BOOLEAN,
    date_creation DATE,
    date_deadline DATE
);

CREATE TABLE Reward (
    id_reward INT PRIMARY KEY,
    nom_reward VARCHAR(255),
    prix DECIMAL(10,2),
    devise VARCHAR(10),
    est_disponible BOOLEAN
);

-- =========================
-- TABLES DE FAITS
-- =========================

CREATE TABLE Fait_projet_snapshot (
    id_fait_projet INT PRIMARY KEY AUTO_INCREMENT,
    id_date_collecte INT,
    id_projet INT,
    id_createur VARCHAR(50),
    categorie VARCHAR(255),
    localisation VARCHAR(255),

    montant_collecte DECIMAL(15,2),
    nombre_contributeurs INT,
    ratio_financement DECIMAL(10,4),
    jours_restants INT,

    reward_backers_count INT,
    reward_quantity_left INT,

    jour_campagne INT,
    delta_montant_1j DECIMAL(15,2),
    delta_contributeurs_1j INT,

    FOREIGN KEY (id_date_collecte) REFERENCES Date_dim(id_date),
    FOREIGN KEY (id_projet) REFERENCES Projet(id_projet),
    FOREIGN KEY (id_createur) REFERENCES Createur(id_createur),
    FOREIGN KEY (categorie) REFERENCES Categorie(nom_categorie),
    FOREIGN KEY (localisation) REFERENCES Localisation(id_localisation)
);

CREATE TABLE Fait_commentaire (
    id_fait_commentaire INT PRIMARY KEY AUTO_INCREMENT,
    id_date_collecte INT,
    id_projet INT,

    score_sentiment DECIMAL(5,2),
    is_creator_reply boolean,

    FOREIGN KEY (id_date_collecte) REFERENCES Date_dim(id_date),
    FOREIGN KEY (id_projet) REFERENCES Projet(id_projet)
);


INSERT INTO Date_dim (id_date, date_complete, annee, mois, jour, semaine)
SELECT 
    DATE_FORMAT(d, '%Y%m%d') AS id_date,
    d AS date_complete,
    YEAR(d) AS annee,
    MONTH(d) AS mois,
    DAY(d) AS jour,
    WEEK(d, 1) AS semaine
FROM (
    WITH RECURSIVE dates AS (
        SELECT DATE('2024-01-01') AS d
        UNION ALL
        SELECT DATE_ADD(d, INTERVAL 1 DAY)
        FROM dates
        WHERE d < DATE('2026-02-09')
    )
    SELECT d FROM dates
) AS all_dates;

ALTER TABLE Fait_commentaire DROP INDEX uq_projet_date;

-- 1. Trouver le nom exact de la FK
SELECT CONSTRAINT_NAME 
FROM information_schema.KEY_COLUMN_USAGE 
WHERE TABLE_NAME = 'Fait_commentaire' 
AND TABLE_SCHEMA = DATABASE()
AND REFERENCED_TABLE_NAME IS NOT NULL;

-- 1. Supprimer les 2 FK
ALTER TABLE Fait_commentaire DROP FOREIGN KEY fait_commentaire_ibfk_1;
ALTER TABLE Fait_commentaire DROP FOREIGN KEY fait_commentaire_ibfk_2;

-- 2. Supprimer l'index
ALTER TABLE Fait_commentaire DROP INDEX uq_projet_date;

-- 3. Remettre les FK
ALTER TABLE Fait_commentaire 
ADD CONSTRAINT fk_fait_date FOREIGN KEY (id_date_collecte) REFERENCES Date_dim(id_date);

ALTER TABLE Fait_commentaire 
ADD CONSTRAINT fk_fait_projet FOREIGN KEY (id_projet) REFERENCES Projet(id_projet);







-- =========================
-- SUPPRESSION (ordre FK)
-- =========================
DROP TABLE IF EXISTS Fait_detail_facteurs;
DROP TABLE IF EXISTS Fait_prediction_projet;
DROP TABLE IF EXISTS Fait_metriques_modele;
DROP TABLE IF EXISTS Modele_AI;

-- =========================
-- DIMENSION
-- =========================
 
CREATE TABLE Modele_AI (
    id_modele          INT          PRIMARY KEY AUTO_INCREMENT,
    nom_modele         VARCHAR(50)  NOT NULL,        -- 'KNN' | 'RandomForest'
    type_algo          VARCHAR(100),                 -- 'KNeighborsTimeSeriesClassifier' | 'RandomForestClassifier'
    n_estimators       INT,                          -- RF : 300  /  KNN : NULL
    n_neighbors        INT,                          -- KNN : 5   /  RF  : NULL
    n_train_projects   INT,                          -- len(X_train)
    date_entrainement  DATE
);
 
-- =========================
-- TABLES DE FAITS
-- =========================
 
-- Métriques globales par modèle et par run
-- 1 ligne = 1 métrique (accuracy, precision, recall, f1) pour 1 modèle à 1 date
CREATE TABLE Fait_metriques_modele (
    id_metrique    INT          PRIMARY KEY AUTO_INCREMENT,
    id_modele      INT          NOT NULL,
    id_date        INT          NOT NULL,
    nom_metrique   VARCHAR(100) NOT NULL,   -- 'accuracy' | 'precision' | 'recall' | 'f1'
    valeur         DECIMAL(5,2) NOT NULL,   -- ex : 89.00
    label_affiche  VARCHAR(100),            -- ex : 'Accuracy', 'Robustness', 'F1 Score'
 
    FOREIGN KEY (id_modele) REFERENCES Modele_AI(id_modele),
    FOREIGN KEY (id_date)   REFERENCES Date_dim(id_date)
);
 
-- Probabilité de succès par projet — 1 ligne = 1 projet par run
CREATE TABLE Fait_prediction_projet (
    id_fait        INT           PRIMARY KEY AUTO_INCREMENT,
    id_projet      INT           NOT NULL,
    id_date        INT           NOT NULL,
 
    proba_knn      DECIMAL(5,2),   -- vote voisins KNN  ex : 80.00
    proba_rf       DECIMAL(5,2),   -- predict_proba() RF ex : 87.00
    ecart_modeles  DECIMAL(5,2),   -- ABS(proba_rf - proba_knn)
 
    FOREIGN KEY (id_projet) REFERENCES Projet(id_projet),
    FOREIGN KEY (id_date)   REFERENCES Date_dim(id_date)
);
 
-- Feature importance RF — 1 ligne = 1 feature par run
-- Uniquement Random Forest (feature_importances_)
CREATE TABLE Fait_detail_facteurs (
    id_detail      INT           PRIMARY KEY AUTO_INCREMENT,
    id_modele      INT           NOT NULL,
    id_date        INT           NOT NULL,
    nom_facteur    VARCHAR(100)  NOT NULL,   -- ex : 'goal_amount'
    score_facteur  DECIMAL(5,2)  NOT NULL,   -- importance * 100
    badge_niveau   VARCHAR(20),              -- 'Hot' | 'Medium' | 'Low'
 
    FOREIGN KEY (id_modele) REFERENCES Modele_AI(id_modele),
    FOREIGN KEY (id_date)   REFERENCES Date_dim(id_date)
);
 