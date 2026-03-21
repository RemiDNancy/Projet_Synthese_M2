from db_connection import read_sql_df
import pandas as pd

# Extract features for KNN/RF at given scrap_date
# - KNN  : utilise percent_funded + current_state pour labelliser ses projets
# - RF   : les supprime lui-même (leakage), construit sa cible séparément

def extract_knn_rf_features(scrap_date=None):
    
    sql = """
    SELECT 
        pe.project_id,
        pe.scrap_date,
        
        -- ✅ Project features (known at launch)
        p.goal_amount,
        DATEDIFF(p.deadline_at, p.created_at)   AS duration_days,
        p.category                               AS category_encoded,
        p.subcategory                            AS subcategory_encoded,
        p.is_project_we_love,
        
        -- ✅ Creator features (known at launch)
        c.launched_projects_count,
        c.backings_count,
        c.is_fb_connected,
        
        -- ✅ Reward aggregates (known at launch)
        COUNT(DISTINCT r.reward_id)              AS num_rewards,
        AVG(r.price_amount)                      AS avg_reward_price,
        
        -- ✅ Mid-campaign state
        pe.pledged_amount,
        pe.backers_count,
        pe.updates_count,
        DATEDIFF(pe.scrap_date, p.created_at)    AS days_since_launch,

        -- ⚠️ Gardés pour le KNN (labellisation) — le RF les supprime lui-même
        pe.percent_funded,
        pe.current_state
        
    FROM PROJECT_EVOLUTION pe
    JOIN PROJECT p         ON pe.project_id  = p.project_id
    JOIN CREATOR c         ON p.id_creator   = c.creator_id
    LEFT JOIN REWARD r     ON p.project_id   = r.project_id
    WHERE 1=1
        {date_filter}
    GROUP BY 
        pe.project_id,
        pe.scrap_date,
        p.goal_amount,
        p.deadline_at,
        p.created_at,
        p.category,
        p.subcategory,
        p.is_project_we_love,
        c.launched_projects_count,
        c.backings_count,
        c.is_fb_connected,
        pe.pledged_amount,
        pe.backers_count,
        pe.updates_count,
        pe.percent_funded,
        pe.current_state;
    """
    
    date_filter = f"AND pe.scrap_date = '{scrap_date}'" if scrap_date else ""
    sql = sql.format(date_filter=date_filter)
    
    df = read_sql_df(sql)
    
    # ✅ Funding velocity
    df = df.sort_values(['project_id', 'scrap_date'])
    df['funding_velocity'] = df.groupby('project_id')['pledged_amount'].diff()

    # ✅ Funding ratio à mi-campagne (légitime)
    df['funding_ratio_mid'] = df['pledged_amount'] / df['goal_amount'].replace(0, 1)

    # PLACEHOLDER SENTIMENT (remplacé par BERT dans le RF)
    df['avg_sentiment_score']   = 0.0
    df['positive_ratio']        = 0.5
    df['creator_response_rate'] = 0.0
    df['sentiment_volatility']  = 0.0
    df['sentiment_trend']       = 0.0
    
    return df