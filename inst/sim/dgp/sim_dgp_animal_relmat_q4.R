phase18_animal_relmat_q4_conditions <- function(
  structured_surface = c("animal", "relmat"),
  matrix_argument = c("precision", "covariance", "pedigree"),
  n_level = 12L,
  n_per_level = 7L,
  matrix_decay = 0.32,
  matrix_jitter = 0.12,
  sd_mu1 = 0.42,
  sd_mu2 = 0.36,
  sd_sigma1 = 0.16,
  sd_sigma2 = 0.14,
  cor_mu1_mu2 = 0.35,
  cor_mu1_sigma1 = 0.12,
  cor_mu1_sigma2 = -0.08,
  cor_mu2_sigma1 = 0.10,
  cor_mu2_sigma2 = 0.18,
  cor_sigma1_sigma2 = 0.30,
  rho12 = -0.08,
  beta_mu1_intercept = 0.20,
  beta_mu1_x = 0.28,
  beta_mu2_intercept = -0.15,
  beta_mu2_x = -0.22,
  beta_sigma1_intercept = -1.05,
  beta_sigma1_z = 0.12,
  beta_sigma2_intercept = -1.10,
  beta_sigma2_z = -0.10
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
    matrix_jitter = matrix_jitter,
    sd_mu1 = sd_mu1,
    sd_mu2 = sd_mu2,
    sd_sigma1 = sd_sigma1,
    sd_sigma2 = sd_sigma2,
    cor_mu1_mu2 = cor_mu1_mu2,
    cor_mu1_sigma1 = cor_mu1_sigma1,
    cor_mu1_sigma2 = cor_mu1_sigma2,
    cor_mu2_sigma1 = cor_mu2_sigma1,
    cor_mu2_sigma2 = cor_mu2_sigma2,
    cor_sigma1_sigma2 = cor_sigma1_sigma2,
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
  conditions$beta_sigma1_intercept <- beta_sigma1_intercept
  conditions$beta_sigma1_z <- beta_sigma1_z
  conditions$beta_sigma2_intercept <- beta_sigma2_intercept
  conditions$beta_sigma2_z <- beta_sigma2_z
  conditions
}

