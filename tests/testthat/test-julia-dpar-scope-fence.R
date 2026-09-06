# #1224 -- THE DPAR-SCOPE FENCE, and the death of the `biv_` PREFIX EXEMPTION.
#
# WHAT WENT WRONG. The A4.G17 fixed-effect-only fence exempted bivariate
# families by testing their NAME: `startsWith(row$family, "biv_")`. The
# exemption itself is real -- `biv_gaussian` legitimately fits predictor-driven
# `sigma1`/`sigma2`/`rho12` cells -- but a name prefix is not a capability, so
# every later `biv_*` admission inherited it without earning it, and the
# failure was SILENT: the bridge fitted a shape `engine = "tmb"` refuses,
# converged, and returned plausible numbers. Two families hit this
# independently within one hour on 2026-09-05 (`biv_student` #1217:
# `sigma1 = ~ z` fit at logLik -466.43141436; `biv_lognormal` #1216:
# `sigma1 = ~ x` fit at -71.4056477), and each was closed by its OWN
# hand-written refusal function.
#
# AND IT WAS NEVER ABOUT BIVARIATE-NESS. Measuring the neighbours while
# building this fence found a third instance on a family with no `biv_` prefix
# at all: `tweedie()` `nu ~ z` FIT through `engine = "julia"` at logLik
# -259.84074955 (drmTMB 2fcbb0fbf, DRM.jl aee371cc9, n = 200, seed 20260905)
# while `engine = "tmb"` REFUSED it with "`tweedie()` currently supports only
# intercept-only `nu ~ 1`". `nu ~ 1` still fit (-260.40627451), so the fence
# below must narrow the first without touching the second.
#
# THE INVARIANT THIS FILE HOLDS. For every family on the Julia registry, any
# `dpar ~ <predictor>` shape outside the family's DECLARED `predictor_dpars`
# is refused on the Julia route BEFORE Julia starts. Zero Julia throughout:
# every assertion runs with DRM_JL_PATH unset.

registry_rows <- function() drmTMB:::drm_julia_family_registry()

# A registry row built the way `spec()` builds one, for the mocked-registry
# red controls below. Deliberately NOT a copy of `spec()`: these rows are
# fabricated test data, and a shared constructor would hide a `spec()` change.
fake_row <- function(family, predictor_dpars, fe = TRUE, phylo_only = FALSE,
                     locscale_phylo = FALSE, slope_phylo = FALSE,
                     dispersionless = FALSE, structured = FALSE,
                     fe_fence_exempt = FALSE, drmjl_tag = family) {
  list(family = family, fe = fe, phylo_only = phylo_only,
       locscale_phylo = locscale_phylo, slope_phylo = slope_phylo,
       dispersionless = dispersionless, structured = structured,
       predictor_dpars = predictor_dpars, fe_fence_exempt = fe_fence_exempt,
       drmjl_tag = drmjl_tag)
}

with_extra_registry_rows <- function(rows, code) {
  base <- registry_rows()
  # Scoped to THIS frame (local_mocked_bindings' default), so the mock is undone
  # when the helper returns and two calls in one `test_that()` cannot stack.
  # `base` is read before the mock is installed, so nesting stays honest.
  testthat::local_mocked_bindings(
    drm_julia_family_registry = function() c(base, rows),
    .package = "drmTMB"
  )
  force(code)
}

# ---------------------------------------------------------------------------
# 1. The prefix is GONE, and the cohort it used to compute is UNCHANGED.
# ---------------------------------------------------------------------------

test_that("the fe-only cohort helper no longer keys its exemption on a name prefix", {
  src <- paste(
    deparse(body(drmTMB:::drm_julia_fe_only_fence_families)),
    collapse = " "
  )
  # The literal defect: an exemption granted by string prefix.
  expect_false(grepl("startsWith(row$family", src, fixed = TRUE))
  expect_true(grepl("fe_fence_exempt", src, fixed = TRUE))
})

test_that("replacing the prefix with a declared column changes NO family's cohort membership", {
  # Pinned verbatim against the cohort the prefix test produced on this
  # branch's base (drmTMB 2fcbb0fbf), so the refactor is provably behaviour
  # preserving rather than merely plausible.
  expect_identical(
    drmTMB:::drm_julia_fe_only_fence_families(),
    c("student", "lognormal", "truncated_nbinom2", "zero_one_beta",
      "tweedie", "beta_binomial", "cumulative_logit", "skew_normal")
  )
  exempt <- vapply(registry_rows(), function(row) {
    if (isTRUE(row$fe_fence_exempt)) row$family else NA_character_
  }, character(1L))
  expect_identical(unname(exempt[!is.na(exempt)]), "biv_gaussian")
})

