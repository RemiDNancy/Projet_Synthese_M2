import os
import json
from datetime import datetime
from db import get_conn
import shutil
import re

base_dir = os.path.dirname(os.path.abspath(__file__))
raw_dir = os.path.join(base_dir, "donnees_json")
processed_dir = os.path.join(base_dir, "processed")

# Crée le dossier processed s'il n'existe pas
os.makedirs(processed_dir, exist_ok=True)

# Liste pour stocker le contenu de tous les JSON
all_json_data = []

# Parcourt tous les fichiers JSON
for filename in os.listdir(raw_dir):
    if filename.endswith(".json"):
        file_path = os.path.join(raw_dir, filename)
        with open(file_path, encoding="utf-8") as f:
            data = json.load(f)
            # Stocke dans la variable
            all_json_data.append({
                "filename": filename,
                "content": data
            })

# Connexion à la BDD et insertion

conn = get_conn()
cursor = conn.cursor()

for file_data in all_json_data:
    filename = file_data["filename"]
    data = file_data["content"]

    # Scrap date pour MySQL
    scrap_date_str = filename.replace(".json", "")
    scrap_date_obj = datetime.strptime(scrap_date_str, "%d-%m-%Y")
    scrap_date_sql = scrap_date_obj.strftime("%Y-%m-%d")

    for entry in data:
        if "project" in entry:
            project = entry["project"]
        elif "head" in entry:
            project = entry["head"]
        else:
            print("Entrée non traitable :", entry)
            continue

        creator = entry.get("creator")
        if not creator:
            print("Entrée sans creator :", entry)
            continue
        creator_name = entry.get("creator", {}).get("name")

        # CREATOR

        cursor.execute("""
        INSERT INTO CREATOR
        (creator_id, creator_name, biography,
         launched_projects_count, backings_count,
         is_fb_connected, nb_websites, last_login)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON DUPLICATE KEY UPDATE creator_name=VALUES(creator_name)
        """, (
            creator["id"],
            creator["name"],
            creator.get("biography"),
            creator["launchedProjects"]["totalCount"],
            creator["backingsCount"],
            creator["isFacebookConnected"],
            len(creator["websites"]),
            creator["lastLogin"]
        ))

        # PROJECT

        created_at = datetime.fromtimestamp(
            project["timeline"]["edges"][0]["node"]["timestamp"]
        )
        deadline = datetime.fromtimestamp(project["deadlineAt"])

        image_url = project.get("imageUrl")

        category = project.get("category", {})
        parent_category = category.get("parentCategory", {})

        parent_category_name = parent_category.get("name") if parent_category else None
        category_name = category.get("name")

        cursor.execute("""
        INSERT INTO PROJECT
        (project_id,id_creator,title,description,
        category,subcategory,location,url,image_url,
        currency,goal_amount,is_project_we_love,
        created_at,deadline_at)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        ON DUPLICATE KEY UPDATE title=VALUES(title)
        """, (
            project["pid"],
            creator["id"],
            project["name"],
            project["description"],
            parent_category_name,
            category_name,
            project["location"]["displayableName"],
            project["url"],
            image_url,
            project["currency"],
            float(project["goal"]["amount"]),
            project["isProjectWeLove"],
            created_at,
            deadline
        ))

        # PROJECT EVOLUTION
        cursor.execute("""
        INSERT INTO PROJECT_EVOLUTION
        (project_id,scrap_date,pledged_amount,
        backers_count,percent_funded,
        updates_count,comments_count,current_state)
        VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
        ON DUPLICATE KEY UPDATE pledged_amount=VALUES(pledged_amount)
        """, (
            project["pid"],
            scrap_date_sql,
            float(project["pledged"]["amount"]),
            project["backersCount"],
            project["percentFunded"],
            0,
            project["commentsCount"],
            project["state"]
        ))

        # PROJECT_COMMENTS

        project = entry.get("project", {})
        project_id = project.get("pid")

        comments = entry.get("comments", [])

        for comment in comments:

            pseudo = comment.get("pseudo")
            text = comment.get("text")
            upload = comment.get("uploadTime")

            if upload:
                date = datetime.fromtimestamp(int(upload)).date()
            else:
                date = None

            cursor.execute("""
                            INSERT INTO PROJECT_COMMENT
                            (project_id, parent_comment_id, pseudo, comment_text, comment_date, is_creator_reply)
                            VALUES (%s,%s,%s,%s,%s,%s)
                        """, (
                project_id,
                None,
                pseudo,
                text,
                date,
                False
            ))

            parent_id = cursor.lastrowid

            for reply in comment.get("replies", []):

                r_pseudo = reply.get("pseudo")
                r_text = reply.get("text")

                upload_r = reply.get("uploadTime")

                if upload_r:
                    r_date = datetime.fromtimestamp(int(upload_r)).date()
                else:
                    r_date = None

                cursor.execute("""
                    INSERT INTO PROJECT_COMMENT
                    (project_id,parent_comment_id,pseudo,
                     comment_text,comment_date,is_creator_reply)
                    VALUES (%s,%s,%s,%s,%s,%s)
                """, (
                    project_id,
                    parent_id,
                    r_pseudo,
                    r_text,
                    r_date,
                    r_pseudo == creator_name
                ))

        rewards_data = entry.get("rewards", {})

        # fusionner available + gone
        all_rewards = rewards_data.get("available", []) + rewards_data.get("gone", [])

        for r in all_rewards:

            # enlève devise du prix

            price_str = r.get("price", "0")
            price = float(re.sub(r"[^\d.]", "", price_str)) if price_str else 0

            delivery = r.get("delivery")
            if delivery:
                delivery = datetime.strptime(delivery, "%Y-%m-%d").date()

            # REWARD
            cursor.execute("""
                INSERT INTO REWARD
                (project_id, reward_name, reward_description,
                    price_amount, estimated_delivery)
                VALUES (%s,%s,%s,%s,%s)
            """, (
                project_id,
                r.get("name"),
                r.get("desc"),
                price,
                delivery
            ))

            reward_id = cursor.lastrowid

            # ITEMS

            for item in r.get("items", []):
                # exempl "Quantité : 3" -> 3
                qty = re.sub(r"[^\d]", "", item.get("quantity", ""))

                cursor.execute("""
                    INSERT INTO REWARD_ITEM
                    (reward_id,item_name,item_quantity)
                    VALUES (%s,%s,%s)
                """, (
                    reward_id,
                    item.get("name"),
                    qty
                ))

            # OPTIONS

            for opt in r.get("options", []):
                cursor.execute("""
                    INSERT INTO REWARD_OPTION
                    (reward_id,option_name,option_price,option_description)
                    VALUES (%s,%s,%s,%s)
                """, (
                    reward_id,
                    opt.get("name"),
                    opt.get("price"),
                    opt.get("desc")
                ))

            # EVOLUTION

            cursor.execute("""
                INSERT INTO REWARD_EVOLUTION
                (reward_id,scrap_date,
                    remaining_quantity,backers_on_reward)
                VALUES (%s,%s,%s,%s)
            """, (
                reward_id,
                scrap_date_sql,
                r.get("left"),
                r.get("backers")
            ))

    conn.commit()

    # Déplacer le fichier dans processed
    shutil.move(os.path.join(raw_dir, filename), processed_dir)
    print("Fichier déplacé dans processed :", filename)

cursor.close()
conn.close()
print("Ingestion terminée")
