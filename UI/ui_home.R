# ============================================================================
# Home tab UI definition
# -> The first page that appears with all the projects + filters
# ============================================================================
home_tab_ui <- function() {
  tabItem(
    tabName = "home",
    
    # === List view (filters + project grid) ===
    div(id = "projects_list_view",
        style = "display: block;",  
        
        div(class = "projects-header",
            tags$svg(
              xmlns = "http://www.w3.org/2000/svg",
              width = "48", height = "48", viewBox = "0 0 24 24",
              fill = "none", stroke = "white", `stroke-width` = "2",
              `stroke-linecap` = "round", `stroke-linejoin` = "round",
              style = "margin-right: 18px; flex-shrink: 0;",
              tags$rect(x = "3", y = "3", width = "7", height = "7", rx = "1"),
              tags$rect(x = "14", y = "3", width = "7", height = "7", rx = "1"),
              tags$rect(x = "3", y = "14", width = "7", height = "7", rx = "1"),
              tags$rect(x = "14", y = "14", width = "7", height = "7", rx = "1")
            ),
            h1("Projects", class = "page-title", style = "margin: 0; color: white; font-size: 26px;")
        ),
        
        # The Filters
        fluidRow(
          column(12,
                 div(class = "filter-section",
                     fluidRow(
                       column(12,
                              textInput("search_project", NULL,
                                        placeholder = "Search for a project...",
                                        width = "100%")
                       )
                     ),
                     fluidRow(
                       column(4,
                              tags$label(class = "filter-label",
                                tags$svg(xmlns="http://www.w3.org/2000/svg", width="20", height="20", viewBox="0 0 24 24",
                                  fill="none", stroke="currentColor", `stroke-width`="2",
                                  `stroke-linecap`="round", `stroke-linejoin`="round",
                                  tags$path(d="M4 6h16M4 10h16M4 14h16M4 18h16")
                                ),
                                " Category"
                              ),
                              selectInput("filter_category", label = NULL,
                                          choices = category_choices,
                                          width = "100%")
                       ),
                       column(4,
                              tags$label(class = "filter-label",
                                tags$svg(xmlns="http://www.w3.org/2000/svg", width="20", height="20", viewBox="0 0 24 24",
                                  fill="none", stroke="currentColor", `stroke-width`="2",
                                  `stroke-linecap`="round", `stroke-linejoin`="round",
                                  tags$circle(cx="12", cy="12", r="10"),
                                  tags$path(d="M9 12l2 2 4-4")
                                ),
                                " Status"
                              ),
                              selectInput("filter_status", label = NULL,
                                          choices = status_choices,
                                          width = "100%")
                       ),
                       column(4,
                              tags$label(class = "filter-label",
                                tags$svg(xmlns="http://www.w3.org/2000/svg", width="20", height="20", viewBox="0 0 24 24",
                                  fill="none", stroke="currentColor", `stroke-width`="2",
                                  `stroke-linecap`="round", `stroke-linejoin`="round",
                                  tags$circle(cx="12", cy="12", r="10"),
                                  tags$path(d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z")
                                ),
                                " Country"
                              ),
                              selectInput("filter_country", label = NULL,
                                          choices = country_choices,
                                          width = "100%")
                       )
                     )
                 )
          )
        ),
        
        # Project grid
        fluidRow(
          column(12, uiOutput("projects_grid"))
        )
    ),
    
    # === Detail view (hidden by default, shown when a project is clicked) ===
    div(id = "project_detail_view",
        style = "display: none;",  
        dashboard_content_ui()
    )
  )
}