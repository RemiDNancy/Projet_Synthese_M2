# ============================================================================
# server_reward.R
# Logique serveur de l'onglet Rewards
# Source : kickstarter.REWARD + REWARD_EVOLUTION (chargé dans config.R)
# ============================================================================
rewards_server <- function(input, output, session, current_project) {

  # ── Colonne de tri active (par défaut : revenue) ──────────────────────────
  sort_by <- reactiveVal("revenue")

  # Couleurs du badge "Revenue vs Avg Tier" — défini une fois, réutilisé par ligne
  perf_colors <- c(
    "Above Average" = "#05CE78",
    "Average"       = "#F39C12",
    "Below Average" = "#E74C3C",
    "No Data"       = "#95A5A6"
  )

  # Helper : réinitialise tous les boutons de tri puis active celui cliqué
  reset_sort_buttons <- function(active_id) {
    shinyjs::runjs(sprintf("
      $('.btn-filter').css({'background':'#F3F4F6','color':'#6B7280'});
      $('#%s').css({'background':'#05CE78','color':'white'});
    ", active_id))
  }

  # Helper : badge coloré (utilisé dans les panneaux Market Intelligence)
  badge <- function(label, color) {
    div(style = paste0(
      "display: inline-block; padding: 4px 12px; border-radius: 20px; ",
      "font-size: 11px; font-weight: 700; margin-bottom: 12px; ",
      "background: ", color, "22; color: ", color, ";"
    ), label)
  }

  # ── Données rewards du projet actif ──────────────────────────────────────
  # Lit project_rewards (chargé au démarrage), ajoute les colonnes de %,
  # puis trie selon la colonne active
  rewards_data <- reactive({
    p <- current_project()
    if (is.null(p)) return(NULL)

    rw <- project_rewards[[as.character(p$project_id)]]
    if (is.null(rw) || nrow(rw) == 0) return(NULL)

    # % de chaque palier sur le total des revenus rewards
    total_rev          <- sum(rw$revenue)
    rw$percent_rewards <- if (total_rev > 0) round(rw$revenue / total_rev * 100, 1) else 0

    # % de chaque palier sur le montant total collecté par le projet
    pledged               <- p$pledged_amount
    rw$percent_collected  <- if (!is.na(pledged) && pledged > 0) round(rw$revenue / pledged * 100, 1) else 0

    rw[order(rw[[sort_by()]], decreasing = TRUE), ]
  })

  # ── Observateurs des boutons de tri ──────────────────────────────────────
  observeEvent(input$sort_revenue, { sort_by("revenue");        reset_sort_buttons("sort_revenue") })
  observeEvent(input$sort_backers, { sort_by("backers");        reset_sort_buttons("sort_backers") })
  observeEvent(input$sort_percent, { sort_by("percent_rewards"); reset_sort_buttons("sort_percent") })

  # ── Stat cards (ligne du haut) ────────────────────────────────────────────

  # Nombre total de paliers de récompense
  output$reward_count <- renderText({
    p <- current_project()
    if (is.null(p)) return("0")
    rw <- project_rewards[[as.character(p$project_id)]]
    if (is.null(rw)) return("0")
    as.character(nrow(rw))
  })

  # Somme des revenus de tous les paliers, convertie en EUR
  output$total_revenue <- renderText({
    rw <- rewards_data()
    p  <- current_project()
    if (is.null(rw) || is.null(p)) return("€0")
    paste0("€", formatC(convert_to_eur(sum(rw$revenue, na.rm = TRUE), rw$currency_code[1]),
                         format = "d", big.mark = ","))
  })

  # Part des revenus rewards sur le montant collecté total
  output$revenue_change <- renderText({
    rw <- rewards_data()
    p  <- current_project()
    if (is.null(rw) || is.null(p)) return("")
    pledged <- p$pledged_amount
    total   <- sum(rw$revenue)
    if (pledged > 0 && total > 0) paste0("~", round(total / pledged * 100), "% of pledged") else ""
  })

  # Revenu moyen par backer (tous paliers confondus), en EUR
  output$avg_per_backer <- renderText({
    rw <- rewards_data()
    p  <- current_project()
    if (is.null(rw) || is.null(p)) return("€0")
    total_b <- sum(rw$backers,  na.rm = TRUE)
    total_r <- sum(rw$revenue,  na.rm = TRUE)
    if (total_b == 0) return("€0")
    paste0("€", formatC(convert_to_eur(round(total_r / total_b, 2), rw$currency_code[1]),
                         format = "f", digits = 2, big.mark = ","))
  })

  # Prix moyen d'un palier, en EUR
  output$conversion_rate <- renderText({
    rw <- rewards_data()
    if (is.null(rw)) return("€0")
    paste0("€", formatC(convert_to_eur(mean(rw$price, na.rm = TRUE), rw$currency_code[1]),
                         format = "f", digits = 2, big.mark = ","))
  })

  # Nom du palier générant le plus de revenus
  output$conversion_change <- renderText({
    rw <- rewards_data()
    if (is.null(rw) || nrow(rw) == 0) return("")
    paste0("Top: ", rw$name[which.max(rw$revenue)])
  })

  # ── Tableau des paliers de récompense ─────────────────────────────────────
  # Chaque ligne affiche : prix EUR | backers | revenue EUR |
  #   % collecté | % revenue | badge performance + barre
  output$rewards_table <- renderUI({
    rw <- rewards_data()

    if (is.null(rw) || nrow(rw) == 0) {
      return(div(style = "text-align: center; padding: 40px; color: #95A5A6;",
                 icon("award", class = "fa-3x", style = "margin-bottom: 15px; opacity: 0.3;"),
                 h3("No rewards data available"),
                 p("This project has no reward tiers.")))
    }

    total_backers <- sum(rw$backers)
    max_revenue   <- max(rw$revenue)
    avg_revenue   <- mean(rw$revenue)

    tagList(lapply(seq_len(nrow(rw)), function(i) {
      reward <- rw[i, ]

      # Étiquette performance : compare le revenu du palier à la moyenne des paliers
      perf <- if (avg_revenue == 0)          "No Data"
              else if (reward$revenue > avg_revenue * 1.2) "Above Average"
              else if (reward$revenue < avg_revenue * 0.8) "Below Average"
              else                                          "Average"

      bar_width    <- if (max_revenue   > 0) round(reward$revenue  / max_revenue   * 100) else 0
      backer_share <- if (total_backers > 0) round(reward$backers  / total_backers * 100, 1) else 0

      div(
        style       = "border: 2px solid #E5E7EB; border-radius: 12px; padding: 20px; margin-bottom: 12px; display: grid; grid-template-columns: 2fr 1fr 1fr 1fr 1fr 2fr; gap: 15px; align-items: center; transition: all 0.2s; cursor: pointer;",
        onmouseover = "this.style.borderColor='#F39C12'; this.style.boxShadow='0 4px 12px rgba(243,156,18,0.2)';",
        onmouseout  = "this.style.borderColor='#E5E7EB'; this.style.boxShadow='none';",

        # Prix et nom du palier
        div(
          div(style = "font-size: 24px; font-weight: bold; color: #F39C12; margin-bottom: 5px;",
              paste0("€", formatC(convert_to_eur(reward$price, reward$currency_code),
                                  format = "f", digits = 0, big.mark = ","))),
          div(style = "font-size: 14px; color: #6B7280; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 250px;",
              reward$name)
        ),

        # Nombre de backers
        div(style = "text-align: center;",
            div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "backers"),
            div(style = "font-size: 22px; font-weight: bold; color: #2C3E50;",
                formatC(reward$backers, format = "d", big.mark = ","))
        ),

        # Revenu total du palier en EUR
        div(style = "text-align: center;",
            div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "revenue"),
            div(style = "font-size: 22px; font-weight: bold; color: #05CE78;",
                paste0("€", formatC(convert_to_eur(reward$revenue, reward$currency_code),
                                    format = "d", big.mark = ",")))
        ),

        # % sur le montant collecté total du projet
        div(style = "text-align: center;",
            div(style = "font-size: 22px; font-weight: bold; color: #9B59B6;",
                paste0(reward$percent_collected, "%"))
        ),

        # % sur le total des revenus rewards du projet
        div(style = "text-align: center;",
            div(style = "font-size: 22px; font-weight: bold; color: #667EEA;",
                paste0(reward$percent_rewards, "%"))
        ),

        # Barre de progression + badge performance
        div(style = "padding: 0 10px;",
            div(style = "width: 100%; height: 8px; background: #E5E7EB; border-radius: 4px; overflow: hidden; margin-bottom: 8px;",
                div(style = sprintf("width: %s%%; height: 100%%; background: linear-gradient(to right, #F39C12, #F59E0B); border-radius: 4px; transition: width 0.3s;", bar_width))
            ),
            div(style = "display: flex; justify-content: space-between; align-items: center;",
                tags$span(style = sprintf("padding: 4px 12px; background: %s; color: white; border-radius: 12px; font-size: 11px; font-weight: 600;",
                                          perf_colors[perf]), perf),
                tags$span(style = "font-size: 11px; color: #95A5A6;",
                          paste0(backer_share, "% of backers"))
            )
        )
      )
    }))
  })

  # ── Market Intelligence : comparaison au marché global ────────────────────
  # 3 panneaux : Price Positioning | Nombre de Tiers | Backer Sweet Spot
  # Source : global_reward_benchmarks (calculé au démarrage dans config.R)
  output$reward_benchmarks <- renderUI({
    p  <- current_project()
    gb <- global_reward_benchmarks

    if (is.null(p) || is.null(gb) || is.null(gb$all_rewards) || nrow(gb$all_rewards) == 0)
      return(div(style = "color: #95A5A6; padding: 20px; text-align: center;",
                 "No benchmark data available."))

    rw_raw <- project_rewards[[as.character(p$project_id)]]

    # Prix EUR des paliers du projet (filtrés : positifs et non-NA)
    proj_prices_eur <- if (!is.null(rw_raw) && nrow(rw_raw) > 0)
      mapply(convert_to_eur, rw_raw$price, rw_raw$currency_code)
    else numeric(0)
    proj_prices_eur <- proj_prices_eur[!is.na(proj_prices_eur) & proj_prices_eur > 0]

    # ── 1. Price Positioning ──────────────────────────────────────────────
    # Percentile moyen des prix du projet dans la distribution globale
    all_prices    <- gb$all_rewards$price_eur[!is.na(gb$all_rewards$price_eur) & gb$all_rewards$price_eur > 0]
    global_median <- round(median(all_prices))

    if (length(proj_prices_eur) > 0 && length(all_prices) > 0) {
      percentiles  <- sapply(proj_prices_eur, function(pr) round(sum(all_prices <= pr) / length(all_prices) * 100))
      avg_pct      <- round(mean(percentiles))
      above_median <- sum(proj_prices_eur > global_median)
      total_tiers  <- length(proj_prices_eur)
    } else {
      avg_pct <- 50; above_median <- 0; total_tiers <- 0
    }

    price_label  <- if (avg_pct >= 75) "Premium Pricing" else if (avg_pct >= 50) "Mid-Range" else if (avg_pct >= 25) "Accessible" else "Budget"
    price_color  <- if (avg_pct >= 75) "#9B59B6"         else if (avg_pct >= 50) "#667EEA"   else if (avg_pct >= 25) "#05CE78"    else "#F39C12"
    price_detail <- if (total_tiers > 0)
      paste0(above_median, " of ", total_tiers, " tiers priced above the global median")
    else "No pricing data"

    # ── 2. Tier Count vs Category Average ────────────────────────────────
    # Compare le nombre de paliers du projet à la moyenne de sa catégorie
    n_tiers    <- if (!is.null(rw_raw)) nrow(rw_raw) else 0
    cat_counts <- gb$tier_counts$n_tiers[gb$tier_counts$category == p$category]
    cat_avg    <- if (length(cat_counts) >= 2) round(mean(cat_counts, na.rm = TRUE), 1) else round(mean(gb$tier_counts$n_tiers, na.rm = TRUE), 1)
    cat_label  <- if (length(cat_counts) >= 2) p$category else "all categories"
    tier_diff  <- n_tiers - cat_avg
    tier_label <- if (tier_diff >  1.5) "More than average" else if (tier_diff < -1.5) "Fewer than average" else "On par with average"
    tier_color <- if (tier_diff >  1.5) "#05CE78"           else if (tier_diff < -1.5) "#E74C3C"            else "#F39C12"
    tier_sign  <- if (tier_diff >= 0) paste0("+", round(tier_diff, 1)) else as.character(round(tier_diff, 1))

    # ── 3. Backer Sweet Spot ─────────────────────────────────────────────
    # Tranche de prix attirant le plus de backers sur l'ensemble des projets
    price_ranges <- list(
      "< €10"      = c(0,   10),
      "€10 – €25"  = c(10,  25),
      "€25 – €75"  = c(25,  75),
      "€75 – €150" = c(75,  150),
      "> €150"     = c(150, Inf)
    )
    range_backers <- sapply(price_ranges, function(r) {
      mask <- !is.na(gb$all_rewards$price_eur) & !is.na(gb$all_rewards$backers) &
              gb$all_rewards$price_eur >= r[1] & gb$all_rewards$price_eur < r[2]
      sum(gb$all_rewards$backers[mask], na.rm = TRUE)
    })
    sweet_name  <- names(which.max(range_backers))
    sweet_range <- price_ranges[[sweet_name]]
    sweet_pct   <- round(range_backers[sweet_name] / sum(range_backers) * 100)
    tiers_in_ss <- if (length(proj_prices_eur) > 0)
      sum(proj_prices_eur >= sweet_range[1] & proj_prices_eur < sweet_range[2])
    else 0
    covered     <- tiers_in_ss > 0
    sweet_color <- if (covered) "#05CE78" else "#E74C3C"
    sweet_icon  <- if (covered) "check-circle" else "times-circle"
    sweet_msg   <- if (covered)
      paste0(tiers_in_ss, if (tiers_in_ss == 1) " tier covers" else " tiers cover", " this range")
    else "No tier in this range — consider adding one"

    # ── Rendu des 3 panneaux ──────────────────────────────────────────────
    div(style = "display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 20px; margin-top: 15px;",

      # Panneau 1 – Price Positioning
      div(style = "background: #F9FAFB; border-radius: 12px; padding: 20px; border-left: 4px solid #667EEA;",
        div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 14px;",
            icon("tag", style = "color: #667EEA;"),
            tags$span("Price Positioning", style = "font-size: 13px; font-weight: 700; color: #2C3E50;")),
        div(style = paste0("font-size: 32px; font-weight: bold; color: ", price_color, "; margin-bottom: 6px;"),
            paste0("Top ", 100 - avg_pct, "%")),
        badge(price_label, price_color),
        div(style = "font-size: 12px; color: #6B7280; margin-bottom: 4px;", price_detail),
        div(style = "font-size: 11px; color: #95A5A6;",
            paste0("Global median reward price: €", formatC(global_median, format = "d", big.mark = ",")))
      ),

      # Panneau 2 – Tier Count
      div(style = "background: #F9FAFB; border-radius: 12px; padding: 20px; border-left: 4px solid #F39C12;",
        div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 14px;",
            icon("layer-group", style = "color: #F39C12;"),
            tags$span("Number of Tiers", style = "font-size: 13px; font-weight: 700; color: #2C3E50;")),
        div(style = "display: flex; align-items: baseline; gap: 10px; margin-bottom: 6px;",
            div(style = paste0("font-size: 40px; font-weight: bold; color: ", tier_color, ";"), n_tiers),
            div(style = "font-size: 13px; color: #95A5A6;", "tiers")),
        badge(tier_label, tier_color),
        div(style = "font-size: 12px; color: #6B7280; margin-bottom: 4px;",
            paste0("Category avg (", cat_label, "): ", cat_avg, " tiers")),
        div(style = paste0("font-size: 12px; font-weight: 600; color: ", tier_color, ";"),
            paste0(tier_sign, " vs average"))
      ),

      # Panneau 3 – Backer Sweet Spot
      div(style = "background: #F9FAFB; border-radius: 12px; padding: 20px; border-left: 4px solid #05CE78;",
        div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 14px;",
            icon("crosshairs", style = "color: #05CE78;"),
            tags$span("Backer Sweet Spot", style = "font-size: 13px; font-weight: 700; color: #2C3E50;")),
        div(style = "font-size: 28px; font-weight: bold; color: #2C3E50; margin-bottom: 4px;", sweet_name),
        div(style = "font-size: 12px; color: #95A5A6; margin-bottom: 14px;",
            paste0("attracts ", sweet_pct, "% of all backers globally")),
        div(style = "display: flex; align-items: flex-start; gap: 8px;",
            icon(sweet_icon, style = paste0("color: ", sweet_color, "; margin-top: 2px;")),
            div(style = paste0("font-size: 12px; font-weight: 600; color: ", sweet_color, ";"), sweet_msg))
      )
    )
  })

  # ── Forcer le rendu même quand l'onglet est masqué ────────────────────────
  outputOptions(output, "reward_count",       suspendWhenHidden = FALSE)
  outputOptions(output, "total_revenue",      suspendWhenHidden = FALSE)
  outputOptions(output, "revenue_change",     suspendWhenHidden = FALSE)
  outputOptions(output, "avg_per_backer",     suspendWhenHidden = FALSE)
  outputOptions(output, "conversion_rate",    suspendWhenHidden = FALSE)
  outputOptions(output, "conversion_change",  suspendWhenHidden = FALSE)
  outputOptions(output, "rewards_table",      suspendWhenHidden = FALSE)
  outputOptions(output, "reward_benchmarks",  suspendWhenHidden = FALSE)
}
