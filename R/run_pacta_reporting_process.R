run_pacta_reporting_process <- function(
  raw_params = commandArgs(trailingOnly = TRUE),
  analysis_output_dir = Sys.getenv("ANALYSIS_OUTPUT_DIR"),
  benchmarks_dir = Sys.getenv("BENCHMARKS_DIR"),
  report_output_dir = Sys.getenv("REPORT_OUTPUT_DIR"),
  summary_output_dir = Sys.getenv("SUMMARY_OUTPUT_DIR"),
  real_estate_dir = Sys.getenv("REAL_ESTATE_DIR"),
  survey_dir = Sys.getenv("SURVEY_DIR"),
  score_card_dir = Sys.getenv("SCORE_CARD_DIR")
) {
  log_debug("Checking configuration.")
  if (is.null(analysis_output_dir) || analysis_output_dir == "") {
    log_error("ANALYSIS_OUTPUTS_DIR not set.")
    stop("ANALYSIS_OUTPUTS_DIR not set.")
  }
  if (is.null(benchmarks_dir) || benchmarks_dir == "") {
    log_error("BENCHMARKS_DIR not set.")
    stop("BENCHMARKS_DIR not set.")
  }
  if (is.null(report_output_dir) || report_output_dir == "") {
    log_error("REPORT_OUTPUT_DIR not set.")
    stop("REPORT_OUTPUT_DIR not set.")
  }
  if (is.null(summary_output_dir) || summary_output_dir == "") {
    log_error("SUMMARY_OUTPUT_DIR not set.")
    stop("SUMMARY_OUTPUT_DIR not set.")
  }

  # defaulting to WARN to maintain current (silent) behavior.
  logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))
  logger::log_formatter(logger::formatter_glue)

  # -------------------------------------------------------------------------

  log_info("Starting portfolio report process")

  # Read Params
  log_trace("Processing input parameters.")
  if (length(raw_params) == 0L || all(raw_params == "")) {
    log_error("No parameters specified.")
  }

  # log_trace("Validating raw input parameters.")
  # raw_input_validation_results <- jsonvalidate::json_validate(
  #   json = raw_params,
  #   schema = system.file(
  #     "extdata", "schema", "rawParameters.json",
  #     package = "workflow.pacta.report"
  #   ),
  #   verbose = TRUE,
  #   greedy = FALSE,
  #   engine = "ajv"
  # )
  # if (raw_input_validation_results) {
  #   log_trace("Raw input parameters are valid.")
  # } else {
  #   log_error(
  #     "Invalid raw input parameters. ",
  #     "Must include \"inherit\" key, or match full schema."
  #   )
  #   stop("Invalid raw input parameters.")
  # }

  params <- pacta.workflow.utils:::parse_params(
    json = raw_params,
    inheritence_search_paths = system.file(
      "extdata", "parameters",
      package = "workflow.pacta.report"
    ) ,
    schema_file = NULL
    # schema_file = system.file(
    #   "extdata", "schema", "portfolioParameters_0-0-1.json",
    #   package = "workflow.pacta.report"
    # )
  )

  # quit if there's no relevant PACTA assets -------------------------------------

  log_debug("Checking for PACTA analysis manifest.")
  analysis_manifest_path <- file.path(analysis_output_dir, "manifest.json")
  if (file.exists(analysis_manifest_path)) {
    log_trace("Reading analysis manifest.")
    analysis_manifest <- jsonlite::read_json(analysis_manifest_path)
    analysis_params <- analysis_manifest[["params"]][["analysis"]]
  } else {
    log_warn("file \"{analysis_manifest_path}\" does not exist.")
    stop("Cannot find analysis manifest file.")
  }


  log_debug("Checking for PACTA relevant data in portfolio results.")
  total_portfolio_path <- file.path(analysis_output_dir, "total_portfolio.rds")
  if (file.exists(total_portfolio_path)) {
    total_portfolio <- readRDS(total_portfolio_path)
    log_trace("Checking for PACTA relevant data in file: \"{total_portfolio_path}\".")
    pacta.portfolio.utils::quit_if_no_pacta_relevant_data(total_portfolio)
  } else {
    log_warn("file \"{total_portfolio_path}\" does not exist.")
    warning("Cannot find total_portfolio.rds file. Exiting.")
  }


  # fix parameters ---------------------------------------------------------------

  if (
    params[["reporting"]][["project_code"]] == "GENERAL" &&
      params[["user"]][["language_select"]] != "EN"
  ) {
    log_warn("Overriding language selection to \"EN\" for \"GENERAL\".")
    params[["user"]][["language_select"]] <- "EN"
  } else {
    log_trace(
      "Using language selection: ",
      "\"{params[['user']][['language_select']]}\"."
    )
  }


  # load PACTA results -----------------------------------------------------------

  log_info("Loading PACTA results.")

  log_debug("Loading audit file.")
  audit_file <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "audit_file.rds"),
    alt_return = pacta.portfolio.utils::empty_audit_file()
  )
  audit_file <- add_inv_and_port_names_if_needed(
    data = audit_file,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading portfolio overview.")
  portfolio_overview <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "overview_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_overview()
  )
  portfolio_overview <- add_inv_and_port_names_if_needed(
    data = portfolio_overview,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading emissions.")
  emissions <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "emissions.rds"),
    alt_return = pacta.portfolio.utils::empty_emissions_results()
  )
  emissions <- add_inv_and_port_names_if_needed(
    data = emissions,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading total portfolio results.")
  total_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "total_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  total_portfolio <- add_inv_and_port_names_if_needed(
    data = total_portfolio,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading portfolio equity results.")
  equity_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "Equity_results_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  equity_results_portfolio <- add_inv_and_port_names_if_needed(
    data = equity_results_portfolio,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading portfolio bonds results.")
  bonds_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "Bonds_results_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  bonds_results_portfolio <- add_inv_and_port_names_if_needed(
    data = bonds_results_portfolio,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading company equity results.")
  equity_results_company <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "Equity_results_company.rds"),
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  equity_results_company <- add_inv_and_port_names_if_needed(
    data = equity_results_company,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading company bonds results.")
  bonds_results_company <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "Bonds_results_company.rds"),
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  bonds_results_company <- add_inv_and_port_names_if_needed(
    data = bonds_results_company,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading equity map results.")
  equity_results_map <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "Equity_results_map.rds"),
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  equity_results_map <- add_inv_and_port_names_if_needed(
    data = equity_results_map,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  log_debug("Loading bonds map results.")
  bonds_results_map <- read_rds_or_return_alt_data(
    filepath = file.path(analysis_output_dir, "Bonds_results_map.rds"),
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  bonds_results_map <- add_inv_and_port_names_if_needed(
    data = bonds_results_map,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["investor_name"]]
  )

  analysis_output_manifest <- jsonlite::read_json(file.path(analysis_output_dir, "manifest.json"))

  log_debug("Loading portfolio equity peer results.")
  peers_equity_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(
      benchmarks_dir,
      paste0(
        params[["reporting"]][["project_code"]],
        "_peers_equity_results_portfolio.rds"
      )
    ),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading portfolio bonds peer results.")
  peers_bonds_results_portfolio <- read_rds_or_return_alt_data(
    filepath = file.path(
      benchmarks_dir,
      paste0(
        params[["reporting"]][["project_code"]],
        "_peers_bonds_results_portfolio.rds"
      )
    ),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity peer results.")
  peers_equity_results_user <- read_rds_or_return_alt_data(
    filepath = file.path(
      benchmarks_dir,
      paste0(
        params[["reporting"]][["project_code"]],
        "_peers_equity_results_portfolio_ind.rds"
      )
    ),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index bonds peer results.")
  peers_bonds_results_user <- read_rds_or_return_alt_data(
    filepath = file.path(
      benchmarks_dir,
      paste0(
        params[["reporting"]][["project_code"]],
        "_peers_bonds_results_portfolio_ind.rds"
      )
    ),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity portfolio results.")
  indices_equity_results_portfolio <- readRDS(file.path(benchmarks_dir, "Indices_equity_results_portfolio.rds"))

  log_debug("Loading index bonds portfolio results.")
  indices_bonds_results_portfolio <- readRDS(file.path(benchmarks_dir, "Indices_bonds_results_portfolio.rds"))

  # create interactive report ----------------------------------------------------

  prepare_interactive_report(
    report_output_dir = report_output_dir,
    project_report_name = params[["reporting"]][["project_report_name"]],
    survey_dir = survey_dir,
    real_estate_dir = real_estate_dir,
    language_select = params[["user"]][["language_select"]],
    peer_group = params[["user"]][["peer_group"]],
    investor_name = params[["user"]][["investor_name"]],
    portfolio_name = params[["portfolio"]][["name"]],
    start_year = analysis_params[["startYear"]],
    currency_exchange_value = params[["user"]][["currency_exchange_value"]],
    select_scenario = params[["reporting"]][["select_scenario"]],
    scenario_other = params[["reporting"]][["scenario_other"]],
    portfolio_allocation_method = params[["reporting"]][["portfolio_allocation_method"]],
    scenario_geography = params[["reporting"]][["scenario_geography"]],
    sector_list = params[["reporting"]][["sector_list"]],
    green_techs = params[["reporting"]][["green_techs"]],
    tech_roadmap_sectors = params[["reporting"]][["tech_roadmap_sectors"]],
    pacta_sectors_not_analysed = params[["reporting"]][["pacta_sectors_not_analysed"]],
    display_currency = params[["user"]][["display_currency"]],
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
    peers_equity_results_user = peers_equity_results_user,
    analysis_output_manifest = analysis_output_manifest
  )

  # create executive summary -----------------------------------------------------
  prepare_executive_summary(
    summary_output_dir = summary_output_dir,
    survey_dir = survey_dir,
    real_estate_dir = real_estate_dir,
    score_card_dir = score_card_dir,
    project_code = params[["reporting"]][["project_code"]],
    language_select = params[["user"]][["language_select"]],
    peer_group = params[["user"]][["peer_group"]],
    investor_name = params[["user"]][["investor_name"]],
    portfolio_name = params[["portfolio"]][["name"]],
    start_year = analysis_params[["start_year"]],
    currency_exchange_value = params[["user"]][["currency_exchange_value"]],
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
