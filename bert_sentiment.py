"""
BERT Sentiment Analysis for Kickstarter Comments
Analyzes comment sentiment and aggregates scores per project
"""

import os
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'  # Disable TensorFlow warnings

import pandas as pd
import numpy as np
from transformers import pipeline
from features_bert import extract_bert_features
import warnings
warnings.filterwarnings('ignore')


class BERTSentimentAnalyzer:
    """BERT-based sentiment analyzer for project comments"""
    
    def __init__(self, model_name="distilbert-base-uncased-finetuned-sst-2-english"):
        """
        Initialize BERT sentiment analyzer
        
        Args:
            model_name: Pretrained model for sentiment analysis
                - "distilbert-base-uncased-finetuned-sst-2-english" (fast, good)
                - "cardiffnlp/twitter-roberta-base-sentiment" (better for short text)
        """
        print(f"Loading BERT model: {model_name}...")
        
        # Force PyTorch framework (avoid TensorFlow/Keras issues)
        import torch
        
        self.sentiment_pipeline = pipeline(
            "sentiment-analysis",
            model=model_name,
            framework="pt",  # Force PyTorch
            device=-1  # -1 for CPU, 0 for GPU
        )
        print("Model loaded successfully!")
    
    def analyze_comment(self, text):
        """
        Analyze sentiment of a single comment
        
        Returns:
            dict with sentiment_label, sentiment_score, sentiment_confidence
        """
        if not text or pd.isna(text) or len(text.strip()) == 0:
            return {
                'sentiment_label': 'NEUTRAL',
                'sentiment_score': 0.0,
                'sentiment_confidence': 0.0
            }
        
        # Truncate long comments (BERT has 512 token limit)
        text = text[:512]
        
        try:
            result = self.sentiment_pipeline(text)[0]
            
            # Convert to standardized format
            label = result['label'].upper()
            confidence = result['score']
            
            # Map to sentiment score (-1 to +1)
            if 'POS' in label or label == 'POSITIVE':
                sentiment_score = confidence  # 0 to 1
                sentiment_label = 'POS'
            elif 'NEG' in label or label == 'NEGATIVE':
                sentiment_score = -confidence  # -1 to 0
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
        """
        Analyze all comments in a DataFrame
        
        Args:
            comments_df: DataFrame with 'comment_text' column
        
        Returns:
            DataFrame with added sentiment columns
        """
        print(f"\nAnalyzing {len(comments_df)} comments...")
        
        # Analyze each comment
        sentiments = []
        for idx, row in comments_df.iterrows():
            if idx % 10 == 0:
                print(f"Progress: {idx}/{len(comments_df)}")
            
            sentiment = self.analyze_comment(row['comment_text'])
            sentiments.append(sentiment)
        
        # Add sentiment columns
        sentiment_df = pd.DataFrame(sentiments)
        result_df = pd.concat([comments_df.reset_index(drop=True), sentiment_df], axis=1)
        
        print("Sentiment analysis complete!")
        return result_df
    
    def aggregate_project_sentiment(self, comments_with_sentiment):
        """
        Aggregate comment-level sentiments to project-level features
        
        Returns:
            DataFrame with project_id and aggregated sentiment features
        """
        print("\nAggregating sentiment scores by project...")
        
        project_sentiment = comments_with_sentiment.groupby('project_id').agg({
            'sentiment_score': ['mean', 'std'],
            'sentiment_label': [
                lambda x: (x == 'POS').sum() / len(x),  # positive ratio
                lambda x: (x == 'NEU').sum() / len(x),  # neutral ratio
                lambda x: (x == 'NEG').sum() / len(x)   # negative ratio
            ],
            'is_creator_reply': 'sum'
        }).reset_index()
        
        # Flatten column names
        project_sentiment.columns = [
            'project_id',
            'avg_sentiment_score',
            'sentiment_volatility',
            'positive_ratio',
            'neutral_ratio',
            'negative_ratio',
            'creator_replies_count'
        ]
        
        # Calculate creator response rate
        total_comments = comments_with_sentiment.groupby('project_id').size().reset_index(name='total_comments')
        project_sentiment = project_sentiment.merge(total_comments, on='project_id')
        project_sentiment['creator_response_rate'] = project_sentiment['creator_replies_count'] / project_sentiment['total_comments']
        
        # Calculate sentiment trend (first half vs second half)
        def calculate_trend(group):
            if len(group) < 2:
                return 0.0
            mid = len(group) // 2
            first_half = group.iloc[:mid]['sentiment_score'].mean()
            second_half = group.iloc[mid:]['sentiment_score'].mean()
            return second_half - first_half
        
        trends = comments_with_sentiment.groupby('project_id').apply(calculate_trend).reset_index(name='sentiment_trend')
        project_sentiment = project_sentiment.merge(trends, on='project_id')
        
        # Fill NaN volatility (projects with only 1 comment)
        project_sentiment['sentiment_volatility'] = project_sentiment['sentiment_volatility'].fillna(0.0)
        
        # Keep only relevant columns
        final_cols = [
            'project_id',
            'avg_sentiment_score',
            'positive_ratio',
            'neutral_ratio',
            'negative_ratio',
            'creator_response_rate',
            'sentiment_volatility',
            'sentiment_trend'
        ]
        
        return project_sentiment[final_cols]
    
    def get_sentiment_time_series(self, comments_with_sentiment):
        """
        Get sentiment evolution over time (for dashboard charts)
        Groups comments by date and calculates sentiment percentages
        
        Returns:
            DataFrame with date, positive_pct, neutral_pct, negative_pct
        """
        print("\nCalculating sentiment time series...")
        
        # Convert comment_date to datetime
        comments_with_sentiment['comment_date'] = pd.to_datetime(comments_with_sentiment['comment_date'])
        
        # Group by date
        time_series = comments_with_sentiment.groupby('comment_date')['sentiment_label'].value_counts(normalize=True).unstack(fill_value=0)
        
        # Convert to percentages
        time_series = time_series * 100
        
        # Ensure all columns exist
        for col in ['POS', 'NEU', 'NEG']:
            if col not in time_series.columns:
                time_series[col] = 0
        
        # Rename columns
        time_series = time_series.rename(columns={
            'POS': 'positive',
            'NEU': 'neutral',
            'NEG': 'negative'
        })
        
        # Reset index to make date a column
        time_series = time_series.reset_index()
        time_series = time_series.rename(columns={'comment_date': 'date'})
        
        return time_series[['date', 'positive', 'neutral', 'negative']]


