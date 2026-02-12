""" This script extract comments for BERT sentiment analysis """

# Connexion to DB + 
from db_connection import read_sql_df


# Function to extract comments from database of ALL projects
def extract_bert_features(project_ids=None): 
    sql = """
    SELECT 
        comment_id,
        project_id,
        comment_text,
        comment_date,
        is_creator_reply
    FROM PROJECT_COMMENT
    WHERE comment_text IS NOT NULL
        {project_filter}            
    """
    # placeholder
    project_filter = f"AND project_id IN ({','.join(map(str, project_ids))})" if project_ids else ""
    sql = sql.format(project_filter=project_filter)
    
    return read_sql_df(sql)


# Function to Merge BERT sentiment results into KNN/RF features
# def add_bert_sentiment(knn_rf_df, bert_sentiment_df):
   
#     # Assume bert_sentiment_df has: project_id, avg_sentiment_score, positive_ratio, etc.
#     return knn_rf_df.merge(
#         bert_sentiment_df, 
#         on='project_id', 
#         how='left',
#         suffixes=('', '_bert')
#     ).drop(columns=['avg_sentiment_score', 'positive_ratio', ...])  # Drop placeholders

