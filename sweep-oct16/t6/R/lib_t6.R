# t6 (sweep-oct16) helpers for the R harness (10_harness_r.R).
#
# Everything here is computed INDEPENDENTLY of drmTMB internals: design
# matrices are built by hand from the data columns, inverse links / moments /
# quantiles come from the documented parameter maps (?predict.drmTMB,
# ?simulate.drmTMB, R/family.R roxygen, vignettes/distribution-families.Rmd),
# and the only things read from the fit object are the estimates themselves
# (coefficients, cutpoints, random-intercept SD and modes, vcov, clamp band).

T6_DIR <- "/home/user/drmTMB/sweep-oct16/t6"
T6_DATA <- file.path(T6_DIR, "data")
T6_RES <- file.path(T6_DIR, "results")
F_LEVELS <- c("a", "b", "c")

# ---- cell specification ------------------------------------------------------

t6_other_dpars <- function(fam) {
  switch(fam,
    gaussian = list(sigma = ~x),
    student = list(sigma = ~x, nu = ~1),
    skew_normal = list(sigma = ~x, nu = ~1),
    lognormal = list(sigma = ~x),
    gamma = list(sigma = ~x),
    beta = list(sigma = ~x),
    zero_one_beta = list(sigma = ~x, zoi = ~1, coi = ~1),
    beta_binomial = list(sigma = ~x),
    binomial = list(),
    poisson = list(),
    nbinom2 = list(sigma = ~x),
    truncated_nbinom2 = list(sigma = ~x),
    tweedie = list(sigma = ~x, nu = ~1),
    cumulative_logit = list(),
    stop("unknown family ", fam)
  )
}

t6_family_object <- function(fam) {
  switch(fam,
    gaussian = gaussian(),
    student = drmTMB::student(),
    skew_normal = drmTMB::skew_normal(),
    lognormal = drmTMB::lognormal(),
    gamma = stats::Gamma(link = "log"),
    beta = drmTMB::beta_family(),
    zero_one_beta = drmTMB::zero_one_beta(),
    beta_binomial = drmTMB::beta_binomial(),
    binomial = binomial(),
    poisson = poisson(),
    nbinom2 = drmTMB::nbinom2(),
    truncated_nbinom2 = drmTMB::truncated_nbinom2(),
    tweedie = drmTMB::tweedie(),
    cumulative_logit = drmTMB::cumulative_logit()
  )
}

t6_family_text <- function(fam) {
  switch(fam,
    gamma = 'Gamma(link = "log")', beta = "beta_family()",
    gaussian = "gaussian()", binomial = "binomial()", poisson = "poisson()",
    paste0(fam, "()")
  )
}

# sigma_const = TRUE builds the SPEC fallback (sigma ~ 1).
t6_formula <- function(fam, re, sigma_const = FALSE) {
  lhs <- if (fam %in% c("binomial", "beta_binomial")) "cbind(successes, failures)" else "y"
  rhs <- if (re == "ri") "x + f + (1 | g)" else "x + f"
  mu_f <- stats::as.formula(paste(lhs, "~", rhs), env = globalenv())
  others <- t6_other_dpars(fam)
  if (sigma_const && !is.null(others$sigma)) others$sigma <- ~1
  # drmTMB::bf() reads the parameter name from the formula LHS (sigma ~ x)
  other_f <- lapply(names(others), function(nm) {
    stats::as.formula(paste(nm, deparse(others[[nm]])), env = globalenv())
  })
  args <- c(list(mu_f), other_f)
  bfo <- do.call(drmTMB::bf, args)
  txt <- paste0("bf(", paste(c(paste(lhs, "~", rhs),
    vapply(names(others), function(nm) paste(nm, deparse(others[[nm]])), "")),
    collapse = ", "), ")")
  list(bf = bfo, text = txt, dpars = c("mu", names(others)))
}

# f_type: "character" (base), "factor" (default levels), "relevel" (c, a, b)
t6_read_cell <- function(file, fam, f_type = "character") {
  d <- utils::read.csv(file.path(T6_DATA, file), stringsAsFactors = FALSE)
  if (fam == "cumulative_logit") d$y <- ordered(d$y)
  d$f <- t6_f_convert(d$f, f_type)
  d
}

