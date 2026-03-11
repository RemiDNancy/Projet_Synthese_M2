# ============================================================================
# AI Insights tab server logic - Simple placeholder version
# ============================================================================
ai_server <- function(input, output, session, current_project) {
  
  # Track which AI model is currently selected
  active_ai_model <- reactiveVal("oracle")
  
  # ============================================================================
  # MODEL SWITCHING LOGIC
  # ============================================================================
  
  # Switch to Oracle
  observeEvent(input$switch_to_oracle, {
    active_ai_model("oracle")
    shinyjs::runjs("
      $('#oracle_card').addClass('active');
      $('#sage_card').removeClass('active');
      $('#oracle_analysis').addClass('active');
      $('#sage_analysis').removeClass('active');
    ")
  })
  
  # Switch to Sage
  observeEvent(input$switch_to_sage, {
    active_ai_model("sage")
    shinyjs::runjs("
      $('#sage_card').addClass('active');
      $('#oracle_card').removeClass('active');
      $('#sage_analysis').addClass('active');
      $('#oracle_analysis').removeClass('active');
    ")
  })
  
  # Direct card click switching
  observeEvent(input$selected_ai_model, {
    if (input$selected_ai_model == "oracle") {
      active_ai_model("oracle")
      shinyjs::runjs("
        $('#oracle_card').addClass('active');
        $('#sage_card').removeClass('active');
        $('#oracle_analysis').addClass('active');
        $('#sage_analysis').removeClass('active');
      ")
    } else if (input$selected_ai_model == "sage") {
      active_ai_model("sage")
      shinyjs::runjs("
        $('#sage_card').addClass('active');
        $('#oracle_card').removeClass('active');
        $('#sage_analysis').addClass('active');
        $('#oracle_analysis').removeClass('active');
      ")
    }
  })
  
  # ============================================================================
  # THE ORACLE - PLACEHOLDER DATA
  # ============================================================================
  
  output$oracle_prediction <- renderText({ "91%" })
  output$oracle_pattern <- renderText({ "95%" })
  output$oracle_accuracy <- renderText({ "89%" })
  output$oracle_neighbor <- renderText({ "92%" })
  
  # ============================================================================
  # THE SAGE - PLACEHOLDER DATA
  # ============================================================================
  
  output$sage_prediction <- renderText({ "87%" })
  output$sage_multifactor <- renderText({ "93%" })
  output$sage_robustness <- renderText({ "90%" })
  output$sage_feature <- renderText({ "94%" })
  
}