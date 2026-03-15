# ============================================================================
# Creator tab server logic
# ============================================================================
creator_server <- function(input, output, session, current_project) {

  # All projects by the same creator (filtered by creator_name)
  creator_projects <- reactive({
    p <- current_project()
    if (is.null(p)) return(data.frame())
    sample_projects[sample_projects$creator_name == p$creator_name, ]
  })

  # ── Données créateur depuis kickstarter.CREATOR ───────────────────────────
  creator_ks_data <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)

    con <- get_ks_connection()
    tryCatch({
      query <- sprintf("
        SELECT c.biography, c.is_fb_connected, c.nb_websites
        FROM CREATOR c
        INNER JOIN PROJECT pr ON c.creator_id = pr.id_creator
        WHERE pr.project_id = %d
        LIMIT 1
      ", p$project_id)
      result <- suppressWarnings(dbGetQuery(con, query))
      if (nrow(result) == 0) return(NULL)
      result
    }, error = function(e) {
      message("Error fetching creator KS data: ", e$message)
      return(NULL)
    }, finally = {
      close_db_connection(con)
    })
  })

  # Creator initials (e.g. "John Doe" -> "JD")
  output$creator_initials <- renderText({
    p <- current_project()
    if (is.null(p)) return("?")
    name <- trimws(as.character(p$creator_name))
    if (is.na(name) || nchar(name) == 0) return("?")
    parts <- strsplit(name, "\\s+")[[1]]
    parts <- parts[nchar(parts) > 0]
    if (length(parts) >= 2) {
      paste0(toupper(substr(parts[1], 1, 1)), toupper(substr(parts[length(parts)], 1, 1)))
    } else if (length(parts) == 1) {
      toupper(substr(parts[1], 1, 2))
    } else {
      "?"
    }
  })

  # Creator full name
  output$creator_name_header <- renderText({
    p <- current_project()
    if (is.null(p)) return("")
    name <- as.character(p$creator_name)
    if (is.na(name) || nchar(trimws(name)) == 0) return("Unknown Creator")
    name
  })

  # Creator title (derived from category)
  output$creator_title <- renderText({
    p <- current_project()
    if (is.null(p)) return("")
    cat_val <- as.character(p$category)
    if (is.na(cat_val) || nchar(trimws(cat_val)) == 0) return("Kickstarter Creator")
    paste0(cat_val, " Creator · Kickstarter")
  })

  # Creator location
  output$creator_location <- renderText({
    p <- current_project()
    if (is.null(p)) return("Location unknown")
    loc <- as.character(p$country)
    if (!is.na(loc) && nchar(trimws(loc)) > 0) loc else "Location unknown"
  })

  # Total number of projects
  output$creator_total_projects <- renderText({
    as.character(nrow(creator_projects()))
  })

  # Nombre de réponses du créateur sur le projet actif
  output$creator_reply_count <- renderText({
    p <- current_project()
    if (is.null(p)) return("0")
    con <- get_ks_connection()
    tryCatch({
      query <- sprintf("
        SELECT COUNT(*) AS n
        FROM PROJECT_COMMENT
        WHERE project_id = %d AND is_creator_reply = 1
      ", p$project_id)
      result <- suppressWarnings(dbGetQuery(con, query))
      as.character(result$n[1])
    }, error = function(e) {
      message("Error fetching creator replies: ", e$message)
      "0"
    }, finally = {
      close_db_connection(con)
    })
  })

  # Nombre de sites web du créateur
  output$creator_nb_websites <- renderText({
    ks <- creator_ks_data()
    if (is.null(ks)) return("—")
    n <- ks$nb_websites[1]
    if (is.na(n)) return("—")
    as.character(as.integer(n))
  })

  # Badge Facebook : connecté ou non
  output$creator_fb_badge <- renderUI({
    ks <- creator_ks_data()
    connected <- !is.null(ks) && isTRUE(as.logical(ks$is_fb_connected[1]))
    if (connected) {
      div(style = "padding: 4px 10px; background: #E8F0FE; color: #1877F2; border-radius: 12px; font-size: 11px; font-weight: 600; display: inline-flex; align-items: center; gap: 5px;",
          icon("facebook", style = "font-size: 12px;"), "Facebook Connected")
    } else {
      div(style = "padding: 4px 10px; background: #F3F4F6; color: #9CA3AF; border-radius: 12px; font-size: 11px; font-weight: 600; display: inline-flex; align-items: center; gap: 5px;",
          icon("facebook", style = "font-size: 12px;"), "Not on Facebook")
    }
  })

  # Biographie du créateur
  output$creator_bio <- renderUI({
    ks <- creator_ks_data()
    bio <- if (!is.null(ks)) trimws(as.character(ks$biography[1])) else ""
    if (is.na(bio) || nchar(bio) == 0) return(NULL)
    div(style = "font-size: 15px; color: #6B7280; margin-top: 8px; line-height: 1.6; font-style: italic;",
        bio)
  })

  # Radar chart: creator strengths (sample scores)
  output$creator_strengths_radar <- renderPlotly({
    theta_labels <- c("Communication", "Delivery", "Innovation", "Community", "Transparency", "Communication")
    r_values     <- c(92, 78, 85, 88, 75, 92)

    plot_ly(
      type   = 'scatterpolar',
      mode   = 'lines+markers',
      r      = r_values,
      theta  = theta_labels,
      fill   = 'toself',
      fillcolor = 'rgba(102, 126, 234, 0.2)',
      line  = list(color = '#667EEA', width = 2),
      marker = list(color = '#667EEA', size = 6)
    ) %>%
      layout(
        polar = list(
          radialaxis = list(
            visible        = TRUE,
            range          = c(0, 100),
            showticklabels = FALSE,
            gridcolor      = '#E5E7EB'
          ),
          angularaxis = list(tickfont = list(size = 11, color = '#6B7280'))
        ),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor  = 'rgba(0,0,0,0)',
        margin        = list(l = 40, r = 40, t = 40, b = 40),
        showlegend    = FALSE
      ) %>%
      config(displayModeBar = FALSE)
  })

  # Bar chart: communication activity (sample monthly update counts)
  output$creator_communication_chart <- renderPlotly({
    months  <- c("Sep", "Oct", "Nov", "Dec", "Jan", "Feb")
    updates <- c(2, 4, 3, 5, 3, 4)

    plot_ly(
      x    = months,
      y    = updates,
      type = 'bar',
      marker = list(
        color = 'rgba(102, 126, 234, 0.8)',
        line  = list(color = '#667EEA', width = 1.5)
      )
    ) %>%
      layout(
        xaxis = list(title = "", showgrid = FALSE, tickfont = list(color = '#6B7280')),
        yaxis = list(title = "Updates", gridcolor = '#E5E7EB', zeroline = FALSE),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor  = 'rgba(0,0,0,0)',
        margin        = list(l = 45, r = 20, t = 20, b = 40)
      ) %>%
      config(displayModeBar = FALSE)
  })

  # Timeline: past / current projects
  output$creator_past_projects <- renderUI({
    cp <- creator_projects()
    p  <- current_project()

    if (nrow(cp) == 0) {
      return(div(style = "color: #95A5A6; text-align: center; padding: 20px;",
                 "No project history available."))
    }

    # Sort by launch date descending
    cp <- cp[order(-cp$launched_at), ]

    project_items <- lapply(seq_len(nrow(cp)), function(i) {
      proj <- cp[i, ]
      is_current <- !is.null(p) && proj$project_id == p$project_id

      status_color <- switch(as.character(proj$status),
        "Successful" = "#05CE78",
        "Live"       = "#3498DB",
        "Failed"     = "#E74C3C",
        "Canceled"   = "#95A5A6",
        "#95A5A6"
      )

      pct_text <- if (!is.na(proj$percent_funded)) {
        paste0(round(proj$percent_funded), "% funded")
      } else ""

      sub_cat <- if (!is.na(proj$category_sub) && nchar(trimws(proj$category_sub)) > 0) {
        paste0(" / ", proj$category_sub)
      } else ""

      launch_year <- tryCatch(
        format(as.POSIXct(proj$launched_at, origin = "1970-01-01"), "%Y"),
        error = function(e) ""
      )

      div(class = "timeline-item",
          div(style = "display: flex; justify-content: space-between; align-items: flex-start;",
              div(
                div(style = "font-weight: bold; color: #2C3E50; margin-bottom: 4px;",
                    proj$title,
                    if (is_current) {
                      tags$span(style = "margin-left: 8px; font-size: 11px; color: #667EEA; font-weight: 600;",
                                "(Current)")
                    }
                ),
                div(style = "font-size: 12px; color: #95A5A6;",
                    paste0(proj$category, sub_cat, if (nchar(launch_year) > 0) paste0("  ·  ", launch_year) else ""))
              ),
              div(style = "text-align: right; flex-shrink: 0; margin-left: 12px;",
                  div(style = paste0("font-size: 12px; font-weight: 600; color: ", status_color, ";"),
                      proj$status),
                  div(style = "font-size: 12px; color: #95A5A6;", pct_text)
              )
          )
      )
    })

    tagList(project_items)
  })

  # Force rendering even when the Creator tab is hidden
  outputOptions(output, "creator_fb_badge",             suspendWhenHidden = FALSE)
  outputOptions(output, "creator_bio",                  suspendWhenHidden = FALSE)
  outputOptions(output, "creator_initials",             suspendWhenHidden = FALSE)
  outputOptions(output, "creator_name_header",         suspendWhenHidden = FALSE)
  outputOptions(output, "creator_title",               suspendWhenHidden = FALSE)
  outputOptions(output, "creator_location",            suspendWhenHidden = FALSE)
  outputOptions(output, "creator_total_projects",      suspendWhenHidden = FALSE)
  outputOptions(output, "creator_reply_count",          suspendWhenHidden = FALSE)
  outputOptions(output, "creator_nb_websites",         suspendWhenHidden = FALSE)
  outputOptions(output, "creator_strengths_radar",     suspendWhenHidden = FALSE)
  outputOptions(output, "creator_communication_chart", suspendWhenHidden = FALSE)
  outputOptions(output, "creator_past_projects",       suspendWhenHidden = FALSE)
}
