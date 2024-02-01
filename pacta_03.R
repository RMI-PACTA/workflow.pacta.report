suppressPackageStartupMessages({
  library(pacta.portfolio.utils)
  library(pacta.portfolio.report)
  library(pacta.executive.summary)
  library(dplyr)
  library(readr)
  library(jsonlite)
  library(fs)
})

# defaulting to WARN to maintain current (silent) behavior.
logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
logger::log_formatter(logger::formatter_glue)

# -------------------------------------------------------------------------

logger::log_info("Starting portfolio report process")

logger::log_trace("Determining configuration file path")
cfg_path <- commandArgs(trailingOnly = TRUE)
if (length(cfg_path) == 0 || cfg_path == "") {
  logger::log_warn("No configuration file specified, using default")
  cfg_path <- "input_dir/default_config.json"
}
logger::log_debug("Loading configuration from file: \"{cfg_path}\".")
cfg <- fromJSON(cfg_path)

# quit if there's no relevant PACTA assets -------------------------------------

logger::log_debug("Checking for PACTA relevant data in portfolio results.")
total_portfolio_path <- file.path(cfg$output_dir, "total_portfolio.rds")
if (file.exists(total_portfolio_path)) {
  total_portfolio <- readRDS(total_portfolio_path)
  logger::log_trace("Checking for PACTA relevant data in file: \"{total_portfolio_path}\".")
  quit_if_no_pacta_relevant_data(total_portfolio)
} else {
  logger::log_warn("file \"{total_portfolio_path}\" does not exist.")
  warning("This is weird... the `total_portfolio.rds` file does not exist in the `30_Processed_inputs` directory.")
}


# fix parameters ---------------------------------------------------------------

if (cfg$project_code == "GENERAL") {
  logger::log_warn("Overriding language selection to \"EN\" for \"GENERAL\".")
  cfg$language_select <- "EN"
} else {
  logger::log_trace("Using language selection: \"{cfg$language_select}\".")
}


# load PACTA results -----------------------------------------------------------

logger::log_info("Loading PACTA results.")

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

logger::log_debug("Loading audit file.")
audit_file <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "audit_file.rds"),
  alt_return = empty_audit_file()
)
audit_file <- add_inv_and_port_names_if_needed(audit_file)

logger::log_debug("Loading portfolio overview.")
portfolio_overview <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "overview_portfolio.rds"),
  alt_return = empty_portfolio_overview()
)
portfolio_overview <- add_inv_and_port_names_if_needed(portfolio_overview)

logger::log_debug("Loading emissions.")
emissions <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "emissions.rds"),
  alt_return = empty_emissions_results()
)
emissions <- add_inv_and_port_names_if_needed(emissions)

logger::log_debug("Loading total portfolio results.")
total_portfolio <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "total_portfolio.rds"),
  alt_return = empty_portfolio_results()
)
total_portfolio <- add_inv_and_port_names_if_needed(total_portfolio)

logger::log_debug("Loading portfolio equity results.")
equity_results_portfolio <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "Equity_results_portfolio.rds"),
  alt_return = empty_portfolio_results()
)
equity_results_portfolio <- add_inv_and_port_names_if_needed(equity_results_portfolio)

logger::log_debug("Loading portfolio bonds results.")
bonds_results_portfolio <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "Bonds_results_portfolio.rds"),
  alt_return = empty_portfolio_results()
)
bonds_results_portfolio <- add_inv_and_port_names_if_needed(bonds_results_portfolio)

logger::log_debug("Loading company equity results.")
equity_results_company <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "Equity_results_company.rds"),
  alt_return = empty_company_results()
)
equity_results_company <- add_inv_and_port_names_if_needed(equity_results_company)

logger::log_debug("Loading company bonds results.")
bonds_results_company <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "Bonds_results_company.rds"),
  alt_return = empty_company_results()
)
bonds_results_company <- add_inv_and_port_names_if_needed(bonds_results_company)

