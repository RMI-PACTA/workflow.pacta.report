logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
workflow.pacta.report:::run_pacta_reporting_process(commandArgs(trailingOnly = TRUE))
