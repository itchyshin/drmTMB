binomial_animal_q2_assembly_fixture <- function() {
  ids <- paste0("animal", seq_len(8L))
  order <- rev(seq_along(ids))
  A <- outer(order, order, function(i, j) 0.3^abs(i - j))
  diag(A) <- seq(0.9, 1.1, length.out = length(ids))
  dimnames(A) <- list(ids[order], ids[order])
  id_index <- rep(seq_along(ids), each = 6L)
  data <- data.frame(
    id = factor(ids[id_index], levels = rev(ids)),
    x = rep(seq(-1, 1, length.out = 6L), length(ids)),
    y = rep(c(0, 1, 1, 0, 1, 0), length(ids))
  )
  z0 <- stats::setNames(rep(c(-1, 1), each = 4L), ids)
  z1 <- stats::setNames(rep(c(-1, 1), times = 4L), ids)
  data$z0 <- unname(z0[as.character(data$id)])
  data$z1 <- unname(z1[as.character(data$id)])
  list(data = data, A = A)
}

binomial_animal_q2_recovery_fixture <- function(
  groups = 160L, repeats = 32L, link = "logit"
) {
  set.seed(2026102828L)
  ids <- sprintf("animal%03d", seq_len(groups))
  variance <- seq(0.8, 1.3, length.out = groups)
  full_A <- 0.25^abs(outer(seq_len(groups), seq_len(groups), "-")) *
    outer(sqrt(variance), sqrt(variance))
  dimnames(full_A) <- list(ids, ids)
  z0 <- stats::setNames(rep(c(-1, 1), length.out = groups), ids)
  z1 <- stats::setNames(rep(c(-1, 1), each = groups / 2L), ids)
  truth <- list(mu = c(0.2, x = 0.3),
                sd0 = c(log(0.8), z0 = 0.6),
                sd1 = c(log(0.6), z1 = -0.5))
  u0 <- drop(t(chol(full_A)) %*% stats::rnorm(groups))
  u1 <- drop(t(chol(full_A)) %*% stats::rnorm(groups))
  b0 <- exp(truth$sd0[[1L]] + truth$sd0[[2L]] * z0) * u0
  b1 <- exp(truth$sd1[[1L]] + truth$sd1[[2L]] * z1) * u1
  ii <- rep(seq_len(groups), each = repeats)
  x <- rep(seq(-1.2, 1.2, length.out = repeats), groups)
  eta <- truth$mu[[1L]] + truth$mu[[2L]] * x + b0[ii] + x * b1[ii]
  probability <- switch(
    link,
    logit = stats::plogis(eta),
    probit = stats::pnorm(eta),
    cloglog = -expm1(-exp(eta))
  )
  dat <- data.frame(y = stats::rbinom(length(ii), 1L, probability),
                    x = x, id = factor(ids[ii], levels = rev(ids)),
                    z0 = unname(z0[ii]), z1 = unname(z1[ii]))
  a_order <- c(seq(2L, groups, 2L), seq(1L, groups, 2L))
  list(data = dat, A = full_A[a_order, a_order], full_A = full_A,
       z0 = z0, z1 = z1, truth = truth)
}

binomial_animal_q2_form <- function(A) {
  bf(y ~ x + animal(1 + x | id, A = A),
     sd(id, level = "animal", coef = "(Intercept)") ~ z0,
     sd(id, level = "animal", coef = "x") ~ z1)
}

