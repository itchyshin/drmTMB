#!/usr/bin/env Rscript

# Independent runtime reconciliation for the generated capability ledger.
# Run from the package root after `python3 tools/capability_ledger.py --check`.

options(warn = 1)
root <- normalizePath(".", mustWork = TRUE)
ledger_path <- file.path(
  root,
  "docs/dev-log/dashboard/capability-ledger/cells.tsv"
)

if (!file.exists(ledger_path)) {
  stop("Missing capability ledger: ", ledger_path, call. = FALSE)
}

suppressPackageStartupMessages(pkgload::load_all(root, quiet = TRUE))

cells <- utils::read.delim(
  ledger_path,
  sep = "\t",
  quote = "\"",
  check.names = FALSE,
  stringsAsFactors = FALSE
)
routes <- cells[cells$axis == "missing_response", , drop = FALSE]

if (nrow(routes) != 18L) {
  stop("Expected 18 missing-response routes; found ", nrow(routes), call. = FALSE)
}

runtime_allow <- getFromNamespace("drm_missing_response_families", "drmTMB")()
ledger_allow <- routes$family_route[
  routes$route_modifier == "base" &
    routes$capability_status == "implemented"
]

if (!setequal(runtime_allow, ledger_allow)) {
  stop(
    "Runtime/ledger missing-response admission drift. Runtime: ",
    paste(sort(runtime_allow), collapse = ", "),
    "; ledger base routes: ",
    paste(sort(ledger_allow), collapse = ", "),
    call. = FALSE
  )
}

expect_route_rejection <- function(expr, route, pattern) {
  error <- tryCatch(
    {
      force(expr)
      NULL
    },
    error = identity
  )
  if (is.null(error)) {
    stop(route, " unexpectedly accepted missing responses", call. = FALSE)
  }
  if (!grepl(pattern, conditionMessage(error))) {
    stop(
      route,
      " rejected for the wrong reason: ",
      conditionMessage(error),
      call. = FALSE
    )
  }
  invisible(TRUE)
}

dat <- data.frame(
  y = c(0L, 1L, NA_integer_, 2L, 0L, 3L, 1L, 2L),
  x = seq(-1, 1, length.out = 8L)
)
control <- miss_control(response = "include")

route_status <- stats::setNames(routes$capability_status, routes$family_route)
if (!identical(route_status[["zi_poisson"]], "implemented")) {
  expect_route_rejection(
    drmTMB(
      bf(y ~ x, zi ~ 1),
      family = stats::poisson(link = "log"),
      data = dat,
      missing = control
    ),
    "zi_poisson",
    "without a .*zi.* formula"
  )
}
if (!identical(route_status[["zi_nbinom2"]], "implemented")) {
  expect_route_rejection(
    drmTMB(
      bf(y ~ x, sigma ~ 1, zi ~ 1),
      family = nbinom2(),
      data = dat,
      missing = control
    ),
    "zi_nbinom2",
    "without a .*zi.* formula"
  )
}
if (!identical(route_status[["hurdle_nbinom2"]], "implemented")) {
  expect_route_rejection(
    drmTMB(
      bf(y ~ x, sigma ~ 1, hu ~ 1),
      family = truncated_nbinom2(),
      data = dat,
      missing = control
    ),
    "hurdle_nbinom2",
    "not implemented for the|Missing-response masking is currently validated only"
  )
}

gate_number <- as.integer(sub("^G", "", routes$test_gate))
invalid_tick <- routes$family_route[
  (routes$work_status == "verified" & gate_number < 3L) |
    (routes$work_status != "verified" & gate_number >= 3L)
]
if (length(invalid_tick)) {
  stop(
    "Missing-response verified ticks disagree with G3+ evidence: ",
    paste(invalid_tick, collapse = ", "),
    call. = FALSE
  )
}

invalid_capability <- routes$family_route[
  (routes$capability_status == "implemented" & gate_number < 1L) |
    (routes$capability_status != "implemented" & gate_number > 0L)
]
if (length(invalid_capability)) {
  stop(
    "Missing-response runtime capability disagrees with G1+ evidence: ",
    paste(invalid_capability, collapse = ", "),
    call. = FALSE
  )
}

gate_counts <- table(factor(routes$test_gate, levels = paste0("G", 0:5)))
verified <- sum(routes$test_gate %in% c("G3", "G4", "G5"))
cat(sprintf(
  paste0(
    "capability-runtime: OK (%d routes; G0=%d G1=%d G2=%d; ",
    "verified=%d)\n"
  ),
  nrow(routes), gate_counts[["G0"]], gate_counts[["G1"]],
  gate_counts[["G2"]], verified
))
