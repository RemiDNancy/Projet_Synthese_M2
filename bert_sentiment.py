"""
BERT Sentiment Analysis for Kickstarter Comments
Analyzes comment sentiment and aggregates scores per project
"""
import sys
import os
sys.path.insert(0, os.path.abspath(os.path.dirname(__file__)))

os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

import pandas as pd
import numpy as np
from transformers import pipeline
from features_bert import extract_bert_features
import warnings
warnings.filterwarnings('ignore')
from dwh_connection import write_dwh_df


class BERTSentimentAnalyzer:
    """BERT-based sentiment analyzer for project comments"""

    def __init__(self, model_name="distilbert-base-uncased-finetuned-sst-2-english"):
        print(f"Loading BERT model: {model_name}...")
        import torch
        self.sentiment_pipeline = pipeline(
            "sentiment-analysis",
            model=model_name,
            framework="pt",
            device=-1
        )
        print("Model loaded successfully!")

    def analyze_comment(self, text):
        """Analyze sentiment of a single comment"""
        if not text or pd.isna(text) or len(text.strip()) == 0:
            return {
                'sentiment_label': 'NEU',
                'sentiment_score': 0.0,
                'sentiment_confidence': 0.0
            }

        # Gestion spéciale des messages automatiques Kickstarter
        auto_messages = [
            "cette personne a annulé son engagement",
            "this person has canceled their pledge",
            "ce commentaire a été supprimé par kickstarter",
            "this comment has been deleted by kickstarter"
        ]
        if any(msg in text.lower() for msg in auto_messages):
            return {
                'sentiment_label': 'NEG',
                'sentiment_score': -0.6,
                'sentiment_confidence': 0.6
            }

        text = text[:512]

        try:
            result = self.sentiment_pipeline(text)[0]
            label = result['label'].upper()
            confidence = result['score']

            if 'POS' in label or label == 'POSITIVE':
                sentiment_score = confidence
                sentiment_label = 'POS'
            elif 'NEG' in label or label == 'NEGATIVE':
                sentiment_score = -confidence
                sentiment_label = 'NEG'
            else:
                sentiment_score = 0.0
                sentiment_label = 'NEU'

            return {
                'sentiment_label': sentiment_label,
                'sentiment_score': sentiment_score,
                'sentiment_confidence': confidence
            }

        except Exception as e:
            print(f"Error analyzing comment: {e}")
            return {
                'sentiment_label': 'NEU',
                'sentiment_score': 0.0,
                'sentiment_confidence': 0.0
            }

    def analyze_comments_batch(self, comments_df):
        """Analyze all comments in a DataFrame"""
        print(f"\nAnalyzing {len(comments_df)} comments...")

        sentiments = []
        for idx, row in comments_df.iterrows():
            if idx % 10 == 0:
                print(f"Progress: {idx}/{len(comments_df)}")
            sentiments.append(self.analyze_comment(row['comment_text']))

        sentiment_df = pd.DataFrame(sentiments)
        result_df = pd.concat([comments_df.reset_index(drop=True), sentiment_df], axis=1)
        print("Sentiment analysis complete!")
        return result_df

    def aggregate_project_sentiment(self, comments_with_sentiment):
        """Aggregate comment-level sentiments to project-level features"""
        print("\nAggregating sentiment scores by project...")

        project_sentiment = comments_with_sentiment.groupby('project_id').agg({
            'sentiment_score': ['mean', 'std'],
            'sentiment_label': [
                lambda x: (x == 'POS').sum() / len(x),
                lambda x: (x == 'NEU').sum() / len(x),
                lambda x: (x == 'NEG').sum() / len(x)
            ],
            'is_creator_reply': 'sum'
        }).reset_index()

        project_sentiment.columns = [
            'project_id',
            'avg_sentiment_score',
            'sentiment_volatility',
            'positive_ratio',
            'neutral_ratio',
            'negative_ratio',
            'creator_replies_count'
        ]

        total_comments = comments_with_sentiment.groupby('project_id').size().reset_index(name='total_comments')
        project_sentiment = project_sentiment.merge(total_comments, on='project_id')
        project_sentiment['creator_response_rate'] = (
            project_sentiment['creator_replies_count'] / project_sentiment['total_comments']
        )

        def calculate_trend(group):
            if len(group) < 2:
                return 0.0
            mid = len(group) // 2
            return group.iloc[mid:]['sentiment_score'].mean() - group.iloc[:mid]['sentiment_score'].mean()

        trends = comments_with_sentiment.groupby('project_id').apply(calculate_trend).reset_index(name='sentiment_trend')
        project_sentiment = project_sentiment.merge(trends, on='project_id')
        project_sentiment['sentiment_volatility'] = project_sentiment['sentiment_volatility'].fillna(0.0)

        return project_sentiment[[
            'project_id', 'avg_sentiment_score', 'positive_ratio', 'neutral_ratio',
            'negative_ratio', 'creator_response_rate', 'sentiment_volatility', 'sentiment_trend'
        ]]

    def get_sentiment_time_series(self, comments_with_sentiment):
        """Get sentiment evolution over time (for dashboard charts)"""
        print("\nCalculating sentiment time series...")

        comments_with_sentiment['comment_date'] = pd.to_datetime(comments_with_sentiment['comment_date'])
        time_series = comments_with_sentiment.groupby('comment_date')['sentiment_label'].value_counts(normalize=True).unstack(fill_value=0)
        time_series = time_series * 100

        for col in ['POS', 'NEU', 'NEG']:
            if col not in time_series.columns:
                time_series[col] = 0

        time_series = time_series.rename(columns={'POS': 'positive', 'NEU': 'neutral', 'NEG': 'negative'})
        time_series = time_series.reset_index().rename(columns={'comment_date': 'date'})

        return time_series[['date', 'positive', 'neutral', 'negative']]


