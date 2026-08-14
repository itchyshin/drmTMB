#!/usr/bin/env python3
"""Validate and generate drmTMB's capability ledger and public surfaces.

The ledger is authoritative. Generated census, JSON, Markdown, HTML, vignette
include, and tranche summaries must never be edited by hand.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import html
import json
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "docs/dev-log/dashboard/capability-ledger"
CELLS = LEDGER / "cells.tsv"
EVIDENCE = LEDGER / "evidence.tsv"
TRANSITIONS = LEDGER / "transitions.tsv"
SCHEMA = LEDGER / "schema.json"
CENSUS = ROOT / "docs/dev-log/dashboard/capability-census"
PARITY_TRIAGE = ROOT / "docs/dev-log/dashboard/parity-triage.tsv"
READER_SUMMARY = ROOT / "vignettes/includes/capability-ledger-summary.md"

# These are deliberately exact ledger cells, not per-family representatives.
# A family has multiple model-surface cells with different parameters,
# structures, estimators, and evidence. Keeping the reader table at cell grain
# makes each reporting permission auditable and prevents a model-surface claim
# from inheriting evidence from the association or missing-response axes.
READER_SUMMARY_SPECS = (
    {
        "cell_id": "mc-0001",
        "claim_boundary_sha256": "5bcfcd9f8a57837ce0891b554e0a897e2174a783bcacff98b393da0e2ffeae5f",
        "reader_route": "Beta location (`mu`) with fixed effects",
        "scope_caveat": (
            "An ML fixed-effect Beta location coefficient at tested sample sizes "
            "50, 150, or 500. Wald mean-coefficient intervals have calibration "
            "evidence in those designs; random effects, other parameters, other "
            "sample sizes, and other families are not covered."
        ),
        "interval_method": "Wald mean-coefficient interval",
        "fallback": (
            "For a different structure, use a fixed-effect `beta()` location "
            "model without `phylo()` or random terms."
        ),
    },
    {
        "cell_id": "mc-0061",
        "claim_boundary_sha256": "71c7e37a8b7aef178fc58cb15f2f27a8dd45cecf6a51c4b1bf964b0a25fbe1a4",
        "reader_route": "Binomial location (`mu`) random slope",
        "scope_caveat": (
            "Use the ML-Laplace profile interval only for a comparable design: "
            "32 or 64 groups, 12 observations per group, 12 trials per "
            "observation, and a clean `check_drm()` result with no profile "
            "boundary. In the calibration study, the true slope SD was 0.6 and "
            "coverage was 94.9% and 95.3%, with more upper- than lower-tail "
            "misses. Other group counts, replication, trial sizes, SD values, "
            "correlated or labelled slopes, and REML are not covered; state this "
            "calibration limit when reporting."
        ),
        "interval_method": "profile-likelihood interval",
        "fallback": (
            "Use a binomial model with a random intercept or fixed effect only "
            "when the tested random-slope design does not match the study."
        ),
    },
    {
        "cell_id": "mc-0436",
        "claim_boundary_sha256": "0faf5812e8165674ee406188f35513f277403b12c11ab15022145472eb989b7b",
        "reader_route": "Poisson phylogenetic location (`mu`) intercept and slope",
        "scope_caveat": (
            "An ML univariate `poisson()` location model with a phylogenetic intercept "
            "and slope; the two phylogenetic standard deviations and their "
            "intercept-slope correlation are recovery-backed. Other structured "
            "providers, scale structures, ordinary random effects, zero inflation, "
            "and all interval claims are outside scope."
        ),
        "interval_method": "",
        "fallback": (
            "Use a Poisson fixed-effect model or an ordinary random-intercept model "
            "when the phylogenetic slope structure is not essential."
        ),
    },
    {
        "cell_id": "mc-0418",
        "claim_boundary_sha256": "03b4da9807ec840e88e26f78d3bd6abab5cd40e421230bc4ecc19303d0a76d96",
        "reader_route": "Negative-binomial location (`mu`) phylogenetic intercept and slope",
        "scope_caveat": (
            "An ML univariate `nbinom2()` location model with an intercept-only "
            "dispersion formula (`sigma ~ 1`) and a phylogenetic intercept and "
            "slope; the two phylogenetic standard "
            "deviations and their intercept-slope correlation are recovery-backed. "
            "Other providers, scale structures, ordinary random effects, zero "
            "inflation, and all interval claims are outside scope."
        ),
        "interval_method": "",
        "fallback": (
            "Use an NB2 fixed-effect model or an ordinary random-intercept model "
            "when the phylogenetic slope structure is not essential."
        ),
    },
    {
        "cell_id": "mc-0544",
        "claim_boundary_sha256": "deaa78215792e213c158690a794dec3f92bcfb607e8abd298c565455b1bcea17",
        "reader_route": "Tweedie location (`mu`) with a phylogenetic random effect",
        "scope_caveat": (
            "A structured random effect on Tweedie location is rejected before "
            "covariance settings are evaluated; it is not a reportable drmTMB route."
        ),
        "interval_method": "",
        "fallback": (
            "Use a Tweedie fixed-effect model or an ordinary random-effect model "
            "without a phylogenetic covariance structure."
        ),
    },
    {
        "cell_id": "mc-0387",
        "claim_boundary_sha256": "e9b981a7ba05be6169f4e8514b7015d26d706f1ae4a60f460689e28eebe47711",
        "reader_route": "Lognormal location (`mu`) with an animal relatedness random effect",
        "scope_caveat": (
            "An animal relatedness random effect on lognormal location is rejected; "
            "it is not a reportable drmTMB route."
        ),
        "interval_method": "",
        "fallback": (
            "Use a lognormal fixed-effect model or an ordinary random-effect model "
            "without an animal relatedness covariance structure."
        ),
    },
    {
        "cell_id": "mc-0260m",
        "claim_boundary_sha256": "b96df4ca59c177c4c0c3392e457f28103ad5cfd43f1173fc40e7a5e80e7e66ae",
        "reader_route": "Gaussian pooled effect with `meta_V(V = V)`",
        "scope_caveat": (
            "An ML pooled effect with known sampling covariance for 48 studies. "
            "Point estimates agree with `metafor`, but one profile interval missed "
            "the known truth; no drmTMB interval, coverage, or heterogeneity "
            "interval claim is available."
        ),
        "interval_method": "profile-likelihood interval (withdrawn for reporting)",
        "fallback": (
            "Use `metafor::rma.uni()` or `metafor::rma.mv()` for the same "
            "known-covariance meta-analysis when an interval is required."
        ),
    },
    {
        "cell_id": "mc-0186",
        "claim_boundary_sha256": "8bc6137d2752e412ad80482f4a19f916d4b3ca1310c3c2c51b4c5c5dc3a4c453",
        "reader_route": "Bivariate Gaussian residual correlation (`rho12`) under REML",
        "scope_caveat": (
            "A REML bivariate-Gaussian residual-correlation interval at 150 "
            "observations is numerically well formed. Coverage and calibration "
            "have not been evaluated, so it is not a calibrated reporting claim."
        ),
        "interval_method": "profile-likelihood interval",
        "fallback": (
            "If a calibrated correlation interval is essential, use a simpler "
            "independent-response analysis or a separately validated correlation tool."
        ),
    },
)

# C14 restores the package-boundary classification from the last ledger commit
# that recorded it explicitly.  This is a taxonomy correction, not evidence for
# an implementation: the immutable source set is deliberately named here so a
# future rerun cannot infer boundaries from a broad formula heuristic.  The
# committed snapshot keeps the check portable when the historical local-only
# commit is not available to a fresh CI checkout.
C14_BOUNDARY_SOURCE_COMMIT = "0ccffcb539e19c3b4eeabf394634ddbcfc930cd8"
C14_BOUNDARY_SOURCE_PATH = "docs/dev-log/dashboard/capability-ledger/cells.tsv"
C14_BOUNDARY_SOURCE_SNAPSHOT = LEDGER / "c14-boundary-source.tsv"
C14_BOUNDARY_COUNT = 330
C14_ZOB_LEAF_TAXONOMY = (
    ("mc-0583", "mc-0695"), ("mc-0584", "mc-0696"),
    ("mc-0585", "mc-0697"), ("mc-0586", "mc-0698"),
    ("mc-0587", "mc-0699"), ("mc-0593", "mc-0700"),
    ("mc-0594", "mc-0701"), ("mc-0595", "mc-0702"),
    ("mc-0596", "mc-0703"), ("mc-0597", "mc-0704"),
)
C14_ZOB_LEAF_TAXONOMY_SOURCE = (
    "docs/dev-log/dashboard/capability-ledger/"
    "c14-zob-structured-leaf-taxonomy.md"
)
# C18 is a sibling split, not a mutation of C14's dated, receipt-bound
# taxonomy: the ten structured zero-one-beta ATOM rows (zoi/coi providers)
# were never part of C14's scope. Each pair below names an original
# not_implemented ATOM row and its new q2-plus boundary leaf.
C18_ZOB_ATOM_LEAF_TAXONOMY = (
    ("mc-0603", "mc-0705"), ("mc-0604", "mc-0706"),
    ("mc-0605", "mc-0707"), ("mc-0606", "mc-0708"),
    ("mc-0607", "mc-0709"), ("mc-0613", "mc-0710"),
    ("mc-0614", "mc-0711"), ("mc-0615", "mc-0712"),
    ("mc-0616", "mc-0713"), ("mc-0617", "mc-0714"),
)
C18_ZOB_ATOM_LEAF_TAXONOMY_SOURCE = (
    "docs/dev-log/dashboard/capability-ledger/"
    "c18-zob-atom-leaf-taxonomy.md"
)
C14_RECEIPT_EQUIVALENCE = LEDGER / "c14-receipt-equivalence.tsv"
C14_RECEIPT_EQUIVALENCE_TARGET = "e58d77119c3562cdfcede3191f2482b38b30f4af"
C14_RECEIPT_EQUIVALENCE_FINGERPRINT = (
    "854d09453a44610c4d699bbb442331634b93852c2aecd024e45892904052470b"
)
C14_RECEIPT_EQUIVALENCE_PATHS = (
    "R/drmTMB.R::zero_one_beta_spec",
    "R/drmTMB.R::zero_one_beta_start_and_map",
    "R/drmTMB.R::zero_one_beta_tmb_and_extractors",
    "src/drmTMB.cpp::model_type_15",
)
C17_C14_CURRENT_SOURCE_COMPATIBILITY = (
    LEDGER / "2026-08-08-c17c2-c14-final-source-compatibility.tsv"
)
C17_C14_COMPATIBLE_SEEDS = {
    "mc-0568": {str(seed) for seed in range(2026073401, 2026073405)},
    "mc-0569": {str(seed) for seed in range(2026073501, 2026073505)},
    "mc-0576": {str(seed) for seed in range(2026073701, 2026073705)},
}
C17_C14_SOURCE_FILES = (
    "R/drmTMB.R",
    "R/methods.R",
    "src/drmTMB.cpp",
    "tests/testthat/test-zero-one-beta.R",
    "tools/run-lane-c-c17c1-c14-model15-compatibility.R",
)

# The 0.7 capability-truth reconciliation corrects two false-negative C14
# taxonomy rows after the already-landed binomial O2 implementation was found
# to admit and deterministically match ordinary random-intercept and
# independent random-slope REML fits.  The historical C14 snapshot remains
# immutable; these are the only source-pinned boundary IDs allowed to be
# overridden, and validate() binds their exact evidence and state below.
CAPABILITY_TRUTH_C14_IMPLEMENTED_OVERRIDES = {"mc-0060", "mc-0062"}
CAPABILITY_TRUTH_CELL_IDS = {
    "mc-0058", "mc-0060", "mc-0062", "mc-0068", "mc-0227",
}
CAPABILITY_TRUTH_DATE = "2026-08-08"
INTERNAL_ONLY_ESTIMATOR_EVIDENCE_IDS = {"ev-mc-0227-o3"}

DATE = "2026-07-14"
IMPORTED_MODEL_COUNT = 668
# 676 frozen census rows + mc-0260m, the meta_V route row landed 2026-07-25 from the
# approved draft docs/dev-log/handover/2026-07-21-mc-0260m-ledger-cell-draft.md. The row
# is an insert at the tier its evidence already supports (point_fit_recovery); nothing was
# promoted. C14 then split ten lossy structured zero-one-beta mu/sigma rows into exact
# q1 leaves plus ten new q2-plus boundary rows (677 -> 687). C18 splits ten further lossy
# structured zero-one-beta ATOM (zoi/coi) rows the same source-bound, non-promoting way,
# appending ten more q2-plus boundary rows (687 -> 697). Arc 4b then splits mc-0207 (a
# single legacy row representing q4/q6/q8 ordinary bivariate REML blocks with no unique
# formula/target) into exact per-q leaves: mc-0207 becomes the q4 leaf in place, and
# mc-0715 (q6) / mc-0716 (q8) are new leaves (697 -> 699). The split promotes nothing.
# Bump this guard only for an approved row insert or split, never to silence drift.
MODEL_SURFACE_COUNT = 699
ASSOCIATION_COUNT = 6
# 2026-08-09 systems-audit seeding: the first missing_predictor axis rows.
# One row per (response family x predictor family) cell actually admitted by
# drm_missing_predictor_families() (R/missing-data.R:366-368) and its use sites
# (R/drmTMB.R:277-296): 13 cells for the gaussian() response x its 13-family
# impute_model() catalogue (gaussian itself plus 12 non-Gaussian predictor
# families), and 4 cells for the poisson()/binomial()/nbinom2()/beta() responses,
# each admitting only one binary (bernoulli) missing predictor. Bump this guard
# only for an approved row insert, never to silence drift.
MISSING_PREDICTOR_COUNT = 17
# The frozen 2026-07-09 census: the original 676 model_surface rows and their
# recovery tier. C12 promoted mc-0653, then the approved canonical Lane-C
# count tranche promoted mc-0418, mc-0425, mc-0436, mc-0446, mc-0450, and
# mc-0454. With explicit user approval, C14 promotes only mc-0568, mc-0569,
# and mc-0576 after source-equivalence verification and fresh three-lens GO.
# B4-CI C1, C2, C3, then C4 promote only their approved source-bound cells.
# C4 moves eleven frozen point-fit cells and twelve diagnostic-only cells; this
# is not a blanket re-baseline. Arc 1 subsequently promotes only five exact
# targets after three current-source Totoro receipts per target: mc-0260,
# mc-0262, mc-0260m's pooled effect, mc-0266's residual-scale RE SD, and
# mc-0269's Gaussian REML independent random-slope SD.
# Arc 2 then promotes exactly three more frozen cells, each after three
# current-source Totoro receipts reconciled 3/3 against the same one-profile
# contract: mc-0186's bivariate REML rho12, mc-0263's heteroscedastic
# sigma ~ x fixed effect, and mc-0274's phylogenetic mean random-intercept SD.
# Arc 2 then adds mc-0277 on a REPLACEMENT fixture. The manifest had prescribed
# a mean-only phylogenetic DGP, under which the true sigma-phylo SD is exactly
# zero, so its profile hit the [0, Inf) boundary by construction -- a null-case
# artifact, not a capability limit. Re-run on a signal-bearing DGP
# (arc2_phylo_sigma_fixture, true log-SD 0.7) it satisfies the same contract 3/3.
# Arc 2 finally adds mc-0013 and mc-0015 (Beta x animal() SD targets) after
# REBUILDING their fixtures on a 40-individual pedigree; the original
# 8-individual design recovered the slope SD at roughly half its true value.
# 77 -> 71 records exactly those six; ARC2_TARGETS below binds each one to
# its exact target, evidence row, and transition, so a seventh silent promotion
# still fails this guard.
# seven exact q1 structured zero-one-beta ATOM (zoi/coi) leaves after
# source-bound four-seed local recovery, a per-group separation filter,
# and fresh three-lens GO following repair of the D-43 panel's three
# blocking defects (mc-0603, mc-0604, mc-0605, mc-0607, mc-0613, mc-0614,
# mc-0617; mc-0615 stays not_implemented/backlog after a documented
# BLOCKED_LOCAL_FIXTURE attempt).
# Arc 2 moved six frozen cells OUT of point_fit_recovery into
# interval_feasible (77 -> 71) while C18 moved seven IN; the merged
# frozen-census total is derived from cells.tsv, not from either lane's
# arithmetic in isolation.
FROZEN_CENSUS_COUNT = 676
# Arc 3 then promotes three more frozen cells, each after a PREDECLARED POINT-FIT
# RECOVERY GATE and three reconciled Totoro receipts: mc-0283's matched-q2
# phylogenetic log-sigma SD, and mc-0422/mc-0423's nbinom2 spatial and animal
# log-sigma SDs on purpose-built provider-specific DGPs. mc-0421 and mc-0424 were
# NOT promoted -- each passed only 2 of 3 seeds and is retained at
# point_fit_recovery on their FIRST cohort. Both were then root-caused as DGP
# numerical-conditioning defects (not estimator defects), redesigned, re-gated
# over five seeds, and re-run: the same previously-failing seed now passes, so
# both are promoted here too. 78 -> 73 after rebasing onto main's new baseline; ARC3_TARGETS binds each promoted cell.
# mc-0321 (gaussian mu-side phylo_interaction SD) then passes Fisher's tightened
# five-seed, truth-bracketing gate (seed family 2026080401-2026080405) 5/5: every
# relative error <0.35 and every profile interval brackets the true 0.6. Its NB2
# sibling mc-0409 (same exact target and geometry) was initially NOT promoted
# under the same gate -- seed 2026080405's interval excluded the true 0.6 despite
# passing the mean-error gate and the mechanical reconciler. A follow-up
# diagnostic found a confirmed NB2 dispersion/interaction-SD confound
# (cor(sigma_hat, sd_hat) = -0.74 at n_each = 8, no count sparsity); raising
# n_each 8 -> 24 fixed it, and a re-run five-seed Totoro campaign (same shared
# seed family) now passes both the relative-error and bracketing checks on
# every seed, so mc-0409 is promoted here too. 73 -> 72.
# Arc 4b then DEMOTES mc-0207 (still frozen: source_order 207 <= 676) from
# point_fit_recovery to none. mc-0207 was a single legacy row claiming q4/q6/q8
# bivariate ordinary REML blocks are recoverable, citing only
# scratchpad/reml_parity_gaps_3A_ladder.R -- but that ladder tests a q2
# bivariate mu-sigma block (mc-0205/mc-0206's territory) and a q3 UNIVARIATE
# mu-only block, never a bivariate mu1+mu2 q4/q6/q8 block. Splitting the row
# into its three per-q leaves (mc-0207/mc-0715/mc-0716) exposes that none of
# them has dimension-matched evidence, so all three are born/kept at
# evidence_tier=none pending a matching recovery fixture. 72 -> 71 in this
# lane alone.
# Arc 4 then promotes mc-0417 (the two-provider AGGREGATE count cell, BOUND to
# its ONE pair with recovery evidence -- spatial+relmat) on its primary
# target sd:mu:spatial(1 | site): a five-seed Totoro campaign (shared seed
# family 2026080501-2026080505, the same family as the local point-fit gate)
# passes both the relative-error (<0.35 every seed) and truth-bracketing
# checks on every seed. 72 -> 71 in this lane alone.
# Arc 4b's demotion and Arc 4's promotion land in the same merge and both
# apply, one frozen cell moving out of point_fit_recovery each: the merged
# frozen-census total is derived from cells.tsv, not from either lane's
# arithmetic in isolation. 72 -> 70.
# Arc 5 then promotes the final three Prong A cells on top of that merged
# baseline of 70: mc-0123 (q6 spatial mu1 SD, the sibling of mc-0124's
# already-promoted mu2 SD, on an independent fixture) and mc-0205/mc-0206
# (the mu1/sigma1 marginal SDs of ONE labelled bivariate REML `(1 | p | id)`
# mu-sigma correlated block, on a fixture that replaces the point-estimate-only
# sim3() harness). None of the three overlaps the mc-0207/mc-0715/mc-0716
# split cells. All three pass Fisher's tightened five-seed, truth-bracketing
# gate 5/5. 70 -> 67 (derived from the merged cells.tsv, not assumed).
# Arc 6 then promotes nine more frozen Gaussian structured cells on top of
# that merged baseline of 67, after five-seed Totoro campaigns (shared base
# commit 75b212cf9db45aeb2fa3181049e663e772e01e7a) that bracket the truth on
# every seed: mc-0286/mc-0298 (q1 one-slope mu spatial/animal, ML), mc-0282
# (q2 matched mu phylo, REML), mc-0291/mc-0303/mc-0315 (q2 matched mu
# spatial/animal/relmat, ML, labelled provider(1 | p | group) spelling), and
# mc-0279/mc-0304/mc-0316 (q2 matched sigma phylo/animal/relmat, ML, unlabelled
# auto-linked spelling). A tenth sibling, mc-0292 (q2 matched sigma spatial), was
# WITHHELD: its seed-303 receipt (estimate 0.53386, interval [0.40397, 0.69375])
# excludes the true 0.7, so 4/5 not 5/5 seeds bracket the truth. The mechanical
# reconciler (tools/arc2_profile_reconcile.py) still recorded PASS_INTERVAL_FEASIBLE_
# TARGET for that seed, because reconcile() never reads a true value -- only a human
# check against the DGP's known truth caught this. None of the nine overlaps the
# mc-0207/mc-0715/mc-0716 split cells or Arc 5's three. 67 -> 58 (derived from the
# merged cells.tsv, not assumed).
#
# Arc 7b: 58 -> 59. mc-0424 fell back from interval_feasible to point_fit_recovery
# when the truth gate (tools/profile_truth_gate.py) was installed: its seed
# 2026080301 interval [0.257, 0.516] excludes the DGP's true 0.55 by 6.3%. Its
# point-fit evidence is untouched, so it lands one rung down rather than at none.
# mc-0260m demoted in the same change but is source_order 694, outside this
# frozen <=676 window, so it does not move this constant. The gap the note above
# describes -- "reconcile() never reads a true value" -- is now closed
# mechanically; that is what found these two.
FROZEN_CENSUS_POINT_FIT_RECOVERY = 55
ARC1_GAUSSIAN_FIXED_SOURCE_SHA = "c8e04258d9d550384b037b1e2a91734c22aaaab5"
ARC1_GAUSSIAN_FIXED_TARGETS = {
    "mc-0260": "mc-0260::fixef:mu:x",
    "mc-0262": "mc-0262::fixef:sigma:x",
}
ARC1_GAUSSIAN_FIXED_RECONCILIATION = (
    "docs/dev-log/interval-feasibility/results/"
    f"{ARC1_GAUSSIAN_FIXED_SOURCE_SHA}/"
    "arc1-gaussian-fixed-profile-feasibility/totoro/reconciliation.tsv"
)
# mc-0260m was removed from this dict in Arc 7b. The loop below asserts that
# every member still holds evidence_tier=interval_feasible, and mc-0260m no
# longer does: its retained seed 2026080233 interval [0.234, 0.423] excludes the
# meta_V DGP's true pooled mean of 0.20 by 16.8%. Its metafor parity evidence is
# unaffected, so it sits at point_fit_recovery. See
# docs/dev-log/dashboard/parity-triage.tsv for the corrected supersession text.
ARC1_ADDITIONAL_TARGETS = {
    "mc-0266": {
        "target_id": "mc-0266::sd:sigma:(1 | id)",
        "evidence_id": "ev-mc-0266-arc1-sigma-re-profile",
        "transition_id": "tr-mc-0266-arc1-sigma-re-profile",
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC1_GAUSSIAN_FIXED_SOURCE_SHA}/"
            "arc1-gaussian-sigma-re-profile-feasibility/totoro/reconciliation.tsv"
        ),
    },
    "mc-0269": {
        "target_id": "mc-0269::sd:mu:(0 + x | id)",
        "evidence_id": "ev-mc-0269-arc1-reml-slope-profile",
        "transition_id": "tr-mc-0269-arc1-reml-slope-profile",
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC1_GAUSSIAN_FIXED_SOURCE_SHA}/"
            "arc1-gaussian-reml-slope-profile-feasibility/totoro/reconciliation.tsv"
        ),
    },
}
ARC2_SOURCE_SHA = "83055ec5846bc2f9b1d939c13aa16c4500181f04"
# Later lane commit: the mc-0013/mc-0015 rebuild on a 40-individual pedigree.
ARC2_BETA_ANIMAL_SOURCE_SHA = "43b4b2a74ee26869cfc785d95ab26df5973ccc45"
ARC2_TARGETS = {
    "mc-0186": {
        "target_id": "mc-0186::rho12",
        "evidence_id": "ev-mc-0186-arc2-rho12-profile",
        "transition_id": "tr-mc-0186-arc2-rho12-profile",
        "claim_snippet": "biv_reml_fixture(n=150)",
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC2_SOURCE_SHA}/"
            "arc2-profile-feasibility/totoro/mc-0186-reconcile.tsv"
        ),
    },
    "mc-0263": {
        "target_id": "mc-0263::fixef:sigma:x",
        "evidence_id": "ev-mc-0263-arc2-sigma-fixef-profile",
        "transition_id": "tr-mc-0263-arc2-sigma-fixef-profile",
        "claim_snippet": "reml_hetero_fixture()",
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC2_SOURCE_SHA}/"
            "arc2-profile-feasibility/totoro/mc-0263-reconcile.tsv"
        ),
    },
    "mc-0274": {
        "target_id": "mc-0274::sd:mu:phylo(1 | species)",
        "evidence_id": "ev-mc-0274-arc2-phylo-mu-sd-profile",
        "transition_id": "tr-mc-0274-arc2-phylo-mu-sd-profile",
        "claim_snippet": "reml_phylo_location_fixture(n_tip=30, n_each=3)",
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC2_SOURCE_SHA}/"
            "arc2-profile-feasibility/totoro/mc-0274-reconcile.tsv"
        ),
    },
    # mc-0277 is bound to the REPLACEMENT signal-bearing fixture, not the
    # manifest's mean-only prescription. The claim_snippet pins that fixture so
    # the claim cannot silently drift back to the signal-free DGP, under which
    # the profile hits the variance-component boundary by construction.
    "mc-0277": {
        "target_id": "mc-0277::sd:sigma:phylo(1 | species)",
        "evidence_id": "ev-mc-0277-arc2-phylo-sigma-sd-profile",
        "transition_id": "tr-mc-0277-arc2-phylo-sigma-sd-profile",
        "claim_snippet": "arc2_phylo_sigma_fixture(n_tip=60, n_each=12)",
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC2_SOURCE_SHA}/"
            "arc2-profile-feasibility/totoro/mc-0277/mc-0277-reconcile.tsv"
        ),
    },
    # mc-0013 and mc-0015 were re-run on a REBUILT 40-individual pedigree. The
    # original 8-individual design recovered the mc-0013 slope SD at ~0.28
    # against a true 0.55 (~49% error), which Rose ruled not promotable. The
    # rebuild recovers at 14.4% and 7.7% mean relative error over five seeds.
    # Their receipts therefore come from a later lane commit than the first four.
    "mc-0013": {
        "target_id": "mc-0013::sd:mu:animal(0 + x | id)",
        "evidence_id": "ev-mc-0013-arc2-beta-animal-mu-slope-profile",
        "transition_id": "tr-mc-0013-arc2-beta-animal-mu-slope-profile",
        "claim_snippet": "beta_animal_mu_slope_fixture",
        "source_sha": ARC2_BETA_ANIMAL_SOURCE_SHA,
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC2_BETA_ANIMAL_SOURCE_SHA}/"
            "arc2-profile-feasibility/totoro/mc-0013-reconcile.tsv"
        ),
    },
    "mc-0015": {
        "target_id": "mc-0015::sd:sigma:animal(1 | id)",
        "evidence_id": "ev-mc-0015-arc2-beta-animal-sigma-profile",
        "transition_id": "tr-mc-0015-arc2-beta-animal-sigma-profile",
        "claim_snippet": "beta_animal_sigma_intercept_fixture",
        "source_sha": ARC2_BETA_ANIMAL_SOURCE_SHA,
        "reconciliation": (
            "docs/dev-log/interval-feasibility/results/"
            f"{ARC2_BETA_ANIMAL_SOURCE_SHA}/"
            "arc2-profile-feasibility/totoro/mc-0015-reconcile.tsv"
        ),
    },
}
ARC3_SOURCE_SHA = "a34bb75092c7733e5d65e4bf427895b4318ced7c"
ARC3_TARGETS = {
    "mc-0283": {
        "target_id": "mc-0283::sd:sigma:sigma:phylo(1 | p | species)",
        "evidence_id": "ev-mc-0283-arc3-profile",
        "transition_id": "tr-mc-0283-arc3-profile",
        "claim_snippet": "arc2_phylo_sigma_q2_fixture(n_tip=60, n_each=12)",
    },
    "mc-0422": {
        "target_id": "mc-0422::sd:sigma:spatial(1 | site)",
        "evidence_id": "ev-mc-0422-arc3-profile",
        "transition_id": "tr-mc-0422-arc3-profile",
        "claim_snippet": "arc3_nbinom2_sigma_spatial_fixture",
    },
    "mc-0421": {
        "target_id": "mc-0421::sd:sigma:phylo(1 | species)",
        "evidence_id": "ev-mc-0421-arc3-profile",
        "transition_id": "tr-mc-0421-arc3-profile",
        "claim_snippet": "arc3_nbinom2_sigma_phylo_fixture",
    },
    # mc-0424 was removed from this dict in Arc 7b, for the same reason mc-0409
    # (below) was once withheld and the same reason mc-0423 still is: its seed
    # 2026080301 profile interval [0.257, 0.516] excludes the true 0.55. mc-0409
    # was caught by a human; mc-0424 was not, and shipped as interval_feasible.
    # tools/profile_truth_gate.py now makes that check mechanical.
    "mc-0321": {
        "target_id": "mc-0321::sd:mu:phylo_interaction(1 | plant:pollinator)",
        "evidence_id": "ev-mc-0321-arc3-profile",
        "transition_id": "tr-mc-0321-arc3-profile",
        "claim_snippet": "arc3_phylo_interaction_gaussian_fixture",
    },
    # mc-0409 (NB2 sibling, same exact target/geometry) was initially withheld:
    # seed 2026080405's profile interval excluded the true 0.6 at n_each = 8
    # despite a passing mean relative error. A diagnosed NB2 dispersion/
    # interaction-SD confound (cor(sigma_hat, sd_hat) = -0.74) was fixed by
    # raising n_each 8 -> 24; a re-run five-seed campaign passes both the
    # relative-error and bracketing checks on every seed -- see cells.tsv's
    # mc-0409 claim_boundary.
    "mc-0409": {
        "target_id": "mc-0409::sd:mu:phylo_interaction(1 | plant:pollinator)",
        "evidence_id": "ev-mc-0409-arc3-profile",
        "transition_id": "tr-mc-0409-arc3-profile",
        "claim_snippet": "arc3_phylo_interaction_nbinom2_fixture",
    },
}
# mc-0417 is an AGGREGATE cell ("exactly two intercept-only providers drawn
# from {phylo, spatial, animal, relmat} ... may co-occur as primary+secondary
# q1 fields", C(4,2) = 6 possible pairs). Boole's BIND decision pins it to the
# ONE pair with recovery evidence on record -- spatial+relmat -- rather than
# splitting into six pair-specific cells. A five-seed Totoro campaign on the
# BIND-selected pair's primary target (sd:mu:spatial(1 | site)) satisfies
# Fisher's tightened truth-bracketing gate 5/5 (shared seed family
# 2026080501-2026080505, the same family used for the local point-fit gate);
# the other five provider pairs remain unevaluated and the companion
# relmat(1 | id) SD is surfaced but not part of this claim.
ARC4_SOURCE_SHA = "095b9e3b1933f9b066365f92ddd4cb3d412a9dad"
ARC4_TARGETS = {
    "mc-0417": {
        "target_id": "mc-0417::sd:mu:spatial(1 | site)",
        "evidence_id": "ev-mc-0417-arc4-profile",
        "transition_id": "tr-mc-0417-arc4-profile",
        "claim_snippet": "arc4_nbinom2_mu_spatial_relmat_fixture",
    },
}
# Arc 5 promotes the final three Prong A cells: mc-0123 (the mu1 sibling of
# mc-0124's already-promoted q6 spatial mu2 SD, on an INDEPENDENT fixture
# because B3's own runner is unreachable from this tree), and mc-0205/
# mc-0206 (the mu1/sigma1 marginal SDs of ONE labelled bivariate REML
# `(1 | p | id)` mu-sigma correlated block, on a committed fixture that
# REPLACES sim3() -- sim3() returned point estimates only and could never
# support an interval claim). All three share the SAME source commit as
# Arc 4 (the checkout both lanes' worktrees were built from) and Fisher's
# tightened five-seed, truth-bracketing gate: every seed's relative error
# <0.35 and every profile interval brackets the true value. 71 -> 68 in
# this lane alone (70 -> 67 once merged with Arc 4b's mc-0207 split, see
# FROZEN_CENSUS_POINT_FIT_RECOVERY above).
ARC5_SOURCE_SHA = "095b9e3b1933f9b066365f92ddd4cb3d412a9dad"
ARC5_TARGETS = {
    "mc-0123": {
        "target_id": "mc-0123::sd:mu:mu1:spatial(1 | p | site)",
        "evidence_id": "ev-mc-0123-arc5-profile",
        "transition_id": "tr-mc-0123-arc5-profile",
        "claim_snippet": "arc4_q6_spatial_mu1_fixture",
    },
    "mc-0205": {
        "target_id": "mc-0205::sd:mu:mu1:(1 | p | id)",
        "evidence_id": "ev-mc-0205-arc5-profile",
        "transition_id": "tr-mc-0205-arc5-profile",
        "claim_snippet": "arc2_biv_musigma_fixture(n_id=60, n_each=8)",
    },
    "mc-0206": {
        "target_id": "mc-0206::sd:sigma:sigma1:(1 | p | id)",
        "evidence_id": "ev-mc-0206-arc5-profile",
        "transition_id": "tr-mc-0206-arc5-profile",
        "claim_snippet": "arc2_biv_musigma_fixture(n_id=60, n_each=8)",
    },
}
# Arc 6 consolidates nine Fisher-approved Gaussian structured cells from three
# parallel lanes (q1 one-slope mu, q2 matched mu, q2 matched sigma) into one
# promotion. All nine share ARC6_SOURCE_SHA -- the merge-base commit the
# five-seed Totoro campaigns were run against -- and all nine bracket the true
# parameter on every one of five seeds. A tenth sibling in the same q2 matched
# sigma group, mc-0292 (spatial), was WITHHELD after independent verification:
# its seed-303 receipt (estimate 0.53386, interval [0.40397, 0.69375]) excludes
# the true 0.7. mc-0292's registry entries are deliberately absent from
# tools/run-arc2-profile-feasibility.R and tools/arc2_profile_reconcile.py.
ARC6_SOURCE_SHA = "75b212cf9db45aeb2fa3181049e663e772e01e7a"
ARC6_TARGETS = {
    "mc-0286": {
        "target_id": "mc-0286::sd:mu:spatial(1 | site)",
        "evidence_id": "ev-mc-0286-arc6-profile",
        "transition_id": "tr-mc-0286-arc6-profile",
        "claim_snippet": "arc5_gaussian_ml_spatial_mu_one_slope_sd",
    },
    "mc-0298": {
        "target_id": "mc-0298::sd:mu:animal(1 | id)",
        "evidence_id": "ev-mc-0298-arc6-profile",
        "transition_id": "tr-mc-0298-arc6-profile",
        "claim_snippet": "arc5_gaussian_ml_animal_mu_one_slope_sd",
    },
    "mc-0282": {
        "target_id": "mc-0282::sd:mu:mu:phylo(1 | p | species)",
        "evidence_id": "ev-mc-0282-arc6-profile",
        "transition_id": "tr-mc-0282-arc6-profile",
        "claim_snippet": "arc2_gaussian_reml_phylo_mu_q2_sd",
    },
    "mc-0291": {
        "target_id": "mc-0291::sd:mu:mu:spatial(1 | p | site)",
        "evidence_id": "ev-mc-0291-arc6-profile",
        "transition_id": "tr-mc-0291-arc6-profile",
        "claim_snippet": "arc2_gaussian_ml_spatial_mu_q2_sd",
    },
    "mc-0303": {
        "target_id": "mc-0303::sd:mu:mu:animal(1 | p | id)",
        "evidence_id": "ev-mc-0303-arc6-profile",
        "transition_id": "tr-mc-0303-arc6-profile",
        "claim_snippet": "arc2_gaussian_ml_animal_mu_q2_sd",
    },
    "mc-0315": {
        "target_id": "mc-0315::sd:mu:mu:relmat(1 | p | id)",
        "evidence_id": "ev-mc-0315-arc6-profile",
        "transition_id": "tr-mc-0315-arc6-profile",
        "claim_snippet": "arc2_gaussian_ml_relmat_mu_q2_sd",
    },
    "mc-0279": {
        "target_id": "mc-0279::sd:sigma:sigma:phylo(1 | species)",
        "evidence_id": "ev-mc-0279-arc6-profile",
        "transition_id": "tr-mc-0279-arc6-profile",
        "claim_snippet": "arc2_gaussian_ml_phylo_sigma_q2_nolabel_sd",
    },
    "mc-0304": {
        "target_id": "mc-0304::sd:sigma:sigma:animal(1 | id)",
        "evidence_id": "ev-mc-0304-arc6-profile",
        "transition_id": "tr-mc-0304-arc6-profile",
        "claim_snippet": "arc2_gaussian_ml_animal_sigma_q2_nolabel_sd",
    },
    "mc-0316": {
        "target_id": "mc-0316::sd:sigma:sigma:relmat(1 | id)",
        "evidence_id": "ev-mc-0316-arc6-profile",
        "transition_id": "tr-mc-0316-arc6-profile",
        "claim_snippet": "arc2_gaussian_ml_relmat_sigma_q2_nolabel_sd",
    },
}
# 135-trace Prong B campaign: five of fourteen candidate cells cleared the
# ten-clause contract on Totoro (source SHA below). Nine siblings withheld
# (mc-0593/0594/0597, five q2 labelled-mu cells, mc-0425). Census move is
# +5 only: model_surface interval_feasible 182→187; frozen PFR 59→54.
ARC135_SOURCE_SHA = "6618e4b30303f7815b272f709ac2c8d09089132d"
ARC135_TARGETS = {
    "mc-0568": {
        "target_id": "mc-0568::sd:sigma:(1 | id)",
        "evidence_id": "ev-mc-0568-135trace-profile",
        "transition_id": "tr-mc-0568-135trace-profile",
        "claim_snippet": "zero_one_beta ordinary sigma intercept q1",
    },
    "mc-0576": {
        "target_id": "mc-0576::sd:sigma:(0 + x | id)",
        "evidence_id": "ev-mc-0576-135trace-profile",
        "transition_id": "tr-mc-0576-135trace-profile",
        "claim_snippet": "zero_one_beta ordinary sigma slope q1",
    },
    "mc-0595": {
        "target_id": "mc-0595::sd:sigma:relmat(1 | species)",
        "evidence_id": "ev-mc-0595-135trace-profile",
        "transition_id": "tr-mc-0595-135trace-profile",
        "claim_snippet": "zero_one_beta sigma relmat q1",
    },
    "mc-0596": {
        "target_id": "mc-0596::sd:sigma:spatial(1 | site)",
        "evidence_id": "ev-mc-0596-135trace-profile",
        "transition_id": "tr-mc-0596-135trace-profile",
        "claim_snippet": "zero_one_beta sigma spatial q1",
    },
    "mc-0653": {
        "target_id": "mc-0653::sd:sigma:phylo_interaction(1 | plant:pollinator)",
        "evidence_id": "ev-mc-0653-135trace-profile",
        "transition_id": "tr-mc-0653-135trace-profile",
        "claim_snippet": "zi_nbinom2 sigma phylo_interaction q1",
    },
}
# Deliberately withheld 135-trace siblings — must stay below interval_feasible.
ARC135_WITHHELD = {
    "mc-0593",
    "mc-0594",
    "mc-0597",
    "mc-0418",
    "mc-0436",
    "mc-0446",
    "mc-0450",
    "mc-0454",
    "mc-0425",
}
B3_Q6_MU2_RUNNER_SHA = "a8d068e641105473b3f30723a92c909467a46fac"
B3_Q6_MU2_TARGETS = {
    "mc-0102": ("phylo", "mc-0101", "mc-0102::sd:mu:mu2:phylo(1 | p | species)"),
    "mc-0124": ("spatial", "mc-0123", "mc-0124::sd:mu:mu2:spatial(1 | p | site)"),
    "mc-0146": ("animal", "mc-0145", "mc-0146::sd:mu:mu2:animal(1 | p | id)"),
    "mc-0168": ("relmat", "mc-0167", "mc-0168::sd:mu:mu2:relmat(1 | p | id)"),
}
# C4 separately promotes these three paired q6 mu1 rows.  Arc 5 separately
# promotes a fourth, mc-0123, on its own INDEPENDENT fixture (B3's own
# runner is unreachable from this tree). The B3 target receipt remains
# limited to mu2 and must not be treated as any of these four rows' evidence.
C4_B3_PAIRED_MU1_IDS = {"mc-0101", "mc-0145", "mc-0167", "mc-0123"}
B3_Q6_MU2_PACKET = (
    ROOT / "docs/dev-log/evidence/2026-08-01-b3-q6-target-promotion-packet.tsv"
)
MODEL_FIELDS = [
    "family", "model_type", "dpar", "effect_type", "structure_provider",
    "dimension", "q_gate", "estimator", "status", "evidence_tier",
    "evidence_source", "notes",
]
CELL_FIELDS = [
    "cell_id", "source_order", "axis", "family_route", "family_type",
    "model_type", "route_variant", "route_modifier", "dpar", "effect_type",
    "structure_provider", "dimension", "q_gate", "estimator",
    "capability_status", "work_status", "evidence_tier", "test_gate",
    "tranche_id", "owner", "blocking_reviewers", "primary_evidence_id",
    "claim_boundary", "next_gate", "issue_url", "pr_url", "updated_commit",
    "updated_date", "legacy_evidence_source", "notes",
    # Provenance keys (Transfer C of #1015). Appended, so every pre-existing
    # column keeps its position for `awk -F'\t'` consumers. These are keys, not
    # prose: #1011 showed free text in a ledger row rots silently because no
    # join can see what it asserts. A citation records provenance; it is not a
    # correctness certificate, so none of these promote a claim.
    "source_citation", "provenance_relation", "assumption_anchor",
    "comparator_bridge",
]
EVIDENCE_FIELDS = [
    "evidence_id", "cell_id", "evidence_class", "path_or_url", "commit_sha",
    "run_id", "command", "result", "replicates", "reviewed_by",
    "review_date", "claim_boundary",
]
TRANSITION_FIELDS = [
    "transition_id", "cell_id", "from_work_status", "to_work_status",
    "evidence_ids", "reason", "actor", "commit_sha", "date",
]

ROUTES = [
    (1, "gaussian", "gaussian", "base", "MR-T1"),
    (2, "biv_gaussian", "biv_gaussian", "base", "MR-T1"),
    (3, "student", "student", "base", "MR-T2"),
    (4, "lognormal", "lognormal", "base", "MR-T2"),
    (5, "gamma", "gamma", "base", "MR-T2"),
    (6, "poisson", "poisson", "base", "MR-T1"),
    (7, "nbinom2", "nbinom2", "base", "MR-T1"),
    (8, "zi_poisson", "poisson", "zi", "MR-T6"),
    (9, "zi_nbinom2", "nbinom2", "zi", "MR-T6"),
    (10, "beta", "beta", "base", "MR-T1"),
    (11, "truncated_nbinom2", "truncated_nbinom2", "base", "MR-T5"),
    (12, "hurdle_nbinom2", "truncated_nbinom2", "hu", "MR-T6"),
    (13, "cumulative_logit", "cumulative_logit", "base", "MR-T4"),
    (14, "beta_binomial", "beta_binomial", "base", "MR-T4"),
    (15, "zero_one_beta", "zero_one_beta", "base", "MR-T3"),
    (16, "tweedie", "tweedie", "base", "MR-T3"),
    (17, "skew_normal", "skew_normal", "base", "MR-T2"),
    (18, "binomial", "binomial", "base", "MR-T1"),
]
ADMITTED = {
    "gaussian", "biv_gaussian", "student", "lognormal", "gamma", "poisson",
    "nbinom2", "beta", "zero_one_beta", "tweedie", "beta_binomial",
    "cumulative_logit", "skew_normal", "binomial", "truncated_nbinom2",
    "zi_poisson", "zi_nbinom2", "hurdle_nbinom2",
}

WORK_STATUSES = {
    "backlog", "designed", "in_progress", "implemented_unverified",
    "verified", "blocked", "deferred",
}
CAPABILITY_STATUSES = {
    "not_implemented", "rejected_by_design", "scaffolded", "implemented",
}
TEST_GATES = {"na", "G0", "G1", "G2", "G3", "G4", "G5"}
# How this route's code relates to its cited source. Constrained for the same
# reason EVIDENCE_CLASSES is: an unconstrained field accepts a typo and still
# passes --check. "none" is a first-class answer and is the default; a route
# with no literature source is not thereby suspect.
PROVENANCE_RELATIONS = {
    "none", "direct_implementation", "adaptation", "independent_derivation",
}
# evidence_class was previously unconstrained, so a typo silently produced zero badges
# and a green --check. external_comparator is the newest member: agreement with an
# independent implementation. Adding a class here is deliberate; it is not a free-text field.
EVIDENCE_CLASSES = {
    "legacy_model_evidence", "model_recovery", "rejection_test", "recovery_test",
    "g2_contract_test", "contract_test", "coverage_study", "admission_test",
    "estimator_diagnostic", "external_comparator",
}
EVIDENCE_TIERS = {
    "supported", "inference_ready_with_caveats", "interval_feasible",
    "diagnostic_only", "point_fit_recovery", "none", "miswired", "na",
}

TIER_ORDER = [
    "supported", "inference_ready_with_caveats", "interval_feasible",
    "diagnostic_only", "point_fit_recovery", "none", "miswired",
]
STRUCTURED_PROVIDERS = [
    "phylo", "spatial", "animal", "relmat", "phylo_interaction",
]

# A route reaches the missing-predictor runtime gate through its fitted
# family_type, not necessarily through its user-facing route name. Keep this
# mapping explicit: mixture routes deliberately share the base family's gate,
# while the hurdle route deliberately does not.
MISSING_PREDICTOR_RUNTIME_GATE = {
    "gaussian": "gaussian",
    "biv_gaussian": "biv_gaussian",
    "student": "student",
    "lognormal": "lognormal",
    "gamma": "gamma",
    "poisson": "poisson",
    "nbinom2": "nbinom2",
    "zi_poisson": "poisson",
    "zi_nbinom2": "nbinom2",
    "beta": "beta",
    "truncated_nbinom2": "truncated_nbinom2",
    "hurdle_nbinom2": "truncated_nbinom2",
    "cumulative_logit": "cumulative_logit",
    "beta_binomial": "beta_binomial",
    "zero_one_beta": "zero_one_beta",
    "tweedie": "tweedie",
    "skew_normal": "skew_normal",
    "binomial": "binomial",
}


def git_sha() -> str:
    return subprocess.check_output(
        ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True
    ).strip()


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def read_legacy_tsv_text(text: str) -> list[dict[str, str]]:
    """Read the historical census literally; its quote characters are data."""
    lines = text.splitlines()
    fields = lines[0].split("\t")
    rows = []
    for line_number, line in enumerate(lines[1:], start=2):
        values = line.split("\t")
        if len(values) != len(fields):
            raise SystemExit(
                f"Legacy census line {line_number} has {len(values)} fields, "
                f"expected {len(fields)}"
            )
        rows.append(dict(zip(fields, values)))
    return rows


def tsv_bytes(fields: list[str], rows: list[dict[str, str]]) -> bytes:
    from io import StringIO

    buffer = StringIO(newline="")
    writer = csv.DictWriter(
        buffer, fieldnames=fields, delimiter="\t", lineterminator="\n",
        extrasaction="ignore",
    )
    writer.writeheader()
    writer.writerows(rows)
    return buffer.getvalue().encode("utf-8")


def json_bytes(value: object) -> bytes:
    return (json.dumps(value, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


def legacy_tsv_bytes(fields: list[str], rows: list[dict[str, str]]) -> bytes:
    """Preserve the historical census's unquoted tab-separated representation."""
    lines = ["\t".join(fields)]
    lines.extend("\t".join(row.get(field, "") for field in fields) for row in rows)
    return ("\n".join(lines) + "\n").encode("utf-8")


