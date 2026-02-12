# Project AI

## Les modéles choisis
- KNN
- RandomForest
- BERT 

## Les features choisis 
KNN features : 
-> Features du Projet (7 features)
goal_amount : Montant objectif => indicateur majeur. "Projets avec goals trop élevés échouent souvent"
duration_days : Durée de campagne. "Études montrent que 30 jours => optimal", maybe il y a un impact: Durées > 45 jours ont taux d'échec plus élevé
category_encoded : Certaines catégories (Games, Tech) ont meilleurs taux de succès et impact: Benchmark historique par catégorie
subcategory_encoded : Granularité fine (ex: Tabletop Games vs Video Games). Impact: Niches spécifiques ont communautés plus engagées
is_project_we_love :  Badge Kickstarter = validation qualité. +15-20% taux succès impact -> Fort signal de crédibilité
num_rewards : Diversité des tiers = plus d'options pour backers . Impact: Sweet spot = 4-6 rewards
avg_reward_price : Accessibilité financière. Prix moyen trop élevé = barrière. Impact: Corrélation avec demographics des backers.

-> Features du Créateur (3 features)
launched_projects_count : Expérience du créateur. Vétérans ont meilleur track record Impact: Créateurs avec 2+ projets = +25% succès
backings_count : Engagement dans la communauté KS Impact: Créateurs actifs comprennent mieux la plateforme
is_fb_connected : Présence réseaux sociaux = capacité marketing. Impact: +10% succès (portée audience)

-> Features de Performance Temporelle (5 features)
pledged_amount (numérique - last snapshot) Montant levé à date = momentum Impact: Indicateur direct de traction
backers_count (numérique - last snapshot) = Nombre de supporters = validation sociale Impact: Effet boule de neige (social proof)
funding_velocity (numérique - dérivée) = Vitesse de levée ($/jour). Projets qui démarrent fort finissent fort. Impact: Premiers 48h = prédicteur #1
days_since_launch (numérique) = Contextualise les autres métriques (début vs fin campagne). Impact: Patterns différents selon phase
avg_sentiment_score (numérique - de l'AI sentiment) =  Feedback communauté = health check Impact: Sentiment négatif = red flag early warning

-> Other features that are for RF : 
percent_funded (numérique - dérivée) =  % d'atteinte objectif = métrique normalisée (indépendante du goal). Impact: RF peut créer splits complexes (ex: if > 30% AND days < 10 → success)
updates_count (numérique) =  Communication créateur. Updates réguliers = engagement. Impact: RF détectera patterns non-linéaires (0 updates = bad, 1-3 = good, 10+ = desperate?)
creator_response_rate (numérique - de l'AI sentiment) = Réactivité aux commentaires = customer care.  RF peut combiner avec sentiment (high response + negative sentiment = damage control)


Sentiment Analyzer (Transformers - BERT) : 

INPUT
comment_text (only input nécessaire) mais il faut Preprocessing: Nettoyage (URLs, mentions, caractères spéciaux) . Limite 512 caractères (contrainte BERT)

OUTPUT (ce qu'on stocke dans la BDD) 
sentiment_score (numérique: -1 à +1) : Métrique continue = nuancée (pas juste positif/négatif) + Utilisation: Input pour KNN & RF (feature #15)
sentiment_label (catégoriel: POSITIF/NEUTRE/NEGATIF) Seuils: score > 0.3 = POSITIF, < -0.3 = NEGATIF, entre = NEUTRE
sentiment_confidence (numérique: 0-100%) =  Indique la certitude du modèle Utilisation: Filtrer prédictions peu fiables (confidence < 60%)
positive_ratio (numérique - %) = Calcul: COUNT(POSITIF) / COUNT(*) * 100 -> Métrique synthétique de "santé" du projet
creator_response_rate (numérique - %) = Calcul: COUNT(is_creator_reply=TRUE) / COUNT(*) * 100 -> Mesure engagement créateur
sentiment_trend (catégoriel: IMPROVING/STABLE/DECLINING) = Calcul: Comparer moyenne première moitié vs deuxième moitié campagne -> Détecte momentum (positif qui empire = warning)
sentiment_volatility (numérique - écart-type) = Calcul: STDDEV(sentiment_score) -> Volatilité élevée = controverse ou problèmes


##