# ============================================================================
# Fonction d'envoi vers le DWH
# ============================================================================
def envoyer_vers_dwh(comments_with_sentiment):
    """
    Prépare et insère les résultats BERT dans Fait_commentaire (base_traitee).

    Structure de la table :
        id_fait_commentaire  INT  PK AUTO_INCREMENT
        id_date_collecte     INT  FK → Date_dim(id_date)
        id_projet            INT  FK → Projet(id_projet)
        score_sentiment      DECIMAL(5,2)
        sentiment_label      VARCHAR(3)   -- 'POS', 'NEU', 'NEG'
        is_creator_reply     TINYINT(1)
    """
    print("\nPréparation de l'envoi vers le DWH (Fait_commentaire)...")

    df_dwh = comments_with_sentiment[[
        'project_id',
        'sentiment_score',
        'sentiment_label',
        'is_creator_reply',
        'comment_date'
    ]].copy()

    # Arrondi à 2 décimales pour DECIMAL(5,2)
    df_dwh['sentiment_score'] = df_dwh['sentiment_score'].round(2)

    # is_creator_reply → 0 ou 1
    df_dwh['is_creator_reply'] = df_dwh['is_creator_reply'].astype(int)

    # Jointure avec Dim_Date sur date_complete (nom réel de la colonne)
    from dwh_connection import read_dwh_df
    dim_date = read_dwh_df("SELECT id_date, date_complete FROM Date_dim")
    dim_date['date_complete'] = pd.to_datetime(dim_date['date_complete']).dt.normalize()
    df_dwh['comment_date'] = pd.to_datetime(df_dwh['comment_date']).dt.normalize()

    df_dwh = df_dwh.merge(dim_date, left_on='comment_date', right_on='date_complete', how='left')

    # Renommage des colonnes pour correspondre à la table
    df_dwh = df_dwh.rename(columns={
        'project_id':      'id_projet',
        'sentiment_score': 'score_sentiment',
        'id_date':         'id_date_collecte'
    })[['id_date_collecte', 'id_projet', 'score_sentiment', 'sentiment_label', 'is_creator_reply']]

    # Lignes sans correspondance dans Dim_Date
    manquantes = df_dwh['id_date_collecte'].isna().sum()
    if manquantes > 0:
        print(f"⚠️  {manquantes} lignes sans correspondance dans Dim_Date (ignorées).")
        df_dwh = df_dwh.dropna(subset=['id_date_collecte'])

    df_dwh['id_date_collecte'] = df_dwh['id_date_collecte'].astype(int)

    try:
        write_dwh_df(df_dwh, "Fait_commentaire", if_exists="append")
        print(f"✅ {len(df_dwh)} lignes insérées dans Fait_commentaire.")
    except Exception as e:
        print(f"❌ Erreur lors de l'envoi vers le DWH : {e}")


