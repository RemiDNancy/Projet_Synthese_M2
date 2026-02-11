# ============================================================================
# Dashboard server logic (project detail view)
# ============================================================================
dashboard_server <- function(input, output, session, selected_project_id) {
  
  # Helper: get the currently selected project row
  current_project <- reactive({
    project <- sample_projects[sample_projects$project_id == selected_project_id(), ]
    if (nrow(project) > 0) project[1, ] else NULL
  })
  
  # Active tab tracker
  active_tab <- reactiveVal("overview")
  
  # Back to project list
  observeEvent(input$goto_home, {
    shinyjs::hide(id = "project_detail_view")
    shinyjs::show(id = "projects_list_view")
  })
  
  # Tab switching logic
  observeEvent(input$active_tab, {
    active_tab(input$active_tab)
    
    # Remove active class from all tabs and content
    shinyjs::runjs("
      $('.nav-tab').removeClass('active');
      $('.dash-tab-content').removeClass('active');
    ")
    
    # Add active class to selected tab and content
    tab_ids <- c(
      "overview" = "#tab_overview",
      "sentiment" = "#tab_sentiment",
      "rewards" = "#tab_rewards",
      "creator" = "#tab_creator",
      "ai" = "#tab_ai"
    )
    
    content_ids <- c(
      "overview" = "#content_overview",
      "sentiment" = "#content_sentiment",
      "rewards" = "#content_rewards",
      "creator" = "#content_creator",
      "ai" = "#content_ai"
    )
    
    shinyjs::runjs(sprintf("$('%s').addClass('active');", tab_ids[input$active_tab]))
    shinyjs::runjs(sprintf("$('%s').addClass('active');", content_ids[input$active_tab]))

    # Trigger resize so plotly charts recalculate dimensions in newly visible tabs
    shinyjs::runjs("setTimeout(function(){ window.dispatchEvent(new Event('resize')); }, 200);")
  })
  
  # Project name (breadcrumb)
  output$current_project_name <- renderText({
    p <- current_project()
    if (!is.null(p)) p$title else ""
  })
  
  # Project title (header)
  output$project_title <- renderText({
    p <- current_project()
    if (!is.null(p)) p$title else ""
  })
  
  # Project image
  output$project_image <- renderUI({
    p <- current_project()
    if (!is.null(p)) {
      tags$img(
        src = p$image_url,
        style = "width: 128px; height: 192px; border-radius: 12px; object-fit: cover; box-shadow: 0 4px 12px rgba(0,0,0,0.2);"
      )
    }
  })
  
  # Category breadcrumb
  output$project_category_breadcrumb <- renderText({
    p <- current_project()
    if (!is.null(p)) paste0(p$category, " → ", p$category_sub) else ""
  })
  
  # Creator name
  output$project_creator <- renderText({
    p <- current_project()
    if (!is.null(p)) p$creator_name else ""
  })
  
  # "Project We Love" badge (conditional)
  output$project_we_love_badge <- renderUI({
    p <- current_project()
    if (!is.null(p) && p$is_project_we_love) {
      div(style = "padding: 6px 12px; background: #E8F5E9; color: #05CE78; border-radius: 20px; font-size: 13px; font-weight: 600; display: inline-block; margin-bottom: 10px;",
          "⭐ Project We Love")
    }
  })
  
  # Kickstarter link
  output$project_kickstarter_link <- renderUI({
    p <- current_project()
    if (!is.null(p)) {
      tagList(
        tags$br(),
        tags$a(href = p$url, target = "_blank",
               style = "color: #667EEA; font-weight: 600; text-decoration: none;",
               "View on Kickstarter →")
      )
    }
  })
  
  # Start date
  output$project_start_date <- renderText({
    p <- current_project()
    if (!is.null(p)) format(as.POSIXct(p$launched_at, origin = "1970-01-01"), "%b %d, %Y") else ""
  })
  
  # End date
  output$project_end_date <- renderText({
    p <- current_project()
    if (!is.null(p)) format(as.POSIXct(p$deadline_at, origin = "1970-01-01"), "%b %d, %Y") else ""
  })
  
  # Status badge
  output$project_status_badge <- renderUI({
    p <- current_project()
    if (!is.null(p)) {
      div(class = "status-badge", p$status)
    }
  })
  
  # Collected amount
  output$project_collected <- renderText({
    p <- current_project()
    if (!is.null(p)) paste0(p$pledged_symbol, formatC(p$pledged_amount, format = "f", digits = 0, big.mark = ",")) else ""
  })
  
  # Goal amount
  output$project_goal <- renderText({
    p <- current_project()
    if (!is.null(p)) paste0(p$goal_symbol, formatC(p$goal_amount, format = "f", digits = 0, big.mark = ",")) else ""
  })
  
  # Backers count
  output$project_backers <- renderText({
    p <- current_project()
    if (!is.null(p)) formatC(p$backers_count, format = "d", big.mark = ",") else ""
  })
  
  # Overview Pie (uses real project data)
  output$overview_pie <- renderPlotly({
    p <- current_project()
    if (is.null(p)) return(NULL)
    
    collected_pct <- min(p$percent_funded, 100)
    remaining_pct <- max(100 - p$percent_funded, 0)
    
    overview_data <- data.frame(
      label = c("Collected", "Remaining"),
      value = c(collected_pct, remaining_pct),
      color = c(colors$indigo_light, colors$warning)
    )
    
    plot_ly(data = overview_data, labels = ~label, values = ~value, type = 'pie',
            marker = list(colors = ~color), textinfo = 'percent',
            hoverinfo = 'label+percent', showlegend = TRUE) %>%
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor = 'rgba(0,0,0,0)',
             margin = list(l = 0, r = 0, t = 0, b = 0),
             legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.1)) %>%
      config(displayModeBar = FALSE)
  })
  
  # Main chart (funding progress - sample data)
  output$main_chart <- renderPlotly({
    plot_ly(funding_data, x = ~date) %>%
      add_trace(y = ~progress, name = 'Funding Progress', type = 'scatter', mode = 'lines+markers',
                line = list(color = colors$indigo_light, width = 4),
                marker = list(color = colors$indigo_light, size = 10,
                              line = list(color = 'white', width = 2))) %>%
      add_trace(y = ~average, name = 'Average (Success Projects)', type = 'scatter',
                mode = 'lines+markers',
                line = list(color = colors$purple_light, width = 3, dash = 'dash'),
                marker = list(color = colors$purple_light, size = 8,
                              line = list(color = 'white', width = 2))) %>%
      add_trace(y = ~goal, name = 'Goal', type = 'scatter', mode = 'lines',
                line = list(color = colors$primary, width = 3, dash = 'dot')) %>%
      layout(xaxis = list(title = "", gridcolor = '#E5E7EB', showgrid = TRUE),
             yaxis = list(title = "", gridcolor = '#E5E7EB', showgrid = TRUE,
                          tickformat = '$,.0f'),
             hovermode = 'x unified', paper_bgcolor = 'rgba(0,0,0,0)',
             plot_bgcolor = 'rgba(0,0,0,0)',
             legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.15),
             margin = list(l = 60, r = 40, t = 20, b = 80)) %>%
      config(displayModeBar = FALSE)
  })
  # ============================================================================
  # CALL SENTIMENT SERVER MODULE
  # ============================================================================
  sentiment_server(input, output, session, current_project)
}