#' Prepare an Executive Summary PDF
#'
#' Run the required steps to prepare an executive summary from existing
#' analysis results.
#'
#' @param summary_output_dir Directory where the executive summary will be
#' saved.
#' @param survey_dir Directory containing survey data.
#' @param real_estate_dir Directory containing real estate data.
#' @param score_card_dir Directory containing score card data.
#' @param project_code Project code, defining the template to use.
#' @param language_select Language to use for the executive summary.
#' @param peer_group Investor's Peer group.
#' @param investor_name Investor's name.
#' @param portfolio_name Portfolio's name.
#' @param start_year Start year of the analysis.
#' @param currency_exchange_value Exchange value from Display cyurrency to USD.
#' @param total_portfolio Data frame with the total portfolio information.
#' @param equity_results_portfolio Data frame with the equity results for the
#' portfolio.
#' @param bonds_results_portfolio Data frame with the bonds results for the
#' portfolio.
#' @param indices_equity_results_portfolio Data frame with the equity results
#' for the indices (benchmarks).
#' @param indices_bonds_results_portfolio Data frame with the bonds results for
#' the indices (benchmarks).
#' @param audit_file Audit file.
#' @param emissions Emissions data.
#' @param peers_bonds_results_portfolio Data frame with the portfolio-level
#' bonds results for the peers.
#' @param peers_bonds_results_user Data frame with the user-level bonds results
#' for the peers.
#' @param peers_equity_results_portfolio Data frame with the portfolio-level
#' equity results for the peers.
#' @param peers_equity_results_user Data frame with the user-level equity
#' results for the peers.
#' @return List of manifest information, suitable for use in
#' `pacta.workflow.utils::export_manifest`.
#' @export
prepare_executive_summary <- function(
  summary_output_dir,
  survey_dir,
  real_estate_dir,
  score_card_dir,
  project_code,
  language_select,
  peer_group,
  investor_name,
  portfolio_name,
  start_year,
  currency_exchange_value,
  total_portfolio,
  equity_results_portfolio,
  bonds_results_portfolio,
  indices_equity_results_portfolio,
  indices_bonds_results_portfolio,
  audit_file,
  emissions,
  peers_bonds_results_portfolio,
  peers_bonds_results_user,
  peers_equity_results_portfolio,
  peers_equity_results_user
) {
  log_debug("Preparing to create executive summary.")

  es_dir <- file.path(summary_output_dir, "executive_summary")
  if (!dir.exists(es_dir)) {
    dir.create(es_dir, showWarnings = FALSE, recursive = TRUE)
  }

  log_trace("Defining executive summary template paths.")
  exec_summary_template_name <- paste0(project_code, "_", tolower(language_select), "_exec_summary")
  exec_summary_builtin_template_path <- system.file(
    "extdata", exec_summary_template_name,
    package = "pacta.executive.summary"
  )
  invisible(file.copy(exec_summary_builtin_template_path, summary_output_dir, recursive = TRUE, copy.mode = FALSE))
  exec_summary_template_path <- file.path(summary_output_dir, exec_summary_template_name)

  if (
    dir.exists(exec_summary_template_path) && (
      peer_group %in% c("assetmanager", "bank", "insurance", "pensionfund")
    )
  ) {
    log_debug("Preparing data for executive summary.")
    data_aggregated_filtered <-
      pacta.executive.summary::prep_data_executive_summary(
        investor_name = investor_name,
        portfolio_name = portfolio_name,
        peer_group = peer_group,
        start_year = start_year,
        scenario_source = "GECO2021",
        scenario_selected = "1.5C-Unif",
        scenario_geography = "Global",
        equity_market = "GlobalMarket",
        portfolio_allocation_method_equity = "portfolio_weight",
        portfolio_allocation_method_bonds = "portfolio_weight",
        green_techs = c(
          "RenewablesCap",
          "HydroCap",
          "NuclearCap",
          "Hybrid",
          "Electric",
          "FuelCell",
          "Hybrid_HDV",
          "Electric_HDV",
          "FuelCell_HDV",
          "Electric Arc Furnace"
        ),
        equity_results_portfolio = equity_results_portfolio,
        bonds_results_portfolio = bonds_results_portfolio,
        peers_equity_results_aggregated = peers_equity_results_portfolio,
        peers_bonds_results_aggregated = peers_bonds_results_portfolio,
        peers_equity_results_individual = peers_equity_results_user,
        peers_bonds_results_individual = peers_bonds_results_user,
        indices_equity_results_portfolio = indices_equity_results_portfolio,
        indices_bonds_results_portfolio = indices_bonds_results_portfolio,
        audit_file = audit_file,
        emissions_portfolio = emissions,
        score_card_dir = score_card_dir
      )

    log_trace("Checking for real estate data.")
    real_estate_flag <- (length(list.files(real_estate_dir)) > 0)

    log_info("Creating executive summary.")
    pacta.executive.summary::render_executive_summary(
      data = data_aggregated_filtered,
      language = language_select,
      output_dir = es_dir,
      exec_summary_dir = exec_summary_template_path,
      survey_dir = survey_dir,
      real_estate_dir = real_estate_dir,
      real_estate_flag = real_estate_flag,
      score_card_dir = score_card_dir,
      file_name = "template.Rmd",
      investor_name = investor_name,
      portfolio_name = portfolio_name,
      peer_group = peer_group,
      total_portfolio = total_portfolio,
      scenario_selected = "1.5C-Unif",
      currency_exchange_value = currency_exchange_value,
      log_dir = summary_output_dir
    )
  } else {
    # this is required for the online tool to know that the process has been completed.
    log_debug("No executive summary created.")
    invisible(file.copy(pacta.executive.summary::blank_pdf(), es_dir))
  }
}
