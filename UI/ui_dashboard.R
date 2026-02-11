# ============================================================================
# Project detail content (displayed inline on the home page)
# Modular version - all sub-UI functions defined here
# ============================================================================

# --- Back link + Project Header ---
dashboard_header_ui <- function() {
  tagList(
    # Back link
    fluidRow(
      column(12,
             tags$p(
               style = "color: #95A5A6; font-size: 14px; margin-bottom: 20px;",
               tags$a(
                 icon("arrow-left"), " Back to Projects",
                 href = "#",
                 onclick = "Shiny.setInputValue('goto_home', Math.random(), {priority: 'event'})",
                 style = "color: #667EEA; text-decoration: none; font-weight: 600;"
               ),
               " \u2192 ",
               tags$strong(textOutput("current_project_name", inline = TRUE), style = "color: #2C3E50;")
             )
      )
    ),

    # Project Header
    fluidRow(
      column(12,
             div(class = "project-header",
                 fluidRow(
                   column(2,
                          uiOutput("project_image")
                   ),
                   column(6,
                          div(style = "font-size: 28px; font-weight: bold; color: #2C3E50; margin-bottom: 10px;",
                              textOutput("project_title", inline = TRUE)),
                          div(style = "color: #95A5A6; font-size: 14px; margin-bottom: 15px;",
                              textOutput("project_category_breadcrumb", inline = TRUE)),
                          div(style = "margin-bottom: 15px;",
                              tags$span("Creator: ", style = "color: #95A5A6; font-size: 14px;"),
                              tags$strong(textOutput("project_creator", inline = TRUE), style = "color: #667EEA; font-size: 14px;")
                          ),
                          uiOutput("project_we_love_badge"),
                          uiOutput("project_kickstarter_link")
                   ),
                   column(4,
                          fluidRow(
                            column(6,
                                   div(style = "background: #EEF2FF; border-radius: 12px; padding: 15px; text-align: center;",
                                       div(style = "color: #667EEA; margin-bottom: 8px;", icon("calendar", class = "fa-lg")),
                                       div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 5px;", "Start Date"),
                                       div(style = "font-weight: bold; color: #2C3E50;",
                                           textOutput("project_start_date", inline = TRUE))
                                   )
                            ),
                            column(6,
                                   div(style = "background: #EEF2FF; border-radius: 12px; padding: 15px; text-align: center;",
                                       div(style = "color: #9B59B6; margin-bottom: 8px;", icon("calendar", class = "fa-lg")),
                                       div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 5px;", "End Date"),
                                       div(style = "font-weight: bold; color: #2C3E50;",
                                           textOutput("project_end_date", inline = TRUE))
                                   )
                            )
                          ),
                          div(style = "margin-top: 15px; text-align: center;",
                              div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 8px;", "Status"),
                              uiOutput("project_status_badge")
                          )
                   )
                 )
             )
      )
    )
  )
}

# --- Overview Tab ---
overview_tab_ui <- function() {
  div(id = "content_overview", class = "dash-tab-content active",
      fluidRow(
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("chart-bar", style = "color: #667EEA; margin-right: 10px;"),
                       "Funding Overview"),
                   fluidRow(
                     column(6, plotlyOutput("overview_pie", height = "220px")),
                     column(6,
                            div(class = "mini-stat",
                                div(style = "display: flex; align-items: center; margin-bottom: 5px;",
                                    icon("dollar-sign", style = "color: #667EEA; margin-right: 8px;"),
                                    tags$span("Collected", style = "font-size: 11px; color: #95A5A6; font-weight: 600;")
                                ),
                                div(style = "font-size: 28px; font-weight: bold; color: #667EEA;",
                                    textOutput("project_collected", inline = TRUE))
                            ),
                            div(class = "mini-stat",
                                div(style = "display: flex; align-items: center; margin-bottom: 5px;",
                                    icon("bullseye", style = "color: #2C3E50; margin-right: 8px;"),
                                    tags$span("Goal", style = "font-size: 11px; color: #95A5A6; font-weight: 600;")
                                ),
                                div(style = "font-size: 22px; font-weight: bold; color: #2C3E50;",
                                    textOutput("project_goal", inline = TRUE))
                            ),
                            div(class = "mini-stat",
                                div(style = "display: flex; align-items: center; margin-bottom: 5px;",
                                    icon("users", style = "color: #9B59B6; margin-right: 8px;"),
                                    tags$span("Contributors", style = "font-size: 11px; color: #95A5A6; font-weight: 600;")
                                ),
                                div(style = "font-size: 22px; font-weight: bold; color: #2C3E50;",
                                    textOutput("project_backers", inline = TRUE))
                            )
                     )
                   )
               )
        ),
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title", "Quick Stats"),
                   div(class = "quick-stats-grid",
                       div(class = "quick-stat green",
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 5px;", "Daily Average"),
                           div(style = "font-size: 24px; font-weight: bold; color: #059669;", "+$1,200")
                       ),
                       div(class = "quick-stat blue",
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 5px;", "Days Remaining"),
                           div(style = "font-size: 24px; font-weight: bold; color: #2563EB;", "18")
                       ),
                       div(class = "quick-stat orange",
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 5px;", "Funding Velocity"),
                           div(style = "font-size: 24px; font-weight: bold; color: #F39C12;", "Above Avg")
                       ),
                       div(class = "quick-stat purple",
                           div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 5px;", "Backers Growth"),
                           div(style = "font-size: 24px; font-weight: bold; color: #9B59B6;", "+42 today")
                       )
                   )
               )
        )
      ),
      fluidRow(
        column(12,
               div(class = "chart-container",
                   div(style = "margin-bottom: 20px;",
                       icon("chart-line", style = "color: #667EEA; font-size: 24px; margin-right: 10px; vertical-align: middle;"),
                       tags$span("Funding Progress",
                                 style = "font-size: 28px; font-weight: bold; color: #2C3E50; display: inline; vertical-align: middle;")
                   ),
                   plotlyOutput("main_chart", height = "450px")
               )
        )
      )
  )
}

