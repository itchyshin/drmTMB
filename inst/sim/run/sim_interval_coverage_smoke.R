phase18_add_synthetic_intervals <- function(
  summary,
  half_width = 0.25,
  lower = "conf.low",
  upper = "conf.high"
) {
  phase18_assert_summary_columns(summary, c("parameter", "truth", "estimate"))
  if (
    !is.numeric(half_width) ||
      !(length(half_width) %in% c(1L, nrow(summary))) ||
      any(!is.finite(half_width)) ||
      any(half_width <= 0)
  ) {
    stop(
      "`half_width` must be one positive finite number or one value per row.",
      call. = FALSE
    )
  }
  if (
    !is.character(lower) ||
      length(lower) != 1L ||
      !nzchar(lower) ||
      !is.character(upper) ||
      length(upper) != 1L ||
      !nzchar(upper)
  ) {
    stop("`lower` and `upper` must be non-empty column names.", call. = FALSE)
  }

  estimate <- phase18_finite_numeric_vector(summary$estimate, "estimate")
  width <- rep(half_width, length.out = nrow(summary))
  out <- summary
  out[[lower]] <- estimate - width
  out[[upper]] <- estimate + width
  out
}

phase18_summarise_synthetic_interval_smoke <- function(
  summary,
  by = NULL,
  half_width = 0.25,
  lower = "conf.low",
  upper = "conf.high"
) {
  augmented <- phase18_add_synthetic_intervals(
    summary,
    half_width = half_width,
    lower = lower,
    upper = upper
  )
  coverage <- phase18_summarise_interval_coverage(
    augmented,
    by = by,
    lower = lower,
    upper = upper
  )
  list(
    interval_source = "synthetic",
    summary = augmented,
    coverage = coverage
  )
}
