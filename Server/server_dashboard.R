# ============================================================================
# server_dashboard.R
# Logique serveur de la vue détail d'un projet
# Données : base_traitee (principal) + kickstarter (rewards via config.R)
# ============================================================================
dashboard_server <- function(input, output, session, selected_project_id) {
  
  # ── Projet sélectionné ───────────────────────────────────────────────────
  # Récupère la ligne du projet depuis sample_projects (chargé dans config.R)
  # selected_project_id est un reactiveVal partagé avec home_server
  current_project <- reactive({
    project <- sample_projects[sample_projects$project_id == selected_project_id(), ]
    if (nrow(project) > 0) project[1, ] else NULL
  })
  
  # ── Quick stats : une seule requête pour tous les indicateurs ────────────
  # Reactive partagé pour éviter 4 requêtes BDD séparées (une par output)
  # Calcule : daily_avg_amount, daily_avg_backers, jours_restants, categorie
  current_quick_stats <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)
    
    con <- get_db_connection()
    tryCatch({
      query <- sprintf("
        SELECT
          -- Moyenne quotidienne du montant collecté (jours inactifs exclus)
          AVG(NULLIF(fps.delta_montant_1j, 0))        AS daily_avg_amount,

          -- Moyenne quotidienne de nouveaux contributeurs (jours inactifs exclus)
          AVG(NULLIF(fps.delta_contributeurs_1j, 0))  AS daily_avg_backers,

          -- Jours restants calculés dynamiquement (jours_restants = NULL dans Talend)
          GREATEST(DATEDIFF(p.date_deadline, CURDATE()), 0) AS jours_restants,

          -- Sous-catégorie du projet (pour comparaison funding velocity et graphique)
          MIN(fps.categorie) AS categorie

        FROM Fait_projet_snapshot fps
        JOIN Projet p ON fps.id_projet = p.id_projet
        WHERE fps.id_projet = %d
        GROUP BY fps.id_projet, p.date_deadline
      ", p$project_id)
      
      result <- safe_dbGetQuery(con, query)
      return(result)
    }, error = function(e) {
      message("Error fetching quick stats: ", e$message)
      return(NULL)
    }, finally = {
      close_db_connection(con)
    })
  })
  
  # ── Moyenne catégorie pour Funding Velocity ──────────────────────────────
  # Calcule le delta_montant_1j moyen de tous les projets de la même catégorie
  # Utilisé pour classifier le projet : Above / Average / Below Average
  category_avg_velocity <- reactive({
    stats <- current_quick_stats()
    if (is.null(stats) || is.na(stats$categorie)) return(NULL)
    
    con <- get_db_connection()
    tryCatch({
      query <- sprintf("
        SELECT AVG(NULLIF(delta_montant_1j, 0)) AS cat_avg_velocity
        FROM Fait_projet_snapshot
        WHERE categorie = '%s'
      ", stats$categorie)
      result <- safe_dbGetQuery(con, query)
      return(result$cat_avg_velocity)
    }, error = function(e) { return(NULL) },
    finally = { close_db_connection(con) })
  })
  
  # ── Navigation entre tabs ────────────────────────────────────────────────
  active_tab <- reactiveVal("overview")
  
  # Retour vers la liste des projets
  observeEvent(input$goto_home, {
    shinyjs::hide(id = "project_detail_view")
    shinyjs::show(id = "projects_list_view")
  })
  
  # Changement de tab : met à jour les classes CSS active/inactive
  observeEvent(input$active_tab, {
    active_tab(input$active_tab)
    
    shinyjs::runjs("
      $('.nav-tab').removeClass('active');
      $('.dash-tab-content').removeClass('active');
    ")
    
    tab_ids <- c(
      "overview"  = "#tab_overview",
      "sentiment" = "#tab_sentiment",
      "rewards"   = "#tab_rewards",
      "creator"   = "#tab_creator",
      "ai"        = "#tab_ai"
    )
    content_ids <- c(
      "overview"  = "#content_overview",
      "sentiment" = "#content_sentiment",
      "rewards"   = "#content_rewards",
      "creator"   = "#content_creator",
      "ai"        = "#content_ai"
    )
    
    shinyjs::runjs(sprintf("$('%s').addClass('active');", tab_ids[input$active_tab]))
    shinyjs::runjs(sprintf("$('%s').addClass('active');", content_ids[input$active_tab]))
    # Force le recalcul des dimensions des graphiques Plotly dans les tabs cachés
    shinyjs::runjs("setTimeout(function(){ window.dispatchEvent(new Event('resize')); }, 200);")
  })
  
  # ── Header projet ────────────────────────────────────────────────────────
  
  # Breadcrumb : nom du projet sélectionné
  output$current_project_name <- renderText({
    p <- current_project()
    if (!is.null(p)) p$title else ""
  })
  
  # Titre principal du projet
  output$project_title <- renderText({
    p <- current_project()
    if (!is.null(p)) p$title else ""
  })
  
  # Image du projet (depuis url_image dans base_traitee)
  output$project_image <- renderUI({
    p <- current_project()
    if (!is.null(p)) {
      tags$img(
        src   = p$image_url,
        style = "width: 450px; height: auto; max-height: 500px; border-radius: 12px; object-fit: contain; background: transparent; box-shadow: 0 4px 12px rgba(0,0,0,0.2);"
      )
    }
  })
  
  # Fil d'Ariane catégorie : sous-catégorie → catégorie parente
  output$project_category_breadcrumb <- renderText({
    p <- current_project()
    if (!is.null(p)) paste0(p$category_sub, " → ", p$category) else ""
  })
  
  # Nom du créateur du projet
  output$project_creator <- renderText({
    p <- current_project()
    if (!is.null(p)) p$creator_name else ""
  })
  
  # Badge "Project We Love" : affiché uniquement si is_project_we_love = TRUE
  output$project_we_love_badge <- renderUI({
    p <- current_project()
    if (!is.null(p) && isTRUE(p$is_project_we_love)) {
      div(style = "padding: 6px 12px; background: #E8F5E9; color: #05CE78; border-radius: 20px; font-size: 13px; font-weight: 600; display: inline-block; margin-bottom: 10px;",
          "⭐ Project We Love")
    }
  })
  
  # Lien vers la page Kickstarter du projet (ouvre dans un nouvel onglet)
  output$project_kickstarter_link <- renderUI({
    p <- current_project()
    if (!is.null(p)) {
      tagList(
        tags$br(),
        tags$a(href = p$url, target = "_blank",
               style = "color: #05CE78; font-weight: 600; text-decoration: none; font-size: 18px; display: inline-flex; align-items: center; gap: 8px;",
               tags$i(class = "fab fa-kickstarter-k", style = "font-size: 26px; color: #05CE78;"),
               "View on Kickstarter")
      )
    }
  })
  
  # Date de lancement (epoch → Date lisible)
  output$project_start_date <- renderText({
    p <- current_project()
    if (!is.null(p)) format(as.Date(as.POSIXct(p$launched_at, origin = "1970-01-01")), "%b %d, %Y") else ""
  })
  
  # Date de fin de campagne (epoch → Date lisible)
  output$project_end_date <- renderText({
    p <- current_project()
    if (!is.null(p)) format(as.Date(as.POSIXct(p$deadline_at, origin = "1970-01-01")), "%b %d, %Y") else ""
  })
  
  # Badge statut : Successful / Live / Failed / Canceled
  # Récupéré depuis kickstarter.PROJECT_EVOLUTION dans config.R
  output$project_status_badge <- renderUI({
    p <- current_project()
    if (!is.null(p)) {
      badge_color <- switch(p$status,
        "Successful" = "#166534",
        "Live"       = "#2563EB",
        "Failed"     = "#991B1B",
        "#667EEA"
      )
      div(class = "status-badge", style = sprintf("background-color: %s;", badge_color), p$status)
    }
  })
  
  # ── Funding Overview ─────────────────────────────────────────────────────
  
  # Montant collecté converti en EUR (taux fixes dans config.R)
  output$project_collected <- renderText({
    p <- current_project()
    if (!is.null(p)) {
      eur <- convert_to_eur(p$pledged_amount, p$goal_currency)
      paste0("€", formatC(eur, format = "f", digits = 0, big.mark = ","))
    } else ""
  })
  
  # Objectif de financement converti en EUR
  output$project_goal <- renderText({
    p <- current_project()
    if (!is.null(p)) {
      eur <- convert_to_eur(p$goal_amount, p$goal_currency)
      paste0("€", formatC(eur, format = "f", digits = 0, big.mark = ","))
    } else ""
  })
  
  # Nombre total de contributeurs (dernier snapshot)
  output$project_backers <- renderText({
    p <- current_project()
    if (!is.null(p)) formatC(p$backers_count, format = "d", big.mark = ",") else ""
  })
  
  # Pie chart : % collecté vs restant (plafonné à 100% visuellement)
  output$overview_pie <- renderPlotly({
    p <- current_project()
    if (is.null(p)) return(NULL)
    
    collected_pct <- min(p$percent_funded, 100)
    remaining_pct <- max(100 - p$percent_funded, 0)
    
    overview_data <- data.frame(
      label = c("Collected", "Remaining"),
      value = c(collected_pct, remaining_pct),
      color = c("#4C1D95", "#C4B5FD")
    )

    plot_ly(data = overview_data, labels = ~label, values = ~value, type = 'pie',
            marker = list(colors = ~color),
            textinfo = 'percent',
            textposition = 'inside',
            textfont = list(size = 20),
            domain = list(x = c(0, 1), y = c(0.15, 1)),
            hoverinfo = 'label+percent', showlegend = TRUE) %>%
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor = 'rgba(0,0,0,0)',
             margin = list(l = 20, r = 20, t = 20, b = 20),
             legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = 0.05)) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── Quick Stats ──────────────────────────────────────────────────────────
  
  # Moyenne quotidienne collectée (devise originale → EUR)
  output$stat_daily_avg <- renderText({
    p     <- current_project()
    stats <- current_quick_stats()
    if (is.null(p) || is.null(stats) || is.na(stats$daily_avg_amount)) return("€0")
    eur <- convert_to_eur(stats$daily_avg_amount, p$goal_currency)
    paste0("€", formatC(eur, format = "f", digits = 0, big.mark = ","))
  })
  
  # Jours restants avant la deadline (calculé dynamiquement)
  output$stat_days_remaining <- renderText({
    stats <- current_quick_stats()
    if (is.null(stats)) return("—")
    paste0(stats$jours_restants, " days")
  })
  
  # Funding Velocity : compare le projet à la moyenne de sa catégorie
  # Seuils : > +20% → Above Average | < -20% → Below Average | sinon Average
  output$stat_funding_velocity <- renderText({
    stats   <- current_quick_stats()
    cat_avg <- category_avg_velocity()
    
    proj_avg <- tryCatch(as.numeric(stats$daily_avg_amount), error = function(e) NA)
    cat_val  <- tryCatch(as.numeric(cat_avg), error = function(e) NA)
    
    if (is.na(proj_avg) || is.na(cat_val) || cat_val == 0) return("🟡 Average")
    
    if (proj_avg > cat_val * 1.2) {
      "🟢 Above Average"
    } else if (proj_avg < cat_val * 0.8) {
      "🔴 Below Average"
    } else {
      "🟡 Average"
    }
  })
  
  # Backers growth : moyenne quotidienne de nouveaux contributeurs (arrondi à l'entier)
  output$stat_backers_growth <- renderText({
    stats <- current_quick_stats()
    if (is.null(stats) || is.na(stats$daily_avg_backers)) return("+0/day")
    paste0("+", round(stats$daily_avg_backers, 0), "/day")
  })
  
  # ── Funding Progress chart ────────────────────────────────────────────────
  # Reactive : récupère les données pour les 3 courbes du graphique
  # Logique de comparaison (courbe catégorie) :
  #   >= 3 projets dans la sous-catégorie → moyenne sous-catégorie
  #   < 3 projets → fallback sur la catégorie parente (plus représentatif)
  current_funding_progress <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)
    
    con <- get_db_connection()
    tryCatch({
      
      # Courbe 1 : progression ratio_financement du projet par date
      query_project <- sprintf("
        SELECT
          d.date_complete       AS date,
          fps.ratio_financement AS ratio
        FROM Fait_projet_snapshot fps
        JOIN Date_dim d ON fps.id_date_collecte = d.id_date
        WHERE fps.id_projet = %d
        ORDER BY d.date_complete
      ", p$project_id)
      
      project_progress      <- safe_dbGetQuery(con, query_project)
      project_progress$date <- as.Date(project_progress$date)
      
      # Courbe 2 : moyenne de comparaison (sous-catégorie ou catégorie parente)
      stats     <- current_quick_stats()
      categorie <- if (!is.null(stats) && !is.na(stats$categorie)) stats$categorie else NULL
      
      category_avg <- NULL
      label_cat    <- "Category Average"
      
      if (!is.null(categorie)) {
        
        # Vérifie si la sous-catégorie a assez de projets pour être représentative
        nb_projets_cat <- tryCatch({
          safe_dbGetQuery(con, sprintf("
            SELECT COUNT(DISTINCT id_projet) AS n
            FROM Fait_projet_snapshot
            WHERE categorie = '%s'
          ", categorie))$n
        }, error = function(e) 0)
        
        if (!is.null(nb_projets_cat) && !is.na(nb_projets_cat) && nb_projets_cat >= 3) {
          # ✅ Sous-catégorie représentative (>= 3 projets)
          filtre_cat <- sprintf("fps.categorie = '%s'", categorie)
          label_cat  <- sprintf("%s avg.", categorie)
          
        } else {
          # ⚠️ Sous-catégorie trop petite → fallback catégorie parente
          cat_parente <- tryCatch({
            safe_dbGetQuery(con, sprintf("
              SELECT nom_categorie_mere FROM Categorie
              WHERE nom_categorie = '%s'
              LIMIT 1
            ", categorie))$nom_categorie_mere
          }, error = function(e) NULL)
          
          if (!is.null(cat_parente) && length(cat_parente) > 0 && !is.na(cat_parente)) {
            filtre_cat <- sprintf("c.nom_categorie_mere = '%s'", cat_parente)
            label_cat  <- sprintf("%s avg. (parent)", cat_parente)
          } else {
            filtre_cat <- NULL
          }
        }
        
        # Requête courbe catégorie : limitée aux dates scrappées du projet
        if (!is.null(filtre_cat)) {
          query_cat <- sprintf("
            SELECT
              d.date_complete            AS date,
              AVG(fps.ratio_financement) AS avg_ratio
            FROM Fait_projet_snapshot fps
            JOIN Date_dim d  ON fps.id_date_collecte = d.id_date
            JOIN Categorie c ON fps.categorie = c.nom_categorie
            WHERE %s
              AND d.date_complete BETWEEN '%s' AND '%s'
            GROUP BY d.date_complete
            ORDER BY d.date_complete
          ",
                               filtre_cat,
                               format(min(project_progress$date)),
                               format(max(project_progress$date)))
          
          category_avg      <- safe_dbGetQuery(con, query_cat)
          category_avg$date <- as.Date(category_avg$date)
        }
      }
      
      return(list(
        project   = project_progress,
        category  = category_avg,
        label_cat = label_cat
      ))
      
    }, error = function(e) {
      message("Error fetching funding progress: ", e$message)
      return(NULL)
    }, finally = {
      close_db_connection(con)
    })
  })
  
  # Rendu du graphique Funding Progress
  output$main_chart <- renderPlotly({
    p    <- current_project()
    data <- current_funding_progress()
    
    if (is.null(p) || is.null(data)) return(NULL)
    
    proj      <- data$project
    cat       <- data$category
    label_cat <- data$label_cat
    
    plot <- plot_ly() %>%
      # Courbe 1 : progression du projet — bleu vif
      add_trace(
        data = proj, x = ~date, y = ~ratio,
        name = 'Funding Progress', type = 'scatter', mode = 'lines+markers',
        line   = list(color = '#1E90FF', width = 4),
        marker = list(color = '#1E90FF', size = 8,
                      line = list(color = 'white', width = 2))
      ) %>%
      # Courbe 2 : ligne Goal = 100% — violet profond
      add_trace(
        data = proj, x = ~date, y = rep(100, nrow(proj)),
        name = 'Goal (100%)', type = 'scatter', mode = 'lines',
        line = list(color = '#6A0DAD', width = 3, dash = 'dot')
      )

    # Courbe 3 : moyenne catégorie — jaune
    if (!is.null(cat) && nrow(cat) > 0) {
      plot <- plot %>%
        add_trace(
          data = cat, x = ~date, y = ~avg_ratio,
          name = label_cat, type = 'scatter', mode = 'lines+markers',
          line   = list(color = '#F4C430', width = 3, dash = 'dash'),
          marker = list(color = '#F4C430', size = 6,
                        line = list(color = 'white', width = 2))
        )
    }
    
    plot %>%
      layout(
        xaxis = list(
          title      = "",
          gridcolor  = '#E5E7EB',
          showgrid   = TRUE,
          tickformat = "%m/%d",  # format date : mois/jour sans année
          nticks     = 25,
          tickangle  = -45
        ),
        yaxis = list(
          title      = "% of Goal",
          gridcolor  = '#E5E7EB',
          showgrid   = TRUE,
          ticksuffix = "%"
        ),
        hovermode     = 'x unified',
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor  = 'rgba(0,0,0,0)',
        legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.15),
        margin = list(l = 60, r = 40, t = 20, b = 80)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ============================================================================
  # APPELS AUX MODULES SERVEUR
  # Chaque module reçoit current_project en reactive pour accéder au projet actif
  # ============================================================================
  sentiment_server(input, output, session, current_project)  # onglet Sentiment (BERT)
  rewards_server(input, output, session, current_project)    # onglet Rewards
  creator_server(input, output, session, current_project)    # onglet Creator
  ai_server(input, output, session, current_project)         # onglet AI Insights
}