def compact_json_bytes(value: object) -> bytes:
    return (json.dumps(value, ensure_ascii=False, separators=(",", ":")) + "\n").encode("utf-8")


def schema_value() -> dict[str, object]:
    return {
        "schema_version": 1,
        "axes": ["model_surface", "association", "missing_response", "missing_predictor"],
        "cell_fields": CELL_FIELDS,
        "evidence_fields": EVIDENCE_FIELDS,
        "transition_fields": TRANSITION_FIELDS,
        "enums": {
            "capability_status": sorted(CAPABILITY_STATUSES),
            "work_status": sorted(WORK_STATUSES),
            "test_gate": sorted(TEST_GATES),
            "evidence_tier": sorted(EVIDENCE_TIERS),
            "evidence_class": sorted(EVIDENCE_CLASSES),
            "provenance_relation": sorted(PROVENANCE_RELATIONS),
        },
        "expected_counts": {
            "model_surface": MODEL_SURFACE_COUNT,
            "association": ASSOCIATION_COUNT,
            "missing_response": 18,
            "missing_predictor": MISSING_PREDICTOR_COUNT,
        },
        "missing_response_verified_gate": (
            "G3 (7 routes); G5 (11 routes, 2026-08-11, two D-43 panels: "
            "gaussian, biv_gaussian, gamma, beta_binomial, binomial, "
            "zero_one_beta, zi_poisson, lognormal [first panel, coverage "
            "inside the pre-registered band]; beta, tweedie, skew_normal "
            "[second panel, threshold-free worst-case coverage bound, "
            "NOT the mr-g5-calibration-v2 floor])"
        ),
        "claim_boundary": (
            "Missing-response evidence is independent of model inference maturity. "
            "Missing-predictor evidence (missing_predictor axis) is a separate, "
            "narrower governance surface seeded 2026-08-09: it tracks admitted "
            "(response family x predictor family) mi()/impute_model() cells, mostly at "
            "G2 likelihood-identity/accounting evidence (diagnostic_only), not the "
            "known-DGP recovery evidence missing_response cells carry at G3, nor the "
            "archived replicated coverage evidence the eleven promoted routes carry "
            "at G5."
        ),
    }


