import random
from playwright.sync_api import sync_playwright
import time

user_agents = [
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:89.0) Gecko/20100101 Firefox/89.0",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.1.1 Safari/605.1.15",
    #"Mozilla/5.0 (iPhone; CPU iPhone OS 14_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1",
]

def move_mouse_randomly(page):
    """Déplace la souris de manière aléatoire sur la page."""
    viewport_width = 1280
    viewport_height = 720

    # Génère des coordonnées aléatoires
    x = random.randint(50, viewport_width - 50)
    y = random.randint(50, viewport_height - 50)

    page.mouse.move(x, y, steps=10)

def scroll_randomly(page):
    scroll_amount = random.randint(100, 500)
    page.mouse.wheel(0, scroll_amount)

def scrap(url: str):
    html = {"head": "#react-project-header", "desc": "#react-campaign", "rewards": ["#react-rewards-tab", ".p3.pt4"], "creator": ["#react-creator-tab", ".grid-col-12.grid-col-8-md"], 
            "faq": ["#project-faqs", ".mb5.grid-col-8-sm"], "updates": ["#project-post-interface", ".grid-col-12.grid-col-8-md.grid-col-offset-2-md.mb6"], "comments": ["#react-project-comments", ".text-center.bg-grey-200.p2.type-14"]}

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=False ,
                                    args=[
                                    '--disable-blink-features=AutomationControlled',
                                    '--no-sandbox',
                                    '--disable-setuid-sandbox',
                                    '--disable-infobars',
                                    '--disable-web-security',
                                    '--disable-features=IsolateOrigins,site-per-process'
        ])

        page = browser.new_page()

        page.evaluate("""() => {
            Object.defineProperty(navigator, 'webdriver', {
                get: () => undefined
            });
            Object.defineProperty(navigator, 'plugins', {
                get: () => [{
                    name: "Chrome PDF Plugin",
                    description: "Portable Document Format",
                    filename: "internal-pdf-viewer",
                    length: 1
                },
                {
                    name: "Shockwave Flash",
                    description: "Shockwave Flash 32.0 r0",
                    filename: "pepflashplayer.dll",
                    length: 1
                }]
            });
            Object.defineProperty(navigator, 'languages', {
                get: () => ['fr-FR', 'fr']
            });
        }""")
        page.set_extra_http_headers({
            'User-Agent': random.choice(user_agents)
        })
        
        page.set_viewport_size({"width": 1280, "height": 720})

        page.goto(url)

        move_mouse_randomly(page)

        # Wait for JavaScript to load
        page.wait_for_load_state("domcontentloaded")

        #page.wait_for_selector("#react-campaign")
        html["desc"] = page.locator("#react-campaign").inner_html() #page.query_selector("#react-campaign")
        html["head"] = page.locator("#react-project-header").inner_html() #page.query_selector("#react-project-header")

        # Go through the differents tabs of kick
        for key in html.keys():
            if key == "head" or key == "desc":
                continue

            move_mouse_randomly(page)

            page.wait_for_timeout(random.randint(100, 3000))

            if random.random() < 0.6:
                scroll_randomly(page)
        
            # Locate and click to change tab
            page.locator("#"+key+"-emoji").click()

            locator = page.locator(html[key][0])

            #pat = ".*?"+html[key][1]+".*?"
            #expect(locator).to_contain_text(html[key][1], timeout=10000)
            #locator.get_by_text(re.compile(pat, re.IGNORECASE))
            #expect(locator.get_by_text(re.compile(pat, re.IGNORECASE))).to_be_visible(timeout=10000)
            
            locator.locator(html[key][1]).first.inner_html()

            #page.wait_for_timeout(2000) rewards-tab--available 

            html[key] = locator.inner_html()

        # Close the browser
        browser.close()

        # Save or process the HTML
        
        name: str = "Downloaded_html/"+ str(round(time.time())) +".html"
        with open(name, "w", encoding="utf-8") as f:
            for key, value in html.items():
                f.write("<!--- " + key + " --->\n" + value + "\n")


