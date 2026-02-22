import datetime

import undetected_chromedriver as uc
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver import ActionChains
import time
import random
import json
import os

import user_info

# constantes
TEMPS_PAUSE_MIN = 4 # temps de pause aléatoire au cas ou
TEMPS_PAUSE_MAX = 8
CHANCE_LONG_PAUSE = 0.15 # 15% de chance d'une longue pause "lecture"
LONG_PAUSE_MIN = 15
LONG_PAUSE_MAX = 30


def human_pause(min_s=TEMPS_PAUSE_MIN, max_s=TEMPS_PAUSE_MAX):
    """Pause variable avec chance occasionnelle d'une longue pause 'lecture'"""
    if random.random() < CHANCE_LONG_PAUSE:
        pause = random.uniform(LONG_PAUSE_MIN, LONG_PAUSE_MAX)
    else:
        pause = random.uniform(min_s, max_s)
    time.sleep(pause)


def human_click(driver, element):
    """Déplace la souris vers l'élément avec un offset aléatoire, puis clique"""
    actions = ActionChains(driver)
    offset_x = random.randint(-5, 5)
    offset_y = random.randint(-3, 3)
    actions.move_to_element_with_offset(element, offset_x, offset_y)
    actions.pause(random.uniform(0.1, 0.4))
    actions.click()
    actions.perform()


def random_scroll(driver, target_element=None):
    """Pattern de scroll aléatoire - certaines étapes sont sautées aléatoirement"""
    actions = ActionChains(driver)
    if target_element:
        actions.scroll_to_element(target_element)
        actions.pause(random.uniform(0.2, 0.6))
    if random.random() < 0.7:
        actions.scroll_by_amount(0, random.randrange(-20, 50))
        actions.pause(random.uniform(0.1, 0.4))
    if random.random() < 0.5 and target_element:
        actions.move_to_element_with_offset(target_element, random.randrange(-50, 50), random.randrange(-50, 50))
        actions.pause(random.uniform(0.1, 0.5))
    if random.random() < 0.6:
        actions.scroll_by_amount(0, random.randrange(50, 400))
    actions.perform()


def apply_stealth(driver):
    """Injecte du JS minimal - UC gère déjà navigator.webdriver au niveau binaire"""
    stealth_js = """
    window.chrome = window.chrome || {};
    window.chrome.runtime = window.chrome.runtime || {};
    """
    driver.execute_cdp_cmd("Page.addScriptToEvaluateOnNewDocument", {"source": stealth_js})


def wait_for_cloudflare(driver, timeout=360):
    """Attend que le challenge Cloudflare se résolve (manuellement ou automatiquement)"""
    start = time.time()
    while time.time() - start < timeout:
        title = driver.title.lower() if driver.title else ""
        page_src = driver.page_source[:2000].lower() if driver.page_source else ""
        # Cloudflare challenge détecté
        if "just a moment" in title or "cloudflare" in title or "challenge-platform" in page_src:
            elapsed = int(time.time() - start)
            print(f"[CF] Challenge Cloudflare détecté... attente ({elapsed}s/{timeout}s)")
            time.sleep(3)
            continue
        # Pas (ou plus) de Cloudflare
        return True
    print("[CF] Timeout - le challenge Cloudflare n'a pas été résolu")
    return False


# Data to collect
html = {"rewards": ["react-rewards-tab", "#react-rewards-tab"],
        "faq": ["project-faqs", "#project-faqs"],
        "updates": ["project-post-interface", "#project-post-interface"],
        "comments": ["react-project-comments", "#react-project-comments"]}
unused_html = {"creator": ["react-creator-tab", ".kds-flex.kds-items-center.kds-gap-05.kds-mb-06"],}


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
        key = "gone"
        if container.find_element(By.CSS_SELECTOR, ".support-700.normal.kds-heading.type-21.mb0.display-none-md").get_attribute("innerHTML") == "Available rewards":
            key = "available"
        for element in container.find_elements("css selector", "article"):
            reward = {}
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
            res[key].append(reward)
    results["rewards"] = res


def scrap_faq(driver: uc.Chrome, results, current):
    res = []
    results["faq"] = res
    current["state"] = "faq"
    faq = driver.find_elements(By.CSS_SELECTOR, ".type-14.navy-700.medium")
    if not faq: return
    faq = driver.find_element(By.ID, "project-faqs").find_element(By.CSS_SELECTOR, "ul").find_elements(By.CSS_SELECTOR, "li")
    for element in faq:
        question = {}
        question["question"] = element.find_element("css selector", ".type-14.navy-700.medium").get_attribute('innerHTML')
        question["answer"] = []
        for part in element.find_elements("css selector", "p"):
            question["answer"].append(part.get_attribute('innerHTML'))
        question["lastUpdated"] = element.find_element("css selector", "time").get_attribute('datetime')
        res.append(question)
    results["faq"] = res


def scrap_updates(driver: uc.Chrome, results, current):
    res = []
    current["state"] = "update"
    container = driver.find_elements(By.CSS_SELECTOR, ".truncated-post.soft-black.block")
    for element in container:
        update = {}
        update["name"] = element.find_element(By.CSS_SELECTOR, ".kds-mb-04.kds-type.kds-type-heading-xl").get_attribute('innerHTML')
        update["uploadTime"] = element.find_element(By.CSS_SELECTOR, ".kds-text-secondary.kds-type.kds-type-body-sm").get_attribute('innerHTML')
        res.append(update)
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
            comment["replies"].append(rep)
        res.append(comment)

    results["comments"] = res


