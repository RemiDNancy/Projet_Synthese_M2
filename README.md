# Projet Synthese M2 -  Kickstarter Scraper

Scraper automatisé pour collecter les données de projets Kickstarter. Le système sélectionne des projets récents par catégorie, puis extrait leurs informations détaillées (entête, description, rewards, FAQ, updates, commentaires) et les sauvegarde en JSON.

## Architecture

```
├── main_execution.py              # Orchestrateur principal (batches, VPN, retry)
├── scrapper.py                    # Logique de scraping d'un projet individuel
├── user_info.py                   # Configuration utilisateur (Chrome, proxy, VPN)
├── scraping pages/
│   └── scrap_link_pages.py        # Collecte des URLs de projets par catégorie
├── Followed_Projects.txt          # Liste des URLs à scraper (générée par scrap_link_pages)
├── donnees_json/                  # Données collectées (un fichier JSON par jour)
│   └── logs_erreurs/              # Logs d'erreurs de scraping par jour
├── .github/workflows/
│   └── routine.yml                # GitHub Actions -  exécution planifiée
└── requirements.txt               # Dépendances Python
```

## Fonctionnement

### 1. Collecte des URLs (`scraping pages/scrap_link_pages.py`)

Parcourt 10 catégories Kickstarter (Art, BD, Design, Mode, Cinéma, Gastronomie, Jeux, Musique, Photographie, Technologie) et sélectionne 10 projets par catégorie (100 au total) selon ces critères :

- **Projets récents** : lancés depuis 7 jours max (contrainte levée si pas assez de résultats)
- **Mix de financement** : 60% de projets faiblement financés (≤15%) et 40% normaux
- **Tri** : commence par `magic` (pertinence), passe en `newest` une fois le quota normal atteint

Les URLs sont écrites dans `Followed_Projects.txt`.

### 2. Scraping des projets (`main_execution.py` + `scrapper.py`)

Les projets sont traités par **batches de 10** avec un seul driver Chrome par batch.

**Données collectées par projet :**
- **Entête** : métadonnées du projet (depuis `data-initial` de `react-project-header`)
- **Description** : titres, texte, liens, images
- **Rewards** : disponibles et épuisées, avec prix, backers, items, options, livraison
- **FAQ** : questions/réponses avec date de mise à jour
- **Updates** : titre et date de publication
- **Commentaires** : pseudo, date, texte et réponses

Les résultats sont sauvegardés dans `donnees_json/<DD-MM-YYYY>.json`.

## Anti-détection

- **VPN rotation** : changement d'IP ProtonVPN (pays aléatoire) avant chaque batch (il est nécessaire d'avoir un [compte protonVPN](https://account.protonvpn.com/signup?plan=free))
- **Viewport aléatoire** : résolution choisie parmi 7 tailles courantes
- **Stealth JS** : injection de `window.chrome.runtime` via CDP
- **Comportement humain** :
  - `human_pause()` -  pauses aléatoires avec 15% de chance d'une longue pause (15-30s)
  - `human_click()` -  clic avec offset souris aléatoire
  - `random_scroll()` -  pattern de scroll non-déterministe
- **Cloudflare** : détection et attente automatique de résolution du challenge (jusqu'à 360s)
- **Profil Chrome persistant** : les cookies Cloudflare survivent entre les sessions
- **Proxy** : support optionnel de proxy HTTP/SOCKS5

## Retry et nettoyage

- **1 retry** par projet en cas d'échec, avec 15s d'attente
- **`kill_chrome()`** : nettoyage des processus Chrome/chromedriver zombies (cross-platform) au démarrage, entre les batches et lors des retries
- **Logging** : les erreurs et succès après retry sont enregistrés dans `donnees_json/logs_erreurs/<DD-MM-YYYY>_erreurs.txt`

## Installation

```bash
pip install -r requirements.txt
```

Dépendances principales : `undetected-chromedriver`, `selenium`, `beautifulsoup4`

## Configuration (`user_info.py`)

| Variable | Description | Défaut |
|---|---|---|
| `chrome_path` | Chemin vers l'exécutable Chrome | `C:\Program Files\Google\Chrome\Application\chrome.exe` |
| `CHROME_PROFILE_DIR` | Répertoire du profil Chrome persistant | `~/.chrome-scraper-profile` |
| `VIEWPORTS` | Liste de résolutions pour la randomisation | 7 résolutions courantes |
| `PROXY` | Proxy HTTP/SOCKS5 (optionnel) | `None` |
| `USE_PROTONVPN` | Activer la rotation VPN ProtonVPN | `False` |
| `VPN_COUNTRIES` | Liste des pays pour la rotation VPN | US, NL, JP, DE, FR, SE, CH, GB, CA, AU |

## Utilisation

```bash
# 1. Collecter les URLs de projets
python "scraping pages/scrap_link_pages.py"

# 2. Lancer le scraping
python main_execution.py
```

## Sortie

Le fichier JSON du jour contient un tableau d'objets, un par projet scrapé avec succès :

```json
[
  {
    "project": { "name": "...", "goal": {...}, "pledged": {...}, ... },
    "creator": { "name": "...", ... },
    "collaborators": [...],
    "description": { "titre": [...], "texte": [...], "links": [...], "imgs": [...] },
    "rewards": { "available": [...], "gone": [...] },
    "comments": [{ "pseudo": "...", "text": "...", "replies": [...] }]
  }
]
```
