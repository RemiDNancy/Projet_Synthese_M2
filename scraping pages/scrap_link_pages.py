from datetime import datetime
import os
import undetected_chromedriver as uc
from bs4 import BeautifulSoup
import html
import json
import time
import random

# constantes
NOMBRE_PROJETS = 100
SEUIL_FINANCEMENT = 15
POURCENTAGE_FAIBLE = 60
NOMBRE_PROJETS_FAIBLE = int((NOMBRE_PROJETS / 10) * POURCENTAGE_FAIBLE / 100)
NOMBRE_PROJETS_NORMAUX = int((NOMBRE_PROJETS / 10) - NOMBRE_PROJETS_FAIBLE)
JOURS_DEPUIS_LANCEMENT_MAX = 7
TEMPS_PAUSE_MIN = 4
TEMPS_PAUSE_MAX = 5
FICHIER_SORTIE = "../Followed_Projects.txt"

# catégories
CATEGORIES = [
    ("Art", "https://www.kickstarter.com/discover/categories/art"),
    ("BD", "https://www.kickstarter.com/discover/categories/comics"),
    ("Design", "https://www.kickstarter.com/discover/categories/design"),
    ("Mode", "https://www.kickstarter.com/discover/categories/fashion"),
    ("Cinéma", "https://www.kickstarter.com/discover/categories/film%20%26%20video"),
    ("Gastronomie", "https://www.kickstarter.com/discover/categories/food"),
    ("Jeux", "https://www.kickstarter.com/discover/categories/games"),
    ("Musique", "https://www.kickstarter.com/discover/categories/music"),
    ("Photographie", "https://www.kickstarter.com/discover/categories/photography"),
    ("Technologie", "https://www.kickstarter.com/discover/categories/technology"),
]

# config chrome
options = uc.ChromeOptions()
options.add_argument("--window-size=1920,1080")
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")

uc_driver = uc.Chrome(options=options, use_subprocess=True, version_main=144)



# OUTILS
def charger_liens_existants(fichier):
    """Charge les liens déjà présents pour éviter les doublons."""
    liens = set()
    if os.path.exists(fichier):
        with open(fichier, "r", encoding="utf-8") as f:
            for ligne in f:
                lien = ligne.strip()
                if lien:
                    liens.add(lien)
    return liens


def pause_aleatoire():
    time.sleep(random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX))


def jours_depuis_lancement(launched_at):
    if not launched_at:
        return 999
    date_lancement = datetime.fromtimestamp(launched_at)
    return (datetime.now() - date_lancement).days


def construire_url(url_base, tri, page):
    if "?" in url_base:
        return f"{url_base}&sort={tri}&page={page}"
    return f"{url_base}?sort={tri}&page={page}"


def extraire_cartes(page_source):
    soup = BeautifulSoup(page_source, "html.parser")
    return soup.select("div.js-react-proj-card")


def extraire_projet(carte):
    donnees = carte.get("data-project")
    if not donnees:
        return None

    try:
        donnees = html.unescape(donnees)
        projet = json.loads(donnees)

        return {
            "lien": projet.get("urls", {}).get("web", {}).get("project"),
            "pourcentage": projet.get("percent_funded", 0),
            "nom": projet.get("name", "Sans nom"),
            "launched_at": projet.get("launched_at"),
        }
    except (json.JSONDecodeError, TypeError):
        return None


#SCRAPER LIENS
def collecter_projets_categorie(nom_categorie, url_categorie, liens_deja_vus):
    liens = []
    nb_faibles = 0
    nb_normaux = 0
    page = 1
    mode_newest = False
    contrainte_7_jours = True
    pages_sans_resultat = 0

    while len(liens) < 10:
        tri = "newest" if mode_newest else "magic"
        url = construire_url(url_categorie, tri, page)
        print(f"[{nom_categorie}] page {page} ({tri})")
        uc_driver.get(url)
        pause_aleatoire()

        cartes = extraire_cartes(uc_driver.page_source)
        if not cartes:
            pages_sans_resultat += 1
            if pages_sans_resultat >= 3 and contrainte_7_jours:
                contrainte_7_jours = False
                print(f"[{nom_categorie}] 3 pages sans résultat, suppression contrainte 7 jours\n")
                pages_sans_resultat = 0
                page = 1
                continue
            page += 1
            continue

        ajouts_sur_page = 0

        for carte in cartes:
            if len(liens) >= 10:
                break

            projet = extraire_projet(carte)
            if not projet or not projet["lien"]:
                continue

            # évite doublons fichier + run
            if projet["lien"] in liens_deja_vus:
                continue

            jours = jours_depuis_lancement(projet["launched_at"])
            if contrainte_7_jours and jours > JOURS_DEPUIS_LANCEMENT_MAX:
                continue

            # faible financement
            if projet["pourcentage"] <= SEUIL_FINANCEMENT:
                if nb_faibles >= NOMBRE_PROJETS_FAIBLE:
                    continue
                nb_faibles += 1

            else:
                if nb_normaux >= NOMBRE_PROJETS_NORMAUX:
                    continue
                nb_normaux += 1
                if nb_normaux >= NOMBRE_PROJETS_NORMAUX:
                    mode_newest = True
                    page = 1

            liens.append(projet["lien"])
            liens_deja_vus.add(projet["lien"])
            ajouts_sur_page += 1

            print(
                f"    {projet['nom']} - {projet['pourcentage']}% "
                + (f"- {jours}j" if contrainte_7_jours else "")
            )

        if ajouts_sur_page == 0:
            pages_sans_resultat += 1
            if pages_sans_resultat >= 3 and contrainte_7_jours:
                contrainte_7_jours = False
                print(f"[{nom_categorie}] suppression contrainte 7 jours\n")
                pages_sans_resultat = 0
                page = 1
                continue
        else:
            pages_sans_resultat = 0

        page += 1

    print(f"[{nom_categorie}] collecté : {len(liens)}\n")
    return liens


#EXECUTION
liens_final = []
liens_vus = charger_liens_existants(FICHIER_SORTIE)
print(f"{len(liens_vus)} liens déjà présents dans le fichier\n")

try:
    for nom, url in CATEGORIES:
        liens_categorie = collecter_projets_categorie(nom, url, liens_vus)
        liens_final.extend(liens_categorie)

finally:
    uc_driver.quit()


#SAUVEGARDE
if liens_final:
    with open(FICHIER_SORTIE, "a", encoding="utf-8") as f:
        for lien in liens_final:
            f.write(lien + "\n")

    print(f"{len(liens_final)} nouveaux liens ajoutés dans {FICHIER_SORTIE}")
else:
    print("Aucun nouveau lien trouvé")