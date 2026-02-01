import datetime

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
TEMPS_PAUSE_MAX = 8
skip = True
# Data to collect
html = {"rewards": ["react-rewards-tab", ".col-span-12.col-span-8-md.col-span-9-lg.flex.flex-column.gap8.pt2.pt8-md"], 
        "faq": ["project-faqs", ".mb5.grid-col-8-sm"], "updates": ["project-post-interface", ".grid-col-12.grid-col-8-md.grid-col-offset-2-md.mb6"], 
        "comments": ["react-project-comments", ".text-center.bg-grey-200.p2.type-14"]}
unused_html = {"creator": ["react-creator-tab", ".kds-flex.kds-items-center.kds-gap-05.kds-mb-06"],}
current = {"state":"none"}

def scrap_entete(driver: uc.Chrome, results, current):
    
    current["state"] = "entete"
    jsondata = driver.find_element(By.ID, "react-project-header").get_attribute("data-initial")

    if (jsondata):
        jsonloaded: dict = json.loads(jsondata)["project"]
        tmp1 = jsonloaded.pop("creator")
        tmp2 = jsonloaded.pop("collaborators")
        results["project"] = jsonloaded
        results["creator"] = tmp1
        results["collaborators"] = tmp2
    else:
        print("no json data")

def scrap_description(driver: uc.Chrome, results, current):
    res = {
        "titre": [],
        "texte": [],
        "links": [],
        "imgs" : []
    }
    current["state"] = "description"
    desc = driver.find_element(By.CSS_SELECTOR, ".rte__content.ck.ck-content").find_element("css selector", "div")
    for element in desc.find_elements("css selector", "p"):
        res["texte"].append(element.get_attribute('innerHTML'))

    for element in desc.find_elements("css selector", "h3"):
        res["titre"].append(element.get_attribute('innerHTML'))

    for element in desc.find_elements("css selector", "a"):
        res["links"].append(element.get_attribute('href'))
    
    for element in desc.find_elements("css selector", "img"):
        res["imgs"].append(element.get_attribute('src'))

    results["description"] = res

def scrap_rewards(driver: uc.Chrome, results, current):
    res = {
        "available": [],
        "gone": []
    }

    current["state"]  = "reward"
    containers = driver.find_elements(By.CSS_SELECTOR, "div.flex.flex-column.gap4")

    for container in containers:
        reward = {}
        key = "gone"
        if container.find_element(By.CSS_SELECTOR, ".support-700.normal.kds-heading.type-21.mb0.display-none-md").get_attribute("innerHTML") == "Available rewards":
            key = "available"
        for element in container.find_elements("css selector", "article"):
            tmp = element.find_elements("css selector", "img")
            reward["logo"] = tmp[0].get_attribute('src') if tmp else None
            reward["name"] = element.find_element("css selector", "header").find_element("css selector", "h3").get_attribute('innerHTML')
            reward["price"] = element.find_element(By.CSS_SELECTOR, ".support-700.type-18.m0.shrink0").get_attribute('innerHTML')
            tmp = element.find_elements("css selector", "time")
            reward["delivery"] = tmp[0].get_attribute('datetime') if tmp else None
            tmp = element.find_elements(By.CSS_SELECTOR, "div.flex.items-center.gap4px > span[aria-label]")
            reward["backers"] = int(str(tmp[0].get_attribute('innerHTML'))) if tmp else 0
            tmp = element.find_elements(By.CSS_SELECTOR, ".type-16.support-700.text-prewrap")
            reward["desc"] = tmp[0].get_attribute('innerHTML') if tmp else None
            tmp = element.find_elements(By.XPATH, ".//h3[contains(text(), 'Limited quantity')]/following-sibling::div[@class='type-14']")
            reward["left"] = tmp[0].get_attribute("innerHTML") if tmp else None
            tmp = element.find_elements(By.XPATH, ".//h3[contains(text(), 'Ships to')]/following-sibling::div[@class='type-14']")
            reward["shipping"] = tmp[0].get_attribute("innerHTML") if tmp else None
            reward["items"] = []
            if element.find_elements(By.CSS_SELECTOR, ".flex.flex-column.gap1"):
                for item in element.find_element(By.CSS_SELECTOR, ".flex.flex-column.gap1").find_elements(By.CSS_SELECTOR, ".border.border-support-700.mb3.py3.px3.radius4px.clip"):
                    blob = {"name": item.find_element("css selector", "h3").get_attribute('innerHTML')}
                    quant = item.find_elements("css selector", "p")
                    blob["quantity"] = quant[0].get_attribute('innerHTML') if quant else None
                    reward["items"].append(blob)
            reward["options"] = []
            if element.find_elements(By.CSS_SELECTOR, ".mt4.flex.flex-column.gap1"):
                for option in element.find_element(By.CSS_SELECTOR, ".mt4.flex.flex-column.gap1").find_elements(By.CSS_SELECTOR, ".border.border-support-700.mb3.py3.px3.radius4px.clip"):
                    blob = {}
                    blob["name"] = option.find_element("css selector", "h3").get_attribute('innerHTML')
                    tmp = option.find_elements("css selector", "p")
                    blob["price"] = tmp[0].get_attribute('innerHTML') if tmp else None
                    desc = option.find_elements(By.CSS_SELECTOR, ".type-14.lh20px.mb0.support-700")
                    blob["desc"] = desc[0].get_attribute('innerHTML') if desc else None
                    reward["options"].append(blob)
            res[key].append(reward.copy())
    results["rewards"] = res

