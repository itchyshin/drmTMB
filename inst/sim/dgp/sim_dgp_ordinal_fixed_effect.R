phase18_ordinal_fe_conditions <- function(
  n = c(240L, 720L),
  n_category = c(3L, 5L),
  beta_mu_x = c(0, 0.75),
  cutpoint_pattern = c("balanced", "close")
) {
  cutpoint_pattern <- phase18_ordinal_cutpoint_pattern(
    cutpoint_pattern,
    several.ok = TRUE
  )
  n_category <- as.integer(n_category)
  bad_category <- is.na(n_category) | n_category < 3L
  if (any(bad_category)) {
    stop("`n_category` must contain integers of at least 3.", call. = FALSE)
  }

  expand.grid(
    n = as.integer(n),
    n_category = n_category,
    beta_mu_x = beta_mu_x,
    cutpoint_pattern = cutpoint_pattern,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
}

phase18_dgp_ordinal_fe <- function(
  n,
  n_category = 3L,
  beta_mu = c(x = 0.75),
  cutpoint_pattern = c("balanced", "close"),
  seed = NULL,
  cell_id = NA_character_,
  replicate = NA_integer_
) {
  assert_positive_whole_number(n, "n")
  n_category <- as.integer(n_category)
  if (length(n_category) != 1L || is.na(n_category) || n_category < 3L) {
    stop("`n_category` must be one integer of at least 3.", call. = FALSE)
  }
  beta_mu <- phase18_ordinal_beta_mu(beta_mu)
  cutpoint_pattern <- phase18_ordinal_cutpoint_pattern(cutpoint_pattern)

  draw <- function() {
    x <- stats::rnorm(n)
    eta_mu <- unname(beta_mu[["x"]] * x)
    levels <- phase18_ordinal_levels(n_category)
    cutpoints <- phase18_ordinal_cutpoints(
      n_category = n_category,
      pattern = cutpoint_pattern,
      levels = levels
    )
    prob <- phase18_ordinal_probabilities(eta_mu, cutpoints)
    draw <- vapply(
      seq_len(n),
      function(i) {
        sample.int(n_category, size = 1L, prob = prob[i, ])
      },
      integer(1)
    )
    expected_score <- as.vector(prob %*% seq_len(n_category))

    dat <- data.frame(
      score = ordered(levels[draw], levels = levels),
      x = x,
      eta_mu = eta_mu,
      expected_score = expected_score,
      family = "cumulative_logit",
      n_category = n_category,
      cutpoint_pattern = cutpoint_pattern,
      cell_id = cell_id,
      replicate = replicate,
      stringsAsFactors = FALSE
    )
    attr(dat, "truth") <- list(
      surface = "ordinal_fixed_effect",
      family = "cumulative_logit",
      beta_mu = beta_mu,
      cutpoints = cutpoints,
      levels = levels,
      n_category = n_category,
      cutpoint_pattern = cutpoint_pattern,
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

phase18_ordinal_beta_mu <- function(beta_mu) {
  if (!is.numeric(beta_mu) || length(beta_mu) != 1L || !is.finite(beta_mu)) {
    stop("`beta_mu` must be one finite numeric slope.", call. = FALSE)
  }
  current <- names(beta_mu)
  if (is.null(current) || !nzchar(current[[1L]])) {
    names(beta_mu) <- "x"
    return(beta_mu)
  }
  if (!identical(current, "x")) {
    stop("`beta_mu` must be unnamed or named `x`.", call. = FALSE)
  }
  beta_mu
}

phase18_ordinal_cutpoint_pattern <- function(
  pattern,
  several.ok = FALSE
) {
  choices <- c("balanced", "close")
  if (
    !is.character(pattern) ||
      length(pattern) == 0L ||
      anyNA(pattern) ||
      any(!nzchar(pattern)) ||
      any(!pattern %in% choices)
  ) {
    stop(
      "`cutpoint_pattern` must be ",
      if (several.ok) "one or more of " else "one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  if (!several.ok && length(pattern) != 1L) {
    stop(
      "`cutpoint_pattern` must be one of ",
      paste(choices, collapse = ", "),
      ".",
      call. = FALSE
    )
  }
  unique(pattern)
}

phase18_ordinal_levels <- function(n_category) {
  if (identical(n_category, 3L)) {
    return(c("low", "medium", "high"))
  }
  if (identical(n_category, 5L)) {
    return(c("very_low", "low", "medium", "high", "very_high"))
  }
  paste0("level_", seq_len(n_category))
}

phase18_ordinal_cutpoints <- function(
  n_category,
  pattern,
  levels = phase18_ordinal_levels(n_category)
) {
  if (identical(pattern, "balanced")) {
    cutpoints <- stats::qlogis(seq_len(n_category - 1L) / n_category)
  } else {
    cutpoints <- seq(-0.35, 0.35, length.out = n_category - 1L)
  }
  names(cutpoints) <- paste(levels[-n_category], levels[-1L], sep = "|")
  cutpoints
}

phase18_ordinal_probabilities <- function(eta_mu, cutpoints) {
  cumulative <- stats::plogis(
    matrix(
      cutpoints,
      nrow = length(eta_mu),
      ncol = length(cutpoints),
      byrow = TRUE
    ) -
      eta_mu
  )
  prob <- cbind(
    cumulative[, 1L],
    cumulative[, -1L, drop = FALSE] -
      cumulative[, -ncol(cumulative), drop = FALSE],
    1 - cumulative[, ncol(cumulative)]
  )
  prob <- pmax(prob, 0)
  prob / rowSums(prob)
}
