"""
knn_script.py
-------------
Modele KNN pour la prediction de succes de projets Kickstarter.

Approche choisie : feature engineering sur series temporelles + KNN classique sklearn.

Pourquoi pas DTW (Dynamic Time Warping) ?
    L'approche DTW avec KNeighborsTimeSeriesClassifier (tslearn) est theoriquement
    plus riche car elle prend en compte la forme des series temporelles.
    Cependant, DTW necessite un volume de donnees important (>500 projets) pour
    generaliser correctement. Avec 77 projets, le modele DTW predisait systematiquement
    la classe majoritaire (accuracy 50%, matrice de confusion entierement a droite).
    L'agregation temporelle en vecteur fixe est plus robuste avec peu de donnees.

Principe de l'agregation temporelle :
    Pour chaque projet, au lieu de conserver les 28 snapshots quotidiens comme
    une serie brute, on en extrait 4 statistiques par feature temporelle :
        - moyenne    : comportement moyen sur toute la campagne
        - maximum    : pic atteint
        - derniere valeur : etat a mi-campagne
        - pente lineaire  : tendance (montee ou descente)
    On obtient ainsi un vecteur fixe de 28 dimensions par projet,
    exploitable par un KNN sklearn standard.

Je procede avec ce pipline :
    1. Extraction des donnees via features_knn_rf.py
    2. Labellisation des projets (succes / echec)
    3. Agregation temporelle => vecteur fixe par projet
    4. Normalisation StandardScaler
    5. Selection de k par GridSearch avec cross-validation
    6. Entrainement du KNN
    7. Evaluation + sauvegarde dans la DWH
"""

import sys
import os

# Ajouter le dossier parent au path Python pour les imports relatifs
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

import numpy as np
import pandas as pd
from collections import Counter
from datetime import date

from sklearn.preprocessing import StandardScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

from features_knn_rf import extract_knn_rf_features
from data_to_dwh import save_knn_to_dwh_with_probas


# ----------------------------------------------------------------------------
# Definition des features
# ----------------------------------------------------------------------------

# Features temporelles : elles evoluent a chaque snapshot quotidien.
# Pour chaque feature, on calculera 4 statistiques (mean, max, last, slope).
# launched_projects_count et backings_count sont deplacees en statiques
# car elles ne changent pas au cours de la campagne (caracteristiques du createur).
TEMPORAL_FEATURES = [
    'pledged_amount',                   # montant collecte
    'backers_count',                    # nombre de contributeurs
    'updates_count',                    # nombre de mises a jour publiees
    'funding_velocity',                 # variation journaliere du montant collecte
    'funding_ratio_mid',                # ratio financement a mi-campagne
]

# Features statiques : une seule valeur par projet, prise au premier snapshot.
# Elles caracterisent le projet et son createur au lancement.
STATIC_FEATURES = [
    'goal_amount',                      # objectif de financement
    'duration_days',                    # duree totale de la campagne
    'is_project_we_love',               # badge Kickstarter
    'is_fb_connected',                  # createur connecte via Facebook
    'num_rewards',                      # nombre de contreparties proposees
    'avg_reward_price',                 # prix moyen des contreparties
    'launched_projects_count',          # nombre de projets lances par le createur
    'backings_count',                   # nombre de projets finances par le createur
]


# ----------------------------------------------------------------------------
# Fonction utilitaire
# ----------------------------------------------------------------------------

def _linear_slope(series: np.ndarray) -> float:
    """
    Calcule la pente d'une regression lineaire de degre 1 sur la serie.
    Represente la tendance globale (positive = montee, negative = descente).

    Args:
        series : valeurs numeriques de la serie temporelle.

    Returns:
        float : coefficient directeur de la droite de regression.
    """
    if len(series) < 2:
        return 0.0
    x = np.arange(len(series), dtype=float)
    slope = np.polyfit(x, series.astype(float), 1)[0]
    return float(slope)


# ----------------------------------------------------------------------------
# Classe principale
# ----------------------------------------------------------------------------

