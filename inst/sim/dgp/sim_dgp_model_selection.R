phase18_model_selection_conditions <- function(
    n_continuous = 140L,
    n_count = 160L,
    beta_mu_intercept = 0.25,
    beta_mu_x = 0.60,
    beta_sigma_intercept = -0.35,
    sigma_slope = 0.45,
    student_nu = 5,
    count_intercept = log(2.6),
    count_slope = 0.45,
    count_sigma = 0.70,
    zi_prob = 0.28) {
  rows <- list(
    phase18_model_selection_condition_row(
      scenario = "normal_tail",
      candidate_set = "gaussian_student",
      selection_target = "Gaussian",
      response_family = "gaussian",
      n = n_continuous,
      beta_mu_intercept = beta_mu_intercept,
      beta_mu_x = beta_mu_x,
      beta_sigma_intercept = beta_sigma_intercept,
      sigma_slope = 0,
      student_nu = Inf,
      count_intercept = NA_real_,
      count_slope = NA_real_,
      count_sigma = NA_real_,
      zi_prob = 0
    ),
    phase18_model_selection_condition_row(
      scenario = "heavy_tail",
      candidate_set = "gaussian_student",
      selection_target = "Student-t",
      response_family = "student",
      n = n_continuous,
      beta_mu_intercept = beta_mu_intercept,
      beta_mu_x = beta_mu_x,
      beta_sigma_intercept = beta_sigma_intercept,
      sigma_slope = 0,
      student_nu = student_nu,
      count_intercept = NA_real_,
      count_slope = NA_real_,
      count_sigma = NA_real_,
      zi_prob = 0
    ),
    phase18_model_selection_condition_row(
      scenario = "nb2_counts",
      candidate_set = "nb2_zinb2",
      selection_target = "NB2",
      response_family = "nbinom2",
      n = n_count,
      beta_mu_intercept = NA_real_,
      beta_mu_x = NA_real_,
      beta_sigma_intercept = NA_real_,
      sigma_slope = NA_real_,
      student_nu = NA_real_,
      count_intercept = count_intercept,
      count_slope = count_slope,
      count_sigma = count_sigma,
      zi_prob = 0
    ),
    phase18_model_selection_condition_row(
      scenario = "extra_zeros",
      candidate_set = "nb2_zinb2",
      selection_target = "ZINB2",
      response_family = "zinb2",
      n = n_count,
      beta_mu_intercept = NA_real_,
      beta_mu_x = NA_real_,
      beta_sigma_intercept = NA_real_,
      sigma_slope = NA_real_,
      student_nu = NA_real_,
      count_intercept = count_intercept,
      count_slope = count_slope,
      count_sigma = count_sigma,
      zi_prob = zi_prob
    ),
    phase18_model_selection_condition_row(
      scenario = "constant_sigma",
      candidate_set = "sigma_formula",
      selection_target = "sigma ~ 1",
      response_family = "gaussian",
      n = n_continuous,
      beta_mu_intercept = beta_mu_intercept,
      beta_mu_x = beta_mu_x,
      beta_sigma_intercept = beta_sigma_intercept,
      sigma_slope = 0,
      student_nu = Inf,
      count_intercept = NA_real_,
      count_slope = NA_real_,
      count_sigma = NA_real_,
      zi_prob = 0
    ),
    phase18_model_selection_condition_row(
      scenario = "sigma_signal",
      candidate_set = "sigma_formula",
      selection_target = "sigma ~ x",
      response_family = "gaussian",
      n = n_continuous,
      beta_mu_intercept = beta_mu_intercept,
      beta_mu_x = beta_mu_x,
      beta_sigma_intercept = beta_sigma_intercept,
      sigma_slope = sigma_slope,
      student_nu = Inf,
      count_intercept = NA_real_,
      count_slope = NA_real_,
      count_sigma = NA_real_,
      zi_prob = 0
    )
  )
  out <- do.call(rbind, rows)
  out$cell_id <- sprintf("model_selection_%03d", seq_len(nrow(out)))
  out <- out[c(
    "cell_id",
    setdiff(names(out), "cell_id")
  )]
  row.names(out) <- NULL
  out
}

phase18_model_selection_condition_row <- function(
    scenario,
    candidate_set,
    selection_target,
    response_family,
    n,
    beta_mu_intercept,
    beta_mu_x,
    beta_sigma_intercept,
    sigma_slope,
    student_nu,
    count_intercept,
    count_slope,
    count_sigma,
    zi_prob) {
  data.frame(
    scenario = scenario,
    candidate_set = candidate_set,
    selection_target = selection_target,
    response_family = response_family,
    n = as.integer(n),
    beta_mu_intercept = beta_mu_intercept,
    beta_mu_x = beta_mu_x,
    beta_sigma_intercept = beta_sigma_intercept,
    sigma_slope = sigma_slope,
    student_nu = student_nu,
    count_intercept = count_intercept,
    count_slope = count_slope,
    count_sigma = count_sigma,
    zi_prob = zi_prob,
    stringsAsFactors = FALSE
  )
}