test_that("RED CONTROL: a new bivariate family no longer inherits the fe-only exemption by name", {
  # The throwaway family the brief asks for. Under the OLD prefix rule this
  # row would have been exempt purely because of the four characters `biv_`.
  with_extra_registry_rows(
    list(fake_row("biv_throwaway", predictor_dpars = c("mu1", "mu2"))),
    {
      expect_true("biv_throwaway" %in% drmTMB:::drm_julia_fe_only_fence_families())
      # ... while the family that EARNED the exemption still holds it.
      expect_false("biv_gaussian" %in% drmTMB:::drm_julia_fe_only_fence_families())
    }
  )
})

# ---------------------------------------------------------------------------
# 2. Registry invariants: the declaration is mandatory and well formed.
# ---------------------------------------------------------------------------

test_that("every registry row declares a well-formed predictor_dpars", {
  expect_identical(drmTMB:::drm_julia_family_registry_problems(), character(0L))
  for (row in registry_rows()) {
    expect_true(is.character(row$predictor_dpars), info = row$family)
    expect_gt(length(row$predictor_dpars), 0L)
    expect_true(all(nzchar(row$predictor_dpars)), info = row$family)
  }
})

test_that("RED CONTROL: a two-response family may not declare predictor_dpars = \"*\"", {
  # `biv_lognormal` is a real two-response `drm_family` with NO registry row on
  # this branch's base, which makes it the exact shape of the defect: the next
  # bivariate admission. Declaring `"*"` is the lazy row a copy-paste produces.
  with_extra_registry_rows(
    list(fake_row("biv_lognormal", predictor_dpars = "*")),
    {
      problems <- drmTMB:::drm_julia_family_registry_problems()
      expect_length(problems, 1L)
      expect_match(problems, "biv_lognormal", fixed = TRUE)
      expect_match(problems, "2-response family may not declare", fixed = TRUE)
    }
  )
  # The same row declared honestly is accepted -- the check discriminates.
  with_extra_registry_rows(
    list(fake_row("biv_lognormal", predictor_dpars = c("mu1", "mu2"))),
    expect_identical(drmTMB:::drm_julia_family_registry_problems(), character(0L))
  )
})

test_that("RED CONTROL: a declaration naming a dpar the family does not have is flagged", {
  with_extra_registry_rows(
    list(fake_row("biv_lognormal", predictor_dpars = c("mu1", "mu2", "kappa"))),
    {
      problems <- drmTMB:::drm_julia_family_registry_problems()
      expect_length(problems, 1L)
      expect_match(problems, "kappa", fixed = TRUE)
    }
  )
})

test_that("RED CONTROL: a malformed declaration is flagged", {
  with_extra_registry_rows(
    list(fake_row("biv_lognormal", predictor_dpars = character(0L))),
    expect_match(
      drmTMB:::drm_julia_family_registry_problems(),
      "non-empty character vector", fixed = TRUE
    )
  )
  with_extra_registry_rows(
    list(fake_row("biv_lognormal", predictor_dpars = c("*", "mu1"))),
    expect_match(
      drmTMB:::drm_julia_family_registry_problems(),
      "cannot be mixed", fixed = TRUE
    )
  )
})

# ---------------------------------------------------------------------------
# 3. The guard, over EVERY admitted family -- not the two someone measured.
# ---------------------------------------------------------------------------

# Build a `drm_formula` for `family` in which exactly `dpar` carries `rhs_text`
# and every other dpar of the family is a plain intercept.
scope_formula <- function(family, dpar, rhs_text) {
  fam_obj <- drmTMB:::drm_julia_registry_family_object(family)
  dpars <- fam_obj$dpars
  args <- vector("list", length(dpars))
  names(args) <- dpars
  for (d in dpars) {
    rhs <- if (identical(d, dpar)) rhs_text else "1"
    args[[d]] <- if (d %in% c("mu", "mu1")) {
      stats::as.formula(sprintf("y ~ %s", rhs))
    } else if (identical(d, "mu2")) {
      stats::as.formula(sprintf("y2 ~ %s", rhs))
    } else {
      stats::as.formula(sprintf("~ %s", rhs))
    }
  }
  do.call(drm_formula, unname_mu(args))
}

# `drm_formula()` takes the location formula positionally and the rest by name.
unname_mu <- function(args) {
  loc <- intersect(c("mu", "mu1"), names(args))[[1L]]
  c(args[loc], args[setdiff(names(args), loc)])
}

fence <- function(formula, family) {
  drmTMB:::drm_julia_refuse_unadmitted_predictor_dpars(formula, family)
}

