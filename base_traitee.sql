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