# ============================================================================
# Main server function assembly
# ============================================================================
source("Server/server_home.R")
source("Server/server_dashboard.R")

server <- function(input, output, session) {
  
  # Global reactive values
  selected_project_id <- reactiveVal(1)  # Default: project 1
  
  # Call sub-server functions
  home_server(input, output, session, selected_project_id)
  dashboard_server(input, output, session, selected_project_id)
}
