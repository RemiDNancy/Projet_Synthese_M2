# main.py
from scrapper import scrap

if __name__ == "__main__":
    filename = "Followed_Projects.txt"
    with open(filename, 'r', encoding='utf-8') as fichier:
        for ligne in fichier:
            ligne = ligne.strip()
            if ligne:
                scrap(ligne)
else:
    print("not executed as main")