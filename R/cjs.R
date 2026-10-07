#' Fit a fixed-effects first-capture-conditional CJS model
#'
#' @param data A `cmr_data` object.
#' @param phi Survival formula, with logit unit-time apparent survival.
#' @param p Detection formula, with logit detection conditional on alive.
#' @param phi_data Optional interval predictor table keyed by `id`,
#'   `interval_start`, and `interval_end`.
#' @param p_data Optional detection predictor table keyed by `id` and `occasion`.
#' @param terminal_constraint Optional named list fixing exactly one common
#'   final-process probability, for example `list(phi = 0.8)` (unit-time
#'   survival) or `list(p = 0.4)` (final-occasion detection). Values must be
#'   strictly between zero and one. It applies at the final declared interval
#'   or occasion, not at each individual's administrative endpoint.
#' @param contrasts Optional named list of process-specific contrast specifications,
#'   `list(phi = ..., p = ...)`. The fitted coding is retained for prediction and
#'   bootstrap refits.
#' @param selection Reserved for the later reference-selection stage; currently
#'   must be `NULL`.
#' @param sd_phi,sd_p Reserved for later random-effect SD models; currently must
#'   be `NULL`.
#' @param control Options passed to [stats::nlminb()].
#' @return A `drm_cjs` fit containing the optimizer and TMB objective.
#' @export
drm_cjs <- function(data, phi = ~1, p = ~1, phi_data = NULL, p_data = NULL,
                    selection = NULL, sd_phi = NULL, sd_p = NULL,
                    terminal_constraint = NULL, control = list(),
                    contrasts = list(phi = NULL, p = NULL)) {
  if (!inherits(data, "cmr_data")) stop("`data` must be made by cmr_data().", call. = FALSE)
  if (!is.null(selection) || !is.null(sd_phi) || !is.null(sd_p))
    stop("selection and random-effect SD formulas are reserved for later CJS stages.", call. = FALSE)
  if (!inherits(phi, "formula") || !inherits(p, "formula"))
    stop("`phi` and `p` must be one-sided formulas.", call. = FALSE)
  if (length(phi) != 2L || length(p) != 2L) stop("`phi` and `p` must be one-sided formulas.", call. = FALSE)
  contains_random <- function(x) is.call(x) && (identical(x[[1L]], as.name("|")) ||
    identical(x[[1L]], as.name("||")) || any(vapply(as.list(x)[-1L], contains_random, logical(1))))
  if (contains_random(phi[[2L]]) || contains_random(p[[2L]]))
    stop("random effects are not supported in the fixed-effects CJS route.", call. = FALSE)
  n <- nrow(data$y); nt <- ncol(data$y)
  if (!any(data$first < data$end))
    stop("CJS fitting needs at least one post-capture transition; final-first histories are retained with likelihood one when other histories inform the fit.", call. = FALSE)
  p_rows <- data.frame(i = rep(seq_len(n), each = nt), t = rep(seq_len(nt), n))
  phi_rows <- data.frame(i = rep(seq_len(n), each = max(nt - 1L, 0L)),
                         t = rep(seq_len(max(nt - 1L, 0L)), n))
  p_frame <- .cmr_join_predictors(data, p_data, p_rows, "p")
  phi_frame <- .cmr_join_predictors(data, phi_data, phi_rows, "phi")
  p_active <- p_rows$t > data$first[p_rows$i] & p_rows$t <= data$end[p_rows$i] &
    data$observed[cbind(p_rows$i, p_rows$t)]
  phi_active <- phi_rows$t >= data$first[phi_rows$i] & phi_rows$t < data$end[phi_rows$i]
  if (!any(p_active))
    stop("CJS fitting needs at least one surveyed post-capture occasion to inform detection.", call. = FALSE)
  if (!is.list(contrasts) || is.null(names(contrasts)) ||
      any(!names(contrasts) %in% c("phi", "p")) || anyDuplicated(names(contrasts)))
    stop("`contrasts` must be a named list with optional `phi` and `p` specifications.", call. = FALSE)
  p_design <- .cmr_design(p, p_frame, "p", p_active, contrasts$p)
  phi_design <- .cmr_design(phi, phi_frame, "phi", phi_active, contrasts$phi)
  for (design in list(phi_design, p_design)) {
    if (ncol(design$X) && qr(design$X)$rank < ncol(design$X))
      stop("`", design$process, "` design is rank deficient; remove linearly dependent predictors.", call. = FALSE)
  }
  # A direction occurring only at the final declared occasion/interval
  # is confounded with its paired terminal process probability.
  if (!is.null(terminal_constraint) && (!is.list(terminal_constraint) ||
      length(terminal_constraint) != 1L || is.null(names(terminal_constraint)) ||
      !names(terminal_constraint) %in% c("phi", "p")))
    stop("supply exactly one named `terminal_constraint`: `phi` or `p`.", call. = FALSE)
  # Identification constraint refers to the common last declared occasion;
  # each individual's administrative endpoint only truncates their likelihood.
  p_terminal <- p_rows$t == nt
  phi_terminal <- phi_rows$t == nt - 1L
  phi_terminal_identified <- .cmr_terminal_rank(phi_design, phi_terminal)
  p_terminal_identified <- .cmr_terminal_rank(p_design, p_terminal)
  if (phi_terminal_identified && p_terminal_identified && is.null(terminal_constraint))
    stop("terminal phi and p directions are jointly unidentified; supply one `terminal_constraint = list(phi = value)` or `list(p = value)`.", call. = FALSE)
  p_fixed <- .cmr_or_null(terminal_constraint[["p"]])
  phi_fixed <- .cmr_or_null(terminal_constraint[["phi"]])
  p_design <- .cmr_fixed_terminal(p_design, p_terminal, "p", p_fixed)
  phi_design <- .cmr_fixed_terminal(phi_design, phi_terminal, "phi", phi_fixed)
  n_phi <- ncol(phi_design$X); n_p <- ncol(p_design$X)
  x_phi <- phi_design$X; x_p <- p_design$X
  beta_phi <- rep(0, n_phi); beta_p <- rep(0, n_p)
  map <- list()
  if (n_phi == 0L) {
    x_phi <- matrix(0, nrow(phi_design$X), 1L)
    beta_phi <- 0
    if (n_p > 0L) map$beta_phi <- factor(NA)
  }
  if (n_p == 0L) {
    x_p <- matrix(0, nrow(p_design$X), 1L)
    beta_p <- 0
    map$beta_p <- factor(NA)
  }
  # Keep a single inert slot in the high-level all-fixed route; it is excluded
  # from the public coefficients and never optimized.
  if (n_phi == 0L && n_p == 0L) map <- list(beta_p = factor(NA))
  obj <- TMB::MakeADFun(data = list(
    model_type = 1000L, cmr_N = n, cmr_T = nt,
    cmr_y = as.integer(t(data$y)), cmr_observed = as.integer(t(data$observed)),
    cmr_first = data$first - 1L, cmr_end = data$end - 1L,
    cmr_delta = as.numeric(t(data$delta)), cmr_frequency = data$frequency,
    cmr_X_phi = x_phi, cmr_X_p = x_p,
    cmr_offset_phi = phi_design$offset, cmr_offset_p = p_design$offset
  ), parameters = list(beta_phi = beta_phi, beta_p = beta_p), map = map,
  DLL = "drmTMB", silent = TRUE)
  n_free <- n_phi + n_p
  if (n_free) {
    opt <- stats::nlminb(start = obj$par, objective = obj$fn,
                         gradient = obj$gr, control = control)
  } else {
    opt <- list(par = obj$par, objective = obj$fn(obj$par), convergence = 0L,
                message = "No free coefficients; evaluated the fixed CJS objective.",
                iterations = 0L, evaluations = c("function" = 1L, gradient = 0L))
  }
  grad <- if (n_free) obj$gr(opt$par) else numeric()
  fd <- if (n_free) .cmr_fd_gradient(obj$fn, opt$par) else numeric()
  final_nll <- obj$fn(opt$par)
  hessian <- if (n_free) obj$he(opt$par) else matrix(numeric(), 0L, 0L)
  if (n_free) names(opt$par) <- c(paste0("phi:", phi_design$columns), paste0("p:", p_design$columns))
  n_informative <- sum(data$first < data$end)
  n_post_occasions <- sum(p_active)
  structure(list(data = data, logLik = -final_nll, objective = -final_nll,
                 # Keep the keyed source rows as well as the fitted designs.
                 # A design matrix cannot be inverted to recover factors,
                 # transforms, interactions, or offset expressions for
                 # conditional simulation and prediction on the training set.
                 training_phi_data = phi_frame, training_p_data = p_frame,
                 coefficients = list(phi = setNames(opt$par[seq_len(ncol(phi_design$X))], phi_design$columns),
                                     p = setNames(opt$par[ncol(phi_design$X) + seq_len(ncol(p_design$X))], p_design$columns)),
                 optimizer = opt, gradient = grad, gradient_fd = fd,
                 gradient_norm = if (length(grad)) max(abs(grad)) else 0,
                 hessian = hessian,
                 n_informative = n_informative, n_post_occasions = n_post_occasions,
                 convergence = opt$convergence, message = opt$message,
                 obj = obj, phi = phi_design, p = p_design,
                 phi_active = phi_active, p_active = p_active,
                 terminal_constraint = terminal_constraint,
                 call = match.call()), class = "drm_cjs")
}