scrap_functions = {
    "rewards": scrap_rewards,
    "faq": scrap_faq,
    "updates": scrap_updates,
}


def scrap(url, driver, skip_faq_updates=True):
    start_time = time.time()
    total_time = 0
    results = {}
    success = False
    current = {"state": "none"}

    try:
        print("Scraping project")
        driver.get(url)

        # Attendre que Cloudflare se résolve
        if not wait_for_cloudflare(driver):
            raise Exception("Cloudflare challenge non résolu")

        ###########################################################################
        # Scrap l'entête
        print("scrap entete et description")
        # Attends que la page charge (la description est toujours présente)
        WebDriverWait(driver, 25).until(
            EC.presence_of_element_located((By.ID, "react-campaign"))
        )

        # Cherche l'entete, l'element react-project-header n'existe pas si le projet est finit
        try:
            element = driver.find_elements(By.ID, "react-project-header")
            if element:
                scrap_entete(driver, results, current)
            else:
                results["head"] = "<p>No Head, project ended</p>"
        except Exception as e:
            print(f"[WARN] Échec scrap entête: {type(e).__name__}: {e}")

        try:
            scrap_description(driver, results, current)
        except Exception as e:
            print(f"[WARN] Échec scrap description: {type(e).__name__}: {e}")

        ###########################################################################
        # pause aléatoire
        human_pause()

        ###########################################################################
        #                   Parcourir les pages du projet                         #
        ###########################################################################
        for key in html.keys():

            if (key == "faq" or key == "updates") and skip_faq_updates:
                continue

            try:
                tab = driver.find_element(By.ID, key+"-emoji")
                driver.execute_script("arguments[0].scrollIntoView({block: 'center'});", tab)
                time.sleep(0.5)

                # JS click pour éviter ElementClickInterceptedException (overlay)
                driver.execute_script("arguments[0].click();", tab)

                WebDriverWait(driver, 10).until(
                    EC.presence_of_element_located((By.CSS_SELECTOR, str(html[key][1])))
                )

                human_pause()

                scrap_functions.get(key, scrap_comments)(driver, results, current)

                iframe = driver.find_element(By.ID, str(html[key][0]))
                random_scroll(driver, iframe)
            except Exception as e:
                print(f"[WARN] Échec scrap {key}: {type(e).__name__}: {e}")

        total_time = time.time() - start_time
        print(f"Projet collecté en {total_time:.1f}s\n")

        success = True  # on ne sauvegarde que si on a réussi à scrap

    except Exception as e:
        project_name = ""
        try:
            if driver.title:
                project_name = driver.title.strip()
            if not project_name:
                header = driver.find_elements(By.ID, "react-project-header")
                if header:
                    jsondata = header[0].get_attribute("data-initial")
                    if jsondata:
                        j = json.loads(jsondata)
                        name_from_json = j.get("project", {}).get("name")
                        if name_from_json:
                            project_name = name_from_json
        except Exception:
            pass  # driver mort, on utilise l'URL comme nom
        
        if not project_name:
            project_name = url
        
        print(f"[ERREUR] {project_name} | {url}")
        print(f"{type(e).__name__}: {e}")
        log_erreur(url, project_name, e)
        return 1, time.time() - start_time

    finally:
        #sauvegarde  si succès
        if success and results:
            folder = "donnees_json"
            if not os.path.exists(folder):
                os.makedirs(folder)

            file_path = os.path.join(folder, datetime.datetime.now().strftime("%d-%m-%Y") + ".json")
            data = []

            if os.path.exists(file_path):
                try:
                    with open(file_path, "r", encoding="utf-8") as f:
                        data = json.load(f)
                        if not isinstance(data, list):
                            data = [data]
                except (json.JSONDecodeError, IOError):
                    data = []

            data.append(results)

            with open(file_path, "w", encoding="utf-8") as fichier:
                json.dump(data, fichier, indent=4, ensure_ascii=False)
            print(f"Projet sauvegardé dans {file_path}")
        else:
            if not success:
                print("Échec scrap -> rien à sauvegarder\n")

    return 0, total_time



#Fonction qui permet d'ajouter dans un fichier log les erreurs de scraping par projet
def log_erreur(url: str, project_name: str, exc: BaseException = None, retry_success: bool = False):
    try:
        date_str = datetime.datetime.now().strftime("%d-%m-%Y")
        log_dir = os.path.join("donnees_json", "logs_erreurs")
        os.makedirs(log_dir, exist_ok=True)

        log_file = os.path.join(log_dir, f"{date_str}_erreurs.txt")

        with open(log_file, "a", encoding="utf-8") as f:
            if retry_success:
                f.write(
                    f"RETRY SUCCESS | {project_name} | {url}\n"
                )
            elif exc:
                f.write(
                    f"{project_name} | {url} | {type(exc).__name__}: {str(exc)}\n"
                )
    except Exception:
        pass



if __name__ == "__main__":
    viewport = random.choice(user_info.VIEWPORTS)
    options = uc.ChromeOptions()
    options.add_argument(f"--window-size={viewport[0]},{viewport[1]}")
    options.add_argument("--no-sandbox")
    options.add_argument(f"--user-data-dir={user_info.CHROME_PROFILE_DIR}")
    options.binary_location = user_info.chrome_path

    driver = uc.Chrome(options=options, version_main=145, use_subprocess=True, headless=False)
    apply_stealth(driver)
    scrap("https://www.kickstarter.com/projects/lifespirittarot/bricks-of-fate-tarot-built-brick-by-brick", driver)
