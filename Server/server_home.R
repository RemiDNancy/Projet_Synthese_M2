# ============================================================================
# Logique serveur de la page Home (Projects list) + Filters
# ============================================================================
home_server <- function(input, output, session, selected_project_id) {

  
  
  # ── Filtrage réactif des projets ──────────────────────────────────────────
  
  # sample_projects est chargé au démarrage dans config.R depuis base_traitee
  # Les filtres (categorie, statut, pays, recherche) sont mis à jour en temps réel
  filtered_projects <- reactive({
    projects <- sample_projects    

    # Filtre par categorie
    if (input$filter_category != "All categories") {
      projects <- projects[projects$category == input$filter_category, ]
    }
    # Filtre par statues
    if (input$filter_status != "All statuses") {
      projects <- projects[tolower(projects$status) == tolower(input$filter_status), ]
    }
    # Filtre par pays
    if (input$filter_country != "All countries") {
      projects <- projects[projects$country == input$filter_country, ]
    }
    # Recherche par titre (insensible à la casse)
    if (!is.null(input$search_project) && input$search_project != "") {
      projects <- projects[grepl(input$search_project, projects$title, ignore.case = TRUE), ]
    }

    return(projects)
  })

  # ── Rendu de la grille de projets ─────────────────────────────────────────
  # Affiche les projets sous forme de cards (2 par ligne)
  # Chaque card montre : image, titre, catégorie, statut, barre de progression
  output$projects_grid <- renderUI({
    projects <- filtered_projects()
    
    # Message si aucun projet ne correspond aux filtres
    if (nrow(projects) == 0) {
      return(
        div(style = "text-align: center; padding: 40px; color: #95A5A6;",
            icon("search", class = "fa-3x"),
            h3("No projects found"),
            p("Try adjusting your filters")
        )
      )
    }
    
    # Création des cards projet
    project_cards <- lapply(1:nrow(projects), function(i) {
      project <- projects[i, ]

      # Couleur de la barre de progression selon le taux de financement
      if (project$percent_funded >= 100) {
        bar_color <- colors$success          # vert : objectif atteint
      } else if (project$percent_funded >= 50) {
        bar_color <- colors$live             # bleu : en bonne voie
      } else {
        bar_color <- colors$danger           # rouge : failed ou cancelled
      }
      
      # Couleur du badge de statut (définie dans functions.R)
      status_color <- get_status_color(project$status)

      column(width = 6,
             div(class = "project-card",
                 
                 # Clic sur la card -> ouverture de la vue détail du projet
                 onclick = sprintf("Shiny.setInputValue('selected_project', %d, {priority: 'event'})",
                                   project$project_id),
                 tags$img(src = project$image_url,
                          style = "width: 120px; height: 120px; border-radius: 8px; object-fit: cover; margin-bottom: 10px;"),
                 div(class = "project-title", project$title),
                 div(class = "project-category", project$category),
                 div(class = "project-status", style = sprintf("color: %s;", status_color), project$status),
                 
                 # Barre de progression (plafonnée à 100% visuellement)
                 div(class = "progress-bar-container",
                     div(class = "progress-bar-fill",
                         style = sprintf("width: %s%%; background: %s;",
                                         min(project$percent_funded, 100), bar_color))
                 ),
                 # Pourcentage affiché pour un projet
                 div(class = "progress-percent", sprintf("%.1f%%", project$percent_funded))
             )
      )
    })
    
    # Mise en page : 2 cards par ligne
    rows <- list()
    for (i in seq(1, length(project_cards), by = 2)) {
      if (i + 1 <= length(project_cards)) {
        rows[[length(rows) + 1]] <- fluidRow(project_cards[[i]], project_cards[[i + 1]])
      } else {
        rows[[length(rows) + 1]] <- fluidRow(project_cards[[i]])
      }
    }

    return(tagList(rows))
  })

  # ── Navigation vers la vue détail ─────────────────────────────────────────
  # Quand l'utilisateur clique sur une card :
  # 1. Met à jour l'ID du projet sélectionné (partagé avec dashboard_server)
  # 2. Cache la liste et affiche la vue détail
  observeEvent(input$selected_project, {
    selected_project_id(input$selected_project)
    shinyjs::hide(id = "projects_list_view")
    shinyjs::show(id = "project_detail_view")
  })



}
