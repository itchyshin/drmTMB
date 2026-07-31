# Missing-response G4/G5 foundation.
#
# This file deliberately records gate-specific evidence separately from the
# capability ledger.  A G5 result is evidence for one frozen response-mask
# target, not a promotion of the model-wide inference tier.

mr_g4g5_route_manifest <- function() {
  data.frame(
    route_id = c(
      "gaussian", "biv_gaussian", "poisson", "nbinom2", "beta",
      "binomial", "student", "lognormal", "gamma", "skew_normal",
      "zero_one_beta", "tweedie", "cumulative_logit", "beta_binomial",
      "truncated_nbinom2", "zi_poisson", "zi_nbinom2", "hurdle_nbinom2"
    ),
    tranche = c(rep("T1", 6), rep("T2", 4), rep("T3", 2), rep("T4", 2), "T5", rep("T6", 3)),
    g3_evidence_id = paste0("ev-mr-", c(
      "gaussian", "biv-gaussian", "poisson", "nbinom2", "beta",
      "binomial", "student", "lognormal", "gamma", "skew-normal",
      "zero-one-beta", "tweedie", "cumulative-logit", "beta-binomial",
      "truncated-nbinom2", "zi-poisson", "zi-nbinom2", "hurdle-nbinom2"
    ), "-g3"),
    mask_design = c(
      "within_group", "paired_within_group", "within_group", "within_group", "within_group",
      "global", "global", "global", "global", "global", "global", "global",
      "global", "global", "within_group", "global", "global", "global"
    ),
    g3_source = c(
      "test-missing-response-recovery.R", "test-missing-response-recovery.R",
      "test-missing-response-recovery.R", "test-missing-response-recovery.R",
      "test-missing-response-recovery.R", "test-missing-response-binomial.R",
      "test-missing-response-continuous.R", "test-missing-response-continuous.R",
      "test-missing-response-continuous.R", "test-missing-response-continuous.R",
      "test-missing-response-boundary.R", "test-missing-response-boundary.R",
      "test-missing-response-encoded.R", "test-missing-response-encoded.R",
      "test-missing-response-truncated-nbinom2.R", "test-missing-response-count-mixtures.R",
      "test-missing-response-count-mixtures.R", "test-missing-response-count-mixtures.R"
    ),
    base_information = c(
      "36_id_x_12", "60_id_x_8", "48_id_x_12", "48_id_x_12", "48_id_x_12",
      "4000", "40_id_x_10", "36_id_x_9", "42_id_x_10", "360", "1600", "500",
      "900", "52_id_x_10", "34_id_x_8", "1800", "1800", "1800"
    ),
    g3_mask_seed = c(
      2026071102L, 2026071104L, 2026071107L, 2026071109L, 2026071111L, 202L,
      2026071221L, 2026071222L, 2026071223L, 2026071231L, 2026071322L, 2026071321L,
      2026071422L, 2026071421L, 2026071506L, 2026071609L, 2026071627L, 2026071650L
    ),
    stringsAsFactors = FALSE
  )
}

mr_g4g5_validate_manifest <- function(manifest = mr_g4g5_route_manifest()) {
  required <- c("route_id", "tranche", "g3_evidence_id", "mask_design", "g3_source",
    "base_information", "g3_mask_seed")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest))) {
    stop("Missing-response manifest must contain the required route fields.", call. = FALSE)
  }
  if (nrow(manifest) != 18L || anyDuplicated(manifest$route_id) ||
      any(!nzchar(manifest$route_id)) || any(!grepl("^ev-mr-.*-g3$", manifest$g3_evidence_id))) {
    stop("Missing-response manifest must contain exactly 18 unique G3 routes.", call. = FALSE)
  }
  if (any(!grepl("^test-missing-response-.*\\.R$", manifest$g3_source)) ||
      any(!nzchar(manifest$base_information)) || any(!is.finite(manifest$g3_mask_seed))) {
    stop("Missing-response manifest must retain a G3 source, size, and mask seed.", call. = FALSE)
  }
  invisible(manifest)
}

mr_g4g5_mask_mcar <- function(data, response, seed, fraction = 0.25, group = NULL) {
  if (!is.character(response) || length(response) != 1L || !response %in% names(data)) {
    stop("`response` must name one response column in `data`.", call. = FALSE)
  }
  if (!is.numeric(fraction) || length(fraction) != 1L || fraction <= 0 || fraction >= 1) {
    stop("`fraction` must be one fraction strictly between zero and one.", call. = FALSE)
  }
  set.seed(seed)
  rows <- if (is.null(group)) {
    sample.int(nrow(data), size = nrow(data) * fraction)
  } else {
    if (!group %in% names(data)) stop("`group` must name a column in `data`.", call. = FALSE)
    unlist(tapply(seq_len(nrow(data)), data[[group]], function(index) {
      sample(index, size = length(index) * fraction)
    }), use.names = FALSE)
  }
  data[[response]][rows] <- NA_real_
  data
}

mr_g4g5_group_count <- function(base_groups, n_each, information_multiplier) {
  n_group <- as.integer(round(base_groups * information_multiplier))
  while ((n_group * n_each) %% 4L != 0L) n_group <- n_group + 1L
  n_group
}

# Exact MR-T1 Gaussian G3 DGP, promoted from its test-local definition so G4
# can regenerate the same route at the prescribed information rungs.
mr_g4g5_gaussian_g3_dgp <- function(information_multiplier = 1, seed = 2026071101L) {
  if (!information_multiplier %in% c(0.5, 1, 2)) {
    stop("Gaussian G4/G5 information multiplier must be 0.5, 1, or 2.", call. = FALSE)
  }
  set.seed(seed)
  n_id <- mr_g4g5_group_count(36L, n_each = 12L, information_multiplier)
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  z <- rnorm(length(id))
  u <- rnorm(n_id, sd = 0.7)
  u <- u - mean(u)
  data <- data.frame(id = id, x = x, z = z)
  data$y <- rnorm(nrow(data), 0.35 + 0.55 * x + u[id], exp(-0.25 + 0.22 * z))
  data <- mr_g4g5_mask_mcar(data, "y", seed = seed + 1L, group = "id")
  list(
    data = data,
    truth = c(
      "fixef:mu:(Intercept)" = 0.35, "fixef:mu:x" = 0.55,
      "fixef:sigma:(Intercept)" = -0.25, "fixef:sigma:z" = 0.22,
      "sd:mu:(1 | id)" = 0.70
    ),
    information_multiplier = information_multiplier
  )
}

mr_g4g5_fit_gaussian <- function(data, se = FALSE) {
  drmTMB(
    bf(y ~ x + (1 | id), sigma ~ z), gaussian(), data,
    missing = miss_control(response = "include"), control = drm_control(se = se)
  )
}

# Remaining MR-T1 univariate random-intercept DGPs. These retain the G3
# family parameterizations and use only the number of groups for information
# scaling, preserving within-group replication.
mr_g4g5_t1_ri_dgp <- function(route, information_multiplier = 1, seed = NULL) {
  if (!route %in% c("poisson", "nbinom2", "beta")) {
    stop("`route` must be poisson, nbinom2, or beta.", call. = FALSE)
  }
  if (!information_multiplier %in% c(0.5, 1, 2)) {
    stop("T1 information multiplier must be 0.5, 1, or 2.", call. = FALSE)
  }
  defaults <- c(poisson = 2026071106L, nbinom2 = 2026071108L, beta = 2026071110L)
  use_g3_seed <- is.null(seed)
  if (use_g3_seed) seed <- defaults[[route]]
  set.seed(seed)
  n_id <- mr_g4g5_group_count(48L, n_each = 12L, information_multiplier)
  n_each <- 12L
  id <- factor(rep(seq_len(n_id), each = n_each))
  data <- data.frame(id = id, x = rnorm(length(id)))
  if (route != "poisson") data$z <- rnorm(length(id))
  spec <- switch(route,
    poisson = list(mu = c(0.35, -0.30), sd = 0.55, mask_seed = 2026071107L),
    nbinom2 = list(mu = c(0.35, -0.25), sigma = c(-0.70, 0.20), sd = 0.45, mask_seed = 2026071109L),
    beta = list(mu = c(-0.30, 0.70), sigma = c(-0.85, 0.16), sd = 0.55, mask_seed = 2026071111L)
  )
  u <- rnorm(n_id, sd = spec$sd)
  if (route %in% c("poisson", "beta")) u <- u - mean(u)
  eta <- spec$mu[[1L]] + spec$mu[[2L]] * data$x + u[id]
  if (route == "poisson") {
    data$count <- rpois(nrow(data), exp(eta))
    response <- "count"
  } else {
    sigma <- exp(spec$sigma[[1L]] + spec$sigma[[2L]] * data$z)
    if (route == "nbinom2") {
      data$count <- rnbinom(nrow(data), size = 1 / sigma^2, mu = exp(eta))
      response <- "count"
    } else {
      mu <- plogis(eta)
      phi <- 1 / sigma^2
      data$prop <- rbeta(nrow(data), mu * phi, (1 - mu) * phi)
      response <- "prop"
    }
  }
  mask_seed <- if (use_g3_seed) spec$mask_seed else as.integer(seed + 1L)
  data <- mr_g4g5_mask_mcar(data, response, seed = mask_seed, group = "id")
  truth <- c("fixef:mu:(Intercept)" = spec$mu[[1L]], "fixef:mu:x" = spec$mu[[2L]])
  if (!is.null(spec$sigma)) {
    truth <- c(truth, "fixef:sigma:(Intercept)" = spec$sigma[[1L]], "fixef:sigma:z" = spec$sigma[[2L]])
  }
  truth <- c(truth, "sd:mu:(1 | id)" = spec$sd)
  list(data = data, truth = truth, information_multiplier = information_multiplier)
}

