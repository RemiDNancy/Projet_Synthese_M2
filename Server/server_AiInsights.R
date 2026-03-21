# ============================================================================
# server_AiInsights.R
# Logique serveur de l'onglet AI Insights
# Sources : Fait_prediction_projet | Fait_metriques_modele | Fait_detail_facteurs
# ============================================================================
ai_server <- function(input, output, session, current_project) {

  # ── Sélection du modèle actif (oracle par défaut) ─────────────────────────
  active_ai_model <- reactiveVal("oracle")

  observeEvent(input$switch_to_oracle, {
    active_ai_model("oracle")
    shinyjs::runjs("
      $('#oracle_card').addClass('active');
      $('#sage_card').removeClass('active');
      $('#oracle_analysis').addClass('active');
      $('#sage_analysis').removeClass('active');
    ")
  })

  observeEvent(input$switch_to_sage, {
    active_ai_model("sage")
    shinyjs::runjs("
      $('#sage_card').addClass('active');
      $('#oracle_card').removeClass('active');
      $('#sage_analysis').addClass('active');
      $('#oracle_analysis').removeClass('active');
    ")
  })

  observeEvent(input$selected_ai_model, {
    if (input$selected_ai_model == "oracle") {
      active_ai_model("oracle")
      shinyjs::runjs("
        $('#oracle_card').addClass('active');
        $('#sage_card').removeClass('active');
        $('#oracle_analysis').addClass('active');
        $('#sage_analysis').removeClass('active');
      ")
    } else if (input$selected_ai_model == "sage") {
      active_ai_model("sage")
      shinyjs::runjs("
        $('#sage_card').addClass('active');
        $('#oracle_card').removeClass('active');
        $('#sage_analysis').addClass('active');
        $('#oracle_analysis').removeClass('active');
      ")
    }
  })

  # ── Prédictions du projet actif ───────────────────────────────────────────
  # Chaque modèle insère sa propre ligne → on récupère la dernière valeur
  # non-nulle pour chaque modèle indépendamment, puis on les combine.
  ai_predictions <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)

    con <- get_db_connection()
    tryCatch({
      knn_row <- suppressWarnings(dbGetQuery(con, sprintf("
        SELECT proba_knn
        FROM Fait_prediction_projet
        WHERE id_projet = %d AND proba_knn IS NOT NULL
        ORDER BY id_date DESC
        LIMIT 1
      ", p$project_id)))

      rf_row <- suppressWarnings(dbGetQuery(con, sprintf("
        SELECT proba_rf
        FROM Fait_prediction_projet
        WHERE id_projet = %d AND proba_rf IS NOT NULL
        ORDER BY id_date DESC
        LIMIT 1
      ", p$project_id)))

      knn_val <- if (nrow(knn_row) > 0) knn_row$proba_knn[1] else NA
      rf_val  <- if (nrow(rf_row)  > 0) rf_row$proba_rf[1]   else NA
      gap_val <- if (!is.na(knn_val) && !is.na(rf_val)) abs(rf_val - knn_val) else NA

      data.frame(proba_knn = knn_val, proba_rf = rf_val, ecart_modeles = gap_val)
    }, error = function(e) {
      message("AI predictions fetch error: ", e$message)
      NULL
    }, finally = { close_db_connection(con) })
  })

  # ── Métriques globales des modèles ────────────────────────────────────────
  # Source : Fait_metriques_modele (accuracy, precision, recall, f1)
  # Ces métriques sont indépendantes du projet — chargées une seule fois
  ai_metrics <- reactive({
    con <- get_db_connection()
    tryCatch({
      knn <- suppressWarnings(dbGetQuery(con, "
        SELECT nom_metrique, valeur
        FROM Fait_metriques_modele fmm
        JOIN Modele_AI ma ON fmm.id_modele = ma.id_modele
        WHERE ma.nom_modele = 'KNN'
        AND fmm.id_date = (
          SELECT MAX(fmm2.id_date)
          FROM Fait_metriques_modele fmm2
          JOIN Modele_AI ma2 ON fmm2.id_modele = ma2.id_modele
          WHERE ma2.nom_modele = 'KNN'
        )
      "))
      rf <- suppressWarnings(dbGetQuery(con, "
        SELECT nom_metrique, valeur
        FROM Fait_metriques_modele fmm
        JOIN Modele_AI ma ON fmm.id_modele = ma.id_modele
        WHERE ma.nom_modele = 'RandomForest'
        AND fmm.id_date = (
          SELECT MAX(fmm2.id_date)
          FROM Fait_metriques_modele fmm2
          JOIN Modele_AI ma2 ON fmm2.id_modele = ma2.id_modele
          WHERE ma2.nom_modele = 'RandomForest'
        )
      "))
      list(knn = knn, rf = rf)
    }, error = function(e) {
      message("AI metrics fetch error: ", e$message)
      list(knn = data.frame(), rf = data.frame())
    }, finally = { close_db_connection(con) })
  })

  # ── Facteurs d'importance RF ──────────────────────────────────────────────
  # Source : Fait_detail_facteurs (uniquement Random Forest)
  ai_factors <- reactive({
    con <- get_db_connection()
    tryCatch({
      suppressWarnings(dbGetQuery(con, "
        SELECT nom_facteur, score_facteur, badge_niveau
        FROM Fait_detail_facteurs fdf
        JOIN Modele_AI ma ON fdf.id_modele = ma.id_modele
        WHERE ma.nom_modele = 'RandomForest'
        AND fdf.id_date = (
          SELECT MAX(fdf2.id_date)
          FROM Fait_detail_facteurs fdf2
          JOIN Modele_AI ma2 ON fdf2.id_modele = ma2.id_modele
          WHERE ma2.nom_modele = 'RandomForest'
        )
        ORDER BY score_facteur DESC
        LIMIT 3
      "))
    }, error = function(e) {
      message("AI factors fetch error: ", e$message)
      data.frame()
    }, finally = { close_db_connection(con) })
  })

  # ── Helper : récupère la valeur d'une métrique par nom ───────────────────
  get_metric <- function(df, metric_name) {
    if (is.null(df) || nrow(df) == 0) return(NA)
    val <- df$valeur[df$nom_metrique == metric_name]
    if (length(val) == 0) return(NA)
    val[1]
  }

  fmt_pct <- function(val, suffix = "%") {
    if (is.null(val) || is.na(val)) return("N/A")
    paste0(round(val), suffix)
  }

  # ── Prédictions principales (cartes du haut) ─────────────────────────────
  output$oracle_prediction <- renderText({
    pred <- ai_predictions()
    if (is.null(pred) || nrow(pred) == 0) return("N/A")
    fmt_pct(pred$proba_knn[1])
  })

  output$sage_prediction <- renderText({
    pred <- ai_predictions()
    if (is.null(pred) || nrow(pred) == 0) return("N/A")
    fmt_pct(pred$proba_rf[1])
  })

  # ── Métriques Oracle (KNN) ────────────────────────────────────────────────
  output$oracle_pattern <- renderText({
    fmt_pct(get_metric(ai_metrics()$knn, "precision"))
  })

  output$oracle_accuracy <- renderText({
    fmt_pct(get_metric(ai_metrics()$knn, "accuracy"))
  })

  output$oracle_neighbor <- renderText({
    fmt_pct(get_metric(ai_metrics()$knn, "recall"))
  })

  # ── Métriques Sage (Random Forest) ───────────────────────────────────────
  output$sage_multifactor <- renderText({
    fmt_pct(get_metric(ai_metrics()$rf, "f1"))
  })

  output$sage_robustness <- renderText({
    fmt_pct(get_metric(ai_metrics()$rf, "recall"))
  })

  output$sage_feature <- renderText({
    fmt_pct(get_metric(ai_metrics()$rf, "precision"))
  })

  # ── Facteurs d'importance (Sage — Random Forest) ─────────────────────────
  output$sage_factors_ui <- renderUI({
    factors <- ai_factors()
    if (is.null(factors) || nrow(factors) == 0) {
      return(div(style = "color: #95A5A6; font-size: 13px;", "No factor data available."))
    }

    badge_colors <- c("Hot" = "#EF4444", "Medium" = "#F59E0B", "Low" = "#95A5A6")

    tagList(lapply(seq_len(nrow(factors)), function(i) {
      f     <- factors[i, ]
      score <- round(f$score_facteur)
      badge <- as.character(f$badge_niveau)
      color <- if (badge %in% names(badge_colors)) badge_colors[badge] else "#95A5A6"

      div(class = "ai-factor-item",
          div(class = "ai-factor-name", as.character(f$nom_facteur)),
          div(class = "ai-factor-score",
              paste0(score, "%"),
              tags$span(class = paste0("ai-badge ", tolower(badge)), badge)
          ),
          div(class = "ai-factor-bar",
              div(style = sprintf("width: %d%%; background: #2A8F74; height: 6px; border-radius: 3px;", score))
          )
      )
    }))
  })

  # ── Mise à jour dynamique des barres et de la section comparaison ─────────
  # Utilise shinyjs pour mettre à jour les largeurs de barres et les textes
  # sans restructurer le HTML
  observe({
    pred <- ai_predictions()
    if (is.null(pred) || nrow(pred) == 0) return()

    knn_raw <- pred$proba_knn[1]
    rf_raw  <- pred$proba_rf[1]
    gap_raw <- pred$ecart_modeles[1]

    if (is.na(knn_raw) || is.na(rf_raw)) return()

    knn_pct <- round(knn_raw)
    rf_pct  <- round(rf_raw)
    gap     <- if (!is.na(gap_raw)) round(gap_raw) else abs(knn_pct - rf_pct)

    shinyjs::runjs(sprintf("
      $('.oracle-fill').css('width', '%d%%');
      $('.sage-fill').css('width', '%d%%');
      $('.ai-gap-value').text('%d%% gap');
    ", knn_pct, rf_pct, gap))
  })

  # ── outputOptions ─────────────────────────────────────────────────────────
  outputOptions(output, "oracle_prediction", suspendWhenHidden = FALSE)
  outputOptions(output, "sage_prediction",   suspendWhenHidden = FALSE)
  outputOptions(output, "oracle_pattern",    suspendWhenHidden = FALSE)
  outputOptions(output, "oracle_accuracy",   suspendWhenHidden = FALSE)
  outputOptions(output, "oracle_neighbor",   suspendWhenHidden = FALSE)
  outputOptions(output, "sage_multifactor",  suspendWhenHidden = FALSE)
  outputOptions(output, "sage_robustness",   suspendWhenHidden = FALSE)
  outputOptions(output, "sage_feature",      suspendWhenHidden = FALSE)
  outputOptions(output, "sage_factors_ui",   suspendWhenHidden = FALSE)
}