# ============================================================================
# Pipeline principal
# ============================================================================
def run_sentiment_analysis(project_ids=None, save_results=True):
    """
    Pipeline complet : Extraction -> Analyse BERT -> Agrégation -> (Optionnel) Envoi DWH

    Args:
        project_ids : liste de project_id spécifiques, ou None pour tout analyser
        save_results: True  → INSERT dans Fait_commentaire + CSV  (appelé seul)
                      False → retourne uniquement les DataFrames   (appelé par RF)

    Returns:
        Tuple (comments_with_sentiment, project_aggregated_sentiment)
    """
    os.makedirs('data', exist_ok=True)

    # STEP 1 : Extraction des commentaires
    print("=" * 60)
    print("STEP 1: Extracting comments from database")
    print("=" * 60)
    comments_df = extract_bert_features(project_ids)
    print(f"Extracted {len(comments_df)} comments from {comments_df['project_id'].nunique()} projects")

    # STEP 2 : Analyse BERT
    print("\n" + "=" * 60)
    print("STEP 2: Analyzing sentiment with BERT")
    print("=" * 60)
    analyzer = BERTSentimentAnalyzer()
    comments_with_sentiment = analyzer.analyze_comments_batch(comments_df)

    # STEP 3 : Agrégation projet
    print("\n" + "=" * 60)
    print("STEP 3: Aggregating to project-level features")
    print("=" * 60)
    project_sentiment = analyzer.aggregate_project_sentiment(comments_with_sentiment)

    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    print(project_sentiment)

    # STEP 4 : Envoi DWH + CSV uniquement si appelé directement (pas par RF)
    if save_results:
        # → DWH
        envoyer_vers_dwh(comments_with_sentiment)

        # → CSV (backup local)
        comments_with_sentiment.to_csv('data/comments_with_sentiment.csv', index=False)
        project_sentiment.to_csv('data/project_sentiment_features.csv', index=False)

        time_series = analyzer.get_sentiment_time_series(comments_with_sentiment)
        time_series.to_csv('data/sentiment_time_series.csv', index=False)

        print("\nRésultats sauvegardés dans data/")
        print("   - comments_with_sentiment.csv")
        print("   - project_sentiment_features.csv")
        print("   - sentiment_time_series.csv")

    # Retourne toujours les deux DataFrames (utile pour RF)
    return comments_with_sentiment, project_sentiment


# ============================================================================
# Exécution directe
# ============================================================================
if __name__ == "__main__":
    comments_sentiment, project_sentiment = run_sentiment_analysis(save_results=True)

    print("\n" + "=" * 60)
    print("SAMPLE COMMENT SENTIMENTS")
    print("=" * 60)
    print(comments_sentiment[['project_id', 'comment_text', 'sentiment_label', 'sentiment_score']].head(10))

    print("\n" + "=" * 60)
    print("PROJECT SENTIMENT SUMMARY")
    print("=" * 60)
    print(project_sentiment)