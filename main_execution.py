# main_execution.py
import undetected_chromedriver as uc
import time
import os
import datetime
from random import randrange
from scrapper import log_erreur


from scrapper import scrap
import user_info


PROJETS_PAR_HEURE = 10
SECONDES_PAR_HEURE = 3600
FICHIER_URLS = "Followed_Projects.txt"

ATTENTE_RETRY_SECONDES = 100  # 100 sec
NB_RETRY = 1  # 1 seule tentative supplémentaire

USER_AGENTS = [
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
]


def new_driver(user_agent: str):
    options = uc.ChromeOptions()
    options.binary_location = user_info.chrome_path

    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--remote-debugging-port=0")
    options.add_argument(f"--user-agent={user_agent}")

    driver = uc.Chrome(
        options=options,
        version_main=144,
        use_subprocess=True,
        headless=False
    )
    return driver


if __name__ == "__main__":

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

    projet_total = 0
    nb_proj_scrap = 0
    temps_total = 0

    # traitement par batch (PROJETS_PAR_HEURE / heure)
    for batch_start in range(0, len(urls), PROJETS_PAR_HEURE):

        batch = urls[batch_start: batch_start + PROJETS_PAR_HEURE]
        batch_start_time = time.time()

        # user agent
        user_agent = USER_AGENTS[randrange(len(USER_AGENTS))]
        print(f"\n[INFO] Nouveau batch ({len(batch)} projets)")
        print(f"[INFO] User-Agent : {user_agent}")

        # driver
        driver = new_driver(user_agent)

        # scrap du batch
        for url in batch:
            projet_total += 1
            print(f"[SCRAP] {url}")

            attempt = 0

            while attempt <= NB_RETRY:
                x, y = scrap(url, driver)
                temps_total += y

                if x == 0:
                    nb_proj_scrap += 1

                    # si on a réussi après au moins 1 retry, on log "retry success"
                    if attempt > 0:
                        project_name = driver.title.strip() if driver.title else url
                        log_erreur(url, project_name, retry_success=True)

                    break

                attempt += 1
                if attempt > NB_RETRY:
                    print(f"[WARN] Échec ({attempt}/{NB_RETRY}) on passe au projet suivant")
                    break

                print(f"[WARN] Échec du scrap -> retry ({attempt}/{NB_RETRY}) dans {ATTENTE_RETRY_SECONDES}s (même URL)")

                # fermer le driver actuel
                try:
                    driver.quit()
                except Exception:
                    pass

                time.sleep(ATTENTE_RETRY_SECONDES)

                # nouveau user agent + nouveau driver
                user_agent = USER_AGENTS[randrange(len(USER_AGENTS))]
                print(f"[INFO] Retry avec User-Agent : {user_agent}")
                driver = new_driver(user_agent)


        # fin de batch
        try:
            driver.quit()
        except Exception:
            pass
        print("[INFO] Navigateur fermé")

        # pause jusqu'à l'heure suivante
        temps_passe = time.time() - batch_start_time
        temps_restant = SECONDES_PAR_HEURE - temps_passe

        if temps_restant > 0:
            print(f"[INFO] Pause {int(temps_restant)} secondes")
            time.sleep(temps_restant)


    print("\n===== FIN SCRAP DU JOUR =====")
    print(f"Total projets : {projet_total}")
    print(f"Succès        : {nb_proj_scrap}")
    print(f"Temps total   : {int(temps_total)} s")

    if nb_proj_scrap > 0:
        print(f"Moyenne / projet : {temps_total / nb_proj_scrap:.2f} s")
