# ============================================================================
# Rewards tab UI
# ============================================================================
rewards_tab_ui <- function() {
  div(id = "content_rewards", class = "dash-tab-content",
      
      # Top Stats Cards
      fluidRow(
        column(3,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("award", style = "color: #667EEA;"),
                       tags$span("Total Rewards", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("reward_count", inline = TRUE)),
                   div(style = "font-size: 11px; color: #95A5A6; margin-top: 5px;",
                       "reward tiers")
               )
        ),
        column(3,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("euro-sign", style = "color: #05CE78;"),
                       tags$span("Total Revenue", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("total_revenue", inline = TRUE)),
                   div(style = "font-size: 11px; color: #05CE78; margin-top: 5px;",
                       textOutput("revenue_change", inline = TRUE))
               )
        ),
        column(3,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("percent", style = "color: #F39C12;"),
                       tags$span("Avg per Backer", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("avg_per_backer", inline = TRUE)),
               )
        ),
        column(3,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("chart-line", style = "color: #9B59B6;"),
                       tags$span("Avg Reward Price", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("conversion_rate", inline = TRUE)),
                   div(style = "font-size: 11px; color: #05CE78; margin-top: 5px;",
                       textOutput("conversion_change", inline = TRUE))
               )
        )
      ),
      
      # Rewards Table (sort buttons integrated in header)
      fluidRow(
        column(12,
               div(class = "stat-box",

                   # Title row + sort buttons in top-right corner
                   div(style = "display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px;",
                       div(style = "display: flex; align-items: center;",
                           icon("award", style = "color: #F39C12; margin-right: 10px; font-size: 16px;"),
                           tags$span("Rewards Performance", style = "font-size: 16px; font-weight: 700; color: #2C3E50;")
                       ),
                       div(style = "display: flex; align-items: center; gap: 6px;",
                           tags$span("Sort by:", style = "font-size: 11px; color: #95A5A6; font-weight: 600; margin-right: 4px;"),
                           actionButton("sort_revenue",
                                        tagList(icon("euro-sign"), " Revenue"),
                                        class = "btn-filter active",
                                        style = "padding: 6px 12px; border-radius: 20px; border: none; font-size: 11px; font-weight: 600; cursor: pointer; background: #05CE78; color: white;"),
                           actionButton("sort_backers",
                                        tagList(icon("users"), " Backers"),
                                        class = "btn-filter",
                                        style = "padding: 6px 12px; border-radius: 20px; border: none; font-size: 11px; font-weight: 600; cursor: pointer; background: #F3F4F6; color: #6B7280;"),
                           actionButton("sort_percent",
                                        tagList(icon("percent"), " % Share"),
                                        class = "btn-filter",
                                        style = "padding: 6px 12px; border-radius: 20px; border: none; font-size: 11px; font-weight: 600; cursor: pointer; background: #F3F4F6; color: #6B7280;")
                       )
                   ),

                   # Table Header
                   div(style = "background: #F9FAFB; border-radius: 8px; padding: 12px 20px; margin-bottom: 12px; display: grid; grid-template-columns: 2fr 1fr 1fr 1fr 1fr 2fr; gap: 15px; font-weight: 600; color: #6B7280; font-size: 13px;",
                       div("Reward Tier"),
                       div("Backers", style = "text-align: center;"),
                       div("Total Revenue", style = "text-align: center;"),
                       div("% of Collected Amount", style = "text-align: center;"),
                       div("% of Total Revenue", style = "text-align: center;"),
                       div("Revenue vs Avg Tier", style = "text-align: center;")
                   ),

                   # Table Rows
                   uiOutput("rewards_table")
               )
        )
      ),

      # Market Intelligence
      fluidRow(
        column(12,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("globe", style = "color: #667EEA; margin-right: 10px;"),
                       "How Your Rewards Compare To The Market"),
                   uiOutput("reward_benchmarks")
               )
        )
      )
  )
}