import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import ActionChains
import time
import random
import json
import user_info

# constantes
TEMPS_PAUSE_MIN = 4 # temps de pause aléatoire au cas ou
TEMPS_PAUSE_MAX = 5
# Data to collect
html = {"rewards": ["react-rewards-tab", ".col-span-12.col-span-8-md.col-span-9-lg.flex.flex-column.gap8.pt2.pt8-md"], "creator": ["react-creator-tab", ".kds-flex.kds-items-center.kds-gap-05.kds-mb-06"], 
        "faq": ["project-faqs", ".mb5.grid-col-8-sm"], "updates": ["project-post-interface", ".grid-col-12.grid-col-8-md.grid-col-offset-2-md.mb6"], "comments": ["react-project-comments", ".text-center.bg-grey-200.p2.type-14"]}



def scrap_entete(driver: uc.Chrome, results):
    
    return results

def scrap_description(driver: uc.Chrome, results):

    return results

def scrap_rewards(driver: uc.Chrome, results):
    
    return results

def scrap_creator(driver: uc.Chrome, results):
    
    return results

def scrap_faq(driver: uc.Chrome, results):
    
    return results

def scrap_updates(driver: uc.Chrome, results):
    
    return results

def scrap_comments(driver: uc.Chrome, results):
    
    return results

scrap_functions = {
    "rewards": scrap_rewards,
    "creator": scrap_creator,
    "faq": scrap_faq,
    "updates": scrap_updates,
}

def scrap(url):
    # initialisation
    # config
    options = uc.ChromeOptions()
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.binary_location = user_info.chrome_path

    driver = uc.Chrome(options=options, version_main=142, use_subprocess=True, headless=False)

    start_time = time.time()
    results = {}
    try:
        print("Scraping project")

        # Go to the page
        driver.get(url)

        ###########################################################################
        # Scrap l'entête
        print("scrap entete et description")
        # Attends que la page charge (la description est toujours présente)
        element = WebDriverWait(driver, 10).until(
            EC.presence_of_element_located((By.ID, "react-campaign"))
        )
        results = scrap_description(driver, results)

        # Cherche l'entete, l'element react-project-header n'existe pas si le projet est finit
        element = driver.find_element(By.ID, "react-project-header")
        if element:
            results = scrap_entete(driver, results)
        else:
            results["head"] = "<p>No Head, project ended</p>"
        
        ###########################################################################

        # on fait une pause d'une durée aléatoire pour réduire les chances d'être perçu comme un bot
        pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
        time.sleep(pause)

        ###########################################################################
        #                   Parcourir les pages du projet                         #
        ###########################################################################
        for key in html.keys():
        
            print("scrap : "+ str(key))

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
            print("balise css found")

            # Appel la fonction de scrap correspondante
            results = scrap_functions.get(key, scrap_comments)(driver, results)

            # Mouvement de souris imittant un comportement humain 
            iframe = driver.find_element(By.ID, str(html[key][0]))
            ActionChains(driver)\
                .scroll_to_element(iframe)\
                .perform()
            
            ActionChains(driver)\
                .scroll_by_amount(0, random.randrange(0,30))\
                .perform()

            ActionChains(driver) \
                .move_to_element_with_offset(iframe, random.randrange(-50, 50), random.randrange(-50, 50)) \
                .perform()
            
            ActionChains(driver)\
                .scroll_by_amount(0, random.randrange(20,100))\
                .perform()
        
        total_time= time.time() - start_time
        print("Projet collecté en "+ str(total_time) +"\n")

    except Exception as e:
        print(f"Erreur : {e.__cause__}")

    finally:
        driver.quit()


    # sauvegarder les projets
    if results:
        name: str = "Downloaded_html/"+ str(round(time.time())) +".json"
        # Écriture du dictionnaire dans un fichier JSON
        with open(name, "w", encoding="utf-8") as fichier:
            json.dump(results, fichier, indent=4)
    else:
        print("Projet non collecté \n")

if __name__ == "__main__":
    scrap("https://www.kickstarter.com/projects/1472560351/wings-of-light-the-hummingbird-symphony")