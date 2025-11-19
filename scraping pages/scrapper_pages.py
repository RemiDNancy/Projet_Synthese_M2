import undetected_chromedriver as uc
from bs4 import BeautifulSoup
import html
import json
import pandas
import time
import random

# constantes
PAGE_SCRAPE = 5
TEMPS_PAUSE_MIN = 4 # temps de pause aléatoire au cas ou
TEMPS_PAUSE_MAX = 5
FICHIER_SORTIE = "kickstarter_projects.csv"

# config
options = uc.ChromeOptions()
options.add_argument("--window-size=1920,1080")
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")

# initialisation
uc_driver = uc.Chrome(options=options, use_subprocess=True)

projects = []
try:
    for page in range(1, PAGE_SCRAPE + 1):
        url = f"https://www.kickstarter.com/discover/advanced?sort=magic&page={page}"
        print(f"Scraping page {page} :")

        uc_driver.get(url)

        # on fait une pause d'une durée aléatoire pour réduire les chances d'être perçu comme un bot
        pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
        time.sleep(pause)

        # récupère les cartes des projets de la page
        soup_donnees = BeautifulSoup(uc_driver.page_source, "html.parser")
        cards = soup_donnees.select("div.js-react-proj-card")

        print(f"{len(cards)} projets trouvés\n")

        for card in cards:
            # on récupère l'attribut 'data-project' qui contient toutes les infos en JSON
            donnees_projet = card.get("data-project")

            # vérifie si donnees_projet existe, pour pas avoir d'erreur on passe à la suite
            if not donnees_projet:
                continue
            try:
                # format le texte correctement et récupère le json
                donnees_projet = html.unescape(donnees_projet)
                donnees_json = json.loads(donnees_projet)

                # on extrait les données du JSON
                projects.append({
                    "titre": donnees_json.get("name"),
                    "categorie": donnees_json.get("category", {}).get("name"),
                    "createur": donnees_json.get("creator", {}).get("name"),
                    "recolte": donnees_json.get("pledged"),
                    "objectif": donnees_json.get("goal"),
                    "etat": donnees_json.get("state"),
                    "URL": donnees_json.get("urls", {}).get("web", {}).get("project"),
                    "nombre contributeurs": donnees_json.get("backers_count"),
                    "pourcentage finance": donnees_json.get("percent_funded"),
                    "pays": donnees_json.get("country"),
                })
            except (json.JSONDecodeError, KeyError, AttributeError):
                continue

    print(f"Projets collectés : {len(projects)}\n")

except Exception as e:
    print(f"Erreur : {e}")

finally:
    uc_driver.quit()


#convertir et sauvegarder les projets
if projects:
    df = pandas.DataFrame(projects)
    df.to_csv(FICHIER_SORTIE, index=False, sep=';', encoding="utf-8-sig")
    print(f"{len(df)} projets enregistrés dans {FICHIER_SORTIE}\n")
else:
    print("Aucun projet collecté \n")