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
        
        h1("Projects", class = "page-title"),
        
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
                              selectInput("filter_category", "Category",
                                          choices = category_choices,
                                          width = "100%")
                       ),
                       column(4,
                              selectInput("filter_status", "Status",
                                          choices = status_choices,
                                          width = "100%")
                       ),
                       column(4,
                              selectInput("filter_country", "Country",
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