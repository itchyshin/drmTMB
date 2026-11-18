test_that("Julia Binomial bridge admits only the mixed phylo and IID SD route", {
  tree <- ape::rcoal(2)
  tree$tip.label <- c("s1", "s2")
  form <- bf(
    y ~ x + (1 | id) + phylo(1 | species, tree = tree),
    sd(id) ~ w,
    sd(species, level = "phylogenetic") ~ z
  )
  no_iid_sd <- bf(
    y ~ x + (1 | id) + phylo(1 | species, tree = tree),
    sd(species, level = "phylogenetic") ~ z
  )
  wrong_phylo_group <- bf(
    y ~ x + (1 | id) + phylo(1 | species, tree = tree),
    sd(id) ~ w,
    sd(other, level = "phylogenetic") ~ z
  )
  ordinary_slope <- bf(
    y ~ x + (x | id) + phylo(1 | species, tree = tree),
    sd(id, coef = "x") ~ w,
    sd(species, level = "phylogenetic") ~ z
  )

  for (link in c("probit", "cloglog")) {
    expect_true(
      drmTMB:::drm_julia_binomial_phylo_ordinary_sd_route_admitted(
        form, link = link
      ),
      info = link
    )
    expect_no_error(drmTMB:::drm_julia_refuse_binomial_nonlogit_sd(
      form, stats::binomial(link = link)
    ))
    expect_false(
      drmTMB:::drm_julia_binomial_phylo_ordinary_sd_route_admitted(
        no_iid_sd, link = link
      ),
      info = link
    )
    expect_false(
      drmTMB:::drm_julia_binomial_phylo_ordinary_sd_route_admitted(
        wrong_phylo_group, link = link
      ),
      info = link
    )
    expect_false(
      drmTMB:::drm_julia_binomial_phylo_ordinary_sd_route_admitted(
        ordinary_slope, link = link
      ),
      info = link
    )
  }
  expect_true(
    drmTMB:::drm_julia_binomial_phylo_ordinary_sd_route_admitted(form),
    info = "logit uses the standard Binomial bridge route"
  )
  labels <- drmTMB:::drm_julia_bridge_payload_coef_labels(
    form, data = data.frame(y = 0:1, x = 0:1, w = 0:1, z = 0:1,
                            id = factor(c("a", "b")),
                            species = factor(c("s1", "s2"))),
    env = environment(), family_type = "binomial"
  )
  expect_true(all(c("sd", "sd_phylo") %in% names(labels)))
  expect_false(any(grepl("^sdtarget_", names(labels))))
})

test_that("Julia Binomial bridge fits and marginally simulates mixed phylo and IID SDs", {
  drm_skip_live_julia()
  skip_if_not_installed("ape")

  set.seed(202610291L)
  n_tip <- 12L
  n_id <- 24L
  n_rep <- 2L
  tree <- ape::rcoal(n_tip)
  tree$tip.label <- paste0("tip_", seq_len(n_tip))
  tree$edge.length <- tree$edge.length / max(ape::node.depth.edgelength(tree)[seq_len(n_tip)])
  K <- drmTMB:::drm_phylo_tip_covariance(tree)
  species_index <- rep(seq_len(n_tip), each = n_id * n_rep)
  id_index <- rep(rep(seq_len(n_id), each = n_rep), times = n_tip)
  species <- factor(tree$tip.label[species_index], levels = tree$tip.label)
  id <- factor(paste0("id_", id_index), levels = paste0("id_", seq_len(n_id)))
  z_tip <- seq(-1, 1, length.out = n_tip)
  w_id <- seq(-1, 1, length.out = n_id)
  z <- z_tip[species_index]
  w <- w_id[id_index]
  x <- stats::rnorm(length(id))
  b_id <- stats::rnorm(n_id, sd = exp(-0.85 + 0.40 * w_id))
  b_phy <- as.vector(t(chol(K)) %*% stats::rnorm(n_tip)) *
    exp(-0.65 + 0.40 * z_tip)
  eta <- -0.15 + 0.25 * x + b_id[id_index] + b_phy[species_index]
  dat <- data.frame(x = x, w = w, z = z, id = id, species = species)
  form <- bf(
    y ~ x + (1 | id) + phylo(1 | species, tree = tree),
    sd(id) ~ w,
    sd(species, level = "phylogenetic") ~ z
  )

  for (link in c("logit", "probit", "cloglog")) {
    dat$y <- stats::rbinom(
      nrow(dat), 1L, stats::binomial(link = link)$linkinv(eta)
    )
    fit_tmb <- drmTMB(
      form, family = stats::binomial(link), data = dat, engine = "tmb",
      control = drm_control(se = FALSE)
    )
    fit_julia <- drmTMB(
      form, family = stats::binomial(link), data = dat, engine = "julia",
      control = drm_control()
    )
    expect_true(is_converged(fit_tmb), info = paste(link, "TMB"))
    expect_true(is_converged(fit_julia), info = paste(link, "Julia"))
    for (target in c("sd(id)", "sd_phylo(species)")) {
      tmb_coef <- coef(fit_tmb, dpar = target)
      julia_coef <- coef(fit_julia, dpar = target)
      slope <- if (identical(target, "sd(id)")) "w" else "z"
      expect_true(unname(tmb_coef[[slope]]) > 0, info = paste(link, target))
      expect_true(unname(julia_coef[[slope]]) > 0, info = paste(link, target))
      expect_lt(abs(unname(tmb_coef[[slope]]) - unname(julia_coef[[slope]])),
                0.45)
      pred_tmb <- predict(fit_tmb, dpar = target)
      pred_julia <- predict(fit_julia, dpar = target)
      expect_equal(as.numeric(pred_julia), as.numeric(pred_tmb),
                   tolerance = 0.45, info = paste(link, target))
    }
    expect_equal(as.numeric(logLik(fit_julia)), as.numeric(logLik(fit_tmb)),
                 tolerance = 0.08, info = link)
    sim <- simulate(fit_julia, nsim = 1L, seed = 202610292L)
    expect_length(sim, 1L)
    expect_length(sim[[1L]], nrow(dat))
    expect_true(all(sim[[1L]] %in% c(0, 1)), info = link)
  }
})
