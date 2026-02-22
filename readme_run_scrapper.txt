Ce document explique comment crée une tache dans Windows pour faire tourner le scrapper. Il est utile aussi de faire le changement des chemins dans le fichier 

1. Ouvrir "cmd" en tant qu'administrateur et taper (en remplacant le chemin par la valeur adequate de run_scrapper.bat ci-dessous):

schtasks /create /tn "KickstarterScraper" /tr "C:\chemin\vers\run_scrapper.bat" /sc daily /st 10:00 /rl highest

Commandes utiles:
- Verifier si la tache existe: schtasks /query /tn "KickstarterScraper"
- Tester la commande maintenant: schtasks /run /tn "KickstarterScraper"
- Supprimer la commande: schtasks /delete /tn "KickstarterScraper" /f
