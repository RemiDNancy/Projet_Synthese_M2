# ============================================================================
# Color palette and project data parsed from test.json
# ============================================================================

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
# Parse real Kickstarter data from test.json
# ============================================================================
us_states <- c("AL","AK","AZ","AR","CA","CO","CT","DE","FL","GA","HI","ID",
               "IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS",
               "MO","MT","NE","NV","NH","NJ","NM","NY","NC","ND","OH","OK",
               "OR","PA","RI","SC","SD","TN","TX","UT","VT","VA","WA","WV","WI","WY")

extract_country <- function(location) {
  parts <- trimws(strsplit(location, ",")[[1]])
  region <- parts[length(parts)]
  if (region %in% us_states) return("USA")
  return(region)
}

raw_data <- jsonlite::fromJSON("test.json", simplifyDataFrame = FALSE)

seen_pids <- c()
projects_list <- list()
for (item in raw_data) {
  if (!"project" %in% names(item)) next
  p <- item$project
  if (p$pid %in% seen_pids) next
  seen_pids <- c(seen_pids, p$pid)

  state_map <- c("LIVE" = "Live", "SUCCESSFUL" = "Successful", "FAILED" = "Failed", "CANCELED" = "Canceled")
  status <- ifelse(p$state %in% names(state_map), state_map[[p$state]], p$state)

  projects_list[[length(projects_list) + 1]] <- data.frame(
    project_id = p$pid,
    title = p$name,
    category = p$category$parentCategory$name,
    category_sub = p$category$name,
    status = status,
    percent_funded = p$percentFunded,
    image_url = p$imageUrl,
    creator_name = item$creator$name,
    is_project_we_love = p$isProjectWeLove,
    url = p$url,
    goal_amount = as.numeric(p$goal$amount),
    goal_symbol = p$goal$symbol,
    pledged_amount = as.numeric(p$pledged$amount),
    pledged_symbol = p$pledged$symbol,
    backers_count = p$backersCount,
    deadline_at = p$deadlineAt,
    launched_at = p$stateChangedAt,
    country = extract_country(p$location$displayableName),
    stringsAsFactors = FALSE
  )
}

sample_projects <- do.call(rbind, projects_list)

# Filter choices derived from real data
category_choices <- c("All categories", sort(unique(sample_projects$category)))
status_choices <- c("All statuses", sort(unique(sample_projects$status)))
country_choices <- c("All countries", sort(unique(sample_projects$country)))

# ============================================================================
# Sample time-series data (no corresponding data in JSON)
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
