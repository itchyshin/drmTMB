#!/usr/bin/env Rscript
# R1 collateral-unlock gate for Prong B Tier 1 (E1-E4 in R/profile.R).
#
# The edits delete fence PREDICATES, not cells, so every route a predicate
# governed becomes profile-ready -- including routes with no ledger cell. This
# script is the pre-merge gate the scoping memo (section 5, R1) requires.
#
# The change is monotone: E1-E4 only delete disjuncts from a FALSE-forcing
# fence and narrow one dpar set, so profile_ready can only move FALSE -> TRUE.
# The flip set is therefore exactly the set of (route, target) pairs where a
# deleted predicate fired. This script rebuilds the four deleted predicates
# verbatim from origin/main and reports every target they governed, so the
# pre-edit column is derived rather than requiring a second install.
#
# Usage: Rscript --no-init-file scratchpad/2026-08-03-prong-b-r1-collateral-diff.R

suppressMessages({
  library(drmTMB)
  library(ape)
})

set.seed(2026080301L)

`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- the four deleted predicates, copied verbatim from origin/main ----------
# (git show 25768833b:R/profile.R). These reconstruct the PRE-edit fence.

smu_type <- drmTMB:::structured_mu_type
smu_q <- drmTMB:::structured_mu_q
pm_endpoint_dpars <- drmTMB:::phylo_mu_endpoint_dpars
pm_labelled_q2 <- drmTMB:::phylo_mu_has_labelled_mu_intercept_slope_q2

old_count_labelled_q2 <- function(object) {
  if (!identical(object$model$model_type, "poisson") &&
      !identical(object$model$model_type, "nbinom2")) {
    return(FALSE)
  }
  structured <- object$model$structured$phylo_mu
  provider <- smu_type(structured)
  permitted <- if (identical(object$model$model_type, "poisson")) {
    c("phylo", "spatial", "animal", "relmat")
  } else {
    "phylo"
  }
  provider %in% permitted && pm_labelled_q2(structured)
}

old_count_sigma_interaction <- function(object, dpar) {
  structured <- object$model$structured$phylo_mu
  object$model$model_type %in% c("nbinom2", "zi_nbinom2") &&
    identical(dpar, "sigma") &&
    isTRUE(structured$has) &&
    identical(smu_type(structured), "phylo_interaction") &&
    identical(pm_endpoint_dpars(structured), "sigma") &&
    identical(smu_q(structured), 1L)
}

old_zob_sigma_q1 <- function(object, dpar, internal) {
  identical(object$model$model_type, "zero_one_beta") &&
    identical(dpar, "sigma") &&
    identical(internal, "log_sd_sigma") &&
    is.list(object$model$random$sigma) &&
    identical(object$model$random$sigma$n_terms, 1L) &&
    identical(object$model$random$sigma$n_cors, 0L) &&
    (!is.list(object$model$random$mu_sigma) ||
      identical(object$model$random$mu_sigma$n_cors, 0L))
}

# the zero_one_beta disjunct of count_point_fit_only_profile_restricted, with
# the PRE-edit dpar set c("mu", "sigma", "zoi", "coi")
old_zob_structured_q1 <- function(object, dpar) {
  identical(object$model$model_type, "zero_one_beta") &&
    dpar %in% c("mu", "sigma", "zoi", "coi") &&
    isTRUE(object$model$structured$phylo_mu$has) &&
    smu_type(object$model$structured$phylo_mu) %in%
      c("phylo", "animal", "relmat", "spatial", "phylo_interaction") &&
    identical(smu_q(object$model$structured$phylo_mu), 1L) &&
    identical(pm_endpoint_dpars(object$model$structured$phylo_mu), dpar)
}

# Which deleted predicate (if any) governed this target pre-edit?
governed_by <- function(object, dpar, internal) {
  hits <- character(0)
  if (identical(dpar, "mu") && isTRUE(try(old_count_labelled_q2(object), silent = TRUE))) {
    hits <- c(hits, "E1/E2:count_labelled_q2")
  }
  if (isTRUE(try(old_count_sigma_interaction(object, dpar), silent = TRUE))) {
    hits <- c(hits, "E1:count_sigma_interaction")
  }
  if (isTRUE(try(old_zob_sigma_q1(object, dpar, internal), silent = TRUE))) {
    hits <- c(hits, "E3:zob_sigma_q1")
  }
  if (isTRUE(try(old_zob_structured_q1(object, dpar), silent = TRUE)) &&
      identical(dpar, "sigma")) {
    hits <- c(hits, "E1:zob_structured_sigma_q1")
  }
  if (length(hits) == 0L) NA_character_ else paste(hits, collapse = "+")
}

# ---- DGPs -------------------------------------------------------------------

zob_ordinary <- function(seed = 2026073401L, n_id = 12L, n_each = 24L,
                         sd_sigma = 0.45, with_mu_re = FALSE) {
  set.seed(seed)
  id <- factor(rep(paste0("id", seq_len(n_id)), each = n_each))
  x <- rnorm(length(id))
  u_sigma <- setNames(rnorm(n_id), levels(id))
  u_mu <- setNames(rnorm(n_id), levels(id))
  mu_lin <- -0.15 + 0.40 * x
  if (with_mu_re) mu_lin <- mu_lin + 0.5 * u_mu[as.character(id)]
  mu <- plogis(mu_lin)
  sigma <- exp(-1.05 + sd_sigma * u_sigma[as.character(id)])
  boundary <- rbinom(length(id), 1L, plogis(-2.0))
  y <- rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- rbinom(sum(boundary == 1L), 1L, plogis(0.15))
  data.frame(y = y, x = x, id = id)
}

zob_phylo <- function(seed = 2026080302L, n_tip = 24L, n_each = 30L,
                      sd_v = 0.45, on = "sigma") {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$edge.length <- tree$edge.length / max(ape::branching.times(tree))
  V <- ape::vcv(tree, corr = TRUE)
  u <- setNames(as.numeric(t(chol(V)) %*% rnorm(n_tip)), rownames(V))
  species <- rep(tree$tip.label, each = n_each)
  x <- rnorm(length(species))
  mu_lin <- -0.15 + 0.35 * x
  sig_lin <- rep(-1, length(species))
  if (on == "mu") mu_lin <- mu_lin + sd_v * u[species]
  if (on == "sigma") sig_lin <- sig_lin + sd_v * u[species]
  mu <- plogis(mu_lin)
  sigma <- exp(sig_lin)
  boundary <- rbinom(length(x), 1L, plogis(-1.1))
  y <- rbeta(length(x), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- rbinom(sum(boundary), 1L, plogis(0.1))
  list(data = data.frame(y = y, x = x, species = species), tree = tree)
}

count_labelled_q2 <- function(seed = 2026080303L, n_tip = 40L, n_each = 12L,
                              family = "poisson") {
  set.seed(seed)
  tree <- ape::rcoal(n_tip)
  tree$edge.length <- tree$edge.length / max(ape::branching.times(tree))
  V <- ape::vcv(tree, corr = TRUE)
  L <- t(chol(V))
  a <- setNames(as.numeric(L %*% rnorm(n_tip)) * 0.45, rownames(V))
  b <- setNames(as.numeric(L %*% rnorm(n_tip)) * 0.35, rownames(V))
  species <- rep(tree$tip.label, each = n_each)
  x <- rnorm(length(species))
  eta <- 0.8 + 0.3 * x + a[species] + b[species] * x
  y <- if (family == "poisson") {
    rpois(length(eta), exp(eta))
  } else {
    rnbinom(length(eta), mu = exp(eta), size = 3)
  }
  list(data = data.frame(y = y, x = x, species = species), tree = tree)
}

nb2_sigma_interaction <- function(seed = 2026080304L, n1 = 8L, n2 = 7L,
                                  n_each = 10L, sd_v = 0.60) {
  set.seed(seed)
  t1 <- ape::rcoal(n1); t1$edge.length <- t1$edge.length / max(ape::branching.times(t1))
  t2 <- ape::rcoal(n2); t2$edge.length <- t2$edge.length / max(ape::branching.times(t2))
  V1 <- ape::vcv(t1, corr = TRUE); V2 <- ape::vcv(t2, corr = TRUE)
  K <- kronecker(V1, V2)
  cells <- expand.grid(p2 = rownames(V2), p1 = rownames(V1), stringsAsFactors = FALSE)
  u <- as.numeric(t(chol(K + diag(1e-8, nrow(K)))) %*% rnorm(nrow(K))) * sd_v
  key <- paste(cells$p1, cells$p2, sep = ":")
  names(u) <- key
  idx <- rep(seq_along(key), each = n_each)
  x <- rnorm(length(idx))
  sigma <- exp(-0.5 + u[key][idx])
  mu <- exp(1.0 + 0.3 * x)
  y <- rnbinom(length(idx), mu = mu, size = 1 / sigma^2)
  list(
    data = data.frame(y = y, x = x,
                      plant = factor(cells$p1[idx]),
                      pollinator = factor(cells$p2[idx])),
    tree1 = t1, tree2 = t2
  )
}

# ---- route battery ----------------------------------------------------------

routes <- list()
add <- function(label, cell, expect, fit_fn) {
  routes[[length(routes) + 1L]] <<- list(
    label = label, cell = cell, expect = expect, fit_fn = fit_fn
  )
}

ctl <- drm_control(se = TRUE)

# --- the 14 that MUST flip ---
add("zob sigma ordinary intercept", "mc-0568", "FLIP", function() {
  d <- zob_ordinary()
  drmTMB(bf(y ~ x, sigma ~ (1 | id), zoi ~ 1, coi ~ 1),
         family = zero_one_beta(), data = d, control = ctl)
})
add("zob sigma ordinary slope", "mc-0576", "FLIP", function() {
  d <- zob_ordinary()
  drmTMB(bf(y ~ x, sigma ~ (0 + x | id), zoi ~ 1, coi ~ 1),
         family = zero_one_beta(), data = d, control = ctl)
})
for (prov in c("phylo", "animal", "relmat", "spatial")) {
  local({
    p <- prov
    add(paste0("zob sigma structured ", p), "mc-0593..0597", "FLIP", function() {
      s <- zob_phylo(on = "sigma")
      rhs <- switch(p,
        phylo  = quote(phylo(1 | species, tree = tree)),
        animal = quote(animal(1 | species, Ainv = Ainv)),
        relmat = quote(relmat(1 | species, K = K)),
        spatial = quote(spatial(1 | site, coords = coords))
      )
      tree <- s$tree
      if (p == "animal") {
        Ainv <- Matrix::Matrix(solve(ape::vcv(tree, corr = TRUE)), sparse = TRUE)
        drmTMB(bf(y ~ x, sigma ~ animal(1 | species, Ainv = Ainv), zoi ~ 1, coi ~ 1),
               family = zero_one_beta(), data = s$data, control = ctl)
      } else if (p == "relmat") {
        K <- ape::vcv(tree, corr = TRUE)
        drmTMB(bf(y ~ x, sigma ~ relmat(1 | species, K = K), zoi ~ 1, coi ~ 1),
               family = zero_one_beta(), data = s$data, control = ctl)
      } else if (p == "spatial") {
        d <- s$data; d$site <- d$species
        us <- unique(d$site)
        coords <- matrix(rnorm(2 * length(us)), ncol = 2, dimnames = list(us, NULL))
        drmTMB(bf(y ~ x, sigma ~ spatial(1 | site, coords = coords), zoi ~ 1, coi ~ 1),
               family = zero_one_beta(), data = d, control = ctl)
      } else {
        drmTMB(bf(y ~ x, sigma ~ phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1),
               family = zero_one_beta(), data = s$data, control = ctl)
      }
    })
  })
}
add("poisson mu labelled q2 phylo", "mc-0436", "FLIP", function() {
  s <- count_labelled_q2(family = "poisson"); tree <- s$tree
  drmTMB(bf(y ~ x + phylo(1 + x | p | species, tree = tree)),
         family = poisson(), data = s$data, control = ctl)
})
add("nbinom2 mu labelled q2 phylo", "mc-0418", "FLIP", function() {
  s <- count_labelled_q2(family = "nbinom2"); tree <- s$tree
  drmTMB(bf(y ~ x + phylo(1 + x | p | species, tree = tree)),
         family = nbinom2(), data = s$data, control = ctl)
})
add("nbinom2 sigma phylo_interaction q1", "mc-0425", "FLIP", function() {
  s <- nb2_sigma_interaction(); t1 <- s$tree1; t2 <- s$tree2
  drmTMB(bf(y ~ x, sigma ~ phylo_interaction(1 | plant:pollinator,
                                             tree1 = t1, tree2 = t2)),
         family = nbinom2(), data = s$data, control = ctl)
})

# --- routes that MUST STAY FENCED ---
add("zob structured mu q1 phylo (Tier 2)", "mc-0583..0587", "FENCED", function() {
  s <- zob_phylo(on = "mu"); tree <- s$tree
  drmTMB(bf(y ~ x + phylo(1 | species, tree = tree), zoi ~ 1, coi ~ 1),
         family = zero_one_beta(), data = s$data, control = ctl)
})
add("zob ordinary zoi q1 (Tier 2)", "mc-0569", "FENCED", function() {
  set.seed(2026080305L)
  n_id <- 32L; n_each <- 50L
  id <- factor(rep(paste0("id", seq_len(n_id)), each = n_each))
  x <- rnorm(length(id))
  u <- setNames(rnorm(n_id), levels(id))
  mu <- plogis(-0.15 + 0.35 * x); sigma <- exp(-1)
  zoi <- plogis(-1.15 + 0.45 * u[as.character(id)])
  boundary <- rbinom(length(id), 1L, zoi)
  y <- rbeta(length(id), mu / sigma^2, (1 - mu) / sigma^2)
  y[boundary == 1L] <- rbinom(sum(boundary), 1L, plogis(0.1))
  drmTMB(bf(y ~ x, sigma ~ 1, zoi ~ (1 | id), coi ~ 1),
         family = zero_one_beta(), data = data.frame(y, x, id), control = ctl)
})

# --- THE COLLATERAL PROBE: zob sigma RE with a CO-PRESENT mu RE ---
# old_zob_sigma_q1 never constrained random$mu$n_re, so this route was
# governed by the deleted predicate but has NO ledger cell.
add("zob sigma RE + co-present mu RE (COLLATERAL)", "<no cell>", "PROBE", function() {
  d <- zob_ordinary(with_mu_re = TRUE)
  drmTMB(bf(y ~ x + (1 | id), sigma ~ (1 | id), zoi ~ 1, coi ~ 1),
         family = zero_one_beta(), data = d, control = ctl)
})

# ---- run --------------------------------------------------------------------

rows <- list()
for (r in routes) {
  cat("== ", r$label, " ...\n", sep = "")
  fit <- tryCatch(r$fit_fn(), error = function(e) e)
  if (inherits(fit, "error")) {
    cat("   FIT ERROR: ", conditionMessage(fit), "\n", sep = "")
    rows[[length(rows) + 1L]] <- data.frame(
      route = r$label, cell = r$cell, expect = r$expect, parm = NA_character_,
      pre_governed = NA_character_, post_ready = NA, post_note = "<fit error>",
      stringsAsFactors = FALSE
    )
    next
  }
  tg <- profile_targets(fit)
  tg <- tg[tg$target_type == "direct", , drop = FALSE]
  for (i in seq_len(nrow(tg))) {
    rows[[length(rows) + 1L]] <- data.frame(
      route = r$label, cell = r$cell, expect = r$expect,
      parm = tg$parm[[i]],
      pre_governed = governed_by(fit, tg$dpar[[i]], tg$tmb_parameter[[i]]),
      post_ready = tg$profile_ready[[i]],
      post_note = tg$profile_note[[i]],
      stringsAsFactors = FALSE
    )
  }
}

out <- do.call(rbind, rows)
out$pre_ready <- ifelse(is.na(out$pre_governed), out$post_ready, FALSE)
out$flipped <- (!out$pre_ready %in% TRUE) & (out$post_ready %in% TRUE)

cat("\n\n================ R1 COLLATERAL-UNLOCK DIFF ================\n")
print(out[, c("route", "cell", "expect", "parm", "pre_governed",
              "pre_ready", "post_ready", "post_note", "flipped")],
      row.names = FALSE)

cat("\n---- FLIPPED targets (profile_ready FALSE -> TRUE) ----\n")
fl <- out[out$flipped %in% TRUE, , drop = FALSE]
if (nrow(fl) == 0L) cat("(none)\n") else
  print(fl[, c("route", "cell", "parm", "pre_governed", "post_note")], row.names = FALSE)

cat("\n---- VIOLATIONS ----\n")
bad <- rbind(
  out[out$expect == "FENCED" & out$flipped %in% TRUE, , drop = FALSE],
  out[out$expect == "FLIP" & out$post_ready %in% FALSE &
        !is.na(out$pre_governed), , drop = FALSE]
)
if (nrow(bad) == 0L) {
  cat("none\n")
} else {
  print(bad[, c("route", "cell", "expect", "parm", "post_ready", "post_note")],
        row.names = FALSE)
}

write.table(out, "scratchpad/2026-08-03-prong-b-r1-collateral-diff.tsv",
            sep = "\t", row.names = FALSE, quote = FALSE)
cat("\nwrote scratchpad/2026-08-03-prong-b-r1-collateral-diff.tsv\n")
