phase18_count_structured_q1_conditions <- function(
  family = c("poisson", "nbinom2"),
  structured_type = c("spatial", "animal", "relmat"),
  n_level = c(10L, 16L),
  n_per_level = c(8L, 12L),
  sd_structured = c(0.25, 0.60),
  mean_count = c(2.5, 5.0),
  sigma_baseline = c(0.40, 0.70),
  beta_mu_x = -0.20,
  beta_sigma_z = 0.15,
  geometry = c("ring", "stretched"),
  matrix_decay = 0.40
) {
  family <- match.arg(
    family,
    choices = c("poisson", "nbinom2"),
    several.ok = TRUE
  )
  structured_type <- match.arg(
    structured_type,
    choices = c("spatial", "animal", "relmat"),
    several.ok = TRUE
  )
  geometry <- match.arg(
    geometry,
    choices = c("ring", "stretched", "clustered"),
    several.ok = TRUE
  )
  conditions <- expand.grid(
    family = family,
    structured_type = structured_type,
    n_level = as.integer(n_level),
    n_per_level = as.integer(n_per_level),
    sd_structured = sd_structured,
    mean_count = mean_count,
    sigma_baseline = sigma_baseline,
    beta_mu_x = beta_mu_x,
    beta_sigma_z = beta_sigma_z,
    geometry = geometry,
    matrix_decay = matrix_decay,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  conditions
}

phase18_dgp_count_structured_q1 <- function(
  family = c("poisson", "nbinom2"),
  structured_type = c("spatial", "animal", "relmat"),
  n_level,
  n_per_level,
  beta_mu = c("(Intercept)" = log(3.0), x = -0.20),
  beta_sigma = c("(Intercept)" = log(0.45), z = 0.15),
  sd_structured = 0.35,
  geometry = c("ring", "stretched", "clustered"),
  matrix_decay = 0.40,
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  family <- match.arg(family)
  structured_type <- match.arg(structured_type)
  assert_positive_whole_number(n_level, "n_level")
  assert_positive_whole_number(n_per_level, "n_per_level")
  if (n_level < 3L) {
    stop("`n_level` must be at least 3.", call. = FALSE)
  }
  beta_mu <- phase18_named_pair(beta_mu, c("(Intercept)", "x"), "beta_mu")
  beta_sigma <- phase18_named_pair(
    beta_sigma,
    c("(Intercept)", "z"),
    "beta_sigma"
  )
  phase18_assert_nonnegative_number(sd_structured, "sd_structured")
  geometry <- match.arg(geometry)
  assert_phase18_correlation(matrix_decay, "matrix_decay")
  if (matrix_decay < 0) {
    stop("`matrix_decay` must be non-negative.", call. = FALSE)
  }

  draw <- function() {
    group <- phase18_count_structured_q1_group(structured_type)
    level_names <- paste0(group, "_", seq_len(n_level))
    structure <- phase18_count_structured_q1_structure(
      structured_type = structured_type,
      level_names = level_names,
      geometry = geometry,
      matrix_decay = matrix_decay
    )
    structured_effect <- as.vector(
      t(chol(structure$covariance)) %*% stats::rnorm(n_level)
    ) *
      sd_structured
    names(structured_effect) <- level_names

    id <- rep(level_names, each = n_per_level)
    x <- rep(seq(-1, 1, length.out = n_per_level), times = n_level)
    z <- rep(seq(-0.8, 0.8, length.out = n_per_level), times = n_level)
    eta_mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        structured_effect[id]
    )
    mu <- exp(eta_mu)
    eta_sigma <- unname(
      beta_sigma[["(Intercept)"]] +
        beta_sigma[["z"]] * z
    )
    sigma <- exp(eta_sigma)
    count <- if (identical(family, "poisson")) {
      stats::rpois(length(mu), lambda = mu)
    } else {
      as.integer(stats::rnbinom(length(mu), size = 1 / sigma^2, mu = mu))
    }

    dat <- data.frame(
      count = count,
      x = x,
      z = z,
      site = factor(id, levels = level_names),
      id = factor(id, levels = level_names),
      eta_mu = eta_mu,
      eta_sigma = eta_sigma,
      mu = mu,
      sigma = sigma,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "count_structured_q1",
      family = family,
      structured_type = structured_type,
      group = group,
      beta_mu = beta_mu,
      beta_sigma = beta_sigma,
      sd = stats::setNames(
        sd_structured,
        paste0(structured_type, "(1 | ", group, ")")
      ),
      coords = structure$coords,
      K = structure$K,
      Q = structure$Q,
      geometry = geometry,
      matrix_decay = matrix_decay,
      n_level = n_level,
      n_per_level = n_per_level,
      mean_count = exp(beta_mu[["(Intercept)"]]),
      sigma_baseline = exp(beta_sigma[["(Intercept)"]])
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_count_structured_q1_group <- function(structured_type) {
  if (identical(structured_type, "spatial")) {
    "site"
  } else {
    "id"
  }
}

phase18_count_structured_q1_structure <- function(
  structured_type,
  level_names,
  geometry,
  matrix_decay
) {
  if (identical(structured_type, "spatial")) {
    coords <- phase18_count_structured_q1_coords(level_names, geometry)
    precision <- drmTMB:::drm_spatial_coords_precision(
      coords,
      site = level_names,
      group = "site"
    )
    covariance <- solve(as.matrix(precision$precision))
    return(list(coords = coords, K = NULL, Q = NULL, covariance = covariance))
  }

  K <- outer(
    seq_along(level_names),
    seq_along(level_names),
    function(i, j) matrix_decay^abs(i - j)
  )
  diag(K) <- 1
  dimnames(K) <- list(level_names, level_names)
  Q <- solve(K)
  list(coords = NULL, K = K, Q = Q, covariance = K)
}

phase18_count_structured_q1_coords <- function(level_names, geometry) {
  level_names <- as.character(level_names)
  if (
    length(level_names) < 3L ||
      anyNA(level_names) ||
      any(!nzchar(level_names))
  ) {
    stop(
      "`level_names` must contain at least three non-missing labels.",
      call. = FALSE
    )
  }
  geometry <- match.arg(geometry, c("ring", "stretched", "clustered"))
  index <- seq_along(level_names)
  if (identical(geometry, "ring")) {
    theta <- seq(0, 1.75 * pi, length.out = length(level_names))
    coords <- data.frame(
      coord_x = cos(theta) + index / (4 * length(level_names)),
      coord_y = sin(theta)
    )
  } else if (identical(geometry, "stretched")) {
    coords <- data.frame(
      coord_x = seq(-1, 1, length.out = length(level_names)),
      coord_y = 0.25 * sin(seq(0, 2 * pi, length.out = length(level_names)))
    )
  } else {
    half <- ceiling(length(level_names) / 2)
    coords <- data.frame(
      coord_x = c(
        seq(-0.9, -0.4, length.out = half),
        seq(0.4, 0.9, length.out = length(level_names) - half)
      ),
      coord_y = c(
        seq(-0.2, 0.2, length.out = half),
        seq(0.2, -0.2, length.out = length(level_names) - half)
      )
    )
  }
  row.names(coords) <- level_names
  coords
}

phase18_assert_nonnegative_number <- function(x, name) {
  ok <- is.numeric(x) &&
    length(x) == 1L &&
    is.finite(x) &&
    x >= 0
  if (!ok) {
    stop("`", name, "` must be one non-negative finite number.", call. = FALSE)
  }
  invisible(x)
}