logger::log_debug("Loading equity map results.")
equity_results_map <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "Equity_results_map.rds"),
  alt_return = empty_map_results()
)
equity_results_map <- add_inv_and_port_names_if_needed(equity_results_map)

logger::log_debug("Loading bonds map results.")
bonds_results_map <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$output_dir, "Bonds_results_map.rds"),
  alt_return = empty_map_results()
)
bonds_results_map <- add_inv_and_port_names_if_needed(bonds_results_map)

logger::log_debug("Loading portfolio equity peer results.")
peers_equity_results_portfolio <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_equity_results_portfolio.rds")),
  alt_return = empty_portfolio_results()
)

logger::log_debug("Loading portfolio bonds peer results.")
peers_bonds_results_portfolio <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_bonds_results_portfolio.rds")),
  alt_return = empty_portfolio_results()
)

logger::log_debug("Loading index equity peer results.")
peers_equity_results_user <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_equity_results_portfolio_ind.rds")),
  alt_return = empty_portfolio_results()
)

logger::log_debug("Loading index bonds peer results.")
peers_bonds_results_user <- readRDS_or_return_alt_data(
  filepath = file.path(cfg$data_dir, paste0(cfg$project_code, "_peers_bonds_results_portfolio_ind.rds")),
  alt_return = empty_portfolio_results()
)

logger::log_debug("Loading index equity portfolio results.")
indices_equity_results_portfolio <- readRDS(file.path(cfg$data_dir, "Indices_equity_results_portfolio.rds"))

logger::log_debug("Loading index bonds portfolio results.")
indices_bonds_results_portfolio <- readRDS(file.path(cfg$data_dir, "Indices_bonds_results_portfolio.rds"))


# create interactive report ----------------------------------------------------

logger::log_debug("Preparing to create interactive report.")

survey_dir <- file.path(cfg$user_results_path, cfg$project_code, "survey")
real_estate_dir <- file.path(cfg$user_results_path, cfg$project_code, "real_estate")
output_dir <- file.path(cfg$output_dir)

logger::log_debug("Loading data frame label translations.")
dataframe_translations <- readr::read_csv(
  system.file("extdata/translation/dataframe_labels.csv", package = "pacta.portfolio.report"),
  col_types = cols()
)

logger::log_debug("Loading data frame header translations.")
header_dictionary <- readr::read_csv(
  system.file("extdata/translation/dataframe_headers.csv", package = "pacta.portfolio.report"),
  col_types = cols()
)

logger::log_debug("Loading JavaScript label translations.")
js_translations <- jsonlite::fromJSON(
  txt = system.file("extdata/translation/js_labels.json", package = "pacta.portfolio.report")
)

logger::log_debug("Loading sector order.")
sector_order <- readr::read_csv(
  system.file("extdata/sector_order/sector_order.csv", package = "pacta.portfolio.report"),
  col_types = cols()
)

# combine config files to send to create_interactive_report()
logger::log_trace("Defining configs and manifest.")
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

logger::log_trace("Defining interactive report template paths.")
template_path <- system.file("templates", package = "pacta.portfolio.report") #TODO: generalize this to accept non-builtin templates
template_dir_name <- paste(tolower(cfg$project_report_name), tolower(cfg$language_select), "template", sep = "_")
template_dir <- file.path(template_path, template_dir_name)

