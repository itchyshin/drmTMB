# Coevolution (Hadfield et al. 2014, "A Tale of Two Phylogenies") additive
# double-phylogeny model: gate + Stage-1 target spec.
#
# The full model needs the simultaneous additive fit of host main + parasite main
# + coevolutionary interaction (and, with star trees, the two evolutionary-
# interaction terms). drmTMB today admits ONE structured effect per dpar
# (R/drmTMB.R extract_gaussian_mu_phylo_term), so the additive model is gated.
# These tests (a) lock the gate as intentional -- a regression guard so multi-block
# is never half-wired silently -- and (b) record the Stage-1 acceptance target as a
# skipped recovery test. See docs/design/178-coevolution-tale-of-two-phylogenies.md.

make_double_phylo_data <- function(seed = 20260620L, n_h = 12L, n_p = 12L,
                                   n_rep = 2L, sd_hm = 0.6, sd_pm = 0.5,
                                   sd_co = 0.7, b0 = 0.3, b1 = 0.5, sigma = 0.4) {
  withr::local_seed(seed)
  ht <- ape::rcoal(n_h); ht$tip.label <- paste0("h", seq_len(n_h))
  pt <- ape::rcoal(n_p); pt$tip.label <- paste0("p", seq_len(n_p))
  A_h <- stats::cov2cor(ape::vcv(ht)); A_p <- stats::cov2cor(ape::vcv(pt))
  L_h <- t(chol(A_h)); L_p <- t(chol(A_p))
  a_h <- as.vector(L_h %*% stats::rnorm(n_h)) * sd_hm; names(a_h) <- ht$tip.label
  a_p <- as.vector(L_p %*% stats::rnorm(n_p)) * sd_pm; names(a_p) <- pt$tip.label
  U <- sd_co * (L_h %*% matrix(stats::rnorm(n_h * n_p), n_h, n_p) %*% t(L_p))
  dimnames(U) <- list(ht$tip.label, pt$tip.label)
  grid <- expand.grid(host = ht$tip.label, parasite = pt$tip.label,
                      stringsAsFactors = FALSE)
  dat <- grid[rep(seq_len(nrow(grid)), each = n_rep), ]
  dat$x <- stats::rnorm(nrow(dat))
  dat$y <- b0 + b1 * dat$x + a_h[dat$host] + a_p[dat$parasite] +
    U[cbind(dat$host, dat$parasite)] + stats::rnorm(nrow(dat), 0, sigma)
  list(data = dat, host_tree = ht, parasite_tree = pt,
       truth = c(sd_host_main = sd_hm, sd_parasite_main = sd_pm, sd_coev = sd_co))
}

test_that("additive double-phylogeny model is gated to one structured effect per dpar (design 178 Stage 1)", {
  skip_if_not_installed("ape")
  skip_if_not_installed("withr")
  d <- make_double_phylo_data(n_h = 10L, n_p = 10L, n_rep = 2L)
  host_tree <- d$host_tree            # phylo() requires a bare tree symbol, not x$y
  parasite_tree <- d$parasite_tree
  form <- bf(
    y ~ x +
      phylo(1 | host, tree = host_tree) +
      phylo(1 | parasite, tree = parasite_tree) +
      phylo_interaction(1 | host:parasite, tree1 = host_tree, tree2 = parasite_tree),
    sigma ~ 1
  )
  # Intentional gate: the simultaneous multi-component fit is not yet implemented.
  # If this stops erroring, the multi-structured-block engine work (design 178
  # Stage 1) has landed -- convert the Stage-1 target test below into the live
  # recovery assertion and remove this guard.
  expect_error(
    drmTMB(form, family = gaussian(), data = d$data),
    regexp = "structured effect"
  )
})

test_that("DESIGN 178 STAGE 1 TARGET: additive double-phylogeny model recovers its components", {
  skip("Engine multi-structured-block support is not yet implemented; see docs/design/178-coevolution-tale-of-two-phylogenies.md Stage 1. This is the acceptance spec to activate once the additive fit is wired (with an adequate-N species ladder per the honest larger-N contract).")
  # Intended behaviour once Stage 1 lands (at adequate N, e.g. a species ladder):
  #   d <- make_double_phylo_data(n_h = 60L, n_p = 60L, n_rep = 2L)
  #   fit <- drmTMB(bf(y ~ x + phylo(1|host, tree=d$host_tree) +
  #                    phylo(1|parasite, tree=d$parasite_tree) +
  #                    phylo_interaction(1|host:parasite, tree1=d$host_tree,
  #                                      tree2=d$parasite_tree), sigma ~ 1),
  #                 family = gaussian(), data = d$data)
  #   expect_true(is_converged(fit))
  #   sds <- fit$sdpars$mu          # host main, parasite main, coevolution SDs
  #   # each recovered within the documented adequate-N tolerance (rel bias bounded),
  #   # the coevolution (phylo_interaction) SD being the headline.
})