def missing_evidence_source(route: str) -> str:
    specific = {
        "gaussian": "tests/testthat/test-missing-response-gaussian.R",
        "biv_gaussian": "tests/testthat/test-missing-response-biv-gaussian.R",
        "binomial": "tests/testthat/test-missing-response-binomial.R",
        "poisson": "tests/testthat/test-missing-response-poisson.R",
        "nbinom2": "tests/testthat/test-missing-response-nbinom2.R",
        "beta": "tests/testthat/test-missing-response-beta.R",
        "zi_poisson": "R/drmTMB.R:5585-5589",
        "zi_nbinom2": "R/drmTMB.R:6126-6130",
    }
    return specific.get(route, "tests/testthat/test-missing-response-family-gate.R")


def bootstrap() -> None:
    if any(path.exists() for path in (CELLS, EVIDENCE, TRANSITIONS, SCHEMA)):
        raise SystemExit("Refusing bootstrap: capability-ledger source files already exist")

    master = read_legacy_tsv_text((CENSUS / "_master.tsv").read_text(encoding="utf-8"))
    if len(master) != IMPORTED_MODEL_COUNT:
        raise SystemExit(
            f"Expected {IMPORTED_MODEL_COUNT} legacy rows, found {len(master)}"
        )

    visible = [
        "family", "model_type", "dpar", "effect_type", "structure_provider",
        "dimension", "q_gate", "estimator",
    ]
    groups: dict[tuple[str, ...], list[int]] = defaultdict(list)
    for index, row in enumerate(master, start=1):
        groups[tuple(row[field] for field in visible)].append(index)

    sha = git_sha()
    cells: list[dict[str, str]] = []
    evidence: list[dict[str, str]] = []
    transitions: list[dict[str, str]] = []

    occurrence: Counter[tuple[str, ...]] = Counter()
    for index, old in enumerate(master, start=1):
        key = tuple(old[field] for field in visible)
        occurrence[key] += 1
        variant = "base" if len(groups[key]) == 1 else f"legacy_{occurrence[key]:02d}"
        cell_id = f"mc-{index:04d}"
        evidence_id = f"ev-{cell_id}-legacy" if old["evidence_source"] else ""
        status = old["status"]
        # The pre-ledger census used `rejected_by_design` for cells deliberately
        # out of scope at the time. That was not a proof of impossibility: every
        # unimplemented model cell belongs to the visible backlog.
        status = "not_implemented" if status == "rejected_by_design" else status
        work = "verified" if status == "implemented" else "backlog"
        cells.append({
            "cell_id": cell_id,
            "source_order": str(index),
            "axis": "model_surface",
            "family_route": old["family"],
            "family_type": old["family"],
            "model_type": old["model_type"],
            "route_variant": variant,
            "route_modifier": "base",
            "dpar": old["dpar"],
            "effect_type": old["effect_type"],
            "structure_provider": old["structure_provider"],
            "dimension": old["dimension"],
            "q_gate": old["q_gate"],
            "estimator": old["estimator"],
            "capability_status": status,
            "work_status": work,
            "evidence_tier": old["evidence_tier"],
            "test_gate": "na",
            "tranche_id": "legacy-census",
            "owner": "",
            "blocking_reviewers": "",
            "primary_evidence_id": evidence_id,
            "claim_boundary": old["notes"],
            "next_gate": "Preserve the existing model-surface evidence tier.",
            "issue_url": "",
            "pr_url": "",
            "updated_commit": sha,
            "updated_date": DATE,
            "legacy_evidence_source": old["evidence_source"],
            "notes": old["notes"],
        })
        if evidence_id:
            evidence.append({
                "evidence_id": evidence_id,
                "cell_id": cell_id,
                "evidence_class": "legacy_model_evidence",
                "path_or_url": old["evidence_source"],
                "commit_sha": sha,
                "run_id": "",
                "command": "",
                "result": "imported",
                "replicates": "",
                "reviewed_by": "MR-T0 migration",
                "review_date": DATE,
                "claim_boundary": old["notes"],
            })
        transitions.append({
            "transition_id": f"tr-{cell_id}-seed",
            "cell_id": cell_id,
            "from_work_status": "",
            "to_work_status": work,
            "evidence_ids": evidence_id,
            "reason": (
                f"MR-T0 import of the unchanged {IMPORTED_MODEL_COUNT}-cell census"
            ),
            "actor": "Codex MR-T0",
            "commit_sha": sha,
            "date": DATE,
        })

    for offset, (model_type, route, family_type, modifier, tranche) in enumerate(ROUTES, start=1):
        admitted = route in ADMITTED
        cell_id = f"mr-{route.replace('_', '-')}"
        evidence_id = f"ev-{cell_id}-baseline"
        boundary = (
            "Route is admitted by current code, but MR-T1 must repair/audit true "
            "sentinel mutation, residual/accounting semantics, and named recovery "
            "before a verified tick."
            if admitted else
            "Current code rejects response-missingness for this exact route. "
            "No support is inherited from a base family."
        )
        next_gate = (
            "MR-T1: complete the shared G2/G3 audit." if admitted else
            f"{tranche}: design and implement this route before G2/G3 validation."
        )
        cells.append({
            "cell_id": cell_id,
            "source_order": str(IMPORTED_MODEL_COUNT + offset),
            "axis": "missing_response",
            "family_route": route,
            "family_type": family_type,
            "model_type": str(model_type),
            "route_variant": "base",
            "route_modifier": modifier,
            "dpar": "all fitted dpars",
            "effect_type": "response_missingness",
            "structure_provider": "route_contract",
            "dimension": "bivariate" if route == "biv_gaussian" else "univariate",
            "q_gate": "na",
            "estimator": "ML",
            "capability_status": "implemented" if admitted else "not_implemented",
            "work_status": "implemented_unverified" if admitted else "backlog",
            "evidence_tier": "na",
            "test_gate": "G1" if admitted else "G0",
            "tranche_id": tranche,
            "owner": "",
            "blocking_reviewers": "Rose; Grace" if admitted else "Noether; Fisher",
            "primary_evidence_id": evidence_id,
            "claim_boundary": boundary,
            "next_gate": next_gate,
            "issue_url": "",
            "pr_url": "",
            "updated_commit": sha,
            "updated_date": DATE,
            "legacy_evidence_source": "",
            "notes": "Seeded from live builder/gate behavior during MR-T0.",
        })
        evidence.append({
            "evidence_id": evidence_id,
            "cell_id": cell_id,
            "evidence_class": "admission_test" if admitted else "rejection_test",
            "path_or_url": missing_evidence_source(route),
            "commit_sha": sha,
            "run_id": "",
            "command": "Rscript tools/check-capability-runtime.R",
            "result": "admitted_unverified" if admitted else "rejected",
            "replicates": "",
            "reviewed_by": "MR-T0 engine audit",
            "review_date": DATE,
            "claim_boundary": boundary,
        })
        transitions.append({
            "transition_id": f"tr-{cell_id}-seed",
            "cell_id": cell_id,
            "from_work_status": "",
            "to_work_status": "implemented_unverified" if admitted else "backlog",
            "evidence_ids": evidence_id,
            "reason": "MR-T0 route-level baseline from live code behavior",
            "actor": "Codex MR-T0",
            "commit_sha": sha,
            "date": DATE,
        })

    LEDGER.mkdir(parents=True, exist_ok=True)
    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    EVIDENCE.write_bytes(tsv_bytes(EVIDENCE_FIELDS, evidence))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    print(f"Bootstrapped {len(cells)} cells and {len(evidence)} evidence records")


def c14_boundary_source_rows() -> list[dict[str, str]]:
    """Return the immutable C14 package-boundary source set.

    The prior MR-T0 import intentionally made all historical rows visible in a
    single implementation backlog. C14 reverses only the 330 records that an
    earlier committed ledger explicitly classified as package boundaries. The
    source commit is part of the contract: a row must never be reclassified by
    a pattern over its current formula fields.  Its checked-in ID snapshot is
    deliberately used instead of ``git show`` so source verification is
    available in a shallow CI checkout too.
    """
    rows = read_tsv(C14_BOUNDARY_SOURCE_SNAPSHOT)
    if not rows or set(rows[0]) != {"cell_id"}:
        raise SystemExit("C14 boundary source snapshot has an invalid schema")
    if len(rows) != C14_BOUNDARY_COUNT:
        raise SystemExit(
            "C14 boundary source count changed: "
            f"{len(rows)} (expected {C14_BOUNDARY_COUNT})"
        )
    ids = [row["cell_id"] for row in rows]
    if len(ids) != len(set(ids)):
        raise SystemExit("C14 boundary source contains duplicate cell IDs")
    return rows


def restore_c14_boundaries() -> None:
    """Restore only the source-pinned C14 package-boundary classifications."""
    source = c14_boundary_source_rows()
    source_ids = {row["cell_id"] for row in source}
    cells = read_tsv(CELLS)
    transitions = read_tsv(TRANSITIONS)
    by_id = {row["cell_id"]: row for row in cells}
    missing = source_ids - set(by_id)
    if missing:
        raise SystemExit(
            "C14 boundary source IDs missing from the current ledger: "
            + ", ".join(sorted(missing))
        )

    affected = [by_id[cell_id] for cell_id in source_ids]
    if any(row["axis"] != "model_surface" for row in affected):
        raise SystemExit("C14 boundary source attempted to alter a non-model row")
    if any(row["capability_status"] == "implemented" for row in affected):
        raise SystemExit("C14 taxonomy restoration would overwrite an implementation")
    unexpected = {
        (row["capability_status"], row["work_status"], row["evidence_tier"])
        for row in affected
        if (row["capability_status"], row["work_status"], row["evidence_tier"])
        not in {
            ("not_implemented", "backlog", "none"),
            ("rejected_by_design", "deferred", "none"),
        }
    }
    if unexpected:
        raise SystemExit(
            "C14 boundary source has non-taxonomy state in the current ledger: "
            + repr(sorted(unexpected))
        )

    for row in affected:
        row["capability_status"] = "rejected_by_design"
        row["work_status"] = "deferred"
        row["evidence_tier"] = "none"

    transition_ids = {row["transition_id"] for row in transitions}
    for cell_id in sorted(source_ids):
        transition_id = f"tr-{cell_id}-c14-boundary-taxonomy"
        if transition_id in transition_ids:
            continue
        transitions.append({
            "transition_id": transition_id,
            "cell_id": cell_id,
            "from_work_status": "backlog",
            "to_work_status": "deferred",
            "evidence_ids": "",
            "reason": (
                "C14 source-pinned taxonomy restoration from the explicit "
                f"package-boundary classification at {C14_BOUNDARY_SOURCE_COMMIT}; "
                "this changes no implementation or evidence claim."
            ),
            "actor": "Codex C14 taxonomy restoration",
            "commit_sha": C14_BOUNDARY_SOURCE_COMMIT,
            "date": "2026-07-31",
        })

    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    print(
        "C14 boundary taxonomy restored "
        f"({len(affected)} rows from {C14_BOUNDARY_SOURCE_COMMIT})"
    )


def _split_zob_leaf_taxonomy(
    taxonomy: tuple[tuple[str, str], ...],
    *,
    source_doc: str,
    source_order_base: int,
    tranche_id: str,
    date: str,
    route_variant_prefix: str,
    run_id_prefix: str,
    evidence_id_suffix: str,
    command: str,
    reviewed_by: str,
    actor: str,
    leaf_label: str,
) -> str:
    """Shared engine behind the C14/C18 zero-one-beta leaf-taxonomy splits.

    Each original row becomes a q1 intercept leaf. A separate q2-plus boundary
    row is added for the same provider and endpoint, so promotion of the q1
    leaf can never silently inherit the untested higher-dimensional forms.
    This helper is source-bound and idempotent for any taxonomy tuple passed
    to it; it never changes an evidence tier or promotes a cell.
    """
    cells = read_tsv(CELLS)
    evidence = read_tsv(EVIDENCE)
    transitions = read_tsv(TRANSITIONS)
    by_id = {row["cell_id"]: row for row in cells}
    evidence_ids = {row["evidence_id"] for row in evidence}
    transition_ids = {row["transition_id"] for row in transitions}
    sha = git_sha()

    for original_id, boundary_id in taxonomy:
        if original_id not in by_id:
            raise SystemExit(f"{leaf_label} q1 leaf source is missing: {original_id}")
        original = by_id[original_id]
        expected = {
            "axis": "model_surface",
            "family_route": "zero_one_beta",
            "effect_type": "structured",
            "capability_status": "not_implemented",
            "work_status": "backlog",
            "evidence_tier": "none",
        }
        if any(original[field] != value for field, value in expected.items()):
            raise SystemExit(
                f"{leaf_label} q1 leaf source has unexpected state: {original_id}"
            )

        q1_evidence_id = f"ev-{original_id}-{route_variant_prefix}-{evidence_id_suffix}"
        q1_transition_id = f"tr-{original_id}-{route_variant_prefix}-{evidence_id_suffix}"
        q1_boundary = (
            f"Exact {leaf_label} leaf for ordinary ML zero_one_beta(): one unlabelled "
            f"structured {original['dpar']} intercept with provider "
            f"`{original['structure_provider']}` and q1 only. This leaf carries "
            "no point-fit evidence until its provider-specific oracle, retained "
            "attempts, source SHA, and independent GO review are bound. Slopes, "
            "labels, covariance, q2+, other random effects, profiles, intervals, "
            "coverage, and inference claims remain outside this leaf."
        )
        if q1_evidence_id not in evidence_ids:
            evidence.append({
                "evidence_id": q1_evidence_id,
                "cell_id": original_id,
                "evidence_class": "contract_test",
                "path_or_url": source_doc,
                "commit_sha": sha,
                "run_id": f"{run_id_prefix}-q1-leaf-taxonomy",
                "command": command,
                "result": "q1_leaf_not_promoted",
                "replicates": "",
                "reviewed_by": reviewed_by,
                "review_date": date,
                "claim_boundary": q1_boundary,
            })
        original.update({
            "route_variant": f"{route_variant_prefix}_exact_q1_structured_intercept",
            "q_gate": "q1",
            "tranche_id": tranche_id,
            "owner": "Lane C",
            "blocking_reviewers": "Noether; Fisher; Rose",
            "primary_evidence_id": q1_evidence_id,
            "claim_boundary": q1_boundary,
            "next_gate": (
                "Bind this exact q1 leaf to its current-source oracle, all-attempt "
                "recovery receipt, and independent GO/BLOCK review before promotion."
            ),
            "updated_commit": sha,
            "updated_date": date,
            "notes": f"{leaf_label} non-lossy q1 leaf; q2-plus boundary is " + boundary_id + ".",
        })
        if q1_transition_id not in transition_ids:
            transitions.append({
                "transition_id": q1_transition_id,
                "cell_id": original_id,
                "from_work_status": "backlog",
                "to_work_status": "backlog",
                "evidence_ids": q1_evidence_id,
                "reason": f"{leaf_label} non-lossy taxonomy split; q1 remains unpromoted.",
                "actor": actor,
                "commit_sha": sha,
                "date": date,
            })

        q2_evidence_id = f"ev-{boundary_id}-{route_variant_prefix}-q2plus-boundary"
        q2_transition_id = f"tr-{boundary_id}-{route_variant_prefix}-q2plus-boundary"
        q2_boundary = (
            f"{leaf_label} q2-plus boundary paired with " + original_id + ": q2, q4, q6, "
            "q8, q12, slopes, labels, covariance, additional structured or "
            "ordinary random effects, profiles, intervals, coverage, and inference "
            "claims are not currently supported by the exact q1 leaf."
        )
        if boundary_id not in by_id:
            boundary = original.copy()
            boundary.update({
                "cell_id": boundary_id,
                "source_order": str(
                    source_order_base
                    + len([pair for pair in taxonomy if pair[1] < boundary_id])
                ),
                "route_variant": f"{route_variant_prefix}_q2plus_structured_boundary",
                "q_gate": "q2plus",
                "capability_status": "rejected_by_design",
                "work_status": "deferred",
                "evidence_tier": "none",
                "tranche_id": tranche_id,
                "owner": "Lane C",
                "blocking_reviewers": "Noether; Fisher; Rose",
                "primary_evidence_id": q2_evidence_id,
                "claim_boundary": q2_boundary,
                "next_gate": (
                    "A separately approved exact q2-plus target, implementation, "
                    "oracle, and recovery programme is required."
                ),
                "updated_commit": sha,
                "updated_date": date,
                "notes": f"{leaf_label} non-lossy q2-plus boundary paired with " + original_id + ".",
            })
            cells.append(boundary)
            by_id[boundary_id] = boundary
        if q2_evidence_id not in evidence_ids:
            evidence.append({
                "evidence_id": q2_evidence_id,
                "cell_id": boundary_id,
                "evidence_class": "contract_test",
                "path_or_url": source_doc,
                "commit_sha": sha,
                "run_id": f"{run_id_prefix}-q2plus-boundary",
                "command": command,
                "result": "q2plus_deferred",
                "replicates": "",
                "reviewed_by": reviewed_by,
                "review_date": date,
                "claim_boundary": q2_boundary,
            })
        if q2_transition_id not in transition_ids:
            transitions.append({
                "transition_id": q2_transition_id,
                "cell_id": boundary_id,
                "from_work_status": "",
                "to_work_status": "deferred",
                "evidence_ids": q2_evidence_id,
                "reason": f"{leaf_label} non-lossy q2-plus boundary created beside a q1 leaf.",
                "actor": actor,
                "commit_sha": sha,
                "date": date,
            })

    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    EVIDENCE.write_bytes(tsv_bytes(EVIDENCE_FIELDS, evidence))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    return f"{leaf_label} zero-one-beta structured q1/q2-plus leaves are current"


def split_c14_zob_structured_leaves() -> None:
    """Replace C14's lossy zero-one-beta structured rows with exact leaves.

    Each original row becomes a q1 intercept leaf. A separate q2-plus boundary
    row is added for the same provider and endpoint, so promotion of the q1
    leaf can never silently inherit the untested higher-dimensional forms.
    """
    message = _split_zob_leaf_taxonomy(
        C14_ZOB_LEAF_TAXONOMY,
        source_doc=C14_ZOB_LEAF_TAXONOMY_SOURCE,
        source_order_base=695,
        tranche_id="lane-c-c14-leaf-taxonomy",
        date="2026-07-31",
        route_variant_prefix="c14",
        run_id_prefix="c14-zob-structured",
        evidence_id_suffix="q1-leaf-taxonomy",
        command="python3 tools/capability_ledger.py --split-c14-zob-structured-leaves",
        reviewed_by="C14 taxonomy reconciliation",
        actor="Codex C14 leaf taxonomy",
        leaf_label="C14",
    )
    print(message)


def split_c18_zob_atom_leaves() -> None:
    """Replace C18's lossy zero-one-beta ATOM (zoi/coi) rows with exact leaves.

    Sibling of ``split_c14_zob_structured_leaves`` for the ten structured
    zero-one-beta ATOM rows (mc-0603..mc-0607 zoi, mc-0613..mc-0617 coi), one
    per provider. C14's own taxonomy and receipt fingerprint are untouched by
    this split: it operates only on the separate C18 taxonomy above.
    """
    message = _split_zob_leaf_taxonomy(
        C18_ZOB_ATOM_LEAF_TAXONOMY,
        source_doc=C18_ZOB_ATOM_LEAF_TAXONOMY_SOURCE,
        source_order_base=705,
        tranche_id="lane-c-c18-atom-leaf-taxonomy",
        date="2026-08-02",
        route_variant_prefix="c18",
        run_id_prefix="c18-zob-atom",
        evidence_id_suffix="q1-leaf-taxonomy",
        command="python3 tools/capability_ledger.py --split-c18-zob-atom-leaves",
        reviewed_by="C18 taxonomy reconciliation",
        actor="Claude C18 atom leaf taxonomy",
        leaf_label="C18",
    )
    print(message)


# mc-0207 was one legacy row representing q4/q6/q8 labelled ORDINARY (no
# structure_provider) bivariate REML random-slope covariance blocks, with
# q_gate="na", no unique formula/target, and evidence limited to an
# uncommitted scratchpad probe (scratchpad/reml_parity_gaps_3A_ladder.R).
# That ladder tests a q2 bivariate mu-sigma block (already mc-0205/mc-0206's
# exact territory) and a q3 UNIVARIATE mu-only block; it never fits a
# bivariate mu1+mu2 q4/q6/q8 block, so the original row's "representative
# across q4/q6/q8" claim was an extrapolation across untested dimensions.
MC_0207_ORIGINAL_STATE = {
    "route_variant": "legacy_02",
    "q_gate": "na",
    "capability_status": "implemented",
    "work_status": "verified",
    "evidence_tier": "point_fit_recovery",
    "tranche_id": "legacy-census",
}
MC_0207_Q_LEAF_TAXONOMY = (
    ("mc-0207", "q4", "one correlated slope each on mu1 and mu2 (intercept + 1 slope per response)"),
    ("mc-0715", "q6", "the row's own worked example: a mu1+mu2 two-slope block (intercept + 2 slopes per response)"),
    ("mc-0716", "q8", "a mu1+mu2 three-slope block (intercept + 3 slopes per response)"),
)