phase18_dgp_model_selection_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "scenario",
    "candidate_set",
    "selection_target",
    "response_family",
    "n",
    "beta_mu_intercept",
    "beta_mu_x",
    "beta_sigma_intercept",
    "sigma_slope",
    "student_nu",
    "count_intercept",
    "count_slope",
    "count_sigma",
    "zi_prob"
  )
  missing <- setdiff(required, names(cell))
  if (length(missing) > 0L) {
    stop(
      "`cell` must contain ",
      paste(missing, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  phase18_dgp_model_selection(
    scenario = cell$scenario[[1L]],
    candidate_set = cell$candidate_set[[1L]],
    selection_target = cell$selection_target[[1L]],
    response_family = cell$response_family[[1L]],
    n = cell$n[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    beta_sigma = c(
      "(Intercept)" = cell$beta_sigma_intercept[[1L]],
      x = cell$sigma_slope[[1L]]
    ),
    student_nu = cell$student_nu[[1L]],
    count_beta = c(
      "(Intercept)" = cell$count_intercept[[1L]],
      x = cell$count_slope[[1L]]
    ),
    count_sigma = cell$count_sigma[[1L]],
    zi_prob = cell$zi_prob[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_dgp_model_selection <- function(
    scenario,
    candidate_set,
    selection_target,
    response_family,
    n,
    beta_mu = c("(Intercept)" = 0.25, x = 0.60),
    beta_sigma = c("(Intercept)" = -0.35, x = 0),
    student_nu = Inf,
    count_beta = c("(Intercept)" = log(2.6), x = 0.45),
    count_sigma = 0.70,
    zi_prob = 0,
    seed = NULL,
    cell_id = NA_character_,
    replicate = NA_integer_) {
  assert_positive_whole_number(n, "n")
  continuous_set <- candidate_set %in% c("gaussian_student", "sigma_formula")
  count_set <- identical(candidate_set, "nb2_zinb2")
  if (!continuous_set && !count_set) {
    stop("Unknown model-selection candidate set.", call. = FALSE)
  }

  if (continuous_set) {
    beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
    beta_sigma <- phase18_named_pair(
      beta_sigma,
      c("(Intercept)", "x"),
      "beta_sigma"
    )
    if (
      !is.numeric(student_nu) ||
        length(student_nu) != 1L ||
        (!is.infinite(student_nu) &&
          (!is.finite(student_nu) || student_nu <= 2))
    ) {
      stop("`student_nu` must be above 2 or `Inf`.", call. = FALSE)
    }
  } else {
    beta_mu <- c("(Intercept)" = NA_real_, x = NA_real_)
    beta_sigma <- c("(Intercept)" = NA_real_, x = NA_real_)
    student_nu <- NA_real_
  }

  if (count_set) {
    count_beta <- phase18_named_pair(
      count_beta,
      c("(Intercept)", "x"),
      "count_beta"
    )
    if (
      !is.numeric(count_sigma) ||
        length(count_sigma) != 1L ||
        !is.finite(count_sigma) ||
        count_sigma <= 0
    ) {
      stop("`count_sigma` must be one positive finite number.", call. = FALSE)
    }
    if (
      !is.numeric(zi_prob) ||
        length(zi_prob) != 1L ||
        !is.finite(zi_prob) ||
        zi_prob < 0 ||
        zi_prob >= 1
    ) {
      stop("`zi_prob` must be in [0, 1).", call. = FALSE)
    }
  } else {
    count_beta <- c("(Intercept)" = NA_real_, x = NA_real_)
    count_sigma <- NA_real_
    zi_prob <- 0
  }

  draw <- function() {
    x <- stats::rnorm(n)
    dat <- data.frame(
      x = x,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    if (candidate_set %in% c("gaussian_student", "sigma_formula")) {
      eta_mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
      eta_sigma <- unname(
        beta_sigma[["(Intercept)"]] + beta_sigma[["x"]] * x
      )
      sigma <- exp(eta_sigma)
      if (identical(response_family, "student")) {
        y <- eta_mu + sigma * stats::rt(n, df = student_nu)
      } else {
        y <- stats::rnorm(n, mean = eta_mu, sd = sigma)
      }
      dat$y <- y
      dat$mu <- eta_mu
      dat$sigma <- sigma
    } else if (identical(candidate_set, "nb2_zinb2")) {
      eta_mu <- unname(count_beta[["(Intercept)"]] + count_beta[["x"]] * x)
      mu <- exp(eta_mu)
      count <- as.integer(stats::rnbinom(n, size = 1 / count_sigma^2, mu = mu))
      structural_zero <- stats::runif(n) < zi_prob
      count[structural_zero] <- 0L
      dat$count <- count
      dat$mu <- mu
      dat$sigma <- count_sigma
      dat$structural_zero <- structural_zero
    } else {
      stop("Unknown model-selection candidate set.", call. = FALSE)
    }
    attr(dat, "truth") <- list(
      surface = "model_selection",
      scenario = scenario,
      candidate_set = candidate_set,
      selection_target = selection_target,
      response_family = response_family,
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      student_nu = student_nu,
      count_beta = count_beta,
      count_sigma = count_sigma,
      zi_prob = zi_prob,
      n = n
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}
