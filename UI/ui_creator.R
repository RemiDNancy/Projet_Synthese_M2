
# ============================================================================
# Creator tab UI - CORRECTED VERSION
# ============================================================================
creator_tab_ui <- function() {  
  
  div(id = "content_creator", class = "dash-tab-content",
      # ============================================================================
      # CREATOR PROFILE HEADER CARD
      # ============================================================================
      fluidRow(
        column(12,
               div(class = "creator-profile-card",
                   fluidRow(
                     # Left: Avatar
                     column(1,
                            div(class = "creator-avatar",
                                div(style = "width: 80px; height: 80px; border-radius: 50%; background: linear-gradient(135deg, #667EEA 0%, #764BA2 100%); display: flex; align-items: center; justify-content: center; color: white; font-size: 36px; font-weight: bold;",
                                    textOutput("creator_initials", inline = TRUE)
                                )
                            )
                     ),
                     # Middle: Creator Info
                     column(7,
                            div(style = "padding-left: 10px;",
                                div(style = "display: flex; align-items: center; gap: 10px; margin-bottom: 8px;",
                                    div(style = "font-size: 24px; font-weight: bold; color: #2C3E50;",
                                        textOutput("creator_name_header", inline = TRUE)),
                                    div(class = "badge-present", 
                                        style = "padding: 4px 10px; background: #E8F5E9; color: #05CE78; border-radius: 12px; font-size: 11px; font-weight: 600;",
                                        "✓ Present"),
                                    div(class = "badge-rewards",
                                        style = "padding: 4px 10px; background: #FFF3E0; color: #F39C12; border-radius: 12px; font-size: 11px; font-weight: 600;",
                                        "🏆 10 Rewards")
                                ),
                                div(style = "font-size: 14px; color: #95A5A6; margin-bottom: 5px;",
                                    textOutput("creator_title", inline = TRUE)),
                                div(style = "font-size: 13px; color: #6B7280;",
                                    icon("map-marker-alt", style = "color: #667EEA; margin-right: 5px;"),
                                    textOutput("creator_location", inline = TRUE)
                                )
                            )
                     ),
                     # Right: Stats
                     column(4,
                            div(class = "creator-quick-stats",
                                fluidRow(
                                  column(3,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size: 24px; font-weight: bold; color: #2C3E50;",
                                                 textOutput("creator_total_projects", inline = TRUE)),
                                             div(style = "font-size: 11px; color: #95A5A6;", "Projects")
                                         )
                                  ),
                                  column(3,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size: 24px; font-weight: bold; color: #05CE78;",
                                                 textOutput("creator_success_rate", inline = TRUE)),
                                             div(style = "font-size: 11px; color: #95A5A6;", "Success")
                                         )
                                  ),
                                  column(3,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size: 24px; font-weight: bold; color: #667EEA;",
                                                 textOutput("creator_total_raised", inline = TRUE)),
                                             div(style = "font-size: 11px; color: #95A5A6;", "Total Raised")
                                         )
                                  ),
                                  column(3,
                                         div(class = "creator-stat-mini",
                                             div(style = "font-size: 24px; font-weight: bold; color: #F39C12;",
                                                 textOutput("creator_avg_backers", inline = TRUE)),
                                             div(style = "font-size: 11px; color: #95A5A6;", "Avg Backers")
                                         )
                                  )
                                )
                            )
                     )
                   )
               )
        )
      ),
      
      # ============================================================================
      # CREATOR STRENGTHS & COMMUNICATION ACTIVITY
      # ============================================================================
      fluidRow(
        # Left: Creator Strengths (Radar Chart)
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("star", style = "color: #F39C12; margin-right: 10px;"),
                       "Creator Strengths"),
                   
                   # Radar Chart
                   div(class = "zoom-btn-row",
                       tags$button(class = "zoom-btn", title = "Zoom In",
                                   onclick = "plotZoomIn('creator_strengths_radar')",
                                   icon("search-plus")),
                       tags$button(class = "zoom-btn", title = "Zoom Out",
                                   onclick = "plotZoomOut('creator_strengths_radar')",
                                   icon("search-minus"))
                   ),
                   div(style = "text-align: center; padding: 20px 0;",
                       plotlyOutput("creator_strengths_radar", height = "280px")
                   ),

                   # Score Boxes
                   fluidRow(
                     column(6,
                            div(style = "background: linear-gradient(135deg, #FFF3E0 0%, #FFE0B2 100%); border-radius: 12px; padding: 15px; text-align: center;",
                                div(style = "font-size: 13px; color: #95A5A6; margin-bottom: 5px;", "Top Trait"),
                                div(style = "font-size: 20px; font-weight: bold; color: #F39C12;",
                                    "Communication (92%)")
                            )
                     ),
                     column(6,
                            div(style = "background: linear-gradient(135deg, #E8F5E9 0%, #C8E6C9 100%); border-radius: 12px; padding: 15px; text-align: center;",
                                div(style = "font-size: 13px; color: #95A5A6; margin-bottom: 5px;", "Avg Score"),
                                div(style = "font-size: 20px; font-weight: bold; color: #05CE78;", "86%")
                            )
                     )
                   )
               )
        ),
        
        # Right: Communication Activity (Bar Chart)
        column(6,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("comments", style = "color: #667EEA; margin-right: 10px;"),
                       "Communication Activity"),
                   
                   # Bar Chart
                   div(style = "padding: 10px 0; margin-bottom: 15px;",
                       plotlyOutput("creator_communication_chart", height = "280px")
                   ),
                   
                   # Average Info Box
                   div(style = "background: linear-gradient(135deg, #EEF2FF 0%, #E0E7FF 100%); border-radius: 12px; padding: 15px; text-align: center;",
                       div(style = "font-size: 13px; color: #667EEA; margin-bottom: 5px;",
                           icon("chart-line", style = "margin-right: 5px;"),
                           "Average: 3 updates per week - Excellent communication!"),
                       div(style = "font-size: 11px; color: #95A5A6; margin-top: 5px;",
                           "Last update: 2 days ago")
                   )
               )
        )
      ),
      
      # ============================================================================
      # CREATOR HISTORY / PAST PROJECTS (Optional Section)
      # ============================================================================
      fluidRow(
        column(12,
               div(class = "stat-box",
                   div(class = "stat-title",
                       icon("history", style = "color: #9B59B6; margin-right: 10px;"),
                       "Creator History"),
                   
                   # Projects Timeline
                   div(id = "creator_projects_timeline",
                       uiOutput("creator_past_projects")
                   )
               )
        )
      )
  )
}