t6_f_convert <- function(f, f_type) {
  f <- as.character(f)
  switch(f_type,
    character = f,
    factor = factor(f),
    relevel = factor(f, levels = c("c", "a", "b")),
    factor_b = factor(f, levels = "b"),
    factor_abc = factor(f, levels = F_LEVELS),
    stop("bad f_type")
  )
}

# ---- documented links (independent table) ------------------------------------
# Sources: ?predict.drmTMB / R/family.R roxygen (student nu = 2 + exp(eta),
# tweedie nu = 1 + plogis(eta), skew_normal nu identity), the distribution
# families vignette, and base R families (binomial logit, poisson log,
# Gamma(link = "log")).
T6_LINKS <- list(
  gaussian = c(mu = "identity", sigma = "log"),
  student = c(mu = "identity", sigma = "log", nu = "logm2"),
  skew_normal = c(mu = "identity", sigma = "log", nu = "identity"),
  lognormal = c(mu = "identity", sigma = "log"),
  gamma = c(mu = "log", sigma = "log"),
  beta = c(mu = "logit", sigma = "log"),
  zero_one_beta = c(mu = "logit", sigma = "log", zoi = "logit", coi = "logit"),
  beta_binomial = c(mu = "logit", sigma = "log"),
  binomial = c(mu = "logit"),
  poisson = c(mu = "log"),
  nbinom2 = c(mu = "log", sigma = "log"),
  truncated_nbinom2 = c(mu = "log", sigma = "log"),
  tweedie = c(mu = "log", sigma = "log", nu = "logit12"),
  cumulative_logit = c(mu = "identity")
)

t6_invlink <- function(link, eta) {
  switch(link,
    identity = eta,
    log = exp(eta),
    logit = 1 / (1 + exp(-eta)),
    logm2 = 2 + exp(eta),
    logit12 = 1 + 1 / (1 + exp(-eta)),
    stop("unknown link ", link)
  )
}

t6_dinvlink <- function(link, eta) {
  switch(link,
    identity = rep(1, length(eta)),
    log = exp(eta),
    logit = { p <- 1 / (1 + exp(-eta)); p * (1 - p) },
    logm2 = exp(eta),
    logit12 = { p <- 1 / (1 + exp(-eta)); p * (1 - p) },
    stop("unknown link ", link)
  )
}

# ---- hand-built design matrices ---------------------------------------------
# levs: the fitted level order of f (reference = levs[1]).
t6_design <- function(fam, dpar, data, levs = F_LEVELS) {
  n <- nrow(data)
  f <- as.character(data$f)
  if (dpar == "mu") {
    dums <- vapply(levs[-1], function(l) as.numeric(f == l), numeric(n))
    if (n == 1L) dums <- matrix(dums, nrow = 1L)
    colnames(dums) <- paste0("f", levs[-1])
    X <- cbind(`(Intercept)` = 1, x = as.numeric(data$x), dums)
    if (fam == "cumulative_logit") X <- X[, -1L, drop = FALSE]
    return(X)
  }
  if (dpar == "sigma") {
    return(cbind(`(Intercept)` = 1, x = as.numeric(data$x)))
  }
  cbind(`(Intercept)` = rep(1, n))
}

# Own re-implementation of the documented log(sigma) soft clamp
# (?predict.drmTMB Details; band read from the fit's tmb_data).
t6_softclamp <- function(eta, fit) {
  td <- fit$model$tmb_data
  en <- td$use_logsigma_clamp
  band <- td$logsigma_clamp
  if (length(en) != 1L || !identical(as.integer(en), 1L) || length(band) < 3L) {
    return(list(eta = eta, n_bent = 0L, band = NULL))
  }
  lo <- band[1]; hi <- band[2]; m <- band[3]
  out <- eta
  a <- eta > hi; b <- eta < lo
  out[a] <- hi + m * tanh((eta[a] - hi) / m)
  out[b] <- lo - m * tanh((lo - eta[b]) / m)
  list(eta = out, n_bent = sum(a | b), band = band[1:3])
}