# TODO: thi is a placeholder until https://github.com/RMI-PACTA/pacta.portfolio.report/issues/43 is resolved
override_prep_emissions_trajectory <- function(
  equity_results_portfolio,
  bonds_results_portfolio,
  investor_name,
  portfolio_name,
  select_scenario_other,
  select_scenario,
  twodi_sectors,
  year_span,
  start_year = cfg$start_year
) {
  emissions_units <-
    c(
      Automotive = "tons of CO2 per km per cars produced",
      Aviation = "tons of CO2 per passenger km per active planes",
      Cement = "tons of CO2 per tons of cement",
      Coal = "tons of CO2 per tons of coal",
      `Oil&Gas` = "tons of CO2 per GJ",
      Power = "tons of CO2 per MWh",
      Steel = "tons of CO2 per tons of steel"
    )
  list(`Listed Equity` = equity_results_portfolio,
    `Corporate Bonds` = bonds_results_portfolio) %>%
  bind_rows(.id = "asset_class") %>%
  dplyr::filter(.data$investor_name == .env$investor_name,
    .data$portfolio_name == .env$portfolio_name) %>%
  pacta.portfolio.report:::filter_scenarios_per_sector(
    select_scenario_other,
    select_scenario
    ) %>%
  dplyr::filter(.data$scenario_geography == "Global") %>%
  select("asset_class", "allocation", "equity_market", sector = "ald_sector", "year",
    plan = "plan_sec_emissions_factor", scen = "scen_sec_emissions_factor", "scenario") %>%
  distinct() %>%
  dplyr::filter(!is.nan(.data$plan)) %>%
  tidyr::pivot_longer(c("plan", "scen"), names_to = "plan") %>%
  tidyr::unite("name", "sector", "plan", remove = FALSE) %>%
  mutate(disabled = !.data$sector %in% .env$twodi_sectors) %>%
  mutate(unit = .env$emissions_units[.data$sector]) %>%
  group_by(.data$asset_class) %>%
  dplyr::filter(!all(.data$disabled)) %>%
  dplyr::mutate(equity_market =  case_when(
      .data$equity_market == "GlobalMarket" ~ "Global Market",
      .data$equity_market == "DevelopedMarket" ~ "Developed Market",
      .data$equity_market == "EmergingMarket" ~ "Emerging Market",
      TRUE ~ .data$equity_market)
    ) %>%
  dplyr::filter(.data$year <= .env$start_year + .env$year_span) %>%
  dplyr::arrange(.data$asset_class, factor(.data$equity_market, levels = c("Global Market", "Developed Market", "Emerging Market"))) %>%
  ungroup()
}
assignInNamespace(
  x = "prep_emissions_trajectory",
  value = override_prep_emissions_trajectory,
  ns = "pacta.portfolio.report"
)

logger::log_info("Creating interactive report.")
create_interactive_report(
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
  twodi_sectors = cfg$sector_list,
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
logger::log_debug("Preparing to create executive summary.")

survey_dir <- fs::path_abs(file.path(cfg$user_results_path, cfg$project_code, "survey"))
real_estate_dir <- fs::path_abs(file.path(cfg$user_results_path, cfg$project_code, "real_estate"))
score_card_dir <- fs::path_abs(file.path(cfg$user_results_path, cfg$project_code, "score_card"))
output_dir <- file.path(cfg$output_dir)
es_dir <- file.path(cfg$output_dir, "executive_summary")
if (!dir.exists(es_dir)) {
  dir.create(es_dir, showWarnings = FALSE, recursive = TRUE)
}

logger::log_trace("Defining executive summary template paths.")
exec_summary_template_name <- paste0(cfg$project_code, "_", tolower(cfg$language_select), "_exec_summary")
exec_summary_builtin_template_path <- system.file("extdata", exec_summary_template_name, package = "pacta.executive.summary")
invisible(file.copy(exec_summary_builtin_template_path, cfg$output_dir, recursive = TRUE, copy.mode = FALSE))
exec_summary_template_path <- file.path(cfg$output_dir, exec_summary_template_name)

if (dir.exists(exec_summary_template_path) && (cfg$peer_group %in% c("assetmanager", "bank", "insurance", "pensionfund"))) {
  logger::log_debug("Preparing data for executive summary.")
  data_aggregated_filtered <-
    prep_data_executive_summary(
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

  logger::log_trace("Checking for real estate data.")
  real_estate_flag <- (length(list.files(real_estate_dir)) > 0)

  logger::log_info("Creating executive summary.")
  render_executive_summary(
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
  logger::log_debug("No executive summary created.")
  invisible(file.copy(blank_pdf(), es_dir))
}

logger::log_info("Portfolio report finished.")
