# ============================================================================
# ui_creator.R — Creator tab UI
# Displays creator profile, strengths radar, and project history.
# All data comes from kickstarter DB (profile) + base_traitee DWH (radar scores).
# ============================================================================

creator_tab_ui <- function() {

  div(id = "content_creator", class = "dash-tab-content",

      # ── CREATOR PROFILE HEADER ─────────────────────────────────────────────
      # Full-width card: avatar initials | name + bio + location | quick stats
      fluidRow(
        column(12,
               div(class = "creator-profile-card",
                   fluidRow(

                     # Avatar circle with initials
                     column(1,
                            div(class = "creator-avatar",
                                div(style = paste0(
                                  "width:80px;height:80px;border-radius:50%;",
                                  "background:linear-gradient(135deg,#667EEA 0%,#764BA2 100%);",
                                  "display:flex;align-items:center;justify-content:center;",
                                  "color:white;font-size:36px;font-weight:bold;"
                                ),
                                textOutput("creator_initials", inline = TRUE))
                            )
                     ),

                     # Name, Facebook badge, title, location, biography
                     column(7,
                            div(style = "padding-left: 10px;",

                                # Name + Facebook connection badge on the same line
                                div(style = "display:flex;align-items:center;gap:10px;margin-bottom:8px;",
                                    div(style = "font-size:24px;font-weight:bold;color:#2C3E50;",
                                        textOutput("creator_name_header", inline = TRUE)),
                                    uiOutput("creator_fb_badge", inline = TRUE)
                                ),

                                # Category-based title (e.g. "Technology Creator · Kickstarter")
                                div(style = "font-size:14px;color:#95A5A6;margin-bottom:5px;",
                                    textOutput("creator_title", inline = TRUE)),

                                # Location from kickstarter DB (falls back to country)
                                div(style = "font-size:13px;color:#6B7280;",
                                    icon("map-marker-alt", style = "color:#667EEA;margin-right:5px;"),
                                    textOutput("creator_location", inline = TRUE)
                                ),

                                # Biography from kickstarter.CREATOR (hidden when empty)
                                uiOutput("creator_bio", style = "font-size:15px;")
                            )
                     ),

                     # Quick stats: Launched Projects | Replies | Websites
                     column(4,
                            div(class = "creator-quick-stats",
                                fluidRow(

                                  column(4,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size:32px;font-weight:bold;color:#2C3E50;",
                                                 textOutput("creator_total_projects", inline = TRUE)),
                                             div(style = "font-size:13px;color:#95A5A6;", "Launched Projects")
                                         )
                                  ),

                                  column(4,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size:32px;font-weight:bold;color:#05CE78;",
                                                 textOutput("creator_reply_count", inline = TRUE)),
                                             div(style = "font-size:13px;color:#95A5A6;", "Replies")
                                         )
                                  ),

                                  column(4,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size:32px;font-weight:bold;color:#F39C12;",
                                                 textOutput("creator_nb_websites", inline = TRUE)),
                                             div(style = "font-size:13px;color:#95A5A6;", "Websites")
                                         )
                                  )

                                )
                            )
                     )

                   )
               )
        )
      ),

      # ── CREATOR STRENGTHS & HISTORY ────────────────────────────────────────
      fluidRow(

        # Left: Radar chart with 5 axes computed from the DWH
        # (Communication, Transparency, Community, Delivery, Innovation)
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("star", style = "color:#F39C12;margin-right:10px;"),
                       "Creator Strengths"),

                   # Zoom controls for the radar chart
                   div(class = "zoom-btn-row",
                       tags$button(class = "zoom-btn", title = "Zoom In",
                                   onclick = "plotZoomIn('creator_strengths_radar')",
                                   icon("search-plus")),
                       tags$button(class = "zoom-btn", title = "Zoom Out",
                                   onclick = "plotZoomOut('creator_strengths_radar')",
                                   icon("search-minus"))
                   ),

                   div(style = "text-align:center;padding:20px 0;",
                       plotlyOutput("creator_strengths_radar", height = "280px")
                   ),

                   # Summary cards below the radar: best axis and average score
                   fluidRow(
                     column(6,
                            div(style = paste0(
                              "background:linear-gradient(135deg,#FFF3E0 0%,#FFE0B2 100%);",
                              "border-radius:12px;padding:15px;text-align:center;"
                            ),
                            div(style = "font-size:13px;color:#95A5A6;margin-bottom:5px;", "Top Trait"),
                            uiOutput("creator_top_trait")
                            )
                     ),
                     column(6,
                            div(style = paste0(
                              "background:linear-gradient(135deg,#E8F5E9 0%,#C8E6C9 100%);",
                              "border-radius:12px;padding:15px;text-align:center;"
                            ),
                            div(style = "font-size:13px;color:#95A5A6;margin-bottom:5px;", "Avg Score"),
                            uiOutput("creator_avg_score")
                            )
                     )
                   )
               )
        ),

        # Right: Chronological list of all projects by this creator
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("history", style = "color:#9B59B6;margin-right:10px;"),
                       "Creator History"),
                   div(id = "creator_projects_timeline",
                       uiOutput("creator_past_projects")
                   )
               )
        )

      )
  )
}
