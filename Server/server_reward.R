# ============================================================================
# Rewards tab server logic - linked to real test.json data
# ============================================================================
rewards_server <- function(input, output, session, current_project) {

  # Active sort column
  sort_by <- reactiveVal("revenue")

  # Get rewards for the current project from parsed data
  rewards_data <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)

    pid_key <- as.character(p$project_id)
    rw <- project_rewards[[pid_key]]
    if (is.null(rw) || nrow(rw) == 0) return(NULL)

    # Compute % of total revenue
    total_rev <- sum(rw$revenue)
    rw$percent <- if (total_rev > 0) round(rw$revenue / total_rev * 100, 1) else 0

    # Sort by the active column (descending)
    sort_col <- sort_by()
    rw <- rw[order(rw[[sort_col]], decreasing = TRUE), ]

    rw
  })

  # --- Sort button observers ---
  observeEvent(input$sort_revenue, {
    sort_by("revenue")
    shinyjs::runjs("
      $('.btn-filter').css({'background':'#F3F4F6','color':'#6B7280'});
      $('#sort_revenue').css({'background':'#05CE78','color':'white'});
    ")
  })

  observeEvent(input$sort_backers, {
    sort_by("backers")
    shinyjs::runjs("
      $('.btn-filter').css({'background':'#F3F4F6','color':'#6B7280'});
      $('#sort_backers').css({'background':'#05CE78','color':'white'});
    ")
  })

  observeEvent(input$sort_percent, {
    sort_by("percent")
    shinyjs::runjs("
      $('.btn-filter').css({'background':'#F3F4F6','color':'#6B7280'});
      $('#sort_percent').css({'background':'#05CE78','color':'white'});
    ")
  })

  # --- Top Stats (computed from real data) ---
  output$total_revenue <- renderText({
    rw <- rewards_data()
    p <- current_project()
    if (is.null(rw) || is.null(p)) return("€0")
    total_eur <- convert_to_eur(sum(rw$revenue, na.rm = TRUE), rw$currency_code[1])
    paste0("€", formatC(total_eur, format = "d", big.mark = ","))
  })

  output$revenue_change <- renderText({
    rw <- rewards_data()
    p <- current_project()
    if (is.null(rw) || is.null(p)) return("")
    total_rev <- sum(rw$revenue)
    pledged <- p$pledged_amount
    if (pledged > 0 && total_rev > 0) {
      paste0("~", round(total_rev / pledged * 100), "% of pledged")
    } else {
      ""
    }
  })

  output$avg_per_backer <- renderText({
    rw <- rewards_data()
    p <- current_project()
    if (is.null(rw) || is.null(p)) return("€0")
    total_b <- sum(rw$backers, na.rm = TRUE)
    total_r <- sum(rw$revenue, na.rm = TRUE)
    if (total_b > 0) {
      avg_eur <- convert_to_eur(round(total_r / total_b, 2), rw$currency_code[1])
      paste0("€", formatC(avg_eur, format = "f", digits = 2, big.mark = ","))
    } else {
      "€0"
    }
  })

  output$conversion_rate <- renderText({
    rw <- rewards_data()
    if (is.null(rw)) return("€0")
    avg_eur <- convert_to_eur(mean(rw$price, na.rm = TRUE), rw$currency_code[1])
    paste0("€", formatC(avg_eur, format = "f", digits = 2, big.mark = ","))
  })

  output$conversion_change <- renderText({
    rw <- rewards_data()
    if (is.null(rw) || nrow(rw) == 0) return("")
    best <- rw[which.max(rw$revenue), ]
    paste0("Top: ", best$name)
  })

  # --- Rewards Table ---
  output$rewards_table <- renderUI({
    rw <- rewards_data()

    if (is.null(rw) || nrow(rw) == 0) {
      return(div(style = "text-align: center; padding: 40px; color: #95A5A6;",
                 icon("award", class = "fa-3x", style = "margin-bottom: 15px; opacity: 0.3;"),
                 h3("No rewards data available"),
                 p("This project has no reward tiers.")
      ))
    }

    total_backers <- sum(rw$backers)
    max_revenue <- max(rw$revenue)

    reward_rows <- lapply(1:nrow(rw), function(i) {
      reward <- rw[i, ]

      # Performance label based on rank
      perf <- if (i == 1) "Best" else if (i == 2) "Good" else if (i <= 4) "Average" else "Low"
      perf_colors <- c("Best" = "#05CE78", "Good" = "#667EEA", "Average" = "#F39C12", "Low" = "#E74C3C")

      # Bar width relative to max revenue
      bar_width <- if (max_revenue > 0) round(reward$revenue / max_revenue * 100) else 0

      # Backer share
      backer_share <- if (total_backers > 0) round(reward$backers / total_backers * 100, 1) else 0

      div(
        style = "border: 2px solid #E5E7EB; border-radius: 12px; padding: 20px; margin-bottom: 12px; display: grid; grid-template-columns: 2fr 1fr 1fr 1fr 2fr; gap: 15px; align-items: center; transition: all 0.2s; cursor: pointer;",
        onmouseover = "this.style.borderColor='#F39C12'; this.style.boxShadow='0 4px 12px rgba(243,156,18,0.2)';",
        onmouseout = "this.style.borderColor='#E5E7EB'; this.style.boxShadow='none';",

        # Reward Tier
        div(
          div(style = "font-size: 24px; font-weight: bold; color: #F39C12; margin-bottom: 5px;",
              reward$price_label),
          div(style = "font-size: 14px; color: #6B7280; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 250px;",
              reward$name)
        ),

        # Backers
        div(style = "text-align: center;",
            div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "backers"),
            div(style = "font-size: 22px; font-weight: bold; color: #2C3E50;",
                formatC(reward$backers, format = "d", big.mark = ","))
        ),

        # Revenue
        div(style = "text-align: center;",
            div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "revenue"),
            div(style = "font-size: 22px; font-weight: bold; color: #05CE78;",
                paste0(reward$symbol, formatC(reward$revenue, format = "d", big.mark = ",")))
        ),

        # % of Total
        div(style = "text-align: center;",
            div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "of total"),
            div(style = "font-size: 22px; font-weight: bold; color: #667EEA;",
                paste0(reward$percent, "%"))
        ),

        # Performance Bar
        div(style = "padding: 0 10px;",
            div(style = "width: 100%; height: 8px; background: #E5E7EB; border-radius: 4px; overflow: hidden; margin-bottom: 8px;",
                div(style = sprintf("width: %s%%; height: 100%%; background: linear-gradient(to right, #F39C12, #F59E0B); border-radius: 4px; transition: width 0.3s;", bar_width))
            ),
            div(style = "display: flex; justify-content: space-between; align-items: center;",
                tags$span(style = sprintf("padding: 4px 12px; background: %s; color: white; border-radius: 12px; font-size: 11px; font-weight: 600;", perf_colors[perf]),
                          perf),
                tags$span(style = "font-size: 11px; color: #95A5A6;",
                          paste0(backer_share, "% of backers"))
            )
        )
      )
    })

    tagList(reward_rows)
  })

  # Force rendering even when tab is hidden
  outputOptions(output, "total_revenue",   suspendWhenHidden = FALSE)
  outputOptions(output, "revenue_change",  suspendWhenHidden = FALSE)
  outputOptions(output, "avg_per_backer",  suspendWhenHidden = FALSE)
  outputOptions(output, "conversion_rate", suspendWhenHidden = FALSE)
  outputOptions(output, "conversion_change", suspendWhenHidden = FALSE)
  outputOptions(output, "rewards_table",   suspendWhenHidden = FALSE)
}
