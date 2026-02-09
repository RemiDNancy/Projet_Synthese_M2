# main.py
import os
from datetime import datetime
import undetected_chromedriver as uc
import time
from scrapper import scrap
from random import randrange

import user_info

PROJETS_PAR_HEURE = 17
SECONDES_PAR_HEURE = 3600


user_agent = ["Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/137.0.0.0 Safari/537.36", 
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/143.0.0.0 Safari/537.36", 
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0.0.0 Safari/537.36",
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36",
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/139.0.0.0 Safari/537.36",
              "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"]

current_user = "default"

if __name__ == "__main__":
    totaltime = 0
    totalproject = 0
    scrappedproject = 0
    filename = "Followed_Projects.txt"


    # initialisation
    # config
    options = uc.ChromeOptions()
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.binary_location = user_info.chrome_path

    # réinitialisation du fichier JSON s'il existe déjà
    dossier_json = "donnees_json"
    nom_fichier = datetime.now().strftime("%d-%m-%Y") + ".json"
    chemin_fichier = os.path.join(dossier_json, nom_fichier)

    if os.path.exists(chemin_fichier):
        print(f"[INFO] Suppression du fichier existant : {chemin_fichier}")
        os.remove(chemin_fichier)
    else:
        print(f"[INFO] Aucun fichier existant pour aujourd'hui ({nom_fichier})")


    with open(filename, 'r', encoding='utf-8') as fichier:
        urls = [ligne.strip() for ligne in fichier if ligne.strip()]

    for batch_start in range(0, len(urls), PROJETS_PAR_HEURE):
        batch = urls[batch_start:batch_start + PROJETS_PAR_HEURE]

        print(f"\n=== Nouveau batch ({len(batch)} projets) ===")
        batch_start_time = time.time()

        # Nouveau navigateur pour chaque batch (≈ 1 heure)
        options = uc.ChromeOptions()
        options.add_argument("--window-size=1920,1080")
        options.add_argument("--disable-gpu")
        options.add_argument("--no-sandbox")
        options.binary_location = user_info.chrome_path

        driver = uc.Chrome(
            options=options,
            version_main=144,  #version Chrome
            use_subprocess=True,
            headless=False
        )

        for url in batch:
            totalproject += 1
            x, y = scrap(url, driver)

            if x == 1:
                print("Erreur de scrap")
            else:
                scrappedproject += 1

            totaltime += y

        driver.quit()

        # Pause jusqu’à la prochaine heure
        elapsed = time.time() - batch_start_time
        remaining = SECONDES_PAR_HEURE - elapsed

        if remaining > 0:
            print(f"Batch terminé en {int(elapsed)}s → pause {int(remaining)}s")
            time.sleep(remaining)
        else:
            print("Batch plus long qu'une heure → enchaînement immédiat")


    print("total :" + str(totalproject))
    print("success :" + str(scrappedproject))
    print("time :" + str(totaltime))
    print("average :" + str(totaltime / scrappedproject))
else:
    print("not executed as main")