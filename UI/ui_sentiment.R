# ============================================================================
# ui_sentiment.R
# Interface de l'onglet Sentiment
# Données : base_traitee.Fait_commentaire (scores BERT distilbert)
# ============================================================================
sentiment_tab_ui <- function() {
  div(id = "content_sentiment", class = "dash-tab-content",
      
      # ── Ligne 1 : Donut + Sentiment Evolution ───────────────────────────
      fluidRow(
        
        # Overall Sentiment : donut + badges %
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("comments", style = "color: #059669; margin-right: 10px;"),
                       "Overall Sentiment"),

                   uiOutput("sentiment_comment_count"),

                   # Donut chart avec texte centré dynamique
                   div(style = "position: relative; height: 280px; margin-bottom: 20px;",
                       plotlyOutput("sentiment_donut_main", height = "280px"),
                       # Texte centré : % positif calculé depuis la BDD
                       div(style = paste(
                         "position: absolute; top: 50%; left: 50%;",
                         "transform: translate(-50%, -50%);",
                         "text-align: center; pointer-events: none; z-index: 10;"
                       ),
                       uiOutput("sentiment_donut_center")
                       )
                   ),
                   
                   # Grille des 3 pourcentages (dynamiques)
                   div(class = "sentiment-feedback-grid",
                       
                       # Positif
                       div(class = "sentiment-feedback-item",
                           div(style = "width: 16px; height: 16px; border-radius: 50%; background: #86EFAC; margin: 0 auto 8px;"),
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Positive"),
                           div(style = "font-size: 20px; font-weight: bold; color: #059669;",
                               textOutput("sentiment_pct_positive", inline = TRUE))
                       ),
                       
                       # Neutre
                       div(class = "sentiment-feedback-item",
                           div(style = "width: 16px; height: 16px; border-radius: 50%; background: #93C5FD; margin: 0 auto 8px;"),
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Neutral"),
                           div(style = "font-size: 20px; font-weight: bold; color: #2563EB;",
                               textOutput("sentiment_pct_neutral", inline = TRUE))
                       ),
                       
                       # Négatif
                       div(class = "sentiment-feedback-item",
                           div(style = "width: 16px; height: 16px; border-radius: 50%; background: #FCA5A5; margin: 0 auto 8px;"),
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Negative"),
                           div(style = "font-size: 20px; font-weight: bold; color: #DC2626;",
                               textOutput("sentiment_pct_negative", inline = TRUE))
                       )
                   )
               )
        ),
        
        # Sentiment Evolution : graphique temporel hebdomadaire
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("chart-area", style = "color: #667EEA; margin-right: 10px;"),
                       "Sentiment Evolution"),
                   div(style = "position: relative;",
                       plotlyOutput("sentiment_evolution_chart", height = "320px")
                   )
               )
        )
      )
  )
}