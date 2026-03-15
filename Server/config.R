# ============================================================================
# Color palette and project data from MySQL database
# ============================================================================

# Source database connection file (with explicit path handling)
if (file.exists("Server/db.R")) {
  source("Server/db.R")
} else if (file.exists("db.R")) {
  source("db.R")
} else {
  stop("Cannot find db.R file. Please ensure it exists in the Server/ directory.")
}

colors <- list(
  primary = "#667EEA",
  secondary = "#764BA2",
  dark = "#2C3E50",
  success = "#05CE78",
  live = "#3498DB",
  warning = "#F39C12",
  danger = "#E74C3C",
  bg_light = "#F8F9FA",
  border = "#E0E0E0",
  text_gray = "#95A5A6",
  indigo_light = "#A5B4F7",
  purple_light = "#C084FC",
  green_light = "#86EFAC",
  blue_light = "#93C5FD",
  red_light = "#FCA5A5"
)

# ============================================================================
# Currency code to symbol mapping
# ============================================================================
currency_to_symbol <- c(
  "USD" = "$", "EUR" = "\u20AC", "GBP" = "\u00A3", "CAD" = "CA$",
  "AUD" = "A$", "JPY" = "\u00A5", "CHF" = "CHF ", "SEK" = "kr ",
  "NOK" = "kr ", "DKK" = "kr ", "NZD" = "NZ$", "MXN" = "MX$",
  "SGD" = "S$", "HKD" = "HK$"
)

eur_rates <- c(
  "EUR" = 1.0000,
  "USD" = 0.9200,
  "GBP" = 1.1700,
  "CAD" = 0.6800,
  "AUD" = 0.5900,
  "JPY" = 0.0062,
  "CHF" = 1.0400,
  "SEK" = 0.0880,
  "NOK" = 0.0850,
  "DKK" = 0.1340,
  "NZD" = 0.5400,
  "MXN" = 0.0460,
  "SGD" = 0.6800,
  "HKD" = 0.1180
)

convert_to_eur <- function(amount, currency) {
  rate <- eur_rates[toupper(trimws(currency))]
  if (is.na(rate)) return(amount)  # fallback si devise inconnue
  return(round(amount * rate, 0))
}

map_symbol <- function(code) {
  sym <- currency_to_symbol[toupper(trimws(code))]
  ifelse(is.na(sym), paste0(code, " "), sym)
}

