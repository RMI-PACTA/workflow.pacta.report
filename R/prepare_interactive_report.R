prepare_interactive_report <- function(
  report_output_dir,
  project_report_name,
  survey_dir,
  real_estate_dir,
  language_select,
  peer_group,
  investor_name,
  portfolio_name,
  start_year,
  currency_exchange_value,
  select_scenario,
  scenario_other,
  portfolio_allocation_method,
  scenario_geography,
  sector_list,
  green_techs,
  tech_roadmap_sectors,
  pacta_sectors_not_analysed,
  display_currency,
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
  peers_equity_results_user,
  analysis_output_manifest
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

  configs <- list(
    analysis_output_manifest = analysis_output_manifest
  )

  log_trace("Defining interactive report template paths.")
  template_path <- system.file("templates", package = "pacta.portfolio.report")
  template_dir_name <- paste(tolower(project_report_name), tolower(language_select), "template", sep = "_")
  template_dir <- file.path(template_path, template_dir_name)

  log_info("Creating interactive report.")
  pacta.portfolio.report::create_interactive_report(
    template_dir = template_dir,
    output_dir = report_output_dir,
    survey_dir = survey_dir,
    real_estate_dir = real_estate_dir,
    language_select = language_select,
    investor_name = investor_name,
    portfolio_name = portfolio_name,
    peer_group = peer_group,
    start_year = start_year,
    select_scenario = select_scenario,
    select_scenario_other = scenario_other,
    portfolio_allocation_method = portfolio_allocation_method,
    scenario_geography = scenario_geography,
    pacta_sectors = sector_list,
    green_techs = green_techs,
    tech_roadmap_sectors = tech_roadmap_sectors,
    pacta_sectors_not_analysed = pacta_sectors_not_analysed,
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
    display_currency = display_currency,
    currency_exchange_value = currency_exchange_value,
    header_dictionary = header_dictionary,
    sector_order = sector_order,
    configs = configs
  )
}
