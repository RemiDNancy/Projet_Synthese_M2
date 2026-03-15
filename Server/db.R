library(DBI)
library(RMySQL)

# Supprime globalement les warnings de conversion DECIMAL → numeric
options(RMySQL.bigint = "numeric")

# ============================================================================
# db.R
# Connexions MySQL : base_traitee (DWH) + kickstarter (BDD source)
# ============================================================================

# Connexion DWH principal (base_traitee)
get_db_connection <- function() {
  DBI::dbConnect(
    RMySQL::MySQL(),
    host     = "127.0.0.1",
    port     = 3306,
    dbname   = "base_traitee",
    user     = Sys.getenv("MYSQL_USER", "root"),
    password = "snow1998"
  )
}

# Connexion BDD source (kickstarter) — pour rewards, current_state
get_ks_connection <- function() {
  DBI::dbConnect(
    RMySQL::MySQL(),
    host     = "127.0.0.1",
    port     = 3306,
    dbname   = "kickstarter",
    user     = Sys.getenv("MYSQL_USER", "root"),
    password = "snow1998"
  )
}

# Wrapper sécurisé : reconnecte si la connexion est invalide
safe_dbGetQuery <- function(con, sql) {
  if (!DBI::dbIsValid(con)) {
    try(DBI::dbDisconnect(con), silent = TRUE)
    con <- get_db_connection()
  }
  suppressWarnings(DBI::dbGetQuery(con, sql))
  #DBI::dbGetQuery(con, sql)
}

# Fermeture propre d'une connexion
close_db_connection <- function(con) {
  if (!is.null(con) && dbIsValid(con)) {
    dbDisconnect(con)
  }
}

# Test de connexion (optionnel — affiche un message de confirmation)
test_db_connection <- function() {
  con <- get_db_connection()
  if (dbIsValid(con)) {
    message("Database connection successful!")
    close_db_connection(con)
    return(TRUE)
  } else {
    message("Database connection failed!")
    return(FALSE)
  }
}
