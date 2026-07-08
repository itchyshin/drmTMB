# Measure the (REML x downstream-surface) cross-product BEFORE declaring it.
# ---------------------------------------------------------------------------
# The REML arc validated REML on its own axis (does it debias? does it converge?)
# and never on the product axis. Every "little thing" found on 2026-07-08 was a
# cell of this grid that no one had enumerated:
#   vcov() reads sdr$cov under REML; profile cannot touch fixed effects under
#   REML; the endpoint solver errored on an empty free-parameter vector; the
#   missing-data gate was over-broad; spatial/animal/relmat are rejected.
#
# This script OBSERVES each cell. The observations become
# docs/dev-log/dashboard/estimator-surface-conformance.tsv, which a test then
# enforces -- and any UNDECLARED cell fails, so adding a surface or a flag forces
# a declaration. Authority rule, same as the q-series TSV: the TSV is truth.
#
# Run: OPENBLAS_NUM_THREADS=1 NOT_CRAN=true R_PROFILE_USER=/dev/null \
#        Rscript --no-init-file scratchpad/conformance_probe.R
# ---------------------------------------------------------------------------
suppressMessages(devtools::load_all(".", quiet = TRUE))

balanced_tree <- function(n_tip = 8L) {
  edges <- matrix(integer(), ncol = 2L); el <- numeric(); nxt <- n_tip + 1L
  build <- function(tips) {
    if (length(tips) == 1L) return(tips)
    node <- nxt; nxt <<- nxt + 1L
    mid <- length(tips) / 2L
    l <- build(tips[seq_len(mid)]); r <- build(tips[seq.int(mid + 1L, length(tips))])
    edges <<- rbind(edges, c(node, l), c(node, r)); el <<- c(el, 1, 1); node
  }
  build(seq_len(n_tip))
  structure(list(edge = edges, edge.length = el,
                 tip.label = paste0("sp_", seq_len(n_tip)), Nnode = n_tip - 1L),
            class = "phylo")
}

n_tip <- 8L; n_each <- 4L
tree <- balanced_tree(n_tip)
sp <- rep(tree$tip.label, each = n_each)
set.seed(20260708)
dat <- data.frame(
  species = sp,
  id = sp,
  x = rep(seq(-0.6, 0.6, length.out = n_each), times = n_tip),
  z_species = rep(seq(-1, 1, length.out = n_tip), each = n_each)
)
dat$y <- 0.2 + 0.3 * dat$x + rep(seq(-0.4, 0.4, length.out = n_tip), each = n_each) +
  rep(c(-0.08, 0.05, -0.03, 0.04), times = n_tip)
dat$count <- rpois(nrow(dat), exp(0.4 + 0.2 * dat$x))
coords <- data.frame(x = cos(seq(0, 1.5 * pi, length.out = n_tip)),
                     y = sin(seq(0, 1.5 * pi, length.out = n_tip)))
rownames(coords) <- tree$tip.label
Kmat <- outer(seq_len(n_tip), seq_len(n_tip), function(i, j) 0.35^abs(i - j))
diag(Kmat) <- diag(Kmat) + 0.15
dimnames(Kmat) <- list(tree$tip.label, tree$tip.label)

CTRL <- drm_control(optimizer = list(eval.max = 400, iter.max = 400))
base_fit <- function(reml) suppressWarnings(drmTMB(
  bf(y ~ x + phylo(1 | species, tree = tree), sigma ~ 1),
  family = gaussian(), data = dat, REML = reml, control = CTRL))

obs <- function(expr) tryCatch({ v <- force(expr); if (isTRUE(v)) "ok" else if (is.character(v)) v else "ok" },
                              error = function(e) paste0("error: ", conditionMessage(e)))

# ---- surfaces on the base model -------------------------------------------
cat("### SURFACES (gaussian, phylo, base model)\n")
cat(sprintf("%-24s %-34s %s\n", "surface", "REML=FALSE", "REML=TRUE"))
cat(strrep("-", 100), "\n")
fits <- list(`FALSE` = base_fit(FALSE), `TRUE` = base_fit(TRUE))

sd_parm <- local({
  tg <- profile_targets(fits[["FALSE"]])
  p <- tg$parm[tg$profile_ready & grepl("^sd:", tg$parm)]
  if (length(p)) p[[1]] else NA_character_
})
cat("# sd profile target:", sd_parm, "\n")

