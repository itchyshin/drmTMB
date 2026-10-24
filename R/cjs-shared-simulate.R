# Internal helpers for fresh conditional simulation from ordinary shared-effect
# CJS fits. The fitted Z matrices and level order define the random-effect
# coordinates; simulation never uses fitted latent modes.

.cmr_shared_draw_effects <- function(levels, sigma) {
  sigma <- .cmr_shared_sd_vector(sigma, length(levels))
  values <- if (all(sigma == 0)) numeric(length(levels)) else stats::rnorm(length(levels))
  values[sigma == 0] <- 0
  stats::setNames(values, as.character(levels))
}

.cmr_shared_effect_contribution <- function(Z, effects, sigma) {
  if (!is.matrix(Z) || !is.numeric(Z) || ncol(Z) != length(effects) ||
      any(!is.finite(Z)))
    stop("shared simulation requires a finite design matrix aligned with its group effects.",
         call. = FALSE)
  sigma <- .cmr_shared_sd_vector(sigma, ncol(Z))
  as.numeric(Z %*% (sigma * effects))
}

.cmr_shared_simulation_probabilities <- function(
    eta_phi, eta_p, delta, contribution_phi, contribution_p,
    phi_terminal = NULL, p_terminal = NULL, terminal_constraint = NULL) {
  eta_phi <- as.matrix(eta_phi)
  eta_p <- as.matrix(eta_p)
  delta <- as.matrix(delta)
  n <- nrow(eta_phi)
  nt <- ncol(eta_p)
  if (!identical(dim(eta_phi), c(n, nt - 1L)) ||
      !identical(dim(delta), dim(eta_phi)) ||
      length(contribution_phi) != length(eta_phi) ||
      length(contribution_p) != length(eta_p))
    stop("shared simulation probabilities require history-major process arrays.", call. = FALSE)
  phi_unit <- stats::plogis(eta_phi + matrix(contribution_phi, nrow = n, byrow = TRUE))
  p <- stats::plogis(eta_p + matrix(contribution_p, nrow = n, byrow = TRUE))
  if (!is.null(phi_terminal) && any(phi_terminal)) {
    if (is.null(terminal_constraint$phi))
      stop("a constrained shared survival row has no terminal probability.", call. = FALSE)
    phi_unit[phi_terminal] <- terminal_constraint$phi
  }
  if (!is.null(p_terminal) && any(p_terminal)) {
    if (is.null(terminal_constraint$p))
      stop("a constrained shared detection row has no terminal probability.", call. = FALSE)
    p[p_terminal] <- terminal_constraint$p
  }
  list(phi_interval = phi_unit ^ delta, p = p)
}

.cmr_shared_simulate_histories <- function(
    eta_phi, eta_p, delta, Z_phi, Z_p, levels_phi, levels_p,
    sigma_phi, sigma_p, observed, first, end, copies,
    phi_terminal = NULL, p_terminal = NULL, terminal_constraint = NULL,
    nsim = 1L) {
  n <- nrow(eta_p)
  nt <- ncol(eta_p)
  out <- vector("list", nsim)
  for (s in seq_len(nsim)) {
    u_phi <- .cmr_shared_draw_effects(levels_phi, sigma_phi)
    u_p <- .cmr_shared_draw_effects(levels_p, sigma_p)
    c_phi <- .cmr_shared_effect_contribution(Z_phi, u_phi, sigma_phi)
    c_p <- .cmr_shared_effect_contribution(Z_p, u_p, sigma_p)
    probability <- .cmr_shared_simulation_probabilities(
      eta_phi, eta_p, delta, c_phi, c_p,
      phi_terminal, p_terminal, terminal_constraint)
    # Frequency copies expand only after group contributions have been formed.
    phi_draw <- probability$phi_interval[copies, , drop = FALSE]
    p_draw <- probability$p[copies, , drop = FALSE]
    seen <- observed[copies, , drop = FALSE]
    first_copy <- first[copies]
    end_copy <- end[copies]
    y <- matrix(0L, nrow = length(copies), ncol = nt)
    y[!seen] <- NA_integer_
    for (j in seq_along(copies)) {
      alive <- TRUE
      y[j, first_copy[[j]]] <- 1L
      if (first_copy[[j]] < end_copy[[j]]) {
        for (t in seq.int(first_copy[[j]] + 1L, end_copy[[j]])) {
          if (alive) alive <- stats::rbinom(1L, 1L, phi_draw[j, t - 1L]) == 1L
          if (seen[j, t]) y[j, t] <- if (alive) stats::rbinom(1L, 1L, p_draw[j, t]) else 0L
        }
      }
    }
    out[[s]] <- y
  }
  out
}