mr_g4g5_fit_t1_ri <- function(route, data, se = FALSE) {
  switch(route,
    poisson = drmTMB(bf(count ~ x + (1 | id)), poisson(), data,
      missing = miss_control(response = "include"), control = drm_control(se = se)),
    nbinom2 = drmTMB(bf(count ~ x + (1 | id), sigma ~ z), nbinom2(), data,
      missing = miss_control(response = "include"), control = drm_control(se = se)),
    beta = drmTMB(bf(prop ~ x + (1 | id), sigma ~ z), beta(), data,
      missing = miss_control(response = "include"), control = drm_control(se = se))
  )
}

# Exact bivariate-Gaussian partial-response design. The two outcomes are
# masked independently within group; this preserves the complete/partial pair
# structure required for the rho12 target.
mr_g4g5_biv_gaussian_g3_dgp <- function(information_multiplier = 1, seed = 2026071103L) {
  if (!information_multiplier %in% c(0.5, 1, 2)) {
    stop("Bivariate information multiplier must be 0.5, 1, or 2.", call. = FALSE)
  }
  set.seed(seed)
  n_id <- mr_g4g5_group_count(60L, n_each = 8L, information_multiplier)
  n_each <- 8L
  id <- factor(rep(seq_len(n_id), each = n_each))
  x <- rnorm(length(id))
  u1 <- rnorm(n_id)
  u2 <- 0.45 * u1 + sqrt(1 - 0.45^2) * rnorm(n_id)
  e1 <- rnorm(length(id))
  e2 <- 0.25 * e1 + sqrt(1 - 0.25^2) * rnorm(length(id))
  data <- data.frame(id = id, x = x)
  data$y1 <- 0.20 + 0.45 * x + 0.55 * u1[id] + 0.35 * e1
  data$y2 <- -0.15 - 0.35 * x + 0.65 * u2[id] + 0.45 * e2
  data <- mr_g4g5_mask_mcar(data, "y1", seed = seed + 1L, group = "id")
  data <- mr_g4g5_mask_mcar(data, "y2", seed = seed + 2L, group = "id")
  list(
    data = data,
    truth = c(
      "fixef:mu1:(Intercept)" = 0.20, "fixef:mu1:x" = 0.45,
      "fixef:mu2:(Intercept)" = -0.15, "fixef:mu2:x" = -0.35,
      "fixef:sigma1:(Intercept)" = log(0.35), "fixef:sigma2:(Intercept)" = log(0.45),
      "fixef:rho12:(Intercept)" = atanh(0.25), "sigma1" = 0.35, "sigma2" = 0.45,
      "rho12" = 0.25, "sd:mu:mu1:(1 | p | id)" = 0.55,
      "sd:mu:mu2:(1 | p | id)" = 0.65,
      "cor:mu:cor(mu1:(Intercept),mu2:(Intercept) | p | id)" = 0.45
    ), information_multiplier = information_multiplier
  )
}