test_that("Binomial animal q2 assembles separate coefficient SD maps", {
  fx <- binomial_animal_q2_assembly_fixture()
  A <- fx$A
  form <- bf(
    y ~ x + animal(1 + x | id, A = A),
    sd(id, level = "animal", coef = "(Intercept)") ~ z0,
    sd(id, level = "animal", coef = "x") ~ z1
  )
  spec <- drmTMB:::drm_build_binomial_spec(form, fx$data)

  expect_identical(spec$structured$phylo_mu$type, "animal")
  expect_identical(spec$structured$phylo_mu$q, 2L)
  expect_identical(spec$tmb_data$has_sd_phylo_coef_model, 1L)
  expect_length(unique(spec$random_scale$phylo$dpars), 2L)
  expect_true(all(spec$tmb_data$phylo_mu_sd_row_coef >= 0L))
  expect_setequal(
    spec$random_scale$phylo$dpars,
    c(
      'sd_animal(id, dpar = "mu", coef = "(Intercept)")',
      'sd_animal(id, dpar = "mu", coef = "x")'
    )
  )
  Ainv <- solve(fx$A)
  dimnames(Ainv) <- dimnames(fx$A)
  precision_spec <- drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + animal(1 + x | id, Ainv = Ainv),
       sd(id, level = "animal", coef = "(Intercept)") ~ z0,
       sd(id, level = "animal", coef = "x") ~ z1),
    fx$data
  )
  expect_identical(precision_spec$structured$phylo_mu$structure, "Ainv")
  expect_identical(drmTMB:::make_tmb_data(precision_spec)$has_sd_phylo_coef_model,
                   1L)

  ids <- levels(fx$data$id)
  pedigree <- data.frame(
    id = ids,
    dam = c(NA, NA, NA, NA, ids[[1L]], ids[[2L]], ids[[1L]], ids[[2L]]),
    sire = c(NA, NA, NA, NA, ids[[3L]], ids[[4L]], ids[[4L]], ids[[3L]])
  )
  pedigree_spec <- drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + animal(1 + x | id, pedigree = pedigree),
       sd(id, level = "animal", coef = "(Intercept)") ~ z0,
       sd(id, level = "animal", coef = "x") ~ z1),
    fx$data
  )
  expect_identical(pedigree_spec$structured$phylo_mu$structure, "pedigree")
  expect_identical(drmTMB:::make_tmb_data(pedigree_spec)$has_sd_phylo_coef_model,
                   1L)
  expect_error(drmTMB:::drm_build_binomial_spec(
    bf(y ~ x + animal(1 + x | id, A = A),
       sd(id, level = "animal", coef = "(Intercept)") ~ z0),
    fx$data
  ), "intercept-only q1")
  for (link in c("probit", "cloglog")) {
    link_spec <- drmTMB:::drm_build_binomial_spec(
      binomial_animal_q2_form(A), fx$data, link = link
    )
    expect_identical(link_spec$structured$phylo_mu$q, 2L, info = link)
    expect_identical(link_spec$tmb_data$has_sd_phylo_coef_model, 1L,
                     info = link)
  }
})

test_that("Binomial animal q2 SD regression recovers under non-logit links", {
  skip_if(identical(Sys.getenv("DRMTMB_ANIMAL_Q2_ASSEMBLY_ONLY"), "1"))
  skip_on_cran()
  keys <- c('sd_animal(id, dpar = "mu", coef = "(Intercept)")',
            'sd_animal(id, dpar = "mu", coef = "x")')
  for (link in c("probit", "cloglog")) {
    fx <- binomial_animal_q2_recovery_fixture(link = link)
    fit <- drmTMB(
      binomial_animal_q2_form(fx$A),
      family = stats::binomial(link = link), data = fx$data,
      control = drm_control(se = FALSE)
    )
    expect_identical(fit$opt$convergence, 0L, info = link)
    expect_true(abs(stats::coef(fit, keys[[1L]])[["z0"]] -
                      fx$truth$sd0[["z0"]]) < 0.45, info = link)
    expect_true(abs(stats::coef(fit, keys[[2L]])[["z1"]] -
                      fx$truth$sd1[["z1"]]) < 0.45, info = link)
    expect_true(max(abs(fit$obj$gr(fit$opt$par))) < 2e-2, info = link)
    expect_setequal(names(predict(fit, dpar = keys[[1L]])),
                    levels(fx$data$id))
    simulated <- simulate(fit, nsim = 1L, seed = 2026102831L)
    expect_true(all(simulated[[1L]] %in% c(0, 1)), info = link)
  }
})

