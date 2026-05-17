phase18_gaussian_ls_conditions <- function(
  n = c(120L, 360L),
  sigma_slope = c(0, 0.35),
  collinearity = c(0, 0.6),
  beta_mu_intercept = 0.25,
  beta_mu_x = 0.60,
  beta_sigma_intercept = -0.30
) {
  conditions <- expand.grid(
    n = as.integer(n),
    sigma_slope = sigma_slope,
    collinearity = collinearity,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions$beta_sigma_intercept <- beta_sigma_intercept
  conditions
}

phase18_dgp_gaussian_ls <- function(
  n,
  beta_mu = c("(Intercept)" = 0.25, x = 0.60),
  beta_sigma = c("(Intercept)" = -0.30, z = 0.35),
  collinearity = 0,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  assert_phase18_correlation(collinearity, "collinearity")

  draw <- function() {
    x <- stats::rnorm(n)
    z_noise <- stats::rnorm(n)
    z <- collinearity * x + sqrt(1 - collinearity^2) * z_noise
    mu <- unname(beta_mu[["(Intercept)"]] + beta_mu[["x"]] * x)
    log_sigma <- unname(
      beta_sigma[["(Intercept)"]] + beta_sigma[["z"]] * z
    )
    sigma <- exp(log_sigma)
    y <- stats::rnorm(n, mean = mu, sd = sigma)

    dat <- data.frame(
      y = y,
      x = x,
      z = z,
      mu = mu,
      sigma = sigma,
      log_sigma = log_sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "gaussian_ls",
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      n = n,
      collinearity = collinearity
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_named_pair <- function(x, expected, name) {
  if (!is.numeric(x) || length(x) != 2L || any(!is.finite(x))) {
    stop(
      "`",
      name,
      "` must be a finite numeric vector of length 2.",
      call. = FALSE
    )
  }
  current <- names(x)
  if (is.null(current) || any(!nzchar(current))) {
    names(x) <- expected
    return(x)
  }
  if (!setequal(current, expected)) {
    stop(
      "`",
      name,
      "` must be unnamed or named with ",
      paste(expected, collapse = " and "),
      ".",
      call. = FALSE
    )
  }
  x[expected]
}

assert_phase18_correlation <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    abs(x) < 1
  if (!ok) {
    stop(
      "`",
      name,
      "` must be one finite number with absolute value below 1.",
      call. = FALSE
    )
  }
  invisible(x)
}

phase18_with_seed <- function(seed, code) {
  assert_positive_whole_number(seed, "seed")
  old_seed <- if (
    exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  ) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit(
    {
      if (is.null(old_seed)) {
        rm(list = ".Random.seed", envir = .GlobalEnv)
      } else {
        assign(".Random.seed", old_seed, envir = .GlobalEnv)
      }
    },
    add = TRUE
  )

  set.seed(seed)
  code()
}