mr_g4g5_fit_biv_gaussian <- function(data, se = FALSE) {
  drmTMB(
    bf(mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x + (1 | p | id),
      sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
    biv_gaussian(), data, missing = miss_control(response = "include"),
    control = drm_control(se = se)
  )
}

mr_g4g5_t2_dgp <- function(route, information_multiplier = 1, seed = NULL) {
  if (!route %in% c("student", "lognormal", "gamma", "skew_normal") ||
      !information_multiplier %in% c(0.5, 1, 2)) {
    stop("Unsupported T2 route or information multiplier.", call. = FALSE)
  }
  defaults <- c(student = 2026071221L, lognormal = 2026071222L,
    gamma = 2026071223L, skew_normal = 2026071231L)
  use_g3_seed <- is.null(seed)
  if (use_g3_seed) seed <- defaults[[route]]
  set.seed(seed)
  if (route == "skew_normal") {
    n <- as.integer(360L * information_multiplier)
    data <- data.frame(x = seq(-1.2, 1.2, length.out = n), z = rep(seq(-1, 1, length.out = 24), length.out = n))
    truth <- c("fixef:mu:(Intercept)" = .2, "fixef:mu:x" = .4,
      "fixef:sigma:(Intercept)" = -.3, "fixef:sigma:z" = .15, "fixef:nu:(Intercept)" = 1.4)
    native <- skew_normal_public_to_native(.2 + .4 * data$x, exp(-.3 + .15 * data$z), 1.4)
    i <- seq_len(n); u <- qnorm((i - .5) / n); v <- qnorm((((i * 37L) %% n) + .5) / n)
    data$y <- native$xi + native$omega * (native$delta * abs(u) + sqrt(1 - native$delta^2) * v)
    data <- mr_g4g5_mask_mcar(data, "y", seed = if (use_g3_seed) defaults[[route]] else seed + 1L)
    return(list(data = data, truth = truth, information_multiplier = information_multiplier))
  }
  n_id0 <- c(student = 40L, lognormal = 36L, gamma = 42L)[[route]]
  n_each <- c(student = 10L, lognormal = 9L, gamma = 10L)[[route]]
  n_id <- mr_g4g5_group_count(n_id0, n_each, information_multiplier)
  id <- factor(rep(seq_len(n_id), each = n_each)); n <- length(id)
  data <- data.frame(id = id, x = rnorm(n), z = rnorm(n))
  spec <- switch(route,
    student = list(mu = c(.20, .48), sigma = c(-.42, .18), sd = .52, nu = log(7)),
    lognormal = list(mu = c(.25, .40), sigma = c(-.75, .18), sd = .55),
    gamma = list(mu = c(.15, .36), sigma = c(-.85, .16), sd = .48)
  )
  u <- rnorm(n_id, sd = spec$sd); u <- u - mean(u)
  eta <- spec$mu[[1L]] + spec$mu[[2L]] * data$x + u[id]
  sigma <- exp(spec$sigma[[1L]] + spec$sigma[[2L]] * data$z)
  if (route == "student") data$y <- eta + sigma * sample(qt((seq_len(n)-.5)/n, df = 2 + exp(spec$nu)))
  if (route == "lognormal") data$y <- rlnorm(n, meanlog = eta, sdlog = sigma)
  if (route == "gamma") data$y <- rgamma(n, shape = 1/sigma^2, scale = exp(eta) * sigma^2)
  data <- mr_g4g5_mask_mcar(data, "y", seed = if (use_g3_seed) defaults[[route]] else seed + 1L)
  truth <- c("fixef:mu:(Intercept)" = spec$mu[[1L]], "fixef:mu:x" = spec$mu[[2L]],
    "fixef:sigma:(Intercept)" = spec$sigma[[1L]], "fixef:sigma:z" = spec$sigma[[2L]])
  if (route == "student") truth <- c(truth, "fixef:nu:(Intercept)" = spec$nu)
  truth <- c(truth, "sd:mu:(1 | id)" = spec$sd)
  list(data = data, truth = truth, information_multiplier = information_multiplier)
}

mr_g4g5_fit_t2 <- function(route, data, se = FALSE) {
  f <- switch(route,
    student = bf(y ~ x + (1 | id), sigma ~ z, nu ~ 1),
    lognormal = bf(y ~ x + (1 | id), sigma ~ z), gamma = bf(y ~ x + (1 | id), sigma ~ z),
    skew_normal = bf(y ~ x, sigma ~ z, nu ~ 1))
  family <- switch(route, student = student(), lognormal = lognormal(), gamma = Gamma(link = "log"), skew_normal = skew_normal())
  drmTMB(f, family, data, missing = miss_control(response = "include"), control = drm_control(se = se))
}

mr_g4g5_t3_dgp <- function(route, information_multiplier = 1, seed = NULL) {
  if (!route %in% c("tweedie", "zero_one_beta") || !information_multiplier %in% c(.5, 1, 2)) {
    stop("Unsupported T3 route or information multiplier.", call. = FALSE)
  }
  defaults <- c(tweedie = 2026071321L, zero_one_beta = 2026071322L)
  use_g3_seed <- is.null(seed); if (use_g3_seed) seed <- defaults[[route]]; set.seed(seed)
  n <- as.integer(ceiling(c(tweedie = 500L, zero_one_beta = 1600L)[[route]] * information_multiplier / 4) * 4)
  if (route == "tweedie") {
    data <- data.frame(x = runif(n, -1, 1), z = rnorm(n))
    mu <- exp(.20 + .45 * data$x); sigma <- exp(-.55 + .20 * data$z)
    data$y <- rtweedie_compound(n, mu = mu, phi = sigma^2, power = 1.35)
    truth <- c("fixef:mu:(Intercept)" = .20, "fixef:mu:x" = .45,
      "fixef:sigma:(Intercept)" = -.55, "fixef:sigma:z" = .20, "fixef:nu:(Intercept)" = 1.35)
  } else {
    data <- data.frame(x = rnorm(n), z = rnorm(n), w = rnorm(n), v = rnorm(n))
    mu <- plogis(-.20 + .65 * data$x); sigma <- exp(-.85 + .22 * data$z)
    zoi <- plogis(-1 + .45 * data$w); coi <- plogis(.15 - .55 * data$v)
    data$y <- rbeta(n, mu/sigma^2, (1-mu)/sigma^2)
    boundary <- runif(n) < zoi; data$y[boundary] <- as.numeric(runif(sum(boundary)) < coi[boundary])
    truth <- c("fixef:mu:(Intercept)" = -.20, "fixef:mu:x" = .65,
      "fixef:sigma:(Intercept)" = -.85, "fixef:sigma:z" = .22,
      "fixef:zoi:(Intercept)" = -1, "fixef:zoi:w" = .45,
      "fixef:coi:(Intercept)" = .15, "fixef:coi:v" = -.55)
  }
  data <- mr_g4g5_mask_mcar(data, "y", if (use_g3_seed) defaults[[route]] else seed + 1L)
  list(data = data, truth = truth, information_multiplier = information_multiplier)
}

mr_g4g5_fit_t3 <- function(route, data, se = FALSE) {
  if (route == "tweedie") {
    drmTMB(bf(y ~ x, sigma ~ z, nu ~ 1), tweedie(), data, missing = miss_control(response = "include"), control = drm_control(se = se))
  } else {
    drmTMB(bf(y ~ x, sigma ~ z, zoi ~ w, coi ~ v), zero_one_beta(), data, missing = miss_control(response = "include"), control = drm_control(se = se))
  }
}

mr_g4g5_t4_dgp <- function(route, information_multiplier = 1, seed = NULL) {
  if (!route %in% c("beta_binomial", "cumulative_logit") || !information_multiplier %in% c(.5, 1, 2)) {
    stop("Unsupported T4 route or information multiplier.", call. = FALSE)
  }
  defaults <- c(beta_binomial = 2026071421L, cumulative_logit = 2026071422L)
  use_g3_seed <- is.null(seed); if (use_g3_seed) seed <- defaults[[route]]; set.seed(seed)
  if (route == "beta_binomial") {
    n_id <- mr_g4g5_group_count(52L, 10L, information_multiplier); id <- factor(rep(seq_len(n_id), each = 10L)); n <- length(id)
    data <- data.frame(id = id, x = rnorm(n), z = rnorm(n), trials = sample(18:34, n, replace = TRUE))
    u <- rnorm(n_id, sd = .60); u <- u - mean(u)
    mu <- plogis(-.25 + .65 * data$x + u[id]); sigma <- exp(-1.35 + .15 * data$z); phi <- 1/sigma^2
    data$success <- rbinom(n, data$trials, rbeta(n, mu*phi, (1-mu)*phi)); data$failure <- data$trials - data$success
    data <- mr_g4g5_mask_mcar(data, "success", if (use_g3_seed) defaults[[route]] else seed+1L)
    data$failure[is.na(data$success)] <- NA_real_
    truth <- c("fixef:mu:(Intercept)"=-.25,"fixef:mu:x"=.65,"fixef:sigma:(Intercept)"=-1.35,"fixef:sigma:z"=.15,"sd:mu:(1 | id)"=.60)
  } else {
    n <- as.integer(ceiling(900L * information_multiplier / 4) * 4); data <- data.frame(x = rnorm(n))
    eta <- .85 * data$x; p1 <- plogis(-.90 - eta); p2 <- plogis(.75 - eta) - p1
    draw <- vapply(seq_len(n), function(i) sample.int(3L, 1L, prob = c(p1[i], p2[i], 1-plogis(.75-eta[i]))), integer(1L))
    data$score <- ordered(c("low","medium","high")[draw], levels = c("low","medium","high"))
    data <- mr_g4g5_mask_mcar(data, "score", if (use_g3_seed) defaults[[route]] else seed+1L)
    truth <- c("fixef:mu:x"=.85, "ordinal:theta_ord:low|medium"=-.90,
      "ordinal:theta_ord:medium|high"=.75)
  }
  list(data=data, truth=truth, information_multiplier=information_multiplier)
}

mr_g4g5_fit_t4 <- function(route, data, se = FALSE) {
  if (route == "beta_binomial") drmTMB(bf(cbind(success, failure) ~ x + (1 | id), sigma ~ z), beta_binomial(), data, missing=miss_control(response="include"), control=drm_control(se=se))
  else drmTMB(bf(score ~ x), cumulative_logit(), data, missing=miss_control(response="include"), control=drm_control(se=se))
}

mr_g4g5_t5_dgp <- function(information_multiplier = 1, seed = 2026071506L) {
  if (!information_multiplier %in% c(.5, 1, 2)) stop("T5 information multiplier must be 0.5, 1, or 2.", call.=FALSE)
  set.seed(seed); n_id <- mr_g4g5_group_count(34L, 8L, information_multiplier); n <- n_id*8L
  id <- factor(rep(seq_len(n_id),each=8L)); data <- data.frame(id=id,x=rep(seq(-1,1,length.out=8L),n_id)+rnorm(n,sd=.05),z=rnorm(n))
  b <- rnorm(n_id,sd=.35); mu <- exp(.35-.28*data$x+b[id]); sigma <- exp(-.65+.15*data$z); p0 <- dnbinom(0,size=1/sigma^2,mu=mu)
  data$count <- qnbinom(p0+pmax(runif(n),.Machine$double.eps)*(1-p0),size=1/sigma^2,mu=mu)
  data <- mr_g4g5_mask_mcar(data,"count",seed=seed+1L,group="id")
  list(data=data,truth=c("fixef:mu:(Intercept)"=.35,"fixef:mu:x"=-.28,"fixef:sigma:(Intercept)"=-.65,"fixef:sigma:z"=.15,"sd:mu:(1 | id)"=.35),information_multiplier=information_multiplier)
}

mr_g4g5_fit_t5 <- function(data, se = FALSE) drmTMB(bf(count~x+(1|id),sigma~z),truncated_nbinom2(),data,missing=miss_control(response="include"),control=drm_control(se=se))

mr_g4g5_t6_dgp <- function(route, information_multiplier=1, seed=NULL) {
  if (!route %in% c("zi_poisson","zi_nbinom2","hurdle_nbinom2") || !information_multiplier %in% c(.5,1,2)) stop("Unsupported T6 route or information multiplier.",call.=FALSE)
  defaults<-c(zi_poisson=2026071609L,zi_nbinom2=2026071627L,hurdle_nbinom2=2026071650L); use_g3<-is.null(seed);if(use_g3)seed<-defaults[[route]];set.seed(seed)
  n<-as.integer(ceiling(1800L*information_multiplier/4)*4); habitat<-if(route=="hurdle_nbinom2") factor(rep(c("open","closed"),length.out=n)) else factor(sample(c("open","edge"),n,replace=TRUE))
  data<-data.frame(x=rnorm(n),z=rnorm(n),w=rnorm(n),habitat=habitat)
  if(route=="zi_poisson") {mu<-exp(.30-.35*data$x+.25*(data$habitat=="open")); zi<-plogis(-.90+.55*data$z-.45*(data$habitat=="open"));data$count<-ifelse(runif(n)<zi,0L,rpois(n,mu));truth<-c("fixef:mu:(Intercept)"=.30,"fixef:mu:x"=-.35,"fixef:mu:habitatopen"=.25,"fixef:zi:(Intercept)"=-.90,"fixef:zi:z"=.55,"fixef:zi:habitatopen"=-.45)}
  if(route=="zi_nbinom2") {mu<-exp(.45-.30*data$x+.25*(data$habitat=="open"));s<-exp(-.75+.20*data$z);zi<-plogis(-1.15+.45*data$w-.35*(data$habitat=="open"));data$count<-ifelse(runif(n)<zi,0L,rnbinom(n,size=1/s^2,mu=mu));truth<-c("fixef:mu:(Intercept)"=.45,"fixef:mu:x"=-.30,"fixef:mu:habitatopen"=.25,"fixef:sigma:(Intercept)"=-.75,"fixef:sigma:z"=.20,"fixef:zi:(Intercept)"=-1.15,"fixef:zi:w"=.45,"fixef:zi:habitatopen"=-.35)}
  if(route=="hurdle_nbinom2") {mu<-exp(.40-.22*data$x+.20*(data$habitat=="open"));s<-exp(-.75+.18*data$z);hu<-plogis(-.85+.45*data$w-.35*(data$habitat=="open"));p0<-dnbinom(0,size=1/s^2,mu=mu);data$count<-ifelse(runif(n)<hu,0L,qnbinom(p0+pmax(runif(n),.Machine$double.eps)*(1-p0),size=1/s^2,mu=mu));truth<-c("fixef:mu:(Intercept)"=.40,"fixef:mu:x"=-.22,"fixef:mu:habitatopen"=.20,"fixef:sigma:(Intercept)"=-.75,"fixef:sigma:z"=.18,"fixef:hu:(Intercept)"=-.85,"fixef:hu:w"=.45,"fixef:hu:habitatopen"=-.35)}
  data<-mr_g4g5_mask_mcar(data,"count",if(use_g3)defaults[[route]] else seed+1L);list(data=data,truth=truth,information_multiplier=information_multiplier)
}

mr_g4g5_fit_t6 <- function(route,data, se = FALSE) switch(route,zi_poisson=drmTMB(bf(count~x+habitat,zi~z+habitat),poisson(),data,missing=miss_control(response="include"),control=drm_control(se=se)),zi_nbinom2=drmTMB(bf(count~x+habitat,sigma~z,zi~w+habitat),nbinom2(),data,missing=miss_control(response="include"),control=drm_control(se=se)),hurdle_nbinom2=drmTMB(bf(count~x+habitat,sigma~z,hu~w+habitat),truncated_nbinom2(),data,missing=miss_control(response="include"),control=drm_control(se=se)))

mr_g4g5_route_fixture <- function(route_id, information_multiplier = 1, seed = NULL) {
  if (!route_id %in% mr_g4g5_route_manifest()$route_id) stop("Unknown missing-response route.", call.=FALSE)
  if (route_id == "gaussian") return(mr_g4g5_gaussian_g3_dgp(information_multiplier, if(is.null(seed))2026071101L else seed))
  if (route_id == "biv_gaussian") return(mr_g4g5_biv_gaussian_g3_dgp(information_multiplier, if(is.null(seed))2026071103L else seed))
  if (route_id == "binomial") {
    use_seed <- if(is.null(seed)) 202L else seed; set.seed(use_seed)
    n <- as.integer(ceiling(4000L * information_multiplier / 4) * 4); data <- data.frame(x=rnorm(n))
    data$y <- rbinom(n,1L,plogis(-.3+1.1*data$x)); data <- mr_g4g5_mask_mcar(data,"y",if(is.null(seed))202L else seed+1L)
    return(list(data=data,truth=c("fixef:mu:(Intercept)"=-.3,"fixef:mu:x"=1.1),information_multiplier=information_multiplier))
  }
  if (route_id %in% c("poisson","nbinom2","beta")) return(mr_g4g5_t1_ri_dgp(route_id,information_multiplier,seed))
  if (route_id %in% c("student","lognormal","gamma","skew_normal")) return(mr_g4g5_t2_dgp(route_id,information_multiplier,seed))
  if (route_id %in% c("tweedie","zero_one_beta")) return(mr_g4g5_t3_dgp(route_id,information_multiplier,seed))
  if (route_id %in% c("beta_binomial","cumulative_logit")) return(mr_g4g5_t4_dgp(route_id,information_multiplier,seed))
  if (route_id == "truncated_nbinom2") return(mr_g4g5_t5_dgp(information_multiplier,if(is.null(seed))2026071506L else seed))
  mr_g4g5_t6_dgp(route_id,information_multiplier,seed)
}

mr_g4g5_route_fit <- function(route_id, data, se = FALSE) {
  if (route_id == "gaussian") return(mr_g4g5_fit_gaussian(data, se = se))
  if (route_id == "biv_gaussian") return(mr_g4g5_fit_biv_gaussian(data, se = se))
  if (route_id == "binomial") return(drmTMB(bf(y ~ x), binomial(), data, missing=miss_control(response="include"), control=drm_control(se=se)))
  if (route_id %in% c("poisson","nbinom2","beta")) return(mr_g4g5_fit_t1_ri(route_id,data, se = se))
  if (route_id %in% c("student","lognormal","gamma","skew_normal")) return(mr_g4g5_fit_t2(route_id,data, se = se))
  if (route_id %in% c("tweedie","zero_one_beta")) return(mr_g4g5_fit_t3(route_id,data, se = se))
  if (route_id %in% c("beta_binomial","cumulative_logit")) return(mr_g4g5_fit_t4(route_id,data, se = se))
  if (route_id == "truncated_nbinom2") return(mr_g4g5_fit_t5(data, se = se))
  mr_g4g5_fit_t6(route_id,data, se = se)
}

mr_g4g5_materialise_target_manifest <- function(route_id, information_multiplier = 1, seed = NULL) {
  fixture <- mr_g4g5_route_fixture(route_id, information_multiplier, seed)
  fit <- mr_g4g5_route_fit(route_id, fixture$data)
  list(fit = fit, manifest = mr_g4_target_manifest(route_id, profile_targets(fit), fixture$truth))
}

# Produce the immutable target contract before a campaign begins.  Later
# information rungs use these exact names, scales, truths, and method choices;
# no route is allowed to select a more convenient target after observing a fit.
mr_g4g5_freeze_target_manifests <- function(information_multiplier = 1, seed = NULL) {
  routes <- mr_g4g5_route_manifest()$route_id
  out <- setNames(lapply(routes, function(route_id) {
    mr_g4g5_materialise_target_manifest(route_id, information_multiplier, seed)$manifest
  }), routes)
  lapply(out, mr_g4_validate_target_manifest)
  out
}

mr_g4_failure_records <- function(target_manifest, replicate = 1L, message,
                                  failure_stage = "fit", trace = TRUE) {
  mr_g4_validate_target_manifest(target_manifest)
  out <- target_manifest
  out$replicate <- as.integer(replicate)
  out$target_scale <- out$scale
  out$conf.low <- NA_real_
  out$conf.high <- NA_real_
  out$conf.status <- paste0(failure_stage, "_failed")
  out$profile.boundary <- NA
  out$profile.message <- as.character(message)
  out$trace_requested <- as.logical(trace)
  out$profile_trace <- NA_character_
  out <- out[, c("route_id", "replicate", "parm", "truth", "conf.level",
    "target_scale", "target_class", "profile_ready", "interval_method",
    "conf.low", "conf.high", "conf.status", "profile.boundary",
    "profile.message", "trace_requested", "profile_trace")]
  do.call(rbind, lapply(seq_len(nrow(out)), function(i) mr_g4_validate_record(out[i, , drop = FALSE])))
}

mr_g4_run_route <- function(route_id, information_multiplier = 1, seed = NULL,
                            replicate = 1L, trace = TRUE, target_manifest = NULL) {
  fixture <- tryCatch(
    mr_g4g5_route_fixture(route_id, information_multiplier, seed),
    error = function(e) e
  )
  if (inherits(fixture, "error")) {
    if (is.null(target_manifest)) stop(conditionMessage(fixture), call. = FALSE)
    return(mr_g4_failure_records(target_manifest, replicate, conditionMessage(fixture), "fixture", trace))
  }
  fit <- tryCatch(mr_g4g5_route_fit(route_id, fixture$data), error = function(e) e)
  if (is.null(target_manifest) && !inherits(fit, "error")) {
    target_manifest <- mr_g4_target_manifest(route_id, profile_targets(fit), fixture$truth)
  }
  if (inherits(fit, "error")) {
    if (is.null(target_manifest)) stop(conditionMessage(fit), call. = FALSE)
    records <- mr_g4_failure_records(target_manifest, replicate, conditionMessage(fit), "fit", trace)
  } else {
    records <- mr_g4_run_target_manifest(fit, target_manifest, replicate = replicate, trace = trace)
  }
  records <- mr_g4_add_mask_receipt(records, fixture, route_id)
  records$information_multiplier <- information_multiplier
  records$information_rung <- paste0(information_multiplier, "x")
  records
}

# Store the realized MCAR mask receipt on every G4/G5 record.  Bivariate
# records retain the four outcome-pattern counts rather than collapsing the
# partial-response information into a single missing-row number.
mr_g4_add_mask_receipt <- function(records, fixture, route_id) {
  response <- if (route_id == "biv_gaussian") c("y1", "y2") else if (route_id == "beta") "prop" else if (route_id == "binomial") "y" else if (route_id == "cumulative_logit") "score" else if (route_id %in% c("gaussian", "student", "lognormal", "gamma", "skew_normal", "tweedie", "zero_one_beta")) "y" else "count"
  records$mask_fraction <- 0.25
  if (length(response) == 1L) {
    records$mask_any_response_rows <- sum(is.na(fixture$data[[response]]))
  } else {
    missing_y1 <- is.na(fixture$data$y1)
    missing_y2 <- is.na(fixture$data$y2)
    records$mask_any_response_rows <- sum(missing_y1 | missing_y2)
    records$mask_complete_pairs <- sum(!missing_y1 & !missing_y2)
    records$mask_y1_only_missing <- sum(missing_y1 & !missing_y2)
    records$mask_y2_only_missing <- sum(!missing_y1 & missing_y2)
    records$mask_both_missing <- sum(missing_y1 & missing_y2)
  }
  records
}

mr_g4_write_records <- function(records, path) {
  if (!is.data.frame(records) || nrow(records) == 0L || !all(c("route_id", "parm", "g4_pass") %in% names(records))) {
    stop("G4 artifacts must be a non-empty target-record data frame.", call.=FALSE)
  }
  dir.create(dirname(path), recursive=TRUE, showWarnings=FALSE)
  saveRDS(records, path)
  invisible(normalizePath(path))
}

mr_g4_write_artifact <- function(records, registry, path) {
  mr_g4_validate_campaign(records, registry)
  artifact <- list(
    schema_version = "mr-g4g5-v1",
    records = records,
    registry = registry,
    created_utc = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  saveRDS(artifact, path)
  invisible(normalizePath(path))
}

# Freeze the actual, canonical targets for one route after constructing its
# frozen G3 DGP. `truth` is a named numeric vector on the reporting scale.
# Requiring an exact name match prevents a runner-local alias (especially for
# ordinal cutpoints and random-effect SDs) from silently shrinking the target
# set.
mr_g4_target_manifest <- function(route_id, targets, truth) {
  required <- c("parm", "target_class", "dpar", "scale", "profile_ready")
  if (!is.data.frame(targets) || !all(required %in% names(targets))) {
    stop("`targets` must be the canonical `profile_targets()` table.", call. = FALSE)
  }
  if (!is.numeric(truth) || is.null(names(truth)) || any(!nzchar(names(truth)))) {
    stop("`truth` must be a named numeric vector keyed by canonical `parm`.", call. = FALSE)
  }
  if (anyDuplicated(targets$parm) || anyDuplicated(names(truth)) ||
      !setequal(targets$parm, names(truth))) {
    stop("Frozen truths must name every canonical target exactly once.", call. = FALSE)
  }
  out <- targets[, required, drop = FALSE]
  out$route_id <- route_id
  out$truth <- unname(truth[out$parm])
  out$interval_method <- ifelse(out$profile_ready, "profile", "wald")
  out$conf.level <- 0.95
  out <- out[c("route_id", "parm", "truth", "target_class", "dpar", "scale",
    "profile_ready", "interval_method", "conf.level")]
  row.names(out) <- NULL
  out
}

mr_g4_validate_target_manifest <- function(manifest) {
  required <- c("route_id", "parm", "truth", "profile_ready", "interval_method", "conf.level")
  if (!is.data.frame(manifest) || !all(required %in% names(manifest)) ||
      anyDuplicated(manifest[c("route_id", "parm")])) {
    stop("A target manifest must have one canonical target per route.", call. = FALSE)
  }
  if (any(!is.finite(manifest$truth)) || any(manifest$conf.level != 0.95) ||
      any(!manifest$interval_method %in% c("profile", "wald")) ||
      any(manifest$profile_ready != (manifest$interval_method == "profile"))) {
    stop("Target manifest has an invalid truth, interval method, or confidence level.", call. = FALSE)
  }
  invisible(manifest)
}

# Convert one profile attempt into an immutable G4 record.  The caller supplies
# the frozen truth on the reporting scale for the canonical `profile_targets()`
# parameter name.  G4 is an interval-feasibility gate: one-shot containment is
# retained as a diagnostic, while repeated coverage belongs exclusively to G5.
mr_g4_profile_record <- function(fit, route_id, parm, truth, replicate = 1L,
                                 level = 0.95, trace = TRUE) {
  targets <- profile_targets(fit)
  target <- targets[targets$parm == parm, , drop = FALSE]
  if (nrow(target) != 1L) {
    stop("`parm` must identify exactly one canonical profile target.", call. = FALSE)
  }
  ci <- tryCatch(
    confint(fit, parm = parm, level = level, method = "profile", trace = trace),
    error = function(e) e
  )
  out <- data.frame(
    route_id = route_id, replicate = as.integer(replicate), parm = parm,
    truth = as.numeric(truth), conf.level = level, target_scale = target$scale,
    target_class = target$target_class, profile_ready = target$profile_ready,
    conf.low = NA_real_, conf.high = NA_real_, conf.status = "profile_failed",
    profile.boundary = NA, profile.message = NA_character_,
    stringsAsFactors = FALSE
  )
  if (inherits(ci, "error")) {
    out$profile.message <- conditionMessage(ci)
    return(mr_g4_validate_record(out))
  }
  row <- ci[ci$parm == parm, , drop = FALSE]
  if (nrow(row) != 1L) {
    out$profile.message <- "profile output did not contain the requested target"
    return(mr_g4_validate_record(out))
  }
  out$conf.low <- row$lower
  out$conf.high <- row$upper
  out$conf.status <- row$conf.status
  out$profile.boundary <- row$profile.boundary
  out$profile.message <- row$profile.message
  mr_g4_validate_record(out)
}

mr_g4_validate_record <- function(record) {
  required <- c("conf.low", "conf.high", "conf.status", "profile.boundary", "truth")
  if (!is.data.frame(record) || nrow(record) != 1L || !all(required %in% names(record))) {
    stop("A G4 record must be one row with interval and truth fields.", call. = FALSE)
  }
  finite_two_sided <- is.finite(record$conf.low) && is.finite(record$conf.high) &&
    record$conf.low < record$conf.high
  method <- if ("interval_method" %in% names(record)) record$interval_method else "profile"
  trace_ok <- !"trace_requested" %in% names(record) || isTRUE(record$trace_requested)
  profile_ok <- identical(method, "profile") && identical(as.character(record$conf.status), "profile") &&
    identical(as.logical(record$profile.boundary), FALSE) && trace_ok
  wald_ok <- identical(method, "wald") && identical(as.character(record$conf.status), "wald")
  record$g4_interval_usable <- finite_two_sided && (profile_ok || wald_ok)
  record$g4_truth_contained <- record$g4_interval_usable &&
    record$conf.low <= record$truth && record$truth <= record$conf.high
  record$g4_feasible <- record$g4_interval_usable
  # Compatibility field for existing artifact consumers.  It now carries the
  # explicit feasibility decision, not a one-shot coverage decision.
  record$g4_pass <- record$g4_feasible
  record
}

# Run the frozen target manifest without dropping an unavailable profile or a
# failed fit. This is the route-level unit consumed by the future DGP runners.
mr_g4_run_target_manifest <- function(fit, target_manifest, replicate = 1L, trace = TRUE) {
  mr_g4_validate_target_manifest(target_manifest)
  rows <- lapply(seq_len(nrow(target_manifest)), function(i) {
    target <- target_manifest[i, , drop = FALSE]
    trace_lines <- character()
    ci <- tryCatch({
      value <- NULL
      trace_lines <- utils::capture.output({
        value <- confint(fit, parm = target$parm, level = target$conf.level,
          method = target$interval_method, trace = trace)
      })
      value
    }, error = function(e) e)
    out <- data.frame(
      route_id = target$route_id, replicate = as.integer(replicate), parm = target$parm,
      truth = target$truth, conf.level = target$conf.level, target_scale = target$scale,
      target_class = target$target_class, profile_ready = target$profile_ready,
      interval_method = target$interval_method, conf.low = NA_real_, conf.high = NA_real_,
      conf.status = paste0(target$interval_method, "_failed"), profile.boundary = NA,
      profile.message = NA_character_, stringsAsFactors = FALSE
    )
    out$trace_requested <- as.logical(trace)
    out$profile_trace <- paste(trace_lines, collapse = "\n")
    if (inherits(ci, "error")) {
      out$profile.message <- conditionMessage(ci)
      return(mr_g4_validate_record(out))
    }
    row <- ci[ci$parm == target$parm, , drop = FALSE]
    if (nrow(row) != 1L) {
      out$profile.message <- "interval output did not contain the requested target"
      return(mr_g4_validate_record(out))
    }
    out$conf.low <- row$lower
    out$conf.high <- row$upper
    out$conf.status <- row$conf.status
    out$profile.boundary <- row$profile.boundary
    out$profile.message <- row$profile.message
    mr_g4_validate_record(out)
  })
  do.call(rbind, rows)
}

# Validate the G4 gate at campaign scope.  A collection of individually valid
# records is insufficient: every frozen route × target × information rung must
# be represented once, and each profiled record must have requested a trace.
mr_g4_validate_campaign <- function(records, registry) {
  if (!is.list(registry) || is.null(registry$cells) || registry$n_rep != 1L) {
    stop("A G4 campaign requires a one-attempt frozen task registry.", call. = FALSE)
  }
  required <- c("route_id", "parm", "information_rung", "g4_feasible",
    "interval_method", "trace_requested", "conf.low", "conf.high")
  if (!is.data.frame(records) || !all(required %in% names(records))) {
    stop("G4 records must carry route, target, rung, method, trace, and gate fields.", call. = FALSE)
  }
  expected <- registry$cells[, c("route_id", "parm", "information_rung"), drop = FALSE]
  actual <- records[, c("route_id", "parm", "information_rung"), drop = FALSE]
  expected_key <- do.call(paste, c(expected, sep = "\r"))
  actual_key <- do.call(paste, c(actual, sep = "\r"))
  if (anyDuplicated(actual_key) || !setequal(expected_key, actual_key)) {
    stop("G4 records must retain exactly one result for every frozen target and information rung.", call. = FALSE)
  }
  profiled <- records$interval_method == "profile"
  if (any(profiled & !records$trace_requested)) {
    stop("Profiled G4 records must retain trace-request evidence.", call. = FALSE)
  }
  invisible(records)
}

# Reconcile independently checkpointed G4 route/rung results before the
# campaign-level validator is called.  A repeated checkpoint is harmless only
# when its retained target record is byte-for-byte equivalent after migration;
# otherwise it is evidence of an ambiguous rerun and must stop the campaign.
# Keeping source paths on the reconciled rows makes the evidence receipt
# auditable without silently preferring a local or remote copy.
mr_g4_reconcile_checkpoints <- function(paths) {
  if (!is.character(paths) || !length(paths) || any(!file.exists(paths))) {
    stop("`paths` must name one or more existing G4 checkpoint files.", call. = FALSE)
  }
  required <- c("route_id", "parm", "information_rung")
  records <- lapply(paths, function(path) {
    x <- readRDS(path)
    if (!is.data.frame(x) || !all(required %in% names(x))) {
      stop("Each G4 checkpoint must be a target-record data frame.", call. = FALSE)
    }
    if (!"g4_feasible" %in% names(x) && "g4_interval_usable" %in% names(x)) {
      x$g4_feasible <- x$g4_interval_usable
    }
    x$.mr_g4_checkpoint_path <- normalizePath(path)
    x
  })
  fields <- Reduce(union, lapply(records, names))
  records <- lapply(records, function(x) {
    missing <- setdiff(fields, names(x))
    for (field in missing) x[[field]] <- NA
    x[, fields, drop = FALSE]
  })
  all_records <- do.call(rbind, records)
  key <- do.call(paste, c(all_records[required], sep = "\r"))
  groups <- split(seq_len(nrow(all_records)), key)
  keep <- vapply(groups, `[[`, integer(1L), 1L)
  sources <- vapply(names(groups), function(group_key) {
    index <- groups[[group_key]]
    rows <- all_records[index, setdiff(names(all_records), ".mr_g4_checkpoint_path"), drop = FALSE]
    if (nrow(rows) > 1L && !all(vapply(seq_len(nrow(rows))[-1L], function(i) {
      # Receipts from separate checkpoint files acquire different row names
      # during rbind().  Row names are provenance-free and must not turn two
      # otherwise identical receipts into an apparent collision.
      left <- rows[1L, , drop = FALSE]
      right <- rows[i, , drop = FALSE]
      row.names(left) <- NULL
      row.names(right) <- NULL
      identical(left, right)
    }, logical(1L)))) {
      stop(sprintf("Conflicting G4 checkpoint records share a route, target, and information rung: %s.",
        gsub("\r", " / ", group_key, fixed = TRUE)), call. = FALSE)
    }
    paste(sort(unique(all_records$.mr_g4_checkpoint_path[index])), collapse = ";")
  }, character(1L))
  out <- all_records[keep, setdiff(names(all_records), ".mr_g4_checkpoint_path"), drop = FALSE]
  out$checkpoint_paths <- unname(sources[key[keep]])
  row.names(out) <- NULL
  out
}

mr_g4_run_campaign <- function(target_manifests, registry = NULL, trace = TRUE,
                               checkpoint_path = NULL) {
  if (is.null(registry)) registry <- mr_g4g5_task_registry(target_manifests)
  if (registry$n_rep != 1L) {
    stop("G4 execution uses one retained attempt per frozen target cell.", call. = FALSE)
  }
  cells <- registry$cells
  seed_lookup <- registry$seeds$seed[match(cells$cell_id, registry$seeds$cell_id)]
  records <- if (!is.null(checkpoint_path) && file.exists(checkpoint_path)) {
    readRDS(checkpoint_path)
  } else {
    NULL
  }
  if (!is.null(records) && !"g4_feasible" %in% names(records) &&
      "g4_interval_usable" %in% names(records)) {
    # Checkpoints written before the feasibility-only G4 decision retain the
    # primitive interval field, so they can be migrated without rerunning fits.
    records$g4_feasible <- records$g4_interval_usable
  }
  if (!is.null(records) && (!is.data.frame(records) || !all(c("route_id", "parm", "information_rung") %in% names(records)))) {
    stop("G4 checkpoint must contain retained target records.", call. = FALSE)
  }
  key <- function(x) do.call(paste, c(x[c("route_id", "parm", "information_rung")], sep = "\r"))
  for (i in seq_len(nrow(cells))) {
    cell <- cells[i, , drop = FALSE]
    cell_key <- key(cell)
    if (!is.null(records) && cell_key %in% key(records)) next
    route_manifest <- target_manifests[[cell$route_id]]
    target <- route_manifest[route_manifest$parm == cell$parm, , drop = FALSE]
    next_record <- mr_g4_run_route(
      route_id = cell$route_id, information_multiplier = cell$information_multiplier,
      seed = seed_lookup[[i]], replicate = 1L, trace = trace, target_manifest = target
    )
    records <- if (is.null(records)) next_record else rbind(records, next_record)
    if (!is.null(checkpoint_path)) {
      dir.create(dirname(checkpoint_path), recursive = TRUE, showWarnings = FALSE)
      saveRDS(records, checkpoint_path)
    }
  }
  mr_g4_validate_campaign(records, registry)
  records
}

mr_g4_campaign_summary <- function(records, registry) {
  mr_g4_validate_campaign(records, registry)
  aggregate(cbind(n_target = one, n_interval_usable = g4_interval_usable,
    n_truth_contained = g4_truth_contained, n_g4_feasible = g4_feasible) ~ route_id + information_rung,
    data = transform(records, one = 1L, g4_feasible = as.integer(g4_feasible),
      g4_interval_usable = as.integer(g4_interval_usable),
      g4_truth_contained = as.integer(g4_truth_contained)), FUN = sum)
}

# Coverage is intentionally unconditional on fit and interval success. Every
# planned replicate stays in the denominator; unusable intervals therefore
# contribute `covered = FALSE` rather than being silently dropped.
mr_g5_summarise_attempts <- function(records, by = c("route_id", "parm", "information_rung"),
                                     planned = 1200L) {
  if ("interval_usable" %in% names(records) && "truth_contained" %in% names(records)) {
    records$g4_interval_usable <- records$interval_usable
    records$g4_truth_contained <- records$truth_contained
  }
  required <- c(by, "g4_interval_usable", "g4_truth_contained")
  if (!is.data.frame(records) || !all(required %in% names(records))) {
    stop("G5 records must include grouping and G4 interval fields.", call. = FALSE)
  }
  if (!is.numeric(planned) || length(planned) != 1L || planned < 1L) {
    stop("`planned` must be one positive number of planned attempts.", call. = FALSE)
  }
  key <- interaction(records[by], drop = TRUE, lex.order = TRUE)
  pieces <- split(records, key)
  out <- lapply(pieces, function(x) {
    if (nrow(x) != planned) {
      stop("Each G5 cell must retain exactly its planned number of attempts.", call. = FALSE)
    }
    covered <- as.logical(x$g4_truth_contained)
    covered[is.na(covered)] <- FALSE
    data.frame(x[1L, by, drop = FALSE], n_planned = planned,
      n_attempt = nrow(x), n_interval_usable = sum(x$g4_interval_usable %in% TRUE),
      n_covered = sum(covered), coverage = mean(covered),
      coverage_mcse = sqrt(mean(covered) * (1 - mean(covered)) / planned),
      stringsAsFactors = FALSE, check.names = FALSE)
  })
  out <- do.call(rbind, out)
  row.names(out) <- NULL
  out
}

mr_g4g5_seed_table <- function(cells, n_rep, master_seed) {
  old_seed <- if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
    get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    if (is.null(old_seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        rm(list = ".Random.seed", envir = .GlobalEnv)
      }
    } else {
      assign(".Random.seed", old_seed, envir = .GlobalEnv)
    }
  }, add = TRUE)
  set.seed(master_seed)
  data.frame(
    cell_id = rep(cells$cell_id, each = n_rep),
    cell_index = rep(seq_len(nrow(cells)), each = n_rep),
    replicate = rep(seq_len(n_rep), times = nrow(cells)),
    seed = sample.int(.Machine$integer.max, nrow(cells) * n_rep),
    stringsAsFactors = FALSE
  )
}

