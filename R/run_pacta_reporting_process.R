run_pacta_reporting_process <- function(
  params,
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
  } else {
    if (!pacta.workflow.utils::check_dir_writable(report_output_dir)) {
      log_warn("Directory \"{report_output_dir}\" is not writable.")
      stop("Directory \"{report_output_dir}\" is not writable.")
    }
  }
  if (is.null(summary_output_dir) || summary_output_dir == "") {
    log_error("SUMMARY_OUTPUT_DIR not set.")
    stop("SUMMARY_OUTPUT_DIR not set.")
  } else {
    if (!pacta.workflow.utils::check_dir_writable(summary_output_dir)) {
      log_warn("Directory \"{report_output_dir}\" is not writable.")
      stop("Directory \"{report_output_dir}\" is not writable.")
    }
  }
  if (is.null(real_estate_dir) || real_estate_dir == "") {
    log_error("REAL_ESTATE_DIR not set.")
    stop("REAL_ESTATE_DIR not set.")
  }
  if (is.null(survey_dir) || survey_dir == "") {
    log_error("SURVEY_DIR not set.")
    stop("SURVEY_DIR not set.")
  }
  if (is.null(score_card_dir) || score_card_dir == "") {
    log_error("SCORE_CARD_DIR not set.")
    stop("SCORE_CARD_DIR not set.")
  }

  log_info("Starting portfolio report process")

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
    params[["reporting"]][["projectCode"]] == "GENERAL" &&
      params[["user"]][["languageSelect"]] != "EN"
  ) {
    log_warn("Overriding language selection to \"EN\" for \"GENERAL\".")
    params[["user"]][["languageSelect"]] <- "EN"
  } else {
    log_trace(
      "Using language selection: ",
      "\"{params[['user']][['languageSelect']]}\"."
    )
  }


  # load PACTA results -----------------------------------------------------------

  log_info("Loading PACTA results.")

  log_debug("Loading audit file.")
  audit_file_path <- file.path(analysis_output_dir, "audit_file.rds")
  audit_file <- read_rds_or_return_alt_data(
    filepath = audit_file_path,
    alt_return = pacta.portfolio.utils::empty_audit_file()
  )
  audit_file <- add_inv_and_port_names_if_needed(
    data = audit_file,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading portfolio overview.")
  portfolio_overview_path <- file.path(analysis_output_dir, "overview_portfolio.rds")
  portfolio_overview <- read_rds_or_return_alt_data(
    filepath = portfolio_overview_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_overview()
  )
  portfolio_overview <- add_inv_and_port_names_if_needed(
    data = portfolio_overview,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading emissions.")
  emissions_path <- file.path(analysis_output_dir, "emissions.rds")
  emissions <- read_rds_or_return_alt_data(
    filepath = emissions_path,
    alt_return = pacta.portfolio.utils::empty_emissions_results()
  )
  emissions <- add_inv_and_port_names_if_needed(
    data = emissions,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading total portfolio results.")
  total_portfolio <- read_rds_or_return_alt_data(
    filepath = total_portfolio_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  total_portfolio <- add_inv_and_port_names_if_needed(
    data = total_portfolio,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading portfolio equity results.")
  equity_results_portfolio_path <- file.path(
    analysis_output_dir,
    "Equity_results_portfolio.rds"
  )
  equity_results_portfolio <- read_rds_or_return_alt_data(
    filepath = equity_results_portfolio_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  equity_results_portfolio <- add_inv_and_port_names_if_needed(
    data = equity_results_portfolio,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading portfolio bonds results.")
  bonds_results_portfolio_path <- file.path(
    analysis_output_dir,
    "Bonds_results_portfolio.rds"
  )
  bonds_results_portfolio <- read_rds_or_return_alt_data(
    filepath = bonds_results_portfolio_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  bonds_results_portfolio <- add_inv_and_port_names_if_needed(
    data = bonds_results_portfolio,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading company equity results.")
  equity_results_company_path <- file.path(
    analysis_output_dir,
    "Equity_results_company.rds"
  )
  equity_results_company <- read_rds_or_return_alt_data(
    filepath = equity_results_company_path,
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  equity_results_company <- add_inv_and_port_names_if_needed(
    data = equity_results_company,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading company bonds results.")
  bonds_results_company_path <- file.path(
    analysis_output_dir,
    "Bonds_results_company.rds"
  )
  bonds_results_company <- read_rds_or_return_alt_data(
    filepath = bonds_results_company_path,
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  bonds_results_company <- add_inv_and_port_names_if_needed(
    data = bonds_results_company,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading equity map results.")
  equity_results_map_path <- file.path(
    analysis_output_dir,
    "Equity_results_map.rds"
  )
  equity_results_map <- read_rds_or_return_alt_data(
    filepath = equity_results_map_path,
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  equity_results_map <- add_inv_and_port_names_if_needed(
    data = equity_results_map,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  log_debug("Loading bonds map results.")
  bonds_results_map_path <- file.path(
    analysis_output_dir,
    "Bonds_results_map.rds"
  )
  bonds_results_map <- read_rds_or_return_alt_data(
    filepath = bonds_results_map_path,
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  bonds_results_map <- add_inv_and_port_names_if_needed(
    data = bonds_results_map,
    portfolio_name = params[["portfolio"]][["name"]],
    investor_name = params[["user"]][["name"]]
  )

  analysis_output_manifest <- jsonlite::read_json(analysis_manifest_path)

  log_debug("Loading portfolio equity peer results.")
  peers_equity_results_portfolio_path <- file.path(
    benchmarks_dir,
    paste0(
      params[["reporting"]][["projectCode"]],
      "_peers_equity_results_portfolio.rds"
    )
  )
  peers_equity_results_portfolio <- read_rds_or_return_alt_data(
    filepath = peers_equity_results_portfolio_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading portfolio bonds peer results.")
  peers_bonds_results_portfolio_path <- file.path(
    benchmarks_dir,
    paste0(
      params[["reporting"]][["projectCode"]],
      "_peers_bonds_results_portfolio.rds"
    )
  )
  peers_bonds_results_portfolio <- read_rds_or_return_alt_data(
    filepath = peers_bonds_results_portfolio_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity peer results.")
  peers_equity_results_user_path <- file.path(
    benchmarks_dir,
    paste0(
      params[["reporting"]][["projectCode"]],
      "_peers_equity_results_portfolio_ind.rds"
    )
  )
  peers_equity_results_user <- read_rds_or_return_alt_data(
    filepath = peers_equity_results_user_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index bonds peer results.")
  peers_bonds_results_user_path <- file.path(
    benchmarks_dir,
    paste0(
      params[["reporting"]][["projectCode"]],
      "_peers_bonds_results_portfolio_ind.rds"
    )
  )
  peers_bonds_results_user <- read_rds_or_return_alt_data(
    filepath = peers_bonds_results_user_path,
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity portfolio results.")
  indices_equity_results_port_path <- file.path(benchmarks_dir, "Indices_equity_results_portfolio.rds")
  indices_equity_results_portfolio <- readRDS(indices_equity_results_port_path)

  log_debug("Loading index bonds portfolio results.")
  indices_bonds_results_port_path <- file.path(benchmarks_dir, "Indices_bonds_results_portfolio.rds")
  indices_bonds_results_portfolio <- readRDS(indices_bonds_results_port_path)

  # create interactive report ----------------------------------------------------

  prepare_interactive_report(
    report_output_dir = report_output_dir,
    project_report_name = params[["reporting"]][["projectReportName"]],
    survey_dir = survey_dir,
    real_estate_dir = real_estate_dir,
    language_select = params[["user"]][["languageSelect"]],
    peer_group = params[["user"]][["peerGroup"]],
    investor_name = params[["user"]][["name"]],
    portfolio_name = params[["portfolio"]][["name"]],
    start_year = analysis_params[["startYear"]],
    currency_exchange_value = params[["user"]][["currencyExchangeValue"]],
    select_scenario = params[["reporting"]][["selectScenario"]],
    scenario_other = params[["reporting"]][["scenarioOther"]],
    portfolio_allocation_method = params[["reporting"]][["portfolioAllocationMethod"]],
    scenario_geography = params[["reporting"]][["scenarioGeography"]],
    sector_list = params[["reporting"]][["sectorList"]],
    green_techs = params[["reporting"]][["greenTechs"]],
    tech_roadmap_sectors = params[["reporting"]][["techRoadmapSectors"]],
    pacta_sectors_not_analysed = params[["reporting"]][["pactaSectorsNotAnalysed"]],
    display_currency = params[["user"]][["displayCurrency"]],
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
    project_code = params[["reporting"]][["projectCode"]],
    language_select = params[["user"]][["languageSelect"]],
    peer_group = params[["user"]][["peerGroup"]],
    investor_name = params[["user"]][["name"]],
    portfolio_name = params[["portfolio"]][["name"]],
    start_year = analysis_params[["startYear"]],
    currency_exchange_value = params[["user"]][["currencyExchangeValue"]],
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
  return(
    list(
      input_files = unique(
        c(
          analysis_manifest_path,
          total_portfolio_path,
          audit_file_path,
          portfolio_overview_path,
          emissions_path,
          total_portfolio_path,
          equity_results_portfolio_path,
          bonds_results_portfolio_path,
          equity_results_company_path,
          bonds_results_company_path,
          equity_results_map_path,
          bonds_results_map_path,
          analysis_manifest_path,
          peers_equity_results_portfolio_path,
          peers_bonds_results_portfolio_path,
          peers_equity_results_user_path,
          peers_bonds_results_user_path,
          indices_equity_results_port_path,
          indices_bonds_results_port_path
        )
      ),
      output_files = c(
        list.files(
          report_output_dir,
          full.names = TRUE,
          recursive = TRUE
        ),
        list.files(
          summary_output_dir,
          full.names = TRUE,
          recursive = TRUE
        )
      ),
      params = params
    )
  )
}
