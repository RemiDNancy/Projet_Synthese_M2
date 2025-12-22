from datetime import datetime

import undetected_chromedriver as uc
from bs4 import BeautifulSoup
import html
import json
import time
import random

# constantes
NOMBRE_PROJETS = 50  # nombre de projets à scraper
SEUIL_FINANCEMENT = 15
POURCENTAGE_FAIBLE = 30  # pourcentage de projet n'ayant pas atteint le seuil de financement qu'on a mis en paramètre
NOMBRE_PROJETS_FAIBLE = int(NOMBRE_PROJETS * POURCENTAGE_FAIBLE / 100)
NOMBRE_PROJETS_NORMAUX = NOMBRE_PROJETS - NOMBRE_PROJETS_FAIBLE
JOURS_DEPUIS_LANCEMENT_MAX = 7  # projets lancés il y a moins de 7 jours
TEMPS_PAUSE_MIN = 4
TEMPS_PAUSE_MAX = 5
FICHIER_SORTIE = "../Followed_Projects.txt"

# config
options = uc.ChromeOptions()
options.add_argument("--window-size=1920,1080")
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")

# initialisation
uc_driver = uc.Chrome(options=options, use_subprocess=True)

liens = []
page = 1
nb_faibles_recoltes = 0
nb_normaux_recoltes = 0
mode_newest = False  # bascule en mode "newest" quand les normaux sont complets

try:
    while len(liens) < NOMBRE_PROJETS:
        # Bascule en mode "newest" si les projets normaux sont complets
        if nb_normaux_recoltes >= NOMBRE_PROJETS_NORMAUX and not mode_newest:
            mode_newest = True
            page = 1  #on reset le numéro de page

        # Choisit le bon tri
        sort_param = "newest" if mode_newest else "magic"
        url = f"https://www.kickstarter.com/discover/advanced?sort={sort_param}&page={page}"
        print(
            f"Scraping page {page} ({sort_param}) : ({len(liens)}/{NOMBRE_PROJETS} projets - {nb_faibles_recoltes}/{NOMBRE_PROJETS_FAIBLE} faibles, {nb_normaux_recoltes}/{NOMBRE_PROJETS_NORMAUX} normaux)")

        uc_driver.get(url)

        # pause aléatoire
        pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
        time.sleep(pause)

        # récupère les cartes des projets
        soup_donnees = BeautifulSoup(uc_driver.page_source, "html.parser")
        cards = soup_donnees.select("div.js-react-proj-card")

        # si aucune "cards" trouvée on arrête
        if len(cards) == 0:
            print("Aucun projets\n")
            break

        for card in cards:
            # cas d'arrêts
            if len(liens) >= NOMBRE_PROJETS:
                break

            donnees_projet = card.get("data-project")

            if not donnees_projet:
                continue
            try:
                donnees_projet = html.unescape(donnees_projet)
                donnees_json = json.loads(donnees_projet)

                # on récupère l'URL et le pourcentage
                lien = donnees_json.get("urls", {}).get("web", {}).get("project")
                pourcentage_finance = donnees_json.get("percent_funded", 0)
                nom = donnees_json.get("name", "Sans nom")
                categorie = donnees_json.get("category", {}).get("name", "N/A")

                # Calcul des jours depuis le lancement
                launched_at = donnees_json.get("launched_at")
                if launched_at:
                    date_lancement = datetime.fromtimestamp(launched_at)
                    date_actuelle = datetime.now()
                    jours_depuis_lancement = (date_actuelle - date_lancement).days
                else:
                    jours_depuis_lancement = 999  #valeur élevée pour sortir lors de la condition

                if not lien:
                    continue

                # Vérifier que le projet a été lancé il y a moins de 7 jours
                if jours_depuis_lancement > JOURS_DEPUIS_LANCEMENT_MAX:
                    continue

                # En mode "newest" on cherche uniquement les projets faibles
                if mode_newest:
                    if pourcentage_finance <= SEUIL_FINANCEMENT and nb_faibles_recoltes < NOMBRE_PROJETS_FAIBLE:
                        nb_faibles_recoltes += 1
                        liens.append(lien)
                        print(f"    FAIBLE [{categorie}] {nom} - {pourcentage_finance:.1f}% - lancé il y a {jours_depuis_lancement}j")
                # En mode normal on collecte les deux types
                else:
                    if pourcentage_finance <= SEUIL_FINANCEMENT and nb_faibles_recoltes < NOMBRE_PROJETS_FAIBLE:
                        nb_faibles_recoltes += 1
                        liens.append(lien)
                        print(f"    FAIBLE [{categorie}] {nom} - {pourcentage_finance:.1f}% - lancé il y a {jours_depuis_lancement}j")
                    elif pourcentage_finance > SEUIL_FINANCEMENT and nb_normaux_recoltes < NOMBRE_PROJETS_NORMAUX:
                        nb_normaux_recoltes += 1
                        liens.append(lien)
                        print(f"    NORMAL [{categorie}] {nom} - {pourcentage_finance:.1f}% - lancé il y a {jours_depuis_lancement}j")

            except (json.JSONDecodeError, KeyError, AttributeError):
                continue

        page += 1

    print(f"\nURL collectés : {len(liens)} ({nb_faibles_recoltes} faibles, {nb_normaux_recoltes} normaux)\n")

except Exception as e:
    print(f"Erreur : {e}")

finally:
    uc_driver.quit()

# sauvegarder les liens dans Followed_Projects.txt
if liens:
    with open(FICHIER_SORTIE, "w", encoding="utf-8") as f:
        for lien in liens:
            f.write(lien + "\n")
    print(f"{len(liens)} liens enregistrés dans {FICHIER_SORTIE}\n")
else:
    print("Aucun lien collecté\n")