# Regression for drmTMB#1716: foreign zero-inflated / hurdle stats families
# (notably glmmTMB::ziGamma()) must be refused, not silently routed to plain
# Gamma(log) or another non-inflation family. The guard lives on
# drm_eval_family_arg(), the family entry point shared by drmTMB(),
# impute_model(), and drm_resolve_priors().

eval_family <- function(expr) {
  drmTMB:::drm_eval_family_arg(substitute(expr), parent.frame())
}

hand_built_zigamma <- function() {
  foreign <- stats::Gamma(link = "log")
  foreign$family <- "ziGamma"
  foreign
}

hand_built_ziformula_gamma <- function() {
  foreign <- stats::Gamma(link = "log")
  foreign$initialize <- expression({
    if (exists("ziformula") && !identical(ziformula, ~0)) NULL
  })
  foreign
}

fix_1716_data <- function() {
  set.seed(1716)
  data.frame(
    y = stats::rgamma(40, shape = 2, scale = 1),
    x = stats::rnorm(40)
  )
}

test_that("hand-built ziGamma stats family is refused with a clear error (#1716)", {
  foreign <- hand_built_zigamma()
  expect_error(
    eval_family(foreign),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("hand-built Gamma family with ziformula initialize is refused (#1716)", {
  foreign <- hand_built_ziformula_gamma()
  expect_error(
    eval_family(foreign),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("the family entry point refuses the silent Gamma misfit; drm_family_type is unwrapped (#1716)", {
  foreign <- hand_built_ziformula_gamma()
  expect_error(
    eval_family(foreign),
    class = "drmTMB_foreign_inflation_family"
  )
  # Path-proof for Code Reviewer item 1: drm_family_type() itself is not
  # rebound. The classifier still sees a log-link Gamma family. The guard
  # is drm_eval_family_arg(), so R/drmTMB.R stays off the C17 watchlist.
  expect_identical(drmTMB:::drm_family_type(foreign), "gamma")
})

test_that("plain Gamma(link = 'log') and drmTMB constructors are unchanged (#1716)", {
  expect_identical(drmTMB:::drm_family_type(stats::Gamma(link = "log")), "gamma")
  expect_identical(drmTMB:::drm_family_type(beta_family()), "beta")
  expect_identical(drmTMB:::drm_family_type(lognormal()), "lognormal")
  g <- stats::Gamma(link = "log")
  expect_identical(eval_family(g), g)
  expect_identical(eval_family(beta_family()), beta_family())
})

test_that("glmmTMB::ziGamma(link = 'log') is refused, not fitted as plain Gamma (#1716)", {
  skip_if_not_installed("glmmTMB")
  d <- fix_1716_data()
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = glmmTMB::ziGamma(link = "log"),
      data = d
    ),
    class = "drmTMB_foreign_inflation_family"
  )
  err <- expect_error(
    eval_family(glmmTMB::ziGamma(link = "log")),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_match(conditionMessage(err), "glmmTMB::ziGamma", fixed = TRUE)
})

test_that("zipf is not treated as a zero-inflated family name (#1716)", {
  expect_null(drmTMB:::drm_foreign_inflation_family_kind("zipf"))
  expect_identical(drmTMB:::drm_foreign_inflation_family_kind("ziGamma"), "zero-inflated")
})

test_that("glmmTMB beta_family and lognormal are refused without a zero-inflated label (#1716)", {
  skip_if_not_installed("glmmTMB")
  err <- expect_error(
    eval_family(glmmTMB::beta_family()),
    class = "drmTMB_foreign_inflation_family"
  )
  msg <- conditionMessage(err)
  expect_false(grepl("zero-inflat", msg, ignore.case = TRUE))
  expect_match(msg, "beta_family")
  expect_false(grepl("glmmTMB::beta\\(\\)", msg))
  expect_match(msg, "drmTMB::beta_family")

  err2 <- expect_error(
    eval_family(glmmTMB::lognormal()),
    class = "drmTMB_foreign_inflation_family"
  )
  msg2 <- conditionMessage(err2)
  expect_false(grepl("zero-inflat", msg2, ignore.case = TRUE))
  expect_match(msg2, "lognormal")
  expect_match(msg2, "drmTMB::lognormal")
})

test_that("drm_stats_family_source_package ignores base, stats, and R_GlobalEnv (#1716)", {
  g <- stats::Gamma(link = "log")
  expect_null(drmTMB:::drm_stats_family_source_package(g))

  g_base <- g
  g_base$variance <- base::identity
  expect_null(drmTMB:::drm_stats_family_source_package(g_base))

  had_binding <- exists(".drm_1716_var", envir = .GlobalEnv, inherits = FALSE)
  old <- if (had_binding) {
    get(".drm_1716_var", envir = .GlobalEnv, inherits = FALSE)
  } else {
    NULL
  }
  on.exit({
    if (had_binding) {
      assign(".drm_1716_var", old, envir = .GlobalEnv)
    } else if (exists(".drm_1716_var", envir = .GlobalEnv, inherits = FALSE)) {
      rm(".drm_1716_var", envir = .GlobalEnv)
    }
  }, add = TRUE)
  assign(".drm_1716_var", function(mu) mu^2, envir = .GlobalEnv)
  g_global <- g
  g_global$variance <- get(".drm_1716_var", envir = .GlobalEnv)
  expect_null(drmTMB:::drm_stats_family_source_package(g_global))
})

test_that("hand-built foreign family label names the source package (#1716)", {
  foreign <- hand_built_zigamma()
  foreign$variance <- utils::head
  expect_identical(drmTMB:::drm_stats_family_source_package(foreign), "utils")
  err <- expect_error(
    eval_family(foreign),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_match(conditionMessage(err), "utils::ziGamma")
})

test_that("string family names cannot silently become Gamma (#1716)", {
  d <- fix_1716_data()
  expect_error(
    eval_family("ziGamma"),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    eval_family("truncated_nbinom1"),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    eval_family("hurdlePoisson"),
    class = "drmTMB_foreign_inflation_family"
  )
  # drmTMB never coerces a family *name* to stats::Gamma(), so "Gamma"
  # cannot take the silent-misfit branch that a family *object* can.
  # There is no supported-families condition class in R/family.R (the
  # later abort lives in drm_family_type() without a class), so this
  # test only asserts the entry point does not treat "Gamma" as foreign.
  expect_identical(eval_family("Gamma"), "Gamma")
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = "ziGamma", data = d),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("uncalled family functions cannot silently become Gamma (#1716)", {
  d <- fix_1716_data()
  ziGamma <- function(link = "log") stats::Gamma(link = link)
  expect_error(
    eval_family(ziGamma),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = ziGamma, data = d),
    class = "drmTMB_foreign_inflation_family"
  )
  # Unlike glm(), drmTMB does not call family constructors. stats::Gamma
  # therefore never becomes Gamma(link = "log") and cannot silently fit.
  # No supported-families condition class exists in R/family.R, so this
  # test only asserts the entry point leaves the uncalled function intact.
  expect_true(is.function(eval_family(stats::Gamma)))
})

test_that("list and composed family routes refuse a foreign inflation family (#1716)", {
  d <- fix_1716_data()
  foreign <- hand_built_ziformula_gamma()
  expect_error(
    eval_family(list(foreign, stats::gaussian())),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    eval_family(c(foreign, stats::gaussian())),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    drmTMB(
      bf(y ~ x, sigma ~ 1),
      family = list(foreign, stats::gaussian()),
      data = d
    ),
    class = "drmTMB_foreign_inflation_family"
  )
  expect_error(
    biv_associate(
      bf(y ~ x, sigma ~ 1),
      bf(y ~ x),
      family = list(foreign, stats::gaussian()),
      data = d
    ),
    class = "drmTMB_foreign_inflation_family"
  )
})

test_that("string and uncalled truncated_nbinom2 hint to call drmTMB::truncated_nbinom2 (#1716)", {
  d <- fix_1716_data()
  err <- expect_error(
    eval_family("truncated_nbinom2"),
    class = "drmTMB_family_constructor_call"
  )
  expect_match(conditionMessage(err), "drmTMB::truncated_nbinom2", fixed = TRUE)
  expect_false(inherits(err, "drmTMB_foreign_inflation_family"))
  err_fn <- expect_error(
    eval_family(truncated_nbinom2),
    class = "drmTMB_family_constructor_call"
  )
  expect_match(conditionMessage(err_fn), "drmTMB::truncated_nbinom2", fixed = TRUE)
  expect_false(inherits(err_fn, "drmTMB_foreign_inflation_family"))
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = "truncated_nbinom2", data = d),
    class = "drmTMB_family_constructor_call"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = truncated_nbinom2, data = d),
    class = "drmTMB_family_constructor_call"
  )
})

test_that("string and uncalled lognormal hint to call drmTMB::lognormal (#1716)", {
  d <- fix_1716_data()
  err <- expect_error(
    eval_family("lognormal"),
    class = "drmTMB_family_constructor_call"
  )
  expect_match(conditionMessage(err), "drmTMB::lognormal", fixed = TRUE)
  expect_false(inherits(err, "drmTMB_foreign_inflation_family"))
  err_fn <- expect_error(
    eval_family(lognormal),
    class = "drmTMB_family_constructor_call"
  )
  expect_match(conditionMessage(err_fn), "drmTMB::lognormal", fixed = TRUE)
  expect_false(inherits(err_fn, "drmTMB_foreign_inflation_family"))
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = "lognormal", data = d),
    class = "drmTMB_family_constructor_call"
  )
  expect_error(
    drmTMB(bf(y ~ x, sigma ~ 1), family = lognormal, data = d),
    class = "drmTMB_family_constructor_call"
  )
})

test_that("impute_model refuses a foreign Gamma inflation family (#1716)", {
  foreign <- hand_built_ziformula_gamma()
  expect_error(
    impute_model(x ~ z, family = foreign),
    class = "drmTMB_foreign_inflation_family"
  )
})
