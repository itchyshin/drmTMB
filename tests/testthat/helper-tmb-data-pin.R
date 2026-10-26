# Helpers for tests/testthat/test-tmb-data-pin.R (issue #1329).
#
# `make_tmb_data_core()` returns the data list handed to the TMB template. The
# pin test compares that list, field by field, against an RDS snapshot taken
# from the hand-written 17-copy implementation, so a refactor of the builder
# cannot silently change a field name, type or value.

# One small model per `model_type` branch, plus variants that switch on the
# conditional fields (random effects, correlated blocks, phylogeny, known
# sampling variances, Gaussian aggregation).
tmb_data_pin_cases <- function() {
  withr::with_seed(1329L, tmb_data_pin_cases_seeded())
}

tmb_data_pin_cases_seeded <- function() {
  n <- 24L
  dat <- data.frame(
    x = stats::rnorm(n),
    z = stats::rnorm(n),
    w = stats::rnorm(n),
    id = factor(rep(seq_len(6L), each = 4L))
  )
  dat$hab <- factor(rep(c("forest", "reef", "grass"), length.out = n))
  dat$eff <- factor(rep(c("low", "high"), each = 3L, length.out = n))
  dat$w_id <- rep(stats::rnorm(6L), each = 4L)
  dat$y_gauss <- stats::rnorm(n)
  dat$y_pos <- stats::rgamma(n, shape = 2, rate = 2)
  dat$y_unit <- stats::rbeta(n, 2, 3)
  dat$y_zoi <- dat$y_unit
  dat$y_zoi[c(1L, 5L)] <- 0
  dat$y_zoi[c(2L, 9L)] <- 1
  dat$y_tw <- dat$y_pos
  dat$y_tw[c(3L, 8L, 14L)] <- 0
  dat$count <- stats::rpois(n, 3)
  dat$count[c(1L, 6L, 11L)] <- 0L
  dat$count_pos <- pmax(dat$count, 1L)
  dat$succ <- stats::rbinom(n, 5L, 0.4)
  dat$fail <- 5L - dat$succ
  dat$ord <- factor(
    rep(c("a", "b", "c"), length.out = n),
    levels = c("a", "b", "c"),
    ordered = TRUE
  )
  dat$y1 <- stats::rnorm(n)
  dat$y2 <- stats::rnorm(n)
  dat$y1_pos <- stats::rgamma(n, 2, 2)
  dat$y2_pos <- stats::rgamma(n, 2, 2)
  tree <- ape::rcoal(6L, tip.label = paste0("sp", seq_len(6L)))
  dat$species <- factor(rep(tree$tip.label, each = 4L), levels = tree$tip.label)

  case <- function(formula, family, model_type, control = NULL) {
    list(
      formula = formula,
      family = family,
      model_type = model_type,
      control = control
    )
  }
  biv_formula <- function(y1, y2, mu_rhs = "x", nu = FALSE) {
    args <- list(
      mu1 = stats::as.formula(paste(y1, "~", mu_rhs)),
      mu2 = stats::as.formula(paste(y2, "~", mu_rhs)),
      sigma1 = ~ 1,
      sigma2 = ~ 1,
      rho12 = ~ 1
    )
    if (nu) args$nu <- ~ 1
    do.call(bf, args)
  }

  list(
    data = dat,
    cases = list(
      gaussian = case(bf(y_gauss ~ x, sigma ~ z), gaussian(), "gaussian"),
      gaussian_re = case(
        bf(y_gauss ~ x + (1 | id), sigma ~ z + (1 | id)),
        gaussian(),
        "gaussian"
      ),
      gaussian_corr_re = case(
        bf(y_gauss ~ x + (1 | p | id), sigma ~ z + (1 | p | id)),
        gaussian(),
        "gaussian"
      ),
      gaussian_re_scale = case(
        bf(y_gauss ~ x + (1 | id), sigma ~ z, sd(id) ~ w_id),
        gaussian(),
        "gaussian"
      ),
      gaussian_meta_V = case(
        bf(y_gauss ~ x + meta_V(V = rep(0.1, n)), sigma ~ 1),
        gaussian(),
        "gaussian"
      ),
      gaussian_phylo = case(
        bf(y_gauss ~ x + phylo(1 | species, tree = tree), sigma ~ z),
        gaussian(),
        "gaussian"
      ),
      gaussian_aggregated = case(
        bf(y_gauss ~ hab, sigma ~ eff),
        gaussian(),
        "gaussian",
        drm_control(aggregate_gaussian = TRUE)
      ),
      student = case(
        bf(y_gauss ~ x, sigma ~ z, nu ~ 1),
        student(),
        "student"
      ),
      student_re = case(
        bf(y_gauss ~ x + (1 | id), sigma ~ z, nu ~ 1),
        student(),
        "student"
      ),
      skew_normal = case(
        bf(y_gauss ~ x, sigma ~ z),
        skew_normal(),
        "skew_normal"
      ),
      lognormal = case(bf(y_pos ~ x, sigma ~ z), lognormal(), "lognormal"),
      gamma = case(bf(y_pos ~ x, sigma ~ z), Gamma(link = "log"), "gamma"),
      tweedie = case(bf(y_tw ~ x, sigma ~ z, nu ~ 1), tweedie(), "tweedie"),
      beta = case(bf(y_unit ~ x, sigma ~ z), beta_family(), "beta"),
      beta_re = case(
        bf(y_unit ~ x + (1 | id), sigma ~ z),
        beta_family(),
        "beta"
      ),
      zero_one_beta = case(
        bf(y_zoi ~ x, sigma ~ z),
        zero_one_beta(),
        "zero_one_beta"
      ),
      zero_one_beta_re = case(
        bf(y_zoi ~ x + (1 | id), sigma ~ z),
        zero_one_beta(),
        "zero_one_beta"
      ),
      beta_binomial = case(
        bf(cbind(succ, fail) ~ x, sigma ~ z),
        beta_binomial(),
        "beta_binomial"
      ),
      binomial = case(bf(cbind(succ, fail) ~ x), binomial(), "binomial"),
      binomial_re = case(
        bf(cbind(succ, fail) ~ x + (1 | id)),
        binomial(),
        "binomial"
      ),
      cumulative_logit = case(
        bf(ord ~ x),
        cumulative_logit(),
        "cumulative_logit"
      ),
      poisson = case(bf(count ~ x), poisson(), "poisson"),
      poisson_phylo = case(
        bf(count ~ x + phylo(1 | species, tree = tree)),
        poisson(),
        "poisson"
      ),
      zi_poisson = case(
        bf(count ~ x, zi ~ z),
        poisson(),
        "zi_poisson"
      ),
      nbinom2 = case(bf(count ~ x, sigma ~ z), nbinom2(), "nbinom2"),
      nbinom2_re = case(
        bf(count ~ x + (1 | id), sigma ~ z),
        nbinom2(),
        "nbinom2"
      ),
      zi_nbinom2 = case(
        bf(count ~ x, sigma ~ z, zi ~ w),
        nbinom2(),
        "zi_nbinom2"
      ),
      truncated_nbinom2 = case(
        bf(count_pos ~ x, sigma ~ z),
        truncated_nbinom2(),
        "truncated_nbinom2"
      ),
      hurdle_nbinom2 = case(
        bf(count ~ x, sigma ~ z, hu ~ w),
        truncated_nbinom2(),
        "hurdle_nbinom2"
      ),
      biv_gaussian = case(
        biv_formula("y1", "y2"),
        biv_gaussian(),
        "biv_gaussian"
      ),
      biv_gaussian_re = case(
        biv_formula("y1", "y2", mu_rhs = "x + (1 | p | id)"),
        biv_gaussian(),
        "biv_gaussian"
      ),
      biv_lognormal = case(
        biv_formula("y1_pos", "y2_pos"),
        biv_lognormal(),
        "biv_lognormal"
      ),
      biv_student = case(
        biv_formula("y1", "y2", nu = TRUE),
        biv_student(),
        "biv_student"
      )
    )
  )
}

# Run one drmTMB() call up to the point where the TMB data list is built for
# the case's `model_type`, keep the list `make_tmb_data_core()` returns, and
# abort before any optimisation. (The bivariate lognormal and Student builders
# first build a bivariate Gaussian spec, so the builder can be called more
# than once per fit.)
capture_tmb_data_core <- function(case, data) {
  core <- get("make_tmb_data_core", envir = asNamespace("drmTMB"))
  captured <- NULL
  stopper <- structure(
    class = c("tmb_data_pin_stop", "condition"),
    list(message = "tmb data captured", call = NULL)
  )
  testthat::local_mocked_bindings(
    make_tmb_data_core = function(spec) {
      out <- core(spec)
      if (identical(spec$model_type, case$model_type)) {
        captured <<- out
        stop(stopper)
      }
      out
    },
    .package = "drmTMB"
  )
  args <- list(case$formula, family = case$family, data = data)
  if (!is.null(case$control)) args$control <- case$control
  tryCatch(
    do.call(drmTMB, args),
    tmb_data_pin_stop = function(cnd) NULL
  )
  captured
}