.cmr_join_predictors <- function(data, predictors, rows, process) {
  keys <- if (process == "p") c("id", "occasion") else c("id", "interval_start", "interval_end")
  keydata <- data.frame(id = data$id[rows$i], occasion = data$occasions[rows$t])
  if (process == "phi") {
    keydata$interval_start <- data$occasions[rows$t]
    keydata$interval_end <- data$occasions[rows$t + 1L]
  }
  if (is.null(predictors)) return(keydata)
  if (!is.data.frame(predictors) || !all(keys %in% names(predictors)))
    stop("`", process, "_data` must be a data frame keyed by ", paste(keys, collapse = ", "), ".", call. = FALSE)
  if (anyNA(predictors[keys]))
    stop("`", process, "_data` keys must be non-missing.", call. = FALSE)
  if (anyDuplicated(predictors[keys])) stop("`", process, "_data` has duplicate keys.", call. = FALSE)
  known <- keydata[keys]
  known$.cmr_known <- TRUE
  checked <- merge(predictors[keys], known, by = keys, all.x = TRUE, sort = FALSE)
  if (anyNA(checked$.cmr_known))
    stop("`", process, "_data` contains unknown keys outside the declared histories and occasions.", call. = FALSE)
  keydata$.cmr_row <- seq_len(nrow(keydata))
  if (".cmr_row" %in% names(predictors))
    stop("predictor tables may not use the reserved name `.cmr_row`.", call. = FALSE)
  joined <- merge(keydata, predictors, by = keys, all.x = TRUE, sort = FALSE)
  joined <- joined[order(joined$.cmr_row), , drop = FALSE]
  if (nrow(joined) != nrow(keydata))
    stop("`", process, "_data` has duplicated or malformed keyed rows.", call. = FALSE)
  joined$.cmr_row <- NULL
  joined
}

