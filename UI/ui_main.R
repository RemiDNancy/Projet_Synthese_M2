# ============================================================================
# Main UI assembly
# ============================================================================
source("UI/styles.R")
source("UI/ui_sentiment.R")
source("UI/ui_reward.R")
source("UI/ui_creator.R")
source("UI/ui_AiInsights.R")
source("UI/ui_dashboard.R")
source("UI/ui_home.R")
source("UI/ui_analytics.R")
source("UI/ui_about.R")

ui <- dashboardPage(
  skin = "purple",

  # HEADER with the logo
  dashboardHeader(
    title = span(
      tags$img(src = "logoKickinsightv2.png", height = "65px", style = "display: block;"),
      "KickInsight"
    ),
    titleWidth = 300
  ),

  # SIDEBAR
  dashboardSidebar(
    width = 380,
    sidebarMenu(
      id = "sidebar",
      menuItem("Home", tabName = "home", icon = icon("home")),
      menuItem("Global Analytics", tabName = "analytics", icon = icon("globe")),
      menuItem("About Us", tabName = "about", icon = icon("users"))
    )
  ),

  # BODY
  dashboardBody(
    shinyjs::useShinyjs(),
    app_styles(),

    # Zoom in / out helpers for plotly charts
    tags$script(HTML("
      function plotZoomIn(plotId) {
        var gd = document.getElementById(plotId);
        if (!gd || !gd._fullLayout) return;
        var fl = gd._fullLayout;
        if (fl.polar) {
          var maxVal = fl.polar.radialaxis.range[1];
          Plotly.relayout(gd, {'polar.radialaxis.range[1]': Math.max(maxVal * 0.7, 20)});
        } else {
          var xr = fl.xaxis.range.slice();
          var yr = fl.yaxis.range.slice();
          var xc = (xr[0] + xr[1]) / 2;
          var yc = (yr[0] + yr[1]) / 2;
          Plotly.relayout(gd, {
            'xaxis.range[0]': xc - (xr[1]-xr[0])*0.35,
            'xaxis.range[1]': xc + (xr[1]-xr[0])*0.35,
            'yaxis.range[0]': yc - (yr[1]-yr[0])*0.35,
            'yaxis.range[1]': yc + (yr[1]-yr[0])*0.35
          });
        }
      }
      function plotZoomOut(plotId) {
        var gd = document.getElementById(plotId);
        if (!gd || !gd._fullLayout) return;
        var fl = gd._fullLayout;
        if (fl.polar) {
          var maxVal = fl.polar.radialaxis.range[1];
          Plotly.relayout(gd, {'polar.radialaxis.range[1]': Math.min(maxVal / 0.7, 100)});
        } else {
          var xr = fl.xaxis.range.slice();
          var yr = fl.yaxis.range.slice();
          var xc = (xr[0] + xr[1]) / 2;
          var yc = (yr[0] + yr[1]) / 2;
          Plotly.relayout(gd, {
            'xaxis.range[0]': xc - (xr[1]-xr[0])*0.5/0.7,
            'xaxis.range[1]': xc + (xr[1]-xr[0])*0.5/0.7,
            'yaxis.range[0]': yc - (yr[1]-yr[0])*0.5/0.7,
            'yaxis.range[1]': yc + (yr[1]-yr[0])*0.5/0.7
          });
        }
      }
    ")),

    tabItems(
      home_tab_ui(),
      analytics_tab_ui(),
      about_tab_ui()
    )
  )
)