.cmr_simulate_shared <- function(object, nsim = 1L, seed = NULL) {
  .cmr_shared_methods_validate(object)
  nsim <- .cmr_validate_count(nsim, "nsim")
  if (!is.null(seed) && (length(seed) != 1L || !is.numeric(seed) ||
                         is.na(seed) || !is.finite(seed) ||
                         abs(seed) > .Machine$integer.max || seed != as.integer(seed)))
    stop("`seed` must be `NULL` or one finite integer in the supported range.", call. = FALSE)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (!is.null(seed) && had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  if (!is.null(seed)) on.exit({
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  if (!is.null(seed)) set.seed(as.integer(seed))

  n <- nrow(object$data$y)
  nt <- ncol(object$data$y)
  re_phi <- object$random_effects$phi
  re_p <- object$random_effects$p
  sigma_phi <- .cmr_shared_process_sd(object, "phi")
  sigma_p <- .cmr_shared_process_sd(object, "p")
  eta_phi <- matrix(as.numeric(object$phi$X %*% object$coefficients$phi + object$phi$offset),
                    nrow = n, byrow = TRUE)
  eta_p <- matrix(as.numeric(object$p$X %*% object$coefficients$p + object$p$offset),
                  nrow = n, byrow = TRUE)
  delta <- object$data$delta
  phi_terminal <- matrix(FALSE, nrow = n, ncol = nt - 1L)
  p_terminal <- matrix(FALSE, nrow = n, ncol = nt)
  if (!is.null(object$terminal_constraint$phi) && nt > 1L)
    phi_terminal[, nt - 1L] <- TRUE
  if (!is.null(object$terminal_constraint$p)) p_terminal[, nt] <- TRUE

  copies <- rep(seq_len(n), times = object$data$frequency)
  new_ids <- make.unique(paste0(as.character(object$data$id[copies]), "__sim", seq_along(copies)),
                         sep = "__")
  observed <- object$data$observed[copies, , drop = FALSE]
  first <- object$data$first
  end <- object$data$end
  replicate_data <- function(frame, keys) {
    out <- vector("list", length(copies))
    for (j in seq_along(copies)) {
      rows <- which(frame$id == object$data$id[copies[[j]]])
      part <- frame[rows, , drop = FALSE]
      part$id <- new_ids[[j]]
      out[[j]] <- part
    }
    result <- do.call(rbind, out)
    rownames(result) <- NULL
    if (anyDuplicated(result[keys]))
      stop("internal simulation produced duplicate keyed predictor rows.", call. = FALSE)
    result
  }
  phi_data <- replicate_data(object$training_phi_data,
                             c("id", "interval_start", "interval_end"))
  p_data <- replicate_data(object$training_p_data, c("id", "occasion"))
  intervals <- if (nt > 1L) as.numeric(object$data$delta[1L, ]) else numeric()
  histories <- .cmr_shared_simulate_histories(
    eta_phi, eta_p, delta,
    if (is.null(re_phi)) matrix(0, n * max(nt - 1L, 0L), 0L) else re_phi$Z,
    if (is.null(re_p)) matrix(0, n * nt, 0L) else re_p$Z,
    if (is.null(re_phi)) character() else as.character(re_phi$levels),
    if (is.null(re_p)) character() else as.character(re_p$levels),
    sigma_phi, sigma_p, object$data$observed, first, end, copies,
    phi_terminal, p_terminal, object$terminal_constraint, nsim)
  lapply(seq_len(nsim), function(s) {
    sim_data <- cmr_data(histories[[s]], id = new_ids, observed = observed,
      occasions = object$data$occasions, intervals = intervals,
      units = object$data$units, end = end[copies], frequency = 1L)
    record <- structure(list(data = sim_data, phi_data = phi_data, p_data = p_data,
                             replicate = s), class = "cmr_simulation")
    attr(record, "simulation") <- list(
      target = "conditional_first_capture_marked_cohort",
      effects = "fresh_independent_shared_group_effects",
      group_draws = "one_per_contributing_level_and_process_per_replicate",
      parameters = "fitted_coefficients_and_sd_held_fixed")
    record
  })
}
