# A4.G17: registry-driven scope fence for the fixed-effect-only cohort of
# `engine = "julia"` families.
#
# `drm_julia_family_tag()` admits any family with `fe = TRUE` in
# R/julia-family-registry.R BEFORE it ever checks phylo_only / locscale_phylo
# / slope_phylo / structured -- so for a family with `fe = TRUE` and none of
# those other columns set, an ordinary random-effect bar `(1 | g)` (including
# a random slope) or an `sd()`/`sd_phylo()` scale submodel passed every gate
# on origin/main and reached `drm_julia_setup()` with no receipt (measured:
# `student()`, `lognormal()`, `truncated_nbinom2()`, `zero_one_beta()`, and
# `beta_binomial()`). `drm_julia_refuse_fe_only_random_effects()` closes that
# gap. `phylo()` and `relmat()`/`animal()`/`spatial()` are deliberately NOT
# part of this fence -- both are already refused, upstream of this fence, by
# EXISTING gates (see the fence's own doc comment in R/julia-bridge.R), and
# their pinned messages are tested by name in the per-family test files
# (e.g. test-julia-family-beta_binomial.R); this file does not duplicate
# those assertions, except for one live confirmation below (G4) that a
# `phylo()` term on an fe-only family still refuses SOMEWHERE before Julia,
# just not via this fence's message.
#
# Every family this file tests is discovered from the registry at test time
# (`fe_only_fence_families()`), never a literal vector -- a later fe-only
# admission (cumulative_logit #1174, skew_normal #1176, ...) is picked up
# automatically as long as its response fits the generic continuous-response
# fixture below (`fe_only_fence_fixture()`); a family whose response needs a
# genuinely different encoding (e.g. an ordinal factor -- cumulative_logit,
# handled below via `fe_only_fence_lhs_overrides`) needs one line added there
# or to the fixture builder, and the per-family tests SKIP (rather than fail
# or silently pass) with a clear message if the generic fixture does not
# parse for it, so a future admission cannot make this file falsely green.
# `fe_only_fence_families()` below is an INDEPENDENT re-derivation of the
# registry filter (not a call into the fence's own implementation) -- the
# first test in this file cross-checks it against
# `drmTMB:::drm_julia_fe_only_fence_families()`, the shared helper the fence
# and the gate registry's `family_type` field both use, so a divergence
# between the two independent readings of the registry fails loudly instead
# of both silently agreeing on a stale cohort.
#
# `engine\\s*=\\s*\"tmb\"` messages carry the fence's own registry-driven
# `message_pattern` (R/julia-bridge.R `drm_julia_intentional_gates()`, row
# `fe_only_random_effects`); that pattern must survive cli's 80-column
# message wrap (a literal space between the closing backtick of `` `fe` ``
# and `(fixed-effect)` becomes a newline for the four longest family names --
# see the comment beside the pattern itself), so `expect_fe_only_fence()`
# below asserts it against BOTH an unwrapped message
# (`cli.condition_width = Inf`) and a wrapped one (`= 80`).
#
# Zero Julia throughout: every assertion here runs with DRM_JL_PATH unset.

fe_only_fence_families <- function() {
  reg <- drmTMB:::drm_julia_family_registry()
  fams <- vapply(reg, function(row) {
    if (!isTRUE(row$fe)) {
      return(NA_character_)
    }
    if (
      isTRUE(row$phylo_only) || isTRUE(row$locscale_phylo) ||
        isTRUE(row$slope_phylo) || isTRUE(row$structured)
    ) {
      return(NA_character_)
    }
    if (startsWith(row$family, "biv_")) {
      return(NA_character_)
    }
    row$family
  }, character(1L))
  fams[!is.na(fams)]
}

# The one place a family's RESPONSE ENCODING (not its dpar set) needs a
# manual override: everything else uses a single generic continuous `y`
# column, which the fence does not care about (it fires on formula
# structure alone, before any data-content check -- verified below with
# garbage `y` values for every family, matching the leaf's "build a call the
# way a working native fit would" discipline in spirit while not requiring
# response values that actually recover the family's parameters).
fe_only_fence_lhs_overrides <- c(
  beta_binomial = "cbind(s, f)",
  cumulative_logit = "y"
)

