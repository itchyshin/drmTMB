# DG3 power-arm family registry (Curie, 2026-07-12). Sourced after
# harness.R; requires devtools::load_all(".") (or a loaded drmTMB) so
# drmTMB()/bf()/family constructors/drm_control()/residuals() are in scope.
#
# Each entry conforms to dg3_run_family()'s spec contract (harness.R):
#   name, n, arm_a = list(dgp, fit, response), mis_specs = list(list(
#     name, dgp, fit_true (or NULL), fit_wrong, response)).
#
# DGPs are lifted directly from the validated DG2/DG3 smoke tests in
# tests/testthat/test-family-dpq-batch{A,B,C,D}.R and test-adequacy.R (same
# true-parameter values, same link functions) so this file introduces no new
# unverified DGP algebra -- only new MIS-SPECIFIED fits layered on top of
# already-proven true-DGP constructions.
#
# Mis-spec pairing follows verification-spec.md's Arm B table. Where the
# table's literal pairing is not implementable with the CURRENT drmTMB
# surface (e.g. no map/fixed-parameter control to force a wrong tweedie
# power; beta()/beta-support families cannot accept an exact atom without
# erroring), a documented, defensible substitute is used and flagged
# "[SUBSTITUTE]" in the mis-spec name/comment -- never silently swapped.

fast_control <- drm_control(se = FALSE)

