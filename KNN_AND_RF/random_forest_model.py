"""
random_forest_model.py
----------------------
Modele Random Forest pour la prediction de succes de projets Kickstarter.

Pipeline complet :
    1. Extraction des features structurees  (features_knn_rf.py)
    2. Suppression des colonnes en data leakage
    3. Remplacement des placeholders BERT par les vraies features de sentiment
    4. Construction de la variable cible (percent_funded final >= 100)
    5. Encodage categoriel                  (encoders.py)
    6. Entrainement du RandomForestClassifier
    7. Sauvegarde des resultats dans la DWH  (data_to_dwh.py)
"""

import sys
import os

# Ajouter le dossier parent au path pour permettre les imports relatifs.
parent_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))
sys.path.append(parent_dir)

import pandas as pd
from datetime import date
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split, GridSearchCV
from sklearn.metrics import accuracy_score, classification_report
from features_knn_rf import extract_knn_rf_features
from encoders import encode_features_for_training
from data_to_dwh import save_rf_to_dwh


# ----------------------------------------------------------------------------
# Colonnes a supprimer avant l'entrainement
# ----------------------------------------------------------------------------

# Colonnes a supprimer avant l'entrainement.
#
# Depuis la correction de la fuite train/test (un seul snapshot par projet,
# au point mi-campagne), les valeurs de pledged_amount, backers_count, etc.
# sont des valeurs MID-CAMPAGNE, pas des valeurs finales.
# Elles sont donc des features legitimes et ne doivent plus etre supprimees.
#
# Seules restent en leakage :
#   - percent_funded  : redondant avec funding_ratio_mid (meme information)
#   - current_state   : vaut 'LIVE' pour tous les projets actifs, non informatif
#   - days_since_launch : vaut ~duration_days * 0.5 pour tous apres dedup,
#                         non informatif et deja encode dans duration_days
LEAKAGE_COLS = [
    'percent_funded',
    'current_state',
    'days_since_launch',
]

# Ces colonnes sont des valeurs provisoires ajoutees dans features_knn_rf.py
# en attendant les vraies features BERT. On les supprime ici avant de les
# remplacer par les vraies valeurs calculees par bert_sentiment.py. 
BERT_PLACEHOLDER_COLS = [
    'avg_sentiment_score',
    'positive_ratio',
    'creator_response_rate',
    'sentiment_volatility',
    'sentiment_trend',
]


# ----------------------------------------------------------------------------
# Classe principale
# ----------------------------------------------------------------------------

