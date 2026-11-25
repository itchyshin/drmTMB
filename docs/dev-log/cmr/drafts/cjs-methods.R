# Draft M2 methods, intentionally not exported or claimed in the R M1 receipt.
# They need new-data prediction, correct unseeded RNG semantics, separate
# reader review, and tests before moving into R/ or S3 registration.

predict.drm_cjs <- function(object, type = c("response", "link"), ...) {
  type <- match.arg(type)
  n <- nrow(object$data$y); nt <- ncol(object$data$y)
  eta_phi <- as.numeric(object$phi$X %*% object$coefficients$phi + object$phi$offset)
  eta_p <- as.numeric(object$p$X %*% object$coefficients$p + object$p$offset)
  eta_phi <- matrix(eta_phi, nrow = n, ncol = nt - 1L, byrow = TRUE)
  eta_p <- matrix(eta_p, nrow = n, ncol = nt, byrow = TRUE)
  phi_active <- matrix(object$phi_active, nrow = n, ncol = nt - 1L, byrow = TRUE)
  p_active <- matrix(object$p_active, nrow = n, ncol = nt, byrow = TRUE)
  eta_phi[!phi_active] <- NA_real_
  eta_p[!p_active] <- NA_real_
  if (type == "link") return(list(phi = eta_phi, p = eta_p))
  unit <- stats::plogis(eta_phi)
  list(phi_unit = unit, phi_interval = unit ^ object$data$delta,
       p = stats::plogis(eta_p))
}

simulate.drm_cjs <- function(object, nsim = 1L, seed = NULL, ...) {
  if (length(nsim) != 1L || is.na(nsim) || nsim < 1L || nsim != as.integer(nsim))
    stop("`nsim` must be a positive integer.", call. = FALSE)
  if (!is.null(seed) && (length(seed) != 1L || !is.numeric(seed) || !is.finite(seed)))
    stop("`seed` must be one finite numeric value or `NULL`.", call. = FALSE)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit(if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv) else
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) rm(".Random.seed", envir = .GlobalEnv),
    add = TRUE)
  if (!is.null(seed)) set.seed(seed)
  pred <- stats::predict(object, type = "response")
  copies <- rep(seq_len(nrow(object$data$y)), object$data$frequency)
  out <- array(NA_integer_, dim = c(length(copies), ncol(object$data$y), as.integer(nsim)),
               dimnames = list(as.character(object$data$id[copies]),
                               as.character(object$data$occasions), paste0("sim", seq_len(nsim))))
  for (s in seq_len(nsim)) for (j in seq_along(copies)) {
    i <- copies[[j]]; first <- object$data$first[[i]]; end <- object$data$end[[i]]
    alive <- TRUE
    out[j, first, s] <- 1L
    if (first < end) for (t in seq.int(first + 1L, end)) {
      if (alive) alive <- stats::rbinom(1L, 1L, pred$phi_interval[i, t - 1L]) == 1L
      if (object$data$observed[i, t] && alive) {
        out[j, t, s] <- stats::rbinom(1L, 1L, pred$p[i, t])
      } else if (object$data$observed[i, t]) {
        out[j, t, s] <- 0L
      }
    }
  }
  out
}
