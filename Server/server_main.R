# ============================================================================
# Main server function assembly
# ============================================================================
source("Server/server_home.R")
source("Server/server_sentiment.R")
source("Server/server_reward.R")
source("Server/server_creator.R")
source("Server/server_dashboard.R")
source("Server/server_AiInsights.R")
source("Server/server_analytics.R")

server <- function(input, output, session) {

  # Global reactive values
  selected_project_id <- reactiveVal(1)  # Default: project 1

  # Reactive returning the full project row (shared across all sub-servers)
  current_project <- reactive({
    project <- sample_projects[sample_projects$project_id == selected_project_id(), ]
    if (nrow(project) > 0) project[1, ] else NULL
  })

  # Call sub-server functions
  home_server(input, output, session, selected_project_id)
  dashboard_server(input, output, session, selected_project_id)
  sentiment_server(input, output, session, current_project)
  rewards_server(input, output, session, current_project)
  creator_server(input, output, session, current_project)
  ai_server(input, output, session, current_project)
  analytics_server(input, output, session)
}