# Build the deterministic G4/G5 task registry only after all route-specific
# target manifests are frozen.  The registry is a plan, not evidence: G5
# callers must pass only rows whose G4 records pass.
mr_g4g5_task_registry <- function(target_manifests, information_rungs = c(0.5, 1, 2),
                                  n_rep = 1L, master_seed = 2026073001L) {
  routes <- mr_g4g5_route_manifest()
  if (!is.list(target_manifests) || is.null(names(target_manifests)) ||
      !setequal(names(target_manifests), routes$route_id)) {
    stop("`target_manifests` must contain one frozen manifest for every one of the 18 routes.", call. = FALSE)
  }
  if (!is.numeric(information_rungs) || !identical(information_rungs, c(0.5, 1, 2))) {
    stop("Information rungs must be exactly 0.5, 1, and 2 times the G3 design.", call. = FALSE)
  }
  if (!is.numeric(n_rep) || length(n_rep) != 1L || n_rep < 1L || n_rep != as.integer(n_rep)) {
    stop("`n_rep` must be one positive whole number.", call. = FALSE)
  }
  targets <- do.call(rbind, lapply(target_manifests, function(x) {
    mr_g4_validate_target_manifest(x)
    x
  }))
  targets <- merge(targets, routes, by = "route_id", all.x = TRUE, sort = FALSE)
  cells <- do.call(rbind, lapply(information_rungs, function(rung) {
    out <- targets
    out$information_rung <- paste0(rung, "x")
    out$information_multiplier <- rung
    out
  }))
  cells$cell_id <- sprintf("mr_g4g5_%04d", seq_len(nrow(cells)))
  seeds <- mr_g4g5_seed_table(cells, n_rep = n_rep, master_seed = master_seed)
  list(cells = cells, seeds = seeds, n_rep = as.integer(n_rep), master_seed = master_seed)
}

