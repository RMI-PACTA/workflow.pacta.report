prepare_interactive_report <- function(
  cfg,
  audit_file,
  emissions,
  portfolio_overview,
  equity_results_portfolio,
  bonds_results_portfolio,
  equity_results_company,
  bonds_results_company,
  equity_results_map,
  bonds_results_map,
  indices_bonds_results_portfolio,
  indices_equity_results_portfolio,
  peers_bonds_results_portfolio,
  peers_bonds_results_user,
  peers_equity_results_portfolio,
  peers_equity_results_user
) {
  log_debug("Preparing to create interactive report.")

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
    output_dir = cfg$report_dir,
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
}
