# ============================================================================
# AI Insights tab UI - Dual AI Model Comparison
# ============================================================================

ai_tab_ui <- function() {
  div(id = "content_ai", class = "dash-tab-content",
      
      # ============================================================================
      # TOP: AI MODEL CARDS (The Oracle vs The Sage)
      # ============================================================================
      fluidRow(
        # The Oracle Card (Left)
        column(6,
               div(class = "ai-model-card oracle-card",
                   id = "oracle_card",
                   onclick = "Shiny.setInputValue('selected_ai_model', 'oracle', {priority: 'event'})",
                   
                   # Header with Icon and Name
                   div(class = "ai-model-header",
                       div(class = "ai-model-icon oracle-icon",
                           tags$img(src = "crystalBall.png", style = "width: 40px; height: 40px; object-fit: contain;")
                       ),
                       div(class = "ai-model-info",
                           div(class = "ai-model-name", "The Oracle"),
                           div(class = "ai-model-subtitle", "KNN Classifier")
                       ),
                       div(class = "ai-favorite-badge",
                           icon("star", style = "color: #F59E0B;")
                       )
                   ),
                   
                   # Success Prediction
                   div(class = "ai-prediction-section",
                       div(style = "font-size: 13px; color: rgba(255,255,255,0.8); margin-bottom: 8px;", 
                           "Success Prediction"),
                       div(class = "ai-prediction-value oracle-value", 
                           textOutput("oracle_prediction", inline = TRUE)),
                       div(class = "ai-prediction-bar oracle-bar",
                           div(class = "ai-prediction-fill oracle-fill",
                               style = "width: 91%;")
                       )
                   ),
                   
                   # Three Key Metrics
                   div(class = "ai-metrics-grid",
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Pattern Recognition"),
                           div(class = "ai-metric-value", textOutput("oracle_pattern", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Historical Accuracy"),
                           div(class = "ai-metric-value", textOutput("oracle_accuracy", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Neighbor Analysis"),
                           div(class = "ai-metric-value", textOutput("oracle_neighbor", inline = TRUE))
                       )
                   ),
                   
                   # Footer
                   div(class = "ai-card-footer",
                       "Based on 1,200+ similar projects"
                   )
               )
        ),
        
        # The Sage Card (Right)
        column(6,
               div(class = "ai-model-card sage-card",
                   id = "sage_card",
                   onclick = "Shiny.setInputValue('selected_ai_model', 'sage', {priority: 'event'})",
                   
                   # Header with Icon and Name
                   div(class = "ai-model-header",
                       div(class = "ai-model-icon sage-icon",
                           tags$img(src = "wizard.png", style = "width: 40px; height: 40px; object-fit: contain;")
                       ),
                       div(class = "ai-model-info",
                           div(class = "ai-model-name", "The Sage"),
                           div(class = "ai-model-subtitle", "Random Forest")
                       )
                   ),
                   
                   # Success Prediction
                   div(class = "ai-prediction-section",
                       div(style = "font-size: 13px; color: rgba(255,255,255,0.8); margin-bottom: 8px;", 
                           "Success Prediction"),
                       div(class = "ai-prediction-value sage-value", 
                           textOutput("sage_prediction", inline = TRUE)),
                       div(class = "ai-prediction-bar sage-bar",
                           div(class = "ai-prediction-fill sage-fill",
                               style = "width: 87%;")
                       )
                   ),
                   
                   # Three Key Metrics
                   div(class = "ai-metrics-grid",
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Multi-factor Analysis"),
                           div(class = "ai-metric-value", textOutput("sage_multifactor", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Robustness"),
                           div(class = "ai-metric-value", textOutput("sage_robustness", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Feature Importance"),
                           div(class = "ai-metric-value", textOutput("sage_feature", inline = TRUE))
                       )
                   ),
                   
                   # Footer
                   div(class = "ai-card-footer",
                       "Analyzed across 50+ decision trees"
                   )
               )
        )
      ),
      
      # ============================================================================
      # BOTTOM: DETAILED ANALYSIS (Changes based on selected model)
      # ============================================================================
      fluidRow(
        column(12,
               # The Oracle's Analysis (shown when Oracle selected)
               div(id = "oracle_analysis", class = "ai-analysis-panel oracle-panel active",
                   
                   # Panel Header
                   div(class = "ai-analysis-header",
                       div(class = "ai-analysis-icon oracle-icon",
                           tags$img(src = "crystalBall.png", style = "width: 32px; height: 32px; object-fit: contain;")
                       ),
                       div(class = "ai-analysis-title",
                           "The Oracle's Analysis",
                           tags$br(),
                           tags$span(class = "ai-analysis-subtitle", "KNN Classifier Deep Dive")
                       )
                   ),
                   
                   fluidRow(
                     # Left: Prediction Details
                     column(6,
                            div(class = "ai-detail-box oracle-detail",
                                div(class = "ai-detail-header",
                                    icon("bullseye", style = "margin-right: 8px;"),
                                    "Prediction Details"
                                ),
                                div(class = "ai-detail-list",
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("rocket", style = "margin-right: 8px;"),
                                            "Funding Pace"
                                        ),
                                        div(class = "ai-detail-value", "+23%")
                                    ),
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("smile", style = "margin-right: 8px;"),
                                            "Sentiment Score"
                                        ),
                                        div(class = "ai-detail-value", "72%")
                                    ),
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("bolt", style = "margin-right: 8px;"),
                                            "Activity Level"
                                        ),
                                        div(class = "ai-detail-value", "3.2x avg")
                                    ),
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("chart-line", style = "margin-right: 8px;"),
                                            "Category Success"
                                        ),
                                        div(class = "ai-detail-value", "75% rate")
                                    )
                                )
                            )
                     ),
                     
                     # Right: Top Success Factors
                     column(6,
                            div(class = "ai-detail-box oracle-detail",
                                div(class = "ai-detail-header",
                                    icon("fire", style = "margin-right: 8px;"),
                                    "Top Success Factors"
                                ),
                                div(class = "ai-factor-list",
                                    div(class = "ai-factor-item",
                                        div(class = "ai-factor-name", "Communication"),
                                        div(class = "ai-factor-score",
                                            "92%",
                                            tags$span(class = "ai-badge hot", "Hot")
                                        ),
                                        div(class = "ai-factor-bar",
                                            div(style = "width: 92%; background: #F59E0B; height: 6px; border-radius: 3px;")
                                        )
                                    ),
                                    div(class = "ai-factor-item",
                                        div(class = "ai-factor-name", "Similar Success Rate"),
                                        div(class = "ai-factor-score",
                                            "88%",
                                            tags$span(class = "ai-badge hot", "Hot")
                                        ),
                                        div(class = "ai-factor-bar",
                                            div(style = "width: 88%; background: #F59E0B; height: 6px; border-radius: 3px;")
                                        )
                                    ),
                                    div(class = "ai-factor-item",
                                        div(class = "ai-factor-name", "Backer Engagement"),
                                        div(class = "ai-factor-score",
                                            "85%",
                                            tags$span(class = "ai-badge medium", "Medium")
                                        ),
                                        div(class = "ai-factor-bar",
                                            div(style = "width: 85%; background: #F59E0B; height: 6px; border-radius: 3px;")
                                        )
                                    )
                                )
                            )
                     )
                   ),
                   
                   # Comparison Section
                   fluidRow(
                     column(12,
                            div(class = "ai-comparison-box oracle-comparison",
                                div(class = "ai-comparison-header",
                                    icon("balance-scale", style = "margin-right: 8px;"),
                                    "The Oracle vs The Sage"
                                ),
                                
                                fluidRow(
                                  # Oracle side
                                  column(5,
                                         div(class = "ai-compare-item oracle-compare",
                                             div(class = "ai-compare-model",
                                                 div(class = "ai-compare-icon oracle-icon",
                                                     tags$img(src = "crystalBall.png", style = "width: 26px; height: 26px; object-fit: contain;")
                                                 ),
                                                 div(class = "ai-compare-info",
                                                     div("The Oracle"),
                                                     div(class = "ai-compare-subtitle", "KNN Classifier")
                                                 )
                                             ),
                                             div(class = "ai-compare-prediction", "91%"),
                                             div(class = "ai-compare-bar",
                                                 div(style = "width: 91%; background: linear-gradient(90deg, #5B6AD4 0%, #8491E8 100%); height: 8px; border-radius: 4px;")
                                             ),
                                             div(class = "ai-compare-confidence", "94% confident")
                                         )
                                  ),
                                  
                                  # Gap indicator
                                  column(2,
                                         div(class = "ai-gap-indicator",
                                             div(class = "ai-gap-label", "Prediction Difference:"),
                                             div(class = "ai-gap-value", "4% gap"),
                                             div(class = "ai-gap-note",
                                                 icon("check-circle", style = "color: #2A8F74; margin-right: 5px;"),
                                                 "Both models strongly agree!"
                                             )
                                         )
                                  ),
                                  
                                  # Sage side
                                  column(5,
                                         div(class = "ai-compare-item sage-compare",
                                             div(class = "ai-compare-model",
                                                 div(class = "ai-compare-icon sage-icon",
                                                     tags$img(src = "wizard.png", style = "width: 26px; height: 26px; object-fit: contain;")
                                                 ),
                                                 div(class = "ai-compare-info",
                                                     div("The Sage"),
                                                     div(class = "ai-compare-subtitle", "Random Forest")
                                                 )
                                             ),
                                             div(class = "ai-compare-prediction", "87%"),
                                             div(class = "ai-compare-bar",
                                                 div(style = "width: 87%; background: linear-gradient(90deg, #1E7A61 0%, #2A8F74 100%); height: 8px; border-radius: 4px;")
                                             ),
                                             div(class = "ai-compare-confidence", "91% confident")
                                         )
                                  )
                                )
                            )
                     )
                   ),
                   
                   # Switch Button
                   div(style = "text-align: center; margin-top: 20px;",
                       actionButton("switch_to_sage",
                                    tagList(icon("exchange-alt"), " Switch to The Sage"),
                                    class = "ai-switch-btn",
                                    style = "background: white; color: #1E7A61; padding: 12px 30px; border-radius: 12px; border: none; font-weight: 600; cursor: pointer; box-shadow: 0 4px 12px rgba(0,0,0,0.1);")
                   )
               ),
               
               # The Sage's Analysis (shown when Sage selected)
               div(id = "sage_analysis", class = "ai-analysis-panel sage-panel",
                   
                   # Panel Header
                   div(class = "ai-analysis-header",
                       div(class = "ai-analysis-icon sage-icon",
                           tags$img(src = "wizard.png", style = "width: 32px; height: 32px; object-fit: contain;")
                       ),
                       div(class = "ai-analysis-title",
                           "The Sage's Analysis",
                           tags$br(),
                           tags$span(class = "ai-analysis-subtitle", "Random Forest Deep Dive")
                       )
                   ),
                   
                   fluidRow(
                     # Left: Prediction Details
                     column(6,
                            div(class = "ai-detail-box sage-detail",
                                div(class = "ai-detail-header",
                                    icon("bullseye", style = "margin-right: 8px;"),
                                    "Prediction Details"
                                ),
                                div(class = "ai-detail-list",
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("rocket", style = "margin-right: 8px;"),
                                            "Funding Pace"
                                        ),
                                        div(class = "ai-detail-value", "+19%")
                                    ),
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("smile", style = "margin-right: 8px;"),
                                            "Sentiment Score"
                                        ),
                                        div(class = "ai-detail-value", "68%")
                                    ),
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("bolt", style = "margin-right: 8px;"),
                                            "Activity Level"
                                        ),
                                        div(class = "ai-detail-value", "2.8x avg")
                                    ),
                                    div(class = "ai-detail-item",
                                        div(class = "ai-detail-label",
                                            icon("chart-line", style = "margin-right: 8px;"),
                                            "Category Success"
                                        ),
                                        div(class = "ai-detail-value", "71% rate")
                                    )
                                )
                            )
                     ),
                     
                     # Right: Top Success Factors
                     column(6,
                            div(class = "ai-detail-box sage-detail",
                                div(class = "ai-detail-header",
                                    icon("fire", style = "margin-right: 8px;"),
                                    "Top Success Factors"
                                ),
                                uiOutput("sage_factors_ui")
                            )
                     )
                   ),
                   
                   # Comparison Section (reversed)
                   fluidRow(
                     column(12,
                            div(class = "ai-comparison-box sage-comparison",
                                div(class = "ai-comparison-header",
                                    icon("balance-scale", style = "margin-right: 8px;"),
                                    "The Sage vs The Oracle"
                                ),
                                
                                fluidRow(
                                  # Sage side
                                  column(5,
                                         div(class = "ai-compare-item sage-compare",
                                             div(class = "ai-compare-model",
                                                 div(class = "ai-compare-icon sage-icon",
                                                     tags$img(src = "wizard.png", style = "width: 26px; height: 26px; object-fit: contain;")
                                                 ),
                                                 div(class = "ai-compare-info",
                                                     div("The Sage"),
                                                     div(class = "ai-compare-subtitle", "Random Forest")
                                                 )
                                             ),
                                             div(class = "ai-compare-prediction", "87%"),
                                             div(class = "ai-compare-bar",
                                                 div(style = "width: 87%; background: linear-gradient(90deg, #1E7A61 0%, #2A8F74 100%); height: 8px; border-radius: 4px;")
                                             ),
                                             div(class = "ai-compare-confidence", "91% confident")
                                         )
                                  ),
                                  
                                  # Gap indicator
                                  column(2,
                                         div(class = "ai-gap-indicator",
                                             div(class = "ai-gap-label", "Prediction Difference:"),
                                             div(class = "ai-gap-value", "4% gap"),
                                             div(class = "ai-gap-note",
                                                 icon("check-circle", style = "color: #2A8F74; margin-right: 5px;"),
                                                 "Both models strongly agree!"
                                             )
                                         )
                                  ),
                                  
                                  # Oracle side
                                  column(5,
                                         div(class = "ai-compare-item oracle-compare",
                                             div(class = "ai-compare-model",
                                                 div(class = "ai-compare-icon oracle-icon",
                                                     tags$img(src = "crystalBall.png", style = "width: 26px; height: 26px; object-fit: contain;")
                                                 ),
                                                 div(class = "ai-compare-info",
                                                     div("The Oracle"),
                                                     div(class = "ai-compare-subtitle", "KNN Classifier")
                                                 )
                                             ),
                                             div(class = "ai-compare-prediction", "91%"),
                                             div(class = "ai-compare-bar",
                                                 div(style = "width: 91%; background: linear-gradient(90deg, #5B6AD4 0%, #8491E8 100%); height: 8px; border-radius: 4px;")
                                             ),
                                             div(class = "ai-compare-confidence", "94% confident")
                                         )
                                  )
                                )
                            )
                     )
                   ),
                   
                   # Switch Button
                   div(style = "text-align: center; margin-top: 20px;",
                       actionButton("switch_to_oracle",
                                    tagList(icon("exchange-alt"), " Switch to The Oracle"),
                                    class = "ai-switch-btn",
                                    style = "background: white; color: #5B6AD4; padding: 12px 30px; border-radius: 12px; border: none; font-weight: 600; cursor: pointer; box-shadow: 0 4px 12px rgba(0,0,0,0.1);")
                   )
               )
        )
      )
  )
}