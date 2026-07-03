# Tranche 117 contract only. Do not source for execution outside the T118 gate.
# Future T118 may test R CMD INSTALL and library(drmTMB); it must stop before any model command.

t117_install_load_contract <- function(
  source_dir = "/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/source",
  install_lib = "/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/Rlib-tranche117-drmTMB",
  dependency_libs = c("/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/Rlib-tranche115", "/project/def-snakagaw/snakagaw/drmtmb-qseries/20260702-q1-mu-slope-spatial-tranche80-drac-source-56add7f0/Rlib-tranche98"),
  expected_source_sha = "56add7f04fab7bec57a42e56eaeb090dff491863"
) {
  list(
    contract = "package_install_load_packet_review_only",
    source_dir = source_dir,
    install_lib = install_lib,
    dependency_libs = dependency_libs,
    expected_source_sha = expected_source_sha,
    install_status = "future_T118_contract_only_not_attempted",
    load_status = "future_T118_contract_only_not_attempted",
    stop_before = c("smoke_runner", "model_formula", "model_fit", "retained_denominator", "coverage")
  )
}

# Fail closed if someone sources the contract as an execution script.
if (identical(environment(), globalenv()) && !identical(Sys.getenv("DRMTMB_QSERIES_T118_APPROVED"), "rose_fisher_gauss_noether_grace")) {
  stop("T117 contract only: T118 approval is required before package install/load execution", call. = FALSE)
}