# ============================================================================
# Fetch projects from database
# ============================================================================
fetch_projects_from_db <- function() {
  con <- get_db_connection()
  
  tryCatch({
    # Query to get projects with their latest evolution data and creator info
    query <- "
    SELECT
      p.id_projet        AS project_id,
      p.titre_projet     AS title,
      c.nom_categorie    AS category,
      c.nom_categorie_mere AS category_sub,
      p.url,
      p.url_image        AS image_url,
      p.objectif_financement AS goal_amount,
      p.devise           AS goal_currency,
      p.is_project_we_love,
      p.date_creation    AS launched_at,
      p.date_deadline    AS deadline_at,
      l.pays             AS country,
      cr.nom_createur    AS creator_name,
      fps.montant_collecte   AS pledged_amount,
      fps.nombre_contributeurs AS backers_count,
      fps.ratio_financement  AS percent_funded,
      fps.id_date_collecte   AS scrap_date
    FROM Projet p
    LEFT JOIN Fait_projet_snapshot fps ON p.id_projet = fps.id_projet
    LEFT JOIN Createur cr ON fps.id_createur = cr.id_createur
    LEFT JOIN Categorie c ON fps.categorie = c.nom_categorie
    LEFT JOIN Localisation l ON fps.localisation = l.id_localisation
    WHERE fps.id_date_collecte = (
      SELECT MAX(fps2.id_date_collecte)
      FROM Fait_projet_snapshot fps2
      WHERE fps2.id_projet = p.id_projet
    )
    ORDER BY p.id_projet
  "
    
    projects_raw <- safe_dbGetQuery(con, query)
    
    if (nrow(projects_raw) == 0) return(data.frame())
    
    # Convert currency codes to display symbols
    projects_raw$goal_symbol <- sapply(projects_raw$goal_currency, map_symbol)
    
    # Pledged symbol: fall back to goal currency if missing
    projects_raw$goal_currency <- ifelse(
      is.na(projects_raw$goal_currency) | projects_raw$goal_currency == "",
      projects_raw$goal_currency,
      projects_raw$goal_currency
    )
    projects_raw$pledged_symbol <- sapply(projects_raw$goal_currency, map_symbol)
    
    # Convert timestamps to numeric (epoch seconds)
    projects_raw$launched_at <- as.numeric(as.POSIXct(projects_raw$launched_at))
    projects_raw$deadline_at <- as.numeric(as.POSIXct(projects_raw$deadline_at))
    
    # Ensure is_project_we_love is logical
    projects_raw$is_project_we_love <- as.logical(projects_raw$is_project_we_love)
    
    # Ensure numeric types
    projects_raw$goal_amount <- as.numeric(projects_raw$goal_amount)
    projects_raw$pledged_amount <- as.numeric(projects_raw$pledged_amount)
    projects_raw$backers_count <- as.integer(projects_raw$backers_count)
    projects_raw$percent_funded <- as.numeric(projects_raw$percent_funded)
    
    # Dérivation du statut depuis base_traitee uniquement
    # Logique : deadline non passée           → Live
    #           deadline passée + collecte >= objectif → Successful
    #           sinon                         → Failed
    projects_raw$status <- mapply(function(pledged, goal, deadline_ts) {
      if (is.na(pledged) || is.na(goal) || goal <= 0) return("Failed")
      deadline_date <- as.Date(as.POSIXct(deadline_ts, origin = "1970-01-01"))
      deadline_passed <- is.na(deadline_date) || deadline_date < Sys.Date()
      if (!deadline_passed) {
        "Live"
      } else if (pledged >= goal) {
        "Successful"
      } else {
        "Failed"
      }
    }, projects_raw$pledged_amount, projects_raw$goal_amount, projects_raw$deadline_at)
    
    return(projects_raw)
    
  }, error = function(e) {
    message("Error fetching projects: ", e$message)
    return(data.frame())
  }, finally = {
    close_db_connection(con)
  })
}