phase18_dgp_animal_relmat_q4 <- function(
  n_level,
  n_per_level,
  surface = c("animal", "relmat"),
  matrix_argument = c("precision", "covariance", "pedigree"),
  matrix_decay = 0.32,
  matrix_jitter = 0.12,
  beta_mu1 = c("(Intercept)" = 0.20, x = 0.28),
  beta_mu2 = c("(Intercept)" = -0.15, x = -0.22),
  beta_sigma1 = c("(Intercept)" = -1.05, z = 0.12),
  beta_sigma2 = c("(Intercept)" = -1.10, z = -0.10),
  sd_struct = c(mu1 = 0.42, mu2 = 0.36, sigma1 = 0.16, sigma2 = 0.14),
  cor_struct = phase18_animal_relmat_q4_cor_matrix(),
  rho12 = -0.08,
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
  if (
    !is.numeric(matrix_jitter) ||
      length(matrix_jitter) != 1L ||
      !is.finite(matrix_jitter) ||
      matrix_jitter < 0
  ) {
    stop(
      "`matrix_jitter` must be one non-negative finite number.",
      call. = FALSE
    )
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
  beta_sigma1 <- phase18_named_pair(
    beta_sigma1,
    c("(Intercept)", "z"),
    "beta_sigma1"
  )
  beta_sigma2 <- phase18_named_pair(
    beta_sigma2,
    c("(Intercept)", "z"),
    "beta_sigma2"
  )
  sd_struct <- phase18_animal_relmat_q4_sd_vector(sd_struct)
  cor_struct <- phase18_animal_relmat_q4_validate_cor(cor_struct)
  assert_phase18_correlation(rho12, "rho12")

  draw <- function() {
    id_levels <- paste0("id", seq_len(n_level))
    pedigree <- NULL
    if (identical(matrix_argument, "pedigree")) {
      pedigree <- phase18_animal_relmat_q4_pedigree(id_levels)
      K <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    } else {
      K <- outer(
        seq_len(n_level),
        seq_len(n_level),
        function(i, j) matrix_decay^abs(i - j)
      )
      diag(K) <- diag(K) + matrix_jitter
      dimnames(K) <- list(id_levels, id_levels)
    }
    Q <- solve(K)

    covariance <- diag(sd_struct) %*% cor_struct %*% diag(sd_struct)
    effect <- t(chol(K)) %*%
      matrix(stats::rnorm(n_level * 4L), nrow = n_level) %*%
      chol(covariance)
    dimnames(effect) <- list(id_levels, names(sd_struct))

    id <- rep(id_levels, each = n_per_level)
    n <- length(id)
    x <- rep(seq(-1, 1, length.out = n_per_level), n_level)
    z <- rep(rep(c(-0.5, 0.5), length.out = n_per_level), n_level)

    mu1 <- unname(
      beta_mu1[["(Intercept)"]] +
        beta_mu1[["x"]] * x +
        effect[id, "mu1"]
    )
    mu2 <- unname(
      beta_mu2[["(Intercept)"]] +
        beta_mu2[["x"]] * x +
        effect[id, "mu2"]
    )
    log_sigma1 <- unname(
      beta_sigma1[["(Intercept)"]] +
        beta_sigma1[["z"]] * z +
        effect[id, "sigma1"]
    )
    log_sigma2 <- unname(
      beta_sigma2[["(Intercept)"]] +
        beta_sigma2[["z"]] * z +
        effect[id, "sigma2"]
    )
    sigma1 <- exp(log_sigma1)
    sigma2 <- exp(log_sigma2)
    e1 <- stats::rnorm(n)
    e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)

    dat <- data.frame(
      y1 = mu1 + sigma1 * e1,
      y2 = mu2 + sigma2 * e2,
      x = x,
      z = z,
      id = factor(id, levels = id_levels),
      mu1 = mu1,
      mu2 = mu2,
      log_sigma1 = log_sigma1,
      log_sigma2 = log_sigma2,
      sigma1 = sigma1,
      sigma2 = sigma2,
      rho12 = rho12,
      residual_covariance = rho12 * sigma1 * sigma2,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "animal_relmat_q4",
      structured_surface = surface,
      matrix_argument = matrix_argument,
      beta_mu1 = beta_mu1,
      beta_mu2 = beta_mu2,
      beta_sigma1 = beta_sigma1,
      beta_sigma2 = beta_sigma2,
      sd_struct = sd_struct,
      cor_struct = cor_struct,
      rho12 = rho12,
      K = K,
      Q = Q,
      pedigree = pedigree,
      n_level = n_level,
      n_per_level = n_per_level,
      matrix_decay = matrix_decay,
      matrix_jitter = matrix_jitter
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_animal_relmat_q4_cor_matrix <- function(
  cor_mu1_mu2 = 0.35,
  cor_mu1_sigma1 = 0.12,
  cor_mu1_sigma2 = -0.08,
  cor_mu2_sigma1 = 0.10,
  cor_mu2_sigma2 = 0.18,
  cor_sigma1_sigma2 = 0.30
) {
  endpoints <- c("mu1", "mu2", "sigma1", "sigma2")
  corr <- diag(1, 4L)
  dimnames(corr) <- list(endpoints, endpoints)
  corr["mu1", "mu2"] <- corr["mu2", "mu1"] <- cor_mu1_mu2
  corr["mu1", "sigma1"] <- corr["sigma1", "mu1"] <- cor_mu1_sigma1
  corr["mu1", "sigma2"] <- corr["sigma2", "mu1"] <- cor_mu1_sigma2
  corr["mu2", "sigma1"] <- corr["sigma1", "mu2"] <- cor_mu2_sigma1
  corr["mu2", "sigma2"] <- corr["sigma2", "mu2"] <- cor_mu2_sigma2
  corr["sigma1", "sigma2"] <- corr["sigma2", "sigma1"] <- cor_sigma1_sigma2
  phase18_animal_relmat_q4_validate_cor(corr)
}

phase18_animal_relmat_q4_sd_vector <- function(sd_struct) {
  endpoints <- c("mu1", "mu2", "sigma1", "sigma2")
  if (
    !is.numeric(sd_struct) ||
      length(sd_struct) != length(endpoints) ||
      any(!is.finite(sd_struct)) ||
      any(sd_struct <= 0)
  ) {
    stop(
      "`sd_struct` must contain four positive finite numbers.",
      call. = FALSE
    )
  }
  if (!is.null(names(sd_struct)) && all(endpoints %in% names(sd_struct))) {
    sd_struct <- sd_struct[endpoints]
  }
  stats::setNames(as.numeric(sd_struct), endpoints)
}

phase18_animal_relmat_q4_validate_cor <- function(cor_struct) {
  endpoints <- c("mu1", "mu2", "sigma1", "sigma2")
  if (
    !is.matrix(cor_struct) ||
      !is.numeric(cor_struct) ||
      !identical(dim(cor_struct), c(4L, 4L)) ||
      any(!is.finite(cor_struct))
  ) {
    stop(
      "`cor_struct` must be a finite 4 by 4 numeric correlation matrix.",
      call. = FALSE
    )
  }
  if (
    !is.null(rownames(cor_struct)) && all(endpoints %in% rownames(cor_struct))
  ) {
    cor_struct <- cor_struct[endpoints, , drop = FALSE]
  }
  if (
    !is.null(colnames(cor_struct)) && all(endpoints %in% colnames(cor_struct))
  ) {
    cor_struct <- cor_struct[, endpoints, drop = FALSE]
  }
  dimnames(cor_struct) <- list(endpoints, endpoints)
  if (max(abs(cor_struct - t(cor_struct))) > 1e-10) {
    stop("`cor_struct` must be symmetric.", call. = FALSE)
  }
  if (max(abs(diag(cor_struct) - 1)) > 1e-10) {
    stop("`cor_struct` must have a unit diagonal.", call. = FALSE)
  }
  off_diagonal <- cor_struct[upper.tri(cor_struct)]
  if (any(abs(off_diagonal) >= 1)) {
    stop(
      "`cor_struct` off-diagonal entries must lie strictly between -1 and 1.",
      call. = FALSE
    )
  }
  if (
    min(eigen(cor_struct, symmetric = TRUE, only.values = TRUE)$values) <= 0
  ) {
    stop("`cor_struct` must be positive definite.", call. = FALSE)
  }
  cor_struct
}

phase18_animal_relmat_q4_pedigree <- function(id_levels) {
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
