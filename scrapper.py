import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time
import random

# constantes
TEMPS_PAUSE_MIN = 4 # temps de pause aléatoire au cas ou
TEMPS_PAUSE_MAX = 5
# Data to collect
html = {"head": "react-project-header", "desc": "react-campaign", "rewards": ["react-rewards-tab", ".col-span-12.col-span-8-md.col-span-9-lg.flex.flex-column.gap8.pt2.pt8-md"], "creator": ["react-creator-tab", ".kds-flex.kds-items-center.kds-gap-05.kds-mb-06"], 
        "faq": ["project-faqs", ".mb5.grid-col-8-sm"], "updates": ["project-post-interface", ".grid-col-12.grid-col-8-md.grid-col-offset-2-md.mb6"], "comments": ["react-project-comments", ".text-center.bg-grey-200.p2.type-14"]}

# config
options = uc.ChromeOptions()
options.add_argument("--window-size=1920,1080")
options.add_argument("--disable-gpu")
options.add_argument("--no-sandbox")
options.binary_location = "/usr/bin/chromium"

def scrap(url):
    # initialisation
    driver = uc.Chrome(options=options, use_subprocess=True)

    start_time = time.time()
    results = {}
    try:
        print("Scraping project")

        # Go to the page
        driver.get(url)

        ###########################################################################
        # Scrap l'entête
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "react-project-header"))
        )
        results["head"] = element.get_attribute("innerHTML")
        # Scrap la description
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "react-campaign"))
        )
        results["desc"] = element.get_attribute("innerHTML")
        ###########################################################################

        # on fait une pause d'une durée aléatoire pour réduire les chances d'être perçu comme un bot
        pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
        time.sleep(pause)

        ###########################################################################
        #                   Parcourir les pages du projet                         #
        ###########################################################################
        for key in html.keys():

            # L'entête et la description sont déjà faite donc skip
            if key == "head" or key == "desc":
                continue

            # on fait une pause d'une durée aléatoire pour réduire les chances d'être perçu comme un bot
            pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
            time.sleep(pause)

            # Trouver l'onglet de la page et cliquer dessus
            driver.find_element(By.ID, key+"-emoji").click()

            print("waiting for the css class")
            # Attendre jusqu'à 10 secondes que le contenue de la balise apparaisse (json de l'onglet terminé)
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, str(html[key][1])))
            )
            print("css found")

            # Récupérer le balise de l'onglet
            balise = WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.ID, str(html[key][0])))
            )

            results[key] = balise.get_attribute("innerHTML")
        
        total_time= time.time() - start_time
        print("Projet collecté en "+ str(total_time) +"\n")

    except Exception as e:
        print(f"Erreur : {e}")

    finally:
        driver.quit()


    #convertir et sauvegarder les projets
    if results:
        name: str = "Downloaded_html/"+ str(round(time.time())) +".html"
        with open(name, "w", encoding="utf-8") as f:
            for key, value in results.items():
                f.write("<!--- " + key + " --->\n" + value + "\n")
    else:
        print("Aucun projet collecté \n")

if __name__ == "__main__":
    scrap("https://www.kickstarter.com/projects/1472560351/wings-of-light-the-hummingbird-symphony")