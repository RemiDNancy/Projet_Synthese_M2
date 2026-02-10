# ============================================================================
# FUNCTION: Get the color based on the status ("successful", "live", "failed")
# ============================================================================
get_status_color <- function(status) {
  status_colors <- c(
    "successful" = colors$success,
    "live" = colors$live,
    "failed" = colors$danger,
    "canceled" = colors$danger
  )
  return(status_colors[tolower(status)])
}