def split_mc0207_ordinary_q_leaves() -> None:
    """Replace mc-0207's lossy q4/q6/q8 representative claim with exact leaves.

    mc-0207 becomes the q4 leaf in place; mc-0715 (q6) and mc-0716 (q8) are new
    leaves. This is a taxonomy correction, not new evidence: none of the three
    leaves has dimension-matched point-fit evidence (the bound scratchpad
    ladder tests adjacent shapes only -- see MC_0207_ORIGINAL_STATE's
    docstring), so all three are demoted from point_fit_recovery to
    evidence_tier=none and from work_status=verified to
    implemented_unverified. capability_status stays implemented because the
    REML gate code does not reject these ordinary q>2 blocks; the split
    changes evidence scope, not code behaviour, and it promotes nothing.
    """
    cells = read_tsv(CELLS)
    evidence = read_tsv(EVIDENCE)
    transitions = read_tsv(TRANSITIONS)
    by_id = {row["cell_id"]: row for row in cells}
    evidence_ids = {row["evidence_id"] for row in evidence}
    transition_ids = {row["transition_id"] for row in transitions}
    sha = git_sha()
    date = "2026-08-03"
    tranche_id = "arc4b-mc0207-split"

    if "mc-0207" not in by_id:
        raise SystemExit("mc-0207 split source is missing")
    original = by_id["mc-0207"]
    if any(original[field] != value for field, value in MC_0207_ORIGINAL_STATE.items()):
        raise SystemExit("mc-0207 has unexpected state; refusing to split")
    base = original.copy()

    for cell_id, q_gate, shape_example in MC_0207_Q_LEAF_TAXONOMY:
        evidence_id = f"ev-{cell_id}-arc4b-{q_gate}-split"
        transition_id = f"tr-{cell_id}-arc4b-{q_gate}-split"
        claim_boundary = (
            f"Exact {q_gate} leaf split from the former mc-0207 q4/q6/q8 "
            "representative row: an unlabelled bivariate ordinary REML "
            f"random-slope covariance block of total dimension {q_gate[1:]} "
            f"({shape_example}) for biv_gaussian. The REML gate code applies "
            "no q-gate-specific restriction, so this shape is not rejected by "
            "the validator, but no point-fit or recovery evidence exists at "
            "this exact dimension: the source scratchpad ladder "
            "(scratchpad/reml_parity_gaps_3A_ladder.R) tests only a q2 "
            "bivariate mu-sigma block (mc-0205/mc-0206's territory) and a q3 "
            "UNIVARIATE mu-only block, neither of which is this bivariate "
            f"{q_gate} shape. Sibling ordinary leaves are recorded separately "
            "at " + "/".join(sibling for sibling, _, _ in MC_0207_Q_LEAF_TAXONOMY if sibling != cell_id) + ". "
            "Slope count, labels, structured providers, intervals, coverage, "
            "and any inference-ready or public-support claim remain outside "
            "this leaf."
        )
        next_gate = (
            f"Bind this exact bivariate {q_gate} ordinary REML leaf to a "
            "dimension-matched recovery fixture and independent GO/BLOCK "
            "review before any promotion above evidence_tier=none."
        )
        notes = (
            "Arc 4b split of the former mc-0207 q4/q6/q8 representative "
            "claim; siblings are " + "; ".join(
                f"{sibling} ({sibling_q})"
                for sibling, sibling_q, _ in MC_0207_Q_LEAF_TAXONOMY
                if sibling != cell_id
            ) + ". Born/kept at evidence_tier=none because the bound "
            "scratchpad evidence tests a UNIVARIATE q3 block and a bivariate "
            f"q2 mu-sigma block, not this bivariate {q_gate} mu1+mu2 shape."
        )

        if cell_id == "mc-0207":
            row = original
            from_work_status = MC_0207_ORIGINAL_STATE["work_status"]
        elif cell_id in by_id:
            row = by_id[cell_id]
            from_work_status = ""
        else:
            row = base.copy()
            row["cell_id"] = cell_id
            row["source_order"] = str(int(cell_id.split("-")[1]))
            cells.append(row)
            by_id[cell_id] = row
            from_work_status = ""

        row.update({
            "route_variant": f"arc4b_ordinary_reml_{q_gate}_block",
            "q_gate": q_gate,
            "capability_status": "implemented",
            "work_status": "implemented_unverified",
            "evidence_tier": "none",
            "tranche_id": tranche_id,
            "owner": "",
            "blocking_reviewers": "Noether; Fisher; Rose",
            "primary_evidence_id": evidence_id,
            "claim_boundary": claim_boundary,
            "next_gate": next_gate,
            "updated_commit": sha,
            "updated_date": date,
            "notes": notes,
        })

        if evidence_id not in evidence_ids:
            evidence.append({
                "evidence_id": evidence_id,
                "cell_id": cell_id,
                "evidence_class": "contract_test",
                "path_or_url": "scratchpad/reml_parity_gaps_3A_ladder.R",
                "commit_sha": sha,
                "run_id": f"arc4b-mc0207-split-{q_gate}",
                "command": "python3 tools/capability_ledger.py --split-mc0207-ordinary-q-leaves",
                "result": f"{q_gate}_leaf_not_promoted",
                "replicates": "",
                "reviewed_by": "Arc4b taxonomy split",
                "review_date": date,
                "claim_boundary": claim_boundary,
            })
            evidence_ids.add(evidence_id)

        if transition_id not in transition_ids:
            transitions.append({
                "transition_id": transition_id,
                "cell_id": cell_id,
                "from_work_status": from_work_status,
                "to_work_status": "implemented_unverified",
                "evidence_ids": evidence_id,
                "reason": (
                    "Arc 4b split of the q4/q6/q8 representative row into "
                    "exact per-q leaves; demoted from point_fit_recovery/"
                    "verified because the bound scratchpad evidence covers "
                    "adjacent shapes (q2 bivariate mu-sigma, q3 univariate), "
                    f"not this bivariate {q_gate} mu1+mu2 shape."
                ),
                "actor": "Claude Arc4b taxonomy split",
                "commit_sha": sha,
                "date": date,
            })
            transition_ids.add(transition_id)

    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    EVIDENCE.write_bytes(tsv_bytes(EVIDENCE_FIELDS, evidence))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    SCHEMA.write_bytes(json_bytes(schema_value()))
    print("mc-0207 q4/q6/q8 ordinary leaves are current")


def reconcile_capability_truth() -> None:
    """Reconcile the five exact 0.7 binomial/O3 capability-truth cells.

    This is an idempotent, one-time ledger migration.  It does not alter the
    immutable C14 snapshot or delete O3's completed internal-estimator study.
    """
    cells = read_tsv(CELLS)
    evidence = read_tsv(EVIDENCE)
    transitions = read_tsv(TRANSITIONS)
    by_id = {row["cell_id"]: row for row in cells}
    missing = CAPABILITY_TRUTH_CELL_IDS - set(by_id)
    if missing:
        raise SystemExit(
            "Capability-truth source cells are missing: " + ", ".join(sorted(missing))
        )

    source_sha = git_sha()
    test_path = "tests/testthat/test-reml-binomial-coxreid.R"
    design_path = "docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md"
    common_next = (
        "A higher evidence tier requires separately approved recovery or calibrated "
        "interval evidence for this exact public drmTMB() route."
    )

    states = {
        "mc-0058": {
            "capability_status": "rejected_by_design",
            "work_status": "deferred",
            "evidence_tier": "none",
            "test_gate": "na",
            "primary_evidence_id": "ev-mc-0058-capability-truth-rejection",
            "claim_boundary": (
                "Fixed-effect-only binomial REML is rejected before TMB construction: "
                "the O2 joint-Laplace restricted likelihood requires exactly one "
                "admitted ordinary unlabelled mu random-effect term. Use REML=FALSE "
                "for a fixed-only binomial model. Multiple-term routes are also "
                "unavailable. This exact gate grants no broader "
                "non-Gaussian REML capability."
            ),
            "next_gate": (
                "A fixed-only binomial REML route would require a separately designed "
                "estimand, implementation, and validation arc; use REML=FALSE now."
            ),
            "updated_commit": source_sha,
        },
        "mc-0060": {
            "capability_status": "implemented",
            "work_status": "verified",
            "evidence_tier": "diagnostic_only",
            "test_gate": "G2",
            "primary_evidence_id": "ev-mc-0060-capability-truth-o2",
            "claim_boundary": (
                "The exact public binomial mu random-intercept route y ~ x + (1 | g) "
                "is admitted with REML=TRUE through O2's joint-Laplace fixed-effect "
                "fold. Deterministic Bernoulli and grouped-binomial fixtures agree "
                "with glmmTMB(REML=TRUE), "
                "converges with pdHess, and exposes finite vcov(). This is "
                "diagnostic_only: no recovery, interval calibration, coverage, or "
                "broader non-Gaussian REML claim is earned."
            ),
            "next_gate": common_next,
            "updated_commit": source_sha,
        },
        "mc-0062": {
            "capability_status": "implemented",
            "work_status": "verified",
            "evidence_tier": "diagnostic_only",
            "test_gate": "G2",
            "primary_evidence_id": "ev-mc-0062-capability-truth-o2",
            "claim_boundary": (
                "The exact public binomial independent mu random-slope route "
                "y ~ x + (0 + x | g) is admitted with REML=TRUE through O2's "
                "joint-Laplace fixed-effect fold. Deterministic Bernoulli and "
                "grouped-binomial fixtures agree with glmmTMB(REML=TRUE), converge "
                "with pdHess, and expose finite "
                "vcov(). This is diagnostic_only: correlated or labelled slopes, "
                "recovery, interval calibration, coverage, and broader non-Gaussian "
                "REML remain outside scope."
            ),
            "next_gate": common_next,
            "updated_commit": source_sha,
        },
        "mc-0068": {
            "capability_status": "rejected_by_design",
            "work_status": "deferred",
            "evidence_tier": "none",
            "test_gate": "na",
            "primary_evidence_id": "ev-mc-0068-capability-truth-rejection",
            "claim_boundary": (
                "Binomial REML remains rejected for structured mu effects. Exact q1 "
                "phylo(), spatial(), animal(), relmat(), and phylo_interaction() "
                "formula gates are tested; the binomial parser admits no structured "
                "q gate. O2 admits only one ordinary unlabelled random intercept or "
                "one independent slope; multiple-term, structured, correlated, and "
                "labelled binomial REML blocks are outside the public contract."
            ),
            "next_gate": (
                "Keep REML=FALSE or use an admitted ordinary binomial random effect; "
                "structured binomial REML needs a separate implementation and evidence arc."
            ),
            "updated_commit": source_sha,
        },
        "mc-0227": {
            "capability_status": "implemented",
            "work_status": "verified",
            "evidence_tier": "point_fit_recovery",
            "test_gate": "G3",
            "primary_evidence_id": "ev-mc-0227-arc2b",
            "claim_boundary": (
                "Public drmTMB() cumulative_logit mu random-slope fitting uses the "
                "ML-Laplace route and has DG2 point-fit recovery for one independent "
                "slope (0 + x | id). The completed O3 AGHQ25+Cox-Reid profile study "
                "is preserved as internal-estimator technical provenance, but O3 is "
                "unavailable through drmTMB() and grants no public ML interval or "
                "reporting permission. Correlated/labelled slopes, public AGHQ/REML, "
                "interval calibration, and coverage remain outside this public row."
            ),
            "next_gate": (
                "Expose and validate a public estimator route, then bind calibration "
                "evidence to that exact callable route before restoring any interval-reporting tier."
            ),
            "updated_commit": source_sha,
        },
    }
    for cell_id, state in states.items():
        row = by_id[cell_id]
        row.update(state)
        row["tranche_id"] = "07-capability-truth"
        row["owner"] = ""
        row["blocking_reviewers"] = ""
        row["issue_url"] = ""
        row["pr_url"] = ""
        row["updated_date"] = CAPABILITY_TRUTH_DATE
        row["legacy_evidence_source"] = test_path if cell_id != "mc-0227" else (
            test_path + "; " + design_path
        )
        row["notes"] = state["claim_boundary"]

    evidence_by_id = {row["evidence_id"]: row for row in evidence}
    new_evidence = (
        {
            "evidence_id": "ev-mc-0058-capability-truth-rejection",
            "cell_id": "mc-0058", "evidence_class": "rejection_test",
            "path_or_url": test_path, "commit_sha": source_sha,
            "run_id": "07-capability-truth-fixed-only-rejection",
            "command": 'devtools::test(filter="reml-binomial-coxreid")',
            "result": "exact_gate", "replicates": "1 deterministic fixture",
            "reviewed_by": "0.7 capability-truth reconciliation",
            "review_date": CAPABILITY_TRUTH_DATE,
            "claim_boundary": states["mc-0058"]["claim_boundary"],
        },
        {
            "evidence_id": "ev-mc-0060-capability-truth-o2",
            "cell_id": "mc-0060", "evidence_class": "external_comparator",
            "path_or_url": test_path, "commit_sha": source_sha,
            "run_id": "glmmTMB(REML=TRUE) (same joint-Laplace construction; weak independence)",
            "command": 'devtools::test(filter="reml-binomial-coxreid")',
            "result": "glmmTMB deterministic parity; convergence 0; pdHess; finite drmTMB vcov",
            "replicates": "2 deterministic response encodings",
            "reviewed_by": "0.7 capability-truth reconciliation",
            "review_date": CAPABILITY_TRUTH_DATE,
            "claim_boundary": (
                "WEAK INDEPENDENCE: glmmTMB is a separately exposed implementation "
                "of the same joint-Laplace fixed-effect fold. Exact intercept route "
                "only; this single-seed comparator supplies no recovery, interval, "
                "coverage, or calibrated-inference claim."
            ),
        },
        {
            "evidence_id": "ev-mc-0062-capability-truth-o2",
            "cell_id": "mc-0062", "evidence_class": "external_comparator",
            "path_or_url": test_path, "commit_sha": source_sha,
            "run_id": "glmmTMB(REML=TRUE) (same joint-Laplace construction; weak independence)",
            "command": 'devtools::test(filter="reml-binomial-coxreid")',
            "result": "glmmTMB deterministic parity; convergence 0; pdHess; finite drmTMB vcov",
            "replicates": "2 deterministic response encodings",
            "reviewed_by": "0.7 capability-truth reconciliation",
            "review_date": CAPABILITY_TRUTH_DATE,
            "claim_boundary": (
                "WEAK INDEPENDENCE: glmmTMB is a separately exposed implementation "
                "of the same joint-Laplace fixed-effect fold. Exact independent-slope "
                "route only; this single-seed comparator supplies no recovery, interval, "
                "coverage, or calibrated-inference claim."
            ),
        },
        {
            "evidence_id": "ev-mc-0068-capability-truth-rejection",
            "cell_id": "mc-0068", "evidence_class": "rejection_test",
            "path_or_url": test_path, "commit_sha": source_sha,
            "run_id": "07-capability-truth-structured-rejection",
            "command": 'devtools::test(filter="reml-binomial-coxreid")',
            "result": "five exact q1 structured formula gates", "replicates": "5 providers",
            "reviewed_by": "0.7 capability-truth reconciliation",
            "review_date": CAPABILITY_TRUTH_DATE,
            "claim_boundary": states["mc-0068"]["claim_boundary"],
        },
        {
            "evidence_id": "ev-mc-0227-capability-truth-public-boundary",
            "cell_id": "mc-0227", "evidence_class": "estimator_diagnostic",
            "path_or_url": design_path, "commit_sha": source_sha,
            "run_id": "07-capability-truth-o3-public-boundary",
            "command": "static public-route and estimator-boundary reconciliation",
            "result": "internal_only_no_public_drmTMB_route", "replicates": "",
            "reviewed_by": "0.7 capability-truth reconciliation",
            "review_date": CAPABILITY_TRUTH_DATE,
            "claim_boundary": (
                "INTERNAL ESTIMATOR ONLY: the completed O3 evidence is preserved, "
                "but O3 is unavailable through drmTMB() and grants no public ML "
                "interval or reporting permission."
            ),
        },
    )
    for row in new_evidence:
        if row["evidence_id"] in evidence_by_id:
            evidence_by_id[row["evidence_id"]].update(row)
        else:
            evidence.append(row)

    o3 = next(row for row in evidence if row["evidence_id"] == "ev-mc-0227-o3")
    internal_boundary = (
        " INTERNAL ESTIMATOR ONLY: O3 is unavailable through drmTMB(); this "
        "completed study is retained as technical provenance and grants no "
        "public ML interval or reporting permission."
    )
    if "INTERNAL ESTIMATOR ONLY" not in o3["claim_boundary"]:
        o3["claim_boundary"] += internal_boundary

    transition_ids = {row["transition_id"] for row in transitions}
    transition_specs = (
        ("mc-0058", "deferred", "deferred", "ev-mc-0058-capability-truth-rejection",
         "Replace the stale family-wide Gaussian-only reason with the exact fixed-only binomial REML gate."),
        ("mc-0060", "deferred", "verified", "ev-mc-0060-capability-truth-o2",
         "Correct a C14 false negative: the landed public O2 random-intercept route has deterministic parity and uncertainty diagnostics."),
        ("mc-0062", "deferred", "verified", "ev-mc-0062-capability-truth-o2",
         "Correct a C14 false negative: the landed public O2 independent-slope route has deterministic parity and uncertainty diagnostics."),
        ("mc-0068", "deferred", "deferred", "ev-mc-0068-capability-truth-rejection",
         "Replace the stale family-wide REML reason with the exact structured binomial boundary."),
        ("mc-0227", "verified", "verified", "ev-mc-0227-arc2b;ev-mc-0227-o3;ev-mc-0227-capability-truth-public-boundary",
         "Restore the public ML row to its independently earned point-fit tier while retaining O3 as internal-estimator provenance only."),
    )
    for cell_id, before, after, evidence_id, reason in transition_specs:
        transition_id = f"tr-{cell_id}-07-capability-truth"
        if transition_id not in transition_ids:
            transitions.append({
                "transition_id": transition_id, "cell_id": cell_id,
                "from_work_status": before, "to_work_status": after,
                "evidence_ids": evidence_id, "reason": reason,
                "actor": "Codex 0.7 capability-truth reconciliation",
                "commit_sha": source_sha, "date": CAPABILITY_TRUTH_DATE,
            })

    CELLS.write_bytes(tsv_bytes(CELL_FIELDS, cells))
    EVIDENCE.write_bytes(tsv_bytes(EVIDENCE_FIELDS, evidence))
    TRANSITIONS.write_bytes(tsv_bytes(TRANSITION_FIELDS, transitions))
    print("0.7 capability-truth cells reconciled")


def check_c14_receipt_equivalence() -> None:
    """Verify C14's separate source-equivalence bridge for retained receipts.

    Raw all-attempt receipt SHA values are immutable and remain their original
    values. The source fingerprints were computed from those immutable
    revisions during the local C14 audit. This check proves that the current
    target matches the committed target fingerprint and is equal to (or
    distinct from) the recorded execution source as declared. It never
    promotes a cell or replaces the required independent completion review.
    """
    rows = read_tsv(C14_RECEIPT_EQUIVALENCE)
    expected_ids = {
        "mc-0568", "mc-0569", "mc-0576", "mc-0586", "mc-0587",
        "mc-0593", "mc-0594", "mc-0595", "mc-0596", "mc-0597",
    }
    ids = {row["cell_id"] for row in rows}
    if ids != expected_ids or len(rows) != len(expected_ids):
        raise SystemExit("C14 receipt-equivalence manifest does not name exactly ten cells")
    current_fingerprint = c14_model15_source_fingerprint()
    c17_bridge = current_fingerprint != C14_RECEIPT_EQUIVALENCE_FINGERPRINT
    if c17_bridge:
        check_c17_c14_current_source_compatibility(current_fingerprint)
    eligible_ids = set()
    for row in rows:
        if row["c14_target_sha"] != C14_RECEIPT_EQUIVALENCE_TARGET:
            raise SystemExit(f"{row['cell_id']}: wrong C14 equivalence target")
        if row["compared_paths"] != ";".join(C14_RECEIPT_EQUIVALENCE_PATHS):
            raise SystemExit(f"{row['cell_id']}: wrong C14 equivalence path set")
        raw_path = ROOT / row["raw_attempts_path"]
        if not raw_path.is_file():
            raise SystemExit(f"{row['cell_id']}: raw attempts receipt is unavailable")
        raw_rows = read_tsv(raw_path)
        raw_shas = {raw_row.get("source_sha", "") for raw_row in raw_rows}
        if not raw_rows or raw_shas != {row["retained_source_sha"]}:
            raise SystemExit(
                f"{row['cell_id']}: manifest SHA does not match its raw attempts receipt"
            )
        if row["target_fingerprint"] != C14_RECEIPT_EQUIVALENCE_FINGERPRINT:
            raise SystemExit(f"{row['cell_id']}: immutable C14 target fingerprint differs")
        eligible = row["equivalence_eligible"] == "TRUE"
        source_matches = row["source_fingerprint"] == row["target_fingerprint"]
        if eligible and not source_matches:
            raise SystemExit(f"{row['cell_id']}: eligible source fingerprint differs")
        if not eligible and source_matches:
            raise SystemExit(
                f"{row['cell_id']}: ineligible receipt unexpectedly matches the C14 target"
            )
        if eligible:
            eligible_ids.add(row["cell_id"])
    if eligible_ids != {"mc-0568", "mc-0569", "mc-0576"}:
        raise SystemExit("C14 receipt equivalence has an unexpected eligible cell set")
    print(
        f"C14 receipt equivalence: OK ({len(eligible_ids)} eligible, "
        f"{len(rows) - len(eligible_ids)} source-different retained receipts"
        + ("; C17 current-source compatibility PASS" if c17_bridge else "")
        + ")"
    )


