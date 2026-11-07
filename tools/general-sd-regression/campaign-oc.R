# Synthetic operating-characteristic stress test for the frozen Bernoulli
# two-look decision rule. This simulates attempt summaries, not fitted models.

native_sd_staged_decision <- local({
  decision_path <- file.path(
    "tools", "general-sd-regression", "native-calibration", "staged-decision.R"
  )
  if (!file.exists(decision_path)) decision_path <- "native-calibration/staged-decision.R"
  e <- new.env(parent = environment())
  sys.source(decision_path, envir = e)
  e$native_sd_staged_decision
})

normal_width_for_coverage <- function(bias, estimator_sd, coverage = 0.95) {
  shift <- bias / estimator_sd
  stats::uniroot(function(width) {
    stats::pnorm(width - shift) - stats::pnorm(-width - shift) - coverage
  }, interval = c(0, 10), tol = 1e-10)$root
}

campaign_oc_scenarios <- function() {
  estimator_sd <- 0.12
  nominal_width <- stats::qnorm(0.975)
  log_bias_boundary <- 0.10
  relative_bias_boundary <- log1p(0.10) - 0.5 * estimator_sd^2
  data.frame(
    scenario = c(
      "nominal", "undercoverage", "overcoverage", "low_validity",
      "log_sd_bias", "informative_invalidity", "joint_lower_boundary",
      "joint_upper_boundary", "log_bias_boundary", "relative_bias_boundary",
      "fit_failures"
    ),
    estimator_sd = rep(estimator_sd, 11L),
    interval_width = c(
      nominal_width, 1.55, 2.42, nominal_width, nominal_width, nominal_width,
      stats::qnorm((1 + 0.925 / 0.95) / 2), stats::qnorm(0.9875),
      normal_width_for_coverage(log_bias_boundary, estimator_sd),
      normal_width_for_coverage(relative_bias_boundary, estimator_sd), nominal_width
    ),
    bias = c(
      0, 0, 0, 0, 0.16, 0, 0, 0, log_bias_boundary,
      relative_bias_boundary, 0
    ),
    valid_fraction = c(0.99, 0.99, 0.99, 0.90, 0.99, 0.95,
                       0.95, 1.00, 0.99, 0.99, 0.99),
    validity_error_correlation = c(0, 0, 0, 0, 0, 0.70, 0, 0, 0, 0, 0),
    fit_failure_fraction = c(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0.08),
    stringsAsFactors = FALSE
  )
}

simulate_campaign_attempts <- function(n_per_truth, scenario) {
  truths <- c(-0.5, 0, 0.5)
  n <- 3L * n_per_truth
  error_z <- stats::rnorm(n)
  validity_noise <- stats::rnorm(n)
  rho <- scenario$validity_error_correlation[[1L]]
  validity_score <- rho * error_z + sqrt(1 - rho^2) * validity_noise
  fit_ok <- stats::runif(n) >= scenario$fit_failure_fraction[[1L]]
  valid <- fit_ok &
    validity_score <= stats::qnorm(scenario$valid_fraction[[1L]])
  estimate <- rep(truths, each = n_per_truth) + scenario$bias[[1L]] +
    scenario$estimator_sd[[1L]] * error_z
  estimate[!fit_ok] <- NA_real_
  half_width <- scenario$interval_width[[1L]] * scenario$estimator_sd[[1L]]
  lower <- estimate - half_width
  upper <- estimate + half_width
  lower[!valid] <- NA_real_
  upper[!valid] <- NA_real_
  data.frame(
    truth = rep(truths, each = n_per_truth), estimate = estimate,
    lower = lower, upper = upper, valid = valid,
    status = ifelse(fit_ok, "completed", "error"),
    stringsAsFactors = FALSE
  )
}

simulate_one_campaign <- function(scenario) {
  first <- simulate_campaign_attempts(1000L, scenario)
  decision1 <- native_sd_staged_decision(
    first, manifest_count = 3000L, look = 1L, completed_campaign = TRUE
  )
  if (decision1$decision != "look2_required") {
    return(list(decision = decision1$decision, look2_decision = NA_character_,
                look2 = FALSE, attempts = 3000L))
  }
  second <- simulate_campaign_attempts(3000L, scenario)
  cumulative <- rbind(first, second)
  decision2 <- native_sd_staged_decision(
    cumulative, manifest_count = 12000L, look = 2L,
    completed_campaign = TRUE
  )
  list(decision = decision2$decision, look2_decision = decision2$decision,
       look2 = TRUE, attempts = 12000L)
}

summarize_look2_outcomes <- function(look2_decision, n_campaigns) {
  if (length(n_campaigns) != 1L || is.na(n_campaigns) ||
      n_campaigns < 1L || length(look2_decision) != n_campaigns) {
    stop("look-two outcomes must match a positive campaign count", call. = FALSE)
  }
  statuses <- c("accept", "fail", "inconclusive")
  unexpected <- setdiff(as.character(look2_decision[!is.na(look2_decision)]), statuses)
  if (length(unexpected) > 0L) {
    stop("unexpected look-two outcome: ", unexpected[[1L]], call. = FALSE)
  }
  reached <- !is.na(look2_decision)
  n_reached <- sum(reached)
  out <- list(look2_required = as.integer(n_reached))
  for (status in statuses) {
    count <- sum(look2_decision[reached] == status)
    unconditional <- stats::binom.test(count, n_campaigns,
                                        conf.level = 0.95)$conf.int
    out[[paste0("look2_", status, "_probability")]] <- count / n_campaigns
    out[[paste0("look2_", status, "_mc_lower")]] <- unconditional[[1L]]
    out[[paste0("look2_", status, "_mc_upper")]] <- unconditional[[2L]]
    if (n_reached == 0L) {
      conditional <- c(NA_real_, NA_real_)
      conditional_probability <- NA_real_
    } else {
      conditional <- stats::binom.test(count, n_reached,
                                       conf.level = 0.95)$conf.int
      conditional_probability <- count / n_reached
    }
    suffix <- paste0(status, "_given_look2")
    out[[paste0("look2_", suffix, "_probability")]] <- conditional_probability
    out[[paste0("look2_", suffix, "_mc_lower")]] <- conditional[[1L]]
    out[[paste0("look2_", suffix, "_mc_upper")]] <- conditional[[2L]]
  }
  out
}