mr_g5_registry_from_g4 <- function(target_manifests, g4_records, master_seed = 2026073002L) {
  required <- c("route_id", "parm", "information_rung", "g4_feasible")
  if (!is.data.frame(g4_records) || !all(required %in% names(g4_records))) {
    stop("`g4_records` must include route, parameter, information rung, and pass fields.", call. = FALSE)
  }
  passed <- g4_records[g4_records$g4_feasible %in% TRUE,
    c("route_id", "parm", "information_rung"), drop = FALSE]
  if (nrow(passed) == 0L) {
    stop("No G4-feasible targets are eligible for G5.", call. = FALSE)
  }
  if (anyDuplicated(passed)) {
    stop("G4 eligibility must retain at most one result per route, target, and information rung.", call. = FALSE)
  }
  valid_rungs <- c("0.5x", "1x", "2x")
  if (any(!passed$information_rung %in% valid_rungs)) {
    stop("G4 eligibility contains an unknown information rung.", call. = FALSE)
  }
  targets <- do.call(rbind, target_manifests)
  target_key <- paste(targets$route_id, targets$parm, sep = "\r")
  passed_key <- paste(passed$route_id, passed$parm, sep = "\r")
  index <- match(passed_key, target_key)
  if (anyNA(index)) {
    stop("A G4-feasible result names a target absent from the frozen manifest.", call. = FALSE)
  }
  # G5 is permitted cohort-by-cohort, but it inherits the *same* information
  # rung that passed G4.  Passing at 2x must never authorize a 0.5x campaign.
  cells <- targets[index, , drop = FALSE]
  cells$information_rung <- passed$information_rung
  cells$information_multiplier <- as.numeric(sub("x$", "", cells$information_rung))
  cells$cell_id <- sprintf("mr_g5_%04d", seq_len(nrow(cells)))
  seeds <- mr_g4g5_seed_table(cells, n_rep = 1200L, master_seed = master_seed)
  list(cells = cells, seeds = seeds, n_rep = 1200L, master_seed = master_seed)
}

