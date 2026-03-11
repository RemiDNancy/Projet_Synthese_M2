# ============================================================================
# APP SHINY - KickInsight
# Thin entry point: sources modules and launches the app
# ============================================================================

# ============================================================================
# Libraries
# ============================================================================
library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(plotly)
library(dplyr)
library(lubridate)
library(shinyjs)
library(DBI)
library(RMySQL)

# ============================================================================
# Source modules  
# ============================================================================
source("Server/db.R")          
source("Server/config.R")      
source("Server/functions.R")
source("UI/ui_main.R")
source("Server/server_main.R")

# ============================================================================
# Launch the app
# ============================================================================
shinyApp(ui, server)