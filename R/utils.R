readRDS_or_return_alt_data <- function(filepath, alt_return = NULL) {
  if (file.exists(filepath)) {
    return(readRDS(filepath))
  }
  alt_return
}

add_inv_and_port_names_if_needed <- function(data) {
  if (!inherits(data, "data.frame")) {
    return(data)
  }

  if (!"portfolio_name" %in% names(data)) {
    data <- mutate(data, portfolio_name = cfg$portfolio_name, .before = everything())
  }

  if (!"investor_name" %in% names(data)) {
    data <- mutate(data, investor_name = cfg$investor_name, .before = everything())
  }

  data
}
