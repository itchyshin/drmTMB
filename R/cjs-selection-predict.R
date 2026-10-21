# Conditioning-aware predictions for the individual reference-selection route.

.cmr_selection_training_input <- function(object) {
  selection <- object$selection
  if (!is.list(selection) || !identical(selection$assumption, "alive_available") ||
      !is.integer(selection$eligibility) ||
      length(selection$eligibility) != nrow(object$data$y))
    stop("selection-integrated training prediction requires retained eligibility provenance.", call. = FALSE)
  n <- nrow(object$data$y)
  nt <- ncol(object$data$y)
  first <- data.frame(id = object$data$id,
    first_index = as.integer(object$data$first),
    eligibility_index = selection$eligibility)
  phi_rows <- expand.grid(i = seq_len(n), t = seq_len(max(nt - 1L, 0L)))
  p_rows <- expand.grid(i = seq_len(n), t = seq_len(nt))
  phi_rows <- phi_rows[with(phi_rows, t >= selection$eligibility[i] & t < object$data$first[i]), , drop = FALSE]
  p_rows <- p_rows[with(p_rows, t >= selection$eligibility[i] & t <= object$data$first[i]), , drop = FALSE]
  phi_index <- (phi_rows$i - 1L) * max(nt - 1L, 0L) + phi_rows$t
  phi <- object$training_phi_data[phi_index, , drop = FALSE]
  phi$interval_length <- as.numeric(t(object$data$delta))[phi_index]
  p_index <- (p_rows$i - 1L) * nt + p_rows$t
  p <- object$training_p_data[p_index, , drop = FALSE]
  p$observed <- object$data$observed[cbind(p_rows$i, p_rows$t)]
  p$capture <- ifelse(p$observed, object$data$y[cbind(p_rows$i, p_rows$t)], NA_integer_)
  list(first = first, phi = phi, p = p)
}

