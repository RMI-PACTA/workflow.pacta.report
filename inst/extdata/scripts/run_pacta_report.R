logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))

raw_params <- commandArgs(trailingOnly = TRUE)
params <- pacta.workflow.utils::parse_raw_params(
  json = raw_params,
  inheritence_search_paths = system.file(
    "extdata", "parameters",
    package = "workflow.pacta.report"
  ) ,
  schema_file = system.file(
    "extdata", "schema", "reportingParameters.json",
    package = "workflow.pacta.report"
  ),
  raw_schema_file = system.file(
    "extdata", "schema", "rawParameters.json",
    package = "workflow.pacta.report"
  )
)

workflow.pacta.report:::run_pacta_reporting_process(
  params = params
)