def check_c17_c14_current_source_compatibility(
    current_fingerprint: str,
) -> None:
    """Authenticate C17's narrow current-source bridge for C14 receipts.

    The historical C14 target and raw receipts stay immutable. This bridge
    accepts only the separately authenticated latest C17 model-15 fingerprint and
    only when all retained attempts for the three previously promoted ordinary
    routes pass with the new ``coi`` carrier inert.
    """
    rows = read_tsv(C17_C14_CURRENT_SOURCE_COMPATIBILITY)
    expected_ids = set(C17_C14_COMPATIBLE_SEEDS)
    if len(rows) != len(expected_ids) or {row["cell_id"] for row in rows} != expected_ids:
        raise SystemExit(
            "C17 compatibility manifest must name exactly mc-0568, "
            "mc-0569, and mc-0576"
        )

    expected_paths = ";".join(C14_RECEIPT_EQUIVALENCE_PATHS)
    expected_source_files = ";".join(C17_C14_SOURCE_FILES)
    runner_path = ROOT / C17_C14_SOURCE_FILES[-1]
    runner_hash = hashlib.sha256(runner_path.read_bytes()).hexdigest()

    # Only for the remediation text below. The tests point this manifest at a
    # temporary directory outside ROOT, and relative_to() raises there, so an
    # unguarded call would replace a clean SystemExit with a traceback.
    try:
        manifest_display = C17_C14_CURRENT_SOURCE_COMPATIBILITY.relative_to(ROOT)
    except ValueError:
        manifest_display = C17_C14_CURRENT_SOURCE_COMPATIBILITY

    for row in rows:
        cell_id = row["cell_id"]
        if row["compared_paths"] != expected_paths:
            raise SystemExit(f"{cell_id}: wrong C17 compatibility path set")
        if row["source_fingerprint"] != current_fingerprint:
            raise SystemExit(
                f"{cell_id}: current model-15 fingerprint differs\n"
                f"    recorded {row['source_fingerprint']}\n"
                f"    current  {current_fingerprint}\n"
                "  MEANING: the authenticated model-15 surface itself moved -- one of the\n"
                "  named anchors above changed, not merely a file that happens to contain\n"
                "  them. This is the mode that CAN hide a real change to zero-one-beta\n"
                "  behaviour, so re-certifying is a genuine check rather than paperwork.\n"
                "  TO CLEAR: re-run the committed runner\n"
                f"    R_PROFILE_USER=/dev/null Rscript --no-init-file {C17_C14_SOURCE_FILES[-1]}\n"
                "  then, in\n"
                f"    {manifest_display}\n"
                "  repoint raw_attempts_path / provenance_path / summary_path, set\n"
                "  current_source_sha, AND update source_fingerprint on all three rows.\n"
                "  Compare mean_tau_relative_error against the previous receipt before you do:\n"
                "  unchanged digits mean the change is inert for model 15. If they MOVE, that\n"
                "  is a real regression -- do not update the fingerprint, fix the code."
            )
        if row["source_files"] != expected_source_files:
            raise SystemExit(f"{cell_id}: wrong C17 authenticated source-file set")
        if (
            row["attempts"] != "4"
            or row["passed"] != "4"
            or row["compatibility_result"] != "PASS_CURRENT_SOURCE_COMPATIBILITY"
        ):
            raise SystemExit(f"{cell_id}: current-source compatibility did not pass 4/4")
        if runner_hash != row["runner_sha256"]:
            raise SystemExit(f"{cell_id}: committed compatibility runner differs")

        raw_path = ROOT / row["raw_attempts_path"]
        provenance_path = ROOT / row["provenance_path"]
        summary_path = ROOT / row["summary_path"]
        if not all(path.is_file() for path in (raw_path, provenance_path, summary_path)):
            raise SystemExit(f"{cell_id}: C17 compatibility receipt is unavailable")

        provenance = {
            item["key"]: item["value"] for item in read_tsv(provenance_path)
        }
        if provenance.get("run_status") != "COMPLETE":
            raise SystemExit(f"{cell_id}: C17 compatibility run is incomplete")
        if provenance.get("source_sha") != row["current_source_sha"]:
            raise SystemExit(f"{cell_id}: compatibility source SHA differs")
        if provenance.get("runner_sha256") != row["runner_sha256"]:
            raise SystemExit(f"{cell_id}: compatibility runner hash differs")
        for source_file in C17_C14_SOURCE_FILES:
            blob = subprocess.run(
                ["git", "hash-object", source_file],
                cwd=ROOT,
                check=True,
                capture_output=True,
                text=True,
            ).stdout.strip()
            if provenance.get(f"git_blob:{source_file}") != blob:
                raise SystemExit(
                    f"{cell_id}: current source blob differs for {source_file}\n"
                    f"    receipt {provenance.get(f'git_blob:{source_file}')}\n"
                    f"    current {blob}\n"
                    "  MEANING: a pinned FILE changed while the authenticated model-15\n"
                    "  surface did NOT -- source_fingerprint already matched, and it is\n"
                    "  checked before this. So the receipt is stale, not wrong: nothing the\n"
                    "  three cells certify has moved. This is the cheap mode.\n"
                    "  TO CLEAR: re-run the committed runner\n"
                    f"    R_PROFILE_USER=/dev/null Rscript --no-init-file {C17_C14_SOURCE_FILES[-1]}\n"
                    "  then, in\n"
                    f"    {manifest_display}\n"
                    "  repoint raw_attempts_path / provenance_path / summary_path and set\n"
                    "  current_source_sha on all three rows. LEAVE source_fingerprint alone --\n"
                    "  changing it here would widen the claim beyond what was re-measured."
                )

        raw_rows = [
            item for item in read_tsv(raw_path) if item["cell_id"] == cell_id
        ]
        if (
            len(raw_rows) != 4
            or {item["seed"] for item in raw_rows}
            != C17_C14_COMPATIBLE_SEEDS[cell_id]
        ):
            raise SystemExit(f"{cell_id}: compatibility seed set differs")
        for attempt in raw_rows:
            passed = (
                attempt["source_sha"] == row["current_source_sha"]
                and attempt["runner_sha256"] == row["runner_sha256"]
                and attempt["status"] == "fit_ok"
                and attempt["convergence"] == "0"
                and attempt["pdHess"] == "TRUE"
                and float(attempt["max_gradient"]) <= 0.01
                and attempt["boundary_hit"] == "FALSE"
                and attempt["support_gate"] == "TRUE"
                and float(attempt["mode_correlation"]) > 0.45
                and attempt["n_coi_re_terms"] == "0"
                and attempt["error"] == "none"
            )
            if not passed:
                raise SystemExit(f"{cell_id}: a compatibility attempt fails its contract")

        summary = [
            item for item in read_tsv(summary_path) if item["cell_id"] == cell_id
        ]
        if (
            len(summary) != 1
            or summary[0]["attempts"] != "4"
            or summary[0]["passed"] != "4"
            or summary[0]["decision"] != "PASS_CURRENT_SOURCE_COMPATIBILITY"
            or float(summary[0]["mean_tau_relative_error"]) > 0.40
        ):
            raise SystemExit(f"{cell_id}: compatibility summary does not pass")


def c14_model15_source_fingerprint() -> str:
    """Hash the closed model-15 surface governing C14's ZOB receipts.

    A model-9 ZINB routing repair must not invalidate a model-15 zero-one-beta
    receipt.  Each named source anchor below is therefore part of this hash;
    changing a builder, carrier, extractor, or the model-15 likelihood changes
    it, while unrelated family code does not.
    """
    r_source = (ROOT / "R/drmTMB.R").read_text(encoding="utf-8")
    cpp_source = (ROOT / "src/drmTMB.cpp").read_text(encoding="utf-8")

    # C17-B widens only the missing-response diagnostic so it names the already
    # fitted same-symbol zoi slope. Missing responses remain rejected before a
    # likelihood object is built, so this prose-only abort must not invalidate
    # C14's immutable fit-source equivalence receipts. Normalize that one abort
    # block to its C14 wording before hashing; all builder/carrier/extractor and
    # model-15 likelihood bytes remain fingerprinted exactly.
    c17_diagnostic = '''  if (include_missing_response && length(zoi_re$terms) > 0L) {
    cli::cli_abort(c(
      "The zero-one-beta zoi q1 random-effect gate does not support missing responses.",
      "i" = "Use complete observed responses with either {.code zoi ~ 1 + (1 | id)} or the same-raw-symbol slope form {.code zoi ~ x + (0 + x | id)}."
    ))
  }
'''
    c14_diagnostic = '''  if (include_missing_response && length(zoi_re$terms) > 0L) {
    cli::cli_abort(c(
      "The zero-one-beta zoi random-intercept q1 gate does not support missing responses.",
      "i" = "Use complete observed responses for {.code bf(y ~ x, sigma ~ 1, zoi ~ 1 + (1 | id), coi ~ 1)}."
    ))
  }
'''
    if c17_diagnostic not in r_source:
        raise SystemExit("C17-B diagnostic normalization anchor is unavailable")
    r_source = r_source.replace(c17_diagnostic, c14_diagnostic, 1)

    def section(source: str, start: str, end: str, label: str) -> str:
        start_index = source.find(start)
        if start_index < 0:
            raise SystemExit(f"C14 equivalence anchor is unavailable: {label}")
        end_index = source.find(end, start_index)
        if end_index < 0:
            raise SystemExit(f"C14 equivalence endpoint is unavailable: {label}")
        return source[start_index:end_index]

    sections = (
        section(
            r_source,
            "drm_build_zero_one_beta_spec <- function(",
            "drm_build_beta_binomial_spec <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[0],
        ),
        section(
            r_source,
            "zero_one_beta_start <- function(",
            "poisson_start <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[1],
        ),
        section(
            r_source,
            "zero_one_beta_atom_tmb_data <- function(",
            "# TMB data for the scoped second structured location field",
            C14_RECEIPT_EQUIVALENCE_PATHS[2],
        )
        + section(
            r_source,
            "split_tmb_sdpars <- function(",
            "split_tmb_corpars <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[2],
        )
        + section(
            r_source,
            "split_tmb_random_effects <- function(",
            "sd_mu_group_values <- function(",
            C14_RECEIPT_EQUIVALENCE_PATHS[2],
        ),
        section(
            cpp_source,
            "  } else if (model_type == 15) {",
            "  } else if (model_type == 14) {",
            C14_RECEIPT_EQUIVALENCE_PATHS[3],
        ),
    )
    fingerprint = hashlib.sha256()
    for label, source in zip(C14_RECEIPT_EQUIVALENCE_PATHS, sections):
        fingerprint.update(label.encode())
        fingerprint.update(b"\\0")
        fingerprint.update(source.encode())
        fingerprint.update(b"\\0")
    return fingerprint.hexdigest()


def source_path_exists(value: str) -> bool:
    if not value or value.startswith(("http://", "https://")):
        return True
    first = value.split(";", 1)[0].strip()
    candidate = first.split(":", 1)[0]
    return (ROOT / candidate).exists()


def bibliography_keys() -> set[str]:
    """Citation keys declared in REFERENCES.bib.

    A `source_citation` must resolve to one of these. Free-text citations were
    rejected deliberately: an unresolvable string looks like provenance without
    being checkable, which is the failure #1011 documented for prose fields.
    """
    path = ROOT / "REFERENCES.bib"
    if not path.exists():
        return set()
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r"^@\w+\{\s*([^,\s]+)\s*,", text, flags=re.MULTILINE))


def validate(
    cells: list[dict[str, str]],
    evidence: list[dict[str, str]],
    transitions: list[dict[str, str]],
) -> None:
    errors: list[str] = []
    bib_keys = bibliography_keys()
    if list(cells[0]) != CELL_FIELDS:
        errors.append("cells.tsv header does not match schema")
    if evidence and list(evidence[0]) != EVIDENCE_FIELDS:
        errors.append("evidence.tsv header does not match schema")
    if transitions and list(transitions[0]) != TRANSITION_FIELDS:
        errors.append("transitions.tsv header does not match schema")

    ids = [row["cell_id"] for row in cells]
    if len(ids) != len(set(ids)):
        errors.append("cell_id values are not unique")
    evidence_ids = [row["evidence_id"] for row in evidence]
    if len(evidence_ids) != len(set(evidence_ids)):
        errors.append("evidence_id values are not unique")
    transition_ids = [row["transition_id"] for row in transitions]
    if len(transition_ids) != len(set(transition_ids)):
        errors.append("transition_id values are not unique")

    by_axis = Counter(row["axis"] for row in cells)
    if by_axis != Counter({
        "model_surface": MODEL_SURFACE_COUNT,
        "missing_response": 18,
        "association": ASSOCIATION_COUNT,
        "missing_predictor": MISSING_PREDICTOR_COUNT,
    }):
        errors.append(
            f"axis counts are {dict(by_axis)}, expected "
            f"{MODEL_SURFACE_COUNT} model + 18 missing-response + "
            f"{ASSOCIATION_COUNT} association + "
            f"{MISSING_PREDICTOR_COUNT} missing-predictor"
        )
    route_names = {row["family_route"] for row in cells if row["axis"] == "missing_response"}
    if route_names != {route for _, route, _, _, _ in ROUTES}:
        errors.append("missing_response route set does not match the 18-route contract")

    cell_ids = set(ids)
    evidence_id_set = set(evidence_ids)
    evidence_by_id = {row["evidence_id"]: row for row in evidence}
    for row in cells:
        if row["capability_status"] not in CAPABILITY_STATUSES:
            errors.append(f"{row['cell_id']}: invalid capability_status")
        if row["work_status"] not in WORK_STATUSES:
            errors.append(f"{row['cell_id']}: invalid work_status")
        if row["test_gate"] not in TEST_GATES:
            errors.append(f"{row['cell_id']}: invalid test_gate")
        if row["evidence_tier"] not in EVIDENCE_TIERS:
            errors.append(f"{row['cell_id']}: invalid evidence_tier")
        if row["provenance_relation"] not in PROVENANCE_RELATIONS:
            errors.append(f"{row['cell_id']}: invalid provenance_relation")
        citation = row["source_citation"]
        if citation and citation != "none" and citation not in bib_keys:
            errors.append(
                f"{row['cell_id']}: source_citation {citation} is not a key in "
                "REFERENCES.bib"
            )
        if citation in ("", "none") and row["provenance_relation"] not in (
            "", "none", "independent_derivation"
        ):
            errors.append(
                f"{row['cell_id']}: provenance_relation "
                f"{row['provenance_relation']} names a source relation but "
                "source_citation is empty"
            )
        for anchor_field in ("assumption_anchor", "comparator_bridge"):
            anchor = row[anchor_field]
            if anchor and anchor != "none" and not source_path_exists(anchor):
                errors.append(
                    f"{row['cell_id']}: {anchor_field} points at a missing path "
                    f"{anchor}"
                )
        if not row["claim_boundary"] or not row["next_gate"]:
            errors.append(f"{row['cell_id']}: claim_boundary and next_gate are required")
        primary = row["primary_evidence_id"]
        if primary and primary not in evidence_id_set:
            errors.append(f"{row['cell_id']}: missing primary evidence {primary}")
        elif primary and evidence_by_id[primary]["cell_id"] != row["cell_id"]:
            errors.append(
                f"{row['cell_id']}: primary evidence {primary} belongs to "
                f"{evidence_by_id[primary]['cell_id']}"
            )

    # The model-cell ledger feeds the public capability surface. Keep the eight
    # conceptual inference-ready configurations (ten endpoint-level ledger
    # rows) explicit about their two distinct interval channels so generic
    # historical "Wald" wording cannot erase the correction or apply it to
    # the sigma axis.
    by_id = {row["cell_id"]: row for row in cells}

    # Bind the exact 0.7 capability-truth repair.  Two historical C14 boundary
    # IDs are deliberately overridden by landed O2 behavior; every other C14
    # member remains source-pinned and non-implemented.
    truth_expected = {
        "mc-0058": ("rejected_by_design", "deferred", "none", "ev-mc-0058-capability-truth-rejection"),
        "mc-0060": ("implemented", "verified", "diagnostic_only", "ev-mc-0060-capability-truth-o2"),
        "mc-0062": ("implemented", "verified", "diagnostic_only", "ev-mc-0062-capability-truth-o2"),
        "mc-0068": ("rejected_by_design", "deferred", "none", "ev-mc-0068-capability-truth-rejection"),
        "mc-0227": ("implemented", "verified", "point_fit_recovery", "ev-mc-0227-arc2b"),
    }
    for cell_id, expected_state in truth_expected.items():
        row = by_id.get(cell_id, {})
        actual_state = tuple(row.get(field, "") for field in (
            "capability_status", "work_status", "evidence_tier", "primary_evidence_id"
        ))
        if actual_state != expected_state:
            errors.append(
                f"{cell_id}: capability-truth state changed: {actual_state!r}"
            )
    for cell_id in CAPABILITY_TRUTH_C14_IMPLEMENTED_OVERRIDES:
        comparator = evidence_by_id.get(
            f"ev-{cell_id}-capability-truth-o2", {}
        )
        if (
            comparator.get("evidence_class") != "external_comparator"
            or "glmmTMB" not in comparator.get("run_id", "")
            or "WEAK INDEPENDENCE" not in comparator.get("claim_boundary", "")
            or "same joint-Laplace" not in comparator.get("claim_boundary", "")
        ):
            errors.append(
                f"{cell_id}: glmmTMB(REML=TRUE) weak-independence comparator binding changed"
            )
    if "unavailable through drmTMB()" not in by_id.get("mc-0227", {}).get(
        "claim_boundary", ""
    ):
        errors.append("mc-0227: public ML boundary does not identify O3 as internal-only")
    for evidence_id in INTERNAL_ONLY_ESTIMATOR_EVIDENCE_IDS:
        internal = evidence_by_id.get(evidence_id, {})
        if "unavailable through drmTMB()" not in internal.get("claim_boundary", ""):
            errors.append(f"{evidence_id}: internal estimator boundary is missing")
        cell = by_id.get(internal.get("cell_id", ""), {})
        if (
            cell.get("primary_evidence_id") == evidence_id
            and cell.get("evidence_tier") in {
                "inference_ready_with_caveats", "supported"
            }
        ):
            errors.append(
                f"{evidence_id}: internal estimator evidence grants public reporting permission"
            )
    location_bias_t_ids = {
        "mc-0085", "mc-0086", "mc-0153", "mc-0154",
        "mc-0272", "mc-0285", "mc-0309",
    }
    sigma_raw_wald_ids = {"mc-0276", "mc-0301", "mc-0313"}
    for cell_id in sorted(location_bias_t_ids):
        boundary = by_id[cell_id]["claim_boundary"]
        for required in (
            "location-axis bias-corrected small-sample-t Wald",
            "inference-ready with caveats",
            "not nominal",
        ):
            if required not in boundary:
                errors.append(
                    f"{cell_id}: location-axis interval boundary omits {required!r}"
                )
    for cell_id in sorted(sigma_raw_wald_ids):
        boundary = by_id[cell_id]["claim_boundary"]
        for required in (
            "raw uncorrected log-SD Wald-z",
            "location-axis bias+t correction does not apply to sigma",
            "profile is diagnostic-only at g=8",
            "inference-ready with caveats",
            "not supported",
        ):
            if required not in boundary:
                errors.append(
                    f"{cell_id}: sigma interval boundary omits {required!r}"
                )

    for row in evidence:
        if row["cell_id"] not in cell_ids:
            errors.append(f"{row['evidence_id']}: unknown cell_id")
        if row["evidence_class"] not in EVIDENCE_CLASSES:
            errors.append(
                f"{row['evidence_id']}: invalid evidence_class "
                f"{row['evidence_class']!r}"
            )
        if row["evidence_class"] == "external_comparator":
            # Rendering matches package names against a fixed tuple, so a comparator
            # nobody registered there would silently render a BLANK badge -- the row
            # would look like no comparator exists. Fail loudly instead: an
            # unregistered package must be added to COMPARATOR_PACKAGES to be recorded.
            named = f"{row['run_id']} {row['result']}"
            if not any(pkg in named for pkg in COMPARATOR_PACKAGES):
                errors.append(
                    f"{row['evidence_id']}: run_id/result names no package from "
                    "COMPARATOR_PACKAGES; register it there or the badge renders blank"
                )
            boundary = row["claim_boundary"].upper()
            if not (
                "STRONG INDEPENDENCE" in boundary or "WEAK INDEPENDENCE" in boundary
            ):
                errors.append(
                    f"{row['evidence_id']}: claim_boundary must declare STRONG "
                    "INDEPENDENCE or WEAK INDEPENDENCE"
                )
        # The frozen 2026-07-09 census contains historical cell names and
        # semicolon-packed provenance as well as paths. Preserve those verbatim
        # during MR-T0; require resolvable paths for every new evidence record.
        if (
            row["evidence_class"] != "legacy_model_evidence"
            and not source_path_exists(row["path_or_url"])
        ):
            errors.append(f"{row['evidence_id']}: unresolved path {row['path_or_url']}")
    for row in transitions:
        if row["cell_id"] not in cell_ids:
            errors.append(f"{row['transition_id']}: unknown cell_id")
        if row["to_work_status"] not in WORK_STATUSES:
            errors.append(f"{row['transition_id']}: invalid target work status")
        for evidence_id in filter(None, row["evidence_ids"].split(";")):
            if evidence_id not in evidence_id_set:
                errors.append(f"{row['transition_id']}: unknown evidence {evidence_id}")

    model = [row for row in cells if row["axis"] == "model_surface"]
    status_counts = Counter(row["capability_status"] for row in model)
    # C14 restores the 330 source-pinned package boundaries and then splits ten
    # lossy structured zero-one-beta representatives into q1 and q2-plus leaves.
    # C18 independently splits ten further lossy structured zero-one-beta ATOM
    # (zoi/coi) representatives into q1 and q2-plus leaves the same non-promoting
    # way; it does not touch C14's own taxonomy or receipt fingerprint.
    # C16 independently promotes ten exact q1 structured zero-one-beta leaves
    # after source-bound recovery and fresh three-lens GO. C17-B promotes the
    # exact ordinary zero-one-beta zoi same-symbol q1 slope after authenticated
    # recovery and fresh Fisher/Noether/Rose GO. C17-C1 promotes the exact coi
    # q1 random intercept with a documented sparse-atom conditional-mode warning.
    # C17-C2 promotes the exact coi same-raw-symbol q1 random slope while retaining
    # weak boundary-row predictor spread as a conditional-mode warning. C18 then
    # promotes seven of the ten structured zero-one-beta ATOM (zoi/coi) q1 leaves
    # after source-bound four-seed local recovery, a per-group separation filter,
    # and fresh three-lens GO following repair of the D-43 panel's three blocking
    # defects; mc-0615 stays not_implemented after a documented
    # BLOCKED_LOCAL_FIXTURE attempt, and mc-0606/mc-0616 (spatial) stay
    # not_implemented and refused by design. The remaining 10 rows are the
    # actionable implementation backlog, not a claim that every boundary is
    # mathematically impossible.
    # Arc 4b's mc-0207 split adds two new implemented leaves (mc-0715, mc-0716);
    # the original mc-0207 stays implemented (the REML gate code does not reject
    # these shapes), so implemented rises 337 -> 339 while rejected_by_design and
    # not_implemented are untouched -- the split changes evidence_tier, not
    # capability_status.
    expected = Counter(
        {
            "implemented": 341,
            "rejected_by_design": (
                C14_BOUNDARY_COUNT
                + len(C14_ZOB_LEAF_TAXONOMY)
                + len(C18_ZOB_ATOM_LEAF_TAXONOMY)
                - len(CAPABILITY_TRUTH_C14_IMPLEMENTED_OVERRIDES)
            ),
            "not_implemented": 10,
        }
    )
    if status_counts != expected:
        errors.append(f"model status counts changed: {dict(status_counts)}")

    # The frozen census has 127 point_fit_recovery cells after the exact
    # ten-leaf promotion, B3's exact four q6 mu2 target promotions, C17-B's
    # exact zero-one-beta zoi same-symbol q1 slope promotion, C1's exact
    # 24-cell promotion, C2's exact 25-cell promotion to interval feasible,
    # C3's exact 36-cell and C4's exact 23-cell promotions, C17-C1's exact
    # zero-one-beta coi q1 random-intercept promotion, and C17-C2's exact
    # same-raw-symbol coi q1 random-slope promotion. C4 moves eleven frozen
    # point-fit cells and twelve diagnostic-only companions. C18 adds seven
    # exact q1 structured zero-one-beta ATOM (zoi/coi) promotions (mc-0603,
    # mc-0604, mc-0605, mc-0607, mc-0613, mc-0614, mc-0617); mc-0615 is not
    # promoted.
    # Approved inserts take a higher source_order and so cannot disturb this
    # number; every frozen-cell promotion needs a named
    # transition and evidence receipt.
    frozen = [row for row in model if int(row["source_order"]) <= FROZEN_CENSUS_COUNT]
    if len(frozen) != FROZEN_CENSUS_COUNT:
        errors.append(
            f"frozen census size changed: {len(frozen)} (expected {FROZEN_CENSUS_COUNT})"
        )
    frozen_recovery = sum(
        row["evidence_tier"] == "point_fit_recovery" for row in frozen
    )
    if frozen_recovery != FROZEN_CENSUS_POINT_FIT_RECOVERY:
        errors.append(
            f"frozen census point_fit_recovery changed: {frozen_recovery} "
            f"(expected {FROZEN_CENSUS_POINT_FIT_RECOVERY}); a frozen cell was promoted "
            "or demoted"
        )

    arc1_by_cell = {row["cell_id"]: row for row in cells}
    for cell_id, target_id in ARC1_GAUSSIAN_FIXED_TARGETS.items():
        direct_target = target_id.split("::", 1)[1]
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = f"ev-{cell_id}-arc1-fixed-profile"
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition_id = f"tr-{cell_id}-arc1-fixed-profile"
        transition = next(
            (row for row in transitions if row["transition_id"] == transition_id),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or direct_target not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC1_GAUSSIAN_FIXED_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: Arc 1 Gaussian fixed-target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("path_or_url") != ARC1_GAUSSIAN_FIXED_RECONCILIATION
            or evidence_row.get("commit_sha") != ARC1_GAUSSIAN_FIXED_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 1 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 1 transition must remain verified-to-verified")

    for cell_id, contract in ARC1_ADDITIONAL_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (
                row for row in transitions
                if row["transition_id"] == contract["transition_id"]
            ),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or direct_target not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC1_GAUSSIAN_FIXED_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: Arc 1 additional target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("path_or_url") != contract["reconciliation"]
            or evidence_row.get("commit_sha") != ARC1_GAUSSIAN_FIXED_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 1 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 1 transition must remain verified-to-verified")

    for cell_id, contract in ARC2_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (
                row for row in transitions
                if row["transition_id"] == contract["transition_id"]
            ),
            {},
        )
        claim_snippet = contract.get("claim_snippet", direct_target)
        # Cells whose receipts were produced at a later lane commit carry their
        # own source sha. Receipts must always name a REAL, PUSHED commit: an
        # earlier mc-0013/mc-0015 run recorded a detached sha that existed only
        # inside the Totoro worktree, which is not reproducible, and was re-run.
        cell_source_sha = contract.get("source_sha", ARC2_SOURCE_SHA)
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or claim_snippet not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != cell_source_sha
        ):
            errors.append(f"{cell_id}: Arc 2 target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("path_or_url") != contract["reconciliation"]
            or evidence_row.get("commit_sha") != cell_source_sha
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 2 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 2 transition must remain verified-to-verified")

    for cell_id, contract in ARC3_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        claim_snippet = contract.get("claim_snippet", direct_target)
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (row for row in transitions if row["transition_id"] == contract["transition_id"]),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or claim_snippet not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC3_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: Arc 3 target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("commit_sha") != ARC3_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 3 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 3 transition must remain verified-to-verified")

    for cell_id, contract in ARC4_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        claim_snippet = contract.get("claim_snippet", direct_target)
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (row for row in transitions if row["transition_id"] == contract["transition_id"]),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or claim_snippet not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC4_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: Arc 4 target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("commit_sha") != ARC4_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 4 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 4 transition must remain verified-to-verified")

    for cell_id, contract in ARC5_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        claim_snippet = contract.get("claim_snippet", direct_target)
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (row for row in transitions if row["transition_id"] == contract["transition_id"]),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or claim_snippet not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC5_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: Arc 5 target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("commit_sha") != ARC5_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 5 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 5 transition must remain verified-to-verified")

    for cell_id, contract in ARC6_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        claim_snippet = contract.get("claim_snippet", direct_target)
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (row for row in transitions if row["transition_id"] == contract["transition_id"]),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or claim_snippet not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC6_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: Arc 6 target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("commit_sha") != ARC6_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: Arc 6 evidence binding changed")
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: Arc 6 transition must remain verified-to-verified")

    mc0292 = arc1_by_cell.get("mc-0292", {})
    if mc0292.get("evidence_tier") == "interval_feasible":
        errors.append(
            "mc-0292: WITHHELD cell (seed-303 receipt excludes the true 0.7) must not "
            "be promoted to interval_feasible"
        )

    for cell_id, contract in ARC135_TARGETS.items():
        target_id = contract["target_id"]
        direct_target = target_id.split("::", 1)[1]
        claim_snippet = contract.get("claim_snippet", direct_target)
        cell = arc1_by_cell.get(cell_id, {})
        evidence_id = contract["evidence_id"]
        evidence_row = evidence_by_id.get(evidence_id, {})
        transition = next(
            (row for row in transitions if row["transition_id"] == contract["transition_id"]),
            {},
        )
        if (
            cell.get("evidence_tier") != "interval_feasible"
            or cell.get("work_status") != "verified"
            or cell.get("primary_evidence_id") != evidence_id
            or claim_snippet not in cell.get("claim_boundary", "")
            or cell.get("updated_commit") != ARC135_SOURCE_SHA
        ):
            errors.append(f"{cell_id}: 135-trace target row changed")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "contract_test"
            or evidence_row.get("commit_sha") != ARC135_SOURCE_SHA
            or evidence_row.get("result") != "interval_feasible"
            or direct_target not in evidence_row.get("claim_boundary", "")
        ):
            errors.append(f"{evidence_id}: 135-trace evidence binding changed")
        if cell_id in {"mc-0595", "mc-0596", "mc-0653"}:
            boundary = cell.get("claim_boundary", "")
            if "REML is unavailable" not in boundary or "ML sigma-axis low bias" not in boundary:
                errors.append(
                    f"{cell_id}: structured-sigma claim_boundary must name ML bias and REML unavailable"
                )
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: 135-trace transition must remain verified-to-verified")

    for cell_id in ARC135_WITHHELD:
        cell = arc1_by_cell.get(cell_id, {})
        if cell.get("evidence_tier") == "interval_feasible":
            errors.append(
                f"{cell_id}: 135-trace WITHHOLD cell must not be promoted to interval_feasible"
            )

    parity_by_cell = {
        row["cell_id"]: row for row in read_tsv(PARITY_TRIAGE)
    }
    arc1_parity_targets = {
        **ARC1_GAUSSIAN_FIXED_TARGETS,
        **{
            cell_id: contract["target_id"]
            for cell_id, contract in ARC1_ADDITIONAL_TARGETS.items()
        },
    }
    for cell_id, target_id in arc1_parity_targets.items():
        direct_target = target_id.split("::", 1)[1]
        parity_text = " ".join(
            parity_by_cell.get(cell_id, {}).get(field, "")
            for field in ("not_covered", "rationale")
        )
        if (
            "DATED SUPERSESSION (2026-08-02)" not in parity_text
            or direct_target not in parity_text
        ):
            errors.append(
                f"{cell_id}: parity triage must retain the dated exact-target "
                "Arc 1 interval supersession"
            )
    mc0438_parity = " ".join(
        parity_by_cell.get("mc-0438", {}).get(field, "")
        for field in ("not_covered", "rationale")
    )
    if (
        "DATED STOP (2026-08-02)" not in mc0438_parity
        or "sd:mu:phylo_interaction(1 | plant:pollinator)" not in mc0438_parity
        or "nonfinite" not in mc0438_parity
    ):
        errors.append("mc-0438: parity triage must retain the dated Arc 1 STOP")

    # parity-triage.tsv rationales are free text, and most of them make no
    # checkable claim. One phrasing does: when a rationale says a campaign
    # "promoted this cell to <tier>", that is an assertion about cells.tsv and
    # it can be false. On 2026-08-03 nine rows (mc-0279/0282/0286/0291/0298/
    # 0303/0304/0315/0316) claimed promotion to interval_feasible while the
    # ledger still read point_fit_recovery, because one PR wrote the rationale
    # for twelve cells but promoted only three. Nothing caught it; the next PR
    # happened to make the claims true.
    #
    # Deliberately narrow. It fires ONLY on that exact phrase, so the other
    # rationale templates -- the 116 "Parked: next_gate directs preserving the
    # existing model-surface evidence tier" rows, the "Frontier per governing
    # rule" rows, the one-offs -- are untouched. Do NOT widen it to the parked
    # template without first repairing that corpus: as of 2026-08-03, 89 of
    # those 116 rows sit at interval_feasible or above while still asserting
    # that no interval campaign is being pursued, so any check over them would
    # report 89 failures on a clean tree. See
    # docs/dev-log/after-task/2026-08-03-parity-triage-claim-check.md.
    promotion_claim = re.compile(
        r"promoted this cell to (" + "|".join(sorted(EVIDENCE_TIERS)) + r")\b"
    )
    cells_by_id = {row["cell_id"]: row for row in cells}
    for cell_id, parity_row in sorted(parity_by_cell.items()):
        # Search both free-text columns, not just `rationale`. Seven rows already
        # name a tier in `not_covered`, and nothing stops the claim phrasing
        # migrating there. No row carries the phrase in that column today, so
        # widening the search costs nothing now and guards later.
        match = next(
            (
                found
                for found in (
                    promotion_claim.search(parity_row.get(field, ""))
                    for field in ("rationale", "not_covered")
                )
                if found
            ),
            None,
        )
        if not match:
            continue
        claimed_tier = match.group(1)
        cell = cells_by_id.get(cell_id)
        if cell is None:
            errors.append(
                f"{cell_id}: parity triage claims promotion to {claimed_tier} "
                "but the cell is absent from the ledger"
            )
        elif cell.get("evidence_tier") != claimed_tier:
            errors.append(
                f"{cell_id}: parity triage claims promotion to {claimed_tier}, "
                f"ledger evidence_tier is {cell.get('evidence_tier')}"
            )

    by_cell = {row["cell_id"]: row for row in cells}
    b3_observed = {
        row["cell_id"]
        for row in model
        if row["q_gate"] == "q6"
        and row["dpar"] == "mu2"
        and row["effect_type"] == "structured"
        and row["estimator"] == "ML"
        and row["evidence_tier"] == "interval_feasible"
    }
    if b3_observed != set(B3_Q6_MU2_TARGETS):
        errors.append(
            "B3 q6 mu2 interval-feasible allowlist changed: "
            f"{sorted(b3_observed)}"
        )
    b3_latest_transition = {
        row["cell_id"]: row for row in transitions
    }
    for cell_id, (provider, paired_mu1, target_id) in B3_Q6_MU2_TARGETS.items():
        cell = by_cell.get(cell_id, {})
        evidence_id = f"ev-{cell_id}-b3-q6-mu2-interval"
        evidence_row = evidence_by_id.get(evidence_id, {})
        expected_receipt = (
            "docs/dev-log/interval-feasibility/results/"
            f"{B3_Q6_MU2_RUNNER_SHA}/b2-q6-proof-profile/{cell_id}/"
            f"b2-q6-proof-{cell_id}-high-seed-20260731-receipt.tsv"
        )
        if (
            cell.get("structure_provider") != provider
            or cell.get("family_route") != "biv_gaussian"
            or cell.get("dpar") != "mu2"
            or cell.get("q_gate") != "q6"
            or cell.get("estimator") != "ML"
            or cell.get("capability_status") != "implemented"
            or cell.get("work_status") != "verified"
            or cell.get("evidence_tier") != "interval_feasible"
            or cell.get("primary_evidence_id") != evidence_id
        ):
            errors.append(f"{cell_id}: B3 canonical target row changed")
        allowed_paired_tiers = {"point_fit_recovery"}
        if paired_mu1 in C4_B3_PAIRED_MU1_IDS:
            allowed_paired_tiers.add("interval_feasible")
        if by_cell.get(paired_mu1, {}).get("evidence_tier") not in allowed_paired_tiers:
            errors.append(f"{paired_mu1}: paired mu1 row inherited B3 target promotion")
        if (
            evidence_row.get("cell_id") != cell_id
            or evidence_row.get("evidence_class") != "estimator_diagnostic"
            or evidence_row.get("path_or_url") != expected_receipt
            or evidence_row.get("commit_sha") != B3_Q6_MU2_RUNNER_SHA
            or evidence_row.get("result") != "interval_feasible"
        ):
            errors.append(f"{evidence_id}: B3 evidence binding changed")
        if target_id not in B3_Q6_MU2_PACKET.read_text(encoding="utf-8"):
            errors.append(f"{cell_id}: exact direct target missing from B3 packet")
        transition = b3_latest_transition.get(cell_id, {})
        if (
            transition.get("from_work_status") != "verified"
            or transition.get("to_work_status") != "verified"
            or transition.get("evidence_ids") != evidence_id
        ):
            errors.append(f"{cell_id}: B3 transition must remain verified-to-verified")

    missing = {row["family_route"]: row for row in cells if row["axis"] == "missing_response"}
    for route, row in missing.items():
        gate = int(row["test_gate"][1:])
        if row["capability_status"] == "implemented" and gate < 1:
            errors.append(f"{route}: implemented capability requires G1 or higher")
        if row["capability_status"] != "implemented" and gate > 0:
            errors.append(f"{route}: G1+ requires implemented capability")
        if row["work_status"] == "verified" and gate < 3:
            errors.append(f"{route}: verified work status requires G3 or higher")
        if gate >= 3 and row["work_status"] != "verified":
            errors.append(f"{route}: G3+ evidence must display verified work status")

    latest_transition = {}
    for row in transitions:
        latest_transition[row["cell_id"]] = row
    for cell in cells:
        transition = latest_transition.get(cell["cell_id"])
        if transition and transition["to_work_status"] != cell["work_status"]:
            errors.append(
                f"{cell['cell_id']}: current work status does not match latest transition"
            )

    evidence_by_cell: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in evidence:
        evidence_by_cell[row["cell_id"]].append(row)
    for route, cell in missing.items():
        gate = int(cell["test_gate"][1:])
        if gate < 2:
            continue
        cell_evidence = evidence_by_cell[cell["cell_id"]]
        g2_ids = {
            row["evidence_id"]
            for row in cell_evidence
            if row["evidence_class"] == "g2_contract_test"
            and row["result"] == "G2_pass"
        }
        if not g2_ids:
            errors.append(f"{route}: G2+ requires passing same-cell G2 contract evidence")
        recovery_ids = {
            row["evidence_id"]
            for row in cell_evidence
            if row["evidence_class"] == "recovery_test"
            and row["result"] == "G3_pass"
        }
        if gate >= 3 and not recovery_ids:
            errors.append(f"{route}: G3+ requires passing same-cell recovery evidence")
        primary = evidence_by_id.get(cell["primary_evidence_id"])
        if gate >= 3 and primary and (
            primary["evidence_class"] != "recovery_test"
            or primary["result"] != "G3_pass"
        ):
            errors.append(f"{route}: G3+ primary evidence must be a passing recovery test")
        transition = latest_transition.get(cell["cell_id"])
        transition_evidence = set(
            filter(None, transition["evidence_ids"].split(";"))
        ) if transition else set()
        if not transition or not (transition_evidence & g2_ids):
            errors.append(f"{route}: latest G2+ transition must cite G2 contract evidence")
        if gate >= 3 and (
            not transition or not (transition_evidence & recovery_ids)
        ):
            errors.append(f"{route}: latest G3+ transition must cite recovery evidence")

    if errors:
        raise SystemExit("Capability ledger validation failed:\n- " + "\n- ".join(errors))