.cmr_design <- function(formula, frame, process, active, contrasts = NULL) {
  tr <- stats::terms(formula)
  mf <- stats::model.frame(tr, data = frame[active, , drop = FALSE],
                           na.action = stats::na.fail, drop.unused.levels = TRUE)
  xa <- stats::model.matrix(tr, mf, contrasts.arg = contrasts)
  off <- stats::model.offset(mf); if (is.null(off)) off <- rep(0, nrow(xa))
  if (any(!is.finite(xa)) || any(!is.finite(off)))
    stop("`", process, "` design and offsets must contain finite values.", call. = FALSE)
  X <- matrix(0, nrow(frame), ncol(xa), dimnames = list(NULL, colnames(xa)))
  X[active, ] <- xa
  full_offset <- rep(0, nrow(frame)); full_offset[active] <- off
  list(X = X, offset = as.numeric(full_offset), columns = colnames(X), terms = tr,
       contrasts = attr(xa, "contrasts"), xlevels = stats::.getXlevels(tr, mf),
       process = process)
}

.cmr_terminal_rank <- function(design, terminal) {
  if (!nrow(design$X)) return(FALSE)
  qr(design$X)$rank > qr(design$X[!terminal, , drop = FALSE])$rank
}

.cmr_or_null <- function(x) if (is.null(x) || !length(x)) NULL else x

.cmr_fixed_terminal <- function(design, terminal, process, fixed) {
  if (!nrow(design$X)) return(design)
  if (is.null(fixed)) return(design)
  if (length(fixed) != 1L || !is.numeric(fixed) || !is.finite(fixed) || fixed <= 0 || fixed >= 1)
    stop("terminal `", process, "` constraint must be one finite probability strictly between zero and one.", call. = FALSE)
  if (!is.null(fixed)) {
    design$X[terminal, ] <- 0
    design$offset[terminal] <- stats::qlogis(fixed)
    if (ncol(design$X)) {
      keep <- qr(design$X)$pivot[seq_len(qr(design$X)$rank)]
      design$X <- design$X[, keep, drop = FALSE]
      design$columns <- design$columns[keep]
    }
  }
  design
}

.cmr_fd_gradient <- function(fn, par) {
  vapply(seq_along(par), function(i) {
    h <- .Machine$double.eps^(1/3) * max(1, abs(par[[i]]))
    d1 <- (fn(replace(par, i, par[[i]] + h)) - fn(replace(par, i, par[[i]] - h))) / (2 * h)
    h <- h / 2
    d2 <- (fn(replace(par, i, par[[i]] + h)) - fn(replace(par, i, par[[i]] - h))) / (2 * h)
    if (!is.finite(d1) || !is.finite(d2) || abs(d1 - d2) > 1e-5 * max(1, abs(d2)))
      warning("finite-difference gradient did not stabilize across step halving for parameter ", i, call. = FALSE)
    d2
  }, numeric(1))
}