# A G5 attempt is a fresh masked DGP, fit, and interval calculation.  It is
# deliberately a separate record type: G4 feasibility authorizes the target,
# but does not turn a failed G5 fit or interval into a dropped observation.
mr_g5_failure_record <- function(cell, seed, message, fit_status = "fit_failed") {
  target <- cell[, c("route_id", "parm", "truth", "target_class", "dpar", "scale",
    "profile_ready", "interval_method", "conf.level", "information_multiplier",
    "information_rung"), drop = FALSE]
  out <- data.frame(
    route_id = target$route_id, parm = target$parm, information_rung = target$information_rung,
    information_multiplier = target$information_multiplier, replicate = NA_integer_,
    attempt_seed = as.integer(seed), truth = target$truth, target_class = target$target_class,
    target_scale = target$scale, interval_method = target$interval_method,
    fit_status = fit_status, fit_converged = FALSE, pdHess = NA,
    conf.low = NA_real_, conf.high = NA_real_, conf.status = "profile_failed",
    profile.boundary = NA, profile.message = as.character(message),
    trace_requested = TRUE, profile_trace = "", mask_fraction = 0.25,
    mask_any_response_rows = NA_real_, stringsAsFactors = FALSE
  )
  out$interval_usable <- FALSE
  out$truth_contained <- FALSE
  out$boundary_or_clamp <- FALSE
  out
}