def model_projection(
    cells: list[dict[str, str]], evidence: list[dict[str, str]]
) -> list[dict[str, str]]:
    evidence_by_id = {row["evidence_id"]: row for row in evidence}
    rows = sorted(
        (row for row in cells if row["axis"] == "model_surface"),
        key=lambda row: int(row["source_order"]),
    )
    return [{
        "family": row["family_route"],
        "model_type": row["model_type"],
        "dpar": row["dpar"],
        "effect_type": row["effect_type"],
        "structure_provider": row["structure_provider"],
        "dimension": row["dimension"],
        "q_gate": row["q_gate"],
        "estimator": row["estimator"],
        "status": row["capability_status"],
        "planning_class": planning_class(row),
        "evidence_tier": row["evidence_tier"],
        "evidence_source": (
            evidence_by_id[row["primary_evidence_id"]]["path_or_url"]
            if row["primary_evidence_id"]
            else row["legacy_evidence_source"]
        ),
        "notes": row["claim_boundary"] or row["notes"],
    } for row in rows]


def planning_class(row: dict[str, str]) -> str:
    """Return a visible scope class without treating an unimplemented cell as impossible.

    It is a planning cue, not an effort estimate or an inference claim. REML is
    a restricted-likelihood objective; an ML fit does not automatically supply it.
    """
    if row["capability_status"] == "implemented":
        return "available"
    if row["estimator"] in {"REML", "AI-REML"}:
        return "estimator method"
    if row["effect_type"] == "structured":
        return "covariance / model method"
    return "admission candidate"


def widget_value(
    model: list[dict[str, str]], generated_date: str
) -> dict[str, object]:
    tiers = [
        "supported", "inference_ready_with_caveats", "interval_feasible",
        "diagnostic_only", "point_fit_recovery", "none", "miswired",
    ]
    families = sorted({row["family"] for row in model})
    matrix = {
        family: {tier: 0 for tier in tiers}
        for family in families
    }
    for row in model:
        if row["status"] == "implemented":
            matrix[row["family"]][row["evidence_tier"]] += 1
    status_counts = Counter(row["status"] for row in model)
    tier_counts = Counter(
        row["evidence_tier"] for row in model if row["status"] == "implemented"
    )
    return {
        "generated": generated_date,
        "rows": [
            {key: row[key] for key in (
                "family", "dpar", "effect_type", "structure_provider",
                "dimension", "q_gate", "estimator", "status", "planning_class", "evidence_tier",
            )}
            for row in model
        ],
        "families": families,
        "tiers": tiers,
        "matrix": matrix,
        "status_counts": dict(status_counts),
        "tier_counts": dict(tier_counts),
        "total": len(model),
    }


def missing_next_gate(row: dict[str, str]) -> str:
    """Return current reader-facing next-step wording for a missing-response row."""
    if row["next_gate"] == "G4/G5 interval and coverage evidence are outside this arc.":
        return (
            "G4/G5 framework is ready and partial calibration evidence is retained; "
            "all routes remain G3 because the campaign stopped before route-wide "
            "reconciliation and promotion review."
        )
    next_gate = row["next_gate"]
    if row["family_route"] != "cumulative_logit":
        next_gate = next_gate.replace(
            "Extending this claim to `cumulative_logit` or any other",
            "Extending this claim to additional `cumulative_logit` targets or any other",
        )
    return next_gate


def missing_g4g5_summary() -> str:
    """Return the current, target-rung-grain missing-response evidence summary."""
    return (
        "G4 framework ready for all 18 routes: 295 of 306 frozen target-rung "
        "records are feasible and 11 ineligible records are retained. G5 has "
        "eight reconciled cohorts: 98 of 130 exact cells pass and 32 fail; "
        "binomial is 6/6. This is target-rung calibration evidence, not a "
        "route-wide G5 or model-inference promotion."
    )


MISSING_G5_ROUTE_SUMMARIES = {
    # 2026-08-11 D-43 panel (Fisher/Noether/Rose) + addendum: a later,
    # authenticated route-wide campaign supersedes the earlier cohort
    # figure for gaussian, biv_gaussian, gamma, and lognormal (four of the
    # eight originally-promoted candidate routes) -- see cells.tsv
    # test_gate=G5 rows. Both numbers are kept side by side; the panel did
    # not determine why the earlier figure differed and makes no claim
    # about it. A second D-43 panel (same date) separately promoted beta,
    # tweedie, and skew_normal on a threshold-free worst-case coverage
    # bound -- explicitly NOT the mr-g5-calibration-v2 availability floor,
    # which was authored post hoc in the same review session and which the
    # panel declined to use as grounds.
    "gaussian": (
        "G5: 15/15 cells pass (2026-08-11 authenticated route-wide "
        "campaign; supersedes the earlier 51/54 figure from the "
        "combined Gaussian cohort)"
    ),
    "biv_gaussian": (
        "G5: 39/39 cells pass (2026-08-11 authenticated route-wide "
        "campaign; supersedes the earlier 51/54 figure from the "
        "combined Gaussian cohort)"
    ),
    "binomial": "G5: 6/6 cells pass",
    "poisson": "G5: 5/9 cells pass; 4 retained failures",
    "nbinom2": "G5: 10/15 cells pass; 5 retained failures",
    "student": "G5: 3/16 cells pass; 13 retained failures",
    "lognormal": (
        "G5: 15/15 cells pass (2026-08-11 authenticated route-wide "
        "campaign; supersedes the earlier 11/15 figure from the "
        "pre-panel cohort)"
    ),
    "gamma": (
        "G5: 15/15 cells pass (2026-08-11 authenticated route-wide "
        "campaign; supersedes the earlier 12/15 figure from the "
        "pre-panel cohort)"
    ),
    "beta": (
        "G5: 15/15 cells' worst-case bound inside [0.925, 0.975] "
        "(2026-08-11, second D-43 panel, threshold-free worst-case bound "
        "-- NOT the mr-g5-calibration-v2 floor; campaign 294/294 "
        "complete; supersedes the earlier 'cancelled after 2 "
        "unreconciled receipts' status, which predated the resume)"
    ),
    "tweedie": (
        "G5: 15/15 cells' worst-case bound inside [0.925, 0.975] "
        "(2026-08-11, second D-43 panel, threshold-free worst-case bound "
        "-- NOT the mr-g5-calibration-v2 floor)"
    ),
    "skew_normal": (
        "G5: 15/15 cells' worst-case bound inside [0.925, 0.975] "
        "(2026-08-11, second D-43 panel, threshold-free worst-case bound "
        "-- NOT the mr-g5-calibration-v2 floor)"
    ),
    "beta_binomial": "G5: 15/15 cells pass (2026-08-11 route-wide campaign)",
    "zero_one_beta": "G5: 24/24 cells pass (2026-08-11 route-wide campaign)",
    "zi_poisson": "G5: 18/18 cells pass (2026-08-11 route-wide campaign)",
"cumulative_logit": (
    "G5: `fixef:mu:x` only, 3/3 target-rung cells pass; cutpoint targets remain excluded (#967)"
),
}


def missing_route_g4g5_summary(route: str) -> str:
    """Return a scoped, non-promotional G4/G5 line for a route-table cell."""
    g5 = MISSING_G5_ROUTE_SUMMARIES.get(route, "G5: not run")
    return f"G4: framework ready; {g5}"


def missing_markdown(missing: list[dict[str, str]], compact: bool = False) -> str:
    lines = [
        "| Route | Runtime state | Evidence gate | Work state | Next gate |",
        "|---|---|---:|---|---|",
    ]
    for row in missing:
        runtime = "implemented" if row["capability_status"] == "implemented" else "rejected"
        verified = " ✓" if int(row["test_gate"][1:]) >= 3 else ""
        lines.append(
            f"| `{row['family_route']}`" + (
                "" if row["dpar"] == "all fitted dpars" else f" (`{row['dpar']}` only)"
            ) + f" | {runtime} | {row['test_gate']}{verified} | "
            f"{row['work_status'].replace('_', ' ')} | {missing_next_gate(row)} |"
        )
    if compact:
        lines.extend([
            "",
            "A ✓ appears only at G3 recovery or above. Missing-response evidence does "
            "not change the model's separate inference tier.",
        ])
    return "\n".join(lines) + "\n"


