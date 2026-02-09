# main_execution.py
import undetected_chromedriver as uc
import time
import os
import datetime
from random import randrange

from scrapper import scrap
import user_info

# ===== CONFIG =====
PROJETS_PAR_HEURE = 9
SECONDES_PAR_HEURE = 3600
FICHIER_URLS = "Followed_Projects.txt"

USER_AGENTS = [
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36",
]



if __name__ == "__main__":

    #reset json du jour s'il existe
    dossier_json = "donnees_json"
    os.makedirs(dossier_json, exist_ok=True)

    nom_fichier = datetime.datetime.now().strftime("%d-%m-%Y") + ".json"
    chemin_fichier = os.path.join(dossier_json, nom_fichier)

    if os.path.exists(chemin_fichier):
        print(f"[INFO] Suppression du fichier existant : {chemin_fichier}")
        os.remove(chemin_fichier)
    else:
        print(f"[INFO] Aucun fichier JSON existant pour aujourd'hui")

    #url
    with open(FICHIER_URLS, "r", encoding="utf-8") as f:
        urls = [l.strip() for l in f if l.strip()]

    totalproject = 0
    scrappedproject = 0
    totaltime = 0

    #traitement par batch (PROJETS_PAR_HEURE / heure)
    for batch_start in range(0, len(urls), PROJETS_PAR_HEURE):

        batch = urls[batch_start: batch_start + PROJETS_PAR_HEURE]
        batch_start_time = time.time()

        #user agent
        current_user_agent = USER_AGENTS[randrange(len(USER_AGENTS))]
        print(f"\n[INFO] Nouveau batch ({len(batch)} projets)")
        print(f"[INFO] User-Agent : {current_user_agent}")

        #chrome
        options = uc.ChromeOptions()
        options.binary_location = user_info.chrome_path

        options.add_argument("--window-size=1920,1080")
        options.add_argument("--disable-gpu")
        options.add_argument("--no-sandbox")
        options.add_argument("--disable-dev-shm-usage")
        options.add_argument("--remote-debugging-port=0")
        options.add_argument(f"--user-agent={current_user_agent}")

        #driver
        driver = uc.Chrome(
            options=options,
            version_main=144,
            use_subprocess=True,
            headless=False
        )

        #scrap du batch
        for url in batch:
            totalproject += 1
            print(f"[SCRAP] {url}")

            x, y = scrap(url, driver)
            totaltime += y

            if x == 0:
                scrappedproject += 1
            else:
                print("[WARN] Échec du scrap")

        driver.quit()
        print("[INFO] Navigateur fermé")

        #pause jusqu'à l'heure suivante
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