t6_bhat_rows <- function(fit, data) {
  vals <- fit$random_effects$mu$values
  key <- paste0("(1 | g):", as.character(data$g))
  out <- unname(vals[key])
  if (anyNA(out)) stop("could not map b-hat to rows")
  out
}

# Population-level linear predictor from the hand-built design (+ clamp for
# sigma, which the docs say predict() reports clamped).
t6_X <- function(fit, fam, dpar, data, levs = F_LEVELS) {
  X <- t6_design(fam, dpar, data, levs)
  beta <- fit$coefficients[[dpar]]
  # sigma ~ 1 fallback fits: keep only the intercept column
  if (dpar == "sigma" && identical(names(beta), "(Intercept)")) X <- X[, 1L, drop = FALSE]
  if (!identical(colnames(X), names(beta))) {
    stop(sprintf("hand design columns [%s] != coef names [%s] for %s",
      paste(colnames(X), collapse = ","), paste(names(beta), collapse = ","), dpar))
  }
  X
}

t6_eta <- function(fit, fam, dpar, data, levs = F_LEVELS) {
  X <- t6_X(fit, fam, dpar, data, levs)
  beta <- fit$coefficients[[dpar]]
  eta <- as.vector(X %*% beta)
  if (dpar == "sigma") eta <- t6_softclamp(eta, fit)$eta
  eta
}

# ---- comparison helpers -------------------------------------------------------
maxabs <- function(a, b) {
  if (length(a) != length(b)) return(Inf)
  d <- abs(as.numeric(a) - as.numeric(b))
  if (all(is.na(d))) return(NA_real_)
  max(d, na.rm = FALSE)
}
# mixed abs/rel: |a-b| / max(1, |b|)
maxmix <- function(a, b) {
  if (length(a) != length(b)) return(Inf)
  max(abs(as.numeric(a) - as.numeric(b)) / pmax(1, abs(as.numeric(b))))
}
maxrel <- function(a, b) {
  if (length(a) != length(b)) return(Inf)
  max(abs(as.numeric(a) - as.numeric(b)) / pmax(1e-300, abs(as.numeric(b))))
}

# ---- documented conditional moments (SPEC moment table) -----------------------
# eta_mu: linear predictor for mu (link scale) incl. any random effect.
# par: list of response-scale non-mu dpars (vectors), plus trials / cutpoints.
t6_cond_moments <- function(fam, eta_mu, par) {
  link <- T6_LINKS[[fam]][["mu"]]
  if (fam == "cumulative_logit") {
    cp <- par$cutpoints
    K <- length(cp) + 1L
    Fk <- sapply(cp, function(c) 1 / (1 + exp(-(c - eta_mu))))
    if (!is.matrix(Fk)) Fk <- matrix(Fk, nrow = length(eta_mu))
    Fk <- cbind(0, Fk, 1)
    p <- Fk[, -1, drop = FALSE] - Fk[, -(K + 1), drop = FALSE]
    k <- seq_len(K)
    E <- as.vector(p %*% k)
    V <- as.vector(p %*% k^2) - E^2
    return(list(E = E, V = V))
  }
  mu <- t6_invlink(link, eta_mu)
  s <- par$sigma; nu <- par$nu
  switch(fam,
    gaussian = list(E = mu, V = s^2 + 0 * mu),
    student = list(E = mu, V = s^2 * nu / (nu - 2) + 0 * mu),
    skew_normal = list(E = mu, V = s^2 + 0 * mu),
    lognormal = list(E = exp(mu + s^2 / 2), V = (exp(s^2) - 1) * exp(2 * mu + s^2)),
    gamma = list(E = mu, V = s^2 * mu^2),
    beta = { phi <- 1 / s^2; list(E = mu, V = mu * (1 - mu) / (1 + phi)) },
    zero_one_beta = {
      phi <- 1 / s^2; zoi <- par$zoi; coi <- par$coi
      vb <- mu * (1 - mu) / (1 + phi)
      E <- (1 - zoi) * mu + zoi * coi
      E2 <- zoi * coi + (1 - zoi) * (vb + mu^2)
      list(E = E, V = E2 - E^2)
    },
    beta_binomial = {
      phi <- 1 / s^2; m <- par$trials
      list(E = m * mu, V = m * mu * (1 - mu) * (1 + (m - 1) / (phi + 1)))
    },
    binomial = { m <- par$trials; list(E = m * mu, V = m * mu * (1 - mu)) },
    poisson = list(E = mu, V = mu),
    nbinom2 = list(E = mu, V = mu + s^2 * mu^2),
    truncated_nbinom2 = {
      k <- 1 / s^2; p0 <- (k / (k + mu))^k
      E <- mu / (1 - p0)
      list(E = E, V = (mu + s^2 * mu^2 + mu^2) / (1 - p0) - E^2)
    },
    tweedie = list(E = mu, V = s^2 * mu^nu),
    stop("no moments for ", fam)
  )
}

