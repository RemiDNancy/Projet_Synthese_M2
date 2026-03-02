from collections import Counter

from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import MinMaxScaler
from sklearn.neighbors import KNeighborsClassifier
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
import pandas as pd
from sklearn.model_selection import train_test_split
from features_knn_rf import extract_knn_rf_features
from tslearn.neighbors import KNeighborsTimeSeriesClassifier
import numpy as np


df = extract_knn_rf_features()

# Liste des features temporelles sélectionnées
temporal_features = [
    'launched_projects_count',
    'backings_count',
    'pledged_amount',
    'backers_count',
    'updates_count',
    'percent_funded',
    'days_since_launch',
    'funding_velocity'
]
# Liste des features non temporelles
static_features = [
    'goal_amount',
    'duration_days',
#    'category_encoded',
#    'subcategory_encoded',
    'is_project_we_love',
    'is_fb_connected',
    'num_rewards',
    'avg_reward_price'
]

# Initialisation du dictionnaire temporel
time_series_dict = {feature: {} for feature in temporal_features}

success_id = []
echec_id = []
X_static = []
# Pour chaque projet, extraire les séries temporelles de chaque feature 
for project_id, group in df.sort_values('scrap_date').groupby('project_id'):
    # Remove useless projects
    live = True
    for percentages in group['percent_funded'].values:
        if percentages >= 100:
            live = False  # Théoriquement toujours live mais réussi.
            if project_id not in success_id: success_id.append(project_id)
    for state in group['current_state'].values:
        if state == 'FAILED' or state == "CANCELED":
            live = False
            if project_id not in echec_id: echec_id.append(project_id)

    # Keep useful projects
    if not live:
        for feature in temporal_features:
            time_series_dict[feature][project_id] = group[feature].values
        # Extraire les features non temporelles (une seule val par projet)
        static_values = group[static_features].iloc[0].values.reshape(1, -1)
        X_static.append(static_values)

# Au cas où
for suc_id in success_id:
    if suc_id in echec_id: success_id.remove(suc_id)

print("Nombre de projets useful: ",time_series_dict[temporal_features[0]].__len__())
# Résultat : time_series_dict[feature][project_id] = [val1, val2, ...]


# Normaliser chaque série pour chaque feature
normalized_time_series = {feature: {} for feature in temporal_features}
X_static_normalized = []
for feature in temporal_features:
    scaler = MinMaxScaler()
    for project_id, series in time_series_dict[feature].items():
        # Reshape pour scaler car nécessite un tableau 2D puis flatten pour retourner au 1D
        normalized_series = scaler.fit_transform(series.reshape(-1, 1)).flatten()
        normalized_time_series[feature][project_id] = normalized_series
    # Ne peut pas scaler une liste d'array de la me^me façon donc on concatenate
    X_static_normalized = scaler.fit_transform(np.concatenate(X_static, axis=0))


# Ensemble d'entraînemebt et de test
X = []
y = []  # 1: succès ou 0: échec du projet
# Pour chaque project id distinct
for project_id in success_id + echec_id:
    # Récupérer les séries normalisées pour chaque feature
    project_series = []
    for feature in temporal_features:
        project_series.append(normalized_time_series[feature][project_id])

    # Transposer pour avoir des points multivariés
    multivariate_series = list(zip(*project_series))
    X.append(multivariate_series)

    # Manage labels
    if project_id in success_id :
        y.append(1)
    else:
        y.append(0)

# Quel enfer
X_combined = []
for i in range(len(X_static_normalized)):
    temporal_series = X[i]
    static_values = X_static_normalized[i]
    combined_series = [
        np.concatenate([temporal_point, static_values])
        for temporal_point in temporal_series
    ]
    X_combined.append(combined_series)
    print("projet ",i,": ",combined_series)

#for project_id in time_series_dict["percent_funded"]:

max_timesteps = max(len(objet) for objet in X_combined)
print(f"Nombre maximal de timesteps : {max_timesteps}")

# Compléter les objets avec un nombre d'observation plus bas, on complète en répétant la dernière valeur
# Car le knn veut une entrée de taille fixe
X_combined_padded = []
for objet in X_combined:
    # Si l'objet a moins de timesteps que max_timesteps
    if len(objet) < max_timesteps:
        # Répète le dernier timestep jusqu'à atteindre max_timesteps
        last_timestep = objet[-1]
        padded_objet = objet + [last_timestep.copy()] * (max_timesteps - len(objet))
        X_combined_padded.append(padded_objet)
    else:
        X_combined_padded.append(objet)

# Vérifie la longueur de chaque objet
for i, objet in enumerate(X_combined_padded):
    if len(objet) != max_timesteps : print(f"Objet {i}: {len(objet)} timesteps")
    for j, timestamp in enumerate(objet):
        if len(timestamp) != 13:
            print(f"timestamp {j}: {len(timestamp)} features")

# Convertir X_combined et y en tableaux NumPy pour la division, merci internet
X_combined_array = np.array([
    np.array(objet, dtype=float)  # Convertis chaque objet en tableau
    for objet in X_combined_padded
])
y_array = np.array(y)
# tableau de n_items, n2_observations_temporelles, n3_features

# Vérifier la forme : (n_projets, n_timesteps, n_features)
print("Forme de X_combined_array :", X_combined_array.shape)
print(X_combined_array[0].shape)


# Diviser en train/test (80% train, 20% test)
X_train, X_test, y_train, y_test = train_test_split(
    X_combined_array, y_array, test_size=0.2, random_state=42, shuffle=True
)


# Créer et entraîner le model
knn = KNeighborsTimeSeriesClassifier(n_neighbors=2, metric="dtw") # maybe add weights = distance
knn.fit(X_train, y_train)

# Prédire sur l'ensemble de test
y_pred = knn.predict(X_test)

print("Répartition des classes prédites :", Counter(y_pred))

# Calculer l'accuracy
accuracy = accuracy_score(y_test, y_pred)
print(f"Accuracy : {accuracy:.2f}")

# Afficher un rapport de classification
print("\nRapport de classification :")
print(classification_report(y_test, y_pred, zero_division=0))

# Afficher la matrice de confusion
print("\nMatrice de confusion :")
print(confusion_matrix(y_test, y_pred))


