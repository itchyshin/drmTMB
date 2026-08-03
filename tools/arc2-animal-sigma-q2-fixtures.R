# Arc 2 -- signal-bearing animal SCALE-side q2 fixture (mc-0304).
#
# WHY THIS FILE EXISTS
# --------------------
# mc-0304's capability-ledger row (dpar=sigma, provider=animal, q_gate=q2,
# estimator=ML) has NO genuine measured profile failure on record -- same
# disqualified-evidence pattern as mc-0292/mc-0316 (see
# tools/arc2-spatial-sigma-q2-fixtures.R's header for the full account of the
# n=1/N=100/Wald/zero-truth-correlation defect this file's evidence source
# shares). This file supplies the missing signal-bearing DGP, mirroring
# tools/arc2-phylo-sigma-fixtures.R::arc2_phylo_sigma_q2_nolabel_fixture()'s
# pattern exactly.
#
# The fitted formula (verified against
# tools/run-structured-re-gaussian-lowq-mu-sigma-intercept-smoke.R:391-398) is
# the SAME unlabelled term in both mu and sigma:
#
#     y ~ animal(1 | id, A = A), sigma ~ animal(1 | id, A = A)
#
# A live toy fit (Curie, 2026-08-03) confirms drmTMB auto-links this matching
# unlabelled pair into a joint q2 block exactly as it does for phylo/spatial:
# `profile_targets()` exposes `sd:mu:mu:animal(1 | id)`,
# `sd:sigma:sigma:animal(1 | id)`, and a
# `cor:animal:cor(mu:(Intercept),sigma:(Intercept) | animal | id)` target.
# Only the two marginal SDs are gated; the correlation is reported for
# information but never gated, matching mc-0283's scoping precisely.
#
# DESIGN RATIONALE
# -----------------
# The nested `.build_animal_pedigree_40()` pedigree builder below is COPIED
# (not shared) from tools/arc2-beta-animal-fixtures.R and
# tools/arc3-nbinom2-sigma-provider-fixtures.R, both of which document why it
# must be nested inside the fixture function rather than hoisted to top level:
# tools/run-arc2-profile-feasibility.R's `source_fixture_builder()` only
# `eval()`s the ONE top-level `<-` assignment matching the requested
# `fn_name`, so a separate top-level helper is silently never sourced.
#
# `n_founders = 4` (40 individuals, the SAME 3-generation synthetic pedigree
# already validated for mc-0013/mc-0015 under beta()) is kept as the default
# here rather than pre-emptively widened to 8: mc-0423 (animal, NB2 q1
# sigma-only) needed n_founders raised to 8 only after a DIAGNOSED,
# seed-specific failure, and a multi-seed cor(v_mu, v_sigma) scan at
# n_founders = 4 here (seeds 101-110, |cor| range 0.08-0.50) is the same
# order of magnitude as the phylo/relmat scans that DID pass their point-fit
# gates -- the gate result governs, not the scan alone (see the point-fit
# gate script's output for the actual 5-seed table). `n_each = 12` follows
# the Gaussian-scale replication ladder already validated for
# mc-0277/mc-0283/mc-0279/mc-0292.

#' Gaussian ML fixture with genuine animal-pedigree signal on BOTH mu and
#' log(sigma) via two UNLABELLED matching `animal(1 | id)` terms (mc-0304
#' shape).
#'
#' @param n_founders Number of founder pairs seeding the synthetic
#'   3-generation pedigree. Default 4 (40 individuals total).
#' @param n_each Observations per individual. Default 12.
#' @param seed RNG seed.
#' @param true_sd_mu True SD of the animal effect on mu (identity link,
#'   additive on the response scale).
#' @param true_log_sd_sigma True SD of the animal effect on log(sigma).
#' @param mu0 Intercept on mu.
#' @param log_sigma0 Baseline log residual SD.
#' @return list(data, pedigree, A, true_sd_mu, true_log_sd_sigma)
arc2_animal_sigma_q2_fixture <- function(n_founders = 4L,
                                         n_each = 12L,
                                         seed = 101L,
                                         true_sd_mu = 0.6,
                                         true_log_sd_sigma = 0.7,
                                         mu0 = 0.4,
                                         log_sigma0 = log(0.5)) {
  .build_animal_pedigree_40 <- function(n_founders) {
    n_f0 <- n_founders
    founders_f <- paste0("f0_", seq_len(n_f0))
    founders_m <- paste0("m0_", seq_len(n_f0))
    ped <- data.frame(
      id = c(founders_f, founders_m), dam = NA_character_, sire = NA_character_,
      stringsAsFactors = FALSE
    )
    gen1 <- do.call(rbind, lapply(seq_len(n_f0), function(i) {
      data.frame(
        id = paste0("g1_", i, "_", 1:2),
        dam = founders_f[i], sire = founders_m[i],
        stringsAsFactors = FALSE
      )
    }))
    ped <- rbind(ped, gen1)
    gen1_f <- gen1$id[seq(1, nrow(gen1), by = 2)]
    gen1_m <- gen1$id[seq(2, nrow(gen1), by = 2)]
    gen2 <- do.call(rbind, lapply(seq_len(n_f0), function(i) {
      j <- (i %% n_f0) + 1L
      data.frame(
        id = paste0("g2_", i, "_", 1:4),
        dam = gen1_f[i], sire = gen1_m[j],
        stringsAsFactors = FALSE
      )
    }))
    ped <- rbind(ped, gen2)
    gen2_f <- gen2$id[seq(1, nrow(gen2), by = 4)]
    gen2_m <- gen2$id[seq(2, nrow(gen2), by = 4)]
    half_f0 <- n_f0 %/% 2L
    gen3 <- do.call(rbind, lapply(seq_len(half_f0), function(i) {
      j <- i + half_f0
      data.frame(
        id = paste0("g3_", i, "_", 1:4),
        dam = gen2_f[i], sire = gen2_m[j],
        stringsAsFactors = FALSE
      )
    }))
    rbind(ped, gen3)
  }
  set.seed(seed)
  pedigree <- .build_animal_pedigree_40(n_founders)
  A <- drmTMB:::drm_pedigree_additive_relationship(pedigree)
  id_levels <- rownames(A)
  n_id <- length(id_levels)
  L <- t(chol(A))
  u_mu <- as.vector(L %*% stats::rnorm(n_id)) * true_sd_mu
  u_sigma <- as.vector(L %*% stats::rnorm(n_id)) * true_log_sd_sigma
  names(u_mu) <- id_levels
  names(u_sigma) <- id_levels
  id <- rep(id_levels, each = n_each)
  n <- length(id)
  sigma_tip <- exp(log_sigma0 + u_sigma[id])
  y <- mu0 + u_mu[id] + stats::rnorm(n, 0, sigma_tip)
  list(
    data = data.frame(
      y = y,
      id = factor(id, levels = id_levels)
    ),
    pedigree = pedigree,
    A = A,
    true_sd_mu = true_sd_mu,
    true_log_sd_sigma = true_log_sd_sigma
  )
}