# 64-node Gauss-Hermite marginalisation over b ~ N(0, sd^2) added to eta_mu.
t6_marg_moments <- function(fam, eta_mu, par, sd_g, n_nodes = 64L) {
  gh <- statmod::gauss.quad(n_nodes, kind = "hermite")
  w <- gh$weights / sqrt(pi)
  E <- 0; E2 <- 0
  for (k in seq_along(gh$nodes)) {
    m <- t6_cond_moments(fam, eta_mu + sqrt(2) * sd_g * gh$nodes[k], par)
    E <- E + w[k] * m$E
    E2 <- E2 + w[k] * (m$V + m$E^2)
  }
  list(E = E, V = E2 - E^2)
}

# ---- independent quantile functions ------------------------------------------
t6_owen_t <- function(h, a) {
  if (a == 0) return(0)
  stats::integrate(function(t) exp(-h^2 * (1 + t^2) / 2) / (1 + t^2),
    lower = 0, upper = a, rel.tol = 1e-13, abs.tol = 0)$value / (2 * pi)
}
# Skew-normal CDF in direct (xi, omega, alpha) form: Phi(z) - 2 T(z, alpha).
t6_psn <- function(y, xi, omega, alpha) {
  z <- (y - xi) / omega
  stats::pnorm(z) - 2 * t6_owen_t(z, alpha)
}
t6_sn_native <- function(mu, sigma, nu) {
  delta <- nu / sqrt(1 + nu^2)
  omega <- sigma / sqrt(1 - 2 * delta^2 / pi)
  xi <- mu - omega * delta * sqrt(2 / pi)
  list(xi = xi, omega = omega, alpha = nu)
}
t6_qsn <- function(p, mu, sigma, nu) {
  nat <- t6_sn_native(mu, sigma, nu)
  vapply(seq_along(mu), function(i) {
    stats::uniroot(function(t) t6_psn(t, nat$xi[i], nat$omega[i], nat$alpha[i]) - p,
      lower = nat$xi[i] - 12 * nat$omega[i], upper = nat$xi[i] + 12 * nat$omega[i],
      tol = 1e-14, maxiter = 2000)$root
  }, numeric(1))
}