.cmr_selection_newdata_input <- function(x, object, post_phi, post_p) {
  if (!is.list(x) || !identical(sort(names(x)), sort(c("first", "phi", "p"))))
    stop("`newdata$selection` must contain exactly `first`, `phi`, and `p`.", call. = FALSE)
  first <- x$first
  required_first <- c("id", "first_index", "eligibility_index")
  if (!is.data.frame(first) || !identical(names(first), required_first) ||
      !nrow(first) || anyNA(first) || anyDuplicated(first$id) ||
      !is.numeric(first$first_index) || !is.numeric(first$eligibility_index) ||
      any(first$first_index != as.integer(first$first_index)) ||
      any(first$eligibility_index != as.integer(first$eligibility_index)))
    stop("`newdata$selection$first` must have unique IDs and integer `first_index` and `eligibility_index` columns.", call. = FALSE)
  nt <- length(object$data$occasions)
  if (any(first$eligibility_index < 1L | first$eligibility_index > first$first_index) ||
      any(first$first_index > nt))
    stop("selection eligibility and first-capture indices must be within the fitted occasion schedule and eligibility must not follow first capture.", call. = FALSE)
  post_ids <- unique(c(as.character(post_phi$id), as.character(post_p$id)))
  if (!all(post_ids %in% as.character(first$id)))
    stop("selection first-capture metadata must cover every post-capture prediction ID.", call. = FALSE)
  for (id in post_ids) {
    f <- as.integer(first$first_index[match(id, as.character(first$id))])
    phi_rows <- which(as.character(post_phi$id) == id)
    if (length(phi_rows)) {
      start <- match(post_phi$interval_start[phi_rows], object$data$occasions)
      end <- match(post_phi$interval_end[phi_rows], object$data$occasions)
      if (anyNA(start) || anyNA(end) || any(start < f) || any(end <= f) ||
          any(end != start + 1L))
        stop("selection-integrated survival predictions must start at or after first capture and end after it.", call. = FALSE)
    }
    p_rows <- which(as.character(post_p$id) == id)
    if (length(p_rows)) {
      occasion <- match(post_p$occasion[p_rows], object$data$occasions)
      if (anyNA(occasion) || any(occasion <= f))
        stop("selection-integrated detection predictions must be after first capture.", call. = FALSE)
    }
  }

  phi <- x$phi
  p <- x$p
  if (!is.data.frame(phi) || !all(c("id", "interval_start", "interval_end", "interval_length") %in% names(phi)))
    stop("`newdata$selection$phi` must contain keyed pre-capture survival intervals.", call. = FALSE)
  phi_valid <- .cmr_prediction_keys(phi, "phi", object, "integrated")
  if (!is.data.frame(p) || !all(c("id", "occasion", "observed", "capture") %in% names(p)))
    stop("`newdata$selection$p` must contain keyed pre-capture occasions, `observed`, and `capture`.", call. = FALSE)
  if (!is.logical(p$observed) || anyNA(p$observed) ||
      any(p$observed & (is.na(p$capture) | !p$capture %in% c(0L, 1L))) ||
      any(!p$observed & !is.na(p$capture)))
    stop("selection detection rows require a complete logical mask and binary captures only on observed occasions.", call. = FALSE)
  p_predictors <- p[setdiff(names(p), c("observed", "capture"))]
  p_valid <- .cmr_prediction_keys(p_predictors, "p", object, "integrated",
                                 active = p$observed)

  first <- first[match(unique(as.character(first$id)), as.character(first$id)), , drop = FALSE]
  for (i in seq_len(nrow(first))) {
    id <- as.character(first$id[[i]])
    f <- as.integer(first$first_index[[i]])
    e <- as.integer(first$eligibility_index[[i]])
    expected_phi <- if (f > e) seq.int(e, f - 1L) else integer()
    rows_phi <- which(as.character(phi$id) == id)
    start_phi <- match(phi$interval_start[rows_phi], object$data$occasions)
    end_phi <- match(phi$interval_end[rows_phi], object$data$occasions)
    order_phi <- order(start_phi)
    if (!identical(start_phi[order_phi], expected_phi) ||
        !identical(end_phi[order_phi], expected_phi + 1L))
      stop("selection survival prehistory must contain exactly every interval from eligibility through first capture.", call. = FALSE)
    if (length(rows_phi)) {
      expected_delta <- as.numeric(object$data$delta[1L, expected_phi])
      order_phi <- order(match(phi$interval_start[rows_phi], object$data$occasions))
      if (any(abs(phi$interval_length[rows_phi][order_phi] - expected_delta) > 1e-10 * pmax(1, expected_delta)))
        stop("selection prehistory interval lengths must match the fitted occasion schedule.", call. = FALSE)
    }
    expected_p <- seq.int(e, f)
    rows_p <- which(as.character(p$id) == id)
    p_index <- match(p$occasion[rows_p], object$data$occasions)
    if (!identical(sort(p_index), expected_p))
      stop("selection detection prehistory must contain every occasion from eligibility through first capture.", call. = FALSE)
    first_row <- rows_p[match(f, p_index)]
    if (is.na(first_row) || !p$observed[[first_row]] || p$capture[[first_row]] != 1L)
      stop("the declared first-capture occasion must be observed with `capture = 1`.", call. = FALSE)
    before <- rows_p[p_index < f]
    if (length(before) && any(p$observed[before] & p$capture[before] != 0L))
      stop("observed selection occasions before first capture must have `capture = 0`.", call. = FALSE)
  }
  if (!setequal(as.character(unique(phi$id)), as.character(first$id)[first$first_index > first$eligibility_index]))
    stop("selection survival prehistory IDs do not match the declared eligibility and first-capture roster.", call. = FALSE)
  if (!setequal(as.character(unique(p$id)), as.character(first$id)))
    stop("selection detection prehistory must include each declared individual.", call. = FALSE)
  list(first = first, phi = phi_valid$.frame, p = p_valid$.frame,
       p_observed = p$observed, p_capture = p$capture)
}

.cmr_selection_log_weights <- function(process, nodes, sigma, history, object) {
  if (process == "phi") {
    n <- nrow(history)
    if (!n) return(rep(0, length(nodes)))
    eta <- history$eta
    terminal <- !is.null(object$terminal_constraint$phi) &
      history$interval_end == max(object$data$occasions)
    if (any(terminal)) eta[terminal] <- stats::qlogis(object$terminal_constraint$phi)
    eta_matrix <- outer(eta, sigma * nodes, "+")
    if (any(terminal)) eta_matrix[terminal, ] <- eta[terminal]
    return(colSums(history$interval_length * stats::plogis(eta_matrix, log.p = TRUE)))
  }
  use <- history$observed
  if (!any(use)) return(rep(0, length(nodes)))
  eta <- history$eta[use]
  capture <- history$capture[use]
  occasion <- history$occasion[use]
  terminal <- !is.null(object$terminal_constraint$p) &
    occasion == utils::tail(object$data$occasions, 1L)
  eta_matrix <- outer(eta, sigma * nodes, "+")
  if (any(terminal)) eta_matrix[terminal, ] <- stats::qlogis(object$terminal_constraint$p)
  ll <- stats::plogis(eta_matrix, log.p = TRUE)
  ll[capture == 0L, ] <- stats::plogis(-eta_matrix[capture == 0L, , drop = FALSE], log.p = TRUE)
  colSums(ll)
}