# ============================================================================
# Fetch rewards for a specific project
# ============================================================================
fetch_rewards_from_db <- function(project_id) {
  con <- get_ks_connection()
  
  tryCatch({
    # Get base reward info
    query_rewards <- sprintf("
      SELECT 
        MIN(r.reward_id) AS reward_id,
        r.reward_name AS name,
        r.price_amount AS price,
        MIN(r.estimated_delivery) AS delivery,
        p.currency AS symbol
      FROM REWARD r
      INNER JOIN PROJECT p ON r.project_id = p.project_id
      WHERE r.project_id = %d
      GROUP BY r.reward_name, r.price_amount, p.currency
      ORDER BY r.price_amount DESC

    ", project_id)
    
    rewards <- suppressWarnings(dbGetQuery(con, query_rewards))
    
    if (nrow(rewards) == 0) {
      return(data.frame(
        name = character(0), 
        price = numeric(0), 
        price_label = character(0),
        backers = integer(0), 
        revenue = numeric(0), 
        delivery = character(0),
        symbol = character(0), 
        stringsAsFactors = FALSE
      ))
    }
    
    # Get latest evolution data for each reward
    reward_ids <- paste(rewards$reward_id, collapse = ",")
    query_evolution <- sprintf("
      SELECT 
        re.reward_id,
        re.backers_on_reward AS backers
      FROM REWARD_EVOLUTION re
      INNER JOIN (
        SELECT reward_id, MAX(scrap_date) AS max_date
        FROM REWARD_EVOLUTION
        WHERE reward_id IN (%s)
        GROUP BY reward_id
      ) latest ON re.reward_id = latest.reward_id 
        AND re.scrap_date = latest.max_date
    ", reward_ids)
    
    evolution <- suppressWarnings(dbGetQuery(con, query_evolution))
    
    # Merge rewards with evolution data
    rewards <- merge(rewards, evolution, by = "reward_id", all.x = TRUE)
    rewards$backers[is.na(rewards$backers)] <- 0
    
    # Calculate revenue
    rewards$revenue <- rewards$price * rewards$backers
    
    rewards$currency_code <- rewards$symbol
    # Convert currency codes to symbols
    rewards$symbol <- sapply(rewards$symbol, map_symbol)
    
    # Create price_label
    rewards$price_label <- paste0(rewards$symbol, formatC(rewards$price, format = "f", digits = 0, big.mark = ","))
    
    # Select and order columns
    rewards <- rewards[, c("name", "price", "price_label", "backers", "revenue", "delivery", "symbol", "currency_code")]
    
    return(rewards)
    
  }, error = function(e) {
    message("Error fetching rewards for project ", project_id, ": ", e$message)
    return(data.frame(
      name = character(0), 
      price = numeric(0), 
      price_label = character(0),
      backers = integer(0), 
      revenue = numeric(0), 
      delivery = character(0),
      symbol = character(0), 
      stringsAsFactors = FALSE
    ))
  }, finally = {
    close_db_connection(con)
  })
}

# ============================================================================
# Load data on startup
# ============================================================================
message("Loading projects from database...")
sample_projects <- fetch_projects_from_db()

if (nrow(sample_projects) == 0) {
  warning("No projects found in database! Please check your database connection and data.")
}

# Build project_rewards list
message("Loading rewards data...")
project_rewards <- list()
unique_project_ids <- unique(sample_projects$project_id)

for (pid in unique_project_ids) {
  pid_key <- as.character(pid)
  project_rewards[[pid_key]] <- fetch_rewards_from_db(pid)
}

# ============================================================================
# Global reward benchmarks (price distribution, tier counts, sweet spot)
# Computed once at startup from already-loaded data — no extra DB query
# ============================================================================
message("Computing global reward benchmarks...")
global_reward_benchmarks <- local({

  # Flatten all rewards with EUR prices + category
  reward_rows <- lapply(names(project_rewards), function(pid) {
    rw <- project_rewards[[pid]]
    if (is.null(rw) || nrow(rw) == 0) return(NULL)
    proj_row <- sample_projects[sample_projects$project_id == suppressWarnings(as.numeric(pid)), ]
    if (nrow(proj_row) == 0) return(NULL)
    data.frame(
      category  = proj_row$category[1],
      price_eur = mapply(convert_to_eur, rw$price, rw$currency_code),
      backers   = as.numeric(rw$backers),
      stringsAsFactors = FALSE
    )
  })
  all_rewards <- do.call(rbind, Filter(Negate(is.null), reward_rows))

  # Tier counts per project with category
  tier_rows <- lapply(names(project_rewards), function(pid) {
    rw <- project_rewards[[pid]]
    if (is.null(rw)) return(NULL)
    proj_row <- sample_projects[sample_projects$project_id == suppressWarnings(as.numeric(pid)), ]
    if (nrow(proj_row) == 0) return(NULL)
    data.frame(category = proj_row$category[1], n_tiers = nrow(rw), stringsAsFactors = FALSE)
  })
  tier_counts <- do.call(rbind, Filter(Negate(is.null), tier_rows))

  list(all_rewards = all_rewards, tier_counts = tier_counts)
})
message(sprintf("  - Benchmarks: %d reward entries across %d projects",
                nrow(global_reward_benchmarks$all_rewards),
                nrow(global_reward_benchmarks$tier_counts)))

# Filter choices derived from real data
category_choices <- c("All categories", sort(unique(sample_projects$category)))
status_choices <- c("All statuses", sort(unique(sample_projects$status)))
country_choices <- c("All countries", sort(unique(sample_projects$country)))

# ============================================================================
# Sample time-series data (no corresponding data in database yet)
# ============================================================================


sentiment_data <- data.frame(
  date = c("02/02", "02/09", "02/16", "02/23", "03/02", "03/09"),
  positive = c(55, 60, 58, 65, 63, 63),
  neutral = c(30, 25, 27, 20, 22, 22),
  negative = c(15, 15, 15, 15, 15, 15),
  stringsAsFactors = FALSE
)

message("✓ Data loaded successfully!")
message(sprintf("  - %d projects loaded", nrow(sample_projects)))
message(sprintf("  - %d reward datasets loaded", length(project_rewards)))