test_that("EVERY registry family: each dpar outside its declaration is refused with a predictor", {
  checked <- 0L
  for (row in registry_rows()) {
    fam_obj <- drmTMB:::drm_julia_registry_family_object(row$family)
    if (is.null(fam_obj) || is.null(fam_obj$dpars)) {
      next
    }
    if (identical(row$predictor_dpars, "*")) {
      # An unfenced family must stay unfenced: no dpar of it is refused.
      for (d in fam_obj$dpars) {
        expect_silent(fence(scope_formula(row$family, d, "z"), row$family))
      }
      next
    }
    for (d in setdiff(fam_obj$dpars, row$predictor_dpars)) {
      checked <- checked + 1L
      expect_error(
        fence(scope_formula(row$family, d, "z"), row$family),
        "every other distributional parameter must be intercept-only",
        info = sprintf("%s / %s", row$family, d)
      )
      # ... and the SAME dpar, intercept-only, is admitted. Without this the
      # test above would pass just as well on a fence that refused everything.
      expect_silent(fence(scope_formula(row$family, d, "1"), row$family))
      expect_silent(fence(scope_formula(row$family, d, "(1)"), row$family))
    }
    for (d in intersect(fam_obj$dpars, row$predictor_dpars)) {
      expect_silent(fence(scope_formula(row$family, d, "z"), row$family))
    }
  }
  # An empty result set is not a pass: at least one narrowed cell must exist.
  expect_gt(checked, 0L)
})

test_that("tweedie: nu is fenced, mu and sigma are not, and `~ 0 + z` counts as a predictor", {
  expect_error(fence(scope_formula("tweedie", "nu", "z"), "tweedie"),
               "Non-intercept formula on \"nu\"")
  expect_error(fence(scope_formula("tweedie", "nu", "0 + z"), "tweedie"),
               "Non-intercept formula on \"nu\"")
  expect_silent(fence(scope_formula("tweedie", "sigma", "z"), "tweedie"))
  expect_silent(fence(scope_formula("tweedie", "mu", "z"), "tweedie"))
})

test_that("biv_gaussian keeps every predictor cell it earned", {
  for (d in c("mu1", "mu2", "sigma1", "sigma2", "rho12")) {
    expect_silent(fence(scope_formula("biv_gaussian", d, "z"), "biv_gaussian"))
  }
})

test_that("a family with no registry row is not fenced by this function", {
  expect_null(drmTMB:::drm_julia_family_predictor_dpars("biv_lognormal"))
  expect_silent(fence(
    drm_formula(y ~ x, sigma1 = ~ z), "biv_lognormal"
  ))
})

test_that("RED CONTROL: a throwaway bivariate admission is caught by the guard", {
  # Admitting a family is one registry row. Under the prefix rule that row
  # silently opened `sigma1 ~ z`; under the declared rule it does not.
  with_extra_registry_rows(
    list(fake_row("biv_lognormal", predictor_dpars = c("mu1", "mu2"))),
    {
      expect_error(
        fence(scope_formula("biv_lognormal", "sigma1", "x"), "biv_lognormal"),
        "Non-intercept formula on \"sigma1\""
      )
      expect_error(
        fence(scope_formula("biv_lognormal", "rho12", "x"), "biv_lognormal"),
        "Non-intercept formula on \"rho12\""
      )
      expect_silent(fence(scope_formula("biv_lognormal", "sigma1", "1"),
                          "biv_lognormal"))
      expect_silent(fence(scope_formula("biv_lognormal", "mu1", "x"),
                          "biv_lognormal"))
    }
  )
})

# ---------------------------------------------------------------------------
# 4. End to end: the refusal happens BEFORE Julia starts.
# ---------------------------------------------------------------------------

test_that("tweedie nu ~ z is refused through drmTMB(engine = \"julia\") with no engine configured", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  set.seed(20260905L)
  n <- 60L
  dat <- data.frame(
    y = stats::rgamma(n, shape = 2, rate = 1),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  err <- tryCatch(
    drmTMB(bf(y ~ x, sigma ~ 1, nu ~ z), family = tweedie(),
           data = dat, engine = "julia"),
    error = function(e) e
  )
  expect_s3_class(err, "error")
  msg <- paste(conditionMessage(err), collapse = " ")
  expect_match(msg, "intercept-only", fixed = TRUE, info = msg)
  expect_match(msg, "nu", info = msg)
  # DRM_JL_PATH is unset, so reaching Julia would have produced a setup error
  # instead. That it did not is the "before Julia starts" claim.
  expect_false(grepl("DRM_JL_PATH", msg, fixed = TRUE), info = msg)
})

test_that("the native engine refuses the SAME tweedie cell -- the two engines agree", {
  set.seed(20260905L)
  n <- 60L
  dat <- data.frame(
    y = stats::rgamma(n, shape = 2, rate = 1),
    x = stats::rnorm(n),
    z = stats::rnorm(n)
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1, nu ~ z), family = tweedie(),
           data = dat, engine = "tmb"),
    "intercept-only"
  )
})