fe_only_fence_fixture <- function(family_name, n = 40L) {
  set.seed(20260905L)
  g <- factor(rep(seq_len(8), each = n / 8L))
  x <- stats::rnorm(n)
  z <- stats::rnorm(n)
  dat <- data.frame(x = x, z = z, g = g)
  lhs <- unname(fe_only_fence_lhs_overrides[family_name])
  if (is.na(lhs)) {
    dat$y <- stats::rnorm(n)
    lhs <- "y"
  } else if (identical(family_name, "beta_binomial")) {
    trials <- sample(8:20, n, replace = TRUE)
    successes <- sample(0:5, n, replace = TRUE)
    dat$s <- pmin(successes, trials)
    dat$f <- trials - dat$s
  } else if (identical(family_name, "cumulative_logit")) {
    # Ordered-factor response (R/family.R cumulative_logit()): the fence
    # fires on formula STRUCTURE alone, before any response-content check,
    # so a garbage draw (not fitted to real cutpoints, like the generic `y`
    # every other family gets) is enough -- see the header comment.
    dat$y <- ordered(
      sample(c("low", "medium", "high"), n, replace = TRUE),
      levels = c("low", "medium", "high")
    )
  }
  list(data = dat, lhs = lhs)
}

# Build a `bf()` call for `family_name` where `bar_dpar` (if supplied) carries
# an ordinary `(1 | g)` on top of `bar_covariate`, and every other dpar is a
# plain intercept. Returns NULL (skip signal) if the family's dpars are not
# known to `family_name()` or the fixture does not apply to it.
fe_only_fence_formula_args <- function(family_name, fixture, bar_dpar = NULL,
                                        bar_covariate = "x", add_sd_term = FALSE) {
  fam_obj <- tryCatch(get(family_name, mode = "function")(), error = function(e) NULL)
  if (is.null(fam_obj) || is.null(fam_obj$dpars)) {
    return(NULL)
  }
  dpars <- fam_obj$dpars
  args <- vector("list", length(dpars))
  names(args) <- dpars
  for (dpar in dpars) {
    if (identical(dpar, "mu")) {
      rhs <- if (identical(dpar, bar_dpar)) {
        sprintf("%s + (1 | g)", bar_covariate)
      } else {
        bar_covariate
      }
      args[["mu"]] <- stats::as.formula(sprintf("%s ~ %s", fixture$lhs, rhs))
    } else if (identical(dpar, bar_dpar)) {
      args[[dpar]] <- stats::as.formula(
        sprintf("~ %s + (1 | g)", bar_covariate)
      )
    } else {
      args[[dpar]] <- ~1
    }
  }
  if (isTRUE(add_sd_term)) {
    args[["sd(g)"]] <- ~1
  }
  args
}

fe_only_fence_second_dpar <- function(family_name) {
  fam_obj <- get(family_name, mode = "function")()
  dpars <- fam_obj$dpars
  if (length(dpars) < 2L) {
    return(NA_character_)
  }
  dpars[[2L]]
}

# Shared assertion: `make_call` (a zero-argument thunk, NOT a bare
# expression -- it must run twice, once per cli wrap width below) must abort
# with the fence's own message, matching the gate registry row
# `fe_only_random_effects` (G5), and naming the family and the offending
# term. Checked against BOTH an unwrapped message (`cli.condition_width =
# Inf`) and cli's real 80-column wrap (`= 80`), because the pattern must
# survive both -- see the header comment on why this matters.
expect_fe_only_fence <- function(make_call, family_name, term_regex) {
  gates <- drmTMB:::drm_julia_intentional_gates()
  gate <- gates[gates$gate_id == "fe_only_random_effects", ]
  expect_equal(nrow(gate), 1L)
  pattern <- gate$message_pattern[[1L]]

  check_one <- function(width) {
    withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
    withr::local_options(cli.condition_width = width)
    err <- tryCatch({
      force(make_call())
      NULL
    }, error = function(e) e)
    expect_false(
      is.null(err),
      info = sprintf("%s (width=%s): expected an error, got none", family_name, width)
    )
    if (is.null(err)) {
      return(invisible(NULL))
    }
    msg <- conditionMessage(err)
    expect_match(msg, pattern, info = msg)
    expect_match(msg, family_name, fixed = TRUE, info = msg)
    expect_match(msg, term_regex, info = msg)
    expect_match(msg, "engine\\s*=\\s*\"tmb\"", info = msg)
    invisible(err)
  }

  check_one(Inf)
  check_one(80)
}

