# ============================================================================
# Global Analytics UI - Overview of all crowdfunding projects
# ============================================================================

analytics_tab_ui <- function() {
  tabItem(
    tabName = "analytics",
    
    # Page Header
    div(class = "analytics-header",
        div(class = "analytics-header-icon",
            tags$img(src = "global_analytics.png", style = "width: 70px; height: 70px; object-fit: contain;")
        ),
        div(class = "analytics-header-text",
            h1("Global Analytics", style = "margin: 0; font-size: 36px; font-weight: bold; color: white;"),
            p("Overview of all crowdfunding projects", 
              style = "margin: 5px 0 0 0; font-size: 16px; color: rgba(255,255,255,0.9);")
        )
    ),
    
    # ============================================================================
    # TOP SECTION - KEY METRICS (4 CARDS)
    # ============================================================================
    fluidRow(
      # Total Projects
      column(3,
             div(class = "analytics-stat-card",
                 div(class = "analytics-stat-icon purple",
                     icon("layer-group", class = "fa-2x")
                 ),
                 div(class = "analytics-stat-content",
                     div(class = "analytics-stat-label", "Total Projects"),
                     div(class = "analytics-stat-value", 
                         textOutput("total_projects", inline = TRUE))
                 )
             )
      ),
      
      # Success Rate
      column(3,
             div(class = "analytics-stat-card",
                 div(class = "analytics-stat-icon green",
                     icon("trophy", class = "fa-2x")
                 ),
                 div(class = "analytics-stat-content",
                     div(class = "analytics-stat-label", "Success Rate"),
                     div(class = "analytics-stat-value", 
                         textOutput("success_rate", inline = TRUE))
                 )
             )
      ),
      
      # Total Raised
      column(3,
             div(class = "analytics-stat-card",
                 div(class = "analytics-stat-icon blue",
                     icon("euro-sign", class = "fa-2x")
                 ),
                 div(class = "analytics-stat-content",
                     div(class = "analytics-stat-label", "Total Raised"),
                     div(class = "analytics-stat-value", 
                         textOutput("total_raised", inline = TRUE))
                 )
             )
      ),
      
      # Total Backers
      column(3,
             div(class = "analytics-stat-card",
                 div(class = "analytics-stat-icon orange",
                     icon("users", class = "fa-2x")
                 ),
                 div(class = "analytics-stat-content",
                     div(class = "analytics-stat-label", "Total Backers"),
                     div(class = "analytics-stat-value", 
                         textOutput("total_backers", inline = TRUE))
                 )
             )
      )
    ),
    
    # ============================================================================
    # MIDDLE SECTION - TWO CHARTS
    # ============================================================================
    fluidRow(
      # Left: Success Rate by Category
      column(6,
             div(class = "analytics-chart-box",
                 div(class = "analytics-chart-header",
                     icon("chart-bar", style = "color: #667EEA; margin-right: 10px;"),
                     tags$span("Success Rate by Category", 
                               style = "font-size: 20px; font-weight: bold; color: #2C3E50;")
                 ),
                 plotlyOutput("success_by_category", height = "600px")
             )
      ),
      
      # Right: Projects by Country
      column(6,
             div(class = "analytics-chart-box",
                 div(class = "analytics-chart-header",
                     icon("globe-americas", style = "color: #667EEA; margin-right: 10px;"),
                     tags$span("Projects by Country", 
                               style = "font-size: 20px; font-weight: bold; color: #2C3E50;")
                 ),
                 plotlyOutput("projects_by_country", height = "700px")
             )
      )
    ),
    
  )
}