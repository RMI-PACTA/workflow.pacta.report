read_rds_or_return_alt_data <- function(filepath, alt_return = NULL) {
  log_trace("Reading RDS file: \"filepath\"")
  if (file.exists(filepath)) {
    log_trace("File found. Reading data.")
    data <- readRDS(filepath)
  } else {
    log_warn("File not found. Returning alternative data.")
    data <- alt_return
  }
  return(data)
}

add_inv_and_port_names_if_needed <- function(data, portfolio_name, investor_name) {
  if (!inherits(data, "data.frame")) {
    return(data)
  }

  if (!"portfolio_name" %in% names(data)) {
    log_trace("Adding portfolio_name column to data.")
    data <- dplyr::mutate(data, portfolio_name = portfolio_name, .before = dplyr::everything())
  }

  if (!"investor_name" %in% names(data)) {
    log_trace("Adding investor_name column to data.")
    data <- dplyr::mutate(data, investor_name = investor_name, .before = dplyr::everything())
  }

  data
}