# ============================================================================
# 1. gaussian (continuous, no atom) -- REPRESENTATIVE FAMILY (mandated set)
# ============================================================================
dg3_spec_gaussian <- list(
  name = "gaussian",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      data.frame(y = 0.3 + 0.6 * x + stats::rnorm(n), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "heteroscedastic_location_only",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        sigma_true <- exp(0.1 + 0.9 * x)
        data.frame(y = 0.3 + 0.6 * x + stats::rnorm(n, sd = sigma_true), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x), family = gaussian(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "heavy_tailed_wrong_family",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        data.frame(y = 0.4 + 0.6 * x + 1.1 * stats::rt(n, df = 3), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 2. poisson (discrete, no atom) -- REPRESENTATIVE FAMILY (mandated set)
# ============================================================================
dg3_spec_poisson <- list(
  name = "poisson",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.5 + 0.3 * x)
      data.frame(y = stats::rpois(n, mu_true), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x), family = poisson(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "overdispersion_wrong_family",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.3 * x)
        sigma_true <- 0.7
        data.frame(y = stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x), family = poisson(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "excess_zeros_ignored",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.25 * x)
        zi_true <- 0.3
        y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, zi ~ 1), family = poisson(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x), family = poisson(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 3. zi_poisson (discrete, atom-at-0 mixture) -- REPRESENTATIVE FAMILY
#    (mandated set: atom/mixture)
# ============================================================================
dg3_spec_zi_poisson <- list(
  name = "zi_poisson",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.4 + 0.25 * x)
      zi_true <- 0.3
      y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
      data.frame(y = y, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, zi ~ 1), family = poisson(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "ignore_zi_fit_plain_poisson",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.25 * x)
        zi_true <- 0.3
        y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, zi ~ 1), family = poisson(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x), family = poisson(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "zi_mechanism_misset_constant_vs_x",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.25 * x)
        zi_true <- stats::plogis(-0.5 + 1.2 * x)
        y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rpois(n, mu_true))
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, zi ~ x), family = poisson(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, zi ~ 1), family = poisson(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 4. student (continuous, no atom)
# ============================================================================
dg3_spec_student <- list(
  name = "student",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      data.frame(y = 0.4 + 0.6 * x + 1.1 * stats::rt(n, df = 6), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "heteroscedastic_location_only",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        sigma_true <- exp(0.1 + 0.7 * x)
        data.frame(y = 0.4 + 0.6 * x + sigma_true * stats::rt(n, df = 8), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x, nu ~ 1), family = student(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [table col 2, worked from student's side]: student truth with SMALL
      # nu (heavy tails); does a gaussian (nu = Inf) fit get flagged?
      name = "gaussian_wrong_family_heavy_tail",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        data.frame(y = 0.4 + 0.6 * x + 1.1 * stats::rt(n, df = 2.5), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = student(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 5. lognormal (continuous, no atom)
# ============================================================================
dg3_spec_lognormal <- list(
  name = "lognormal",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      data.frame(y = stats::rlnorm(n, meanlog = 0.3 + 0.4 * x, sdlog = 0.5), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "dispersion_varying_mean_only",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        sdlog_true <- exp(-1.0 + 0.5 * x)
        data.frame(y = stats::rlnorm(n, meanlog = 0.3 + 0.4 * x, sdlog = sdlog_true), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x), family = lognormal(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "wrong_family_gamma_on_lognormal",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        data.frame(y = stats::rlnorm(n, meanlog = 0.3 + 0.4 * x, sdlog = 0.5), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 6. gamma (continuous, no atom)
# ============================================================================
dg3_spec_gamma <- list(
  name = "gamma",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.4 + 0.3 * x)
      data.frame(y = stats::rgamma(n, shape = 1 / 0.6^2, scale = mu_true * 0.6^2), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "dispersion_varying_mean_only",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.3 * x)
        sigma_true <- exp(-0.5 + 0.6 * x)
        data.frame(y = stats::rgamma(n, shape = 1 / sigma_true^2, scale = mu_true * sigma_true^2), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x), family = Gamma(link = "log"), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "wrong_family_gamma_on_lognormal",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        data.frame(y = stats::rlnorm(n, meanlog = 0.3 + 0.4 * x, sdlog = 0.5), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 7. beta (continuous, no atom, bounded (0,1))
# ============================================================================
dg3_spec_beta <- list(
  name = "beta",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- stats::plogis(0.2 + 0.5 * x)
      phi_true <- 1 / 0.4^2
      data.frame(
        y = stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true),
        x = x
      )
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "dispersion_varying_mean_only",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- stats::plogis(0.2 + 0.5 * x)
        # sigma_true clamped so phi_true = 1/sigma^2 never gets small enough
        # to make both beta shape parameters < ~0.15 -- an unclamped
        # exp(-0.9 + 0.5*x) occasionally produced a near-boundary-hugging
        # (U-shaped) beta at large |x| whose rbeta() draw underflowed to
        # exactly 0/1 on ~20% of seeds; a DGP tuning issue, not a harness or
        # diagnostic finding.
        sigma_true <- pmin(exp(-0.9 + 0.5 * x), 1.0)
        phi_true <- 1 / sigma_true^2
        data.frame(
          y = stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true),
          x = x
        )
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x), family = beta(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [SUBSTITUTE]: the table's "wrong family" column for this row has no
      # safe cross-family partner for beta's bounded (0,1) support inside the
      # package (gamma/lognormal are (0, Inf); zero_one_beta's atoms at
      # {0,1} would make beta()'s density undefined at those exact points,
      # erroring rather than fitting). Substituted with a standard, equally
      # legitimate GAMLSS-diagnostic mis-spec: an omitted quadratic term in
      # the mean's link-scale predictor (worm-plot/QQ literature's classic
      # "omitted nonlinearity" case).
      name = "omitted_nonlinear_mean_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        # mean-centered quadratic (E[x^2] = 1 under x ~ N(0,1)) keeps mu_true
        # away from the 0/1 boundary on average -- an UNcentered 0.9*x^2 term
        # (tried first) pushed mu_true so close to 1 for most of the sample
        # that rbeta() underflowed to exact 1s, erroring beta()'s (0,1)-open
        # support requirement on ~100% of seeds; a DGP bug, not a harness or
        # diagnostic finding. A hard clamp on the tail (rare |x| > ~2.5 still
        # pushed mu_true to ~0.99 with phi_true = 6.25, giving shape2 small
        # enough that rbeta() occasionally underflows to exactly 1) keeps
        # every draw safely interior.
        mu_true <- pmin(pmax(stats::plogis(0.2 + 0.5 * x + 0.5 * (x^2 - 1)), 0.05), 0.95)
        phi_true <- 1 / 0.4^2
        data.frame(
          y = stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true),
          x = x
        )
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x + I(x^2), sigma ~ 1), family = beta(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 8. skew_normal (continuous, no atom)
# ============================================================================
dg3_spec_skew_normal <- list(
  name = "skew_normal",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- 0.5 + 0.4 * x
      data.frame(y = rskew_normal_public(n, mu = mu_true, sigma = 1.1, nu = 3), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "heteroscedastic_location_only",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- 0.5 + 0.4 * x
        sigma_true <- exp(-0.1 + 0.6 * x)
        data.frame(y = rskew_normal_public(n, mu = mu_true, sigma = sigma_true, nu = 3), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x, nu ~ 1), family = skew_normal(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "wrong_family_gaussian_ignoring_skew",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- 0.5 + 0.4 * x
        data.frame(y = rskew_normal_public(n, mu = mu_true, sigma = 1.1, nu = 6), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = skew_normal(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

dg3_registry_core <- list(
  gaussian = dg3_spec_gaussian,
  poisson = dg3_spec_poisson,
  zi_poisson = dg3_spec_zi_poisson
)

dg3_registry_group2 <- list(
  student = dg3_spec_student,
  lognormal = dg3_spec_lognormal,
  gamma = dg3_spec_gamma,
  beta = dg3_spec_beta,
  skew_normal = dg3_spec_skew_normal
)

# ============================================================================
# 9. nbinom2 (discrete, no atom)
# ============================================================================
dg3_spec_nbinom2 <- list(
  name = "nbinom2",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.5 + 0.3 * x)
      sigma_true <- 0.7
      data.frame(y = stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "poisson_ignoring_overdispersion",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.3 * x)
        sigma_true <- 0.7
        data.frame(y = stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x), family = poisson(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "excess_zeros_ignored",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.25 * x)
        sigma_true <- 0.6
        zi_true <- 0.25
        y <- ifelse(
          stats::runif(n) < zi_true, 0L,
          stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true)
        )
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zi ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 10. binomial (discrete, known trials)
# ============================================================================
dg3_spec_binomial <- list(
  name = "binomial",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      trials <- sample(5:20, n, replace = TRUE)
      mu_true <- stats::plogis(-0.2 + 0.6 * x)
      success <- stats::rbinom(n, size = trials, prob = mu_true)
      data.frame(success = success, failure = trials - success, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(cbind(success, failure) ~ x), family = binomial(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      # table's LAST row ("beta_binomial | binomial fit to overdispersed
      # (beta-binomial) DGP -> under-dispersed residuals | --") worked from
      # binomial's side.
      name = "overdispersion_beta_binomial_wrong_family",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        trials <- sample(8:24, n, replace = TRUE)
        mu_true <- stats::plogis(-0.2 + 0.7 * x)
        sigma_true <- 0.5
        phi_true <- 1 / sigma_true^2
        p_true <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
        success <- stats::rbinom(n, size = trials, prob = p_true)
        data.frame(success = success, failure = trials - success, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x, sigma ~ 1), family = beta_binomial(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x), family = binomial(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [SUBSTITUTE]: the table gives binomial only the beta_binomial-row
      # partner above; a second, standard mis-spec (omitted covariate) is
      # added for symmetry with the other families' 2-mis-spec convention.
      name = "omitted_covariate_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        x2 <- stats::rnorm(n)
        trials <- sample(5:20, n, replace = TRUE)
        mu_true <- stats::plogis(-0.2 + 0.6 * x + 0.9 * x2)
        success <- stats::rbinom(n, size = trials, prob = mu_true)
        data.frame(success = success, failure = trials - success, x = x, x2 = x2)
      },
      fit_true = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x + x2), family = binomial(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x), family = binomial(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 11. beta_binomial (discrete, known trials)
# ============================================================================
dg3_spec_beta_binomial <- list(
  name = "beta_binomial",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      trials <- sample(8:24, n, replace = TRUE)
      mu_true <- stats::plogis(-0.2 + 0.7 * x)
      sigma_true <- 0.5
      phi_true <- 1 / sigma_true^2
      p_true <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
      success <- stats::rbinom(n, size = trials, prob = p_true)
      data.frame(success = success, failure = trials - success, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(cbind(success, failure) ~ x, sigma ~ 1), family = beta_binomial(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "binomial_ignoring_overdispersion",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        trials <- sample(8:24, n, replace = TRUE)
        mu_true <- stats::plogis(-0.2 + 0.7 * x)
        sigma_true <- 0.5
        phi_true <- 1 / sigma_true^2
        p_true <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
        success <- stats::rbinom(n, size = trials, prob = p_true)
        data.frame(success = success, failure = trials - success, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x, sigma ~ 1), family = beta_binomial(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x), family = binomial(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [SUBSTITUTE]: table's cell for beta_binomial's 2nd mis-spec is "--"
      # (none named); dispersion_varying_mean_only added for symmetry,
      # matching the gamma/beta/lognormal row's pattern.
      name = "dispersion_varying_mean_only_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        z <- stats::rnorm(n)
        trials <- sample(8:24, n, replace = TRUE)
        mu_true <- stats::plogis(-0.2 + 0.7 * x)
        sigma_true <- pmin(exp(-1.1 + 0.5 * z), 1.0)
        phi_true <- 1 / sigma_true^2
        p_true <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
        success <- stats::rbinom(n, size = trials, prob = p_true)
        data.frame(success = success, failure = trials - success, x = x, z = z)
      },
      fit_true = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x, sigma ~ z), family = beta_binomial(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(cbind(success, failure) ~ x, sigma ~ 1), family = beta_binomial(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 12. cumulative_logit (discrete, ordinal)
# ============================================================================
dg3_ordinal_po_data <- function(seed, n) {
  set.seed(seed)
  dat <- data.frame(x = stats::rnorm(n))
  cutpoints <- c(-0.90, 0.75)
  eta <- 0.85 * dat$x
  p_low <- stats::plogis(cutpoints[1] - eta)
  p_medium <- stats::plogis(cutpoints[2] - eta) - p_low
  prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[2] - eta))
  draw <- vapply(seq_len(n), function(i) sample.int(3L, size = 1L, prob = prob[i, ]), integer(1))
  dat$score <- ordered(c("low", "medium", "high")[draw], levels = c("low", "medium", "high"))
  dat
}

dg3_spec_cumulative_logit <- list(
  name = "cumulative_logit",
  n = 400L,
  arm_a = list(
    dgp = dg3_ordinal_po_data,
    fit = function(dat) {
      drmTMB(bf(score ~ x), family = cumulative_logit(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      # table: "proportional-odds fit to non-PO DGP". cumulative_logit() IS
      # the proportional-odds model -- the package has no non-PO fit to pair
      # as "fit_true", so this mis-spec is SINGLE-ARM: fit_true = NULL, and
      # fit_wrong's rejection rate directly reports power (Arm A above is
      # the type-I reference for the SAME fitting procedure on a genuinely
      # PO-satisfying DGP).
      name = "non_proportional_odds",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        cutpoints <- c(-0.90, 0.75)
        eta1 <- 0.85 * x
        eta2 <- 1.8 * x # different slope at the 2nd cutpoint -> violates PO
        p_low <- stats::plogis(cutpoints[1] - eta1)
        p_up_cum <- stats::plogis(cutpoints[2] - eta2)
        p_up_cum <- pmax(p_up_cum, p_low + 1e-6) # keep the mid-category mass non-negative
        prob <- cbind(p_low, p_up_cum - p_low, 1 - p_up_cum)
        draw <- vapply(seq_len(n), function(i) sample.int(3L, size = 1L, prob = prob[i, ]), integer(1))
        data.frame(x = x, score = ordered(c("low", "medium", "high")[draw], levels = c("low", "medium", "high")))
      },
      fit_true = NULL,
      fit_wrong = function(dat) {
        drmTMB(bf(score ~ x), family = cumulative_logit(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [SUBSTITUTE]: table's "collapse categories" is not a clean residual-
      # diagnostic power case (collapsing to a coarser but still correctly
      # specified ordinal outcome does not, by itself, break the model) --
      # substituted with the standard omitted-covariate mis-spec used
      # elsewhere in this registry.
      name = "omitted_covariate_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        x2 <- stats::rnorm(n)
        cutpoints <- c(-0.90, 0.75)
        eta <- 0.85 * x + 1.1 * x2
        p_low <- stats::plogis(cutpoints[1] - eta)
        p_medium <- stats::plogis(cutpoints[2] - eta) - p_low
        prob <- cbind(p_low, p_medium, 1 - stats::plogis(cutpoints[2] - eta))
        draw <- vapply(seq_len(n), function(i) sample.int(3L, size = 1L, prob = prob[i, ]), integer(1))
        data.frame(x = x, x2 = x2, score = ordered(c("low", "medium", "high")[draw], levels = c("low", "medium", "high")))
      },
      fit_true = function(dat) {
        drmTMB(bf(score ~ x + x2), family = cumulative_logit(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(score ~ x), family = cumulative_logit(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

dg3_registry_group3 <- list(
  nbinom2 = dg3_spec_nbinom2,
  binomial = dg3_spec_binomial,
  beta_binomial = dg3_spec_beta_binomial,
  cumulative_logit = dg3_spec_cumulative_logit
)

# ============================================================================
# 13. zi_nbinom2 (discrete, atom-at-0 mixture)
# ============================================================================
dg3_spec_zi_nbinom2 <- list(
  name = "zi_nbinom2",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.4 + 0.25 * x)
      sigma_true <- 0.6
      zi_true <- 0.25
      y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true))
      data.frame(y = y, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1, zi ~ 1), family = nbinom2(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "ignore_zi_fit_plain_nbinom2",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.25 * x)
        sigma_true <- 0.6
        zi_true <- 0.25
        y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true))
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zi ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "zi_mechanism_misset_constant_vs_x",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.4 + 0.25 * x)
        sigma_true <- 0.6
        zi_true <- stats::plogis(-0.5 + 1.2 * x)
        y <- ifelse(stats::runif(n) < zi_true, 0L, stats::rnbinom(n, size = 1 / sigma_true^2, mu = mu_true))
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zi ~ x), family = nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zi ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 14. truncated_nbinom2 (discrete, zero-truncated, NO zero/hurdle mechanism
#     parameter -- see mis-spec 2's [SUBSTITUTE] note)
# ============================================================================
dg3_spec_truncated_nbinom2 <- list(
  name = "truncated_nbinom2",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.5 + 0.25 * x)
      sigma_true <- 0.6
      p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
      u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
      y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
      data.frame(y = y, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1), family = truncated_nbinom2(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      # table: "fit non-mixture base to the mixture DGP" reinterpreted for a
      # support-restriction (not a mixture-weight) family: fit the UNtruncated
      # nbinom2, which allows y = 0, a value that never occurs in the
      # truncated data -- the wrong-support analogue of "ignoring the atom".
      name = "ignore_truncation_fit_plain_nbinom2",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.25 * x)
        sigma_true <- 0.6
        p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
        u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
        y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = truncated_nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [SUBSTITUTE]: truncated_nbinom2 has NO zero/hurdle-mechanism
      # parameter (truncation is a fixed structural constraint, not a
      # mixture weight), so the table's "constant vs x-dependent mechanism"
      # cell does not apply; substituted with the mean-only-vs-dispersion-
      # varying pattern used for gamma/beta/lognormal.
      name = "dispersion_varying_mean_only_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.25 * x)
        sigma_true <- pmin(exp(-0.6 + 0.5 * x), 1.0)
        p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
        u_true <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
        y <- stats::qnbinom(u_true, size = 1 / sigma_true^2, mu = mu_true)
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x), family = truncated_nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = truncated_nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 15. hurdle_nbinom2 (discrete, atom-at-0 hurdle mixture)
# ============================================================================
dg3_spec_hurdle_nbinom2 <- list(
  name = "hurdle_nbinom2",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.5 + 0.25 * x)
      sigma_true <- 0.6
      hu_true <- 0.3
      p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
      pos_u <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
      pos_y <- stats::qnbinom(pos_u, size = 1 / sigma_true^2, mu = mu_true)
      y <- ifelse(stats::runif(n) < hu_true, 0L, pos_y)
      data.frame(y = y, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1, hu ~ 1), family = truncated_nbinom2(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      name = "ignore_hurdle_fit_plain_nbinom2",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.25 * x)
        sigma_true <- 0.6
        hu_true <- 0.3
        p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
        pos_u <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
        pos_y <- stats::qnbinom(pos_u, size = 1 / sigma_true^2, mu = mu_true)
        y <- ifelse(stats::runif(n) < hu_true, 0L, pos_y)
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, hu ~ 1), family = truncated_nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1), family = nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "hurdle_mechanism_misset_constant_vs_x",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.25 * x)
        sigma_true <- 0.6
        hu_true <- stats::plogis(-0.5 + 1.2 * x)
        p0_true <- stats::dnbinom(0, size = 1 / sigma_true^2, mu = mu_true)
        pos_u <- p0_true + pmax(stats::runif(n), 1e-10) * (1 - p0_true)
        pos_y <- stats::qnbinom(pos_u, size = 1 / sigma_true^2, mu = mu_true)
        y <- ifelse(stats::runif(n) < hu_true, 0L, pos_y)
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, hu ~ x), family = truncated_nbinom2(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, hu ~ 1), family = truncated_nbinom2(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 16. tweedie (continuous, atom at 0)
# ============================================================================
dg3_spec_tweedie <- list(
  name = "tweedie",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- exp(0.5 + 0.3 * x)
      data.frame(y = rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5), x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      # [SUBSTITUTE]: "ignore the atom (fit interior-only)" is implemented as
      # a documented, standard practitioner move -- substitute exact zeros
      # with a small positive epsilon, then fit a strictly-positive
      # continuous family (Gamma) that cannot accept y = 0 at all.
      name = "ignore_atom_epsilon_substituted_gamma_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.3 * x)
        data.frame(y = rtweedie_compound(n, mu = mu_true, phi = 0.9^2, power = 1.5), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        dat_eps <- dat
        dat_eps$y[dat_eps$y == 0] <- 1e-3
        drmTMB(bf(y ~ x, sigma ~ 1), family = Gamma(link = "log"), data = dat_eps, control = fast_control)
      },
      response = NULL
    ),
    list(
      # [SUBSTITUTE]: the table's "wrong power parameter" cell cannot be
      # implemented -- drm_control() has no map/fixed-parameter contract yet
      # to force an incorrect nu at fit time (drm_control()'s own docs: "a
      # different... future... fixed-parameter... controls will use explicit
      # arguments after their contract is implemented"). Substituted with the
      # mean-only-vs-dispersion-varying pattern (sigma, i.e. phi, mis-spec).
      name = "dispersion_varying_mean_only_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- exp(0.5 + 0.3 * x)
        phi_true <- exp(-1.0 + 0.6 * x)
        data.frame(y = rtweedie_compound(n, mu = mu_true, phi = phi_true, power = 1.5), x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ x, nu ~ 1), family = tweedie(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, nu ~ 1), family = tweedie(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

# ============================================================================
# 17. zero_one_beta (continuous, atoms at 0 AND 1)
# ============================================================================
dg3_spec_zero_one_beta <- list(
  name = "zero_one_beta",
  n = 400L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu_true <- stats::plogis(0.2 + 0.4 * x)
      sigma_true <- 0.5
      zoi_true <- 0.3
      coi_true <- 0.4
      phi_true <- 1 / sigma_true^2
      boundary <- stats::runif(n) < zoi_true
      one <- stats::runif(n) < coi_true
      interior <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
      y <- ifelse(boundary, as.numeric(one), interior)
      data.frame(y = y, x = x)
    },
    fit = function(dat) {
      drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = dat, control = fast_control)
    },
    response = NULL
  ),
  mis_specs = list(
    list(
      # [SUBSTITUTE]: same epsilon-substitution idea as tweedie's mis-spec 1
      # (beta()'s density is undefined at exact 0/1, so a literal
      # "interior-only" refit on unmodified data errors rather than fits).
      name = "ignore_atoms_epsilon_substituted_beta_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- stats::plogis(0.2 + 0.4 * x)
        sigma_true <- 0.5
        zoi_true <- 0.3
        coi_true <- 0.4
        phi_true <- 1 / sigma_true^2
        boundary <- stats::runif(n) < zoi_true
        one <- stats::runif(n) < coi_true
        interior <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
        y <- ifelse(boundary, as.numeric(one), interior)
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        dat_eps <- dat
        dat_eps$y[dat_eps$y == 0] <- 1e-4
        dat_eps$y[dat_eps$y == 1] <- 1 - 1e-4
        drmTMB(bf(y ~ x, sigma ~ 1), family = beta(), data = dat_eps, control = fast_control)
      },
      response = NULL
    ),
    list(
      name = "zoi_mechanism_misset_constant_vs_x",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu_true <- stats::plogis(0.2 + 0.4 * x)
        sigma_true <- 0.5
        zoi_true <- stats::plogis(-0.5 + 1.0 * x)
        coi_true <- 0.4
        phi_true <- 1 / sigma_true^2
        boundary <- stats::runif(n) < zoi_true
        one <- stats::runif(n) < coi_true
        interior <- stats::rbeta(n, shape1 = mu_true * phi_true, shape2 = (1 - mu_true) * phi_true)
        y <- ifelse(boundary, as.numeric(one), interior)
        data.frame(y = y, x = x)
      },
      fit_true = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ x, coi ~ 1), family = zero_one_beta(), data = dat, control = fast_control)
      },
      fit_wrong = function(dat) {
        drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1), family = zero_one_beta(), data = dat, control = fast_control)
      },
      response = NULL
    )
  )
)

dg3_registry_group4 <- list(
  zi_nbinom2 = dg3_spec_zi_nbinom2,
  truncated_nbinom2 = dg3_spec_truncated_nbinom2,
  hurdle_nbinom2 = dg3_spec_hurdle_nbinom2,
  tweedie = dg3_spec_tweedie,
  zero_one_beta = dg3_spec_zero_one_beta
)

# ============================================================================
# 18. biv_gaussian (bivariate; response = 1 marginal only in this toy pass --
#     response = 2 is symmetric future work, not run here)
# ============================================================================
dg3_spec_biv_gaussian <- list(
  name = "biv_gaussian",
  n = 300L,
  arm_a = list(
    dgp = function(seed, n) {
      set.seed(seed)
      x <- stats::rnorm(n)
      mu1 <- 0.4 + 0.6 * x
      mu2 <- -0.2 + 0.3 * x
      sigma1 <- 0.8
      sigma2 <- 1.1
      rho12 <- 0.35
      e1 <- stats::rnorm(n)
      e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
      data.frame(y1 = mu1 + sigma1 * e1, y2 = mu2 + sigma2 * e2, x = x)
    },
    fit = function(dat) {
      drmTMB(
        bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
        family = biv_gaussian(), data = dat, control = fast_control
      )
    },
    response = 1L
  ),
  mis_specs = list(
    list(
      name = "heteroscedastic_location_only_response1",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        mu1 <- 0.4 + 0.6 * x
        mu2 <- -0.2 + 0.3 * x
        sigma1_true <- exp(-0.1 + 0.7 * x)
        sigma2 <- 1.1
        rho12 <- 0.35
        e1 <- stats::rnorm(n)
        e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
        data.frame(y1 = mu1 + sigma1_true * e1, y2 = mu2 + sigma2 * e2, x = x)
      },
      fit_true = function(dat) {
        drmTMB(
          bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~x, sigma2 = ~1, rho12 = ~1),
          family = biv_gaussian(), data = dat, control = fast_control
        )
      },
      fit_wrong = function(dat) {
        drmTMB(
          bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
          family = biv_gaussian(), data = dat, control = fast_control
        )
      },
      response = 1L
    ),
    list(
      # [SUBSTITUTE]: no second bivariate family exists in the package to
      # supply a "wrong family" cross-fit; substituted with an omitted-
      # covariate mis-spec in mu1.
      name = "omitted_covariate_response1_SUBSTITUTE",
      dgp = function(seed, n) {
        set.seed(seed)
        x <- stats::rnorm(n)
        x2 <- stats::rnorm(n)
        mu1 <- 0.4 + 0.6 * x + 0.9 * x2
        mu2 <- -0.2 + 0.3 * x
        sigma1 <- 0.8
        sigma2 <- 1.1
        rho12 <- 0.35
        e1 <- stats::rnorm(n)
        e2 <- rho12 * e1 + sqrt(1 - rho12^2) * stats::rnorm(n)
        data.frame(y1 = mu1 + sigma1 * e1, y2 = mu2 + sigma2 * e2, x = x, x2 = x2)
      },
      fit_true = function(dat) {
        drmTMB(
          bf(mu1 = y1 ~ x + x2, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
          family = biv_gaussian(), data = dat, control = fast_control
        )
      },
      fit_wrong = function(dat) {
        drmTMB(
          bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1, sigma2 = ~1, rho12 = ~1),
          family = biv_gaussian(), data = dat, control = fast_control
        )
      },
      response = 1L
    )
  )
)

dg3_registry_group5 <- list(
  biv_gaussian = dg3_spec_biv_gaussian
)

dg3_registry_all <- c(
  dg3_registry_core, dg3_registry_group2, dg3_registry_group3,
  dg3_registry_group4, dg3_registry_group5
)