class KNNKickstarter:

    def __init__(self, n_neighbors: int = None):
        """
        Initialise le KNN Kickstarter.

        Args:
            n_neighbors (int, optional) : nombre de voisins.
                                          Si None, le meilleur k est selectionne
                                          automatiquement par GridSearch.
        """
        self.n_neighbors = n_neighbors
        self.scaler      = StandardScaler()
        self.model       = None   # instancie apres la selection de k

    # -------------------------------------------------------------------------
    # Chargement et labellisation
    # -------------------------------------------------------------------------

    def _load_raw(self) -> pd.DataFrame:
        """
        Charge toutes les donnees disponibles depuis la base kickstarter
        et les trie par projet et date de scraping.
        """
        df = extract_knn_rf_features()
        df = df.sort_values(['project_id', 'scrap_date'])
        return df

    def _label_projects(self, df: pd.DataFrame):
        """
        Identifie les projets termines et les etiquette succes ou echec.

        Regles :
            - Succes  : percent_funded >= 100 sur au moins un snapshot.
            - Echec   : current_state == 'FAILED' ou 'CANCELED'.
            - Live    : ignore (resultat inconnu, on ne peut pas l'utiliser).
            - Conflit : si un projet a atteint 100% ET est marque FAILED,
                        il est considere comme un succes (priorite au financement).

        Returns:
            (list, list) : (success_ids, echec_ids)
        """
        success_ids = set()
        echec_ids   = set()

        for project_id, group in df.groupby('project_id'):
            if (group['percent_funded'] >= 100).any():
                success_ids.add(project_id)
            elif group['current_state'].isin(['FAILED', 'CANCELED']).any():
                echec_ids.add(project_id)
            # projets encore live : ignores

        # Securite : exclure des echecs tout projet deja marque comme succes
        echec_ids -= success_ids
        return list(success_ids), list(echec_ids)

    # -------------------------------------------------------------------------
    # Feature engineering : serie temporelle => vecteur fixe
    # -------------------------------------------------------------------------

    def _aggregate_project(self, group: pd.DataFrame,
                            static_row: np.ndarray) -> np.ndarray:
        """
        Transforme les snapshots d'un projet en un vecteur numerique fixe.

        Pour chaque feature temporelle, on extrait :
            - mean  : moyenne sur tous les snapshots
            - max   : valeur maximale atteinte
            - last  : valeur au dernier snapshot disponible (mi-campagne)
            - slope : tendance lineaire (pente de la regression)

        Les features statiques sont ajoutees a la fin du vecteur.

        Args:
            group      : DataFrame des snapshots du projet (une ligne par date).
            static_row : valeurs statiques du projet (numpy 1D array).

        Returns:
            np.ndarray : vecteur 1D de taille (len(TEMPORAL_FEATURES)*4 + len(STATIC_FEATURES))
        """
        features = []

        for feat in TEMPORAL_FEATURES:
            if feat not in group.columns:
                # Feature absente : on insere des zeros pour maintenir la coherence des dimensions
                features.extend([0.0, 0.0, 0.0, 0.0])
                continue
            series = group[feat].fillna(0).values
            features.append(float(np.mean(series)))    # comportement moyen
            features.append(float(np.max(series)))     # pic atteint
            features.append(float(series[-1]))          # etat a mi-campagne
            features.append(_linear_slope(series))     # tendance

        # Ajout des features statiques
        features.extend(static_row.tolist())

        return np.array(features, dtype=float)

    def _build_feature_matrix(self, df: pd.DataFrame,
                               success_ids: list, echec_ids: list):
        """
        Construit la matrice de features X et le vecteur de labels y.

        Chaque ligne de X correspond a un projet (vecteur agrege fixe).
        y contient 1 pour succes, 0 pour echec.

        Returns:
            (np.ndarray, np.ndarray, np.ndarray) : (X, y, project_ids)
        """
        all_ids     = success_ids + echec_ids
        success_set = set(success_ids)
        df_filtered = df[df['project_id'].isin(all_ids)]

        rows        = []
        y           = []
        project_ids = []

        for project_id, group in df_filtered.groupby('project_id'):
            # Features statiques : premiere observation du projet
            static_row = group[STATIC_FEATURES].iloc[0].values.astype(float)
            vec = self._aggregate_project(group, static_row)
            rows.append(vec)
            y.append(1 if project_id in success_set else 0)
            project_ids.append(project_id)

        X = np.array(rows, dtype=float)
        y = np.array(y)

        n_feats = len(TEMPORAL_FEATURES) * 4 + len(STATIC_FEATURES)
        print(f"Projets : {len(all_ids)} "
              f"({len(success_ids)} succes / {len(echec_ids)} echecs)")
        print(f"Shape X : {X.shape}  (attendu : {len(all_ids)} x {n_feats})")

        return X, y, np.array(project_ids)

    def _build_live_vectors(self, df: pd.DataFrame,
                             success_ids: list, echec_ids: list):
        """
        Construit les vecteurs de features pour les projets encore live
        (ni succes confirme, ni echec/annule).

        Ces projets ne sont pas utilises pour l'entrainement (pas de label),
        mais le modele entraine peut quand meme produire une proba_knn pour eux.

        Returns:
            (np.ndarray, np.ndarray) : (X_live, live_project_ids)
                                       Tableaux vides si aucun projet live.
        """
        labeled_ids = set(success_ids) | set(echec_ids)
        live_ids    = [pid for pid in df['project_id'].unique()
                       if pid not in labeled_ids]

        if not live_ids:
            return np.empty((0, len(TEMPORAL_FEATURES) * 4 + len(STATIC_FEATURES))), np.array([])

        df_live = df[df['project_id'].isin(live_ids)]
        rows    = []
        pids    = []

        for project_id, group in df_live.groupby('project_id'):
            static_row = group[STATIC_FEATURES].iloc[0].values.astype(float)
            vec = self._aggregate_project(group, static_row)
            rows.append(vec)
            pids.append(project_id)

        print(f"Projets live detectes pour prediction DWH : {len(pids)}")
        return np.array(rows, dtype=float), np.array(pids)

    # -------------------------------------------------------------------------
    # Selection automatique de k par GridSearch
    # -------------------------------------------------------------------------

    def _best_k(self, X_train: np.ndarray, y_train: np.ndarray) -> int:
        """
        Selectionne le meilleur k par cross-validation 3-fold sur le train set.
        Critere : F1 weighted (adapte aux datasets potentiellement desequilibres).

        Les candidats sont limites a n_train // 2 pour eviter que k soit trop
        grand par rapport a la taille du train set.

        Args:
            X_train : features normalisees du train set.
            y_train : labels du train set.

        Returns:
            int : meilleur k trouve.
        """
        candidates = [3, 5, 7, 9, 11]
        max_k      = max(1, len(X_train) // 2)
        candidates = [k for k in candidates if k <= max_k] or [1]

        best_k, best_score = candidates[0], -1.0

        for k in candidates:
            knn = KNeighborsClassifier(n_neighbors=k, weights='distance',
                                        metric='euclidean')
            cv     = min(3, len(X_train))
            scores = cross_val_score(knn, X_train, y_train,
                                     cv=cv, scoring='f1_weighted')
            mean_score = scores.mean()
            print(f"   k={k:2d} -> F1 moyen (CV) : {mean_score:.4f}")
            if mean_score > best_score:
                best_score, best_k = mean_score, k

        print(f"Meilleur k = {best_k}  (F1={best_score:.4f})")
        return best_k

    # -------------------------------------------------------------------------
    # Entrainement principal
    # -------------------------------------------------------------------------

    def train(self, save_to_dwh: bool = True, scrap_date: date = None):
        """
        Charge les donnees, entraine le KNN et sauvegarde les resultats dans la DWH.

        L'evaluation (accuracy, F1, etc.) se fait sur le test set (20%) pour rester
        honnete. En revanche, la sauvegarde DWH couvre TOUS les projets etiquetes
        afin qu'aucun projet n'ait proba_knn NULL dans Fait_prediction_projet.

        Args:
            save_to_dwh (bool) : si True, sauvegarde dans base_traitee.
            scrap_date  (date) : date enregistree dans la DWH. Defaut = aujourd'hui.

        Returns:
            KNeighborsClassifier : modele entraine.
        """
        run_date = scrap_date or date.today()

        # -- Chargement et labellisation --------------------------------------
        df = self._load_raw()
        success_ids, echec_ids = self._label_projects(df)

        if not success_ids or not echec_ids:
            print("Pas assez de projets etiquetes pour entrainer le KNN.")
            return None

        X, y, pids = self._build_feature_matrix(df, success_ids, echec_ids)
        print(f"Repartition classes : {Counter(y)}")

        # -- Split train / test (stratifie pour garantir l'equilibre des classes)
        X_train, X_test, y_train, y_test, pids_train, pids_test = train_test_split(
            X, y, pids,
            test_size    = 0.2,
            random_state = 42,
            stratify     = y,
        )

        # -- Normalisation ----------------------------------------------------
        # On fit le scaler uniquement sur le train pour eviter toute fuite
        # d'information du test set vers le train set.
        X_train_sc = self.scaler.fit_transform(X_train)
        X_test_sc  = self.scaler.transform(X_test)

        # -- Selection de k --------------------------------------------------
        if self.n_neighbors is None:
            print("\nGridSearch sur k :")
            best_k = self._best_k(X_train_sc, y_train)
        else:
            best_k = self.n_neighbors

        self.n_neighbors = best_k
        self.model = KNeighborsClassifier(
            n_neighbors = best_k,
            weights     = 'distance',   # les voisins plus proches ont plus de poids
            metric      = 'euclidean',
        )

        # -- Entrainement -----------------------------------------------------
        print(f"\nEntrainement du KNN (k={best_k})...")
        self.model.fit(X_train_sc, y_train)

        # -- Evaluation (sur le test set uniquement — evaluation honnete) -----
        y_pred  = self.model.predict(X_test_sc)
        y_proba = self.model.predict_proba(X_test_sc)

        print(f"\nAccuracy : {accuracy_score(y_test, y_pred):.4f}")
        print(f"Repartition classes predites : {Counter(y_pred)}")
        print("\nRapport de classification :\n",
              classification_report(y_test, y_pred, zero_division=0))
        print("\nMatrice de confusion :\n", confusion_matrix(y_test, y_pred))

        # -- Sauvegarde DWH : on predit sur TOUS les projets etiquetes --------
        # Pourquoi ? Le train/test split fait que chaque modele ne predit que
        # sur ~20% des projets. En ne sauvegardant que le test set, les projets
        # qui tombent dans le train set d'un modele mais pas de l'autre
        # restent avec proba NULL dans Fait_prediction_projet.
        # Solution : on normalise tout X avec le scaler fitte sur X_train,
        # et on predit sur l'integralite des projets pour la DWH.
        # Les metriques d'evaluation restent calculees sur le vrai test set.
        if save_to_dwh:
            X_all_sc    = self.scaler.transform(X)
            probas_all  = self.model.predict_proba(X_all_sc)[:, 1] * 100

            # Inclure aussi les projets live (pas de label, donc hors train/test)
            X_live, live_pids = self._build_live_vectors(df, success_ids, echec_ids)
            if len(live_pids) > 0:
                X_live_sc    = self.scaler.transform(X_live)
                probas_live  = self.model.predict_proba(X_live_sc)[:, 1] * 100
                all_pids     = np.concatenate([pids, live_pids])
                all_probas   = np.concatenate([probas_all, probas_live])
            else:
                all_pids   = pids
                all_probas = probas_all

            _save_knn_probas_to_dwh(
                knn_model        = self.model,
                probas_success   = all_probas,
                y_test           = y_test,
                y_pred           = y_pred,
                project_ids_test = all_pids.tolist(),
                n_train_projects = len(X_train),
                scrap_date       = run_date,
            )

        return self.model


# ----------------------------------------------------------------------------
# Sauvegarde DWH (fonction interne)
# ----------------------------------------------------------------------------

def _save_knn_probas_to_dwh(knn_model, probas_success,
                              y_test, y_pred,
                              project_ids_test, n_train_projects, scrap_date):
    """
    Sauvegarde les resultats du KNN dans base_traitee.

    Recoit les probas deja calculees (tableau 1D en %) pour eviter
    de relancer predict_proba, ce qui necessite de repasser X_test.

    Tables alimentees :
        - Modele_AI            : caracteristiques du modele (k, algo, date)
        - Fait_metriques_modele : accuracy, precision, recall, f1
        - Fait_prediction_projet : probabilite de succes par projet (tous les projets)
    """
    from data_to_dwh import (get_connection, get_or_create_modele,
                              get_or_create_id_date, _insert_metriques,
                              _upsert_prediction)

    conn = get_connection(db="base_traitee")
    try:
        # Enregistrement du modele dans la dimension Modele_AI
        id_modele = get_or_create_modele(
            conn,
            nom              = "KNN",
            type_algo        = "KNeighborsClassifier",
            n_estimators     = None,
            n_neighbors      = knn_model.n_neighbors,
            n_train_projects = n_train_projects,
            date_entrainement= scrap_date,
        )
        id_date = get_or_create_id_date(conn, scrap_date)
        cursor  = conn.cursor()

        # Metriques globales du modele (calculees sur le vrai test set)
        _insert_metriques(cursor, id_modele, id_date, y_test, y_pred)

        # Probabilite de succes pour TOUS les projets etiquetes
        for project_id, proba_knn in zip(project_ids_test, probas_success):
            _upsert_prediction(cursor, int(project_id), id_date,
                               col_proba="proba_knn", proba_value=float(proba_knn))

        conn.commit()
        cursor.close()
        print(f"KNN sauvegarde -> id_modele={id_modele}, id_date={id_date}")
        print(f"  {len(project_ids_test)} projets avec proba_knn enregistres.")

    except Exception as e:
        conn.rollback()
        print(f"Erreur sauvegarde KNN : {e}")
        raise
    finally:
        conn.close()


# ----------------------------------------------------------------------------
# Execution directe
# ----------------------------------------------------------------------------

if __name__ == "__main__":
    knn = KNNKickstarter()   # k selectionne automatiquement par GridSearch
    knn.train(save_to_dwh=True, scrap_date=date.today())