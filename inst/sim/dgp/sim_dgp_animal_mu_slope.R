phase18_animal_mu_slope_conditions <- function(
  n_id = c(8L, 12L),
  n_each = c(7L, 9L),
  sd_intercept = 0.55,
  sd_slope = 0.32,
  beta_mu_intercept = 0.25,
  beta_mu_x = 0.45,
  sigma = 0.22
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
  conditions
}

phase18_dgp_animal_mu_slope_cell <- function(cell, seed, cell_id, replicate) {
  phase18_assert_one_row_data_frame(cell, "cell")
  required <- c(
    "n_id",
    "n_each",
    "sd_intercept",
    "sd_slope",
    "beta_mu_intercept",
    "beta_mu_x",
    "sigma"
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

  phase18_dgp_animal_mu_slope(
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
    seed = seed,
    cell_id = cell_id,
    replicate = replicate
  )
}

phase18_dgp_animal_mu_slope <- function(
  n_id,
  n_each,
  beta_mu = c("(Intercept)" = 0.25, x = 0.45),
  sigma = 0.22,
  sd = c("(Intercept)" = 0.55, x = 0.32),
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n_id, "n_id")
  assert_positive_whole_number(n_each, "n_each")
  if (n_id < 3L) {
    stop("`n_id` must be at least 3.", call. = FALSE)
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

  draw <- function() {
    id_levels <- paste0("id_", seq_len(n_id))
    pedigree <- phase18_animal_mu_slope_pedigree(id_levels)
    A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
    Ainv <- solve(A)

    animal_intercept <- as.vector(
      t(chol(A)) %*% stats::rnorm(n_id, sd = sd[["(Intercept)"]])
    )
    animal_slope <- as.vector(
      t(chol(A)) %*% stats::rnorm(n_id, sd = sd[["x"]])
    )
    names(animal_intercept) <- id_levels
    names(animal_slope) <- id_levels

    id <- rep(id_levels, each = n_each)
    x <- rep(seq(-1, 1, length.out = n_each), times = n_id)
    mu <- unname(
      beta_mu[["(Intercept)"]] +
        beta_mu[["x"]] * x +
        animal_intercept[id] +
        animal_slope[id] * x
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
      surface = "animal_mu_slope",
      beta_mu = beta_mu,
      sigma = sigma,
      sd = stats::setNames(
        sd,
        c("animal(1 | id)", "animal(0 + x | id)")
      ),
      animal_intercept = animal_intercept,
      animal_slope = animal_slope,
      pedigree = pedigree,
      A = A,
      Ainv = Ainv,
      n_id = n_id,
      n_each = n_each
    )
    dat
  }

  if (is.null(seed)) {
    draw()
  } else {
    phase18_with_seed(seed, draw)
  }
}

phase18_animal_mu_slope_pedigree <- function(id_levels) {
  id_levels <- as.character(id_levels)
  if (length(id_levels) < 3L || anyNA(id_levels) || any(!nzchar(id_levels))) {
    stop(
      "`id_levels` must contain at least three non-missing labels.",
      call. = FALSE
    )
  }
  dam <- rep(NA_character_, length(id_levels))
  sire <- rep(NA_character_, length(id_levels))
  for (i in seq.int(3L, length(id_levels))) {
    dam[[i]] <- id_levels[[i - 2L]]
    sire[[i]] <- id_levels[[i - 1L]]
  }
  data.frame(
    id = id_levels,
    dam = dam,
    sire = sire,
    stringsAsFactors = FALSE
  )
}
