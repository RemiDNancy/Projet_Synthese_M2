# ============================================================================
# ui_dashboard.R
# Interface de la vue détail d'un projet (affiché inline sur la home page)
# Structure : Header projet->  Tabs de navigation-> Contenu des tabs
# ============================================================================

# ── Header projet ────────────────────────────────────────────────────────────
# Affiche : breadcrumb retour, image, titre, catégorie, créateur,
#           badge "Project We Love", lien Kickstarter, dates, statut
dashboard_header_ui <- function() {
  tagList(
    
    # Lien retour vers la liste des projets
    fluidRow(
      column(12,
             tags$p(
               style = "margin-bottom: 20px;",
               tags$a(
                 icon("arrow-left"), " Back to Projects",
                 href    = "#",
                 onclick = "Shiny.setInputValue('goto_home', Math.random(), {priority: 'event'})",
                 style   = "display: inline-block; background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%); color: white; text-decoration: none; font-weight: 700; font-size: 18px; padding: 10px 22px; border-radius: 10px; box-shadow: 0 4px 12px rgba(102,126,234,0.35); transition: all 0.2s ease;"
               )
             )
      )
    ),
    
    # Carte header : image | infos projet | dates + statut
    fluidRow(
      column(12,
             div(class = "project-header",
                 fluidRow(
                   
                   # Colonne image
                   column(4, uiOutput("project_image")),

                   # Colonne infos principales
                   column(4,
                          div(style = "font-size: 34px; font-weight: bold; color: #2C3E50; margin-bottom: 12px;",
                              textOutput("project_title", inline = TRUE)),
                          div(style = "color: #4B5563; font-size: 22px; margin-bottom: 18px;",
                              textOutput("project_category_breadcrumb", inline = TRUE)),
                          div(style = "margin-bottom: 18px;",
                              tags$span("Creator: ", style = "color: #6B7280; font-size: 20px;"),
                              tags$strong(textOutput("project_creator", inline = TRUE),
                                          style = "color: #667EEA; font-size: 20px;")
                          ),
                          uiOutput("project_we_love_badge"),
                          uiOutput("project_kickstarter_link")
                   ),

                   # Colonne dates + statut
                   column(4,
                          fluidRow(
                            column(6,
                                   div(style = "background: #EEF2FF; border-radius: 12px; padding: 15px; text-align: center;",
                                       div(style = "color: #667EEA; margin-bottom: 8px;",
                                           icon("calendar", class = "fa-2x")),
                                       div(style = "font-size: 18px; color: #6B7280; margin-bottom: 5px; font-weight: 600;", "Start Date"),
                                       div(style = "font-size: 24px; font-weight: bold; color: #2C3E50;",
                                           textOutput("project_start_date", inline = TRUE))
                                   )
                            ),
                            column(6,
                                   div(style = "background: #EEF2FF; border-radius: 12px; padding: 15px; text-align: center;",
                                       div(style = "color: #9B59B6; margin-bottom: 8px;",
                                           icon("calendar", class = "fa-2x")),
                                       div(style = "font-size: 18px; color: #6B7280; margin-bottom: 5px; font-weight: 600;", "End Date"),
                                       div(style = "font-size: 24px; font-weight: bold; color: #2C3E50;",
                                           textOutput("project_end_date", inline = TRUE))
                                   )
                            )
                          ),
                          div(style = "margin-top: 15px; text-align: center;",
                              div(style = "font-size: 18px; color: #6B7280; margin-bottom: 8px; font-weight: 600;", "Status"),
                              uiOutput("project_status_badge")
                          )
                   )
                 )
             )
      )
    )
  )
}

