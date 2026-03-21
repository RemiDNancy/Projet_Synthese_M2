"""
run_all.py
----------
Script d'orchestration : lance le Random Forest puis le KNN sur la meme date.

Les deux modeles ecrivent dans Fait_prediction_projet avec le meme id_date.
Grace a la contrainte UNIQUE (id_projet, id_date) et au ON DUPLICATE KEY UPDATE,
les probabilites des deux modeles se retrouvent sur la meme ligne.

Emplacement : placer ce fichier dans KNN_AND_RF/ et lancer depuis ce dossier.

Usage :
    python run_all.py                  # date DWH = aujourd'hui
    python run_all.py 2026-03-21       # date DWH specifique (format ISO)
"""

import sys
import os

# S'assurer que le dossier KNN_AND_RF est dans le path Python
# pour que les imports (random_forest_model, knn_script, etc.) fonctionnent
# independamment de l'endroit depuis lequel le script est lance.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from datetime import date

# ----------------------------------------------------------------------------
# Date commune aux deux modeles
# ----------------------------------------------------------------------------
# Cette date sera enregistree dans la DWH pour les deux modeles.
# Elle doit etre identique pour que les lignes de Fait_prediction_projet
# se fusionnent correctement via ON DUPLICATE KEY UPDATE.
if len(sys.argv) > 1:
    run_date = date.fromisoformat(sys.argv[1])
else:
    run_date = date.today()

print(f"\n{'='*60}")
print(f"  RUN DATE (DWH) : {run_date}")
print(f"{'='*60}\n")

# ----------------------------------------------------------------------------
# Etape 1 : Random Forest
# ----------------------------------------------------------------------------
# data_date=None : pas de filtre sur la date de scraping.
#                  Le RF utilise tous les snapshots disponibles dans
#                  PROJECT_EVOLUTION, filtre a mi-campagne en interne.
# run_date       : date enregistree dans la DWH (pas un filtre de donnees).
print("ETAPE 1 - Random Forest\n")
from random_forest_model import RandomForestKickstarter

rf = RandomForestKickstarter()
rf.train(data_date=None, run_date=run_date, save_to_dwh=True)

# ----------------------------------------------------------------------------
# Etape 2 : KNN
# ----------------------------------------------------------------------------
# Le KNN charge egalement toutes les donnees disponibles (pas de filtre date).
# scrap_date = run_date pour garantir la meme cle (id_projet, id_date)
# que le RF dans Fait_prediction_projet.
print("\nETAPE 2 - KNN\n")
from knn_script import KNNKickstarter

knn = KNNKickstarter()
knn.train(save_to_dwh=True, scrap_date=run_date)

# ----------------------------------------------------------------------------
# Confirmation
# ----------------------------------------------------------------------------
print(f"\n{'='*60}")
print(f"  Les deux modeles ont tourne sur id_date={run_date.strftime('%Y%m%d')}")
print(f"  Fait_prediction_projet mis a jour correctement.")
print(f"{'='*60}\n")