def ledger_updated_date(cells: list[dict[str, str]]) -> str:
    """Return the newest ISO date present in the authoritative ledger."""
    dates = {row["updated_date"] for row in cells if row.get("updated_date")}
    invalid = sorted(date for date in dates if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", date))
    if invalid:
        raise SystemExit(f"Invalid ledger updated_date value(s): {', '.join(invalid)}")
    if not dates:
        raise SystemExit("Capability ledger has no updated_date values")
    return max(dates)


def reader_reporting_permissions(
    row: dict[str, str], interval_method: str
) -> tuple[str, str, str]:
    """Translate one exact model cell into deliberately narrow reader wording."""
    if row["capability_status"] != "implemented":
        fit = "No — this exact request is not available."
        return (
            fit,
            "No — no point-estimate reporting permission.",
            "No — no named interval method or reporting permission.",
        )
    if row["evidence_tier"] == "supported":
        return (
            "Yes — this exact model route is implemented.",
            "Yes — report the point estimate only within the stated exact scope.",
            (
                f"No — {interval_method} is not authorized by the legacy "
                "supported label; use a separately calibrated route."
                if interval_method
                else "No — the legacy supported label does not authorize an interval."
            ),
        )
    if row["evidence_tier"] == "inference_ready_with_caveats":
        return (
            "Yes — this exact model route is implemented.",
            "Yes — report only within the stated exact scope and caveat.",
            f"Yes — {interval_method}; report only within the stated exact scope and caveat.",
        )
    if row["evidence_tier"] == "interval_feasible":
        return (
            "Yes — this exact model route is implemented.",
            "Yes — report the point estimate with the stated caveat.",
            f"No — {interval_method} is available, but there is no calibrated "
            "interval-reporting permission.",
        )
    if row["evidence_tier"] == "point_fit_recovery":
        return (
            "Yes — this exact model route is implemented.",
            "Yes — recovery-backed point estimate only, within the stated scope.",
            (
                f"No — {interval_method} is not reportable for this route."
                if interval_method
                else "No — no named interval-reporting permission."
            ),
        )
    return (
        "Implemented, but not validated for reporting.",
        "No — implementation or diagnostic evidence is not point-report permission.",
        "No — no named interval-reporting permission.",
    )


def reader_summary_value(cells: list[dict[str, str]]) -> dict[str, object]:
    """Build the package-contained, model-surface-only reader summary.

    The counts are intentionally scoped to ``model_surface``. Association and
    missing-response cells have different estimands and evidence ladders, so
    they cannot contribute to these fit or reporting permissions.
    """
    model = [row for row in cells if row["axis"] == "model_surface"]
    by_id = {row["cell_id"]: row for row in model}
    runtime_counts = Counter(row["capability_status"] for row in model)
    evidence_counts = Counter(
        row["evidence_tier"]
        for row in model
        if row["capability_status"] == "implemented"
    )
    rows = []
    for spec in READER_SUMMARY_SPECS:
        cell_id = spec["cell_id"]
        if cell_id not in by_id:
            raise SystemExit(
                f"Reader summary cell {cell_id} is absent from the model-surface ledger"
            )
        source = by_id[cell_id]
        actual_claim_sha = hashlib.sha256(
            source["claim_boundary"].encode("utf-8")
        ).hexdigest()
        if actual_claim_sha != spec["claim_boundary_sha256"]:
            raise SystemExit(
                "Reader summary scope is stale for "
                f"{cell_id}: canonical claim boundary changed; review the public "
                "scope/caveat and refresh its claim_boundary_sha256 only after "
                "reconciling the wording."
            )
        fit_permission, point_permission, interval_permission = reader_reporting_permissions(
            source, spec["interval_method"]
        )
        rows.append({
            "cell_id": cell_id,
            "route": spec["reader_route"],
            "fit_permission": fit_permission,
            "point_report_permission": point_permission,
            "interval_method_report_permission": interval_permission,
            "scope_caveat": spec["scope_caveat"],
            "fallback": spec["fallback"],
            "ledger": {
                key: source[key]
                for key in (
                    "axis", "family_route", "route_variant", "dpar",
                    "effect_type", "structure_provider", "dimension", "q_gate",
                    "estimator", "capability_status", "work_status", "evidence_tier",
                )
            },
        })
    return {
        "ledger_updated": ledger_updated_date(cells),
        "model_surface_total": len(model),
        "runtime_counts": dict(runtime_counts),
        "evidence_counts": dict(evidence_counts),
        "rows": rows,
    }


def reader_summary_markdown(cells: list[dict[str, str]]) -> str:
    """Render the reader summary consumed from ``vignettes/includes``."""
    summary = reader_summary_value(cells)
    runtime = summary["runtime_counts"]
    evidence = summary["evidence_counts"]
    lines = [
        "<!-- Generated by tools/capability_ledger.py; do not edit by hand. -->",
        "",
        "The canonical ledger was last updated **{date}**. These counts and "
        "permissions cover the **model-surface** axis only: association and "
        "missing-response evidence are separate and do not transfer here.".format(
            date=summary["ledger_updated"]
        ),
        "",
        "## Reader routes {.drmtmb-reader-routes}",
    ]
    for row in summary["rows"]:
        fit_yes = row["fit_permission"].startswith("Yes")
        interval_yes = row["interval_method_report_permission"].startswith("Yes")
        route_class = (
            "drmtmb-route-interval" if interval_yes else
            "drmtmb-route-point" if fit_yes else
            "drmtmb-route-unavailable"
        )
        lines.extend([
            "",
            f"### {row['route']} {{.drmtmb-route-card .{route_class}}}",
            "",
            f"**Can I fit it?** {row['fit_permission']}",
            "",
            f"**Can I report the point estimate?** {row['point_report_permission']}",
            "",
            "**Named interval method / reporting permission.** "
            f"{row['interval_method_report_permission']}",
            "",
            f"**Exact scope and caveat.** {row['scope_caveat']}",
            "",
            f"**Concrete fallback.** {row['fallback']}",
        ])
    lines.extend([
        "",
        "<details>",
        "<summary>Technical ledger snapshot</summary>",
        "",
        "- Model-surface total: **{total} exact model routes**.".format(
            total=summary["model_surface_total"]
        ),
        "- Runtime: **{implemented} implemented**, **{not_implemented} not "
        "implemented**, and **{rejected} rejected by design**.".format(
            implemented=runtime.get("implemented", 0),
            not_implemented=runtime.get("not_implemented", 0),
            rejected=runtime.get("rejected_by_design", 0),
        ),
        "- Evidence among implemented model cells: **{supported} supported**, "
        "**{inference_ready} inference-ready with caveats**, **{interval_feasible} "
        "interval-feasible**, **{point_fit_recovery} point-fit recovery**, and "
        "**{diagnostic_only} diagnostic-only**.".format(
            supported=evidence.get("supported", 0),
            inference_ready=evidence.get("inference_ready_with_caveats", 0),
            interval_feasible=evidence.get("interval_feasible", 0),
            point_fit_recovery=evidence.get("point_fit_recovery", 0),
            diagnostic_only=evidence.get("diagnostic_only", 0),
        ),
        "",
        "</details>",
    ])
    return "\n".join(lines) + "\n"


def runtime_missing_predictor_families() -> set[str]:
    """Read the fitted-family allow-list from the R runtime's SSOT helper."""
    source = (ROOT / "R/missing-data.R").read_text(encoding="utf-8")
    match = re.search(
        r"drm_missing_predictor_families\s*<-\s*function\(\)\s*\{\s*c\((.*?)\)\s*\}",
        source,
        flags=re.DOTALL,
    )
    if not match:
        raise SystemExit("Cannot read drm_missing_predictor_families() runtime gate")
    families = set(re.findall(r'["\']([^"\']+)["\']', match.group(1)))
    if not families:
        raise SystemExit("drm_missing_predictor_families() runtime gate is empty")
    return families


def validate_missing_predictor_runtime_map() -> set[str]:
    """Validate route-to-family routing, then return the live R allow-list."""
    expected = {route: family_type for _, route, family_type, _, _ in ROUTES}
    if MISSING_PREDICTOR_RUNTIME_GATE != expected:
        raise SystemExit(
            "MISSING_PREDICTOR_RUNTIME_GATE does not match the fitted route contract"
        )
    runtime = runtime_missing_predictor_families()
    unknown = runtime - set(expected.values())
    if unknown:
        raise SystemExit(
            "R missing-predictor runtime gate names unknown family type(s): "
            + ", ".join(sorted(unknown))
        )
    return runtime


def _aggregate_state(rows: list[dict[str, str]]) -> str:
    """Aggregate cells without turning absence into rejection."""
    if not rows:
        return "absent"
    counts = Counter(row["capability_status"] for row in rows)
    labels = {
        "implemented": "implemented",
        "not_implemented": "not implemented",
        "rejected_by_design": "not currently supported",
        "scaffolded": "scaffolded",
    }
    if len(counts) == 1:
        return labels[next(iter(counts))]
    details = "; ".join(
        f"{labels[status]} {counts[status]}"
        for status in (
            "implemented", "not_implemented", "rejected_by_design", "scaffolded"
        )
        if counts[status]
    )
    prefix = "scope-limited" if counts["implemented"] else "mixed"
    return f"{prefix} ({details})"


def _dpar_order(rows: list[dict[str, str]]) -> list[str]:
    first_seen: dict[str, int] = {}
    for row in rows:
        first_seen.setdefault(row["dpar"], int(row["source_order"]))
    return sorted(first_seen, key=first_seen.get)


def _effect_summary(
    rows: list[dict[str, str]], dpars: list[str], effect_type: str
) -> str:
    pieces = []
    for dpar in dpars:
        selected = [
            row for row in rows
            if row["dpar"] == dpar and row["effect_type"] == effect_type
        ]
        pieces.append(f"`{dpar}`: {_aggregate_state(selected)}")
    return "; ".join(pieces)


def _ordinary_summary(rows: list[dict[str, str]], dpars: list[str]) -> str:
    pieces = []
    for dpar in dpars:
        intercept = [
            row for row in rows
            if row["dpar"] == dpar and row["effect_type"] == "ordinary_re_intercept"
        ]
        slope = [
            row for row in rows
            if row["dpar"] == dpar and row["effect_type"] == "ordinary_re_slope"
        ]
        pieces.append(
            f"`{dpar}`: int {_aggregate_state(intercept)} / "
            f"slope {_aggregate_state(slope)}"
        )
    return "; ".join(pieces)


def _structured_summary(rows: list[dict[str, str]], dpars: list[str]) -> str:
    pieces = []
    for dpar in dpars:
        providers = []
        for provider in STRUCTURED_PROVIDERS:
            selected = [
                row for row in rows
                if row["dpar"] == dpar
                and row["effect_type"] == "structured"
                and row["structure_provider"] == provider
            ]
            providers.append(f"{provider}={_aggregate_state(selected)}")
        pieces.append(f"`{dpar}`: " + ", ".join(providers))
    return "; ".join(pieces)


def _evidence_summary(rows: list[dict[str, str]]) -> tuple[str, str]:
    implemented = [row for row in rows if row["capability_status"] == "implemented"]
    available = {row["evidence_tier"] for row in implemented}
    highest = next((tier for tier in TIER_ORDER if tier in available), "none")
    scoped = sorted(
        (row for row in implemented if row["evidence_tier"] == highest),
        key=lambda row: int(row["source_order"]),
    )
    if not scoped:
        return highest, f"**{highest}** — no implemented cell at this tier"
    scopes = "; ".join(
        "`{cell}` ({dpar}; {effect}; provider={provider}; estimator={estimator}; "
        "dimension={dimension}; q={q}; variant={variant})".format(
            cell=row["cell_id"],
            dpar=row["dpar"],
            effect=row["effect_type"],
            provider=row["structure_provider"],
            estimator=row["estimator"],
            dimension=row["dimension"],
            q=row["q_gate"],
            variant=row["route_variant"],
        )
        for row in scoped
    )
    return highest, f"**{highest}** — {scopes}"


def _missing_predictor_summary(route: str, runtime: set[str]) -> str:
    family_type = MISSING_PREDICTOR_RUNTIME_GATE[route]
    if family_type not in runtime:
        return f"rejected by runtime gate (`{family_type}` response)"
    if family_type == "gaussian":
        return "implemented: broad predictor-family catalogue"
    inherited = "" if route == family_type else f" via `{family_type}` family-type gate"
    return f"implemented: one binary missing predictor{inherited}"


def family_map_rows(cells: list[dict[str, str]]) -> list[dict[str, str]]:
    """Project the per-family reference exclusively from live ledger cells."""
    runtime = validate_missing_predictor_runtime_map()
    model = [row for row in cells if row["axis"] == "model_surface"]
    by_route: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in model:
        by_route[row["family_route"]].append(row)

    rows = []
    for _, route, _, _, _ in ROUTES:
        route_rows = by_route.get(route, [])
        if not route_rows:
            raise SystemExit(f"No live model-surface cells for route {route}")
        dpars = _dpar_order(route_rows)
        ml = [row for row in route_rows if row["estimator"] == "ML"]
        reml = [row for row in route_rows if row["estimator"] == "REML"]
        highest, evidence = _evidence_summary(route_rows)
        rows.append({
            "family_route": route,
            "Response": f"**{route}**",
            "dpars": ", ".join(f"`{dpar}`" for dpar in dpars),
            "Fixed": _effect_summary(ml, dpars, "fixed"),
            "Random (int/slope)": _ordinary_summary(ml, dpars),
            "Structured (phylo/spatial/animal/relmat/phylo_interaction)": (
                _structured_summary(ml, dpars)
            ),
            "REML": "",
            "Highest evidence (exact scope)": evidence,
            "highest_evidence_tier": highest,
            "Miss-predictor mi()": _missing_predictor_summary(route, runtime),
        })
        # REML is one estimator-wide state per dpar. It is intentionally
        # computed from REML rows only, including fixed, ordinary, and
        # structured cells, rather than inferred from the ML surface.
        rows[-1]["REML"] = "; ".join(
            f"`{dpar}`: {_aggregate_state([row for row in reml if row['dpar'] == dpar])}"
            for dpar in dpars
        )
    return rows


def corrected_family_map_markdown(
    missing: list[dict[str, str]], family_rows: list[dict[str, str]]
) -> str:
    by_route = {row["family_route"]: row for row in missing}
    headers = [
        "Response", "dpars", "Fixed", "Random (int/slope)",
        "Structured (phylo/spatial/animal/relmat/phylo_interaction)", "REML",
        "Highest evidence (exact scope)",
        "Miss-response", "Miss-predictor mi()",
    ]
    lines = [
        "| " + " | ".join(headers) + " |",
        "|" + "|".join("---" for _ in headers) + "|",
    ]
    for source_row in family_rows:
        row = dict(source_row)
        gate = by_route[row["family_route"]]["test_gate"]
        gate_num = int(gate[1:])
        labels = {
            0: "rejected/planned",
            1: "implemented; audit pending",
            2: "masking validated; recovery pending",
            3: "✓ recovery verified",
            4: "✓ interval feasible",
            5: "✓ inference-ready",
        }
        row["Miss-response"] = (
            f"{gate} {labels[gate_num]}; {missing_route_g4g5_summary(row['family_route'])}"
        )
        lines.append("| " + " | ".join(row[header] for header in headers) + " |")
    return "\n".join(lines) + "\n"


def inline_markdown(value: str) -> str:
    value = html.escape(value)
    value = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"`(.+?)`", r"<code>\1</code>", value)
    return value


def family_map_html(
    missing: list[dict[str, str]], family_rows: list[dict[str, str]]
) -> str:
    by_route = {row["family_route"]: row for row in missing}
    descriptors = {
        "gaussian": "continuous", "biv_gaussian": "two responses",
        "nbinom2": "NB2 count", "poisson": "count, log", "beta": "proportions",
        "binomial": "logit", "student": "robust", "gamma": "positive",
        "truncated_nbinom2": "positive count", "hurdle_nbinom2": "trunc + hu~",
        "cumulative_logit": "ordinal", "lognormal": "positive, log scale",
        "beta_binomial": "overdispersed trials", "skew_normal": "continuous skew",
        "tweedie": "semicontinuous", "zero_one_beta": "boundary proportions",
        "zi_poisson": "zero-inflated count", "zi_nbinom2": "zero-inflated NB2",
    }
    body = []
    for row in family_rows:
        route = row["family_route"]
        gate = by_route[route]["test_gate"]
        gate_num = int(gate[1:])
        gate_labels = {
            0: ("rejected", "planned"),
            1: ("implemented", "audit pending"),
            2: ("masking validated", "recovery pending"),
            3: ("✓ recovery verified", ""),
            4: ("✓ interval feasible", ""),
            5: ("✓ inference-ready", ""),
        }
        label, note = gate_labels[gate_num]
        gate_class = "mr-g0" if gate_num == 0 else "mr-g1" if gate_num == 1 else "mr-g2" if gate_num == 2 else "mr-verified"
        missing_cell = (
            f'<span class="mr-state {gate_class}">{gate} {label}</span>'
            + (f"<small>{note}</small>" if note else "")
            + f'<small class="mr-g4g5">{html.escape(missing_route_g4g5_summary(route))}</small>'
        )
        interval_class = (
            "inference"
            if row["highest_evidence_tier"] in {"supported", "inference_ready_with_caveats"}
            else "feasible"
        )
        body.append(
            "<tr>"
            f'<th scope="row"><code>{html.escape(route)}</code><small>{html.escape(descriptors[route])}</small></th>'
            f"<td>{inline_markdown(row['dpars'])}</td>"
            f"<td class=\"fixed\">{inline_markdown(row['Fixed'])}</td>"
            f"<td>{inline_markdown(row['Random (int/slope)'])}</td>"
            f"<td>{inline_markdown(row['Structured (phylo/spatial/animal/relmat/phylo_interaction)'])}</td>"
            f"<td>{inline_markdown(row['REML'])}</td>"
            f'<td><span class="tier {interval_class}">{inline_markdown(row["Highest evidence (exact scope)"])}</span></td>'
            f"<td>{missing_cell}</td>"
            f"<td>{inline_markdown(row['Miss-predictor mi()'])}</td>"
            "</tr>"
        )
    return "".join(body)


def surface_markdown(
    cells: list[dict[str, str]], evidence: list[dict[str, str]],
    family_rows: list[dict[str, str]] | None = None,
) -> str:
    if family_rows is None:
        family_rows = family_map_rows(cells)
    model = [row for row in cells if row["axis"] == "model_surface"]
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    association = sorted(
        (row for row in cells if row["axis"] == "association"),
        key=lambda row: int(row["source_order"]),
    )
    status = Counter(row["capability_status"] for row in model)
    tiers = Counter(
        row["evidence_tier"] for row in model if row["capability_status"] == "implemented"
    )
    missing_gates = Counter(row["test_gate"] for row in missing)
    verified_missing = sum(int(row["test_gate"][1:]) >= 3 for row in missing)
    by_family: dict[str, list[dict[str, str]]] = defaultdict(list)
    for row in model:
        by_family[row["family_route"]].append(row)
    lines = [
        "# drmTMB capability surface",
        "",
        f"_Generated {ledger_updated_date(cells)} from `capability-ledger/` by "
        "`tools/capability_ledger.py`; do not hand-edit this file._",
        "",
        "The model surface, staged-association surface, and missing-response "
        "execution axis answer different questions. Model cells describe direct "
        "drmTMB fits; association cells describe post-fit associate_pairs() "
        "estimators; missing-response cells describe response handling. Evidence "
        "never transfers automatically between axes.",
        "",
        "## Snapshot",
        "",
        f"- Model surface: **{len(model)} cells** across **{len(by_family)} routes**.",
        f"- Staged association: **{len(association)} cells**; "
        f"**{sum(row['evidence_tier'] == 'interval_feasible' for row in association)} interval-feasible** and "
        f"**{sum(row['evidence_tier'] == 'inference_ready_with_caveats' for row in association)} inference-ready with caveats**.",
        f"- Runtime status: **{status['implemented']} implemented**, "
        f"**{status['not_implemented']} actionable not implemented**, and "
        f"**{status['rejected_by_design']} not currently supported**.",
        "- Planning classes make the backlog visible without calling it impossible: "
        "admission candidate, covariance/model method, or estimator method. "
        "They are scope classes, not effort estimates or evidence claims.",
        "- ML and REML are separate estimators. An ML implementation does not "
        "automatically supply REML; REML cells require a valid restricted-likelihood "
        "objective and their own validation.",
        f"- Evidence: **{tiers['supported']} supported**, "
        f"**{tiers['inference_ready_with_caveats']} inference-ready**, "
        f"**{tiers['interval_feasible']} interval-feasible**, "
        f"**{tiers['point_fit_recovery']} recovery-grade**.",
        f"- Missing-response board: **{len(missing)} routes; "
        f"{missing_gates['G0']} G0; {missing_gates['G1']} G1; "
        f"{missing_gates['G2']} G2; {verified_missing} verified (G3+)**.",
        "",
        "## Staged association capability",
        "",
        "The evidence ladder is point-fit recovery, interval feasible, inference-"
        "ready with caveats, then supported. Interval feasibility is sufficient "
        "to expose a scoped method; coverage evidence promotes the tested domain "
        "to inference-ready. Limits belong in the claim boundary unless evidence "
        "directly contradicts the route.",
        "",
        "| Cell | Pair route | Association shape | Status | Evidence tier | Claim boundary |",
        "|---|---|---|---|---|---|",
        *[
            f"| `{row['cell_id']}` | `{row['family_route']}` | "
            f"`{row['route_variant']}` | {row['capability_status'].replace('_', ' ')} | "
            f"{row['evidence_tier'].replace('_', ' ')} | {row['claim_boundary']} |"
            for row in association
        ],
        "",
        "## Missing-response execution board",
        "",
        "G0 = rejected; G1 = implemented; G2 = masking validated; G3 = recovery; "
        "G4 = interval feasible; G5 = inference-ready. The verified tick begins "
        "at G3.",
        "",
        f"> **Current G4/G5 evidence (target-rung grain):** {missing_g4g5_summary()}",
        "",
        missing_markdown(missing).rstrip(),
        "",
        "### Route-level evidence rule",
        "",
        "Mixture routes have their own masking and recovery evidence. A zero-"
        "inflated or hurdle route never inherits a tick from its Poisson, NB2, "
        "or truncated-NB2 base family.",
        "",
        "Each route's displayed gate and work state come from its own ledger "
        "evidence. Verified routes have passed direct sentinel mutation, "
        "residual/accounting, and named recovery audits; no route inherits a "
        "tick from a base family.",
        "",
        "## Per-family model-surface summary",
        "",
        "| Route | Cells | Implemented | Actionable backlog | Not currently supported | Highest evidence |",
        "|---|---:|---:|---:|---:|---|",
    ]
    for family in sorted(by_family):
        rows = by_family[family]
        counts = Counter(row["capability_status"] for row in rows)
        available = {row["evidence_tier"] for row in rows if row["capability_status"] == "implemented"}
        highest = next((tier for tier in TIER_ORDER if tier in available), "none")
        lines.append(
            f"| `{family}` | {len(rows)} | {counts['implemented']} | "
            f"{counts['not_implemented']} | {counts['rejected_by_design']} | "
            f"{highest.replace('_', ' ')} |"
        )
    lines.extend([
        "",
        "## Evidence and detailed cells",
        "",
        "Use the generated HTML surface for filters, route anchors, claim "
        "boundaries, next gates, and direct evidence links. Machine-readable "
        "sources are `capability-ledger/cells.tsv`, `evidence.tsv`, and "
        "`transitions.tsv`.",
        "",
        "## Per-family capability reference",
        "",
        "This table is projected from the current model-surface cells. Its "
        "missing-response column is joined separately from the 18-route ledger, "
        "and its missing-predictor column follows the live R runtime gate.",
        "",
        corrected_family_map_markdown(missing, family_rows).rstrip(),
        "",
    ])
    return "\n".join(lines)


COMPARATOR_PACKAGES = (
    "metafor", "glmmTMB", "lme4", "MASS", "ordinal", "VGAM", "mgcv", "betareg",
    "gamlss", "brms", "stats::glm",
)


def external_comparator_by_cell(
    evidence: list[dict[str, str]]
) -> dict[str, str]:
    """Name the external comparators recorded for each cell, keyed by cell_id.

    DELIBERATELY PER CELL, and it must stay that way. A family_route bucket mixes
    fixed, random, structured, phylogenetic, spatial and bivariate cells together. A
    family-level comparator badge would therefore read as covering frontier routes for
    which no external implementation exists at all -- which is exactly the
    credibility-laundering this evidence class is meant to avoid. Agreement with an
    established package licenses the OVERLAP region only, never the frontier.

    Each entry reads "package (strong)" or "package (weak)". The strength is NOT
    decoration: lme4 and metafor are separate estimation engines, so agreement is a real
    cross-implementation check, whereas glmmTMB is built on the same TMB/AD stack and
    outer optimizer as drmTMB, so agreement there is a consistency check between related
    implementations. Rendering the package name alone made all three look equivalent.

    Package names are matched against run_id and result only, never claim_boundary. The
    boundary is where a row says what it does NOT cover, so a phrase like "does not extend
    to glmmTMB" would otherwise badge glmmTMB as a comparator.
    """
    found: dict[str, set[str]] = {}
    for row in evidence:
        if row["evidence_class"] != "external_comparator":
            continue
        haystack = f"{row['run_id']} {row['result']}"
        boundary = row["claim_boundary"].upper()
        if "STRONG INDEPENDENCE" in boundary:
            strength = "strong"
        elif "WEAK INDEPENDENCE" in boundary:
            strength = "weak"
        else:
            strength = "unclassified"
        names = {
            f"{pkg} ({strength})" for pkg in COMPARATOR_PACKAGES if pkg in haystack
        }
        found.setdefault(row["cell_id"], set()).update(names)
    return {
        cell_id: ", ".join(sorted(names, key=str.lower))
        for cell_id, names in found.items()
        if names
    }


