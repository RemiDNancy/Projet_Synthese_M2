# ============================================================================
# Home tab server logic
# ============================================================================
home_server <- function(input, output, session, selected_project_id) {

  # Filter projects
  filtered_projects <- reactive({
    projects <- sample_projects

    if (input$filter_category != "All categories") {
      projects <- projects[projects$category == input$filter_category, ]
    }

    if (input$filter_status != "All statuses") {
      projects <- projects[tolower(projects$status) == tolower(input$filter_status), ]
    }

    if (input$filter_country != "All countries") {
      projects <- projects[projects$country == input$filter_country, ]
    }

    if (!is.null(input$search_project) && input$search_project != "") {
      projects <- projects[grepl(input$search_project, projects$title, ignore.case = TRUE), ]
    }

    return(projects)
  })

  # Render project grid
  output$projects_grid <- renderUI({
    projects <- filtered_projects()

    if (nrow(projects) == 0) {
      return(
        div(style = "text-align: center; padding: 40px; color: #95A5A6;",
            icon("search", class = "fa-3x"),
            h3("No projects found"),
            p("Try adjusting your filters")
        )
      )
    }

    project_cards <- lapply(1:nrow(projects), function(i) {
      project <- projects[i, ]

      if (project$percent_funded >= 100) {
        bar_color <- colors$success
      } else if (project$percent_funded >= 50) {
        bar_color <- colors$live
      } else {
        bar_color <- colors$danger
      }

      status_color <- get_status_color(project$status)

      column(width = 6,
             div(class = "project-card",
                 onclick = sprintf("Shiny.setInputValue('selected_project', %d, {priority: 'event'})",
                                   project$project_id),
                 tags$img(src = project$image_url,
                          style = "width: 80px; height: 80px; border-radius: 8px; object-fit: cover; margin-bottom: 10px;"),
                 div(class = "project-title", project$title),
                 div(class = "project-category", project$category),
                 div(class = "project-status", style = sprintf("color: %s;", status_color), project$status),
                 div(class = "progress-bar-container",
                     div(class = "progress-bar-fill",
                         style = sprintf("width: %s%%; background: %s;",
                                         min(project$percent_funded, 100), bar_color))
                 ),
                 div(class = "progress-percent", sprintf("%.1f%%", project$percent_funded))
             )
      )
    })

    rows <- list()
    for (i in seq(1, length(project_cards), by = 2)) {
      if (i + 1 <= length(project_cards)) {
        rows[[length(rows) + 1]] <- fluidRow(project_cards[[i]], project_cards[[i + 1]])
      } else {
        rows[[length(rows) + 1]] <- fluidRow(project_cards[[i]])
      }
    }

    return(tagList(rows))
  })

  # Click on a project -> show detail view inline
  observeEvent(input$selected_project, {
    selected_project_id(input$selected_project)
    shinyjs::hide("projects_list_view")
    shinyjs::show("project_detail_view")
  })
}
