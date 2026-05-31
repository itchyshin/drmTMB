phase18_relmat_mu_slope_conditions <- function(
  n_id = c(8L, 12L),
  n_each = c(7L, 9L),
  sd_intercept = 0.55,
  sd_slope = 0.32,
  beta_mu_intercept = 0.25,
  beta_mu_x = 0.45,
  sigma = 0.22,
  matrix_decay = 0.35,
  matrix_nugget = 0.15
) {
  conditions <- expand.grid(
    n_id = as.integer(n_id),
    n_each = as.integer(n_each),
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions$sd_intercept <- sd_intercept
  conditions$sd_slope <- sd_slope
  conditions$beta_mu_intercept <- beta_mu_intercept
  conditions$beta_mu_x <- beta_mu_x
  conditions$sigma <- sigma
  conditions$matrix_decay <- matrix_decay
  conditions$matrix_nugget <- matrix_nugget
  conditions
}

phase18_dgp_relmat_mu_slope_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_id",
    "n_each",
    "sd_intercept",
    "sd_slope",
    "beta_mu_intercept",
    "beta_mu_x",
    "sigma",
    "matrix_decay",
    "matrix_nugget"
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

  phase18_dgp_relmat_mu_slope(
    n_id = cell$n_id[[1L]],
    n_each = cell$n_each[[1L]],
    beta_mu = c(
      "(Intercept)" = cell$beta_mu_intercept[[1L]],
      x = cell$beta_mu_x[[1L]]
    ),
    sigma = cell$sigma[[1L]],
    sd = c(
      "(Intercept)" = cell$sd_intercept[[1L]],
      x = cell$sd_slope[[1L]]
    ),
    matrix_decay = cell$matrix_decay[[1L]],
    matrix_nugget = cell$matrix_nugget[[1L]],
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_dgp_relmat_mu_slope <- function(
  n_id,
  n_each,
  beta_mu = c("(Intercept)" = 0.25, x = 0.45),
  sigma = 0.22,
  sd = c("(Intercept)" = 0.55, x = 0.32),
  matrix_decay = 0.35,
  matrix_nugget = 0.15,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  if (n_id < 2L) {
    stop("`n_id` must be at least 2.", call. = FALSE)
  }
  if (n_each < 2L) {
    stop("`n_each` must be at least 2.", call. = FALSE)
  }
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  sd <- phase18_named_pair(sd, c("(Intercept)", "x"), "sd")
  if (any(sd <= 0)) {
    stop("`sd` values must be positive.", call. = FALSE)
  }
  assert_phase18_positive_number(sigma, "sigma")
  phase18_assert_relmat_mu_slope_matrix_inputs(
    matrix_decay = matrix_decay,
    matrix_nugget = matrix_nugget
  )

  draw <- function() {
    id_levels <- paste0("id_", seq_len(n_id))
    K <- outer(
      seq_len(n_id),
      seq_len(n_id),
      function(i, j) matrix_decay^abs(i - j)
    )
    diag(K) <- diag(K) + matrix_nugget
    dimnames(K) <- list(id_levels, id_levels)
    Q <- solve(K)

    relmat_intercept <- as.vector(
      t(chol(K)) %*% stats::rnorm(n_id, sd = sd[["(Intercept)"]])
    )
    relmat_slope <- as.vector(
      t(chol(K)) %*% stats::rnorm(n_id, sd = sd[["x"]])
    )
    names(relmat_intercept) <- id_levels
    names(relmat_slope) <- id_levels

    id <- rep(id_levels, each = n_each)
    x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
    mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        relmat_intercept[id] +
        relmat_slope[id] * x
    )
    y <- stats::rnorm(length(id), mean = mu, sd = sigma)

    dat <- data.frame(
      y = y,
      x = x,
      id = id,
      mu = mu,
      sigma = sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "relmat_mu_slope",
      beta_mu = beta_mu,
      sigma = sigma,
      sd = stats::setNames(
        sd,
        c("relmat(1 | id)", "relmat(0 + x | id)")
      ),
      relmat_intercept = relmat_intercept,
      relmat_slope = relmat_slope,
      K = K,
      Q = Q,
      n_id = n_id,
      n_each = n_each,
      matrix_decay = matrix_decay,
      matrix_nugget = matrix_nugget
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_assert_relmat_mu_slope_matrix_inputs <- function(
  matrix_decay,
  matrix_nugget
) {
  ok_decay <- is.numeric(matrix_decay) &&
    length(matrix_decay) == 1L &&
    is.finite(matrix_decay) &&
    matrix_decay >= 0 &&
    matrix_decay < 1
  if (!ok_decay) {
    stop(
      "`matrix_decay` must be one finite number in [0, 1).",
      call. = FALSE
    )
  }
  assert_phase18_positive_number(matrix_nugget, "matrix_nugget")
  invisible(TRUE)
}
