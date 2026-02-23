
USE kickstarter;

DROP TABLE IF EXISTS REWARD_EVOLUTION;
DROP TABLE IF EXISTS REWARD_OPTION;
DROP TABLE IF EXISTS REWARD_ITEM;
DROP TABLE IF EXISTS REWARD;
DROP TABLE IF EXISTS PROJECT_COMMENT;
DROP TABLE IF EXISTS PROJECT_EVOLUTION;
DROP TABLE IF EXISTS PROJECT;
DROP TABLE IF EXISTS CREATOR;
-- Création de la table CREATOR

CREATE TABLE CREATOR (
    creator_id VARCHAR(255) PRIMARY KEY, 
    creator_name VARCHAR(255),
    biography TEXT,
    launched_projects_count INT,
    backings_count INT, 
    is_fb_connected BOOLEAN,
    nb_websites INT,
    last_login INT
);

-- Création de la table PROJECT (ce qui change pas)

CREATE TABLE PROJECT (
    project_id BIGINT PRIMARY KEY,
    id_creator VARCHAR(255),
    title VARCHAR(255),
    description TEXT,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    location VARCHAR(255),
    url VARCHAR(500),
    image_url VARCHAR(500),
    currency VARCHAR(10),
    goal_amount DECIMAL(15, 2),
    is_project_we_love BOOLEAN,
    created_at DATETIME,
    deadline_at DATETIME,
    CONSTRAINT fk_project_creator FOREIGN KEY (id_creator) REFERENCES CREATOR(creator_id)
);

CREATE INDEX idx_project_creator ON PROJECT(id_creator);
CREATE INDEX idx_project_category ON PROJECT(category);

-- Création de la table PROJECT_EVOLUTION ce qui change dans projet 

CREATE TABLE PROJECT_EVOLUTION (
    evolution_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id BIGINT NOT NULL,
    scrap_date DATETIME,
    pledged_amount DECIMAL(15, 2),
    backers_count INT,
    percent_funded DECIMAL(10, 2),
    updates_count INT,
    comments_count INT,
    current_state VARCHAR(50),
    CONSTRAINT fk_hist_project FOREIGN KEY (project_id) REFERENCES PROJECT(project_id),
    CONSTRAINT uq_project UNIQUE (project_id, scrap_date)
);

CREATE INDEX idx_pe_project_date ON PROJECT_EVOLUTION(project_id, scrap_datetime);
CREATE INDEX idx_pe_state ON PROJECT_EVOLUTION(current_state);

-- Création de la table PROJECT_COMMENT

CREATE TABLE PROJECT_COMMENT (
    comment_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id BIGINT NOT NULL,
    parent_comment_id INT,
    pseudo VARCHAR(150),
    comment_text TEXT,
    comment_date DATE,
    is_creator_reply BOOLEAN,
    CONSTRAINT fk_comment_project FOREIGN KEY (project_id) REFERENCES PROJECT(project_id)
);

CREATE INDEX idx_pc_project ON PROJECT_COMMENT(project_id);
CREATE INDEX idx_pc_parent ON PROJECT_COMMENT(parent_comment_id);
CREATE INDEX idx_pc_creator_reply ON PROJECT_COMMENT(is_creator_reply);

-- Création de la table REWARD ce qui change pas

CREATE TABLE REWARD (
    reward_id INT PRIMARY KEY AUTO_INCREMENT,
    project_id BIGINT,
    reward_name VARCHAR(255),
    reward_description TEXT,
    price_amount DECIMAL(15, 2),
    estimated_delivery DATE,
    CONSTRAINT fk_reward_project FOREIGN KEY (project_id) REFERENCES PROJECT(project_id)
    
);

CREATE INDEX idx_r_project ON REWARD(project_id);

-- REWARD_ITEM : les items inclus dans le reward
CREATE TABLE REWARD_ITEM (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    reward_id INT NOT NULL,
    item_name VARCHAR(255) NOT NULL,
    item_quantity VARCHAR(50),                                  -- "50" format du JSON Donc il faut faire un pretraitement ici avec le python                                                   
    CONSTRAINT fk_item_reward FOREIGN KEY (reward_id) REFERENCES REWARD(reward_id)
        ON DELETE CASCADE
);
CREATE INDEX idx_ri_reward ON REWARD_ITEM(reward_id);

-- REWARD_OPTION : les options additionnelles
CREATE TABLE REWARD_OPTION (
    option_id INT PRIMARY KEY AUTO_INCREMENT,
    reward_id INT NOT NULL,
    option_name VARCHAR(255) NOT NULL,
    option_price VARCHAR(50),                                   -- "+€5" format du JSON Donc il faut faire un pretraitement ici avec le python 
    option_description TEXT,
    CONSTRAINT fk_option_reward FOREIGN KEY (reward_id) REFERENCES REWARD(reward_id)
        ON DELETE CASCADE
);

CREATE INDEX idx_ro_reward ON REWARD_OPTION(reward_id);

-- ce qui change
CREATE TABLE REWARD_EVOLUTION (
    reward_evolution_id INT PRIMARY KEY AUTO_INCREMENT,
    reward_id INT NOT NULL,                          -- NOT NULL
    scrap_date DATETIME NOT NULL,                       -- NOT NULL
    
    
    remaining_quantity INT,
    backers_on_reward INT DEFAULT 0,                    -- defaukt = 0
    
    -- Variations journalières pour l'analyse
    daily_backers_variation INT,

    CONSTRAINT fk_rev_hist FOREIGN KEY (reward_id) REFERENCES REWARD(reward_id),
        
        -- anti-doublon (1 snapshot par reward par datetime)
    UNIQUE KEY uq_reward_snapshot (reward_id, scrap_date)
);
CREATE INDEX idx_re_reward_date ON REWARD_EVOLUTION(reward_id, scrap_date);
