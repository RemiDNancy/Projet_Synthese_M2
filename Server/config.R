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
        p.project_id,
        p.title,
        p.category,
        p.subcategory AS category_sub,
        p.url,
        p.image_url,
        p.goal_amount,
        p.currency AS goal_currency,
        p.is_project_we_love,
        p.created_at AS launched_at,
        p.deadline_at,
        p.location AS country,
        c.creator_name,
        pe.pledged_amount,
        pe.backers_count,
        pe.percent_funded,
        pe.current_state,
        pe.scrap_date
      FROM PROJECT p
      INNER JOIN CREATOR c ON p.id_creator = c.creator_id
      INNER JOIN (
        SELECT
          project_id,
          pledged_amount,
          backers_count,
          percent_funded,
          current_state,
          scrap_date
        FROM PROJECT_EVOLUTION pe1
        WHERE scrap_date = (
          SELECT MAX(scrap_date)
          FROM PROJECT_EVOLUTION pe2
          WHERE pe2.project_id = pe1.project_id
        )
      ) pe ON p.project_id = pe.project_id
      ORDER BY p.project_id
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

    # Normalize state to Title Case regardless of DB casing
    projects_raw$status <- sapply(projects_raw$current_state, function(state) {
      tools::toTitleCase(tolower(trimws(as.character(state))))
    })

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
  con <- get_db_connection()
  
  tryCatch({
    # Get base reward info
    query_rewards <- sprintf("
      SELECT 
        r.reward_id,
        r.reward_name AS name,
        r.price_amount AS price,
        r.estimated_delivery AS delivery,
        p.currency AS symbol
      FROM REWARD r
      INNER JOIN PROJECT p ON r.project_id = p.project_id
      WHERE r.project_id = %d
      ORDER BY r.price_amount DESC
    ", project_id)
    
    rewards <- dbGetQuery(con, query_rewards)
    
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
    
    evolution <- dbGetQuery(con, query_evolution)
    
    # Merge rewards with evolution data
    rewards <- merge(rewards, evolution, by = "reward_id", all.x = TRUE)
    rewards$backers[is.na(rewards$backers)] <- 0
    
    # Calculate revenue
    rewards$revenue <- rewards$price * rewards$backers
    
    # Convert currency codes to symbols
    rewards$symbol <- sapply(rewards$symbol, map_symbol)

    # Create price_label
    rewards$price_label <- paste0(rewards$symbol, formatC(rewards$price, format = "f", digits = 0, big.mark = ","))
    
    # Select and order columns
    rewards <- rewards[, c("name", "price", "price_label", "backers", "revenue", "delivery", "symbol")]
    
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

# Filter choices derived from real data
category_choices <- c("All categories", sort(unique(sample_projects$category)))
status_choices <- c("All statuses", sort(unique(sample_projects$status)))
country_choices <- c("All countries", sort(unique(sample_projects$country)))

# ============================================================================
# Sample time-series data (no corresponding data in database yet)
# ============================================================================
funding_data <- data.frame(
  date = c("02/02", "02/09", "02/16", "02/23", "03/02", "03/09"),
  progress = c(8000, 12000, 18000, 26000, 32000, 34000),
  average = c(10000, 13000, 16000, 19000, 22000, 24000),
  goal = rep(40000, 6),
  stringsAsFactors = FALSE
)

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