# --- Placeholder Tabs ---
rewards_tab_ui <- function() {
  div(id = "content_rewards", class = "dash-tab-content",
      div(class = "stat-box",
          div(class = "stat-title",
              icon("award", style = "color: #F39C12; margin-right: 10px;"),
              "Rewards Performance"),
          div(style = "text-align: center; padding: 60px; color: #95A5A6;",
              icon("award", class = "fa-3x", style = "margin-bottom: 20px; opacity: 0.3;"),
              h3("Rewards data coming soon"),
              p("This section will show performance metrics for different reward tiers.")
          )
      )
  )
}

creator_tab_ui <- function() {
  div(id = "content_creator", class = "dash-tab-content",
      div(class = "stat-box",
          div(class = "stat-title",
              icon("user", style = "color: #9B59B6; margin-right: 10px;"),
              "Creator Profile"),
          div(style = "text-align: center; padding: 60px; color: #95A5A6;",
              icon("user", class = "fa-3x", style = "margin-bottom: 20px; opacity: 0.3;"),
              h3("Creator information coming soon"),
              p("This section will show detailed creator statistics and update history.")
          )
      )
  )
}

ai_tab_ui <- function() {
  div(id = "content_ai", class = "dash-tab-content",
      div(class = "stat-box ai-insights",
          div(class = "stat-title",
              icon("bolt", style = "color: #F59E0B; margin-right: 10px;"),
              "AI-Powered Insights"),
          div(style = "text-align: center; padding: 60px; color: rgba(255,255,255,0.7);",
              icon("bolt", class = "fa-3x", style = "margin-bottom: 20px; opacity: 0.3;"),
              h3("AI predictions coming soon"),
              p("This section will show AI-powered success predictions and recommendations.")
          )
      )
  )
}

# --- Main dashboard content assembly ---
dashboard_content_ui <- function() {
  tagList(
    # Project Header (imported)
    dashboard_header_ui(),

    # Navigation Tabs
    fluidRow(
      column(12,
             div(class = "tab-navigation",
                 actionButton("tab_overview",
                              tagList(icon("chart-bar"), " Overview"),
                              class = "nav-tab active",
                              onclick = "Shiny.setInputValue('active_tab', 'overview', {priority: 'event'})"),
                 actionButton("tab_sentiment",
                              tagList(icon("comments"), " Sentiment"),
                              class = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'sentiment', {priority: 'event'})"),
                 actionButton("tab_rewards",
                              tagList(icon("award"), " Rewards"),
                              class = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'rewards', {priority: 'event'})"),
                 actionButton("tab_creator",
                              tagList(icon("user"), " Creator"),
                              class = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'creator', {priority: 'event'})"),
                 actionButton("tab_ai",
                              tagList(icon("bolt"), " AI Insights"),
                              class = "nav-tab",
                              onclick = "Shiny.setInputValue('active_tab', 'ai', {priority: 'event'})")
             )
      )
    ),

    # Tab Content
    fluidRow(
      column(12,
             overview_tab_ui(),
             sentiment_tab_ui(),
             rewards_tab_ui(),
             creator_tab_ui(),
             ai_tab_ui()
      )
    )
  )
}
