run_pacta_reporting_process <- function() {

  # defaulting to WARN to maintain current (silent) behavior.
  logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
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
  total_portfolio_path <- file.path(cfg$output_dir, "total_portfolio.rds")
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
  audit_file <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "audit_file.rds"),
    alt_return = pacta.portfolio.utils::empty_audit_file()
  )
  audit_file <- add_inv_and_port_names_if_needed(audit_file)

  log_debug("Loading portfolio overview.")
  portfolio_overview <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "overview_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_overview()
  )
  portfolio_overview <- add_inv_and_port_names_if_needed(portfolio_overview)

  log_debug("Loading emissions.")
  emissions <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "emissions.rds"),
    alt_return = pacta.portfolio.utils::empty_emissions_results()
  )
  emissions <- add_inv_and_port_names_if_needed(emissions)

  log_debug("Loading total portfolio results.")
  total_portfolio <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "total_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  total_portfolio <- add_inv_and_port_names_if_needed(total_portfolio)

  log_debug("Loading portfolio equity results.")
  equity_results_portfolio <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "Equity_results_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  equity_results_portfolio <- add_inv_and_port_names_if_needed(equity_results_portfolio)

  log_debug("Loading portfolio bonds results.")
  bonds_results_portfolio <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "Bonds_results_portfolio.rds"),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )
  bonds_results_portfolio <- add_inv_and_port_names_if_needed(bonds_results_portfolio)

  log_debug("Loading company equity results.")
  equity_results_company <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "Equity_results_company.rds"),
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  equity_results_company <- add_inv_and_port_names_if_needed(equity_results_company)

  log_debug("Loading company bonds results.")
  bonds_results_company <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "Bonds_results_company.rds"),
    alt_return = pacta.portfolio.utils::empty_company_results()
  )
  bonds_results_company <- add_inv_and_port_names_if_needed(bonds_results_company)

  log_debug("Loading equity map results.")
  equity_results_map <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "Equity_results_map.rds"),
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  equity_results_map <- add_inv_and_port_names_if_needed(equity_results_map)

  log_debug("Loading bonds map results.")
  bonds_results_map <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$output_dir, "Bonds_results_map.rds"),
    alt_return = pacta.portfolio.utils::empty_map_results()
  )
  bonds_results_map <- add_inv_and_port_names_if_needed(bonds_results_map)

  log_debug("Loading portfolio equity peer results.")
  peers_equity_results_portfolio <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_equity_results_portfolio.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading portfolio bonds peer results.")
  peers_bonds_results_portfolio <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_bonds_results_portfolio.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity peer results.")
  peers_equity_results_user <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_equity_results_portfolio_ind.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index bonds peer results.")
  peers_bonds_results_user <- readRDS_or_return_alt_data(
    filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_bonds_results_portfolio_ind.rds")),
    alt_return = pacta.portfolio.utils::empty_portfolio_results()
  )

  log_debug("Loading index equity portfolio results.")
  indices_equity_results_portfolio <- readRDS(file.path(cfg$data_dir, "Indices_equity_results_portfolio.rds"))

  log_debug("Loading index bonds portfolio results.")
  indices_bonds_results_portfolio <- readRDS(file.path(cfg$data_dir, "Indices_bonds_results_portfolio.rds"))

  # create interactive report ----------------------------------------------------

  log_debug("Preparing to create interactive report.")

  survey_dir <- file.path(cfg$user_results_path, cfg$project_code, "survey")
  real_estate_dir <- file.path(cfg$user_results_path, cfg$project_code, "real_estate")

  log_debug("Loading data frame label translations.")
  dataframe_translations <- readr::read_csv(
    system.file("extdata/translation/dataframe_labels.csv", package = "pacta.portfolio.report"),
    col_types = readr::cols()
  )

  log_debug("Loading data frame header translations.")
  header_dictionary <- readr::read_csv(
    system.file("extdata/translation/dataframe_headers.csv", package = "pacta.portfolio.report"),
    col_types = readr::cols()
  )

  log_debug("Loading JavaScript label translations.")
  js_translations <- jsonlite::fromJSON(
    txt = system.file("extdata/translation/js_labels.json", package = "pacta.portfolio.report")
  )

  log_debug("Loading sector order.")
  sector_order <- readr::read_csv(
    system.file("extdata/sector_order/sector_order.csv", package = "pacta.portfolio.report"),
    col_types = readr::cols()
  )

  # combine config files to send to create_interactive_report()
  log_trace("Defining configs and manifest.")
  pacta_data_public_manifest <-
    list(
      creation_time_date = jsonlite::read_json(file.path(cfg$data_dir, "manifest.json"))$creation_time_date,
      outputs_manifest = jsonlite::read_json(file.path(cfg$data_dir, "manifest.json"))$outputs_manifest
    )

  configs <-
    list(
      portfolio_config = cfg,
      pacta_data_public_manifest = pacta_data_public_manifest
    )

  # workaround a bug in {config} v0.3.2 that only adds "config" class to objects it creates
  class(configs$portfolio_config) <- c(class(configs$portfolio_config), "list")

  log_trace("Defining interactive report template paths.")
  template_path <- system.file("templates", package = "pacta.portfolio.report")
  template_dir_name <- paste(tolower(cfg$project_report_name), tolower(cfg$language_select), "template", sep = "_")
  template_dir <- file.path(template_path, template_dir_name)

  log_info("Creating interactive report.")
  pacta.portfolio.report::create_interactive_report(
    template_dir = template_dir,
    output_dir = file.path(cfg$output_dir, "report"),
    survey_dir = cfg$survey_dir,
    real_estate_dir = cfg$real_estate_dir,
    language_select = cfg$language_select,
    investor_name = cfg$investor_name,
    portfolio_name = cfg$portfolio_name,
    peer_group = cfg$peer_group,
    start_year = cfg$start_year,
    select_scenario = cfg$select_scenario,
    select_scenario_other = cfg$scenario_other,
    portfolio_allocation_method = cfg$portfolio_allocation_method,
    scenario_geography = cfg$scenario_geography,
    pacta_sectors = cfg$sector_list,
    green_techs = cfg$green_techs,
    tech_roadmap_sectors = cfg$tech_roadmap_sectors,
    pacta_sectors_not_analysed = cfg$pacta_sectors_not_analysed,
    audit_file = audit_file,
    emissions = emissions,
    portfolio_overview = portfolio_overview,
    equity_results_portfolio = equity_results_portfolio,
    bonds_results_portfolio = bonds_results_portfolio,
    equity_results_company = equity_results_company,
    bonds_results_company = bonds_results_company,
    equity_results_map = equity_results_map,
    bonds_results_map = bonds_results_map,
    indices_equity_results_portfolio = indices_equity_results_portfolio,
    indices_bonds_results_portfolio = indices_bonds_results_portfolio,
    peers_equity_results_portfolio = peers_equity_results_portfolio,
    peers_bonds_results_portfolio = peers_bonds_results_portfolio,
    peers_equity_results_user = peers_equity_results_user,
    peers_bonds_results_user = peers_bonds_results_user,
    dataframe_translations = dataframe_translations,
    js_translations = js_translations,
    display_currency = cfg$display_currency,
    currency_exchange_value = cfg$currency_exchange_value,
    header_dictionary = header_dictionary,
    sector_order = sector_order,
    configs = configs
  )


  # create executive summary -----------------------------------------------------
  log_debug("Preparing to create executive summary.")

  survey_dir <- fs::path_abs(file.path(cfg$user_results_path, cfg$project_code, "survey"))
  real_estate_dir <- fs::path_abs(file.path(cfg$user_results_path, cfg$project_code, "real_estate"))
  score_card_dir <- fs::path_abs(file.path(cfg$user_results_path, cfg$project_code, "score_card"))
  es_dir <- file.path(cfg$output_dir, "executive_summary")
  if (!dir.exists(es_dir)) {
    dir.create(es_dir, showWarnings = FALSE, recursive = TRUE)
  }

  log_trace("Defining executive summary template paths.")
  exec_summary_template_name <- paste0(cfg$project_code, "_", tolower(cfg$language_select), "_exec_summary")
  exec_summary_builtin_template_path <- system.file(
    "extdata", exec_summary_template_name,
    package = "pacta.executive.summary"
  )
  invisible(file.copy(exec_summary_builtin_template_path, cfg$output_dir, recursive = TRUE, copy.mode = FALSE))
  exec_summary_template_path <- file.path(cfg$output_dir, exec_summary_template_name)

  if (
    dir.exists(exec_summary_template_path) && (
      cfg$peer_group %in% c("assetmanager", "bank", "insurance", "pensionfund")
    )
  ) {
    log_debug("Preparing data for executive summary.")
    data_aggregated_filtered <-
      pacta.executive.summary::prep_data_executive_summary(
        investor_name = cfg$investor_name,
        portfolio_name = cfg$portfolio_name,
        peer_group = cfg$peer_group,
        start_year = cfg$start_year,
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
      language = cfg$language_select,
      output_dir = es_dir,
      exec_summary_dir = exec_summary_template_path,
      survey_dir = survey_dir,
      real_estate_dir = real_estate_dir,
      real_estate_flag = real_estate_flag,
      score_card_dir = score_card_dir,
      file_name = "template.Rmd",
      investor_name = cfg$investor_name,
      portfolio_name = cfg$portfolio_name,
      peer_group = cfg$peer_group,
      total_portfolio = total_portfolio,
      scenario_selected = "1.5C-Unif",
      currency_exchange_value = cfg$currency_exchange_value,
      log_dir = cfg$output_dir
    )
  } else {
    # this is required for the online tool to know that the process has been completed.
    log_debug("No executive summary created.")
    invisible(file.copy(pacta.executive.summary::blank_pdf(), es_dir))
  }

  log_info("Portfolio report finished.")
}
