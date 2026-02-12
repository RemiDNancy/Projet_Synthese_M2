from db_connection import read_sql_df
import pandas as pd

# Extract features for KNN/RF at given scrap_date
def extract_knn_rf_features(scrap_date=None):
    
    sql = """
    SELECT 
        pe.project_id,
        pe.scrap_date,
        
        -- Project features
        p.goal_amount,
        DATEDIFF(p.deadline_at, p.created_at) as duration_days,
        p.category as category_encoded,
        p.subcategory as subcategory_encoded,
        p.is_project_we_love,
        
        -- Creator features
        c.launched_projects_count,
        c.backings_count,
        c.is_fb_connected,
        
        -- Reward aggregates
        COUNT(DISTINCT r.reward_id) as num_rewards,
        AVG(r.price_amount) as avg_reward_price,
        
        -- Temporal features
        pe.pledged_amount,
        pe.backers_count,
        pe.percent_funded,
        pe.updates_count,
        DATEDIFF(pe.scrap_date, p.created_at) as days_since_launch
        
    FROM PROJECT_EVOLUTION pe
    JOIN PROJECT p ON pe.project_id = p.project_id
    JOIN CREATOR c ON p.id_creator = c.creator_id
    LEFT JOIN REWARD r ON p.project_id = r.project_id
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
        pe.percent_funded,
        pe.updates_count
    """
    
    date_filter = f"AND pe.scrap_date = '{scrap_date}'" if scrap_date else ""
    sql = sql.format(date_filter=date_filter)
    
    df = read_sql_df(sql)
    
    # Add funding_velocity
    df = df.sort_values(['project_id', 'scrap_date'])
    df['funding_velocity'] = df.groupby('project_id')['pledged_amount'].diff()
    
    # PLACEHOLDER SENTIMENT FEATURES (until BERT is ready)
    df['avg_sentiment_score'] = 0.0
    df['positive_ratio'] = 0.5
    df['creator_response_rate'] = 0.0
    df['sentiment_volatility'] = 0.0
    df['sentiment_trend'] = 0.0
    
    return df
