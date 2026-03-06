
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from .features_knn_rf import extract_knn_rf_features
from bert_sentiment import run_sentiment_analysis
from .encoders import encode_features_for_training


class RandomForestKickstarter:
    def __init__(self):

        self.model = RandomForestClassifier(
            n_estimators=300,  # nombre d'arbres dans la forêt
            max_depth=12,  # profondeur maximale de chaque arbre
            random_state=42,  # pour reproduire les résultats
            class_weight="balanced"  # ajuste automatiquement le poids des classes pour les déséquilibres
        )

    def prepare_dataset(self, scrap_date=None):

        # Extraction des features structurées
        df = extract_knn_rf_features(scrap_date)

        # Extraction des features de sentiment avec BERT
        comments_df = run_sentiment_analysis(save_results=False)

        # Suppression des anciennes colonnes de sentiment si elles existent
        df = df.drop(columns=[
            'avg_sentiment_score',
            'positive_ratio',
            'creator_response_rate',
            'sentiment_volatility',
            'sentiment_trend'
        ], errors='ignore')

        # Extraction des features de sentiment avec BERT
        try:
            _, sentiment_features = run_sentiment_analysis(save_results=False)
        except Exception as e:
            print("BERT non disponible ou test rapide : création de features factices")
            sentiment_features = pd.DataFrame({
                "project_id": df["project_id"].unique(),
                "avg_sentiment_score": 0.0,
                "positive_ratio": 0.5,
                "creator_response_rate": 0.0,
                "sentiment_volatility": 0.0,
                "sentiment_trend": 0.0
            })

        # Fusion des nouvelles features de sentiment avec le dataframe principal
        df = df.merge(sentiment_features, on="project_id", how="left")

        #  Remplacement des valeurs manquantes par 0
        df.fillna(0, inplace=True)

        # Définition de la cible : succès si financement >= 100%
        df["is_successful"] = (df["percent_funded"] >= 100).astype(int)

        # Encodage des variables catégorielles
        df = encode_features_for_training(df)
        for col in ['current_state', 'is_project_we_love']:
            if col in df.columns:
                df[col] = df[col].astype('category').cat.codes

        return df

    def train(self, scrap_date=None):

        # Préparation des données
        df = self.prepare_dataset(scrap_date)

        if df.empty:
            print(f"Aucune donnée trouvée pour scrap_date={scrap_date} !")
            return None

        # Séparation des features et de la cible
        X = df.drop(columns=["project_id", "scrap_date", "is_successful"])
        y = df["is_successful"]

        # Séparation en train/test (80% / 20%)
        X_train, X_test, y_train, y_test = train_test_split(
            X, y,
            test_size=0.2,
            random_state=42
        )

        print("Entraînement du Random Forest...")
        self.model.fit(X_train, y_train)

        # Prédiction sur le jeu de test
        y_pred = self.model.predict(X_test)

        # Évaluation des performances
        print("\n Accuracy :", accuracy_score(y_test, y_pred))
        print("\n Rapport de classification :\n", classification_report(y_test, y_pred))

        # Affichage des importances des features
        importances = pd.DataFrame({
            "feature": X.columns,
            "importance": self.model.feature_importances_
        }).sort_values(by="importance", ascending=False)

        print("\n Top 15 des features les plus importantes :")
        print(importances.head(15))

        return self.model


if __name__ == "__main__":
    # Création de l'objet RandomForestKickstarter
    rf = RandomForestKickstarter()

    # Entraînement avec les données d'une date spécifique
    rf.train(scrap_date="2026-02-22")