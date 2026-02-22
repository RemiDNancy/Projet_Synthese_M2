# Merci de ne pas push vos informations sur le Git!
import os


# Adapter le chemin si necessaire pour le navigateur Google Chrome
chrome_path = "C:\Program Files\Google\Chrome\Application\chrome.exe"

# Profil Chrome persistant (les cookies Cloudflare survivent entre les sessions)
CHROME_PROFILE_DIR = os.path.expanduser("~/.chrome-scraper-profile")

# Résolutions courantes pour varier le viewport
VIEWPORTS = [
    (1920, 1080),
    (1366, 768),
    (1536, 864),
    (1440, 900),
    (1280, 720),
    (1600, 900),
    (1280, 800),
]

# Proxy résidentiel (laisser None si pas de proxy)
# Exemples de format :
#   "http://user:pass@host:port"
#   "socks5://host:port"
PROXY = None

# ProtonVPN — rotation de pays entre les batches
# Mettre USE_PROTONVPN = True pour activer la rotation VPN
USE_PROTONVPN = False
VPN_COUNTRIES = ["US", "NL", "JP", "DE", "FR", "SE", "CH", "GB", "CA", "AU"]
