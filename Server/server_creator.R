# ============================================================================
# server_creator.R
# Creator tab — profile data from kickstarter DB, radar scores from base_traitee DWH.
#
# Data sources:
#   kickstarter.CREATOR + PROJECT  → biography, facebook status, nb_websites, location
#   kickstarter.PROJECT_COMMENT    → creator reply count
#   kickstarter.PROJECT_EVOLUTION  → project history (all projects by same creator)
#   base_traitee.Fait_commentaire  → communication score, community (sentiment)
#   base_traitee.Fait_projet_snapshot → transparency score, delivery score
#   base_traitee.Projet            → innovation flag (is_project_we_love)
# ============================================================================

creator_server <- function(input, output, session, current_project) {

  # ── 1. Creator profile data (kickstarter DB) ─────────────────────────────
  # Fetches biography, Facebook status, website count, and location
  # joined via PROJECT to match the current project's creator.
  creator_ks_data <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)

    con <- get_ks_connection()
    tryCatch({
      query <- sprintf("
        SELECT c.biography, c.is_fb_connected, c.nb_websites,
               c.creator_name, p.location
        FROM CREATOR c
        INNER JOIN PROJECT p ON c.creator_id = p.id_creator
        WHERE p.project_id = %d
        LIMIT 1
      ", p$project_id)
      result <- suppressWarnings(dbGetQuery(con, query))
      if (nrow(result) == 0) return(NULL)
      result
    }, error = function(e) {
      message("Error fetching creator KS data: ", e$message)
      return(NULL)
    }, finally = { close_db_connection(con) })
  })

  # ── 2. Creator reply count (kickstarter DB) ───────────────────────────────
  # Number of comments on this project where the creator is the author.
  creator_reply_data <- reactive({
    p <- current_project()
    if (is.null(p)) return(0L)

    con <- get_ks_connection()
    tryCatch({
      query <- sprintf("
        SELECT COUNT(*) AS n
        FROM PROJECT_COMMENT
        WHERE project_id = %d AND is_creator_reply = 1
      ", p$project_id)
      result <- suppressWarnings(dbGetQuery(con, query))
      as.integer(result$n[1])
    }, error = function(e) 0L,
    finally = { close_db_connection(con) })
  })

  # ── 3. Creator project history (kickstarter DB) ───────────────────────────
  # All projects launched by the same creator, ordered most recent first.
  # Funding state and percentage come from the latest PROJECT_EVOLUTION snapshot.
  creator_history <- reactive({
    p <- current_project()
    if (is.null(p)) return(data.frame())

    con <- get_ks_connection()
    tryCatch({
      query <- sprintf("
        SELECT
          pr.project_id,
          pr.title,
          pr.category,
          pr.subcategory,
          pr.currency,
          pr.goal_amount,
          pr.created_at,
          pr.deadline_at,
          pe.pledged_amount,
          pe.percent_funded,
          pe.current_state
        FROM PROJECT pr
        LEFT JOIN (
          SELECT project_id, pledged_amount, percent_funded, current_state
          FROM PROJECT_EVOLUTION
          WHERE (project_id, scrap_date) IN (
            SELECT project_id, MAX(scrap_date)
            FROM PROJECT_EVOLUTION
            GROUP BY project_id
          )
        ) pe ON pr.project_id = pe.project_id
        WHERE pr.id_creator = (
          SELECT id_creator FROM PROJECT WHERE project_id = %d LIMIT 1
        )
        ORDER BY pr.created_at DESC
      ", p$project_id)

      result <- suppressWarnings(dbGetQuery(con, query))
      if (nrow(result) == 0) return(data.frame())
      result
    }, error = function(e) {
      message("Error fetching creator history: ", e$message)
      return(data.frame())
    }, finally = { close_db_connection(con) })
  })

  # ── 4. Radar scores (base_traitee DWH) ───────────────────────────────────
  #
  # Five axes, all normalised to [0, 100]:
  #
  #   COMMUNICATION  — reply rate: (creator replies / total comments) × 100
  #   TRANSPARENCY   — activity rate: (days with delta > 0 / total days) × 100
  #   COMMUNITY      — average sentiment normalised: ((avg_score + 1) / 2) × 100
  #                    (score_sentiment is in [-1, 1])
  #   DELIVERY       — max funding ratio capped at 100
  #   INNOVATION     — is_project_we_love: 90 if true, 60 if false
  #
  # Falls back to 50 on any missing value.
  creator_radar_scores <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)

    con <- get_db_connection()
    tryCatch({

      q_comm <- sprintf("
        SELECT ROUND(
          100.0 * SUM(CASE WHEN is_creator_reply = 1 THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0)
        , 1) AS comm_score
        FROM Fait_commentaire
        WHERE id_projet = %d
      ", p$project_id)

      q_trans <- sprintf("
        SELECT ROUND(
          100.0 * SUM(CASE WHEN delta_montant_1j > 0 THEN 1 ELSE 0 END)
          / NULLIF(COUNT(*), 0)
        , 1) AS trans_score
        FROM Fait_projet_snapshot
        WHERE id_projet = %d
      ", p$project_id)

      q_sent <- sprintf("
        SELECT ROUND(((AVG(score_sentiment) + 1) / 2) * 100, 1) AS sent_score
        FROM Fait_commentaire
        WHERE id_projet = %d
      ", p$project_id)

      q_deliv <- sprintf("
        SELECT ROUND(LEAST(MAX(ratio_financement) * 100, 100), 1) AS deliv_score
        FROM Fait_projet_snapshot
        WHERE id_projet = %d
      ", p$project_id)

      q_innov <- sprintf("
        SELECT is_project_we_love
        FROM Projet
        WHERE id_projet = %d
        LIMIT 1
      ", p$project_id)

      r_comm  <- safe_dbGetQuery(con, q_comm)
      r_trans <- safe_dbGetQuery(con, q_trans)
      r_sent  <- safe_dbGetQuery(con, q_sent)
      r_deliv <- safe_dbGetQuery(con, q_deliv)
      r_innov <- safe_dbGetQuery(con, q_innov)

      # Helper: extract a numeric score or fall back to 50
      score_or_50 <- function(df, col) {
        val <- df[[col]][1]
        if (is.null(val) || is.na(val)) 50 else as.numeric(val)
      }

      list(
        Communication = score_or_50(r_comm,  "comm_score"),
        Transparency  = score_or_50(r_trans, "trans_score"),
        Community     = score_or_50(r_sent,  "sent_score"),
        Delivery      = score_or_50(r_deliv, "deliv_score"),
        Innovation    = ifelse(
          !is.null(r_innov) && nrow(r_innov) > 0 &&
            isTRUE(as.logical(r_innov$is_project_we_love[1])),
          90, 60
        )
      )

    }, error = function(e) {
      message("Error fetching radar scores: ", e$message)
      return(NULL)
    }, finally = { close_db_connection(con) })
  })

  # ── 5. Header outputs ─────────────────────────────────────────────────────

  # Initials for the avatar circle (e.g. "JD" for "John Doe")
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
    } else "?"
  })

  output$creator_name_header <- renderText({
    p <- current_project()
    if (is.null(p)) return("")
    name <- as.character(p$creator_name)
    if (is.na(name) || nchar(trimws(name)) == 0) return("Unknown Creator")
    name
  })

  # Sub-title built from the project's category (e.g. "Technology Creator · Kickstarter")
  output$creator_title <- renderText({
    p <- current_project()
    if (is.null(p)) return("")
    cat_val <- as.character(p$category)
    if (is.na(cat_val) || nchar(trimws(cat_val)) == 0) return("Kickstarter Creator")
    paste0(cat_val, " Creator · Kickstarter")
  })

  # Location: prefer kickstarter DB value, fall back to country from sample_projects
  output$creator_location <- renderText({
    ks <- creator_ks_data()
    if (!is.null(ks) && !is.na(ks$location[1]) && nchar(trimws(ks$location[1])) > 0) {
      return(ks$location[1])
    }
    p <- current_project()
    if (!is.null(p)) {
      loc <- as.character(p$country)
      if (!is.na(loc) && nchar(trimws(loc)) > 0) return(loc)
    }
    "Location unknown"
  })

  # ── 6. Quick stat outputs ─────────────────────────────────────────────────

  # Total projects launched by this creator (count of history rows)
  output$creator_total_projects <- renderText({
    as.character(nrow(creator_history()))
  })

  # Number of creator replies on this project
  output$creator_reply_count <- renderText({
    as.character(creator_reply_data())
  })

  # Number of external websites listed on the creator's profile
  output$creator_nb_websites <- renderText({
    ks <- creator_ks_data()
    if (is.null(ks)) return("—")
    n <- ks$nb_websites[1]
    if (is.na(n)) return("—")
    as.character(as.integer(n))
  })

  # Facebook connection badge (blue = connected, grey = not connected)
  output$creator_fb_badge <- renderUI({
    ks <- creator_ks_data()
    connected <- !is.null(ks) && isTRUE(as.logical(ks$is_fb_connected[1]))
    if (connected) {
      div(style = paste0(
        "padding:4px 10px;background:#E8F0FE;color:#1877F2;border-radius:12px;",
        "font-size:11px;font-weight:600;display:inline-flex;align-items:center;gap:5px;"
      ), icon("facebook", style = "font-size:12px;"), "Facebook Connected")
    } else {
      div(style = paste0(
        "padding:4px 10px;background:#F3F4F6;color:#9CA3AF;border-radius:12px;",
        "font-size:11px;font-weight:600;display:inline-flex;align-items:center;gap:5px;"
      ), icon("facebook", style = "font-size:12px;"), "Not on Facebook")
    }
  })

  # Biography text (hidden when empty)
  output$creator_bio <- renderUI({
    ks <- creator_ks_data()
    bio <- if (!is.null(ks)) trimws(as.character(ks$biography[1])) else ""
    if (is.na(bio) || nchar(bio) == 0) return(NULL)
    div(style = "font-size:15px;color:#6B7280;margin-top:8px;line-height:1.6;font-style:italic;", bio)
  })

  # ── 7. Radar chart ────────────────────────────────────────────────────────

  output$creator_strengths_radar <- renderPlotly({
    scores <- creator_radar_scores()

    # Fall back to neutral 50 on all axes if DWH query failed
    if (is.null(scores)) {
      scores <- list(Communication = 50, Delivery = 50,
                     Innovation = 50, Community = 50, Transparency = 50)
    }

    axes   <- c("Communication", "Delivery", "Innovation", "Community", "Transparency")
    values <- as.numeric(unlist(scores[axes]))

    # Repeat first point to close the polygon
    theta_labels <- c(axes, axes[1])
    r_values     <- c(values, values[1])

    plot_ly(
      type      = 'scatterpolar',
      mode      = 'lines+markers',
      r         = r_values,
      theta     = theta_labels,
      fill      = 'toself',
      fillcolor = 'rgba(102, 126, 234, 0.2)',
      line      = list(color = '#667EEA', width = 2),
      marker    = list(color = '#667EEA', size = 6)
    ) %>%
      layout(
        polar = list(
          radialaxis  = list(
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

  # ── 8. Radar summary cards ────────────────────────────────────────────────

  # Best performing axis and its score
  output$creator_top_trait <- renderUI({
    scores <- creator_radar_scores()
    if (is.null(scores)) {
      return(div(style = "font-size:20px;font-weight:bold;color:#F39C12;", "—"))
    }
    top_name  <- names(which.max(unlist(scores)))
    top_score <- round(max(unlist(scores)), 0)
    div(style = "font-size:20px;font-weight:bold;color:#F39C12;",
        paste0(top_name, " (", top_score, "%)"))
  })

  # Mean score across all five axes
  output$creator_avg_score <- renderUI({
    scores <- creator_radar_scores()
    if (is.null(scores)) {
      return(div(style = "font-size:20px;font-weight:bold;color:#05CE78;", "—"))
    }
    avg <- round(mean(unlist(scores)), 0)
    div(style = "font-size:20px;font-weight:bold;color:#05CE78;",
        paste0(avg, "%"))
  })

  # ── 9. Creator history timeline ───────────────────────────────────────────

  output$creator_past_projects <- renderUI({
    cp <- creator_history()
    p  <- current_project()

    if (nrow(cp) == 0) {
      return(div(style = "color:#95A5A6;text-align:center;padding:20px;",
                 "No project history available."))
    }

    project_items <- lapply(seq_len(nrow(cp)), function(i) {
      proj       <- cp[i, ]
      is_current <- !is.null(p) && proj$project_id == p$project_id

      state       <- tolower(as.character(proj$current_state))
      state_label <- ifelse(nchar(state) == 0, "Unknown", tools::toTitleCase(state))
      status_color <- switch(state,
                             "successful" = "#05CE78",
                             "live"       = "#3498DB",
                             "failed"     = "#E74C3C",
                             "canceled"   = "#95A5A6",
                             "#95A5A6")

      # Funding percentage text (hidden when not available)
      pct_text <- if (!is.na(proj$percent_funded) && proj$percent_funded != 0) {
        paste0(round(proj$percent_funded), "% funded")
      } else ""

      # Subcategory suffix (e.g. " / Tabletop Games")
      sub_cat <- if (!is.na(proj$subcategory) && nchar(trimws(proj$subcategory)) > 0) {
        paste0(" / ", proj$subcategory)
      } else ""

      launch_year <- tryCatch(
        format(as.Date(proj$created_at), "%Y"),
        error = function(e) ""
      )

      div(class = "timeline-item",
          div(style = "display:flex;justify-content:space-between;align-items:flex-start;",
              div(
                div(style = "font-weight:bold;color:#2C3E50;margin-bottom:4px;",
                    proj$title,
                    # Mark the currently viewed project
                    if (is_current) tags$span(
                      style = "margin-left:8px;font-size:11px;color:#667EEA;font-weight:600;",
                      "(Current)"
                    )
                ),
                div(style = "font-size:12px;color:#95A5A6;",
                    paste0(proj$category, sub_cat,
                           if (nchar(launch_year) > 0) paste0("  ·  ", launch_year) else ""))
              ),
              div(style = "text-align:right;flex-shrink:0;margin-left:12px;",
                  div(style = paste0("font-size:12px;font-weight:600;color:", status_color, ";"),
                      state_label),
                  div(style = "font-size:12px;color:#95A5A6;", pct_text)
              )
          )
      )
    })

    tagList(project_items)
  })

  # ── 10. Prevent Shiny from suspending outputs in CSS-hidden tabs ──────────
  # Required because tab switching is CSS-based (display:none), not Shiny tabPanel.
  outputOptions(output, "creator_fb_badge",        suspendWhenHidden = FALSE)
  outputOptions(output, "creator_bio",             suspendWhenHidden = FALSE)
  outputOptions(output, "creator_initials",        suspendWhenHidden = FALSE)
  outputOptions(output, "creator_name_header",     suspendWhenHidden = FALSE)
  outputOptions(output, "creator_title",           suspendWhenHidden = FALSE)
  outputOptions(output, "creator_location",        suspendWhenHidden = FALSE)
  outputOptions(output, "creator_total_projects",  suspendWhenHidden = FALSE)
  outputOptions(output, "creator_reply_count",     suspendWhenHidden = FALSE)
  outputOptions(output, "creator_nb_websites",     suspendWhenHidden = FALSE)
  outputOptions(output, "creator_strengths_radar", suspendWhenHidden = FALSE)
  outputOptions(output, "creator_past_projects",   suspendWhenHidden = FALSE)
  outputOptions(output, "creator_top_trait",       suspendWhenHidden = FALSE)
  outputOptions(output, "creator_avg_score",       suspendWhenHidden = FALSE)
}
