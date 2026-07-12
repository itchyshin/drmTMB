# P4a anti-drift lock for the missing-data capability gates.
#
# Every response family_type that is NOT yet validated for a missing-data mode
# must LOUDLY reject (a family-specific cli_abort), so the capability matrix
# cannot silently drift as P1/P3 validate families one slice at a time. This
# test asserts observed BEHAVIOUR (does the fit reject?), not the gate's own
# allow-list constant, so it is an independent oracle: loosening a gate without
# the full implementation, or vice versa, breaks this test.
#
# When P1 validates a response family (e.g. binomial), MOVE it from the reject
# set to `response_validated` here IN THE SAME COMMIT that loosens the R gate.
# Same for P3 and `predictor_validated`.
#
# Gates under test (R/drmTMB.R), kept in sync with the SSOT helpers
# drm_missing_response_families() / drm_missing_predictor_families():
#   response  = "include" -> drm_missing_response_families()
#   predictor = "model"   -> drm_missing_predictor_families()
# The `impute` family gate is redundant with the predictor gate for reject
# cases (predictor="model" with a non-validated family hits the predictor gate
# first), so it is exercised through the predictor axis.

response_validated <- c(
  "gaussian", "biv_gaussian", "student", "skew_normal", "lognormal", "gamma",
  "tweedie", "binomial", "poisson", "nbinom2", "beta", "zero_one_beta"
)
predictor_validated <- c("gaussian", "poisson", "binomial", "nbinom2", "beta")

# One response family object per family_type a user can pass, with a y valid
# enough to reach the policy gate (the gate fires before family y-validation).
cap_family_cases <- function() {
  n <- 30L
  z <- seq_len(n) / n
  base <- function(y) data.frame(y = y, x = rnorm(n), z = z)
  list(
    gaussian          = list(fam = gaussian(),               data = base(rnorm(n))),
    gamma             = list(fam = Gamma(link = "log"),      data = base(rgamma(n, 2, 1))),
    poisson           = list(fam = poisson(link = "log"),    data = base(rpois(n, 3))),
    binomial          = list(fam = binomial(link = "logit"), data = base(rbinom(n, 1, 0.5))),
    nbinom2           = list(fam = nbinom2(),                data = base(rnbinom(n, mu = 3, size = 2))),
    tweedie           = list(fam = tweedie(),                data = base(pmax(0, rnorm(n, 2)))),
    truncated_nbinom2 = list(fam = truncated_nbinom2(),      data = base(1L + rpois(n, 3))),
    beta              = list(fam = beta(),                   data = base(plogis(rnorm(n)))),
    zero_one_beta     = list(fam = zero_one_beta(),          data = base(plogis(rnorm(n)))),
    beta_binomial     = list(fam = beta_binomial(),          data = base(rbinom(n, 1, 0.5))),
    cumulative_logit  = list(fam = cumulative_logit(),
                             data = base(factor(sample(1:3, n, TRUE), ordered = TRUE))),
    student           = list(fam = student(),                data = base(rnorm(n))),
    skew_normal       = list(fam = skew_normal(),            data = base(rnorm(n))),
    lognormal         = list(fam = lognormal(),              data = base(rlnorm(n)))
  )
}

test_that("every non-validated response family loudly rejects miss_control(response = \"include\")", {
  set.seed(1)
  cases <- cap_family_cases()
  for (ft in names(cases)) {
    if (ft %in% response_validated) next
    cs <- cases[[ft]]
    expect_error(
      drmTMB(
        bf(y ~ x),
        family = cs$fam,
        data = cs$data,
        missing = miss_control(response = "include")
      ),
      regexp = "not implemented for the",
      info = sprintf("family_type = %s", ft)
    )
  }
})

test_that("every non-validated response family loudly rejects miss_control(predictor = \"model\")", {
  set.seed(1)
  cases <- cap_family_cases()
  for (ft in names(cases)) {
    if (ft %in% predictor_validated) next
    cs <- cases[[ft]]
    expect_error(
      drmTMB(
        bf(y ~ x),
        family = cs$fam,
        data = cs$data,
        missing = miss_control(predictor = "model")
      ),
      regexp = "models are currently validated only",
      info = sprintf("family_type = %s", ft)
    )
  }
})

test_that("supplying `impute` with a non-validated response family loudly rejects", {
  set.seed(1)
  cases <- cap_family_cases()
  # Use response families that remain OUTSIDE drm_missing_predictor_families();
  # as P3 validates a family (beta/nbinom2/binomial are now validated) it must
  # move out of this reject set, mirroring predictor_validated above.
  for (ft in c("gamma", "tweedie", "lognormal")) {
    cs <- cases[[ft]]
    # predictor="model" + impute on a non-validated response hits the predictor
    # capability gate first; either way it must reject loudly, never proceed.
    expect_error(
      drmTMB(
        bf(y ~ x),
        family = cs$fam,
        data = cs$data,
        missing = miss_control(predictor = "model"),
        impute = list(x = x ~ z)
      ),
      regexp = "is not implemented for the",
      info = sprintf("family_type = %s", ft)
    )
  }
})

test_that("the abort names the offending family (family-specific message)", {
  set.seed(1)
  cases <- cap_family_cases()
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = cases$beta_binomial$fam,
      data = cases$beta_binomial$data,
      missing = miss_control(response = "include")
    ),
    regexp = "beta_binomial",
    fixed = TRUE
  )
})

# Positive controls: the gates must not OVER-reject the validated families.
test_that("validated families pass the capability gate", {
  set.seed(1)
  cases <- cap_family_cases()

  # gaussian passes the response gate (complete data -> ordinary fit, no gate abort).
  expect_no_error(
    drmTMB(
      bf(y ~ x),
      family = cases$gaussian$fam,
      data = cases$gaussian$data,
      missing = miss_control(response = "include")
    )
  )

  # poisson passes the predictor capability gate: it reaches the mi()-setup
  # check (needs exactly one mi() term) rather than the family reject gate.
  expect_error(
    drmTMB(
      bf(y ~ x),
      family = cases$poisson$fam,
      data = cases$poisson$data,
      missing = miss_control(predictor = "model")
    ),
    regexp = "mi\\(\\)"
  )
})