mr_g5_validate_record <- function(record) {
  required <- c("route_id", "parm", "information_rung", "replicate", "attempt_seed",
    "fit_status", "fit_converged", "pdHess", "interval_usable", "truth_contained",
    "conf.low", "conf.high", "conf.status", "profile.boundary", "boundary_or_clamp",
    "mask_fraction", "mask_any_response_rows")
  if (!is.data.frame(record) || nrow(record) != 1L || !all(required %in% names(record))) {
    stop("A G5 record must retain one attempted fit, interval, and containment result.", call. = FALSE)
  }
  if (!is.finite(record$attempt_seed) || is.na(record$replicate) ||
      !is.logical(record$interval_usable) || !is.logical(record$truth_contained)) {
    stop("A G5 record has an invalid attempt identifier or interval outcome.", call. = FALSE)
  }
  if (isTRUE(record$truth_contained) && !isTRUE(record$interval_usable)) {
    stop("G5 containment requires a usable interval.", call. = FALSE)
  }
  no_realization <- identical(record$fit_status, "fixture_failed") && is.na(record$mask_any_response_rows)
  if (!identical(as.numeric(record$mask_fraction), 0.25) ||
      (!no_realization && !is.finite(record$mask_any_response_rows))) {
    stop("A G5 record must retain its realized 25% MCAR mask receipt.", call. = FALSE)
  }
  if (identical(record$route_id, "biv_gaussian") && !all(c(
      "mask_complete_pairs", "mask_y1_only_missing", "mask_y2_only_missing", "mask_both_missing"
    ) %in% names(record))) {
    stop("A bivariate G5 record must retain every partial-response mask count.", call. = FALSE)
  }
  invisible(record)
}

