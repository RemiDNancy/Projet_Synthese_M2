"""
Encoders for categorical features in KNN/RF models
One-Hot Encoding for category and subcategory
"""
import pandas as pd
import pickle
import os

def encode_categories(df, fit=True, encoder_path='encoders/'):
    """
    One-Hot encode category and subcategory columns
    
    Args:
        df: DataFrame containing 'category_encoded' and 'subcategory_encoded'.
        fit: True → create new encoders.
            False → load existing encoders.
        encoder_path: Folder to save or load encoder data.
    
    Returns:
        DataFrame with one-hot encoded categories
    """
    
    # Create encoder directory if it doesn't exist
    os.makedirs(encoder_path, exist_ok=True)
    
    if fit:
        # TRAINING MODE: Learn categories and save them
        print("Creating new encoders...")
        
        # Store unique categories for later
        cat_columns = df['category_encoded'].unique().tolist()
        subcat_columns = df['subcategory_encoded'].unique().tolist()
        
        # Save category lists
        with open(f'{encoder_path}category_list.pkl', 'wb') as f:
            pickle.dump(cat_columns, f)
        with open(f'{encoder_path}subcategory_list.pkl', 'wb') as f:
            pickle.dump(subcat_columns, f)
        
        print(f"Found {len(cat_columns)} categories: {cat_columns}")
        print(f"Found {len(subcat_columns)} subcategories: {subcat_columns}")
        
    else:
        # PREDICTION MODE: Load existing categories
        print("Loading existing encoders...")
        
        with open(f'{encoder_path}category_list.pkl', 'rb') as f:
            cat_columns = pickle.load(f)
        with open(f'{encoder_path}subcategory_list.pkl', 'rb') as f:
            subcat_columns = pickle.load(f)
    
    # One-hot encode categories
    category_dummies = pd.get_dummies(
        df['category_encoded'], 
        prefix='cat',
        dtype=int
    )
    
    subcategory_dummies = pd.get_dummies(
        df['subcategory_encoded'], 
        prefix='subcat',
        dtype=int
    )
    
    # Handle unseen categories in prediction mode
    if not fit:
        # Add missing columns with zeros
        for cat in cat_columns:
            col_name = f'cat_{cat}'
            if col_name not in category_dummies.columns:
                category_dummies[col_name] = 0
        
        for subcat in subcat_columns:
            col_name = f'subcat_{subcat}'
            if col_name not in subcategory_dummies.columns:
                subcategory_dummies[col_name] = 0
        
        # Remove extra columns not seen during training
        category_dummies = category_dummies[[f'cat_{c}' for c in cat_columns]]
        subcategory_dummies = subcategory_dummies[[f'subcat_{c}' for c in subcat_columns]]
    
    # Drop original columns
    df = df.drop(columns=['category_encoded', 'subcategory_encoded'])
    
    # Concatenate one-hot encoded columns
    df = pd.concat([df, category_dummies, subcategory_dummies], axis=1)
    
    print(f"Added {len(category_dummies.columns)} category columns")
    print(f"Added {len(subcategory_dummies.columns)} subcategory columns")
    
    return df


def encode_features_for_training(df):
    """
    Encode features during training phase
    Creates and saves encoders
    """
    return encode_categories(df, fit=True)


def encode_features_for_prediction(df):
    """
    Encode features during prediction phase
    Uses saved encoders
    """
    return encode_categories(df, fit=False)