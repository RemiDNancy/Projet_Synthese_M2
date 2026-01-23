# main.py
from scrapper import scrap
import undetected_chromedriver as uc
import time
from random import randrange

import user_info

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

    driver = uc.Chrome(options=options, version_main=142, use_subprocess=True, headless=False)

    with open(filename, 'r', encoding='utf-8') as fichier:
        for ligne in fichier:
            ligne = ligne.strip()
            if ligne:
                totalproject += 1
                x, y = scrap(ligne, driver)
                if x == 1:
                    print("erreur with agent: "+ current_user + " spend : "+str(y))
                else:
                    scrappedproject += 1
                totaltime += y
            
            if totalproject % 8 == 0:
                driver.quit()
                time.sleep(20)
                options = uc.ChromeOptions()
                options.add_argument("--window-size=1920,1080")
                options.add_argument("--disable-gpu")
                options.add_argument("--no-sandbox")
                options.binary_location = user_info.chrome_path
                current_user = user_agent[randrange(len(user_agent))]
                print ("\n ###### \n"+current_user+"\n#####\n")
                options.add_argument(f"--user-agent={current_user}")
                driver = uc.Chrome(options=options, version_main=142, use_subprocess=True, headless=False, )
    
    driver.quit()

    print("total :" + str(totalproject))
    print("success :" + str(scrappedproject))
    print("time :" + str(totaltime))
    print("average :" + str(totaltime / scrappedproject))
else:
    print("not executed as main")