# ── Onglet Overview ──────────────────────────────────────────────────────────
# Contient :
#   - Funding Overview : pie chart % collecté + montants + contributeurs
#   - Quick Stats      : daily avg, jours restants, velocity, backers growth
#   - Funding Progress : graphique temporel (projet vs catégorie vs goal)
overview_tab_ui <- function() {
  div(id = "content_overview", class = "dash-tab-content active",
      
      # ── Ligne 1 : Funding Overview + Quick Stats ──────────────────────
      fluidRow(
        
        # Funding Overview
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("chart-bar", style = "color: #667EEA; margin-right: 10px;"),
                       "Funding Overview"),
                   fluidRow(
                     # Pie chart : % collecté vs restant
                     column(6, plotlyOutput("overview_pie", height = "320px")),
                     # Chiffres clés : montant collecté, objectif, contributeurs
                     column(6,
                            div(class = "mini-stat",
                                div(style = "display: flex; align-items: center; margin-bottom: 6px;",
                                    icon("dollar-sign", style = "color: #667EEA; margin-right: 8px; font-size: 18px;"),
                                    tags$span("Collected",
                                              style = "font-size: 17px; color: #374151; font-weight: 600;")
                                ),
                                div(style = "font-size: 44px; font-weight: bold; color: #4C1D95; line-height: 1.1;",
                                    textOutput("project_collected", inline = TRUE))
                            ),
                            div(class = "mini-stat",
                                div(style = "display: flex; align-items: center; margin-bottom: 6px;",
                                    icon("bullseye", style = "color: #2C3E50; margin-right: 8px; font-size: 18px;"),
                                    tags$span("Goal",
                                              style = "font-size: 17px; color: #374151; font-weight: 600;")
                                ),
                                div(style = "font-size: 36px; font-weight: bold; color: #1F2937; line-height: 1.1;",
                                    textOutput("project_goal", inline = TRUE))
                            ),
                            div(class = "mini-stat",
                                div(style = "display: flex; align-items: center; margin-bottom: 6px;",
                                    icon("users", style = "color: #9B59B6; margin-right: 8px; font-size: 18px;"),
                                    tags$span("Contributors",
                                              style = "font-size: 17px; color: #374151; font-weight: 600;")
                                ),
                                div(style = "font-size: 36px; font-weight: bold; color: #1F2937; line-height: 1.1;",
                                    textOutput("project_backers", inline = TRUE))
                            )
                     )
                   )
               )
        ),
        
        # Quick Stats (4 indicateurs dynamiques depuis base_traitee)
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title", "Quick Stats"),
                   div(class = "quick-stats-grid",
                       
                       # Moyenne quotidienne collectée (converti en EUR)
                       div(class = "quick-stat green",
                           div(style = "font-size: 17px; color: #374151; margin-bottom: 8px; font-weight: 600;",
                               "Daily Average"),
                           div(style = "font-size: 38px; font-weight: bold; color: #059669; line-height: 1.1;",
                               textOutput("stat_daily_avg", inline = TRUE))
                       ),

                       # Jours restants avant la deadline (calculé depuis date_deadline)
                       div(class = "quick-stat blue",
                           div(style = "font-size: 17px; color: #374151; margin-bottom: 8px; font-weight: 600;",
                               "Days Remaining"),
                           div(style = "font-size: 38px; font-weight: bold; color: #2563EB; line-height: 1.1;",
                               textOutput("stat_days_remaining", inline = TRUE))
                       ),

                       # Funding velocity : Above / Average / Below (vs moyenne de la catégorie)
                       div(class = "quick-stat orange",
                           div(style = "font-size: 17px; color: #374151; margin-bottom: 8px; font-weight: 600;",
                               "Funding Velocity"),
                           div(style = "font-size: 38px; font-weight: bold; color: #F39C12; line-height: 1.1;",
                               textOutput("stat_funding_velocity", inline = TRUE))
                       ),

                       # Backers growth : moyenne quotidienne de nouveaux contributeurs
                       div(class = "quick-stat purple",
                           div(style = "font-size: 17px; color: #374151; margin-bottom: 8px; font-weight: 600;",
                               "Backers Growth"),
                           div(style = "font-size: 38px; font-weight: bold; color: #9B59B6; line-height: 1.1;",
                               textOutput("stat_backers_growth", inline = TRUE))
                       )
                   )
               )
        )
      ),
      
      # ── Ligne 2 : Funding Progress (graphique temporel) ──────────────
      # 3 courbes : progression du projet | moyenne catégorie | goal 100%
      # Comparaison : sous-catégorie si >= 3 projets, sinon catégorie parente
      fluidRow(
        column(12,
               div(class = "chart-container",
                   div(style = "display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px;",
                       div(
                         icon("chart-line",
                              style = "color: #667EEA; font-size: 24px; margin-right: 10px; vertical-align: middle;"),
                         tags$span("Funding Progress",
                                   style = "font-size: 28px; font-weight: bold; color: #2C3E50; display: inline; vertical-align: middle;")
                       ),
                       # Boutons zoom (JS)
                       div(class = "zoom-btn-row", style = "margin-bottom: 0;",
                           tags$button(class = "zoom-btn", title = "Zoom In",
                                       onclick = "plotZoomIn('main_chart')",
                                       icon("search-plus")),
                           tags$button(class = "zoom-btn", title = "Zoom Out",
                                       onclick = "plotZoomOut('main_chart')",
                                       icon("search-minus"))
                       )
                   ),
                   plotlyOutput("main_chart", height = "450px")
               )
        )
      )
  )
}

# ── Assemblage principal du dashboard ────────────────────────────────────────
# Combine : header + tabs de navigation + contenu de chaque tab
dashboard_content_ui <- function() {
  tagList(
    
    # Header projet (breadcrumb, image, titre, dates, statut)
    dashboard_header_ui(),
    
    # Barre de navigation entre les tabs
    fluidRow(
      column(12,
             div(class = "tab-navigation",
                 actionButton("tab_overview",
                              tagList(icon("chart-bar"), " Overview"),
                              class   = "nav-tab active",
                              onclick = "Shiny.setInputValue('active_tab', 'overview', {priority: 'event'})"),
                 actionButton("tab_sentiment",
                              tagList(icon("comments"), " Sentiment"),
                              class   = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'sentiment', {priority: 'event'})"),
                 actionButton("tab_rewards",
                              tagList(icon("award"), " Rewards"),
                              class   = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'rewards', {priority: 'event'})"),
                 actionButton("tab_creator",
                              tagList(icon("user"), " Creator"),
                              class   = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'creator', {priority: 'event'})"),
                 actionButton("tab_ai",
                              tagList(icon("bolt"), " AI Insights"),
                              class   = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'ai', {priority: 'event'})")
             )
      )
    ),
    
    # Contenu des tabs (un seul visible à la fois via CSS active/inactive)
    fluidRow(
      column(12,
             overview_tab_ui(),   # onglet Overview (actif par défaut)
             sentiment_tab_ui(),  # onglet Sentiment (BERT scores)
             rewards_tab_ui(),    # onglet Rewards
             creator_tab_ui(),    # onglet Creator
             ai_tab_ui()          # onglet AI Insights
      )
    )
  )
}