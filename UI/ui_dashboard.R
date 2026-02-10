# ============================================================================
# Project detail content (displayed inline on the home page)
# ============================================================================
dashboard_content_ui <- function() {
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
               " → ",
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
    ),

    # Stats Cards
    fluidRow(
      column(6,
             div(id = "overview-card", class = "stat-box",
                 onclick = "Shiny.setInputValue('view_mode', 'overview', {priority: 'event'})",
                 div(class = "stat-title", "Overview"),
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
             div(id = "sentiment-card", class = "stat-box",
                 onclick = "Shiny.setInputValue('view_mode', 'sentiment', {priority: 'event'})",
                 div(class = "stat-title", "Feedback"),
                 plotlyOutput("sentiment_donut", height = "220px"),
                 div(class = "feedback-grid",
                     div(class = "feedback-item positive",
                         div(style = "width: 16px; height: 16px; border-radius: 50%; background: #86EFAC; margin: 0 auto 8px;"),
                         div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Positive"),
                         div(style = "font-size: 20px; font-weight: bold; color: #059669;", "63%")
                     ),
                     div(class = "feedback-item neutral",
                         div(style = "width: 16px; height: 16px; border-radius: 50%; background: #93C5FD; margin: 0 auto 8px;"),
                         div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Neutral"),
                         div(style = "font-size: 20px; font-weight: bold; color: #2563EB;", "22%")
                     ),
                     div(class = "feedback-item negative",
                         div(style = "width: 16px; height: 16px; border-radius: 50%; background: #FCA5A5; margin: 0 auto 8px;"),
                         div(style = "font-size: 11px; color: #95A5A6; margin-bottom: 3px;", "Negative"),
                         div(style = "font-size: 20px; font-weight: bold; color: #DC2626;", "15%")
                     )
                 )
             )
      )
    ),

    # Chart Section
    fluidRow(
      column(12,
             div(class = "chart-container",
                 fluidRow(
                   column(8,
                          div(
                            icon("chart-line", style = "color: #667EEA; font-size: 24px; margin-right: 10px; vertical-align: middle;"),
                            tags$span(textOutput("chart_title", inline = TRUE),
                                      style = "font-size: 28px; font-weight: bold; color: #2C3E50; display: inline; vertical-align: middle;")
                          )
                   ),
                   column(4,
                          div(style = "text-align: right;",
                              actionButton("btn_overview", "Overview", class = "btn-view active"),
                              actionButton("btn_sentiment", "Sentiment", class = "btn-view")
                          )
                   )
                 ),
                 hr(style = "margin: 20px 0;"),
                 plotlyOutput("main_chart", height = "450px")
             )
      )
    )
  )
}
