# ============================================================================
# server_sentiment.R
# Logique serveur de l'onglet Sentiment
# Source : base_traitee.Fait_commentaire (BERT scores)
# ============================================================================
sentiment_server <- function(input, output, session, current_project) {
  
  # ── Données sentiment : une seule requête pour donut + évolution ─────────
  # Compte les commentaires par label (POS/NEU/NEG) pour le projet actif
  current_sentiment_summary <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)
    
    con <- get_db_connection()
    tryCatch({
      query <- sprintf("
        SELECT
          sentiment_label,
          COUNT(*) AS nb
        FROM Fait_commentaire
        WHERE id_projet = %d
          AND sentiment_label IS NOT NULL
        GROUP BY sentiment_label
      ", p$project_id)
      
      result <- suppressWarnings(safe_dbGetQuery(con, query))
      return(result)
    }, error = function(e) {
      message("Error fetching sentiment summary: ", e$message)
      return(NULL)
    }, finally = {
      close_db_connection(con)
    })
  })
  
  # ── Calcul des pourcentages POS / NEU / NEG ──────────────────────────────
  # Retourne une liste avec pct_pos, pct_neu, pct_neg et total
  sentiment_pcts <- reactive({
    data <- current_sentiment_summary()
    if (is.null(data) || nrow(data) == 0) {
      return(list(pos = 0, neu = 0, neg = 0, total = 0))
    }
    
    total <- sum(data$nb)
    
    get_pct <- function(label) {
      row <- data[data$sentiment_label == label, ]
      if (nrow(row) == 0) return(0)
      round(row$nb / total * 100, 1)
    }
    
    list(
      pos   = get_pct("POS"),
      neu   = get_pct("NEU"),
      neg   = get_pct("NEG"),
      total = total
    )
  })
  
  # ── Donut chart : Overall Sentiment ──────────────────────────────────────
  # Arc POS (vert) / NEU (bleu) / NEG (rouge)
  # Le texte centré (% positif) est géré côté UI avec uiOutput
  output$sentiment_donut_main <- renderPlotly({
    pcts <- sentiment_pcts()
    
    sentiment_df <- data.frame(
      label  = c("Positive", "Neutral", "Negative"),
      value  = c(pcts$pos, pcts$neu, pcts$neg),
      color  = c('#86EFAC', '#93C5FD', '#FCA5A5'),
      stringsAsFactors = FALSE
    )
    
    # Si aucune donnée → donut gris placeholder
    if (pcts$total == 0) {
      sentiment_df$value <- c(33, 34, 33)
      sentiment_df$color <- c('#E5E7EB', '#E5E7EB', '#E5E7EB')
    }
    
    plot_ly() %>%
      add_pie(
        data         = sentiment_df,
        labels       = ~label,
        values       = ~value,
        hole         = 0.65,
        marker       = list(colors = ~color,
                            line = list(color = 'white', width = 2)),
        textposition = 'none',
        hoverinfo    = 'label+percent',
        showlegend   = FALSE
      ) %>%
      layout(
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor  = 'rgba(0,0,0,0)',
        margin = list(l = 0, r = 0, t = 0, b = 0),
        xaxis  = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
        yaxis  = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ── Texte centré du donut : % positif ou message si pas de commentaires ──
  output$sentiment_donut_center <- renderUI({
    pcts <- sentiment_pcts()
    
    if (pcts$total == 0) {
      # Projet sans commentaires BERT → message explicite
      tagList(
        div(style = "font-size: 28px; color: #BDC3C7; line-height: 1;", "\U1F4AC"),
        div(style = "font-size: 12px; color: #BDC3C7; margin-top: 6px; max-width: 100px;",
            "No comments available for this project")
      )
    } else {
      tagList(
        div(style = "font-size: 42px; font-weight: bold; color: #059669; line-height: 1;",
            paste0(pcts$pos, "%")),
        div(style = "font-size: 13px; color: #95A5A6; margin-top: 4px;", "Positive")
      )
    }
  })
  
  # ── Badges % sous le donut : Positive / Neutral / Negative ──────────────
  output$sentiment_pct_positive <- renderText({
    paste0(sentiment_pcts()$pos, "%")
  })
  output$sentiment_pct_neutral <- renderText({
    paste0(sentiment_pcts()$neu, "%")
  })
  output$sentiment_pct_negative <- renderText({
    paste0(sentiment_pcts()$neg, "%")
  })
  
  # ── Sentiment Evolution chart ─────────────────────────────────────────────
  # Agrège les commentaires par semaine pour voir l'évolution temporelle
  # Source : Fait_commentaire JOIN Date_dim sur id_date_collecte
  output$sentiment_evolution_chart <- renderPlotly({
    p <- current_project()
    if (is.null(p)) return(NULL)
    
    con <- get_db_connection()
    tryCatch({
      # Agrégation hebdomadaire par label
      # GROUP BY inclut YEARWEEK + sentiment_label (compatible only_full_group_by)
      # MIN(date_complete) est une fonction d'agrégation → pas de problème
      query <- sprintf("
        SELECT
          YEARWEEK(d.date_complete, 1)    AS semaine,
          MIN(d.date_complete)            AS date_debut,
          fc.sentiment_label,
          COUNT(*)                        AS nb
        FROM Fait_commentaire fc
        JOIN Date_dim d ON fc.id_date_collecte = d.id_date
        WHERE fc.id_projet = %d
          AND fc.sentiment_label IS NOT NULL
        GROUP BY YEARWEEK(d.date_complete, 1), fc.sentiment_label
        ORDER BY semaine
      ", p$project_id)
      
      raw <- suppressWarnings(safe_dbGetQuery(con, query))
      
      if (is.null(raw) || nrow(raw) == 0) {
        # Retourne un graphique vide avec message "No comments"
        return(
          plot_ly() %>%
            layout(
              xaxis = list(visible = FALSE),
              yaxis = list(visible = FALSE),
              paper_bgcolor = 'rgba(0,0,0,0)',
              plot_bgcolor  = 'rgba(0,0,0,0)',
              annotations = list(list(
                text      = "No comments available for this project",
                x         = 0.5, y = 0.5,
                xref      = "paper", yref = "paper",
                showarrow = FALSE,
                font      = list(size = 14, color = "#BDC3C7")
              ))
            ) %>%
            config(displayModeBar = FALSE)
        )
      }
      
      # Pivot : une ligne par semaine, colonnes POS/NEU/NEG
      raw$date_debut <- as.Date(raw$date_debut)
      
      semaines <- sort(unique(raw$semaine))
      weekly <- do.call(rbind, lapply(semaines, function(s) {
        sub   <- raw[raw$semaine == s, ]
        total <- sum(sub$nb)
        date  <- sub$date_debut[1]
        data.frame(
          date = date,
          pos  = round(sum(sub$nb[sub$sentiment_label == "POS"]) / total * 100, 1),
          neu  = round(sum(sub$nb[sub$sentiment_label == "NEU"]) / total * 100, 1),
          neg  = round(sum(sub$nb[sub$sentiment_label == "NEG"]) / total * 100, 1)
        )
      }))
      
      plot_ly(weekly) %>%
        add_trace(
          x = ~date, y = ~pos, name = "Positive",
          type = 'scatter', mode = 'lines+markers',
          fill = 'tozeroy',
          line   = list(color = '#86EFAC', width = 3),
          marker = list(color = '#86EFAC', size = 7,
                        line = list(color = 'white', width = 2)),
          fillcolor = 'rgba(134, 239, 172, 0.2)'
        ) %>%
        add_trace(
          x = ~date, y = ~neu, name = "Neutral",
          type = 'scatter', mode = 'lines+markers',
          fill = 'tonexty',
          line   = list(color = '#93C5FD', width = 3),
          marker = list(color = '#93C5FD', size = 7,
                        line = list(color = 'white', width = 2)),
          fillcolor = 'rgba(147, 197, 253, 0.2)'
        ) %>%
        add_trace(
          x = ~date, y = ~neg, name = "Negative",
          type = 'scatter', mode = 'lines+markers',
          fill = 'tonexty',
          line   = list(color = '#FCA5A5', width = 3),
          marker = list(color = '#FCA5A5', size = 7,
                        line = list(color = 'white', width = 2)),
          fillcolor = 'rgba(252, 165, 165, 0.2)'
        ) %>%
        layout(
          xaxis = list(
            title      = "",
            gridcolor  = '#E5E7EB',
            showgrid   = TRUE,
            zeroline   = FALSE,
            tickformat = "%b %d"
          ),
          yaxis = list(
            title      = "% of comments",
            gridcolor  = '#E5E7EB',
            showgrid   = TRUE,
            ticksuffix = "%",
            range      = c(0, 100),
            zeroline   = FALSE
          ),
          hovermode     = 'x unified',
          paper_bgcolor = 'rgba(0,0,0,0)',
          plot_bgcolor  = 'rgba(0,0,0,0)',
          legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.15),
          margin = list(l = 60, r = 40, t = 20, b = 80)
        ) %>%
        config(displayModeBar = FALSE)
      
    }, error = function(e) {
      message("Error fetching sentiment evolution: ", e$message)
      return(NULL)
    }, finally = {
      close_db_connection(con)
    })
  })
  
  # Force le rendu même quand l'onglet est caché (tab CSS custom)
  outputOptions(output, "sentiment_donut_main",      suspendWhenHidden = FALSE)
  outputOptions(output, "sentiment_donut_center",    suspendWhenHidden = FALSE)
  outputOptions(output, "sentiment_pct_positive",    suspendWhenHidden = FALSE)
  outputOptions(output, "sentiment_pct_neutral",     suspendWhenHidden = FALSE)
  outputOptions(output, "sentiment_pct_negative",    suspendWhenHidden = FALSE)
  outputOptions(output, "sentiment_evolution_chart", suspendWhenHidden = FALSE)
}