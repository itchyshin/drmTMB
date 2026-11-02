# Exact component-wise operating characteristics for the prospective
# two-look Bernoulli calibration screen. This does not model dependence among
# calibration cells or the fitted-model bias gates.

calibration_gate_state <- function(k, n, metric,
                                   coverage_band = c(0.925, 0.975),
                                   fpr_band = c(0.025, 0.075),
                                   valid_floor = 0.950) {
  ci <- stats::binom.test(k, n, conf.level = 0.975)$conf.int
  band <- switch(metric,
    coverage = coverage_band,
    fpr = fpr_band,
    valid = c(valid_floor, Inf),
    stop("Unknown metric: ", metric, call. = FALSE)
  )
  if (metric == "valid") {
    if (ci[[1L]] >= band[[1L]]) return("pass")
    if (ci[[2L]] < band[[1L]]) return("fail")
    return("ambiguous")
  }
  if (ci[[1L]] >= band[[1L]] && ci[[2L]] <= band[[2L]]) return("pass")
  if (ci[[2L]] < band[[1L]] || ci[[1L]] > band[[2L]]) return("fail")
  "ambiguous"
}

state_map <- function(n, metric, ...) {
  states <- vapply(seq.int(0L, n), calibration_gate_state, character(1L),
                   n = n, metric = metric, ...)
  if (anyNA(states) || any(!states %in% c("pass", "fail", "ambiguous"))) {
    stop("Every count must have exactly one decision state", call. = FALSE)
  }
  states
}

state_ranges <- function(states, state) {
  counts <- which(states == state) - 1L
  if (!length(counts)) return(list())
  groups <- split(counts, cumsum(c(TRUE, diff(counts) != 1L)))
  lapply(groups, function(x) c(min(x), max(x)))
}

range_probability <- function(count_ranges, offset, n, p) {
  if (!length(count_ranges)) return(0)
  sum(vapply(count_ranges, function(count_range) {
    if (length(count_range) != 2L || anyNA(count_range)) return(0)
    lo <- max(0L, count_range[[1L]] - offset)
    hi <- min(n, count_range[[2L]] - offset)
    if (hi < lo) return(0)
    min(1, max(0, stats::pbinom(hi, n, p) -
                   stats::pbinom(lo - 1L, n, p)))
  }, numeric(1L)))
}

staged_gate_oc <- function(p, metric, n1 = 1000L, n2 = 3000L, ...) {
  if (!is.numeric(p) || length(p) != 1L || !is.finite(p) || p < 0 || p > 1) {
    stop("p must be one probability in [0, 1]", call. = FALSE)
  }
  first <- state_map(n1, metric, ...)
  cumulative <- state_map(n1 + n2, metric, ...)
  first_pmf <- stats::dbinom(seq.int(0L, n1), n1, p)
  pass_ranges <- state_ranges(cumulative, "pass")
  fail_ranges <- state_ranges(cumulative, "fail")
  out <- c(look1_pass = 0, look1_fail = 0, look1_ambiguous = 0,
           final_pass = 0, final_fail = 0, final_inconclusive = 0)
  for (k1 in seq.int(0L, n1)) {
    prob1 <- first_pmf[[k1 + 1L]]
    state1 <- first[[k1 + 1L]]
    out[[paste0("look1_", state1)]] <-
      out[[paste0("look1_", state1)]] + prob1
    if (state1 != "ambiguous") {
      out[[paste0("final_", if (state1 == "pass") "pass" else "fail")]] <-
        out[[paste0("final_", if (state1 == "pass") "pass" else "fail")]] + prob1
      next
    }
    pass2 <- range_probability(pass_ranges, k1, n2, p)
    fail2 <- range_probability(fail_ranges, k1, n2, p)
    out[["final_pass"]] <- out[["final_pass"]] + prob1 * pass2
    out[["final_fail"]] <- out[["final_fail"]] + prob1 * fail2
    out[["final_inconclusive"]] <- out[["final_inconclusive"]] +
      prob1 * max(0, 1 - pass2 - fail2)
  }
  if (abs(sum(out[1:3]) - 1) > 1e-10 || abs(sum(out[4:6]) - 1) > 1e-10) {
    stop("Operating-characteristic probabilities do not sum to one",
         call. = FALSE)
  }
  out
}

scenarios <- list(
  coverage = c(nominal = 0.950, lower_margin = 0.925,
               undercoverage_1pp_beyond = 0.915,
               undercoverage_2_5pp_beyond = 0.900,
               upper_margin = 0.975, overcoverage_1_5pp = 0.990),
  fpr = c(nominal = 0.050, lower_margin = 0.025, upper_margin = 0.075,
          inflation_1pp_beyond = 0.085,
          inflation_2_5pp_beyond = 0.100,
          under_rejection = 0.010),
  valid = c(high_availability = 0.990, floor = 0.950,
            below_floor = 0.930)
)

# Two-sided bands have two disjoint fail tails; collapsing them to one range
# would count the central acceptance set as failure at the cumulative look.
if (length(state_ranges(state_map(1000L, "coverage"), "fail")) != 2L ||
    length(state_ranges(state_map(1000L, "fpr"), "fail")) != 2L) {
  stop("Two-sided coverage and FPR gates must retain both fail tails",
       call. = FALSE)
}

results <- do.call(rbind, lapply(names(scenarios), function(metric) {
  do.call(rbind, lapply(names(scenarios[[metric]]), function(scenario) {
    p <- unname(scenarios[[metric]][[scenario]])
    oc <- staged_gate_oc(p, metric)
    data.frame(metric = metric, scenario = scenario, true_rate = p,
               as.list(oc), row.names = NULL, check.names = FALSE)
  }))
}))

probability_columns <- setdiff(names(results),
                               c("metric", "scenario", "true_rate"))
if (any(!vapply(results[probability_columns], is.numeric, logical(1L)))) {
  stop("Result probabilities must be numeric", call. = FALSE)
}
cat("Exact binomial operating characteristics; component gates only\n")
for (i in seq_len(nrow(results))) {
  x <- results[i, ]
  cat(sprintf(
    paste0("%s | %s (p=%.3f) | look 1 pass/fail/ambiguous %.4f/%.4f/%.4f",
           " | final pass/fail/inconclusive %.4f/%.4f/%.4f\n"),
    x$metric, x$scenario, x$true_rate,
    x$look1_pass, x$look1_fail, x$look1_ambiguous,
    x$final_pass, x$final_fail, x$final_inconclusive
  ))
}
