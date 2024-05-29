readRDS_or_return_alt_data <- function(filepath, alt_return = NULL) {
  if (file.exists(filepath)) {
    return(readRDS(filepath))
  }
  alt_return
}

add_inv_and_port_names_if_needed <- function(data, portfolio_name, investor_name) {
  if (!inherits(data, "data.frame")) {
    return(data)
  }

  if (!"portfolio_name" %in% names(data)) {
    data <- dplyr::mutate(data, portfolio_name = portfolio_name, .before = dplyr::everything())
  }

  if (!"investor_name" %in% names(data)) {
    data <- dplyr::mutate(data, investor_name = investor_name, .before = dplyr::everything())
  }

  data
}