campaign_oc <- function(n_campaigns = 100L, seed = 20261019L,
                        scenarios = campaign_oc_scenarios()) {
  if (length(n_campaigns) != 1L || !is.finite(n_campaigns) ||
      n_campaigns < 2L || n_campaigns != as.integer(n_campaigns)) {
    stop("n_campaigns must be one whole number of at least two", call. = FALSE)
  }
  required <- c("scenario", "estimator_sd", "interval_width", "bias",
                "valid_fraction", "validity_error_correlation",
                "fit_failure_fraction")
  if (!is.data.frame(scenarios) || nrow(scenarios) < 1L ||
      !all(required %in% names(scenarios)) || anyNA(scenarios[required]) ||
      anyDuplicated(scenarios$scenario) || any(scenarios$estimator_sd <= 0) ||
      any(scenarios$interval_width <= 0) ||
      any(scenarios$valid_fraction <= 0 | scenarios$valid_fraction > 1) ||
      any(scenarios$fit_failure_fraction < 0 | scenarios$fit_failure_fraction >= 1) ||
      any(abs(scenarios$validity_error_correlation) >= 1)) {
    stop("Invalid scenario table", call. = FALSE)
  }
  set.seed(seed)
  rows <- vector("list", nrow(scenarios))
  for (s in seq_len(nrow(scenarios))) {
    outcomes <- lapply(seq_len(as.integer(n_campaigns)), function(i) {
      simulate_one_campaign(scenarios[s, , drop = FALSE])
    })
    decision <- vapply(outcomes, `[[`, character(1L), "decision")
    look2_decision <- vapply(outcomes, `[[`, character(1L), "look2_decision")
    look2 <- vapply(outcomes, `[[`, logical(1L), "look2")
    attempts <- vapply(outcomes, `[[`, integer(1L), "attempts")
    count <- function(x) sum(decision == x)
    look2_count <- function(x) sum(look2_decision == x, na.rm = TRUE)
    event_counts <- c(
      early_accept = sum(decision == "accept" & !look2),
      early_fail = sum(decision == "fail" & !look2),
      look2_required = sum(look2),
      look2_accept = look2_count("accept"),
      look2_fail = look2_count("fail"),
      look2_inconclusive = look2_count("inconclusive"),
      accept = count("accept"), fail = count("fail"),
      inconclusive = count("inconclusive")
    )
    row <- data.frame(
      scenario = scenarios$scenario[[s]], n_campaigns = n_campaigns,
      early_accept = event_counts[["early_accept"]],
      early_fail = event_counts[["early_fail"]],
      look2_required = event_counts[["look2_required"]],
      look2_accept = event_counts[["look2_accept"]],
      look2_fail = event_counts[["look2_fail"]],
      look2_inconclusive = event_counts[["look2_inconclusive"]],
      accept = event_counts[["accept"]], fail = event_counts[["fail"]],
      inconclusive = event_counts[["inconclusive"]],
      expected_attempts = mean(attempts), seed = seed,
      stringsAsFactors = FALSE
    )
    for (name in names(event_counts)) {
      ci <- stats::binom.test(event_counts[[name]], n_campaigns,
                              conf.level = 0.95)$conf.int
      row[[paste0(name, "_mc_lower")]] <- ci[[1L]]
      row[[paste0(name, "_mc_upper")]] <- ci[[2L]]
    }
    mean_attempts <- mean(attempts)
    half_width <- stats::qt(0.975, df = n_campaigns - 1L) *
      stats::sd(attempts) / sqrt(n_campaigns)
    row$expected_attempts_mc_lower <- mean_attempts - half_width
    row$expected_attempts_mc_upper <- mean_attempts + half_width
    look2_summary <- summarize_look2_outcomes(look2_decision, n_campaigns)
    for (name in names(look2_summary)) row[[name]] <- look2_summary[[name]]
    rows[[s]] <- row
  }
  out <- do.call(rbind, rows)
  if (any(out$accept + out$fail + out$inconclusive != out$n_campaigns) ||
      any(out$early_accept + out$early_fail + out$look2_required != out$n_campaigns) ||
      any(out$look2_accept + out$look2_fail + out$look2_inconclusive !=
            out$look2_required)) {
    stop("Campaign outcomes do not partition all simulations", call. = FALSE)
  }
  out
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  n <- if (length(args) >= 1L) as.integer(args[[1L]]) else 100L
  seed <- if (length(args) >= 2L) as.integer(args[[2L]]) else 20261019L
  print(campaign_oc(n_campaigns = n, seed = seed), row.names = FALSE)
}
