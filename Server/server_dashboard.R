# ============================================================================
# Dashboard server logic (project detail view)
# ============================================================================
dashboard_server <- function(input, output, session, selected_project_id, current_view) {

  # Helper: get the currently selected project row
  current_project <- reactive({
    project <- sample_projects[sample_projects$project_id == selected_project_id(), ]
    if (nrow(project) > 0) project[1, ] else NULL
  })

  # Back to project list
  observeEvent(input$goto_home, {
    shinyjs::hide("project_detail_view")
    shinyjs::show("projects_list_view")
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

  # View mode switching
  observeEvent(input$view_mode, { current_view(input$view_mode) })
  observeEvent(input$btn_overview, { current_view("overview") })
  observeEvent(input$btn_sentiment, { current_view("sentiment") })

  observe({
    if (current_view() == "overview") {
      shinyjs::runjs("$('#btn_overview').addClass('active'); $('#btn_sentiment').removeClass('active');")
      shinyjs::runjs("$('#overview-card').addClass('active'); $('#sentiment-card').removeClass('active');")
    } else {
      shinyjs::runjs("$('#btn_sentiment').addClass('active'); $('#btn_overview').removeClass('active');")
      shinyjs::runjs("$('#sentiment-card').addClass('active'); $('#overview-card').removeClass('active');")
    }
  })

  # Chart title
  output$chart_title <- renderText({
    if (current_view() == "overview") "Funding Progress" else "Sentiment Over Time"
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

  # Sentiment Donut (sample data — no per-project sentiment in JSON)
  output$sentiment_donut <- renderPlotly({
    sentiment_summary <- data.frame(
      label = c("Positive", "Neutral", "Negative"),
      value = c(63, 22, 15),
      color = c(colors$green_light, colors$blue_light, colors$red_light)
    )

    plot_ly(data = sentiment_summary, labels = ~label, values = ~value,
            type = 'pie', hole = 0.6, marker = list(colors = ~color),
            textposition = 'none', hoverinfo = 'label+percent', showlegend = FALSE) %>%
      layout(paper_bgcolor = 'rgba(0,0,0,0)', plot_bgcolor = 'rgba(0,0,0,0)',
             margin = list(l = 0, r = 0, t = 0, b = 0)) %>%
      config(displayModeBar = FALSE)
  })

  # Main chart (sample time-series data — no per-project time-series in JSON)
  output$main_chart <- renderPlotly({
    if (current_view() == "overview") {
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
    } else {
      plot_ly(sentiment_data, x = ~date) %>%
        add_trace(y = ~positive, name = 'Positive', type = 'scatter', mode = 'lines+markers',
                  line = list(color = colors$green_light, width = 4),
                  marker = list(color = colors$green_light, size = 10,
                                line = list(color = 'white', width = 2))) %>%
        add_trace(y = ~neutral, name = 'Neutral', type = 'scatter', mode = 'lines+markers',
                  line = list(color = colors$blue_light, width = 4),
                  marker = list(color = colors$blue_light, size = 10,
                                line = list(color = 'white', width = 2))) %>%
        add_trace(y = ~negative, name = 'Negative', type = 'scatter', mode = 'lines+markers',
                  line = list(color = colors$red_light, width = 4),
                  marker = list(color = colors$red_light, size = 10,
                                line = list(color = 'white', width = 2))) %>%
        layout(xaxis = list(title = "", gridcolor = '#E5E7EB', showgrid = TRUE),
               yaxis = list(title = "", gridcolor = '#E5E7EB', showgrid = TRUE,
                            ticksuffix = '%', range = c(0, 100)),
               hovermode = 'x unified', paper_bgcolor = 'rgba(0,0,0,0)',
               plot_bgcolor = 'rgba(0,0,0,0)',
               legend = list(orientation = 'h', x = 0.5, xanchor = 'center', y = -0.15),
               margin = list(l = 60, r = 40, t = 20, b = 80)) %>%
        config(displayModeBar = FALSE)
    }
  })
}
