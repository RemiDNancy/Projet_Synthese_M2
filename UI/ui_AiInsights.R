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
                           div(class = "ai-metric-label", "Precision"),
                           div(class = "ai-metric-value", textOutput("oracle_pattern", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Accuracy"),
                           div(class = "ai-metric-value", textOutput("oracle_accuracy", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Recall"),
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
                           div(class = "ai-metric-label", "F1 Score"),
                           div(class = "ai-metric-value", textOutput("sage_multifactor", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Recall"),
                           div(class = "ai-metric-value", textOutput("sage_robustness", inline = TRUE))
                       ),
                       div(class = "ai-metric-item",
                           div(class = "ai-metric-label", "Precision"),
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
                   
                   # Comparison Section
                   fluidRow(
                     column(12,
                            div(class = "ai-comparison-box oracle-comparison",
                                div(class = "ai-comparison-header",
                                    icon("balance-scale", style = "margin-right: 8px;"),
                                    "Model Comparison"
                                ),
                                div(style = "display:flex;align-items:center;justify-content:space-around;padding:20px 0;",

                                    div(style = "text-align:center;",
                                        tags$img(src = "crystalBall.png", style = "width:80px;height:80px;object-fit:contain;margin-bottom:10px;"),
                                        div(style = "font-weight:700;font-size:15px;color:#2C3E50;", "The Oracle"),
                                        div(style = "font-size:12px;color:#6B7280;", "KNN Classifier")
                                    ),

                                    div(class = "ai-gap-indicator",
                                        div(class = "ai-gap-label", "Prediction Difference"),
                                        div(class = "ai-gap-value", "4% gap")
                                    ),

                                    div(style = "text-align:center;",
                                        tags$img(src = "wizard.png", style = "width:80px;height:80px;object-fit:contain;margin-bottom:10px;"),
                                        div(style = "font-weight:700;font-size:15px;color:#2C3E50;", "The Sage"),
                                        div(style = "font-size:12px;color:#6B7280;", "Random Forest")
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
                   
                   # Top Success Factors — full width, real data from Fait_detail_facteurs
                   fluidRow(
                     column(12,
                            div(class = "ai-detail-box sage-detail",
                                div(class = "ai-detail-header",
                                    icon("fire", style = "margin-right: 8px;"),
                                    "Top Success Factors",
                                    tags$span(style = "font-size:12px;color:#6B7280;margin-left:10px;font-weight:400;",
                                              "(Random Forest feature importance)")
                                ),
                                uiOutput("sage_factors_ui")
                            )
                     )
                   ),

                   # Comparison Section
                   fluidRow(
                     column(12,
                            div(class = "ai-comparison-box sage-comparison",
                                div(class = "ai-comparison-header",
                                    icon("balance-scale", style = "margin-right: 8px;"),
                                    "Model Comparison"
                                ),
                                div(style = "display:flex;align-items:center;justify-content:space-around;padding:20px 0;",

                                    div(style = "text-align:center;",
                                        tags$img(src = "wizard.png", style = "width:80px;height:80px;object-fit:contain;margin-bottom:10px;"),
                                        div(style = "font-weight:700;font-size:15px;color:#2C3E50;", "The Sage"),
                                        div(style = "font-size:12px;color:#6B7280;", "Random Forest")
                                    ),

                                    div(class = "ai-gap-indicator",
                                        div(class = "ai-gap-label", "Prediction Difference"),
                                        div(class = "ai-gap-value", "4% gap")
                                    ),

                                    div(style = "text-align:center;",
                                        tags$img(src = "crystalBall.png", style = "width:80px;height:80px;object-fit:contain;margin-bottom:10px;"),
                                        div(style = "font-weight:700;font-size:15px;color:#2C3E50;", "The Oracle"),
                                        div(style = "font-size:12px;color:#6B7280;", "KNN Classifier")
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