# Unused as creator info are collected in the head
def scrap_creator(driver: uc.Chrome, results, current):
    res = {
        "tags" : "kds-flex kds-flex-wrap kds-gap-02" # repeat creator | super backer...
    }

def scrap_faq(driver: uc.Chrome, results, current):
    res = []
    results["faq"] = res

    current["state"] = "faq"

    faq = driver.find_elements(By.CSS_SELECTOR, ".type-14.navy-700.medium")

    if not faq : return 

    faq = driver.find_element(By.ID, "project-faqs").find_element(By.CSS_SELECTOR, "ul").find_elements(By.CSS_SELECTOR, "li")

    for element in faq:
        question = {}
        question["question"] = element.find_element("css selector", ".type-14.navy-700.medium").get_attribute('innerHTML')
        question["answer"] = []
        for part in element.find_elements("css selector", "p"):
            question["answer"].append(part.get_attribute('innerHTML'))
        question["lastUpdated"] = element.find_element("css selector", "time").get_attribute('datetime')
        res.append(question.copy())

    results["faq"] = res

def scrap_updates(driver: uc.Chrome, results, current):
    res = []

    current["state"] = "update"

    container = driver.find_elements(By.CSS_SELECTOR, "truncated-post soft-black block")

    for element in container:
        update = {}

        update["name"] = element.find_element(By.CSS_SELECTOR, ".kds-mb-04.kds-type.kds-type-heading-xl").get_attribute('innerHTML')
        update["uploadTime"] = element.find_element(By.CSS_SELECTOR, ".kds-text-secondary.kds-type.kds-type-body-sm").get_attribute('innerHTML')
        
        res.append(update.copy())
    
    res.reverse()
    results["updates"] = res

