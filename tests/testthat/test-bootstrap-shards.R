# Issue #861 (owner decision 18): internal retained-bootstrap shards and an
# internal reducer. Acceptance criteria from the issue: deterministic replay,
# fail-closed joins, a combined ledger equal to a single run under a fixed
# partition, and explicit retained/failed denominators.

new_shard_fit <- function(seed = 20261016) {
  set.seed(seed)
  x <- stats::rnorm(30)
  dat <- data.frame(y = 0.2 + 0.5 * x + stats::rnorm(30, sd = 0.7), x = x)
  drmTMB(bf(y ~ x, sigma ~ 1), family = gaussian(), data = dat)
}

test_that("a bootstrap shard replays deterministically and keeps every attempt", {
  fit <- new_shard_fit()
  set.seed(1)
  before <- get(".Random.seed", envir = globalenv())
  a <- drm_bootstrap_shard(fit, parm = c("fixef:mu:x", "sigma"), indices = 1:3, seed = 11)
  expect_identical(get(".Random.seed", envir = globalenv()), before)
  b <- drm_bootstrap_shard(fit, parm = c("fixef:mu:x", "sigma"), indices = 1:3, seed = 11)
  expect_s3_class(a, "drm_bootstrap_shard")
  expect_identical(a$attempts, b$attempts)
  expect_identical(nrow(a$attempts), 6L)
  expect_identical(sort(unique(a$attempts$bootstrap)), 1:3)
  expect_true(all(a$attempts$replicate_seed == 11L))
  expect_true(all(c("refit_status", "refit_message", "estimate") %in% names(a$attempts)))
  expect_identical(a$header$schema_version, 1L)
})

test_that("combining a fixed partition equals one shard over all replicates", {
  fit <- new_shard_fit()
  whole <- drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = 1:4, seed = 5)
  left <- drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = c(1L, 3L), seed = 5)
  right <- drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = c(4L, 2L), seed = 5)
  combined <- drm_bootstrap_combine(right, left)
  expect_identical(combined$attempts, whole$attempts)
  expect_identical(combined$indices, whole$indices)
  expect_identical(drm_bootstrap_ledger(combined), drm_bootstrap_ledger(whole))
})

test_that("incompatible or overlapping shards fail closed", {
  fit <- new_shard_fit()
  other <- new_shard_fit(seed = 99)
  a <- drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = 1:2, seed = 5)
  expect_error(
    drm_bootstrap_combine(a, drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = 2:3, seed = 5)),
    class = "drmTMB_bootstrap_shard_overlap"
  )
  expect_error(
    drm_bootstrap_combine(a, drm_bootstrap_shard(other, parm = "fixef:mu:x", indices = 3:4, seed = 5)),
    class = "drmTMB_bootstrap_shard_incompatible"
  )
  expect_error(
    drm_bootstrap_combine(a, drm_bootstrap_shard(fit, parm = "sigma", indices = 3:4, seed = 5)),
    class = "drmTMB_bootstrap_shard_incompatible"
  )
  expect_error(
    drm_bootstrap_combine(a, drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = 3:4, seed = 6)),
    class = "drmTMB_bootstrap_shard_incompatible"
  )
  schema <- a
  schema$header$schema_version <- 2L
  expect_error(
    drm_bootstrap_combine(a, schema),
    class = "drmTMB_bootstrap_shard_incompatible"
  )
  expect_error(drm_bootstrap_combine(a, list()), class = "drmTMB_bootstrap_shard_incompatible")
})

test_that("failed refits stay in the ledger with explicit denominators", {
  fit <- new_shard_fit()
  starved <- drm_control(
    se = FALSE,
    keep_tmb_object = FALSE,
    newton_polish = FALSE,
    optimizer = list(iter.max = 1, eval.max = 2)
  )
  shard <- suppressWarnings(drm_bootstrap_shard(
    fit,
    parm = "fixef:mu:x",
    indices = 1:3,
    seed = 3,
    refit_control = starved
  ))
  ledger <- drm_bootstrap_ledger(shard)
  expect_identical(ledger$attempted, 3L)
  expect_identical(
    ledger$usable + ledger$refit_error + ledger$refit_nonconverged + ledger$target_missing,
    3L
  )
  expect_gt(ledger$refit_error + ledger$refit_nonconverged, 0L)
  expect_identical(nrow(shard$attempts), 3L)
})

test_that("multicore shards equal serial shards", {
  testthat::skip_on_os("windows")
  fit <- new_shard_fit()
  serial <- drm_bootstrap_shard(fit, parm = "fixef:mu:x", indices = 1:4, seed = 8)
  forked <- drm_bootstrap_shard(
    fit,
    parm = "fixef:mu:x",
    indices = 1:4,
    seed = 8,
    parallel = "multicore",
    workers = 2
  )
  expect_identical(forked$attempts, serial$attempts)
})

test_that("a dead forked worker is a worker_died attempt, not a dropped replicate (#1537)", {
  testthat::skip_on_os("windows")
  fit <- new_shard_fit()
  # Replicate 2's child exits without a value, as an OOM-killed worker would.
  testthat::local_mocked_bindings(
    drm_bootstrap_replicate_simulation = function(object, seed, index, re_form) {
      if (index == 2L) quit("no", status = 1L, runLast = FALSE)
      stats::simulate(object, nsim = 1L, re.form = re_form)
    }
  )
  shard <- suppressWarnings(drm_bootstrap_shard(
    fit,
    parm = "fixef:mu:x",
    indices = 1:3,
    seed = 4,
    parallel = "multicore",
    workers = 2
  ))
  expect_identical(nrow(shard$attempts), 3L)
  expect_identical(shard$attempts$bootstrap, 1:3)
  expect_identical(shard$attempts$refit_status[[2L]], "worker_died")
  expect_false(shard$attempts$refit_ok[[2L]])
  expect_true(all(shard$attempts$replicate_seed == 4L))
  ledger <- drm_bootstrap_ledger(shard)
  expect_identical(ledger$attempted, 3L)
  expect_identical(ledger$worker_died, 1L)
  expect_identical(
    ledger$usable + ledger$refit_error + ledger$refit_nonconverged +
      ledger$target_missing + ledger$worker_died,
    3L
  )
})