test_that("fe-only, non-exempt family set is non-empty and matches the fence's own cohort helper", {
  cohort <- fe_only_fence_families()
  expect_gt(length(cohort), 0L)
  expect_setequal(cohort, drmTMB:::drm_julia_fe_only_fence_families())
})

for (fam in fe_only_fence_families()) {
  local({
    family_name <- fam
    fixture <- fe_only_fence_fixture(family_name)
    fam_obj <- get(family_name, mode = "function")()
    second_dpar <- fe_only_fence_second_dpar(family_name)

    test_that(sprintf(
      "%s: an ordinary mean-side (1 | g) refuses with the fe-only fence",
      family_name
    ), {
      args <- fe_only_fence_formula_args(family_name, fixture, bar_dpar = "mu")
      if (is.null(args)) {
        skip(sprintf("no generic fixture for %s yet", family_name))
      }
      formula <- do.call(bf, args)
      expect_fe_only_fence(
        function() drmTMB(formula, family = fam_obj, data = fixture$data, engine = "julia"),
        family_name,
        "`mu`"
      )
    })

    test_that(sprintf(
      "%s: an ordinary %s-side (1 | g) refuses with the fe-only fence",
      family_name, second_dpar
    ), {
      if (is.na(second_dpar)) {
        skip(sprintf("%s has no second dpar", family_name))
      }
      args <- fe_only_fence_formula_args(family_name, fixture, bar_dpar = second_dpar)
      if (is.null(args)) {
        skip(sprintf("no generic fixture for %s yet", family_name))
      }
      formula <- do.call(bf, args)
      expect_fe_only_fence(
        function() drmTMB(formula, family = fam_obj, data = fixture$data, engine = "julia"),
        family_name,
        sprintf("`%s`", second_dpar)
      )
    })
  })
}

test_that("student(): a random slope (1 + x | g) also refuses with the fe-only fence", {
  fixture <- fe_only_fence_fixture("student")
  args <- fe_only_fence_formula_args("student", fixture, bar_dpar = NULL)
  args[["mu"]] <- stats::as.formula(sprintf("%s ~ x + (1 + x | g)", fixture$lhs))
  formula <- do.call(bf, args)
  expect_fe_only_fence(
    function() drmTMB(formula, family = student(), data = fixture$data, engine = "julia"),
    "student",
    "`mu`"
  )
})

test_that("student(): an sd(g) scale submodel refuses with the fe-only fence", {
  fixture <- fe_only_fence_fixture("student")
  args <- fe_only_fence_formula_args(
    "student", fixture,
    bar_dpar = NULL, add_sd_term = TRUE
  )
  formula <- do.call(bf, args)
  expect_fe_only_fence(
    function() drmTMB(formula, family = student(), data = fixture$data, engine = "julia"),
    "student",
    "sd\\(\\)"
  )
})

test_that("student(): a phylo() term on an fe-only family still refuses before Julia (existing gate, not this fence)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  skip_if_not_installed("ape")
  n <- 60L
  set.seed(1)
  x <- stats::rnorm(n)
  tr <- ape::rcoal(10)
  tr$tip.label <- paste0("s", seq_len(10))
  sp <- factor(paste0("s", rep(seq_len(10), each = 6)))
  dat <- data.frame(y = stats::rt(n, df = 5) + 0.3 * x, x = x, sp = sp)
  err <- tryCatch({
    drmTMB(
      bf(y ~ x + phylo(1 | sp, tree = tr), sigma ~ 1),
      family = student(), data = dat, engine = "julia"
    )
    NULL
  }, error = function(e) e)
  expect_false(is.null(err))
  msg <- conditionMessage(err)
  # The EXISTING drm_julia_phylo_payload() family allowlist fires here, not
  # the new fence -- the fence deliberately does not check phylo() (see the
  # header comment above and the doc comment on
  # drm_julia_refuse_fe_only_random_effects() in R/julia-bridge.R).
  expect_match(msg, "can marshal `phylo\\(\\)` only for")
  gates <- drmTMB:::drm_julia_intentional_gates()
  fence_pattern <- gates$message_pattern[gates$gate_id == "fe_only_random_effects"]
  expect_false(grepl(fence_pattern, msg))
})

# ---- G4: positive controls -- the fence must not fire for these ----------