def run_sentiment_analysis(project_ids=None, save_results=True):
    """
    Complete pipeline: Extract comments -> Analyze -> Aggregate
    
    Args:
        project_ids: List of specific projects, or None for all
        save_results: Save results to CSV
    
    Returns:
        Tuple of (comments_with_sentiment, project_aggregated_sentiment)
    """
    # Create data directory if it doesn't exist
    os.makedirs('data', exist_ok=True)
    
    # Step 1: Extract comments
    print("=" * 60)
    print("STEP 1: Extracting comments from database")
    print("=" * 60)
    comments_df = extract_bert_features(project_ids)
    print(f"Extracted {len(comments_df)} comments from {comments_df['project_id'].nunique()} projects")
    
    # Step 2: Analyze sentiment
    print("\n" + "=" * 60)
    print("STEP 2: Analyzing sentiment with BERT")
    print("=" * 60)
    analyzer = BERTSentimentAnalyzer()
    comments_with_sentiment = analyzer.analyze_comments_batch(comments_df)
    
    # Step 3: Aggregate to project level
    print("\n" + "=" * 60)
    print("STEP 3: Aggregating to project-level features")
    print("=" * 60)
    project_sentiment = analyzer.aggregate_project_sentiment(comments_with_sentiment)
    
    print("\n" + "=" * 60)
    print("RESULTS")
    print("=" * 60)
    print(f"\nProject-level sentiment features:")
    print(project_sentiment)
    
    # Save results
    if save_results:
        comments_with_sentiment.to_csv('data/comments_with_sentiment.csv', index=False)
        project_sentiment.to_csv('data/project_sentiment_features.csv', index=False)
        
        # Also save time series for dashboard
        time_series = analyzer.get_sentiment_time_series(comments_with_sentiment)
        time_series.to_csv('data/sentiment_time_series.csv', index=False)
        
        print("\nResults saved to data/ folder")
        print("   - comments_with_sentiment.csv (comment-level)")
        print("   - project_sentiment_features.csv (project-level for ML)")
        print("   - sentiment_time_series.csv (for dashboard charts)")
    
    return comments_with_sentiment, project_sentiment


# Main execution
if __name__ == "__main__":
    # Run complete analysis
    comments_sentiment, project_sentiment = run_sentiment_analysis()
    
    # Display sample results
    print("\n" + "=" * 60)
    print("SAMPLE COMMENT SENTIMENTS")
    print("=" * 60)
    print(comments_sentiment[['project_id', 'comment_text', 'sentiment_label', 'sentiment_score']].head(10))
    
    print("\n" + "=" * 60)
    print("PROJECT SENTIMENT SUMMARY")
    print("=" * 60)
    print(project_sentiment)