test_that("Binomial animal q2 recovers separate SD regressions", {
  skip_if(identical(Sys.getenv("DRMTMB_ANIMAL_Q2_ASSEMBLY_ONLY"), "1"))
  skip_on_cran()
  fx <- binomial_animal_q2_recovery_fixture()
  fit <- drmTMB(binomial_animal_q2_form(fx$A), family = stats::binomial(),
                data = fx$data, control = drm_control(se = FALSE))
  expect_identical(fit$opt$convergence, 0L)
  keys <- c('sd_animal(id, dpar = "mu", coef = "(Intercept)")',
            'sd_animal(id, dpar = "mu", coef = "x")')
  expect_lt(abs(stats::coef(fit, keys[[1L]])[["z0"]] -
                  fx$truth$sd0[["z0"]]), 0.4)
  expect_lt(abs(stats::coef(fit, keys[[2L]])[["z1"]] -
                  fx$truth$sd1[["z1"]]), 0.4)
  expect_lt(max(abs(fit$obj$gr(fit$opt$par))), 1e-2)
  for (j in seq_along(keys)) {
    alpha <- stats::coef(fit, keys[[j]])
    z <- if (j == 1L) fx$z0 else fx$z1
    predicted <- predict(fit, dpar = keys[[j]])
    expect_setequal(names(predicted), levels(fx$data$id))
    expect_equal(unname(predicted),
                 unname(exp(alpha[[1L]] + alpha[[2L]] * z[names(predicted)])),
                 tolerance = 1e-8)
  }
  sd_by_node <- drmTMB:::drm_binomial_q2_structured_sd_by_node(
    fit, fit$model$structured$phylo_mu
  )
  expect_identical(colnames(sd_by_node), fit$model$structured$phylo_mu$coef_names)
  expect_setequal(rownames(sd_by_node), rownames(fx$A))
  for (j in seq_along(keys)) {
    expect_equal(unname(sd_by_node[, j]),
                 unname(predict(fit, dpar = keys[[j]])[
                   rownames(sd_by_node)
                 ]), tolerance = 1e-8)
  }
  marginal1 <- simulate(fit, nsim = 2L, seed = 2026102829L)
  marginal2 <- simulate(fit, nsim = 2L, seed = 2026102829L)
  conditional <- simulate(fit, nsim = 1L, seed = 2026102829L,
                           re.form = NULL)
  expect_identical(marginal1, marginal2)
  expect_true(all(vapply(marginal1, function(y) all(y %in% c(0, 1)),
                         logical(1L))))
  expect_false(identical(marginal1[[1L]], conditional[[1L]]))
  save_file <- tempfile(fileext = ".rds")
  on.exit(unlink(save_file), add = TRUE)
  saveRDS(fit, save_file)
  reloaded <- readRDS(save_file)
  expect_equal(coef(reloaded, keys[[1L]]), coef(fit, keys[[1L]]))
  expect_equal(predict(reloaded, dpar = keys[[2L]]),
               predict(fit, dpar = keys[[2L]]))
  target <- paste0("fixef:", keys[[2L]], ":z1")
  target_table <- profile_targets(fit)
  selected <- target_table[target_table$parm == target, , drop = FALSE]
  expect_equal(nrow(selected), 1L)
  bootstrap <- suppressMessages(confint(
    fit, parm = paste0(keys[[2L]], ":z1"), method = "bootstrap", R = 2L,
    seed = 2026102830L
  ))
  diagnostics <- attr(bootstrap, "bootstrap.diagnostics", exact = TRUE)
  expect_equal(nrow(diagnostics), 2L)
  expect_equal(bootstrap$parm, target)
  expect_true(any(diagnostics$refit_status == "ok"))
})
