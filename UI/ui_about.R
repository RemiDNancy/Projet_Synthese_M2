# ============================================================================
# About Us UI
# ============================================================================

about_tab_ui <- function() {
  tabItem(
    tabName = "about",

    # ============================================================================
    # TOP: PROJECT & UNIVERSITY HEADER
    # ============================================================================
    fluidRow(
      column(12,
             div(class = "about-header",

                 # University logo (top)
                 div(class = "about-logo-wrap",
                     tags$img(src = "UL_MIM.png", class = "about-uni-logo")
                 ),

                 # Title block (below logo)
                 div(class = "about-header-text",
                     div(class = "about-app-name", "KickInsight"),
                     div(class = "about-project-title",
                         "Master's Project in Decision Support System (SID)"),
                     div(class = "about-project-sub",
                         icon("university", style = "margin-right: 8px;"),
                         "University of Lorraine — MIM Programme")
                 )
             )
      )
    ),

    # ============================================================================
    # TEAM SECTION
    # ============================================================================
    fluidRow(
      column(12,
             div(class = "about-team-section",

                 div(class = "about-team-heading",
                     icon("users", style = "color: #667EEA; font-size: 28px; margin-right: 12px;"),
                     "Our Team"
                 ),

                 # 5 member cards
                 div(class = "about-team-grid",

                     # Member 1
                     div(class = "about-person-card",
                         div(class = "about-person-avatar",
                             icon("user", class = "fa-3x")
                         ),
                         div(class = "about-person-name",   "First Name"),
                         div(class = "about-person-surname", "Last Name")
                     ),

                     # Member 2
                     div(class = "about-person-card",
                         div(class = "about-person-avatar",
                             icon("user", class = "fa-3x")
                         ),
                         div(class = "about-person-name",   "First Name"),
                         div(class = "about-person-surname", "Last Name")
                     ),

                     # Member 3
                     div(class = "about-person-card",
                         div(class = "about-person-avatar",
                             icon("user", class = "fa-3x")
                         ),
                         div(class = "about-person-name",   "First Name"),
                         div(class = "about-person-surname", "Last Name")
                     ),

                     # Member 4
                     div(class = "about-person-card",
                         div(class = "about-person-avatar",
                             icon("user", class = "fa-3x")
                         ),
                         div(class = "about-person-name",   "First Name"),
                         div(class = "about-person-surname", "Last Name")
                     ),

                     # Member 5
                     div(class = "about-person-card",
                         div(class = "about-person-avatar",
                             icon("user", class = "fa-3x")
                         ),
                         div(class = "about-person-name",   "First Name"),
                         div(class = "about-person-surname", "Last Name")
                     )
                 )
             )
      )
    )
  )
}