.cmr_selection_draw_effect <- function(object, process, history, ids, sigma) {
  if (!length(ids)) return(numeric())
  if (!is.numeric(sigma) || !length(sigma) %in% c(1L, length(ids)) ||
      any(!is.finite(sigma)) || any(sigma < 0))
    stop("selection-conditioned simulation requires a finite non-negative process SD.", call. = FALSE)
  sigma <- rep_len(sigma, length(ids))
  order <- object$random_effects$integration$selected_order
  gh <- .cmr_gauss_hermite(order)
  vapply(seq_along(ids), function(i) {
    id <- as.character(ids[[i]])
    if (sigma[[i]] == 0) return(0)
    rows <- which(as.character(history$id) == id)
    log_weight <- log(gh$weights)
    if (length(rows)) log_weight <- log_weight + .cmr_selection_log_weights(
      process, gh$nodes, sigma[[i]], history[rows, , drop = FALSE], object)
    prob <- exp(log_weight - max(log_weight))
    gh$nodes[[sample.int(length(gh$nodes), size = 1L, prob = prob)]] * sigma[[i]]
  }, numeric(1))
}

.cmr_selection_forward_draw <- function(object, history, ids, sigma_phi,
                                        sigma_p, max_attempts) {
  n <- length(ids)
  if (!is.numeric(sigma_phi) || length(sigma_phi) != n ||
      any(!is.finite(sigma_phi)) || any(sigma_phi < 0) ||
      !is.numeric(sigma_p) || length(sigma_p) != n ||
      any(!is.finite(sigma_p)) || any(sigma_p < 0))
    stop("reference-selection simulation requires one finite non-negative SD per individual.", call. = FALSE)
  if (!is.numeric(max_attempts) || length(max_attempts) != 1L ||
      !is.finite(max_attempts) || max_attempts < 1L ||
      max_attempts != as.integer(max_attempts))
    stop("`max_selection_attempts` must be one positive integer.", call. = FALSE)
  max_attempts <- as.integer(max_attempts)
  nt <- length(object$data$occasions)
  z_phi <- numeric(n)
  z_p <- numeric(n)
  prehistory <- matrix(NA_integer_, nrow = n, ncol = nt)
  for (j in seq_len(n)) {
    id <- as.character(ids[[j]])
    first_row <- match(id, as.character(history$first$id))
    if (is.na(first_row))
      stop("reference-selection simulation has no retained first-capture profile for ID `", id, "`.", call. = FALSE)
    f <- as.integer(history$first$first_index[[first_row]])
    e <- as.integer(history$first$eligibility_index[[first_row]])
    phi_rows <- which(as.character(history$phi$id) == id)
    p_rows <- which(as.character(history$p$id) == id)
    phi_by_time <- if (length(phi_rows)) stats::setNames(phi_rows,
      match(history$phi$interval_start[phi_rows], object$data$occasions)) else integer()
    p_by_time <- if (length(p_rows)) stats::setNames(p_rows,
      match(history$p$occasion[p_rows], object$data$occasions)) else integer()
    accepted <- FALSE
    for (attempt in seq_len(max_attempts)) {
      z_phi_candidate <- if (sigma_phi[[j]] == 0) 0 else stats::rnorm(1L)
      z_p_candidate <- if (sigma_p[[j]] == 0) 0 else stats::rnorm(1L)
      y <- rep(NA_integer_, nt)
      alive <- TRUE
      captured <- FALSE
      failed <- FALSE
      for (t in seq.int(e, f)) {
        p_row <- p_by_time[as.character(t)]
        observed <- length(p_row) == 1L && !is.na(p_row) && history$p$observed[[p_row]]
        if (observed) {
          eta <- history$p$eta[[p_row]] + sigma_p[[j]] * z_p_candidate
          if (!is.null(object$terminal_constraint$p) &&
              history$p$occasion[[p_row]] == utils::tail(object$data$occasions, 1L))
            probability <- object$terminal_constraint$p
          else probability <- stats::plogis(eta)
          y[[t]] <- stats::rbinom(1L, 1L, probability)
          if (y[[t]] == 1L) {
            if (t == f) captured <- TRUE else failed <- TRUE
            break
          }
        }
        if (t < f) {
          phi_row <- phi_by_time[as.character(t)]
          if (length(phi_row) != 1L || is.na(phi_row))
            stop("reference-selection simulation is missing a pre-capture survival row for ID `", id, "`.", call. = FALSE)
          eta <- history$phi$eta[[phi_row]] + sigma_phi[[j]] * z_phi_candidate
          if (!is.null(object$terminal_constraint$phi) &&
              history$phi$interval_end[[phi_row]] == utils::tail(object$data$occasions, 1L))
            probability <- object$terminal_constraint$phi ^ history$phi$interval_length[[phi_row]]
          else probability <- stats::plogis(eta) ^ history$phi$interval_length[[phi_row]]
          alive <- stats::rbinom(1L, 1L, probability) == 1L
          if (!alive) {
            failed <- TRUE
            break
          }
        }
      }
      if (captured && !failed) {
        z_phi[[j]] <- z_phi_candidate
        z_p[[j]] <- z_p_candidate
        prehistory[j, ] <- y
        accepted <- TRUE
        break
      }
    }
    if (!accepted)
      stop("reference-selection simulation could not realize first-capture occasion ", f,
           " for ID `", id, "` after `max_selection_attempts` = ", max_attempts, ".", call. = FALSE)
  }
  list(z_phi = z_phi, z_p = z_p, prehistory = prehistory)
}