def scrap_comments(driver: uc.Chrome, results, current):
    res = []

    current["state"] = "comments"

    tmp = driver.find_elements(By.CSS_SELECTOR, ".bg-grey-100.border.border-grey-400.p2.mb3")
    if not tmp : 
        print("no comments")
        results["comments"] = res
        return

    comments = tmp[0].find_elements(By.CSS_SELECTOR, ":scope > li")

    for element in comments:
        comment = {}
        tmp = element.find_elements(By.CSS_SELECTOR, ":scope > div")
        if not tmp : continue
        pseudo = tmp[0].find_elements(By.CSS_SELECTOR, "span.mr2")
        if pseudo:
            comment["pseudo"] = pseudo[0].find_element(By.CSS_SELECTOR, "span").get_attribute("innerHTML")
            comment["uploadTime"] = tmp[0].find_element(By.CSS_SELECTOR, "time").get_attribute('datetime')
        else:
            comment["pseudo"] = None
            comment["uploadTime"] = None
        comment["text"] = tmp[0].find_element(By.CSS_SELECTOR, "p").get_attribute('innerHTML')
        comment["replies"] = []
        for reply in element.find_elements(By.CSS_SELECTOR, "li"):
            rep = {}
            pseudo = reply.find_elements(By.XPATH, ".//a[@class='comment-link']/preceding-sibling::span[@class='mr2']")
            if pseudo:
                rep["pseudo"] = pseudo[0].find_element(By.CSS_SELECTOR, "span").get_attribute("innerHTML")
                rep["uploadTime"] = reply.find_element(By.CSS_SELECTOR, "time").get_attribute('datetime')
            else:
                rep["pseudo"] = None
                rep["uploadTime"] = None
            rep["text"] = reply.find_element(By.CSS_SELECTOR, "p").get_attribute('innerHTML')
            comment["replies"].append(rep.copy())
        res.append(comment.copy())
    
    results["comments"] = res

scrap_functions = {
    "rewards": scrap_rewards,
    "creator": scrap_creator,
    "faq": scrap_faq,
    "updates": scrap_updates,
}

def scrap(url, driver):

    start_time = time.time()
    total_time = 0
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

        # Cherche l'entete, l'element react-project-header n'existe pas si le projet est finit
        element = driver.find_elements(By.ID, "react-project-header")
        if element:
            scrap_entete(driver, results, current)
        else:
            results["head"] = "<p>No Head, project ended</p>"
        
        scrap_description(driver, results, current)
        
        ###########################################################################

        # on fait une pause d'une durée aléatoire pour réduire les chances d'être perçu comme un bot
        pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
        time.sleep(pause)

        ###########################################################################
        #                   Parcourir les pages du projet                         #
        ###########################################################################
        for key in html.keys():

            if (key == "faq" or key == "updates") and skip:
                continue
        
            #print("scrap : "+ str(key))

            # Trouver l'onglet de la page et cliquer dessus
            driver.find_element(By.ID, key+"-emoji").click()

            # Attendre jusqu'à 10 secondes que le contenue de la balise apparaisse (json de l'onglet terminé)
            WebDriverWait(driver, 10).until(
                EC.presence_of_element_located((By.CSS_SELECTOR, str(html[key][1])))
            )

            # on fait une pause d'une durée aléatoire pour réduire les chances d'être perçu comme un bot
            pause = random.uniform(TEMPS_PAUSE_MIN, TEMPS_PAUSE_MAX)
            time.sleep(pause)

            # Appel la fonction de scrap correspondante
            scrap_functions.get(key, scrap_comments)(driver, results, current)

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
                .scroll_by_amount(0, random.randrange(100,300))\
                .perform()
        
        total_time = time.time() - start_time
        print("Projet collecté en "+ str(total_time) +"\n")

    except Exception as e:
        print(f"Erreur : {e.__traceback__}")
        print("#### "+current["state"] +" ####")
        return 1, time.time() - start_time

    finally:

        # sauvegarder les projets
        if results:
            name: str = "donnees_json/"+datetime.datetime.now().strftime("%d-%m-%Y")+".json"
            # Écriture du dictionnaire dans un fichier JSON
            with open(name, "w", encoding="utf-8") as fichier:
                json.dump(results, fichier, indent=4)
        else:
            print("Projet non collecté \n")
    
    return 0, total_time

if __name__ == "__main__":
    # initialisation
    # config
    options = uc.ChromeOptions()
    options.add_argument("--window-size=1920,1080")
    options.add_argument("--disable-gpu")
    options.add_argument("--no-sandbox")
    options.binary_location = user_info.chrome_path

    driver = uc.Chrome(options=options, version_main=144, use_subprocess=True, headless=False)
    scrap("https://www.kickstarter.com/projects/lifespirittarot/bricks-of-fate-tarot-built-brick-by-brick", driver)