run_pacta_reporting_process <- function(
  raw_params = commandArgs(trailingOnly = TRUE),
  analysis_outputs_dir = Sys.getenv("ANALYSIS_OUTPUTS_DIR"),
  benchmarks_dir = Sys.getenv("BENCHMARKS_DIR"),
  report_output_dir = Sys.getenv("REPORT_OUTPUT_DIR"),
  summary_output_dir = Sys.getenv("SUMMARY_OUTPUT_DIR")
) {

  # defaulting to WARN to maintain current (silent) behavior.
  logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))
  logger::log_formatter(logger::formatter_glue)

  # -------------------------------------------------------------------------

  log_info("Starting portfolio report process")

  log_trace("Determining configuration file path")
  cfg_path <- commandArgs(trailingOnly = TRUE)
  if (length(cfg_path) == 0 || cfg_path == "") {
    log_warn("No configuration file specified, using default")
    cfg_path <- "/workflow.pacta.report/input_dir/default_config.json"
  }
  log_debug("Loading configuration from file: \"{cfg_path}\".")
  cfg <- jsonlite::fromJSON(cfg_path)

  # quit if there's no relevant PACTA assets -------------------------------------

  log_debug("Checking for PACTA relevant data in portfolio results.")
  total_portfolio_path <- file.path(analysis_outputs_dir, "total_portfolio.rds")
  if (file.exists(total_portfolio_path)) {
    total_portfolio <- readRDS(total_portfolio_path)
    log_trace("Checking for PACTA relevant data in file: \"{total_portfolio_path}\".")
    pacta.portfolio.utils::quit_if_no_pacta_relevant_data(total_portfolio)
  } else {
    log_warn("file \"{total_portfolio_path}\" does not exist.")
    warning("This is weird... the `total_portfolio.rds` file does not exist in the `30_Processed_inputs` directory.")
  }


  # fix parameters ---------------------------------------------------------------

  if (cfg$project_code == "GENERAL") {
    log_warn("Overriding language selection to \"EN\" for \"GENERAL\".")
    cfg$language_select <- "EN"
  } else {
    log_trace("Using language selection: \"{cfg$language_select}\".")
  }


  # load PACTA results -----------------------------------------------------------

  log_info("Loading PACTA results.")

  log_debug("Loading audit file.")
  audit_file <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "audit_file.rds"),
    alt_return = pacta.portfolio.utils::empty_audit_file()
  )
  audit_file <- add_inv_and_port_names_if_needed(
    data = audit_file,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading portfolio overview.")
  portfolio_overview <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "overview_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_overview()
  )
  portfolio_overview <- add_inv_and_port_names_if_needed(
    data = portfolio_overview,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading emissions.")
  emissions <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "emissions.rds"),
    alt_return = pacta.portfolio.utils::empty_emissions_results()
  )
  emissions <- add_inv_and_port_names_if_needed(
    data = emissions,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading total portfolio results.")
  total_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "total_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  total_portfolio <- add_inv_and_port_names_if_needed(
    data = total_portfolio,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading portfolio equity results.")
  equity_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "Equity_results_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  equity_results_portfolio <- add_inv_and_port_names_if_needed(
    data = equity_results_portfolio,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading portfolio bonds results.")
  bonds_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "Bonds_results_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  bonds_results_portfolio <- add_inv_and_port_names_if_needed(
    data = bonds_results_portfolio,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading company equity results.")
  equity_results_company <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "Equity_results_company.rds"),
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  equity_results_company <- add_inv_and_port_names_if_needed(
    data = equity_results_company,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading company bonds results.")
  bonds_results_company <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "Bonds_results_company.rds"),
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  bonds_results_company <- add_inv_and_port_names_if_needed(
    data = bonds_results_company,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading equity map results.")
  equity_results_map <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "Equity_results_map.rds"),
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  equity_results_map <- add_inv_and_port_names_if_needed(
    data = equity_results_map,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading bonds map results.")
  bonds_results_map <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_outputs_dir, "Bonds_results_map.rds"),
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  bonds_results_map <- add_inv_and_port_names_if_needed(
    data = bonds_results_map,
    portfolio_name = cfg[["portfolio_name"]],
    investor_name = cfg[["investor_name"]]
  )

  log_debug("Loading portfolio equity peer results.")
  peers_equity_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(benchmarks_dir, paste0(cfg$project_code, "_peers_equity_results_portfolio.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading portfolio bonds peer results.")
  peers_bonds_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(benchmarks_dir, paste0(cfg$project_code, "_peers_bonds_results_portfolio.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity peer results.")
  peers_equity_results_user <- read_rds_or_return_alt_data(
    filepath = file.path(benchmarks_dir, paste0(cfg$project_code, "_peers_equity_results_portfolio_ind.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index bonds peer results.")
  peers_bonds_results_user <- read_rds_or_return_alt_data(
    filepath = file.path(benchmarks_dir, paste0(cfg$project_code, "_peers_bonds_results_portfolio_ind.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity portfolio results.")
  indices_equity_results_portfolio <- readRDS(file.path(benchmarks_dir, "Indices_equity_results_portfolio.rds"))

  log_debug("Loading index bonds portfolio results.")
  indices_bonds_results_portfolio <- readRDS(file.path(benchmarks_dir, "Indices_bonds_results_portfolio.rds"))

  # create interactive report ----------------------------------------------------

  prepare_interactive_report(
    cfg = cfg,
    audit_file = audit_file,
    emissions = emissions,
    portfolio_overview = portfolio_overview,
    equity_results_portfolio = equity_results_portfolio,
    bonds_results_portfolio = bonds_results_portfolio,
    equity_results_company = equity_results_company,
    bonds_results_company = bonds_results_company,
    equity_results_map = equity_results_map,
    bonds_results_map = bonds_results_map,
    indices_bonds_results_portfolio = indices_bonds_results_portfolio,
    indices_equity_results_portfolio = indices_equity_results_portfolio,
    peers_bonds_results_portfolio = peers_bonds_results_portfolio,
    peers_bonds_results_user = peers_bonds_results_user,
    peers_equity_results_portfolio = peers_equity_results_portfolio,
    peers_equity_results_user = peers_equity_results_user
  )

  # create executive summary -----------------------------------------------------
  prepare_executive_summary(
    cfg = cfg,
    total_portfolio = total_portfolio,
    equity_results_portfolio = equity_results_portfolio,
    bonds_results_portfolio = bonds_results_portfolio,
    indices_equity_results_portfolio = indices_equity_results_portfolio,
    indices_bonds_results_portfolio = indices_bonds_results_portfolio,
    audit_file = audit_file,
    emissions = emissions,
    peers_bonds_results_portfolio = peers_bonds_results_portfolio,
    peers_bonds_results_user = peers_bonds_results_user,
    peers_equity_results_portfolio = peers_equity_results_portfolio,
    peers_equity_results_user = peers_equity_results_user
  )

  log_info("Portfolio report finished.")
}
