# ============================================================================
# Rewards tab UI
# ============================================================================
rewards_tab_ui <- function() {
  div(id = "content_rewards", class = "dash-tab-content",
      
      # Top Stats Cards
      fluidRow(
        column(4,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("dollar-sign", style = "color: #05CE78;"),
                       tags$span("Total Revenue", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("total_revenue", inline = TRUE)),
                   div(style = "font-size: 11px; color: #05CE78; margin-top: 5px;",
                       textOutput("revenue_change", inline = TRUE))
               )
        ),
        column(4,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("percent", style = "color: #F39C12;"),
                       tags$span("Avg per Backer", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("avg_per_backer", inline = TRUE)),
                   div(style = "font-size: 11px; color: #667EEA; margin-top: 5px;",
                       "Industry: $19.00")
               )
        ),
        column(4,
               div(class = "stat-box",
                   div(style = "display: flex; align-items: center; gap: 8px; margin-bottom: 8px;",
                       icon("trending-up", style = "color: #9B59B6;"),
                       tags$span("Avg Reward Price", style = "font-size: 12px; color: #95A5A6; font-weight: 600;")
                   ),
                   div(style = "font-size: 32px; font-weight: bold; color: #2C3E50;",
                       textOutput("conversion_rate", inline = TRUE)),
                   div(style = "font-size: 11px; color: #05CE78; margin-top: 5px;",
                       textOutput("conversion_change", inline = TRUE))
               )
        )
      ),
      
      # Filter Buttons
      fluidRow(
        column(12,
               div(style = "background: white; border-radius: 12px; padding: 15px; margin-bottom: 20px; box-shadow: 0 2px 8px rgba(0,0,0,0.08);",
                   div(style = "font-size: 13px; color: #95A5A6; margin-bottom: 10px; font-weight: 600;", "Sort by:"),
                   div(style = "display: flex; gap: 10px;",
                       actionButton("sort_revenue", "Revenue", 
                                    class = "btn-filter active",
                                    style = "padding: 8px 16px; border-radius: 8px; border: none; font-weight: 600; cursor: pointer; background: #05CE78; color: white;"),
                       actionButton("sort_backers", "Backers",
                                    class = "btn-filter",
                                    style = "padding: 8px 16px; border-radius: 8px; border: none; font-weight: 600; cursor: pointer; background: #F3F4F6; color: #6B7280;"),
                       actionButton("sort_percent", "% of Total",
                                    class = "btn-filter",
                                    style = "padding: 8px 16px; border-radius: 8px; border: none; font-weight: 600; cursor: pointer; background: #F3F4F6; color: #6B7280;")
                   )
               )
        )
      ),
      
      # Rewards Table
      fluidRow(
        column(12,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("award", style = "color: #F39C12; margin-right: 10px;"),
                       "Rewards Performance"),
                   
                   # Table Header
                   div(style = "background: #F9FAFB; border-radius: 8px; padding: 12px 20px; margin-bottom: 12px; display: grid; grid-template-columns: 2fr 1fr 1fr 1fr 2fr; gap: 15px; font-weight: 600; color: #6B7280; font-size: 13px;",
                       div("Reward Tier"),
                       div("Backers", style = "text-align: center;"),
                       div("Revenue", style = "text-align: center;"),
                       div("% of Total", style = "text-align: center;"),
                       div("Performance", style = "text-align: center;")
                   ),
                   
                   # Table Rows
                   uiOutput("rewards_table")
               )
        )
      )
  )
}