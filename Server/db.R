library(DBI)
library(RMySQL)

# ============================================================================
# Database connection function
# ============================================================================
get_db_connection <- function() {
  DBI::dbConnect(
    RMySQL::MySQL(),
    host = "127.0.0.1",
    port = 3306,
    dbname = "kickstarter",
    user = Sys.getenv("MYSQL_USER", "root"),
    password = "snow1998"
  )
}

safe_dbGetQuery <- function(con, sql) {
  if (!DBI::dbIsValid(con)) {
    try(DBI::dbDisconnect(con), silent = TRUE)
    con <- get_db_connection()
  }
  DBI::dbGetQuery(con, sql)
}

# ============================================================================
# Function to close database connection
# ============================================================================
close_db_connection <- function(con) {
  if (!is.null(con) && dbIsValid(con)) {
    dbDisconnect(con)
  }
}

# ============================================================================
# Test connection (optional - will print success message)
# ============================================================================
test_db_connection <- function() {
  con <- get_db_connection()
  if (dbIsValid(con)) {
    message("✓ Database connection successful!")
    close_db_connection(con)
    return(TRUE)
  } else {
    message("✗ Database connection failed!")
    return(FALSE)
  }
}