# par: list with mu (response scale) and other response-scale dpars,
# trials, cutpoints, eta_mu (for cumulative_logit).
t6_quantile <- function(fam, p, par) {
  mu <- par$mu; s <- par$sigma; nu <- par$nu
  n <- length(mu)
  switch(fam,
    gaussian = stats::qnorm(p, mu, s),
    student = mu + s * stats::qt(p, df = nu),
    skew_normal = t6_qsn(p, mu, s, nu),
    lognormal = stats::qlnorm(p, meanlog = mu, sdlog = s),
    gamma = stats::qgamma(p, shape = 1 / s^2, scale = mu * s^2),
    beta = stats::qbeta(p, mu / s^2, (1 - mu) / s^2),
    zero_one_beta = {
      zoi <- par$zoi; coi <- par$coi
      p0 <- zoi * (1 - coi); p1 <- zoi * coi
      out <- numeric(n)
      for (i in seq_len(n)) {
        out[i] <- if (p <= p0[i]) 0 else if (p > 1 - p1[i]) 1 else
          stats::qbeta((p - p0[i]) / (1 - zoi[i]), mu[i] / s[i]^2, (1 - mu[i]) / s[i]^2)
      }
      out
    },
    beta_binomial = {
      m <- par$trials
      vapply(seq_len(n), function(i) {
        ks <- 0:m[i]
        cdf <- extraDistr::pbbinom(ks, size = m[i], alpha = mu[i] / s[i]^2,
          beta = (1 - mu[i]) / s[i]^2)
        ks[which(cdf >= p)[1]]
      }, numeric(1))
    },
    binomial = stats::qbinom(p, size = par$trials, prob = mu),
    poisson = stats::qpois(p, mu),
    nbinom2 = stats::qnbinom(p, size = 1 / s^2, mu = mu),
    truncated_nbinom2 = {
      vapply(seq_len(n), function(i) {
        k <- 1 / s[i]^2
        p0 <- (k / (k + mu[i]))^k
        top <- stats::qnbinom(1 - 1e-12, size = k, mu = mu[i]) + 10
        ks <- 1:top
        cdf <- (stats::pnbinom(ks, size = k, mu = mu[i]) - p0) / (1 - p0)
        ks[which(cdf >= p)[1]]
      }, numeric(1))
    },
    tweedie = rep(NA_real_, n),
    cumulative_logit = {
      cp <- par$cutpoints; K <- length(cp) + 1L
      vapply(seq_len(n), function(i) {
        Fk <- c(1 / (1 + exp(-(cp - par$eta_mu[i]))), 1)
        which(Fk >= p)[1]
      }, numeric(1))
    },
    stop("no quantile for ", fam)
  )
}

# ---- P8 statistics -------------------------------------------------------------
t6_sim_stats <- function(Y, E, V, data, nbatch = 40L) {
  nsim <- ncol(Y); n <- nrow(Y)
  G <- colMeans(Y)
  z_mean <- (mean(G) - mean(E)) / (stats::sd(G) / sqrt(nsim))
  bsize <- nsim %/% nbatch
  Vb <- vapply(seq_len(nbatch), function(b) {
    cols <- ((b - 1L) * bsize + 1L):(b * bsize)
    Yb <- Y[, cols, drop = FALSE]
    rv <- rowSums((Yb - rowMeans(Yb))^2) / (bsize - 1L)
    mean(rv)
  }, numeric(1))
  z_var <- (mean(Vb) - mean(V)) / (stats::sd(Vb) / sqrt(nbatch))
  ybar <- rowMeans(Y)
  sdi <- sqrt(rowSums((Y - ybar)^2) / (nsim - 1L))
  zi <- (ybar - E) / (sdi / sqrt(nsim))
  zi[sdi == 0] <- NA_real_
  res <- ybar - E
  ff <- factor(as.character(data$f), levels = F_LEVELS)
  lmfit <- stats::lm(res ~ data$x + ff)
  tt <- summary(lmfit)$coefficients[, "t value"]
  names(tt) <- c("(Intercept)", "x", "fb", "fc")[seq_along(tt)]
  tslopes <- tt[names(tt) != "(Intercept)"]
  list(
    z_mean = z_mean, z_var = z_var,
    mean_sim = mean(G), mean_expected = mean(E),
    var_sim_batchmean = mean(Vb), var_expected = mean(V),
    sd_G = stats::sd(G), sd_Vb = stats::sd(Vb),
    max_abs_zi = max(abs(zi), na.rm = TRUE),
    n_abs_zi_gt3 = sum(abs(zi) > 3, na.rm = TRUE),
    n_zi_na = sum(is.na(zi)),
    expected_n_gt3 = n * 0.0027,
    reg_t = as.list(tt), reg_max_abs_t_slopes = max(abs(tslopes)),
    reg_flag = max(abs(tslopes)) > 4,
    pass_mean = abs(z_mean) < 3, pass_var = abs(z_var) < 3
  )
}

# ---- misc ----------------------------------------------------------------------
t6_err <- function(e) {
  msg <- conditionMessage(e)
  msg <- gsub("\033\\[[0-9;]*m", "", msg)
  paste(trimws(strsplit(msg, "\n", fixed = TRUE)[[1]]), collapse = " | ")
}

t6_test <- function(status, metric = NA, value = NA, notes = "", details = NULL) {
  list(status = status, metric = metric, value = value, notes = notes, details = details)
}

t6_status <- function(ok) if (isTRUE(ok)) "PASS" else "FAIL"
