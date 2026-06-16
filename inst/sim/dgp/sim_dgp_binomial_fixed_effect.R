phase18_binomial_fe_conditions <- function(
  encoding = c("binary", "cbind"),
  n = c(240L, 480L),
  trial_min = c(8L, 20L),
  trial_max = c(12L, 30L),
  beta_mu_intercept = -0.20,
  beta_mu_x = 0.60
) {
  encoding <- phase18_binomial_fe_encoding(encoding, several.ok = TRUE)
  if (length(trial_min) != length(trial_max)) {
    stop(
      "`trial_min` and `trial_max` must have the same length.",
      call. = FALSE
    )
  }
  trial_min <- as.integer(trial_min)
  trial_max <- as.integer(trial_max)
  bad_trials <- is.na(trial_min) |
    is.na(trial_max) |
    trial_min < 1L |
    trial_max < trial_min
  if (any(bad_trials)) {
    stop(
      "`trial_min` and `trial_max` must define positive integer ranges.",
      call. = FALSE
    )
  }

  base <- expand.grid(
    n = as.integer(n),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  base$beta_mu_intercept <- beta_mu_intercept
  base$beta_mu_x <- beta_mu_x

  pieces <- list()
  if ("binary" %in% encoding) {
    binary_rows <- base
    binary_rows$encoding <- "binary"
    binary_rows$trial_min <- NA_integer_
    binary_rows$trial_max <- NA_integer_
    pieces$binary <- binary_rows
  }
  if ("cbind" %in% encoding) {
    trial_bands <- data.frame(
      trial_min = trial_min,
      trial_max = trial_max
    )
    cbind_rows <- merge(base, trial_bands, all = TRUE, sort = FALSE)
    cbind_rows$encoding <- "cbind"
    pieces$cbind <- cbind_rows
  }

  out <- do.call(rbind, pieces)
  row.names(out) <- NULL
  out[c(
    "encoding",
    "n",
    "trial_min",
    "trial_max",
    "beta_mu_intercept",
    "beta_mu_x"
  )]
}

phase18_dgp_binomial_fe <- function(
  n,
  encoding = c("binary", "cbind"),
  beta_mu = c("(Intercept)" = -0.20, x = 0.60),
  trial_min = 8L,
  trial_max = 12L,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  encoding <- phase18_binomial_fe_encoding(encoding)
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  if (identical(encoding, "cbind")) {
    phase18_binomial_fe_assert_trial_range(trial_min, trial_max)
  }

  draw <- function() {
    x <- stats::rnorm(n)
    eta_mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    mu <- stats::plogis(eta_mu)

    if (identical(encoding, "binary")) {
      y01 <- stats::rbinom(n, size = 1L, prob = mu)
      dat <- data.frame(
        y01 = y01,
        x = x,
        eta_mu = eta_mu,
        mu = mu,
        trials = 1L,
        encoding = encoding,
        cell_id = cell_id,
        replicate = replicate,
        stringsAsFactors = FALSE
      )
    } else {
      trials <- sample(seq.int(trial_min, trial_max), n, replace = TRUE)
      success <- stats::rbinom(n, size = trials, prob = mu)
      failure <- trials - success
      dat <- data.frame(
        success = success,
        failure = failure,
        trials = trials,
        observed_prop = success / trials,
        x = x,
        eta_mu = eta_mu,
        mu = mu,
        encoding = encoding,
        cell_id = cell_id,
        replicate = replicate,
        stringsAsFactors = FALSE
      )
    }
    attr(dat, "truth") <- list(
      surface = "binomial_fixed_effect",
      encoding = encoding,
      beta_mu = beta_mu,
      n = n,
      trial_min = if (identical(encoding, "cbind")) trial_min else NA_integer_,
      trial_max = if (identical(encoding, "cbind")) trial_max else NA_integer_
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_binomial_fe_encoding <- function(
  encoding,
  several.ok = FALSE
) {
  choices <- c("binary", "cbind")
  if (
    !is.character(encoding) ||
      length(encoding) == 0L ||
      anyNA(encoding) ||
      any(!nzchar(encoding)) ||
      any(!encoding %in% choices)
  ) {
    stop(
      "`encoding` must be ",
      if (several.ok) "one or more of " else "one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!several.ok && length(encoding) != 1L) {
    stop(
      "`encoding` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(encoding)
}

phase18_binomial_fe_assert_trial_range <- function(trial_min, trial_max) {
  trial_min <- as.integer(trial_min)
  trial_max <- as.integer(trial_max)
  ok <- length(trial_min) == 1L &&
    length(trial_max) == 1L &&
    !is.na(trial_min) &&
    !is.na(trial_max) &&
    trial_min >= 1L &&
    trial_max >= trial_min
  if (!ok) {
    stop(
      "`trial_min` and `trial_max` must define one positive integer range.",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