.cmr_selection_mean <- function(eta, sigma, power, terminal, constraint,
                                process, history, object) {
  eta <- as.numeric(eta)
  power <- rep_len(as.numeric(power), length(eta))
  terminal <- rep_len(terminal, length(eta))
  ans <- stats::plogis(eta)^power
  if (!length(eta)) return(ans)
  if (any(!is.finite(sigma)) || any(sigma < 0) || max(sigma) - min(sigma) > 1e-10 * max(1, max(sigma)))
    stop("selection-integrated prediction requires one finite process SD per individual.", call. = FALSE)
  if (all(terminal)) {
    if (!is.null(constraint)) ans[terminal] <- constraint^power[terminal]
    return(ans)
  }
  sigma <- unname(sigma[[1L]])
  active <- which(!terminal)
  previous <- NULL
  previous_log_den <- NULL
  previous_log_num <- NULL
  converged <- FALSE
  orders <- .cmr_validate_quadrature_orders(object$random_effects$integration$orders)
  log_close <- function(x, y) {
    if (length(x) != length(y)) return(FALSE)
    same_infinite <- x == y
    close_finite <- is.finite(x) & is.finite(y) & abs(x - y) <= 1e-8
    all(same_infinite | close_finite)
  }
  for (order in orders) {
    gh <- .cmr_gauss_hermite(order)
    log_weight <- .cmr_selection_log_weights(process, gh$nodes, sigma, history, object)
    log_mass <- log(gh$weights) + log_weight
    normalizer <- max(log_mass)
    if (!is.finite(normalizer))
      stop("selection event has numerically zero quadrature mass; prediction is unavailable.", call. = FALSE)
    log_mass <- log_mass - normalizer
    posterior <- exp(log_mass)
    posterior <- posterior / sum(posterior)
    log_den <- normalizer + log(sum(exp(log(gh$weights) + log_weight - normalizer)))
    current <- vapply(active, function(i) sum(posterior *
      stats::plogis(eta[[i]] + sigma * gh$nodes)^power[[i]]), numeric(1))
    current_log_num <- log_den + log(current)
    if (!is.null(previous) && max(abs(current - previous)) <= 1e-8 &&
        log_close(log_den, previous_log_den) &&
        log_close(current_log_num, previous_log_num)) {
      ans[active] <- current
      converged <- TRUE
      break
    }
    previous <- current
    previous_log_den <- log_den
    previous_log_num <- current_log_num
    ans[active] <- current
  }
  if (!converged)
    stop("selection-integrated prediction quadrature is unrefined at order ",
         max(orders), ".", call. = FALSE)
  if (any(terminal) && !is.null(constraint)) ans[terminal] <- constraint^power[terminal]
  ans
}

.cmr_selection_validate_sd_history <- function(object, process, post_frame,
                                               post_ids, post_sigma,
                                               pre_frame) {
  if (!isTRUE(object$prediction_contract$sd_formula_present[[process]])) return(invisible(TRUE))
  if (!nrow(pre_frame)) return(invisible(TRUE))
  pre_sigma <- .cmr_prediction_sd_rows(object, process, pre_frame, pre_frame$id)
  for (id in unique(as.character(post_ids))) {
    post <- post_sigma[as.character(post_ids) == id]
    pre <- pre_sigma[as.character(pre_frame$id) == id]
    if (length(post) && length(pre) &&
        max(abs(c(post, pre) - post[[1L]])) >
          1e-10 * max(1, post[[1L]]))
      stop("SD-formula predictors must be constant across the selection and post-prediction history for each individual.", call. = FALSE)
  }
  invisible(TRUE)
}

.cmr_selection_prediction_rows <- function(object, process, keys, eta, sigma,
                                           power, terminal, selection) {
  ans <- stats::plogis(eta)^power
  if (!length(eta)) return(ans)
  history_all <- selection[[process]]
  for (id in unique(as.character(keys$id))) {
    rows <- which(as.character(keys$id) == id)
    history_rows <- which(as.character(history_all$id) == id)
    history <- history_all[history_rows, , drop = FALSE]
    constraint <- object$terminal_constraint[[process]]
    ans[rows] <- .cmr_selection_mean(eta[rows], sigma[rows], power[rows],
      terminal[rows], constraint, process, history, object)
  }
  ans
}
