# ============================================================================
# Global Analytics server logic
# Source : sample_projects (chargé au démarrage depuis base_traitee dans config.R)
# ============================================================================
analytics_server <- function(input, output, session) {

  # ── Stats globales calculées une seule fois depuis sample_projects ─────────
  global_stats <- reactive({
    sp <- sample_projects

    total_proj    <- nrow(sp)
    n_success     <- sum(sp$status == "Successful", na.rm = TRUE)
    success_pct   <- if (total_proj > 0) round(n_success / total_proj * 100, 1) else 0
    total_raised  <- sum(mapply(convert_to_eur, sp$pledged_amount, sp$goal_currency), na.rm = TRUE)
    total_backers <- sum(sp$backers_count, na.rm = TRUE)

    list(total_proj    = total_proj,
         success_pct   = success_pct,
         total_raised  = total_raised,
         total_backers = total_backers)
  })

  # ── Formatage compact : 1500000 → "€1.5M", 3200 → "€3.2K" ───────────────
  fmt_eur <- function(x) {
    if (is.na(x) || x == 0) return("€0")
    if (x >= 1e9)  return(paste0("€", round(x / 1e9, 1), "B"))
    if (x >= 1e6)  return(paste0("€", round(x / 1e6, 1), "M"))
    if (x >= 1e3)  return(paste0("€", round(x / 1e3,  1), "K"))
    paste0("€", formatC(round(x), format = "d", big.mark = ","))
  }

  fmt_num <- function(x) {
    if (is.na(x) || x == 0) return("0")
    if (x >= 1e6)  return(paste0(round(x / 1e6, 1), "M"))
    if (x >= 1e3)  return(paste0(round(x / 1e3,  1), "K"))
    formatC(round(x), format = "d", big.mark = ",")
  }

  # ── Stat cards ─────────────────────────────────────────────────────────────
  output$total_projects <- renderText({
    formatC(global_stats()$total_proj, format = "d", big.mark = ",")
  })

  output$success_rate <- renderText({
    paste0(global_stats()$success_pct, "%")
  })

  output$total_raised <- renderText({
    fmt_eur(global_stats()$total_raised)
  })

  output$total_backers <- renderText({
    fmt_num(global_stats()$total_backers)
  })
  
  # ============================================================================
  # SUCCESS RATE BY CATEGORY - HORIZONTAL BAR CHART
  # ============================================================================
  
  output$success_by_category <- renderPlotly({
    sp <- sample_projects
    sp <- sp[!is.na(sp$category_sub) & nchar(trimws(sp$category_sub)) > 0, ]

    # Calcul du taux de succès par catégorie parente (projets terminés uniquement)
    finished <- sp[sp$status %in% c("Successful", "Failed"), ]
    if (nrow(finished) == 0) return(plotly_empty())

    cat_stats <- do.call(rbind, lapply(split(finished, finished$category_sub), function(df) {
      data.frame(
        category     = df$category_sub[1],
        success_rate = round(sum(df$status == "Successful") / nrow(df) * 100, 1),
        n_projects   = nrow(df),
        stringsAsFactors = FALSE
      )
    }))

    cat_stats <- cat_stats[order(cat_stats$success_rate, decreasing = TRUE), ]

    cat_stats$color <- ifelse(cat_stats$success_rate >= 60, "#05CE78",
                       ifelse(cat_stats$success_rate >= 40, "#F39C12", "#E74C3C"))

    plot_ly(cat_stats,
            y          = ~reorder(category, success_rate),
            x          = ~success_rate,
            type       = 'bar',
            orientation = 'h',
            marker     = list(color = ~color),
            text       = ~paste0(success_rate, "%"),
            textposition = 'outside',
            hoverinfo  = 'text',
            hovertext  = ~paste0(category, ": ", success_rate, "% (", n_projects, " projects)")
    ) %>%
      layout(
        xaxis = list(title = "", range = c(0, 110), showgrid = TRUE,
                     gridcolor = '#E5E7EB', zeroline = FALSE),
        yaxis = list(title = "", showgrid = FALSE),
        margin = list(l = 120, r = 60, t = 20, b = 40),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor  = 'rgba(0,0,0,0)',
        showlegend    = FALSE
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ============================================================================
  # PROJECTS BY COUNTRY - PIE CHART
  # ============================================================================
  
  output$projects_by_country <- renderPlotly({
    sp <- sample_projects
    sp <- sp[!is.na(sp$country) & nchar(trimws(sp$country)) > 0, ]

    counts <- sort(table(sp$country), decreasing = TRUE)
    total  <- sum(counts)

    # Sépare les pays avec >= 3 projets des autres
    top          <- counts[counts >= 3]
    others_vec   <- counts[counts < 3]
    others_total <- sum(others_vec)

    country_data <- data.frame(
      country    = names(top),
      projects   = as.integer(top),
      percentage = round(as.integer(top) / total * 100, 1),
      hover      = paste0(names(top), ": ", as.integer(top), " projects"),
      stringsAsFactors = FALSE
    )

    if (others_total > 0) {
      others_label <- paste(names(others_vec), collapse = ", ")
      country_data <- rbind(country_data, data.frame(
        country    = "Others",
        projects   = as.integer(others_total),
        percentage = round(others_total / total * 100, 1),
        hover      = paste0("Others (", others_total, " projects): ", others_label),
        stringsAsFactors = FALSE
      ))
    }

    colors_pie <- c('#667EEA', '#5B6AD4', '#F39C12', '#05CE78', '#E74C3C',
                    '#3498DB', '#9B59B6', '#1ABC9C', '#E67E22', '#6B7280')

    plot_ly(country_data,
            labels       = ~country,
            values       = ~projects,
            type         = 'pie',
            marker       = list(colors = colors_pie[seq_len(nrow(country_data))],
                                line   = list(color = '#FFFFFF', width = 2)),
            textinfo     = 'percent',
            textposition = 'inside',
            insidetextorientation = 'radial',
            hoverinfo    = 'text',
            hovertext    = ~hover,
            domain       = list(x = c(0, 0.72), y = c(0, 1))
    ) %>%
      layout(
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor  = 'rgba(0,0,0,0)',
        margin        = list(l = 10, r = 10, t = 20, b = 20),
        showlegend    = TRUE,
        legend        = list(
          orientation  = 'v',
          x            = 0.75,
          y            = 0.5,
          font         = list(size = 13),
          tracegroupgap = 6
        )
      ) %>%
      config(displayModeBar = FALSE)
  })
  

}