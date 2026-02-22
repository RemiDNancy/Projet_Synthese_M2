# main_execution.py
import undetected_chromedriver as uc
import subprocess
import time
import os
import datetime
import random
from scrapper import log_erreur, apply_stealth
from scrapper import scrap
import user_info
import platform

PROJETS_PAR_BATCH = 10
FICHIER_URLS = "Followed_Projects.txt"

ATTENTE_RETRY_SECONDES = 15  # 15 sec (le nouveau driver suffit à reset l'état)
NB_RETRY = 1  # 1 seule tentative supplémentaire

_projet_total = 0
_nb_proj_scrap = 0
_temps_total = 0


def rotate_vpn():
    """Déconnecte puis reconnecte ProtonVPN sur un pays aléatoire"""
    country = random.choice(user_info.VPN_COUNTRIES)
    print(f"[VPN] Changement d'IP — rotation vers {country}...")

    try:
        subprocess.run(["sudo", "-E", "protonvpn", "disconnect"], timeout=15, capture_output=True)
        time.sleep(3)
    except Exception as e:
        print(f"[VPN] Erreur déconnexion: {e}")

    try:
        result = subprocess.run(
            ["sudo", "-E", "protonvpn", "connect", "--country", country],
            timeout=30, capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"[VPN] Connecté à {country}")
        else:
            print(f"[VPN] Échec connexion {country}: {result.stderr.strip()}")
    except Exception as e:
        print(f"[VPN] Erreur connexion: {e}")

    # Attendre que le VPN se stabilise
    time.sleep(5)


def kill_chrome():
    """Tue les processus Chrome/chromedriver restants d'une session précédente"""
    try:
        if platform.system() == "Windows":
            subprocess.run(["taskkill", "/f", "/im", "chrome.exe"], capture_output=True)
            subprocess.run(["taskkill", "/f", "/im", "chromedriver.exe"], capture_output=True)
        else:
            subprocess.run(["pkill", "-f", "chrome"], capture_output=True)
            subprocess.run(["pkill", "-f", "chromedriver"], capture_output=True)
    except Exception:
        pass
    time.sleep(2)


def new_driver():
    viewport = random.choice(user_info.VIEWPORTS)
    options = uc.ChromeOptions()
    options.binary_location = user_info.chrome_path

    options.add_argument(f"--window-size={viewport[0]},{viewport[1]}")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--disable-gpu")
    options.add_argument(f"--user-data-dir={user_info.CHROME_PROFILE_DIR}")

    if user_info.PROXY:
        options.add_argument(f"--proxy-server={user_info.PROXY}")

    driver = uc.Chrome(
        options=options,
        version_main=145,
        use_subprocess=True,
        headless=False
    )

    apply_stealth(driver)
    print(f"[INFO] Viewport : {viewport[0]}x{viewport[1]}")
    return driver


def run_batch(batch, total_urls):
    """Traite un batch séquentiellement avec un seul driver"""
    global _projet_total, _nb_proj_scrap, _temps_total

    kill_chrome()
    driver = new_driver()

    for url in batch:
        _projet_total += 1
        print(f"[SCRAP] ({_projet_total}/{total_urls}) {url}")
        attempt = 0

        while attempt <= NB_RETRY:
            x, y = scrap(url, driver)
            _temps_total += y

            if x == 0:
                _nb_proj_scrap += 1

                if attempt > 0:
                    try:
                        project_name = driver.title.strip() if driver.title else url
                    except Exception:
                        project_name = url
                    log_erreur(url, project_name, retry_success=True)
                break

            attempt += 1
            if attempt > NB_RETRY:
                print(f"[WARN] Échec ({attempt}/{NB_RETRY}) on passe au suivant")
                break

            print(f"[WARN] Retry ({attempt}/{NB_RETRY}) dans {ATTENTE_RETRY_SECONDES}s")

            try:
                driver.quit()
            except Exception:
                pass

            time.sleep(ATTENTE_RETRY_SECONDES)
            kill_chrome()
            driver = new_driver()

    try:
        driver.quit()
    except Exception:
        pass
    time.sleep(5)  # laisser Chrome se fermer complètement
    print("[INFO] Navigateur fermé")


if __name__ == "__main__":

    # Nettoyer les processus Chrome restants d'une exécution précédente
    kill_chrome()

    # reset json du jour s'il existe
    dossier_json = "donnees_json"
    os.makedirs(dossier_json, exist_ok=True)

    nom_fichier = datetime.datetime.now().strftime("%d-%m-%Y") + ".json"
    chemin_fichier = os.path.join(dossier_json, nom_fichier)

    if os.path.exists(chemin_fichier):
        print(f"[INFO] Suppression du fichier existant : {chemin_fichier}")
        os.remove(chemin_fichier)
    else:
        print(f"[INFO] Aucun fichier JSON existant pour aujourd'hui")

    # url
    with open(FICHIER_URLS, "r", encoding="utf-8") as f:
        urls = [l.strip() for l in f if l.strip()]

    print(f"[INFO] {len(urls)} projets à scraper")

    # traitement par batch
    for batch_start in range(0, len(urls), PROJETS_PAR_BATCH):

        batch = urls[batch_start: batch_start + PROJETS_PAR_BATCH]
        batch_num = batch_start // PROJETS_PAR_BATCH + 1
        batch_start_time = time.time()

        # rotation VPN avant chaque batch
        if user_info.USE_PROTONVPN:
            rotate_vpn()

        print(f"\n[INFO] Batch {batch_num} ({len(batch)} projets)")

        run_batch(batch, len(urls))

        batch_elapsed = time.time() - batch_start_time
        print(f"[INFO] Batch {batch_num} terminé en {int(batch_elapsed)}s ({batch_elapsed / 60:.1f} min)")


    print("\n===== FIN SCRAP DU JOUR =====")
    print(f"Total projets : {_projet_total}")
    print(f"Succès        : {_nb_proj_scrap}")
    print(f"Temps total   : {int(_temps_total)}s ({_temps_total / 60:.1f} min)")

    if _nb_proj_scrap > 0:
        print(f"Moyenne / projet : {_temps_total / _nb_proj_scrap:.2f} s")
