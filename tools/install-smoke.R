args <- commandArgs(trailingOnly = TRUE)
ref <- if (length(args) >= 1L && nzchar(args[[1L]])) args[[1L]] else "main"
expected_version <- if (length(args) >= 2L && nzchar(args[[2L]])) {
  args[[2L]]
} else {
  NA_character_
}

lib <- tempfile("drmtmb-install-smoke-lib-")
dir.create(lib)
.libPaths(c(lib, .libPaths()))

message("Installing drmTMB from GitHub ref: ", ref)
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak", repos = "https://cloud.r-project.org")
}
pak::pak(paste0("itchyshin/drmTMB@", ref), ask = FALSE, upgrade = FALSE)

library(drmTMB, lib.loc = lib)
installed_version <- as.character(utils::packageVersion("drmTMB"))
if (
  !is.na(expected_version) && !identical(installed_version, expected_version)
) {
  stop(
    "Expected drmTMB version ",
    expected_version,
    " but installed ",
    installed_version,
    call. = FALSE
  )
}

required_exports <- c("drmTMB", "bf", "drm_control", "check_drm")
missing_exports <- setdiff(required_exports, getNamespaceExports("drmTMB"))
if (length(missing_exports) > 0L) {
  stop(
    "Missing exported functions: ",
    paste(missing_exports, collapse = ", "),
    call. = FALSE
  )
}

set.seed(20260510)
dat <- data.frame(x = stats::rnorm(60))
dat$y <- stats::rnorm(
  nrow(dat),
  mean = 0.2 + 0.4 * dat$x,
  sd = exp(-0.4 + 0.3 * dat$x)
)

fit <- drmTMB(
  bf(y ~ x, sigma ~ x),
  family = gaussian(),
  data = dat,
  control = drm_control(
    keep_data = FALSE,
    keep_model_frame = FALSE,
    keep_tmb_object = FALSE
  )
)

checks <- check_drm(fit)
required_checks <- c("optimizer_budget", "fixed_effect_design_size")
missing_checks <- setdiff(required_checks, checks$check)
if (length(missing_checks) > 0L) {
  stop(
    "Missing diagnostic rows: ",
    paste(missing_checks, collapse = ", "),
    call. = FALSE
  )
}
if (!is.null(fit$obj) || !is.null(fit$data) || !is.null(fit$model$data)) {
  stop(
    "Storage controls did not drop the expected fitted-object components.",
    call. = FALSE
  )
}
if (!is.null(fit$model$model_frame)) {
  stop("Storage controls did not drop model frames.", call. = FALSE)
}
if (!isTRUE(all(is.finite(stats::sigma(fit))))) {
  stop("Fitted sigma values are not finite.", call. = FALSE)
}

message(
  "drmTMB install smoke passed for version ",
  installed_version,
  " from ref ",
  ref
)
