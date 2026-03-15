# ============================================================================
# Global Analytics server logic - Placeholder data version
# ============================================================================
analytics_server <- function(input, output, session) {
  
  # ============================================================================
  # TOP STATS - KEY METRICS
  # ============================================================================
  
  output$total_projects <- renderText({
    "1,247"
  })
  
  output$success_rate <- renderText({
    "62.3%"
  })
  
  output$total_raised <- renderText({
    "$48.2M"
  })
  
  output$total_backers <- renderText({
    "156K"
  })
  
  # ============================================================================
  # SUCCESS RATE BY CATEGORY - HORIZONTAL BAR CHART
  # ============================================================================
  
  output$success_by_category <- renderPlotly({
    # Placeholder data
    category_data <- data.frame(
      category = c("Games", "Technology", "Art", "Design", "Film & Video", "Music", "Fashion"),
      success_rate = c(71.2, 68.5, 55.3, 58.7, 42.1, 38.9, 31.2),
      stringsAsFactors = FALSE
    )
    
    # Color coding: green for high, orange for medium, red for low
    category_data$color <- ifelse(category_data$success_rate >= 60, "#10B981",
                                  ifelse(category_data$success_rate >= 45, "#F59E0B", "#EF4444"))
    
    # Sort by success rate
    category_data <- category_data[order(category_data$success_rate, decreasing = TRUE), ]
    
    plot_ly(category_data, 
            y = ~reorder(category, success_rate),
            x = ~success_rate,
            type = 'bar',
            orientation = 'h',
            marker = list(color = ~color),
            text = ~paste0(success_rate, "%"),
            textposition = 'outside',
            hoverinfo = 'text',
            hovertext = ~paste0(category, ": ", success_rate, "%")
    ) %>%
      layout(
        xaxis = list(
          title = "",
          range = c(0, 100),
          showgrid = TRUE,
          gridcolor = '#E5E7EB',
          zeroline = FALSE
        ),
        yaxis = list(
          title = "",
          showgrid = FALSE
        ),
        margin = list(l = 100, r = 40, t = 20, b = 40),
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)',
        showlegend = FALSE
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ============================================================================
  # PROJECTS BY COUNTRY - PIE CHART
  # ============================================================================
  
  output$projects_by_country <- renderPlotly({
    # Placeholder data
    country_data <- data.frame(
      country = c("USA", "UK", "Canada", "France", "Germany", "Others"),
      projects = c(487, 234, 156, 122, 93, 155),
      stringsAsFactors = FALSE
    )
    
    # Calculate percentages
    country_data$percentage <- round(country_data$projects / sum(country_data$projects) * 100, 1)
    
    # Color palette
    colors_pie <- c('#667EEA', '#9333EA', '#10B981', '#F59E0B', '#EF4444', '#6B7280')
    
    plot_ly(country_data,
            labels = ~country,
            values = ~projects,
            type = 'pie',
            marker = list(colors = colors_pie),
            textinfo = 'label+percent',
            hoverinfo = 'text',
            hovertext = ~paste0(country, ": ", projects, " projects (", percentage, "%)")
    ) %>%
      layout(
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)',
        margin = list(l = 20, r = 20, t = 20, b = 20),
        showlegend = TRUE,
        legend = list(
          orientation = 'v',
          x = 1.05,
          y = 0.5
        )
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # ============================================================================
  # PROJECTS LAUNCHED OVER TIME - LINE CHART
  # ============================================================================
  
  output$projects_over_time <- renderPlotly({
    # Placeholder data - time series
    time_data <- data.frame(
      month = c("Jul 24", "Aug 24", "Sep 24", "Oct 24", "Nov 24", "Dec 24", "Jan 25", "Feb 25"),
      total_launched = c(95, 108, 98, 132, 115, 97, 137, 128),
      successful = c(62, 68, 65, 78, 72, 64, 82, 78),
      failed = c(33, 40, 33, 54, 43, 33, 55, 50),
      stringsAsFactors = FALSE
    )
    
    plot_ly() %>%
      # Total Launched line
      add_trace(
        data = time_data,
        x = ~month,
        y = ~total_launched,
        name = 'Total Launched',
        type = 'scatter',
        mode = 'lines+markers',
        line = list(color = '#667EEA', width = 3),
        marker = list(color = '#667EEA', size = 8, line = list(color = 'white', width = 2))
      ) %>%
      # Successful line
      add_trace(
        data = time_data,
        x = ~month,
        y = ~successful,
        name = 'Successful',
        type = 'scatter',
        mode = 'lines+markers',
        line = list(color = '#10B981', width = 3),
        marker = list(color = '#10B981', size = 8, line = list(color = 'white', width = 2))
      ) %>%
      # Failed line (dashed)
      add_trace(
        data = time_data,
        x = ~month,
        y = ~failed,
        name = 'Failed',
        type = 'scatter',
        mode = 'lines+markers',
        line = list(color = '#EF4444', width = 2, dash = 'dot'),
        marker = list(color = '#EF4444', size = 6)
      ) %>%
      layout(
        xaxis = list(
          title = "",
          showgrid = FALSE
        ),
        yaxis = list(
          title = "",
          showgrid = TRUE,
          gridcolor = '#E5E7EB',
          zeroline = FALSE
        ),
        hovermode = 'x unified',
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)',
        legend = list(
          orientation = 'h',
          x = 0.5,
          xanchor = 'center',
          y = -0.15
        ),
        margin = list(l = 60, r = 40, t = 20, b = 80)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
}