mr_g5_run_attempt <- function(cell, seed, replicate, trace = TRUE) {
  if (!is.data.frame(cell) || nrow(cell) != 1L) {
    stop("A G5 attempt requires exactly one frozen registry cell.", call. = FALSE)
  }
  fixture <- tryCatch(
    mr_g4g5_route_fixture(cell$route_id, cell$information_multiplier, seed),
    error = function(e) e
  )
  if (inherits(fixture, "error")) {
    out <- mr_g5_failure_record(cell, seed, conditionMessage(fixture), "fixture_failed")
    out$replicate <- as.integer(replicate)
    return(mr_g5_validate_record(out))
  }
  fit <- tryCatch(mr_g4g5_route_fit(cell$route_id, fixture$data, se = TRUE), error = function(e) e)
  if (inherits(fit, "error")) {
    out <- mr_g5_failure_record(cell, seed, conditionMessage(fit))
    out$replicate <- as.integer(replicate)
    out <- mr_g4_add_mask_receipt(out, fixture, cell$route_id)
    return(mr_g5_validate_record(out))
  }
  target <- cell[, c("route_id", "parm", "truth", "target_class", "dpar", "scale",
    "profile_ready", "interval_method", "conf.level"), drop = FALSE]
  out <- mr_g4_run_target_manifest(fit, target, replicate = replicate, trace = trace)
  out$information_multiplier <- cell$information_multiplier
  out$information_rung <- cell$information_rung
  out$attempt_seed <- as.integer(seed)
  out$fit_status <- "fit_ok"
  out$fit_converged <- isTRUE(fit$opt$convergence == 0L)
  out$pdHess <- if (!is.null(fit$sdreport$pdHess)) isTRUE(fit$sdreport$pdHess) else NA
  out$interval_usable <- out$g4_interval_usable
  out$truth_contained <- out$g4_truth_contained
  out$boundary_or_clamp <- isTRUE(out$profile.boundary) || identical(out$conf.status, "clamp_limited")
  out <- mr_g4_add_mask_receipt(out, fixture, cell$route_id)
  mr_g5_validate_record(out)
  out
}

mr_g5_validate_campaign <- function(records, registry) {
  if (!is.list(registry) || registry$n_rep != 1200L || is.null(registry$cells) || is.null(registry$seeds)) {
    stop("A G5 campaign requires the frozen 1,200-attempt registry.", call. = FALSE)
  }
  required <- c("route_id", "parm", "information_rung", "replicate", "attempt_seed")
  if (!is.data.frame(records) || !all(required %in% names(records))) {
    stop("G5 campaign records must retain every planned attempt identity.", call. = FALSE)
  }
  expected <- merge(registry$seeds, registry$cells[, c("cell_id", "route_id", "parm", "information_rung")],
    by = "cell_id", sort = FALSE)
  expected_key <- with(expected, paste(route_id, parm, information_rung, replicate, sep = "\r"))
  actual_key <- with(records, paste(route_id, parm, information_rung, replicate, sep = "\r"))
  if (anyDuplicated(actual_key) || !setequal(expected_key, actual_key)) {
    stop("G5 records must retain exactly every planned attempt.", call. = FALSE)
  }
  seed_expected <- expected$seed[match(actual_key, expected_key)]
  if (!identical(as.integer(records$attempt_seed), as.integer(seed_expected))) {
    stop("G5 records must retain the deterministic seed for every planned attempt.", call. = FALSE)
  }
  invisible(records)
}

# Reconcile one or more completed array receipts against the exact frozen
# registry.  A rerun may leave an identical receipt behind; that is harmless,
# whereas two non-identical records for the same deterministic attempt are a
# provenance failure and must stop interpretation.
mr_g5_reconcile_checkpoints <- function(paths, registry) {
  if (!is.character(paths) || !length(paths) || any(!file.exists(paths))) {
    stop("G5 reconciliation requires existing checkpoint files.", call. = FALSE)
  }
  key_columns <- c("route_id", "parm", "information_rung", "replicate")
  records <- lapply(normalizePath(paths), function(path) {
    x <- readRDS(path)
    if (!is.data.frame(x) || !all(key_columns %in% names(x))) {
      stop("Each G5 checkpoint must contain retained attempt identities.", call. = FALSE)
    }
    cell_key <- unique(do.call(paste, c(x[key_columns[1:3]], sep = "\r")))
    expected_key <- do.call(paste, c(registry$cells[key_columns[1:3]], sep = "\r"))
    if (!length(cell_key) || any(!cell_key %in% expected_key)) {
      stop("A G5 checkpoint contains a cell outside the frozen registry.", call. = FALSE)
    }
    cell_ids <- registry$cells$cell_id[match(cell_key, expected_key)]
    local_registry <- registry
    local_registry$cells <- registry$cells[registry$cells$cell_id %in% cell_ids, , drop = FALSE]
    local_registry$seeds <- registry$seeds[registry$seeds$cell_id %in% cell_ids, , drop = FALSE]
    mr_g5_validate_campaign(x, local_registry)
    invisible(lapply(seq_len(nrow(x)), function(i) {
      mr_g5_validate_record(x[i, , drop = FALSE])
    }))
    x$.mr_g5_checkpoint_path <- path
    x
  })
  fields <- Reduce(union, lapply(records, names))
  records <- lapply(records, function(x) {
    for (field in setdiff(fields, names(x))) x[[field]] <- NA
    x[, fields, drop = FALSE]
  })
  all_records <- do.call(rbind, records)
  attempt_key <- do.call(paste, c(all_records[key_columns], sep = "\r"))
  groups <- split(seq_len(nrow(all_records)), attempt_key)
  keep <- vapply(groups, `[[`, integer(1L), 1L)
  sources <- vapply(groups, function(index) {
    rows <- all_records[index, setdiff(names(all_records), ".mr_g5_checkpoint_path"), drop = FALSE]
    identical_rows <- vapply(seq_len(nrow(rows))[-1L], function(i) {
      # Duplicate receipts from separate files have distinct rbind() row
      # names.  Compare the retained evidence, not that incidental label.
      left <- rows[1L, , drop = FALSE]
      right <- rows[i, , drop = FALSE]
      row.names(left) <- NULL
      row.names(right) <- NULL
      identical(left, right)
    }, logical(1L))
    if (length(identical_rows) && !all(identical_rows)) {
      stop("Conflicting G5 checkpoint records share a deterministic attempt.", call. = FALSE)
    }
    paste(sort(unique(all_records$.mr_g5_checkpoint_path[index])), collapse = ";")
  }, character(1L))
  out <- all_records[keep, setdiff(names(all_records), ".mr_g5_checkpoint_path"), drop = FALSE]
  out$checkpoint_paths <- unname(sources[attempt_key[keep]])
  row.names(out) <- NULL
  mr_g5_validate_campaign(out, registry)
  out
}

# Run or resume a planned G5 campaign.  Checkpoints are append-only at the
# attempt level: an unsuccessful fit is retained and never retried in place,
# while an interrupted campaign resumes only genuinely absent attempt keys.
mr_g5_run_campaign <- function(registry, trace = TRUE, checkpoint_path = NULL,
                               runner = mr_g5_run_attempt) {
  if (!is.list(registry) || registry$n_rep != 1200L || is.null(registry$cells) || is.null(registry$seeds)) {
    stop("G5 execution requires the frozen 1,200-attempt registry.", call. = FALSE)
  }
  records <- if (!is.null(checkpoint_path) && file.exists(checkpoint_path)) readRDS(checkpoint_path) else NULL
  required <- c("route_id", "parm", "information_rung", "replicate")
  if (!is.null(records) && (!is.data.frame(records) || !all(required %in% names(records)))) {
    stop("G5 checkpoint must contain retained attempted records.", call. = FALSE)
  }
  key <- function(x) with(x, paste(route_id, parm, information_rung, replicate, sep = "\r"))
  for (i in seq_len(nrow(registry$seeds))) {
    seed_row <- registry$seeds[i, , drop = FALSE]
    cell <- registry$cells[match(seed_row$cell_id, registry$cells$cell_id), , drop = FALSE]
    expected_key <- key(data.frame(route_id = cell$route_id, parm = cell$parm,
      information_rung = cell$information_rung, replicate = seed_row$replicate))
    if (!is.null(records) && expected_key %in% key(records)) next
    next_record <- runner(cell, seed = seed_row$seed, replicate = seed_row$replicate, trace = trace)
    mr_g5_validate_record(next_record)
    records <- if (is.null(records)) next_record else rbind(records, next_record)
    if (!is.null(checkpoint_path)) {
      dir.create(dirname(checkpoint_path), recursive = TRUE, showWarnings = FALSE)
      saveRDS(records, checkpoint_path)
    }
  }
  mr_g5_validate_campaign(records, registry)
  records
}
