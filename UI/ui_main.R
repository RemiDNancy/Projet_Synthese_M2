# ============================================================================
# Main UI assembly
# ============================================================================
source("UI/styles.R")
source("UI/ui_sentiment.R")
source("UI/ui_dashboard.R")
source("UI/ui_home.R")

ui <- dashboardPage(
  skin = "purple",

  # HEADER with the logo
  dashboardHeader(
    title = span(
      tags$img(src = "logoKickinsightv2.png", height = "40px", style = "vertical-align: middle; margin-right: 8px;"),
      "KickInsight"
    ),
    titleWidth = 300
  ),

  # SIDEBAR
  dashboardSidebar(
    width = 200,
    sidebarMenu(
      id = "sidebar",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Global Analytics", tabName = "analytics", icon = icon("globe"))
    )
  ),

  # BODY
  dashboardBody(
    shinyjs::useShinyjs(),
    app_styles(),

    tabItems(
      home_tab_ui(),
      tabItem(tabName = "analytics", h2("Global Analytics - Coming soon"))
    )
  )
)
