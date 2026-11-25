test_that("CJS kernel matches the frozen independent probability fixture", {
  fixture <- read.delim(test_path("fixtures/cmr-exact.tsv"))
  expect_true(file.exists(system.file("include", "TMB.hpp", package = "TMB")))
  expect_true("terminal_constraint" %in% names(formals(drm_cjs)))
  expect_equal(nrow(fixture), 719L)
  for (i in seq_len(nrow(fixture))) {
    row <- fixture[i, ]
    history_chr <- strsplit(row$history, "", fixed = TRUE)[[1]]
    observed <- history_chr != "?"
    history <- as.integer(ifelse(observed, history_chr, "0"))
    phi <- as.numeric(strsplit(row$phi, ",", fixed = TRUE)[[1]])
    p <- as.numeric(strsplit(row$p, ",", fixed = TRUE)[[1]])
    nt <- length(history)
    expect_equal(length(phi), nt - 1L, info = paste("fixture", i))
    expect_equal(length(p), nt, info = paste("fixture", i))
    obj <- TMB::MakeADFun(
      data = list(model_type = 1000L, cmr_N = 1L, cmr_T = nt,
                  cmr_y = history, cmr_observed = as.integer(observed),
                  cmr_first = as.integer(row$first - 1L), cmr_end = nt - 1L,
                  cmr_delta = rep(1, nt - 1L), cmr_frequency = 2L,
                  cmr_X_phi = matrix(0, nt - 1L, 1L),
                  cmr_X_p = matrix(0, nt, 1L),
                  cmr_offset_phi = qlogis(phi), cmr_offset_p = qlogis(p)),
      parameters = list(beta_phi = 0, beta_p = 0),
      DLL = "drmTMB", silent = TRUE)
    nll <- obj$fn(obj$par)
    if (row$probability == 0) {
      expect_true(is.infinite(nll) && nll > 0, info = paste("fixture", i))
    } else {
      expect_equal(exp(-nll), row$probability^2, tolerance = 1e-10,
                   info = paste("fixture", i))
    }
  }

  # Irregular survival intervals use s^Delta; unobserved emissions retain the
  # state transition while contributing no detection probability.
  obj <- TMB::MakeADFun(
    data = list(model_type = 1000L, cmr_N = 1L, cmr_T = 3L,
                cmr_y = c(1L, 0L, 0L), cmr_observed = c(1L, 0L, 1L),
                cmr_first = 0L, cmr_end = 2L, cmr_delta = c(2, 1),
                cmr_frequency = 1L,
                cmr_X_phi = matrix(0, 2L, 1L), cmr_X_p = matrix(0, 3L, 1L),
                cmr_offset_phi = qlogis(c(.8, .6)),
                cmr_offset_p = qlogis(c(.5, .3, .4))),
    parameters = list(beta_phi = 0, beta_p = 0), DLL = "drmTMB", silent = TRUE)
  expect_equal(exp(-obj$fn(obj$par)), .8^2 * .6 * .6 +
                 (1 - .8^2) + .8^2 * (1 - .6), tolerance = 1e-10)

  histories <- rbind(c(1, 0, 0), c(1, 0, 1), c(0, 1, 0))
  d <- cmr_data(histories, frequency = c(2L, 1L, 1L))
  p_rows <- expand.grid(t = 1:3, i = 1:3)
  p_data <- data.frame(id = d$id[p_rows$i], occasion = d$occasions[p_rows$t],
                       lp = qlogis(c(.5, .3, .4)[p_rows$t]))
  f_rows <- expand.grid(t = 1:2, i = 1:3)
  phi_data <- data.frame(id = d$id[f_rows$i],
                         interval_start = d$occasions[f_rows$t],
                         interval_end = d$occasions[f_rows$t + 1L],
                         lp = qlogis(c(.8, .6)[f_rows$t]))
  fixed_fit <- drm_cjs(d, phi = ~ 0 + offset(lp), p = ~ 0 + offset(lp),
                       phi_data = phi_data, p_data = p_data,
                       terminal_constraint = list(phi = .6))
  expect_equal(fixed_fit$logLik, sum(d$frequency * log(c(.6256, .1344, .76))), tolerance = 1e-10)
})
