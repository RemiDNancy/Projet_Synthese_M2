"""
data_to_dwh.py
--------------
Pipeline de sauvegarde des resultats des modeles AI vers base_traitee (DWH).

Fonctions publiques :
    save_rf_to_dwh(...)              -> sauvegarde les resultats du Random Forest
    save_knn_to_dwh_with_probas(...) -> sauvegarde les resultats du KNN

Fonctions utilitaires internes (utilisees aussi par knn_script.py) :
    get_or_create_id_date(...)  -> gestion de la dimension Date_dim
    get_or_create_modele(...)   -> gestion de la dimension Modele_AI
    _insert_metriques(...)      -> insertion des metriques globales
    _upsert_prediction(...)     -> insertion ou mise a jour des probas par projet
"""

import pandas as pd
from datetime import date
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score

# Connexion pymysql native (cursors) — definie dans db_connection.py
from db_connection import get_connection


# ============================================================
# UTILITAIRES
# ============================================================

def get_or_create_id_date(conn, d: date) -> int:
    """
    Retourne l'id_date correspondant a une date dans la table Date_dim.
    Si la date n'existe pas encore, elle est inseree automatiquement.

    L'id_date est construit au format YYYYMMDD (ex: 20260321).

    Args:
        conn : connexion pymysql active sur base_traitee.
        d    : date Python a rechercher ou inserer.

    Returns:
        int : id_date de la forme YYYYMMDD.
    """
    id_date = int(d.strftime("%Y%m%d"))
    cursor  = conn.cursor()
    cursor.execute(
        "SELECT id_date FROM Date_dim WHERE id_date = %s", (id_date,)
    )
    if not cursor.fetchone():
        cursor.execute("""
            INSERT INTO Date_dim (id_date, date_complete, annee, mois, jour, semaine)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (id_date, d, d.year, d.month, d.day, d.isocalendar()[1]))
        conn.commit()
    cursor.close()
    return id_date


def get_or_create_modele(conn, nom: str, type_algo: str,
                          n_estimators=None, n_neighbors=None,
                          n_train_projects=None,
                          date_entrainement=None) -> int:
    """
    Retourne l'id_modele d'un modele existant (meme nom + meme date)
    ou insere une nouvelle ligne dans Modele_AI si absent.

    La cle de deduplication est (nom_modele, date_entrainement) :
    un meme modele peut etre reentraine a des dates differentes.

    Args:
        conn              : connexion pymysql active sur base_traitee.
        nom               : nom du modele ('KNN' ou 'RandomForest').
        type_algo         : classe sklearn utilisee.
        n_estimators      : nombre d'arbres (RF uniquement, None pour KNN).
        n_neighbors       : nombre de voisins (KNN uniquement, None pour RF).
        n_train_projects  : taille du jeu d'entrainement.
        date_entrainement : date Python du run.

    Returns:
        int : id_modele de la ligne existante ou nouvellement inseree.
    """
    cursor = conn.cursor()
    cursor.execute(
        "SELECT id_modele FROM Modele_AI WHERE nom_modele = %s AND date_entrainement = %s",
        (nom, date_entrainement)
    )
    row = cursor.fetchone()
    if row:
        cursor.close()
        return row[0]

    cursor.execute("""
        INSERT INTO Modele_AI
            (nom_modele, type_algo, n_estimators, n_neighbors, n_train_projects, date_entrainement)
        VALUES (%s, %s, %s, %s, %s, %s)
    """, (nom, type_algo, n_estimators, n_neighbors, n_train_projects, date_entrainement))
    conn.commit()
    id_modele = cursor.lastrowid
    cursor.close()
    return id_modele


def badge_from_importance(score: float) -> str:
    """
    Attribue un badge qualitatif a une feature selon son importance RF.

        >= 10% -> 'Hot'    : feature tres influente
        >= 5%  -> 'Medium' : influence moderee
        < 5%   -> 'Low'    : faible influence

    Args:
        score : importance brute issue de feature_importances_ (entre 0 et 1).

    Returns:
        str : 'Hot', 'Medium' ou 'Low'.
    """
    if score >= 0.10:
        return "Hot"
    elif score >= 0.05:
        return "Medium"
    return "Low"


def _upsert_prediction(cursor, id_projet: int, id_date: int,
                        col_proba: str, proba_value: float):
    """
    Insere ou met a jour la probabilite de succes d'un projet dans Fait_prediction_projet.

    Si la ligne (id_projet, id_date) n'existe pas : insertion.
    Si elle existe deja (l'autre modele a deja ecrit) : mise a jour de la colonne
    manquante et calcul automatique de ecart_modeles si les deux probas sont presentes.

    Cette logique repose sur la contrainte UNIQUE (id_projet, id_date) definie
    dans migration_unique_constraint.sql.

    Args:
        cursor      : curseur pymysql actif.
        id_projet   : identifiant du projet Kickstarter.
        id_date     : date du run au format YYYYMMDD.
        col_proba   : colonne a remplir — 'proba_rf' ou 'proba_knn'.
        proba_value : probabilite de succes en pourcentage (0-100).
    """
    other_col = "proba_knn" if col_proba == "proba_rf" else "proba_rf"

    cursor.execute(f"""
        INSERT INTO Fait_prediction_projet
            (id_projet, id_date, {col_proba}, ecart_modeles)
        VALUES (%s, %s, %s, NULL)
        ON DUPLICATE KEY UPDATE
            {col_proba}   = VALUES({col_proba}),
            ecart_modeles = CASE
                WHEN {other_col} IS NOT NULL
                THEN ABS(VALUES({col_proba}) - {other_col})
                ELSE NULL
            END
    """, (id_projet, id_date, round(proba_value, 2)))


def _insert_metriques(cursor, id_modele: int, id_date: int,
                       y_test, y_pred):
    """
    Insere les 4 metriques d'evaluation dans Fait_metriques_modele.

    Metriques calculees : accuracy, precision, recall, f1 (toutes en %).
    zero_division=0 evite les erreurs si une classe est absente du jeu de test.

    Args:
        cursor    : curseur pymysql actif.
        id_modele : identifiant du modele dans Modele_AI.
        id_date   : date du run au format YYYYMMDD.
        y_test    : labels reels du jeu de test.
        y_pred    : labels predits par le modele.
    """
    metriques = {
        "accuracy" : (accuracy_score(y_test, y_pred)                   * 100, "Accuracy"),
        "precision": (precision_score(y_test, y_pred, zero_division=0) * 100, "Precision"),
        "recall"   : (recall_score(y_test, y_pred, zero_division=0)    * 100, "Recall"),
        "f1"       : (f1_score(y_test, y_pred, zero_division=0)        * 100, "F1 Score"),
    }
    for nom_metrique, (valeur, label) in metriques.items():
        cursor.execute("""
            INSERT INTO Fait_metriques_modele
                (id_modele, id_date, nom_metrique, valeur, label_affiche)
            VALUES (%s, %s, %s, %s, %s)
        """, (id_modele, id_date, nom_metrique, round(valeur, 2), label))


# ============================================================
# RANDOM FOREST -> DWH
# ============================================================

def save_rf_to_dwh(rf_model,
                   X,
                   X_test,
                   y_test,
                   y_pred,
                   project_ids_test: list,
                   scrap_date: date):
    """
    Sauvegarde les resultats du Random Forest dans base_traitee.

    Tables alimentees :
        - Modele_AI             : enregistrement du modele (hyperparametres, date)
        - Fait_metriques_modele : accuracy, precision, recall, f1
        - Fait_prediction_projet : probabilite de succes par projet (proba_rf)
        - Fait_detail_facteurs  : top 15 features les plus importantes

    Args:
        rf_model         : RandomForestClassifier entraine.
        X                : DataFrame complet des features (toutes lignes).
                           Utilise pour compter n_train = len(X) - len(X_test)
                           et pour extraire feature_importances_.
        X_test           : subset test, utilise pour predict_proba.
        y_test           : labels reels du test set.
        y_pred           : labels predits sur le test set.
        project_ids_test : liste des project_id correspondant aux lignes de X_test.
        scrap_date       : date Python du run — enregistree dans la DWH.
    """
    conn = get_connection(db="base_traitee")
    try:
        # -- Dimension Modele_AI ----------------------------------------------
        id_modele = get_or_create_modele(
            conn,
            nom              = "RandomForest",
            type_algo        = "RandomForestClassifier",
            n_estimators     = rf_model.n_estimators,
            n_neighbors      = None,
            n_train_projects = len(X) - len(X_test),
            date_entrainement= scrap_date
        )
        id_date = get_or_create_id_date(conn, scrap_date)
        cursor  = conn.cursor()

        # -- Metriques globales -----------------------------------------------
        _insert_metriques(cursor, id_modele, id_date, y_test, y_pred)

        # -- Probabilite de succes par projet ---------------------------------
        # predict_proba retourne shape (n, 2) — colonne 1 = proba classe succes
        probas = rf_model.predict_proba(X_test)[:, 1] * 100
        for project_id, proba_rf in zip(project_ids_test, probas):
            _upsert_prediction(cursor, int(project_id), id_date,
                               col_proba="proba_rf", proba_value=float(proba_rf))

        # -- Feature importances (top 15) ------------------------------------
        # score_facteur est exprime en % (importance * 100)
        importances = pd.DataFrame({
            "feature"   : X.columns,
            "importance": rf_model.feature_importances_
        }).sort_values("importance", ascending=False).head(15)

        for _, row in importances.iterrows():
            score = round(float(row["importance"]) * 100, 2)
            cursor.execute("""
                INSERT INTO Fait_detail_facteurs
                    (id_modele, id_date, nom_facteur, score_facteur, badge_niveau)
                VALUES (%s, %s, %s, %s, %s)
            """, (id_modele, id_date, row["feature"], score,
                  badge_from_importance(row["importance"])))

        conn.commit()
        cursor.close()
        print(f"RF sauvegarde -> id_modele={id_modele}, id_date={id_date}")

    except Exception as e:
        conn.rollback()
        print(f"Erreur save_rf_to_dwh : {e}")
        raise
    finally:
        conn.close()


# ============================================================
# KNN -> DWH
# ============================================================

def save_knn_to_dwh_with_probas(knn_model,
                                  X_test_array,
                                  y_test,
                                  y_pred,
                                  project_ids_test: list,
                                  n_train_projects: int,
                                  scrap_date: date):
    """
    Sauvegarde les resultats du KNN dans base_traitee.

    Contrairement au RF, le KNN ne produit pas de feature importances.
    On alimente donc uniquement Modele_AI, Fait_metriques_modele
    et Fait_prediction_projet (colonne proba_knn).

    Args:
        knn_model         : KNeighborsClassifier entraine.
        X_test_array      : numpy array du jeu de test, utilise pour predict_proba.
        y_test            : labels reels.
        y_pred            : labels predits.
        project_ids_test  : liste des project_id du test set.
        n_train_projects  : taille du train set.
        scrap_date        : date Python du run — enregistree dans la DWH.
    """
    conn = get_connection(db="base_traitee")
    try:
        # -- Dimension Modele_AI ----------------------------------------------
        id_modele = get_or_create_modele(
            conn,
            nom              = "KNN",
            type_algo        = "KNeighborsTimeSeriesClassifier",
            n_estimators     = None,
            n_neighbors      = knn_model.n_neighbors,
            n_train_projects = n_train_projects,
            date_entrainement= scrap_date
        )
        id_date = get_or_create_id_date(conn, scrap_date)
        cursor  = conn.cursor()

        # -- Metriques globales -----------------------------------------------
        _insert_metriques(cursor, id_modele, id_date, y_test, y_pred)

        # -- Probabilite de succes par projet ---------------------------------
        # predict_proba retourne shape (n, 2) — colonne 1 = proba classe 1 (succes)
        probas         = knn_model.predict_proba(X_test_array)
        probas_success = probas[:, 1] * 100

        for project_id, proba_knn in zip(project_ids_test, probas_success):
            _upsert_prediction(cursor, int(project_id), id_date,
                               col_proba="proba_knn", proba_value=float(proba_knn))

        conn.commit()
        cursor.close()
        print(f"KNN sauvegarde -> id_modele={id_modele}, id_date={id_date}")

    except Exception as e:
        conn.rollback()
        print(f"Erreur save_knn_to_dwh_with_probas : {e}")
        raise
    finally:
        conn.close()