def surface_html(
    cells: list[dict[str, str]], evidence: list[dict[str, str]],
    family_rows: list[dict[str, str]] | None = None,
) -> str:
    if family_rows is None:
        family_rows = family_map_rows(cells)
    generated_date = ledger_updated_date(cells)
    model = sorted(
        (row for row in cells if row["axis"] == "model_surface"),
        key=lambda row: int(row["source_order"]),
    )
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    association = sorted(
        (row for row in cells if row["axis"] == "association"),
        key=lambda row: int(row["source_order"]),
    )
    status = Counter(row["capability_status"] for row in model)
    tiers = Counter(
        row["evidence_tier"] for row in model if row["capability_status"] == "implemented"
    )
    missing_gates = Counter(row["test_gate"] for row in missing)
    verified_missing = sum(int(row["test_gate"][1:]) >= 3 for row in missing)
    comparators = external_comparator_by_cell(evidence)
    model_data = json.dumps([
        {
            **{key: row[key] for key in (
                "cell_id", "family_route", "route_variant", "dpar", "effect_type",
                "structure_provider", "dimension", "q_gate", "estimator",
                "capability_status", "evidence_tier", "claim_boundary",
                "primary_evidence_id",
            )},
            "planning_class": planning_class(row),
            "external_comparator": comparators.get(row["cell_id"], ""),
        }
        for row in model
    ], ensure_ascii=False).replace("</", "<\\/")
    initial_model_rows = "".join(
        "<tr>"
        f"<td><code>{html.escape(row['cell_id'])}</code></td>"
        f"<td><code>{html.escape(row['family_route'])}</code></td>"
        f"<td>{html.escape(row['route_variant'])}</td>"
        f"<td>{html.escape(row['dpar'])}</td>"
        f"<td>{html.escape(row['effect_type'])}</td>"
        f"<td>{html.escape(row['structure_provider'])}</td>"
        f"<td>{html.escape(row['estimator'])}</td>"
        f"<td>{html.escape(planning_class(row))}</td>"
        f"<td><span class=\"pill\">{html.escape(row['capability_status'].replace('_', ' '))}</span></td>"
        f"<td>{html.escape(row['evidence_tier'].replace('_', ' '))}</td>"
        f"<td>{html.escape(comparators.get(row['cell_id'], ''))}</td>"
        f"<td>{html.escape(row['claim_boundary'])}</td>"
        "</tr>"
        for row in model
    )
    association_rows = "".join(
        "<tr>"
        f"<td><code>{html.escape(row['cell_id'])}</code></td>"
        f"<td><code>{html.escape(row['family_route'])}</code></td>"
        f"<td>{html.escape(row['route_variant'])}</td>"
        f"<td><span class=\"pill\">{html.escape(row['capability_status'].replace('_', ' '))}</span></td>"
        f"<td>{html.escape(row['evidence_tier'].replace('_', ' '))}</td>"
        f"<td>{html.escape(row['claim_boundary'])}</td>"
        "</tr>"
        for row in association
    )
    return f"""<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>drmTMB capability surface</title>
<style>
:root{{--bg:#eef3f4;--panel:#fff;--text:#162326;--muted:#617176;--line:#d4dfe2;--teal:#087d89;--green:#188653;--amber:#b77a13;--red:#b84436;--blue:#2f6fad;--shadow:0 8px 24px #17333a12;--mono:ui-monospace,SFMono-Regular,Menlo,monospace}}
@media(prefers-color-scheme:dark){{:root{{--bg:#10181b;--panel:#182328;--text:#e8f0f2;--muted:#a3b2b7;--line:#304147;--teal:#48bdc8;--green:#4bc78b;--amber:#e4b45e;--red:#f07b6a;--blue:#78afe8;--shadow:none}}}}
:root[data-theme="light"]{{--bg:#eef3f4;--panel:#fff;--text:#162326;--muted:#617176;--line:#d4dfe2;--teal:#087d89;--green:#188653;--amber:#b77a13;--red:#b84436;--blue:#2f6fad;--shadow:0 8px 24px #17333a12}}
:root[data-theme="dark"]{{--bg:#10181b;--panel:#182328;--text:#e8f0f2;--muted:#a3b2b7;--line:#304147;--teal:#48bdc8;--green:#4bc78b;--amber:#e4b45e;--red:#f07b6a;--blue:#78afe8;--shadow:none}}
*{{box-sizing:border-box}} body{{margin:0;background:var(--bg);color:var(--text);font:16px/1.5 system-ui,-apple-system,Segoe UI,sans-serif}} a{{color:var(--teal)}} code{{font-family:var(--mono)}} .skip{{position:absolute;left:-9999px;top:8px;background:var(--panel);padding:8px 12px;z-index:10}} .skip:focus{{left:8px}} .page{{max-width:1440px;margin:auto;padding:34px 28px 80px}} .topline{{display:flex;justify-content:space-between;gap:16px;align-items:center}} .eyebrow{{font:700 13px/1.2 var(--mono);letter-spacing:.14em;text-transform:uppercase;color:var(--teal)}} h1{{font-size:clamp(2.1rem,5vw,4.4rem);line-height:1.02;margin:.35rem 0 1rem}} h2{{font-size:1.55rem;margin:3rem 0 1rem;scroll-margin-top:18px}} .lede{{font-size:1.2rem;color:var(--muted);max-width:980px}} .jump{{display:flex;gap:10px;flex-wrap:wrap;margin:1rem 0 1.5rem}} .jump a{{background:var(--panel);border:1px solid var(--line);border-radius:99px;padding:6px 11px;text-decoration:none}} .scope{{border-left:4px solid var(--teal);padding:.8rem 1rem;background:var(--panel);box-shadow:var(--shadow)}} .stats{{display:grid;grid-template-columns:repeat(auto-fit,minmax(155px,1fr));gap:12px;margin:28px 0}} .stat{{background:var(--panel);border:1px solid var(--line);border-radius:12px;padding:15px;box-shadow:var(--shadow)}} .stat b{{display:block;font:750 1.8rem var(--mono)}} .stat span{{color:var(--muted)}} .legend{{display:flex;gap:18px;flex-wrap:wrap;color:var(--muted);margin:.6rem 0 1.4rem}} .legend i{{display:inline-block;width:10px;height:10px;border-radius:50%;margin-right:6px}} .routes{{display:grid;grid-template-columns:repeat(auto-fit,minmax(285px,1fr));gap:14px}} .route-card{{background:var(--panel);border:1px solid var(--line);border-top:5px solid var(--amber);border-radius:13px;padding:16px;box-shadow:var(--shadow);scroll-margin-top:20px}} .route-card.g0{{border-top-color:var(--red)}} .route-card.g2{{border-top-color:var(--blue)}} .route-card.g3,.route-card.g4,.route-card.g5{{border-top-color:var(--green)}} .route-head{{display:flex;justify-content:space-between;gap:12px;align-items:center;font-size:1.06rem;font-weight:750}} .gate{{font:750 .85rem var(--mono);border:1px solid currentColor;border-radius:99px;padding:2px 8px;color:var(--amber)}} .g0 .gate{{color:var(--red)}} .g2 .gate{{color:var(--blue)}} .g3 .gate,.g4 .gate,.g5 .gate{{color:var(--green)}} .route-state{{color:var(--muted);margin:.45rem 0}} .gate-track{{height:6px;border-radius:6px;background:var(--line);overflow:hidden}} .gate-track span{{display:block;height:100%;background:var(--amber)}} .g0 .gate-track span{{background:var(--red)}} .g2 .gate-track span{{background:var(--blue)}} .g3 .gate-track span,.g4 .gate-track span,.g5 .gate-track span{{background:var(--green)}} .route-card p{{font-size:.92rem}} .route-card .next{{min-height:4.1em}} .route-card a{{font-size:.82rem;overflow-wrap:anywhere}} .verified{{color:var(--green);font-weight:700}} .filters{{display:flex;gap:10px;flex-wrap:wrap;margin:1rem 0}} input,select,button{{font:inherit;color:var(--text);background:var(--panel);border:1px solid var(--line);border-radius:8px;padding:8px 10px}} button{{cursor:pointer}} .table-wrap{{overflow:auto;background:var(--panel);border:1px solid var(--line);border-radius:12px;max-height:720px}} table{{border-collapse:collapse;width:100%;font-size:.84rem}} caption{{text-align:left;padding:12px;color:var(--muted)}} th,td{{padding:9px 11px;border-bottom:1px solid var(--line);text-align:left;vertical-align:top}} thead th{{position:sticky;top:0;background:var(--panel);z-index:1}} tbody tr:hover{{background:color-mix(in srgb,var(--teal) 7%,transparent)}} .pill{{display:inline-block;border-radius:99px;padding:2px 7px;background:var(--bg);white-space:nowrap}} .family-wrap{{overflow:auto;background:var(--panel);border:1px solid var(--line);border-radius:14px;box-shadow:var(--shadow)}} .family-map{{min-width:1620px;font-size:.92rem}} .family-map th,.family-map td{{padding:18px 16px}} .family-map tbody th{{position:sticky;left:0;background:var(--panel);z-index:1;min-width:175px}} .family-map tbody th code{{font-size:1rem;font-weight:800}} .family-map small{{display:block;color:var(--muted);font-weight:400;margin-top:4px}} .family-map .fixed{{color:var(--green);font-weight:700;text-align:center;font-size:1.05rem}} .tier{{display:inline-block;border-radius:8px;padding:5px 7px}} .tier.inference{{background:color-mix(in srgb,var(--green) 14%,transparent);color:var(--green)}} .tier.feasible{{background:color-mix(in srgb,var(--amber) 14%,transparent);color:var(--amber)}} .mr-state{{font-weight:750;white-space:nowrap}} .mr-g1{{color:var(--amber)}} .mr-g0{{color:var(--red)}} .mr-g2{{color:var(--blue)}} .mr-verified{{color:var(--green)}} .muted{{color:var(--muted)}} footer{{margin-top:3rem;color:var(--muted)}} @media(max-width:650px){{.page{{padding:24px 14px 60px}} .route-card .next{{min-height:0}}}} @media(prefers-reduced-motion:reduce){{*{{scroll-behavior:auto!important}}}}
</style></head><body><a class="skip" href="#model-cells">Skip to capability content</a><main class="page">
<div class="topline"><div class="eyebrow">drmTMB · generated capability ledger · MR-T0</div><button id="theme" type="button" aria-label="Toggle light and dark theme">Theme</button></div>
<h1>Capability surface</h1>
<p class="lede">One model census, one staged-association surface, one scoped missing-response evidence summary, and no inherited ticks. The ledger distinguishes code admission, validation work, and inferential evidence across axes.</p>
<nav class="jump" aria-label="Capability surface sections"><a href="#association">Association</a><a href="#missing-response">Missing-response board</a><a href="#model-cells">Detailed cells</a><a href="#family-capability">Per-family map</a></nav>
<p class="scope"><strong>Scope:</strong> {len(model)} model-surface cells, {len(association)} staged-association cells, and 18 missing-response routes. Evidence never transfers automatically between axes; a missing-response ✓ appears only at G3 recovery or above and never promotes the model's separate inference tier.</p>
<section class="stats" aria-label="Capability summary">
<div class="stat"><b>{len(model)}</b><span>model cells</span></div><div class="stat"><b>{len(association)}</b><span>association cells</span></div><div class="stat"><b>{sum(row['evidence_tier'] == 'interval_feasible' for row in association)}</b><span>association interval-feasible</span></div><div class="stat"><b>{sum(row['evidence_tier'] == 'inference_ready_with_caveats' for row in association)}</b><span>association inference-ready</span></div><div class="stat"><b>{len(missing)}</b><span>missing-response routes</span></div>
<div class="stat"><b>{status['implemented']}</b><span>implemented model cells</span></div><div class="stat"><b>{status['not_implemented']}</b><span>actionable backlog cells</span></div><div class="stat"><b>{status['rejected_by_design']}</b><span>not currently supported</span></div><div class="stat"><b>{tiers['inference_ready_with_caveats']}</b><span>inference-ready cells</span></div>
<div class="stat"><b>{missing_gates['G1']}</b><span>routes at G1</span></div><div class="stat"><b>{verified_missing}</b><span>routes verified at G3+</span></div>
</section>
<h2 id="association">Staged association capability</h2>
<p>The evidence ladder is point-fit recovery → interval feasible → inference-ready with caveats → supported. Interval feasibility is enough to expose a scoped method; coverage promotes the tested domain to inference-ready. Limits belong in warnings and the claim boundary unless evidence directly contradicts the route.</p>
<div class="table-wrap"><table><caption>{len(association)} post-fit <code>associate_pairs()</code> capability cells</caption><thead><tr><th scope="col">Cell</th><th scope="col">Pair route</th><th scope="col">Shape</th><th scope="col">Status</th><th scope="col">Evidence tier</th><th scope="col">Claim boundary</th></tr></thead><tbody>{association_rows}</tbody></table></div>
<h2 id="missing-response">Missing-response evidence</h2>
<p class="scope"><strong>Current G4/G5 evidence (target-rung grain):</strong> {html.escape(missing_g4g5_summary())}</p>
<p class="muted">The per-family reference below remains the route-level source: its Missing response column retains G3 recovery status, while this summary shows the additional G4/G5 evidence without implying a route-wide promotion.</p>
<h2 id="model-cells">Detailed model surface</h2>
<p class="muted">These {len(model)} cells are the current model/inference census. Missing-response progress is not folded into these tiers.</p>
<p class="scope"><strong>Missing-response column:</strong> route-level G3 is retained on purpose. {html.escape(missing_g4g5_summary())}</p>
<p class="muted"><strong>Estimator:</strong> ML and REML are separate objectives. A working ML route does not automatically have a valid REML implementation. <strong>Planning class</strong> distinguishes an admission candidate from a covariance/model-method or estimator-method extension; it is a planning cue, not an effort estimate or a support claim.</p>
<p class="muted"><strong>External comparator</strong> names a package that fits the same model and reaches the same estimates on a single simulated dataset. It says the implementation agrees with an independent one; it is <em>not</em> an interval, coverage, bias or recovery claim, and it never raises the evidence tier. <em>strong</em> means a separate estimation engine (lme4, metafor); <em>weak</em> means the comparator shares drmTMB's TMB/AD stack (glmmTMB), so agreement is a consistency check between related implementations. A blank cell means no comparator has been recorded — for structured, scale-side, bivariate and phylogenetic routes no established implementation exists to compare against at all.</p>
<div class="filters" role="search"><label>Route <select id="family"><option value="">All</option></select></label><label>Status <select id="status"><option value="">All</option></select></label><label>Search <input id="query" type="search" placeholder="parameter, provider, evidence…"></label><button id="clear" type="button">Clear</button></div>
<div id="count" class="muted" aria-live="polite"></div>
<div class="table-wrap"><table><caption>Generated {len(model)}-cell model capability census</caption><thead><tr><th scope="col">Cell</th><th scope="col">Route</th><th scope="col">Variant</th><th scope="col">dpar</th><th scope="col">Effect</th><th scope="col">Provider</th><th scope="col">Estimator</th><th scope="col">Planning class</th><th scope="col">Status</th><th scope="col">Evidence tier</th><th scope="col">External comparator</th><th scope="col">Claim boundary</th></tr></thead><tbody id="rows">{initial_model_rows}</tbody></table></div>
<h2 id="family-capability">Per-family capability reference</h2>
<p class="muted">This reference is projected from current model-surface cells. REML uses only REML rows; missing-response is joined from its separate route ledger; and missing-predictor support follows the live R runtime gate.</p>
<div class="family-wrap"><table class="family-map"><caption>Live per-family capability map</caption><thead><tr><th scope="col">Family</th><th scope="col">dpars</th><th scope="col">Fixed</th><th scope="col">Random (int / slope)</th><th scope="col">Structured — phylo / spatial / animal / relmat / phylo_interaction</th><th scope="col">REML</th><th scope="col">Highest evidence (exact scope)</th><th scope="col">Missing response</th><th scope="col">Missing predictor mi()</th></tr></thead><tbody>{family_map_html(missing, family_rows)}</tbody></table></div>
<footer>Generated {generated_date} by <code>tools/capability_ledger.py</code> from <code>docs/dev-log/dashboard/capability-ledger/</code>. Do not hand-edit generated outputs.</footer>
</main><script>const DATA={model_data};
const esc=s=>String(s??'').replace(/[&<>"']/g,c=>({{'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}}[c]));
const fam=document.querySelector('#family'),status=document.querySelector('#status'),query=document.querySelector('#query'),body=document.querySelector('#rows'),count=document.querySelector('#count');
for(const v of [...new Set(DATA.map(r=>r.family_route))].sort()) fam.insertAdjacentHTML('beforeend',`<option>${{esc(v)}}</option>`);
for(const v of [...new Set(DATA.map(r=>r.capability_status))].sort()) status.insertAdjacentHTML('beforeend',`<option>${{esc(v)}}</option>`);
function render(){{const q=query.value.toLowerCase();const out=DATA.filter(r=>(!fam.value||r.family_route===fam.value)&&(!status.value||r.capability_status===status.value)&&(!q||Object.values(r).join(' ').toLowerCase().includes(q)));count.textContent=`${{out.length}} of {len(model)} cells`;body.innerHTML=out.map(r=>`<tr><td><code>${{esc(r.cell_id)}}</code></td><td><code>${{esc(r.family_route)}}</code></td><td>${{esc(r.route_variant)}}</td><td>${{esc(r.dpar)}}</td><td>${{esc(r.effect_type)}}</td><td>${{esc(r.structure_provider)}}</td><td>${{esc(r.estimator)}}</td><td>${{esc(r.planning_class)}}</td><td><span class="pill">${{esc(r.capability_status.replaceAll('_',' '))}}</span></td><td>${{esc(r.evidence_tier.replaceAll('_',' '))}}</td><td>${{esc(r.external_comparator)}}</td><td>${{esc(r.claim_boundary)}}</td></tr>`).join('')}}
for(const el of [fam,status,query]) el.addEventListener('input',render);document.querySelector('#clear').addEventListener('click',()=>{{fam.value=status.value=query.value='';render()}});document.querySelector('#theme').addEventListener('click',()=>{{const root=document.documentElement;root.dataset.theme=root.dataset.theme==='dark'?'light':'dark'}});render();</script></body></html>"""


def tranche_summary(cells: list[dict[str, str]], tranche_id: str) -> str:
    missing = [
        row for row in cells
        if row["axis"] == "missing_response" and row["tranche_id"] == tranche_id
    ]
    counts = Counter(row["work_status"] for row in missing)
    lines = [
        f"# {tranche_id} missing-response ledger summary",
        "",
        "_Generated; do not hand-edit._",
        "",
        "| Tranche | Routes | Backlog | Implemented unverified | Verified | Next gate |",
        "|---|---:|---:|---:|---:|---|",
        f"| {tranche_id} | {len(missing)} | {counts['backlog']} | {counts['implemented_unverified']} | {counts['verified']} | Follow each route's evidence and next-gate fields |",
        "",
        "## Route accounting",
        "",
        missing_markdown(sorted(missing, key=lambda row: int(row["model_type"]))).rstrip(),
        "",
        "## Does not cover",
        "",
        "This summary does not promote intervals, coverage, model inference tiers, "
        "missing-predictor support, REML, or structured-effect claims.",
        "",
    ]
    return "\n".join(lines)


def outputs(
    cells: list[dict[str, str]], evidence: list[dict[str, str]]
) -> dict[Path, bytes]:
    model = model_projection(cells, evidence)
    generated_date = ledger_updated_date(cells)
    family_rows = family_map_rows(cells)
    missing = sorted(
        (row for row in cells if row["axis"] == "missing_response"),
        key=lambda row: int(row["model_type"]),
    )
    result: dict[Path, bytes] = {
        CENSUS / "_master.tsv": legacy_tsv_bytes(MODEL_FIELDS, model),
        CENSUS / "_widget_data.json": compact_json_bytes(
            widget_value(model, generated_date)
        ),
        ROOT / "docs/dev-log/dashboard/capability-surface.md": surface_markdown(
            cells, evidence, family_rows
        ).encode("utf-8"),
        ROOT / "docs/dev-log/dashboard/capability-surface.html": surface_html(
            cells, evidence, family_rows
        ).encode("utf-8"),
        ROOT / "vignettes/includes/capability-ledger-missing-response.md": missing_markdown(missing, compact=True).encode("utf-8"),
        ROOT / "vignettes/includes/capability-ledger-family-map.md": corrected_family_map_markdown(
            missing, family_rows
        ).encode("utf-8"),
        READER_SUMMARY: reader_summary_markdown(cells).encode("utf-8"),
        **{
            LEDGER / "tranches" / f"{tranche}.md": tranche_summary(cells, tranche).encode("utf-8")
            for tranche in ("MR-T1", "MR-T2", "MR-T3", "MR-T4", "MR-T5", "MR-T6")
        },
    }
    for family in sorted({row["family"] for row in model}):
        result[CENSUS / f"{family}.tsv"] = legacy_tsv_bytes(
            MODEL_FIELDS, [row for row in model if row["family"] == family]
        )
    return result


def load_sources() -> tuple[list[dict[str, str]], list[dict[str, str]], list[dict[str, str]]]:
    if not all(path.exists() for path in (CELLS, EVIDENCE, TRANSITIONS, SCHEMA)):
        raise SystemExit("Capability ledger is missing; run --bootstrap once")
    if json.loads(SCHEMA.read_text(encoding="utf-8")) != schema_value():
        raise SystemExit("schema.json does not match the generator contract")
    cells = read_tsv(CELLS)
    evidence = read_tsv(EVIDENCE)
    transitions = read_tsv(TRANSITIONS)
    validate(cells, evidence, transitions)
    return cells, evidence, transitions


def write_outputs(generated: dict[Path, bytes]) -> None:
    for path, content in generated.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        print(display_path(path))


def display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def check_outputs(generated: dict[Path, bytes]) -> None:
    stale = []
    for path, expected in generated.items():
        if not path.exists():
            stale.append(f"missing: {display_path(path)}")
        elif path.read_bytes() != expected:
            stale.append(f"stale: {display_path(path)}")
    if stale:
        raise SystemExit(
            "Generated capability outputs are not current:\n- " + "\n- ".join(stale)
            + "\nRun: python3 tools/capability_ledger.py --write"
        )
    print(f"capability-ledger: OK ({len(generated)} generated outputs)")


def summary(cells: list[dict[str, str]]) -> None:
    axes = Counter(row["axis"] for row in cells)
    missing = [row for row in cells if row["axis"] == "missing_response"]
    work = Counter(row["work_status"] for row in missing)
    gates = Counter(row["test_gate"] for row in missing)
    print(f"model_surface={axes['model_surface']} missing_response={axes['missing_response']}")
    print("missing work:", " ".join(f"{key}={work[key]}" for key in sorted(work)))
    print("missing gates:", " ".join(f"{key}={gates[key]}" for key in sorted(gates)))


def main() -> None:
    parser = argparse.ArgumentParser()
    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--bootstrap", action="store_true")
    action.add_argument("--restore-c14-boundaries", action="store_true")
    action.add_argument("--split-c14-zob-structured-leaves", action="store_true")
    action.add_argument("--split-c18-zob-atom-leaves", action="store_true")
    action.add_argument("--split-mc0207-ordinary-q-leaves", action="store_true")
    action.add_argument("--reconcile-capability-truth", action="store_true")
    action.add_argument("--check-c14-receipt-equivalence", action="store_true")
    action.add_argument("--write", action="store_true")
    action.add_argument("--check", action="store_true")
    action.add_argument("--summary", action="store_true")
    args = parser.parse_args()
    if args.bootstrap:
        bootstrap()
        return
    if args.restore_c14_boundaries:
        restore_c14_boundaries()
        return
    if args.split_c14_zob_structured_leaves:
        split_c14_zob_structured_leaves()
        return
    if args.split_c18_zob_atom_leaves:
        split_c18_zob_atom_leaves()
        return
    if args.split_mc0207_ordinary_q_leaves:
        split_mc0207_ordinary_q_leaves()
        return
    if args.reconcile_capability_truth:
        reconcile_capability_truth()
        return
    if args.check_c14_receipt_equivalence:
        check_c14_receipt_equivalence()
        return
    cells, evidence, _ = load_sources()
    if args.write:
        write_outputs(outputs(cells, evidence))
    elif args.check:
        check_outputs(outputs(cells, evidence))
    else:
        summary(cells)


if __name__ == "__main__":
    main()
