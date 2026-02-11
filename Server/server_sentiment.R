# ============================================================================
# Sentiment tab server logic - Version corrigée
# ============================================================================
sentiment_server <- function(input, output, session, current_project) {
  
  # Sentiment Donut Chart - VERSION CORRIGÉE
  output$sentiment_donut_main <- renderPlotly({
    sentiment_summary <- data.frame(
      label = c("Positive", "Neutral", "Negative"),
      value = c(63, 22, 15),
      stringsAsFactors = FALSE
    )
    
    colors_sentiment <- c('#86EFAC', '#93C5FD', '#FCA5A5')
    
    plot_ly() %>%
      add_pie(
        data = sentiment_summary,
        labels = ~label,
        values = ~value,
        hole = 0.6,
        marker = list(colors = colors_sentiment),
        textposition = 'none',
        hoverinfo = 'label+percent',
        showlegend = FALSE
      ) %>%
      layout(
        paper_bgcolor = 'rgba(0,0,0,0)',
        plot_bgcolor = 'rgba(0,0,0,0)',
        margin = list(l = 0, r = 0, t = 0, b = 0),
        xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
        yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
      ) %>%
      config(displayModeBar = FALSE)
  })
  
  # Sentiment Evolution Chart - VERSION CORRIGÉE
  output$sentiment_evolution_chart <- renderPlotly({
    plot_ly(sentiment_data) %>%
      add_trace(
        x = ~date,
        y = ~positive,
        name = 'Positive',
        type = 'scatter',
        mode = 'lines+markers',
        fill = 'tozeroy',
        line = list(color = '#86EFAC', width = 3),
        marker = list(
          color = '#86EFAC',
          size = 8,
          line = list(color = 'white', width = 2)
        ),
        fillcolor = 'rgba(134, 239, 172, 0.2)'
      ) %>%
      add_trace(
        x = ~date,
        y = ~neutral,
        name = 'Neutral',
        type = 'scatter',
        mode = 'lines+markers',
        fill = 'tonexty',
        line = list(color = '#93C5FD', width = 3),
        marker = list(
          color = '#93C5FD',
          size = 8,
          line = list(color = 'white', width = 2)
        ),
        fillcolor = 'rgba(147, 197, 253, 0.2)'
      ) %>%
      add_trace(
        x = ~date,
        y = ~negative,
        name = 'Negative',
        type = 'scatter',
        mode = 'lines+markers',
        fill = 'tonexty',
        line = list(color = '#FCA5A5', width = 3),
        marker = list(
          color = '#FCA5A5',
          size = 8,
          line = list(color = 'white', width = 2)
        ),
        fillcolor = 'rgba(252, 165, 165, 0.2)'
      ) %>%
      layout(
        xaxis = list(
          title = "",
          gridcolor = '#E5E7EB',
          showgrid = TRUE,
          zeroline = FALSE
        ),
        yaxis = list(
          title = "",
          gridcolor = '#E5E7EB',
          showgrid = TRUE,
          ticksuffix = '%',
          range = c(0, 100),
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

  # Force Shiny to render these outputs even when their tab is hidden.
  # Without this, Shiny suspends rendering for hidden outputs and our
  # custom CSS tab system doesn't trigger Shiny's visibility detection.
  outputOptions(output, "sentiment_donut_main", suspendWhenHidden = FALSE)
  outputOptions(output, "sentiment_evolution_chart", suspendWhenHidden = FALSE)
}