test_that("gaussian(): an ordinary mean-side (1 | g) is untouched by the fence (reaches Julia setup)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  n <- 40L
  g <- factor(rep(seq_len(8), each = 5))
  x <- stats::rnorm(n)
  dat <- data.frame(y = stats::rnorm(n, mean = 0.3 * x), x = x, g = g)
  err <- tryCatch({
    drmTMB(bf(y ~ x + (1 | g), sigma ~ 1), family = gaussian(), data = dat, engine = "julia")
    NULL
  }, error = function(e) e)
  expect_false(is.null(err))
  msg <- conditionMessage(err)
  expect_match(msg, "needs a local DRM.jl checkout", fixed = TRUE)
  gates <- drmTMB:::drm_julia_intentional_gates()
  fence_pattern <- gates$message_pattern[gates$gate_id == "fe_only_random_effects"]
  expect_false(grepl(fence_pattern, msg))
})

test_that("poisson(): phylo(1 | sp) is untouched by the fence (reaches Julia setup)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  skip_if_not_installed("ape")
  n <- 60L
  set.seed(2)
  x <- stats::rnorm(n)
  tr <- ape::rcoal(10)
  tr$tip.label <- paste0("s", seq_len(10))
  sp <- factor(paste0("s", rep(seq_len(10), each = 6)))
  dat <- data.frame(y = stats::rpois(n, exp(0.2 + 0.3 * x)), x = x, sp = sp)
  err <- tryCatch({
    drmTMB(bf(y ~ x + phylo(1 | sp, tree = tr)), family = poisson(), data = dat, engine = "julia")
    NULL
  }, error = function(e) e)
  expect_false(is.null(err))
  msg <- conditionMessage(err)
  expect_match(msg, "needs a local DRM.jl checkout", fixed = TRUE)
  gates <- drmTMB:::drm_julia_intentional_gates()
  fence_pattern <- gates$message_pattern[gates$gate_id == "fe_only_random_effects"]
  expect_false(grepl(fence_pattern, msg))
})

test_that("biv_gaussian(): an invalid partial phylo term is untouched by the fence (its own q2/q4 gate fires)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  skip_if_not_installed("ape")
  n <- 60L
  set.seed(3)
  x <- stats::rnorm(n)
  tr <- ape::rcoal(10)
  tr$tip.label <- paste0("s", seq_len(10))
  sp <- factor(paste0("s", rep(seq_len(10), each = 6)))
  dat <- data.frame(
    y1 = stats::rnorm(n, 0.2 + 0.3 * x), y2 = stats::rnorm(n, -0.1 + 0.2 * x),
    x = x, sp = sp
  )
  err <- tryCatch({
    drmTMB(
      bf(
        mu1 = y1 ~ x + phylo(1 | sp, tree = tr), mu2 = y2 ~ x,
        sigma1 = ~1, sigma2 = ~1, rho12 = ~1
      ),
      family = biv_gaussian(), data = dat, engine = "julia"
    )
    NULL
  }, error = function(e) e)
  expect_false(is.null(err))
  msg <- conditionMessage(err)
  expect_match(msg, "requires either q2.*mu1/mu2|q4 all-four-axis")
  gates <- drmTMB:::drm_julia_intentional_gates()
  fence_pattern <- gates$message_pattern[gates$gate_id == "fe_only_random_effects"]
  expect_false(grepl(fence_pattern, msg))
})

test_that("gaussian(): sigma ~ phylo(1 | sp) is untouched by the fence (reaches Julia setup)", {
  withr::local_envvar(DRM_JL_PATH = NA, DRM_JL_PHYLO_PATH = NA)
  skip_if_not_installed("ape")
  n <- 60L
  set.seed(4)
  x <- stats::rnorm(n)
  tr <- ape::rcoal(10)
  tr$tip.label <- paste0("s", seq_len(10))
  sp <- factor(paste0("s", rep(seq_len(10), each = 6)))
  dat <- data.frame(y = stats::rnorm(n, 0.2 + 0.3 * x), x = x, sp = sp)
  err <- tryCatch({
    drmTMB(
      bf(y ~ x, sigma ~ phylo(1 | sp, tree = tr)),
      family = gaussian(), data = dat, engine = "julia"
    )
    NULL
  }, error = function(e) e)
  expect_false(is.null(err))
  msg <- conditionMessage(err)
  expect_match(msg, "needs a local DRM.jl checkout", fixed = TRUE)
  gates <- drmTMB:::drm_julia_intentional_gates()
  fence_pattern <- gates$message_pattern[gates$gate_id == "fe_only_random_effects"]
  expect_false(grepl(fence_pattern, msg))
})
