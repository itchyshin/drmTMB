phase18_animal_relmat_q2_conditions <- function(
  structured_surface = c("animal", "relmat"),
  matrix_argument = c("precision", "covariance", "pedigree"),
  n_level = 10L,
  n_per_level = 6L,
  matrix_decay = 0.40,
  sd_struct1 = 0.60,
  sd_struct2 = 0.50,
  rho_struct = 0.35,
  sigma1 = 0.22,
  sigma2 = 0.24,
  rho12 = -0.10,
  beta_mu1_intercept = 0.25,
  beta_mu1_x = 0.35,
  beta_mu2_intercept = -0.15,
  beta_mu2_x = -0.25
) {
  structured_surface <- match.arg(
    structured_surface,
    choices = c("animal", "relmat"),
    several.ok = TRUE
  )
  matrix_argument <- match.arg(
    matrix_argument,
    choices = c("precision", "covariance", "pedigree"),
    several.ok = TRUE
  )
  conditions <- expand.grid(
    structured_surface = structured_surface,
    matrix_argument = matrix_argument,
    n_level = as.integer(n_level),
    n_per_level = as.integer(n_per_level),
    matrix_decay = matrix_decay,
    sd_struct1 = sd_struct1,
    sd_struct2 = sd_struct2,
    rho_struct = rho_struct,
    sigma1 = sigma1,
    sigma2 = sigma2,
    rho12 = rho12,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions <- conditions[
    !(conditions$structured_surface == "relmat" &
      conditions$matrix_argument == "pedigree"),
    ,
    drop = FALSE
  ]
  if (nrow(conditions) == 0L) {
    stop(
      "`matrix_argument = \"pedigree\"` is only available for `structured_surface = \"animal\"`.",
      call. = FALSE
    )
  }
  conditions$beta_mu1_intercept <- beta_mu1_intercept
  conditions$beta_mu1_x <- beta_mu1_x
  conditions$beta_mu2_intercept <- beta_mu2_intercept
  conditions$beta_mu2_x <- beta_mu2_x
  conditions
}

phase18_dgp_animal_relmat_q2 <- function(
  n_level,
  n_per_level,
  surface = c("animal", "relmat"),
  matrix_argument = c("precision", "covariance", "pedigree"),
  matrix_decay = 0.40,
  beta_mu1 = c("(Intercept)" = 0.25, x = 0.35),
  beta_mu2 = c("(Intercept)" = -0.15, x = -0.25),
  sd_struct = c(mu1 = 0.60, mu2 = 0.50),
  rho_struct = 0.35,
  sigma = c(sigma1 = 0.22, sigma2 = 0.24),
  rho12 = -0.10,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_level, "n_level")
  assert_positive_whole_number(n_per_level, "n_per_level")
  surface <- match.arg(surface)
  matrix_argument <- match.arg(matrix_argument)
  if (identical(matrix_argument, "pedigree") && !identical(surface, "animal")) {
    stop(
      "`matrix_argument = \"pedigree\"` is only available for `surface = \"animal\"`.",
      call. = FALSE
    )
  }
  assert_phase18_correlation(matrix_decay, "matrix_decay")
  if (matrix_decay < 0) {
    stop("`matrix_decay` must be non-negative.", call. = FALSE)
  }
  beta_mu1 <- phase18_named_pair(
    beta_mu1,
    c("(Intercept)", "x"),
    "beta_mu1"
  )
  beta_mu2 <- phase18_named_pair(
    beta_mu2,
    c("(Intercept)", "x"),
    "beta_mu2"
  )
  if (
    !is.numeric(sd_struct) ||
      length(sd_struct) != 2L ||
      any(!is.finite(sd_struct)) ||
      any(sd_struct <= 0)
  ) {
    stop("`sd_struct` must be two positive finite numbers.", call. = FALSE)
  }
  if (
    !is.numeric(sigma) ||
      length(sigma) != 2L ||
      any(!is.finite(sigma)) ||
      any(sigma <= 0)
  ) {
    stop("`sigma` must be two positive finite numbers.", call. = FALSE)
  }
  assert_phase18_correlation(rho_struct, "rho_struct")
  assert_phase18_correlation(rho12, "rho12")

  draw <- function() {
    id_levels <- paste0("id", seq_len(n_level))
    pedigree <- NULL
    if (identical(matrix_argument, "pedigree")) {
      pedigree <- phase18_animal_relmat_q2_pedigree(id_levels)
      K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    } else {
      K <- outer(
        seq_len(n_level),
        seq_len(n_level),
        function(i, j) matrix_decay^abs(i - j)
      )
      diag(K) <- 1
      dimnames(K) <- list(id_levels, id_levels)
    }
    Q <- solve(K)

    id <- rep(id_levels, each = n_per_level)
    n <- length(id)
    x <- stats::rnorm(n)

    z1 <- stats::rnorm(n_level)
    z2 <- rho_struct * z1 + sqrt(1 - rho_struct^2) * stats::rnorm(n_level)
    known1 <- as.vector(t(chol(K)) %*% z1) * sd_struct[[1L]]
    known2 <- as.vector(t(chol(K)) %*% z2) * sd_struct[[2L]]
    names(known1) <- id_levels
    names(known2) <- id_levels

    e1 <- stats::rnorm(n)
    e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
    mu1 <- unname(beta_mu1[["(Intercept)"]] + beta_mu1[["x"]] * x + known1[id])
    mu2 <- unname(beta_mu2[["(Intercept)"]] + beta_mu2[["x"]] * x + known2[id])

    dat <- data.frame(
      y1 = mu1 + sigma[[1L]] * e1,
      y2 = mu2 + sigma[[2L]] * e2,
      x = x,
      id = factor(id, levels = id_levels),
      mu1 = mu1,
      mu2 = mu2,
      sigma1 = sigma[[1L]],
      sigma2 = sigma[[2L]],
      rho12 = rho12,
      residual_covariance = rho12 * sigma[[1L]] * sigma[[2L]],
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "animal_relmat_q2",
      structured_surface = surface,
      matrix_argument = matrix_argument,
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      sd_struct = stats::setNames(as.numeric(sd_struct), c("mu1", "mu2")),
      rho_struct = rho_struct,
      sigma = stats::setNames(as.numeric(sigma), c("sigma1", "sigma2")),
      rho12 = rho12,
      K = K,
      Q = Q,
      pedigree = pedigree,
      n_level = n_level,
      n_per_level = n_per_level,
      matrix_decay = matrix_decay
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_animal_relmat_q2_pedigree <- function(id_levels) {
  id_levels <- as.character(id_levels)
  if (length(id_levels) < 2L || anyNA(id_levels) || any(!nzchar(id_levels))) {
    stop(
      "`id_levels` must contain at least two non-missing labels.",
      call. = FALSE
    )
  }
  dam <- rep(NA_character_, length(id_levels))
  sire <- rep(NA_character_, length(id_levels))
  if (length(id_levels) >= 3L) {
    for (i in seq.int(3L, length(id_levels))) {
      dam[[i]] <- id_levels[[i - 2L]]
      sire[[i]] <- id_levels[[i - 1L]]
    }
  }
  data.frame(
    id = id_levels,
    dam = dam,
    sire = sire,
    stringsAsFactors = FALSE
  )
}
