# ============================================================================
# Sentiment tab UI - Version corrigée avec donut chart et évolution
# ============================================================================
sentiment_tab_ui <- function() {
  div(id = "content_sentiment", class = "dash-tab-content",
      fluidRow(
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("comments", style = "color: #059669; margin-right: 10px;"),
                       "Overall Sentiment"),
                   # Donut chart avec texte centré
                   div(style = "position: relative; height: 280px; margin-bottom: 20px;",
                       plotlyOutput("sentiment_donut_main", height = "280px"),
                       div(style = "position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); text-align: center; pointer-events: none; z-index: 10;",
                           div(style = "font-size: 48px; font-weight: bold; color: #059669;", "63%"),
                           div(style = "font-size: 14px; color: #95A5A6;", "Positive")
                       )
                   ),
                   # Grille des 3 pourcentages
                   div(class = "sentiment-feedback-grid",
                       div(class = "sentiment-feedback-item",
                           div(style = "width: 16px; height: 16px; border-radius: 50%; background: #86EFAC; margin: 0 auto 8px;"),
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Positive"),
                           div(style = "font-size: 20px; font-weight: bold; color: #059669;", "63%")
                       ),
                       div(class = "sentiment-feedback-item",
                           div(style = "width: 16px; height: 16px; border-radius: 50%; background: #93C5FD; margin: 0 auto 8px;"),
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Neutral"),
                           div(style = "font-size: 20px; font-weight: bold; color: #2563EB;", "22%")
                       ),
                       div(class = "sentiment-feedback-item",
                           div(style = "width: 16px; height: 16px; border-radius: 50%; background: #FCA5A5; margin: 0 auto 8px;"),
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Negative"),
                           div(style = "font-size: 20px; font-weight: bold; color: #DC2626;", "15%")
                       )
                   )
               )
        ),
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("chart-line", style = "color: #667EEA; margin-right: 10px;"),
                       "Communication Frequency"),
                   div(class = "communication-bars",
                       div(class = "comm-bar-item",
                           div(style = "display: flex; justify-content: space-between; margin-bottom: 5px;",
                               tags$span(style = "font-size: 12px; color: #95A5A6;", "Week 1"),
                               tags$span(style = "font-size: 12px; color: #2C3E50; font-weight: 600;", "2 updates")
                           ),
                           div(class = "comm-bar-bg",
                               div(class = "comm-bar-fill", style = "width: 40%; background: #667EEA;")
                           )
                       ),
                       div(class = "comm-bar-item",
                           div(style = "display: flex; justify-content: space-between; margin-bottom: 5px;",
                               tags$span(style = "font-size: 12px; color: #95A5A6;", "Week 2"),
                               tags$span(style = "font-size: 12px; color: #2C3E50; font-weight: 600;", "5 updates")
                           ),
                           div(class = "comm-bar-bg",
                               div(class = "comm-bar-fill", style = "width: 100%; background: #667EEA;")
                           )
                       ),
                       div(class = "comm-bar-item",
                           div(style = "display: flex; justify-content: space-between; margin-bottom: 5px;",
                               tags$span(style = "font-size: 12px; color: #95A5A6;", "Week 3"),
                               tags$span(style = "font-size: 12px; color: #2C3E50; font-weight: 600;", "3 updates")
                           ),
                           div(class = "comm-bar-bg",
                               div(class = "comm-bar-fill", style = "width: 60%; background: #667EEA;")
                           )
                       ),
                       div(class = "comm-bar-item",
                           div(style = "display: flex; justify-content: space-between; margin-bottom: 5px;",
                               tags$span(style = "font-size: 12px; color: #95A5A6;", "Week 4"),
                               tags$span(style = "font-size: 12px; color: #2C3E50; font-weight: 600;", "4 updates")
                           ),
                           div(class = "comm-bar-bg",
                               div(class = "comm-bar-fill", style = "width: 80%; background: #667EEA;")
                           )
                       ),
                       div(class = "comm-bar-item",
                           div(style = "display: flex; justify-content: space-between; margin-bottom: 5px;",
                               tags$span(style = "font-size: 12px; color: #95A5A6;", "Week 5"),
                               tags$span(style = "font-size: 12px; color: #2C3E50; font-weight: 600;", "1 update")
                           ),
                           div(class = "comm-bar-bg",
                               div(class = "comm-bar-fill", style = "width: 20%; background: #05CE78;")
                           )
                       )
                   ),
                   # Moyenne en bas
                   div(style = "margin-top: 20px; padding: 15px; background: linear-gradient(135deg, #D1FAE5 0%, #A7F3D0 100%); border-radius: 12px; text-align: center;",
                       div(style = "font-size: 11px; color: #047857; margin-bottom: 3px;", "Average"),
                       div(style = "font-size: 24px; font-weight: bold; color: #059669;", "3 updates/week")
                   )
               )
        )
      ),
      fluidRow(
        column(12,
               div(class = "chart-container",
                   div(style = "margin-bottom: 20px;",
                       icon("chart-area", style = "color: #667EEA; font-size: 24px; margin-right: 10px; vertical-align: middle;"),
                       tags$span("Sentiment Evolution",
                                 style = "font-size: 28px; font-weight: bold; color: #2C3E50; display: inline; vertical-align: middle;")
                   ),
                   plotlyOutput("sentiment_evolution_chart", height = "400px")
               )
        )
      )
  )
}