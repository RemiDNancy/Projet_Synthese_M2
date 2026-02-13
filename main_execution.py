# main_execution.py
import undetected_chromedriver as uc
import time
import os
import datetime
from random import randrange

from scrapper import scrap
import user_info


PROJETS_PAR_HEURE = 9
SECONDES_PAR_HEURE = 3600
FICHIER_URLS = "Followed_Projects.txt"

ATTENTE_APRES_FIN_SECONDES = 2000  #environ 33 minutes

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

    totalproject = 0
    scrappedproject = 0
    totaltime = 0

    # traitement par batch (PROJETS_PAR_HEURE / heure)
    for batch_start in range(0, len(urls), PROJETS_PAR_HEURE):

        batch = urls[batch_start: batch_start + PROJETS_PAR_HEURE]
        batch_start_time = time.time()

        # user agent
        current_user_agent = USER_AGENTS[randrange(len(USER_AGENTS))]
        print(f"\n[INFO] Nouveau batch ({len(batch)} projets)")
        print(f"[INFO] User-Agent : {current_user_agent}")

        driver = new_driver(current_user_agent)

        # scrap du batch
        for url in batch:
            totalproject += 1
            print(f"[SCRAP] {url}")

            x, y = scrap(url, driver)
            totaltime += y

            if x == 0:
                scrappedproject += 1
            else:
                print("[WARN] Échec du scrap")

        try:
            driver.quit()
        except Exception:
            pass
        print("[INFO] Navigateur fermé")

        # pause jusqu'à l'heure suivante
        elapsed = time.time() - batch_start_time
        remaining = SECONDES_PAR_HEURE - elapsed

        if remaining > 0:
            print(f"[INFO] Pause {int(remaining)} secondes")
            time.sleep(remaining)
        else:
            print("[WARN] Batch plus long qu’une heure, enchaînement immédiat")

    print("\n===== FIN SCRAP DU JOUR =====")
    print(f"Total projets : {totalproject}")
    print(f"Succès        : {scrappedproject}")
    print(f"Temps total   : {int(totaltime)} s")

    if scrappedproject > 0:
        print(f"Moyenne / projet : {totaltime / scrappedproject:.2f} s")

    # =========================
    # RETRY A LA FIN (UNE FOIS)
    # =========================
    date_str = datetime.datetime.now().strftime("%d-%m-%Y")
    retry_file = os.path.join("donnees_json", "logs_erreurs", f"{date_str}_retry_urls.txt")

    if os.path.exists(retry_file):
        with open(retry_file, "r", encoding="utf-8") as f:
            retry_urls = [l.strip() for l in f if l.strip()]

        # éviter doublons
        retry_urls = list(dict.fromkeys(retry_urls))

        if retry_urls:
            print(f"\n[INFO] {len(retry_urls)} projets à retenter")
            print(f"[INFO] Attente {ATTENTE_APRES_FIN_SECONDES}s (30 min) avant retry...")
            time.sleep(ATTENTE_APRES_FIN_SECONDES)

            # nouveau driver avec nouvel agent
            current_user_agent = USER_AGENTS[randrange(len(USER_AGENTS))]
            print(f"[INFO] Retry fin de journée avec User-Agent : {current_user_agent}")
            driver = new_driver(current_user_agent)

            ok_retry = 0
            for url in retry_urls:
                print(f"[RETRY] {url}")
                x, y = scrap(url, driver)
                totaltime += y
                if x == 0:
                    ok_retry += 1
                else:
                    print("[WARN] Retry échoué")

            try:
                driver.quit()
            except Exception:
                pass
            print(f"[INFO] Retry fin de journée : {ok_retry}/{len(retry_urls)} réussis")

            #on supprime le fichier de retry une fois traité
            try:
                os.remove(retry_file)
                print("[INFO] Fichier retry supprimé")
            except Exception:
                print("[WARN] Impossible de supprimer le fichier retry")

        else:
            print("[INFO] Fichier retry présent mais vide")
    else:
        print("[INFO] Aucun retry à faire (pas de fichier retry)")