class RandomForestKickstarter:

    def __init__(self):
        """
        Le RandomForestClassifier est initialise avec des valeurs par defaut.
        Les hyperparametres finaux (n_estimators, max_depth, min_samples_leaf)
        sont selectionnes automatiquement par GridSearchCV dans train().
        """
        self.model = RandomForestClassifier(random_state=42, class_weight='balanced')

    # -------------------------------------------------------------------------
    # Preparation des donnees
    # -------------------------------------------------------------------------

    def prepare_dataset(self, data_date=None):
        """
        Charge et prepare les donnees pour l'entrainement.

        Args:
            data_date (str, optional) : filtre sur pe.scrap_date au format 'YYYY-MM-DD'.
                                        Si None, toutes les dates disponibles sont utilisees.
        Returns:
            pd.DataFrame : dataset pret pour l'entrainement, avec la colonne 'is_successful'.
        """

        # ETAPE 1 : Extraction des features depuis la base kickstarter ------
        df = extract_knn_rf_features(data_date)

        # On garde uniquement les snapshots pris a mi-campagne (50% du temps ecoule).
        # C'est la condition du projet : predire le succes avant la fin.
        df_all = df.copy()
        df = df[df['days_since_launch'] <= df['duration_days'] * 0.5]

        # Fallback : projets sans aucun snapshot a mi-campagne
        # (ex : scraping demarre apres la moitie de la campagne).
        # On utilise leur snapshot le plus ancien pour ne pas les exclure.
        missing_pids = set(df_all['project_id'].unique()) - set(df['project_id'].unique())
        if missing_pids:
            earliest = (df_all[df_all['project_id'].isin(missing_pids)]
                        .sort_values('scrap_date')
                        .groupby('project_id', as_index=False)
                        .first())
            df = pd.concat([df, earliest], ignore_index=True)
            print(f"{len(missing_pids)} projets sans snapshot mi-campagne : "
                  f"snapshot le plus ancien utilise comme fallback")

        # Un seul snapshot par projet : le plus avance dans la campagne
        # (le plus proche du point mi-campagne = le plus informatif).
        # Sans cette deduplication, le meme projet apparait plusieurs fois
        # dans le dataset et peut se retrouver dans le train ET le test,
        # ce qui provoque une accuracy de 100% (le modele memorise le projet).
        df = (df.sort_values('days_since_launch', ascending=False)
                .groupby('project_id', as_index=False)
                .first())

        # ETAPE 2 : Suppression des colonnes en data leakage ---------------
        df = df.drop(columns=LEAKAGE_COLS, errors='ignore')

        # ETAPE 3 : Suppression des placeholders BERT ----------------------
        # On retire les valeurs provisoires avant de les remplacer par les
        # vraies features de sentiment calculees par BERT.
        df = df.drop(columns=BERT_PLACEHOLDER_COLS, errors='ignore')

        # -- ETAPE 4 : Features de sentiment BERT -----------------------------
        # On tente d'utiliser le vrai modele BERT. Si indisponible (erreur,
        # premier lancement, environnement sans GPU), on cree des valeurs
        # neutres pour ne pas bloquer l'entrainement.
        try:
            from bert_sentiment import run_sentiment_analysis
            _, sentiment_features = run_sentiment_analysis(save_results=False)
        except Exception as e:
            print(f"BERT non disponible - features neutres utilisees ({e})")
            sentiment_features = pd.DataFrame({
                "project_id"           : df["project_id"].unique(),
                "avg_sentiment_score"  : 0.0,
                "positive_ratio"       : 0.5,
                "creator_response_rate": 0.0,
                "sentiment_volatility" : 0.0,
                "sentiment_trend"      : 0.0,
            })

        # Fusion des features de sentiment avec le dataset principal
        df = df.merge(sentiment_features, on="project_id", how="left")
        df.fillna(0, inplace=True)

        # -- ETAPE 5 : Construction de la variable cible ----------------------
        # On va chercher le percent_funded au dernier snapshot disponible
        # pour chaque projet. C'est la valeur finale, utilisee uniquement
        # comme etiquette (label) — pas comme feature.
        # Un projet est considere un succes si son financement final >= 100%.
        from db_connection import read_sql_df
        target_sql = """
            SELECT project_id, percent_funded
            FROM PROJECT_EVOLUTION
            WHERE (project_id, scrap_date) IN (
                SELECT project_id, MAX(scrap_date)
                FROM PROJECT_EVOLUTION
                GROUP BY project_id
            )
        """
        target_df = read_sql_df(target_sql)
        target_df["is_successful"] = (target_df["percent_funded"] >= 100).astype(int)
        target_df = target_df[["project_id", "is_successful"]]

        df = df.merge(target_df, on="project_id", how="left")
        df["is_successful"] = df["is_successful"].fillna(0).astype(int)

        # -- ETAPE 6 : Encodage des variables categorielles -------------------
        # One-hot encoding sur category et subcategory (via encoders.py).
        # is_project_we_love est un booleen encode en 0/1.
        df = encode_features_for_training(df)
        if 'is_project_we_love' in df.columns:
            df['is_project_we_love'] = df['is_project_we_love'].astype('category').cat.codes

        return df

    # -------------------------------------------------------------------------
    # Entrainement
    # -------------------------------------------------------------------------

    def train(self, data_date=None, run_date: date = None, save_to_dwh: bool = True):
        """
        Entraine le modele et sauvegarde les resultats dans la DWH.

        L'evaluation (accuracy, F1, etc.) se fait sur le test set (20%) pour rester
        honnete. En revanche, la sauvegarde DWH couvre TOUS les projets du dataset
        afin qu'aucun projet n'ait proba_rf NULL dans Fait_prediction_projet.

        Args:
            data_date (str, optional)  : date de scraping pour filtrer les donnees
                                         d'entrainement ('YYYY-MM-DD'). None = tout utiliser.
            run_date  (date, optional) : date a enregistrer dans la DWH.
                                         Defaut = date du jour.
            save_to_dwh (bool)         : si True, sauvegarde dans base_traitee via data_to_dwh.py.

        Returns:
            RandomForestClassifier : modele entraine.
        """
        df = self.prepare_dataset(data_date)

        if df.empty:
            print(f"Aucune donnee trouvee pour data_date={data_date}")
            return None

        # Sauvegarder les project_id avant de les retirer des features.
        project_ids = df["project_id"].values

        # Separation features / cible
        cols_to_drop = ["project_id", "scrap_date", "is_successful"]
        X = df.drop(columns=[c for c in cols_to_drop if c in df.columns])
        y = df["is_successful"]

        # On passe aussi les index du DataFrame pour pouvoir retrouver les
        # project_ids correspondant aux lignes du jeu de test apres le split.
        idx = df.index
        X_train, X_test, y_train, y_test, idx_train, idx_test = train_test_split(
            X, y, idx,
            test_size    = 0.2,
            random_state = 42,
            stratify     = y,
        )

        # Recuperer les project_ids du jeu de test dans le bon ordre
        project_ids_series = pd.Series(project_ids, index=df.index)
        project_ids_test   = project_ids_series.loc[idx_test].values

        # -- Entrainement avec GridSearchCV -----------------------------------
        # On cherche les meilleurs hyperparametres par cross-validation 5-fold
        # sur le train set uniquement (pas de fuite vers le test).
        print("GridSearch sur les hyperparametres du Random Forest...")
        param_grid = {
            'n_estimators'    : [200, 300, 500],
            'max_depth'       : [4, 6, 8, 12],
            'min_samples_leaf': [2, 4, 6],
        }
        gs = GridSearchCV(
            RandomForestClassifier(random_state=42, class_weight='balanced'),
            param_grid,
            cv      = 5,
            scoring = 'f1_weighted',
            n_jobs  = -1,
        )
        gs.fit(X_train, y_train)
        self.model = gs.best_estimator_
        print(f"Meilleurs hyperparametres : {gs.best_params_}  "
              f"(F1 CV={gs.best_score_:.4f})")

        y_pred = self.model.predict(X_test)

        # -- Evaluation (sur le test set uniquement — evaluation honnete) -----
        print(f"\nAccuracy : {accuracy_score(y_test, y_pred):.4f}")
        print("\nRapport de classification :\n",
              classification_report(y_test, y_pred, zero_division=0))

        importances = pd.DataFrame({
            "feature"   : X.columns,
            "importance": self.model.feature_importances_
        }).sort_values("importance", ascending=False)
        print("\nTop 15 features les plus importantes :")
        print(importances.head(15).to_string(index=False))

        # -- Sauvegarde DWH ---------------------------------------------------
        # On sauvegarde les metriques, les probabilites par projet et
        # les importances des features dans base_traitee.
        #
        # IMPORTANT : pour les probabilites, on predit sur TOUS les projets
        # du dataset (pas seulement le test set). Raison : le train/test split
        # fait que chaque modele ne predit que sur ~20% des projets. Si on ne
        # sauvegarde que le test set, les projets dans le train set d'un modele
        # mais pas de l'autre restent avec proba NULL dans Fait_prediction_projet,
        # ce qui se traduit par N/A dans l'interface Shiny.
        # Les metriques d'evaluation restent calculees sur le vrai test set.
        if save_to_dwh:
            dwh_date = run_date or date.today()
            save_rf_to_dwh(
                rf_model         = self.model,
                X                = X,               # pour les feature importances
                X_test           = X,               # tous les projets pour les probas DWH
                y_test           = y_test,          # vrai test set pour les metriques
                y_pred           = y_pred,          # predictions du test set
                project_ids_test = project_ids,     # tous les project_ids
                scrap_date       = dwh_date,
            )
            print(f"  {len(project_ids)} projets avec proba_rf enregistres.")

        return self.model


# ----------------------------------------------------------------------------
# Execution directe
# ----------------------------------------------------------------------------

if __name__ == "__main__":
    rf = RandomForestKickstarter()
    # data_date=None : utilise toutes les donnees disponibles dans kickstarter
    # run_date=today : date enregistree dans la DWH pour ce run
    rf.train(data_date=None, run_date=date.today(), save_to_dwh=True)