SURF <- list(
  fit                   = function(f) if (identical(f$opt$convergence, 0L)) "ok" else "nonconvergence",
  sdreport              = function(f) f$uncertainty$status,
  vcov                  = function(f) { vcov(f); "ok" },
  summary_coef_se       = function(f) if (all(is.finite(summary(f)$coefficients$std_error))) "ok" else "na",
  confint_wald          = function(f) { confint(f, parm = "fixef:mu:x", method = "wald"); "ok" },
  confint_profile_fixef = function(f) { suppressWarnings(confint(f, parm = "fixef:mu:x", method = "profile")); "ok" },
  confint_profile_sd    = function(f) { if (is.na(sd_parm)) return("skip"); suppressWarnings(confint(f, parm = sd_parm, method = "profile")); "ok" },
  profile_targets       = function(f) if (any(profile_targets(f)$profile_ready)) "ok" else "none_ready",
  check_drm             = function(f) if (isTRUE(attr(check_drm(f), "ok"))) "ok" else "not_ok",
  ranef                 = function(f) { ranef(f); "ok" },
  predict               = function(f) { predict(f, dpar = "mu"); "ok" },
  simulate              = function(f) { simulate(f, nsim = 1, seed = 1); "ok" },
  pdHess                = function(f) if (isTRUE(f$sdr$pdHess)) "ok" else "false"
)
for (nm in names(SURF)) {
  a <- obs(SURF[[nm]](fits[["FALSE"]])); b <- obs(SURF[[nm]](fits[["TRUE"]]))
  cat(sprintf("%-24s %-34s %s\n", nm, substr(a, 1, 33), substr(b, 1, 60)))
}

# ---- REML admission gates --------------------------------------------------
cat("\n### REML ADMISSION GATES (surface = fit)\n")
gate <- function(lbl, expr) cat(sprintf("%-34s %s\n", lbl, substr(obs({force(expr); "ok"}), 1, 90)))
gate("phylo mu",          suppressWarnings(drmTMB(bf(y ~ x + phylo(1|species, tree=tree)), family=gaussian(), data=dat, REML=TRUE, control=CTRL)))
gate("spatial mu",        suppressWarnings(drmTMB(bf(y ~ x + spatial(1|species, coords=coords)), family=gaussian(), data=dat, REML=TRUE, control=CTRL)))
gate("relmat mu",         suppressWarnings(drmTMB(bf(y ~ x + relmat(1|species, K=Kmat)), family=gaussian(), data=dat, REML=TRUE, control=CTRL)))
gate("poisson family",    suppressWarnings(drmTMB(bf(count ~ x + (1|id)), family=poisson(), data=dat, REML=TRUE, control=CTRL)))
gate("aggregate_gaussian",suppressWarnings(drmTMB(bf(y ~ x), family=gaussian(), data=dat, REML=TRUE, control=drm_control(aggregate_gaussian=TRUE))))
gate("sparse_fixed",      suppressWarnings(drmTMB(bf(y ~ x), family=gaussian(), data=dat, REML=TRUE, control=drm_control(sparse_fixed=TRUE))))
gate("ordinary sd() scale", suppressWarnings(drmTMB(bf(y ~ x + (1|id), sigma ~ 1, sd(id) ~ 1), family=gaussian(), data=dat, REML=TRUE, control=CTRL)))
gate("missing engine, complete", suppressWarnings(drmTMB(bf(y ~ x), family=gaussian(), data=dat, missing=miss_control(response="include"), REML=TRUE, control=CTRL)))
dna <- dat; dna$y[2] <- NA
gate("missing engine, real NAs",  suppressWarnings(drmTMB(bf(y ~ x), family=gaussian(), data=dna, missing=miss_control(response="include"), REML=TRUE, control=CTRL)))
gate("sd_phylo + sigma~phylo", suppressWarnings(drmTMB(bf(y ~ x + phylo(1|species, tree=tree), sigma ~ 1 + phylo(1|species, tree=tree), sd_phylo(species) ~ z_species), family=gaussian(), data=dat, REML=TRUE, control=CTRL)))
cat("\n(the last row is Ayumi's location-scale-scale model)\n")
