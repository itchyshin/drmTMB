#!/usr/bin/env python3
"""Generate the response-missingness formula inventory from the capability ledger.

The existing ``missing_response`` ledger axis is deliberately family-level.  This
tool projects each ``model_surface`` cell onto that family evidence without
silently promoting a random, structured, covariance, or REML formula because
its base density has a response mask.
"""

from __future__ import annotations

import argparse
import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
LEDGER = ROOT / "docs/dev-log/dashboard/capability-ledger"
CELLS = LEDGER / "cells.tsv"
OUTPUT = LEDGER / "response-mask-formulas.tsv"

FIELDS = [
    "formula_cell_id", "model_cell_id", "family_type", "model_type",
    "route_variant", "route_modifier", "dpar", "effect_type",
    "structure_provider", "dimension", "q_gate", "estimator",
    "formula_status", "family_mask_gate", "formula_mask_gate",
    "claim_boundary", "next_gate",
]

EXPLICIT_BOUNDARIES = (
    {
        "formula_cell_id": "rmf-biv-gaussian-mu12-labelled-intercept",
        "model_cell_id": "mc-0069,mc-0070",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_labelled_mu1_mu2_intercept",
        "route_modifier": "covariance_block",
        "dpar": "mu1+mu2",
        "effect_type": "labelled_covariance_block",
        "structure_provider": "none",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched labelled block "
            "`mu1 ~ (1 | p | id)`, `mu2 ~ (1 | p | id)`, not either endpoint "
            "alone. G2 conditional TMB-objective equality at the fitted latent mode, "
            "including the independent-standard-normal random-effect prior, and "
            "component-wise sentinel retapes validate the response mask. G3 deterministic "
            "25% MCAR recovery validates fixed effects, both residual scales, both latent "
            "SDs, the latent correlation, and rho12. This is not a marginal dense-MVN "
            "oracle, a slope, a structured effect, REML, interval/coverage evidence, "
            "or dense known-V partial-response support."
        ),
        "next_gate": (
            "Validate the next admitted labelled geometry separately; retain dense known-V "
            "partial responses as blocked until component-level covariance slicing exists."
        ),
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-sigma12-labelled-intercept",
        "model_cell_id": "mc-0071,mc-0072",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_labelled_sigma1_sigma2_intercept",
        "route_modifier": "covariance_block",
        "dpar": "sigma1+sigma2",
        "effect_type": "labelled_covariance_block",
        "structure_provider": "none",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched labelled residual-scale block "
            "`sigma1 ~ 1 + (1 | p | id)`, `sigma2 ~ 1 + (1 | p | id)`, not either "
            "endpoint alone. G2 conditional TMB-objective equality at the fitted latent mode "
            "includes the independent-standard-normal scale latent prior, and direct endpoint "
            "sentinel retapes leave the objective and gradient unchanged. G3 deterministic 25% "
            "MCAR recovery validates both fixed location vectors, both fixed log-scale terms, "
            "both scale SDs, their correlation, and rho12 on a 128-group, 12-observation-per-"
            "group fixture. This is not a slope, a mixed location-scale block, a structured "
            "effect, REML, interval/coverage evidence, or dense known-V partial-response support."
        ),
        "next_gate": "Validate each remaining labelled bivariate scale geometry separately.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-phylo-mu12-q2-intercept",
        "model_cell_id": "mc-0083,mc-0084",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_phylo_mu1_mu2_intercept",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "phylo",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched phylogenetic q2 location "
            "block `mu1 ~ phylo(1 | p | species, tree = tree)`, `mu2 ~ "
            "phylo(1 | p | species, tree = tree)`, not either endpoint alone. G2 "
            "conditional TMB-objective equality at the fitted latent mode includes the "
            "correlated phylogenetic-field prior, and component-wise sentinel retapes "
            "validate the response mask. G3 deterministic 25% MCAR recovery validates "
            "both fixed-effect vectors, both residual scales, both phylogenetic SDs, "
            "the phylogenetic correlation, and rho12 on a 32-tip, 8-observation-per-tip "
            "fixture. This is not a dense marginal-MVN oracle, a slope, another structured "
            "provider, REML, interval/coverage evidence, or dense known-V partial-response support."
        ),
        "next_gate": (
            "Validate each remaining bivariate structured geometry separately; retain dense "
            "known-V partial responses as blocked until component-level covariance slicing exists."
        ),
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-phylo-mu12-q2-slope",
        "model_cell_id": "mc-0085,mc-0086",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_phylo_mu1_mu2_slope",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "phylo",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched phylogenetic q2 slope block "
            "`mu1 ~ phylo(0 + x | p | species, tree = tree)`, `mu2 ~ phylo(0 + x | "
            "p | species, tree = tree)`, not either endpoint alone. G2 conditional "
            "TMB-objective equality at the fitted latent mode includes the correlated "
            "phylogenetic-field prior, and direct endpoint sentinel retapes leave the "
            "objective and gradient unchanged. G3 deterministic 25% MCAR recovery validates "
            "both fixed-effect vectors, both residual scales, both phylogenetic slope SDs, "
            "the slope correlation, and rho12 on a 128-tip, 20-observation-per-tip fixture. "
            "This is not an intercept or q4+ block, another provider, REML, interval/coverage "
            "evidence, or dense known-V partial-response support."
        ),
        "next_gate": "Validate each remaining phylogenetic bivariate geometry separately.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-spatial-mu1-q2-intercept",
        "model_cell_id": "mc-0107",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_spatial_mu1_mu2_intercept",
        "route_modifier": "structured_q2",
        "dpar": "mu1",
        "effect_type": "structured_covariance_block",
        "structure_provider": "spatial",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "needs_formula_evidence",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G1",
        "claim_boundary": (
            "The bivariate spatial q2 response-mask claim is not currently supported: "
            "at the cited 128-site, 20-observation fixture the mu1 location intercept "
            "lands 1.199 from truth against a 0.25 bound whose own standard error is "
            "0.5568, so the fixture does not identify the intercept to the precision "
            "the claim states; the slope, spatial SDs, spatial correlation, residual "
            "scales, and rho12 all recover."
        ),
        "next_gate": "Redesign the fixture (more sites, or a lower-variance information design) so the mu1 intercept's own SE clears the 0.25 bound, then re-run G3 recovery.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-spatial-mu2-q2-intercept",
        "model_cell_id": "mc-0108",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_spatial_mu1_mu2_intercept",
        "route_modifier": "structured_q2",
        "dpar": "mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "spatial",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "needs_formula_evidence",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G1",
        "claim_boundary": (
            "The bivariate spatial q2 response-mask claim is not currently supported: "
            "the mu2 location intercept lands 0.882 from truth against a 0.25 bound "
            "whose own standard error is 0.5244, so the cited fixture does not "
            "identify the intercept to the claimed precision; every other checked "
            "quantity recovers."
        ),
        "next_gate": "Redesign the fixture (more sites, or a lower-variance information design) so the mu2 intercept's own SE clears the 0.25 bound, then re-run G3 recovery.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-spatial-mu12-q2-slope",
        "model_cell_id": "mc-0109,mc-0110",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_spatial_mu1_mu2_slope",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "spatial",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched spatial q2 slope block "
            "`mu1 ~ spatial(0 + x | p | site, coords = coords)`, `mu2 ~ spatial(0 + "
            "x | p | site, coords = coords)`, not either endpoint alone. G2 conditional "
            "TMB-objective equality at the fitted latent mode includes the correlated "
            "spatial-field prior, and direct endpoint sentinel retapes leave the objective "
            "and gradient unchanged. G3 deterministic 25% MCAR recovery validates both "
            "fixed-effect vectors, both residual scales, both spatial slope SDs, the slope "
            "correlation, and rho12 on a 128-site, 20-observation-per-site fixture. This is "
            "not an intercept or q4+ block, another provider, REML, interval/coverage evidence, "
            "or dense known-V partial-response support."
        ),
        "next_gate": "Validate each remaining spatial bivariate geometry separately.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-animal-mu12-q2-intercept",
        "model_cell_id": "mc-0129,mc-0130",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_animal_mu1_mu2_intercept",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "animal",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched animal q2 location block "
            "`mu1 ~ animal(1 | p | id, Ainv = Ainv)`, `mu2 ~ animal(1 | p | id, "
            "Ainv = Ainv)`, not either endpoint alone. G2 conditional TMB-objective "
            "equality at the fitted latent mode includes the correlated animal-field prior, "
            "and component-wise sentinel retapes validate the response mask. G3 deterministic "
            "25% MCAR recovery validates both fixed-effect vectors, both residual scales, "
            "both animal SDs, the animal correlation, and rho12 on an independent 64-ID, "
            "20-observation-per-ID fixture. This is not relmat evidence, a slope, another "
            "animal geometry, REML, interval/coverage evidence, or dense known-V partial-"
            "response support."
        ),
        "next_gate": "Validate other animal geometries with their own recovery designs.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-animal-mu12-q2-slope",
        "model_cell_id": "mc-0131,mc-0132",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_animal_mu1_mu2_slope",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "animal",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched animal q2 slope block "
            "`mu1 ~ animal(0 + x | p | id, Ainv = Ainv)`, `mu2 ~ animal(0 + x | "
            "p | id, Ainv = Ainv)`, not either endpoint alone. G2 conditional TMB-objective "
            "equality at the fitted latent mode includes the correlated animal-field prior, "
            "and direct endpoint sentinel retapes leave the objective and gradient unchanged. "
            "G3 deterministic 25% MCAR recovery validates both fixed-effect vectors, both "
            "residual scales, both animal slope SDs, the slope correlation, and rho12 on an "
            "independently seeded 64-ID, 20-observation-per-ID fixture. This is not an "
            "intercept or q4+ block, relmat evidence, REML, interval/coverage evidence, or "
            "dense known-V partial-response support."
        ),
        "next_gate": "Validate each remaining animal bivariate geometry separately.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-relmat-mu12-q2-intercept",
        "model_cell_id": "mc-0151,mc-0152",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_relmat_mu1_mu2_intercept",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "relmat",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "formula_validated",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "The accepted bivariate formula is the matched relmat q2 location block "
            "`mu1 ~ relmat(1 | p | id, Q = Q)`, `mu2 ~ relmat(1 | p | id, Q = Q)`, "
            "not either endpoint alone. G2 conditional TMB-objective equality at the fitted "
            "latent mode includes the correlated relatedness-field prior, and component-wise "
            "sentinel retapes validate the response mask. G3 deterministic 25% MCAR recovery "
            "validates both fixed-effect vectors, both residual scales, both relatedness SDs, "
            "the relatedness correlation, and rho12 on an independent 64-ID, 20-observation-"
            "per-ID fixture. This is not animal evidence, a slope, a Q/K representation claim "
            "beyond the tested Q route, REML, interval/coverage evidence, or dense known-V "
            "partial-response support."
        ),
        "next_gate": "Validate animal and other relmat geometries with their own recovery designs.",
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-relmat-mu12-q2-slope",
        "model_cell_id": "mc-0153,mc-0154",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "matched_relmat_mu1_mu2_slope",
        "route_modifier": "structured_q2",
        "dpar": "mu1+mu2",
        "effect_type": "structured_covariance_block",
        "structure_provider": "relmat",
        "dimension": "bivariate",
        "q_gate": "q2",
        "estimator": "ML",
        "formula_status": "needs_formula_evidence",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G1",
        "claim_boundary": (
            "The bivariate relmat q2 matched-slope response-mask claim is not currently "
            "supported: on the cited seed the relmat slope correlation recovers at 0.5167 "
            "against a truth of 0.30, a deviation of 0.217 over a 0.20 bound; the overestimate "
            "direction is consistent with this cell's own recorded right-tail miss asymmetry "
            "at this cluster count, so the next gate is a replicated multi-seed estimate with "
            "an MCSE rather than a wider bound."
        ),
        "next_gate": (
            "Run a replicated multi-seed estimate of the relmat slope correlation with an MCSE "
            "before re-promoting; do not widen the bound to accommodate the single cited seed."
        ),
    },
    {
        "formula_cell_id": "rmf-biv-gaussian-meta-v-partial",
        "model_cell_id": "",
        "family_type": "biv_gaussian",
        "model_type": "2",
        "route_variant": "partial_response_dense_known_V",
        "route_modifier": "meta_V",
        "dpar": "rho12",
        "effect_type": "fixed",
        "structure_provider": "none",
        "dimension": "bivariate",
        "q_gate": "na",
        "estimator": "ML",
        "formula_status": "blocked_dense_known_V",
        "family_mask_gate": "G3",
        "formula_mask_gate": "G0",
        "claim_boundary": (
            "Partial bivariate response rows with dense meta_V(V = V) are rejected; "
            "the covariance needs component-level slicing."
        ),
        "next_gate": (
            "Implement component-level covariance slicing and verify it against a dense-MVN oracle."
        ),
    },
)

# ``cells.tsv`` is a parameter-target ledger, so one accepted covariance
# formula may be represented by several endpoint rows.  The response-mask
# surface is formula-level: replace those bookkeeping fragments with their one
# explicit paired-formula row rather than counting them twice.
EXPLICIT_MODEL_CELL_IDS = frozenset(
    cell_id.strip()
    for boundary in EXPLICIT_BOUNDARIES
    for cell_id in boundary["model_cell_id"].split(",")
    if cell_id.strip()
)

# Formula-level evidence is deliberately enumerated here rather than inferred
# from a family mask or from the complete-response model-surface ledger.
FORMULA_EVIDENCE = {
    "mc-0593": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1", "replace_model_claim": True,
        "claim_boundary": "The zero-one-beta phylo sigma q1 response-mask claim is not currently supported: the retaped sentinel objective returns nlminb convergence code 1 (\"false convergence\") in two to six iterations under both 200- and 900-iteration budgets, with a sigma-intercept recovery miss of 0.52 against a 0.15 bound; the 2026-08-05 135-trace campaign independently withheld this cell on the interval axis (tools/capability_ledger.py ARC135_WITHHELD), which corroborates but does not itself govern this formula status.",
        "next_gate": "Diagnose the nlminb false-convergence signature on the retaped sentinel objective (control= budget/tolerance sweep) before re-attempting recovery; re-run G3 and confirm the sigma-intercept miss clears the 0.15 bound.",
    },
    "mc-0594": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1", "replace_model_claim": True,
        "claim_boundary": "The zero-one-beta animal sigma q1 response-mask claim is not currently supported: the retaped sentinel objective shows the same false-convergence signature as mc-0593 under both optimizer budgets, and the 2026-08-05 135-trace campaign independently withheld this cell on the interval axis, corroborating a near-singular Hessian rather than an optimizer-budget shortfall.",
        "next_gate": "Diagnose the shared false-convergence/near-singular-Hessian signature (see mc-0593) before re-attempting recovery; re-run G3 once the objective converges cleanly.",
    },
    "mc-0583": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct zero-one-beta observed-data objective and numerical-gradient "
            "equality, direct atom/interior response-sentinel retapes, and masked-"
            "versus-observed objective equality validate `y ~ x + phylo(1 | species, tree "
            "= tree)`. Masked-versus-observed agreement is evidenced at the OBJECTIVE "
            "level (relative difference 1.9e-13 to 9.0e-13 across all five providers, "
            "from identical starting values), not at the coefficient level; coefficient "
            "agreement ranges from 5.3e-10 to 1.7e-5 across providers because the "
            "fixtures differ in conditioning by roughly 5e4 along the intercept "
            "direction, and is not an invariant of the response mask. G3 uses a "
            "deterministic 64-tip, 50-observation-per-tip fixture "
            "to recover fixed location, constant beta scale, and the phylogenetic mu "
            "SD. This is not another provider, sigma or atom endpoint, a labelled or "
            "correlated block, REML, interval or coverage evidence, or missing-predictor "
            "support."
        ),
        "next_gate": "Validate each zero-one-beta provider and endpoint separately; do not reuse this phylogenetic mu evidence.",
    },
    "mc-0584": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct zero-one-beta observed-data objective and numerical-gradient "
            "equality, direct atom/interior response-sentinel retapes, and masked-"
            "versus-observed objective equality validate `y ~ x + animal(1 | species, Ainv "
            "= Ainv)`. Masked-versus-observed agreement is evidenced at the OBJECTIVE "
            "level (relative difference 1.9e-13 to 9.0e-13 across all five providers, "
            "from identical starting values), not at the coefficient level; coefficient "
            "agreement ranges from 5.3e-10 to 1.7e-5 across providers because the "
            "fixtures differ in conditioning by roughly 5e4 along the intercept "
            "direction, and is not an invariant of the response mask. G3 uses a "
            "deterministic 64-ID, 50-observation-per-ID fixture "
            "to recover fixed location, constant beta scale, and the animal mu SD. "
            "This is not phylogenetic or relmat evidence, another endpoint, a labelled "
            "or correlated block, REML, interval or coverage evidence, or missing-"
            "predictor support."
        ),
        "next_gate": "Validate each zero-one-beta provider and endpoint separately; do not reuse this animal mu evidence.",
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "replace_model_claim": True,
            "claim_boundary": (
                "G2 direct zero-one-beta observed-data objective and numerical-gradient "
                "equality, direct atom/interior response-sentinel retapes, and masked-"
                "versus-observed objective equality validate this q1 location formula. "
                "Masked-versus-observed agreement is evidenced at the OBJECTIVE level "
                "(relative difference 1.9e-13 to 9.0e-13 across all five providers, "
                "from identical starting values), not at the coefficient level; "
                "coefficient agreement ranges from 5.3e-10 to 1.7e-5 across providers "
                "because the fixtures differ in conditioning by roughly 5e4 along the "
                "intercept direction, and is not an invariant of the response mask. G3 uses "
                "a deterministic 64-group, 50-observation-per-group fixture to recover "
                "fixed location, constant beta scale, and the named structured mu SD. "
                "This is not evidence for another provider or endpoint, a labelled or "
                "correlated block, REML, interval or coverage evidence, or missing-"
                "predictor support."
            ),
            "next_gate": "Validate each zero-one-beta provider and endpoint separately; do not reuse this provider-specific mu evidence.",
        }
        for cell_id in ("mc-0585", "mc-0586")
    },
    "mc-0587": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct zero-one-beta observed-data objective and numerical-gradient "
            "equality, direct atom/interior response-sentinel retapes, and masked-"
            "versus-observed objective equality validate `y ~ x + phylo_interaction(1 | "
            "plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`. "
            "Masked-versus-observed agreement is evidenced at the OBJECTIVE level "
            "(relative difference 1.9e-13 to 9.0e-13 across all five providers, from "
            "identical starting values), not at the coefficient level; coefficient "
            "agreement ranges from 5.3e-10 to 1.7e-5 across providers because the "
            "fixtures differ in conditioning by roughly 5e4 along the intercept "
            "direction, and is not an invariant of the response mask. G3 uses "
            "a deterministic 8-by-8 pair grid with 50 observations per pair to recover "
            "fixed location and the phylogenetic-interaction mu SD. This is not another "
            "endpoint or provider, a labelled or correlated block, REML, interval or "
            "coverage evidence, or missing-predictor support."
        ),
        "next_gate": "Validate each zero-one-beta scale or atom endpoint separately; do not reuse this mu evidence.",
    },
    "mc-0595": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct zero-one-beta observed-data objective equality against a "
            "hand-written dense oracle (tolerance 1e-8), central-difference gradient "
            "equality (tolerance 2e-5), in-domain atom/interior response-sentinel "
            "invariance (sentinels c(0, 1, .5)), masked-versus-observed `coef(sigma)` "
            "and `sdpars$sigma` equality (tolerance 1e-6), and `nobs()`/`observed_y` "
            "agreement validate the univariate zero-one-beta unlabelled q1 relmat "
            "sigma-side intercept ML response-mask formula `sigma ~ relmat(1 | "
            "species, K = K)`. G3 deterministic known-DGP recovery (single "
            "deterministic seed 2026081824) gives a log-sigma intercept error of "
            "0.0070 against a 0.15 bound and a `sd(relmat(1 | species))` error of "
            "0.0255 against a 0.25 bound. Convergence was clean (\"relative "
            "convergence (4)\") at every one of 5 seeds probed, including the "
            "sentinel helper's independent nlminb re-optimization. This is not "
            "another zero-one-beta scale provider, another endpoint, REML, "
            "interval/coverage evidence, or missing predictors."
        ),
        "next_gate": (
            "Validate each remaining zero-one-beta scale provider separately; this "
            "does not transfer to another provider, another endpoint, REML, "
            "interval/coverage evidence, or missing predictors."
        ),
    },
    "mc-0596": {
        "claim_boundary": (
            "Attempted and refused on measurement, not deferred by policy: the "
            "outer fit reports convergence 0, but the sentinel helper's independent "
            "nlminb re-optimization from that same optimum returns \"false "
            "convergence (8)\", reproduced at eval.max/iter.max of 200, 900 and "
            "3000 — so this is not optimizer starvation. Measured cause: the "
            "exp(-distance/range) covariance at the 64-site scale has condition "
            "number about 917 (eigenvalues 0.030-27.7) with a near-constant leading "
            "eigenvector that aliases the sigma fixed intercept; only 1 of 4 seeds "
            "fell inside the 0.15 log-sigma bound. The next gate is a "
            "better-conditioned spatial design or a reparameterisation that "
            "separates the constant mode from the sigma intercept, not a larger "
            "optimizer budget or a longer fixture. "
        ),
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "next_gate": (
            "Attempted and refused on measurement, not deferred by policy: the "
            "outer fit reports convergence 0, but the sentinel helper's independent "
            "nlminb re-optimization from that same optimum returns \"false "
            "convergence (8)\", reproduced at eval.max/iter.max of 200, 900 and "
            "3000 — so this is not optimizer starvation. Measured cause: the "
            "exp(-distance/range) covariance at the 64-site scale has condition "
            "number about 917 (eigenvalues 0.030-27.7) with a near-constant leading "
            "eigenvector that aliases the sigma fixed intercept; only 1 of 4 seeds "
            "fell inside the 0.15 log-sigma bound. The next gate is a "
            "better-conditioned spatial design or a reparameterisation that "
            "separates the constant mode from the sigma intercept, not a larger "
            "optimizer budget or a longer fixture."
        ),
    },
    "mc-0597": {
        "claim_boundary": (
            "Attempted and refused on measurement, not deferred by policy: across "
            "7 deterministic seeds at the 8x8-tip, 60-observation scale, 1 gave "
            "outright \"false convergence (8)\" and all 6 that converged missed the "
            "0.15 log-sigma bound (errors 0.11-0.33); 0 of 7 satisfied both "
            "conditions. Measured cause: phylo_interaction composes two tree GMRFs "
            "each carrying unobserved internal-node latents, giving 196 latent "
            "dimensions against only 64 observed plant:pollinator combinations. The "
            "next gate is a design with more observed combinations per latent "
            "dimension, or a reduced-rank representation, not a larger optimizer "
            "budget. "
        ),
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "next_gate": (
            "Attempted and refused on measurement, not deferred by policy: across "
            "7 deterministic seeds at the 8x8-tip, 60-observation scale, 1 gave "
            "outright \"false convergence (8)\" and all 6 that converged missed the "
            "0.15 log-sigma bound (errors 0.11-0.33); 0 of 7 satisfied both "
            "conditions. Measured cause: phylo_interaction composes two tree GMRFs "
            "each carrying unobserved internal-node latents, giving 196 latent "
            "dimensions against only 64 observed plant:pollinator combinations. The "
            "next gate is a design with more observed combinations per latent "
            "dimension, or a reduced-rank representation, not a larger optimizer "
            "budget."
        ),
    },
    # The zoi/coi structured-atom admission guard in R/drmTMB.R was lifted on
    # 2026-08-14 after src/drmTMB.cpp:3226 was confirmed to already mask the
    # full zero-one-beta contribution on observed_y(i) == 1; src/ itself was
    # not changed. All seven admitted zoi/coi structured cells below were then
    # measured against the full five-part contract and refused evidence, not
    # policy: none earn promotion out of needs_formula_evidence/G1.
    "mc-0603": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. The outer fit reports "
            "convergence 0, but the sentinel helper's independent nlminb "
            "re-optimization returns \"false convergence (8)\" on both "
            "sentinel pairs, budget-independent (confirmed with a fresh AD "
            "tape at eval.max/iter.max of 900). Recovery was in bounds "
            "(log-zoi-intercept error 0.14 against a 0.15 bound; sd(phylo) "
            "error 0.004 against a 0.25 bound) — the refusal is the "
            "near-singular Hessian, the same signature as mc-0593/mc-0594, "
            "not the recovery. The next gate is a better-conditioned "
            "phylogenetic design or a reparameterisation that separates the "
            "near-singular mode from the zoi intercept, not a larger "
            "optimizer budget or a longer fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. The outer fit reports "
            "convergence 0, but the sentinel helper's independent nlminb "
            "re-optimization returns \"false convergence (8)\" on both "
            "sentinel pairs, budget-independent (confirmed with a fresh AD "
            "tape at eval.max/iter.max of 900). Recovery was in bounds "
            "(log-zoi-intercept error 0.14 against a 0.15 bound; sd(phylo) "
            "error 0.004 against a 0.25 bound) — the refusal is the "
            "near-singular Hessian, the same signature as mc-0593/mc-0594, "
            "not the recovery. The next gate is a better-conditioned "
            "phylogenetic design or a reparameterisation that separates the "
            "near-singular mode from the zoi intercept, not a larger "
            "optimizer budget or a longer fixture."
        ),
    },
    "mc-0604": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. The same false-convergence "
            "signature as mc-0603 reproduces here — the sentinel helper's "
            "independent nlminb re-optimization returns \"false convergence "
            "(8)\", budget-independent (confirmed with a fresh AD tape) — "
            "with recovery in bounds. The refusal is the near-singular "
            "Hessian, not the recovery. The next gate is a better-conditioned "
            "animal-model design or a reparameterisation that separates the "
            "near-singular mode from the zoi intercept, not a larger "
            "optimizer budget or a longer fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. The same false-convergence "
            "signature as mc-0603 reproduces here — the sentinel helper's "
            "independent nlminb re-optimization returns \"false convergence "
            "(8)\", budget-independent (confirmed with a fresh AD tape) — "
            "with recovery in bounds. The refusal is the near-singular "
            "Hessian, not the recovery. The next gate is a better-conditioned "
            "animal-model design or a reparameterisation that separates the "
            "near-singular mode from the zoi intercept, not a larger "
            "optimizer budget or a longer fixture."
        ),
    },
    "mc-0605": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. This is the best-behaved of "
            "the seven measured zoi/coi cells: clean convergence at 2 of 3 "
            "scanned seeds, with recovery in bounds where it converged "
            "(log-zoi-intercept error 0.009-0.065 against a 0.15 bound; "
            "sd(relmat) error 0.029-0.101 against a 0.25 bound) — but a "
            "genuine failing seed (\"false convergence (8)\") was found "
            "before anything was committed. The next gate is a multi-seed "
            "convergence study establishing the failure rate, not a single "
            "passing seed, and not a larger optimizer budget or a longer "
            "fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. This is the best-behaved of "
            "the seven measured zoi/coi cells: clean convergence at 2 of 3 "
            "scanned seeds, with recovery in bounds where it converged "
            "(log-zoi-intercept error 0.009-0.065 against a 0.15 bound; "
            "sd(relmat) error 0.029-0.101 against a 0.25 bound) — but a "
            "genuine failing seed (\"false convergence (8)\") was found "
            "before anything was committed. The next gate is a multi-seed "
            "convergence study establishing the failure rate, not a single "
            "passing seed, and not a larger optimizer budget or a longer "
            "fixture."
        ),
    },
    "mc-0607": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. Clean at the original seed but "
            "\"false convergence (8)\" at an alternate seed — notably the "
            "seed with the best recovery; recovery ranges 0.03-0.13 against a "
            "0.15 bound across 4 seeds. The mc-0597 internal-node-GMRF "
            "fragility (two composed tree GMRFs carrying unobserved "
            "internal-node latents against too few observed combinations) "
            "reappears at the zoi endpoint. The next gate is a design with "
            "more observed combinations per latent dimension, or a "
            "reduced-rank representation, not a larger optimizer budget or a "
            "longer fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. Clean at the original seed but "
            "\"false convergence (8)\" at an alternate seed — notably the "
            "seed with the best recovery; recovery ranges 0.03-0.13 against a "
            "0.15 bound across 4 seeds. The mc-0597 internal-node-GMRF "
            "fragility (two composed tree GMRFs carrying unobserved "
            "internal-node latents against too few observed combinations) "
            "reappears at the zoi endpoint. The next gate is a design with "
            "more observed combinations per latent dimension, or a "
            "reduced-rank representation, not a larger optimizer budget or a "
            "longer fixture."
        ),
    },
    "mc-0613": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. Converges cleanly, but "
            "recovery is unstable: sd(phylo) error ranges 0.006 to 0.227 "
            "against a 0.15 bound across 4 seeds, 3 of 4 outside. The next "
            "gate is a better-conditioned phylogenetic design or a "
            "multi-seed recovery study, not a larger optimizer budget or a "
            "longer fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. Converges cleanly, but "
            "recovery is unstable: sd(phylo) error ranges 0.006 to 0.227 "
            "against a 0.15 bound across 4 seeds, 3 of 4 outside. The next "
            "gate is a better-conditioned phylogenetic design or a "
            "multi-seed recovery study, not a larger optimizer budget or a "
            "longer fixture."
        ),
    },
    "mc-0614": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. The same false-convergence "
            "signature as mc-0603/mc-0604 reproduces here — the sentinel "
            "helper's independent nlminb re-optimization returns \"false "
            "convergence (8)\", budget-independent — with recovery in "
            "bounds. The refusal is the near-singular Hessian, not the "
            "recovery. The next gate is a better-conditioned animal-model "
            "design or a reparameterisation that separates the near-singular "
            "mode from the coi intercept, not a larger optimizer budget or a "
            "longer fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. The same false-convergence "
            "signature as mc-0603/mc-0604 reproduces here — the sentinel "
            "helper's independent nlminb re-optimization returns \"false "
            "convergence (8)\", budget-independent — with recovery in "
            "bounds. The refusal is the near-singular Hessian, not the "
            "recovery. The next gate is a better-conditioned animal-model "
            "design or a reparameterisation that separates the near-singular "
            "mode from the coi intercept, not a larger optimizer budget or a "
            "longer fixture."
        ),
    },
    "mc-0617": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1",
        "claim_boundary": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. Converges cleanly; recovery "
            "ranges 0.01 to 0.31 against a 0.15 bound across 4 seeds, 2 of 4 "
            "outside. The mc-0597/mc-0607 internal-node-GMRF fragility "
            "reappears at the coi endpoint. The next gate is a design with "
            "more observed combinations per latent dimension, or a "
            "reduced-rank representation, not a larger optimizer budget or a "
            "longer fixture. "
        ),
        "next_gate": (
            "The package guard that previously refused this route was lifted "
            "on 2026-08-14 after src/drmTMB.cpp was confirmed to mask the full "
            "zero-one-beta contribution; the route is admitted and was then "
            "measured, not deferred by policy. Converges cleanly; recovery "
            "ranges 0.01 to 0.31 against a 0.15 bound across 4 seeds, 2 of 4 "
            "outside. The mc-0597/mc-0607 internal-node-GMRF fragility "
            "reappears at the coi endpoint. The next gate is a design with "
            "more observed combinations per latent dimension, or a "
            "reduced-rank representation, not a larger optimizer budget or a "
            "longer fixture."
        ),
    },
    "mc-0364": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct hurdle-NB2 observed-data objective and numerical-gradient "
            "equality, direct count-sentinel retapes, and masked-versus-observed fit "
            "equality validate `y ~ x, sigma ~ 1, hu ~ relmat(1 | id, Q = Q)`. "
            "G3 uses a deterministic 80-ID, 30-observation-per-ID fixture to recover "
            "fixed log-mean, constant log-scale, fixed hurdle probability, and the "
            "relmat hurdle SD. This is not a mu-side structured effect, another hurdle "
            "provider, a slope, a labelled or correlated block, REML, interval or "
            "coverage evidence, or missing-predictor support."
        ),
        "next_gate": "Validate each remaining hurdle or mixture formula separately; do not use this hu evidence for another endpoint.",
    },
    "mc-0493": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct Student-t observed-data objective and numerical-gradient "
            "equality, direct continuous-sentinel retapes, and masked-versus-observed "
            "fit equality validate `y ~ x + spatial(1 | id, coords = coords), "
            "sigma ~ 1`. G3 uses a deterministic 64-site, 40-observation-per-site "
            "known-DGP fixture to recover fixed location, constant log-scale, fixed "
            "shape, and the spatial intercept SD. This is not a slope, a labelled or "
            "correlated block, another provider, nu-side structure, REML, interval or "
            "coverage evidence, or missing-predictor support."
        ),
        "next_gate": "Validate the Student spatial one-slope formula separately; retain the remaining structured endpoints as separate cells.",
    },
    "mc-0494": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct Student-t observed-data objective and numerical-gradient "
            "equality, direct continuous-sentinel retapes, and masked-versus-observed "
            "fit equality validate `y ~ x + spatial(1 + x | id, coords = coords), "
            "sigma ~ 1`. G3 uses a deterministic 64-site, 48-observation-per-site "
            "known-DGP fixture to recover fixed location, constant log-scale, fixed "
            "shape, and both independent spatial location SDs. This is not a labelled "
            "or correlated block, multiple slopes, another provider, nu-side structure, "
            "REML, interval or coverage evidence, or missing-predictor support."
        ),
        "next_gate": "Validate the Student phylogenetic nu formula separately; do not use this mu evidence for another endpoint.",
    },
    "mc-0495": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 direct Student-t observed-data objective and numerical-gradient "
            "equality, direct continuous-sentinel retapes, and masked-versus-observed "
            "fit equality validate `y ~ x, sigma ~ 1, nu ~ phylo(1 | id, tree = "
            "tree)`. G3 uses a deterministic 48-tip, 200-observation-per-tip "
            "tail-information fixture to recover fixed location, constant log-scale, "
            "fixed shape, and the phylogenetic nu SD. This is not mu-side spatial "
            "evidence, another provider, another structured endpoint, a labelled or "
            "correlated block, REML, interval or coverage evidence, or missing-predictor "
            "support."
        ),
        "next_gate": "Validate any other admitted Student formula separately; do not reuse this nu-side evidence for a mu formula.",
    },
    **{
        cell_id: {
            "formula_status": "not_admitted",
            "formula_mask_gate": "G0",
            "replace_model_claim": True,
            "claim_boundary": (
                "This endpoint-only bivariate random-effect fragment is not an accepted "
                "formula. The parser requires a matched labelled covariance block across "
                "mu1 and mu2, or a same-response mu/sigma pair; it rejects an unlabelled "
                "term and a labelled endpoint without its partner. The corresponding accepted "
                "intercept block is represented separately as "
                "`rmf-biv-gaussian-mu12-labelled-intercept`."
            ),
            "next_gate": "Keep the endpoint fragment absent; validate the paired labelled formula cell instead.",
        }
        for cell_id in ("mc-0069", "mc-0070")
    },
    "mc-0272": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data dense full marginal-Gaussian likelihood equality "
            "and direct sentinel retapes, plus a deterministic 25% MCAR known-DGP "
            "recovery check, validate the univariate Gaussian unlabelled q1 "
            "phylo mu random-intercept ML response-mask formula. The check covers "
            "fixed mu coefficients, constant residual sigma, and the phylogenetic "
            "mu SD. It does not promote phylo slopes or q2 blocks, sigma-side "
            "phylo effects, other providers, bivariate, non-Gaussian, or missing-"
            "predictor ML formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining phylo geometry.",
    },
    "mc-0273": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for all fixed mu coefficients, both "
            "phylogenetic mu SDs, residual sigma, and likelihood, plus direct continuous-"
            "response sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the univariate Gaussian unlabelled q1 phylo mu intercept-plus-slope "
            "ML response-mask formula `phylo(1 + x | species, tree = tree)`. The recovery "
            "fixture has 64 tips and 12 observations per tip; fixed-effect tolerance is "
            "wider than an independent-group design because it shares one correlated "
            "phylogenetic field. It does not promote a labelled or q2 block, sigma-side "
            "phylo effects, another provider, bivariate, REML, intervals/coverage, or "
            "missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining phylo geometry.",
    },
    "mc-0275": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "the phylogenetic sigma SD, and likelihood, plus direct continuous-response "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery validate "
            "the univariate Gaussian unlabelled q1 sigma-side phylo intercept ML response-"
            "mask formula `y ~ x, sigma ~ phylo(1 | species, tree = tree)`. The recovery "
            "fixture has 64 tips and 20 observations per tip. It does not promote a sigma "
            "slope or q2 block, mu-side phylo effects, another provider, bivariate, REML, "
            "interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining phylo geometry.",
    },
    "mc-0276": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "both phylogenetic sigma SDs, and likelihood, plus direct continuous-response "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery validate "
            "the univariate Gaussian unlabelled q1 sigma-side phylo intercept-plus-slope "
            "ML response-mask formula `y ~ x, sigma ~ phylo(1 + x | species, tree = tree)`. "
            "The recovery fixture has 64 tips and 20 observations per tip. It does not "
            "promote a labelled/q2 block, mu-side phylo effects, another provider, bivariate, "
            "REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining phylo geometry.",
    },
    "mc-0288": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "the spatial sigma SD, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 spatial sigma-side intercept ML response-mask "
            "formula `y ~ x, sigma ~ spatial(1 | site, coords = coords)`. The recovery fixture "
            "has 64 sites and 20 observations per site. It does not promote a spatial slope "
            "or q2 block, mu-side spatial effects, another provider, bivariate, REML, "
            "interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining spatial geometry.",
    },
    "mc-0289": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "both spatial sigma SDs, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 spatial sigma-side intercept-plus-slope ML "
            "response-mask formula `y ~ x, sigma ~ spatial(1 + x | site, coords = coords)`. "
            "The recovery fixture has 64 sites and 20 observations per site. It does not "
            "promote a labelled/q2 block, mu-side spatial effects, another provider, bivariate, "
            "REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining spatial geometry.",
    },
    "mc-0285": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu coefficients, the spatial "
            "mu SD, residual sigma, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the univariate "
            "Gaussian unlabelled q1 spatial mu intercept ML response-mask formula `y ~ x + "
            "spatial(1 | site, coords = coords), sigma ~ 1`. The recovery fixture has 64 sites "
            "and 20 observations per site. It does not promote a spatial slope or q2 block, "
            "sigma-side spatial effects, another provider, bivariate, REML, interval/coverage, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining spatial geometry.",
    },
    "mc-0286": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu coefficients, both spatial "
            "mu SDs, residual sigma, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the univariate "
            "Gaussian unlabelled q1 spatial mu intercept-plus-slope ML response-mask formula "
            "`y ~ x + spatial(1 + x | site, coords = coords), sigma ~ 1`. The recovery fixture "
            "has 80 sites and 20 observations per site; the fixed-effect tolerance reflects one "
            "realized correlated spatial field. It does not promote a labelled/q2 block, sigma-"
            "side spatial effects, another provider, bivariate, REML, interval/coverage, or "
            "missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining spatial geometry.",
    },
    "mc-0287": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-response restricted-likelihood equality and direct continuous-response "
            "sentinel retapes, plus G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 spatial mu intercept REML response-mask formula "
            "`y ~ x + spatial(1 | site, coords = coords), sigma ~ 1`. The recovery fixture has "
            "128 sites and 20 observations per site. The 64-site rung did not recover fixed mu "
            "coefficients within the fixed bound, so this claim has that 128-site information "
            "floor. It does not promote spatial slopes/q2 blocks, another provider, bivariate, "
            "non-Gaussian, interval/coverage, or missing-predictor REML formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining structured REML geometry.",
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 spatial "
                "location-scale intercept formula `y ~ x + spatial(1 | site, coords = coords), "
                "sigma ~ spatial(1 | site, coords = coords)`; neither endpoint is promoted "
                "alone. G2 masked-versus-observed-data equality covers fixed mu and sigma "
                "coefficients, both spatial SDs, their named cross-axis correlation, and "
                "likelihood; direct continuous-response sentinel retapes and G3 deterministic "
                "25% MCAR recovery cover the same paired block. The fixture has 128 sites and "
                "20 observations per site. The 64-site rung did not recover the cross-axis "
                "correlation within the fixed point-recovery bound, so this claim has that 128-"
                "site information floor. This does not promote either endpoint alone, slopes, "
                "another provider, q4+, bivariate, REML, interval/coverage, or missing-predictor "
                "formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0291", "mc-0292")
    },
    "mc-0300": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "the animal sigma SD, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 animal sigma-side intercept ML response-mask "
            "formula `y ~ x, sigma ~ animal(1 | id, A = A)`. The recovery fixture has 64 "
            "related IDs and 20 observations per ID. It does not promote an animal slope or "
            "q2 block, mu-side animal effects, pedigree/Ainv representations, another provider, "
            "bivariate, REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining animal geometry.",
    },
    "mc-0297": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu coefficients, the animal "
            "mu SD, residual sigma, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the univariate "
            "Gaussian unlabelled q1 animal mu intercept ML response-mask formula `y ~ x + "
            "animal(1 | id, A = A), sigma ~ 1`. The recovery fixture has 64 related IDs and "
            "20 observations per ID. It does not promote an animal slope or q2 block, sigma-"
            "side animal effects, pedigree/Ainv representations, another provider, bivariate, "
            "REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining animal geometry.",
    },
    "mc-0298": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu coefficients, both animal "
            "mu SDs, residual sigma, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the univariate "
            "Gaussian unlabelled q1 animal mu intercept-plus-slope ML response-mask formula "
            "`y ~ x + animal(1 + x | id, A = A), sigma ~ 1`. The recovery fixture has 80 "
            "related IDs and 20 observations per ID; the fixed-effect tolerance reflects one "
            "realized correlated animal field. It does not promote a labelled/q2 block, sigma-"
            "side animal effects, pedigree/Ainv representations, another provider, bivariate, "
            "REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining animal geometry.",
    },
    "mc-0299": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-response restricted-likelihood equality and direct continuous-response "
            "sentinel retapes, plus G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 animal mu intercept REML response-mask formula "
            "`y ~ x + animal(1 | id, A = A), sigma ~ 1`. The recovery fixture has 128 related "
            "IDs and 20 observations per ID. It does not promote animal slopes/q2 blocks, "
            "pedigree/Ainv representations, another provider, bivariate, non-Gaussian, interval/"
            "coverage, or missing-predictor REML formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining structured REML geometry.",
    },
    "mc-0301": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "both animal sigma SDs, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 animal sigma-side intercept-plus-slope ML "
            "response-mask formula `y ~ x, sigma ~ animal(1 + x | id, A = A)`. The recovery "
            "fixture has 64 related IDs and 20 observations per ID. It does not promote a "
            "labelled/q2 block, mu-side animal effects, pedigree/Ainv representations, another "
            "provider, bivariate, REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining animal geometry.",
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 animal "
                "location-scale intercept formula `y ~ x + animal(1 | id, A = A), sigma ~ "
                "animal(1 | id, A = A)`; neither endpoint is promoted alone. G2 masked-versus-"
                "observed-data equality covers fixed mu and sigma coefficients, both animal SDs, "
                "their named cross-axis correlation, and likelihood; direct continuous-response "
                "sentinel retapes and G3 deterministic 25% MCAR recovery cover the same paired "
                "block. The fixture has 128 related IDs and 20 observations per ID. This does "
                "not promote either endpoint alone, slopes, pedigree/Ainv representations, another "
                "provider, q4+, bivariate, REML, interval/coverage, or missing-predictor formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0303", "mc-0304")
    },
    "mc-0312": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "the relmat sigma SD, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 relmat sigma-side intercept ML response-mask "
            "formula `y ~ x, sigma ~ relmat(1 | id, K = K)`. The recovery fixture has 64 "
            "related IDs and 20 observations per ID. It does not promote a relmat slope or q2 "
            "block, mu-side relmat effects, Q representations, another provider, bivariate, "
            "REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining relmat geometry.",
    },
    "mc-0309": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu coefficients, the relmat "
            "mu SD, residual sigma, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the univariate "
            "Gaussian unlabelled q1 relmat mu intercept ML response-mask formula `y ~ x + "
            "relmat(1 | id, K = K), sigma ~ 1`. The recovery fixture has 64 related IDs and "
            "20 observations per ID. It does not promote a relmat slope or q2 block, sigma-side "
            "relmat effects, Q representations, another provider, bivariate, REML, interval/"
            "coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining relmat geometry.",
    },
    "mc-0310": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu coefficients, both relmat "
            "mu SDs, residual sigma, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the univariate "
            "Gaussian unlabelled q1 relmat mu intercept-plus-slope ML response-mask formula "
            "`y ~ x + relmat(1 + x | id, K = K), sigma ~ 1`. The recovery fixture has 80 "
            "related IDs and 20 observations per ID; the fixed-effect tolerance reflects one "
            "realized correlated relmat field. It does not promote a labelled/q2 block, sigma-"
            "side relmat effects, Q representations, another provider, bivariate, REML, "
            "interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining relmat geometry.",
    },
    "mc-0311": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-response restricted-likelihood equality and direct continuous-response "
            "sentinel retapes, plus G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 relmat mu intercept REML response-mask formula "
            "`y ~ x + relmat(1 | id, K = K), sigma ~ 1`. The recovery fixture has 128 related "
            "IDs and 20 observations per ID. It does not promote relmat slopes/q2 blocks, Q "
            "representations, another provider, bivariate, non-Gaussian, interval/coverage, or "
            "missing-predictor REML formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining structured REML geometry.",
    },
    "mc-0313": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 masked-versus-observed-data equality for fixed mu and sigma coefficients, "
            "both relmat sigma SDs, and likelihood, plus direct continuous-response sentinel "
            "retapes, and G3 deterministic 25% MCAR known-DGP recovery validate the "
            "univariate Gaussian unlabelled q1 relmat sigma-side intercept-plus-slope ML "
            "response-mask formula `y ~ x, sigma ~ relmat(1 + x | id, K = K)`. The recovery "
            "fixture has 64 related IDs and 20 observations per ID. It does not promote a "
            "labelled/q2 block, mu-side relmat effects, Q representations, another provider, "
            "bivariate, REML, interval/coverage, or missing-predictor formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining relmat geometry.",
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 relmat "
                "location-scale intercept formula `y ~ x + relmat(1 | id, K = K), sigma ~ "
                "relmat(1 | id, K = K)`; neither endpoint is promoted alone. G2 masked-versus-"
                "observed-data equality covers fixed mu and sigma coefficients, both relmat SDs, "
                "their named cross-axis correlation, and likelihood; direct continuous-response "
                "sentinel retapes and G3 deterministic 25% MCAR recovery cover the same paired "
                "block. The fixture has 128 related IDs and 20 observations per ID. This does "
                "not promote either endpoint alone, slopes, Q representations, another provider, "
                "q4+, bivariate, REML, interval/coverage, or missing-predictor formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0315", "mc-0316")
    },
    "mc-0317": {
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "replace_model_claim": True,
        "claim_boundary": (
            "The paired relmat q2 location-scale one-slope response-mask claim is not "
            "currently supported: the residual log-SD relmat slope SD is estimated at "
            "3.61e-05 against a true 0.15, a zero-boundary solution reported with "
            "convergence code 0 and no identifiability diagnostic, so the cited G3 "
            "recovery evidence is not currently produced."
        ),
        "next_gate": (
            "Add an identifiability diagnostic for the residual log-SD relmat slope "
            "and re-run G3 recovery with a fixture that clears the zero boundary "
            "before re-validating this formula cell."
        ),
    },
    "mc-0318": {
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "replace_model_claim": True,
        "claim_boundary": (
            "The paired relmat q2 location-scale one-slope response-mask claim is not "
            "currently supported: this row's sigma endpoint shares the mu endpoint's "
            "evidence, whose residual log-SD relmat slope SD is at the zero boundary "
            "(3.61e-05 against a true 0.15) under a fixture with 18 retained "
            "observations per id."
        ),
        "next_gate": (
            "Add an identifiability diagnostic for the residual log-SD relmat slope "
            "and re-run G3 recovery with a fixture that clears the zero boundary "
            "before re-validating this formula cell."
        ),
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 animal "
                "location-scale one-slope formula `y ~ x + animal(1 + x | id, A = A), sigma ~ "
                "animal(1 + x | id, A = A)`; neither endpoint is promoted alone. G2 masked-"
                "versus-observed-data equality covers fixed mu and sigma coefficients, all four "
                "named animal SDs, and likelihood; direct continuous-response sentinel retapes "
                "and G3 deterministic 25% MCAR recovery cover the same four-field block. The "
                "fixture has 64 related IDs and 24 observations per ID. The ledger's q2 label "
                "denotes the paired mu/sigma formula cell; this unlabelled formula fits four "
                "independent coefficient-level animal fields and exposes no cross-axis correlation "
                "target. This does not promote either endpoint alone, a labelled/correlated or "
                "q4+ block, pedigree/Ainv representations, another provider, bivariate, REML, "
                "interval/coverage, or missing-predictor formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0305", "mc-0306")
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 spatial "
                "location-scale one-slope formula `y ~ x + spatial(1 + x | site, coords = "
                "coords), sigma ~ spatial(1 + x | site, coords = coords)`; neither endpoint "
                "is promoted alone. G2 masked-versus-observed-data equality covers fixed mu "
                "and sigma coefficients, all four named spatial SDs, and likelihood; direct "
                "continuous-response sentinel retapes and G3 deterministic 25% MCAR recovery "
                "cover the same four-field block. The fixture has 64 sites and 24 observations "
                "per site. The ledger's q2 label denotes the paired mu/sigma formula cell; this "
                "unlabelled formula fits four independent coefficient-level spatial fields and "
                "exposes no cross-axis correlation target. This does not promote either endpoint "
                "alone, a labelled/correlated or q4+ block, another provider, bivariate, REML, "
                "interval/coverage, or missing-predictor formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0293", "mc-0294")
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 phylogenetic "
                "location-scale formula `y ~ x + phylo(1 | species, tree = tree), sigma ~ "
                "phylo(1 | species, tree = tree)`; neither endpoint is promoted alone. G2 "
                "masked-versus-observed-data equality covers fixed mu and sigma coefficients, "
                "both phylogenetic SDs, their correlation, and likelihood; direct continuous-"
                "response sentinel retapes and G3 deterministic 25% MCAR recovery cover the "
                "same paired block. The fixture has 64 tips and 20 observations per tip. This "
                "does not promote slopes, another q2 provider, q4+, bivariate, REML, intervals/"
                "coverage, or missing-predictor formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0278", "mc-0279")
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "This row is one component of the paired univariate Gaussian q2 "
                "phylogenetic location-scale one-slope formula `y ~ x + phylo(1 + x | "
                "species, tree = tree), sigma ~ phylo(1 + x | species, tree = tree)`; "
                "neither endpoint is promoted alone. G2 masked-versus-observed-data "
                "equality covers fixed mu and sigma coefficients, all four named "
                "phylogenetic SDs, and likelihood; direct continuous-response sentinel "
                "retapes and G3 deterministic 25% MCAR recovery cover the same four-field "
                "block. The fixture has 64 tips and 20 observations per tip. The ledger's "
                "q2 label denotes the paired mu/sigma formula cell; this unlabelled formula "
                "fits four independent coefficient-level phylogenetic fields and exposes no "
                "cross-axis correlation target. This does not promote either endpoint alone, "
                "a labelled/correlated or q4+ block, another provider, bivariate, REML, "
                "interval/coverage, or missing-predictor formulas."
            ),
            "next_gate": "Validate each remaining paired covariance geometry as one formula cell.",
        }
        for cell_id in ("mc-0280", "mc-0281")
    },
    "mc-0264": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data full marginal-Gaussian likelihood equality and "
            "direct sentinel retapes, plus a deterministic 25% MCAR known-DGP "
            "recovery check, validate the univariate Gaussian ordinary mu "
            "random-intercept ML response-mask formula `(1 | id)`. The check "
            "covers fixed mu coefficients, constant residual sigma, and the mu "
            "random-intercept SD. It does not promote random slopes, correlated "
            "blocks, sigma-side effects, structured, bivariate, non-Gaussian, "
            "or missing-predictor ML formulas."
        ),
        "next_gate": "Add an independent recovery design before widening this ML formula geometry.",
    },
    "mc-0268": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data full marginal-Gaussian likelihood equality and "
            "direct sentinel retapes, plus a deterministic 25% MCAR known-DGP "
            "recovery check, validate the univariate Gaussian ordinary mu "
            "random-slope ML response-mask formula `(0 + x | id)`. The check "
            "covers fixed mu coefficients, constant residual sigma, and the mu "
            "random-slope SD. It does not promote random intercepts, correlated "
            "blocks, sigma-side effects, structured, bivariate, non-Gaussian, "
            "or missing-predictor ML formulas."
        ),
        "next_gate": "Add an independent recovery design before widening this ML formula geometry.",
    },
    "mc-0265": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-row REML equality and direct sentinel retapes, plus a "
            "deterministic 25% MCAR known-DGP recovery check, validate the "
            "univariate Gaussian ordinary mu random-intercept REML response-mask "
            "formula. One fixture has constant residual sigma; a second has "
            "sigma ~ z and agrees with an independent observed-data restricted-"
            "likelihood oracle. Together they cover fixed mu coefficients, fixed "
            "sigma coefficients, and the mu random-intercept SD. They do not "
            "promote fixed-only, random-slope, sigma-random-effect, structured, "
            "bivariate, non-Gaussian, or missing-predictor REML formulas."
        ),
        "next_gate": "Add an independent recovery design before widening this REML formula geometry.",
    },
    "mc-0269": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data dense restricted-likelihood equality and direct "
            "sentinel retapes, plus a deterministic 25% MCAR known-DGP recovery "
            "check, validate the univariate Gaussian ordinary mu random-slope "
            "REML response-mask formula `(0 + x | id)`. The check covers fixed "
            "mu coefficients, constant residual sigma, and the mu random-slope "
            "SD. It does not promote random intercepts, correlated blocks, "
            "sigma-side effects, structured, bivariate, non-Gaussian, or "
            "missing-predictor REML formulas."
        ),
        "next_gate": "Add an independent recovery design before widening this REML formula geometry.",
    },
    "mc-0274": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data dense restricted-likelihood equality and direct "
            "sentinel retapes, plus a deterministic 25% MCAR known-DGP recovery "
            "check, validate the univariate Gaussian unlabelled q1 phylo mu "
            "random-intercept REML response-mask formula. The check covers fixed "
            "mu coefficients, constant residual sigma, and the phylogenetic mu "
            "SD. It does not promote phylo slopes or q2 blocks, sigma-side phylo "
            "effects, other providers, bivariate, non-Gaussian, or missing-"
            "predictor REML formulas."
        ),
        "next_gate": "Add a separate observed-response oracle and recovery design for each remaining phylo geometry.",
    },
    "mc-0429": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality, "
            "plus direct sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the Poisson univariate ordinary mu "
            "random-intercept ML response-mask formula `(1 | id)`. The check "
            "covers fixed mu coefficients, the mu random-intercept SD, and "
            "conditional random-effect recovery. It does not promote Poisson "
            "random slopes, correlated blocks, structured effects, bivariate, "
            "REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining Poisson geometry.",
    },
    "mc-0431": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality, "
            "plus direct sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the Poisson univariate ordinary mu "
            "independent random-slope ML response-mask formula `(0 + x | id)`. "
            "The check covers fixed mu coefficients, the mu random-slope SD, "
            "and conditional random-effect recovery. It does not promote "
            "correlated blocks, structured effects, "
            "bivariate, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining Poisson geometry.",
    },
    "mc-0401": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality, "
            "plus direct sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the NB2 univariate ordinary mu "
            "random-intercept ML response-mask formula `(1 | id)` with fixed "
            "sigma regression. The check covers fixed mu and sigma coefficients, "
            "the mu random-intercept SD, and conditional random-effect recovery. "
            "It does not promote NB2 mu random slopes, sigma random effects, "
            "correlated blocks, structured effects, bivariate, REML, another "
            "family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining NB2 geometry.",
    },
    "mc-0402": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality, "
            "plus direct sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the NB2 univariate ordinary mu "
            "independent random-slope ML response-mask formula `(0 + x | id)` "
            "with fixed sigma regression. The check covers fixed mu and sigma "
            "coefficients, the mu random-slope SD, and conditional slope-effect "
            "recovery. It does not promote sigma random effects, correlated "
            "blocks, structured effects, bivariate, REML, another family, or "
            "missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining NB2 geometry.",
    },
    "mc-0005": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality "
            "within the stated latent-mode numerical tolerance, plus direct "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the Beta univariate ordinary mu random-intercept ML "
            "response-mask formula `(1 | id)` with fixed sigma regression. The "
            "check covers fixed mu and sigma coefficients, the mu random-intercept "
            "SD, and conditional random-effect recovery. It does not promote Beta "
            "random slopes, sigma random effects, correlated blocks, structured "
            "effects, bivariate, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining Beta geometry.",
    },
    "mc-0007": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality "
            "within the stated latent-mode numerical tolerance, plus direct "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the Beta univariate ordinary mu independent random-slope ML "
            "response-mask formula `(0 + x | id)` with fixed sigma regression. "
            "The check covers fixed mu and sigma coefficients, the mu random-slope "
            "SD, and conditional slope-effect recovery. It does not promote sigma "
            "random effects, correlated blocks, structured effects, bivariate, "
            "REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining Beta geometry.",
    },
    "mc-0059": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality "
            "within the stated latent-mode numerical tolerance, plus direct "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the binomial-logit univariate ordinary mu random-intercept "
            "ML response-mask formula `(1 | id)`. The check covers fixed mu "
            "coefficients, the mu random-intercept SD, and conditional random-"
            "effect recovery. It does not promote binomial random slopes, "
            "correlated blocks, structured effects, bivariate, REML, another "
            "family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining binomial geometry.",
    },
    "mc-0061": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality "
            "within the stated latent-mode numerical tolerance, plus direct "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the grouped-binomial-logit univariate ordinary mu independent "
            "random-slope ML response-mask formula `(0 + x | id)`. The check uses "
            "a two-column cbind response, covers its response-row accounting, fixed "
            "mu coefficients, the mu random-slope SD, and conditional slope-effect "
            "recovery. It does not promote correlated blocks, structured effects, "
            "REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining binomial geometry.",
    },
    "mc-0227": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data parameter and likelihood equality, plus direct "
            "ordinal-sentinel retapes, and G3 deterministic 25% MCAR known-DGP "
            "recovery validate the cumulative-logit univariate ordinary mu "
            "independent random-slope ML response-mask formula `(0 + x | id)`. "
            "The check retains declared ordinal levels and covers the mu slope, "
            "random-slope SD, and conditional slope-effect recovery. It does not "
            "promote intercepts, correlated blocks, structured effects, REML, "
            "another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining cumulative-logit geometry.",
    },
    "mc-0225": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data parameter and likelihood equality, ordinal-sentinel "
            "retapes, and declared-level preservation, plus G3 deterministic 25% "
            "MCAR known-DGP recovery validate the cumulative-logit univariate ordinary "
            "mu random-intercept ML response-mask formula `(1 | id)`. The check covers "
            "the mu coefficient, random-intercept SD, and conditional random-effect "
            "recovery. It does not promote slopes beyond their separate cell, correlated "
            "or structured effects, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining cumulative-logit geometry.",
    },
    "mc-0029": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality, "
            "plus direct beta-binomial encoded-response sentinel retapes, and G3 "
            "deterministic 25% MCAR known-DGP recovery validate the beta-binomial "
            "univariate ordinary mu random-intercept ML response-mask formula "
            "`(1 | id)` with fixed sigma regression. The check covers two-column "
            "response-row accounting, fixed mu and sigma coefficients, the mu "
            "random-intercept SD, and conditional random-effect recovery. It does "
            "not promote slopes, sigma random effects, correlated blocks, structured "
            "effects, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining beta-binomial geometry.",
    },
    "mc-0031": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case likelihood and parameter equality, "
            "plus direct beta-binomial encoded-response sentinel retapes, and G3 "
            "deterministic 25% MCAR known-DGP recovery validate the beta-binomial "
            "univariate ordinary mu independent random-slope ML response-mask formula "
            "`(0 + x | id)` with fixed sigma regression. The check covers two-column "
            "response-row accounting, fixed mu and sigma coefficients, the mu random-"
            "slope SD, and conditional slope-effect recovery. It does not promote sigma "
            "random effects, correlated blocks, structured effects, REML, another "
            "family, or missing-predictor formulas."
        ),
        "next_gate": "Add an independent observed-response oracle and recovery design for each remaining beta-binomial geometry.",
    },
    "mc-0567": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": "G2 observed-data equality and sentinel retapes, plus G3 deterministic MCAR recovery, validate zero-one-beta mu random intercepts with fixed sigma, zoi, and coi regressions. This does not promote other distributional parameters, slopes, structured effects, REML, or missing predictors.",
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0575": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct zero-one-beta sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the zero-one-beta univariate ordinary mu "
            "independent random-slope ML response-mask formula `(0 + x | id)` with "
            "fixed sigma, zoi, and coi regressions. The check covers fixed mu "
            "coefficients, the mu random-slope SD, and conditional slope-effect "
            "recovery. It does not promote other distributional-parameter random "
            "effects, correlated blocks, structured effects, REML, another family, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0539": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct Tweedie zero and positive-response sentinel retapes, and G3 "
            "deterministic 25% MCAR known-DGP recovery validate the Tweedie "
            "univariate ordinary mu independent random-slope ML response-mask formula "
            "`(0 + x | id)` with fixed sigma and nu regressions. The check covers fixed "
            "mu, sigma, and nu coefficients, the mu random-slope SD, and conditional "
            "slope-effect recovery. It does not promote sigma or nu random effects, "
            "correlated blocks, structured effects, REML, another family, or missing-"
            "predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Tweedie parameter geometry.",
    },
    "mc-0240": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct positive-response sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the Gamma univariate ordinary mu random-"
            "intercept ML response-mask formula `(1 | id)` with fixed sigma regression. "
            "The check covers fixed mu and sigma coefficients, the mu random-intercept "
            "SD, and conditional random-effect recovery. It does not promote slopes, "
            "sigma random effects, correlated blocks, structured effects, REML, another "
            "family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gamma parameter geometry.",
    },
    "mc-0378": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct positive-response sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the lognormal univariate ordinary mu random-"
            "intercept ML response-mask formula `(1 | id)` with fixed sigma regression. "
            "The check covers fixed mu and sigma coefficients, the mu random-intercept "
            "SD, and conditional random-effect recovery. It does not promote slopes, "
            "sigma random effects, correlated blocks, structured effects, REML, another "
            "family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining lognormal parameter geometry.",
    },
    "mc-0487": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct response sentinel retapes, and G3 deterministic 25% MCAR known-DGP "
            "recovery validate the Student univariate ordinary mu random-intercept ML "
            "response-mask formula `(1 | id)` with fixed sigma and nu regressions. The "
            "check covers fixed mu, sigma, and nu coefficients, the mu random-intercept "
            "SD, and conditional random-effect recovery. It does not promote slopes, "
            "sigma or nu random effects, correlated blocks, structured effects, REML, "
            "another family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Student parameter geometry.",
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "G2 observed-data complete-case parameter and likelihood equality, plus "
                "direct response-sentinel retapes, and G3 deterministic 25% MCAR known-"
                "DGP recovery validate the univariate ordinary mu independent random-"
                "slope ML response-mask formula `(0 + x | id)` with fixed distributional-"
                "parameter regressions. The check covers fixed coefficients, the mu random-"
                "slope SD, and conditional slope-effect recovery. It does not promote other "
                "random distributional parameters, correlated blocks, structured effects, "
                "REML, another family, or missing-predictor formulas."
            ),
            "next_gate": "Add formula-specific evidence for every remaining ordinary continuous-family geometry.",
        }
        for cell_id in ("mc-0244", "mc-0380", "mc-0488")
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "G2 observed-data complete-case parameter and likelihood equality, "
                "with direct zero and positive-response sentinel retapes, plus G3 "
                "deterministic 25% MCAR recovery validate this fixed-effect count-mixture "
                "ML response-mask formula. Separate masked-zero and masked-positive tests "
                "exercise the mixture path. The check covers every fixed distributional "
                "parameter exposed by the formula. It does not promote random or structured "
                "effects, REML, another family, or missing-predictor formulas."
            ),
            "next_gate": "Add formula-specific evidence for each admitted count-mixture effect geometry.",
        }
        for cell_id in (
            "mc-0657", "mc-0663",  # ZIP: mu, zi
            "mc-0623", "mc-0625", "mc-0627",  # ZINB2: mu, sigma, zi
            "mc-0326", "mc-0342", "mc-0358",  # hurdle NB2: mu, sigma, hu
        )
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "G2 partial-response bivariate-Gaussian likelihood equality and "
                "component-wise sentinel retapes, plus G3 deterministic 25% MCAR recovery, "
                "validate this fixed-effect ML response-mask formula. The recovery fixture "
                "has over 800 complete pairs and separately recovers both endpoint location "
                "and scale parameters and rho12. It does not promote random or structured "
                "effects, dense known-V partial responses, REML, another family, or missing-"
                "predictor formulas."
            ),
            "next_gate": "Add formula-specific evidence for each admitted bivariate effect geometry.",
        }
        for cell_id in ("mc-0177", "mc-0178", "mc-0179", "mc-0180", "mc-0181")
    },
    **{
        cell_id: {
            "formula_status": "formula_validated",
            "formula_mask_gate": "G3",
            "claim_boundary": (
                "G2 observed-data complete-case parameter and likelihood equality, with "
                "direct support-valid response-sentinel retapes, plus G3 deterministic 25% "
                "MCAR known-DGP recovery validate this fixed-effect univariate ML response-"
                "mask formula. The check covers every fixed distributional parameter exposed "
                "by the formula. It does not promote random or structured effects, bivariate "
                "formulas, REML, another family, or missing-predictor formulas."
            ),
            "next_gate": "Add formula-specific evidence for each admitted non-fixed effect geometry.",
        }
        for cell_id in (
            "mc-0001", "mc-0003",  # beta
            "mc-0025", "mc-0027",  # beta-binomial
            "mc-0057",              # binomial
            "mc-0223",              # cumulative logit
            "mc-0236", "mc-0238",  # Gamma
            "mc-0260", "mc-0262",  # Gaussian
            "mc-0374", "mc-0376",  # lognormal
            "mc-0397", "mc-0398",  # NB2
            "mc-0427",              # Poisson
            "mc-0456", "mc-0458", "mc-0460",  # skew-normal
            "mc-0484", "mc-0485", "mc-0486",  # Student
            "mc-0508", "mc-0509",  # truncated NB2
            "mc-0531", "mc-0533", "mc-0535",  # Tweedie
            "mc-0559", "mc-0560", "mc-0561", "mc-0562",  # zero-one-beta
        )
    },
    "mc-0403": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct count-response sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the NB2 univariate ordinary sigma random-"
            "intercept ML response-mask formula `(1 | id)` with a fixed mu regression. "
            "The check covers fixed mu and sigma coefficients, the sigma random-intercept "
            "SD, and conditional random-effect recovery. It does not promote sigma slopes, "
            "mu random effects, correlated blocks, structured effects, REML, another family, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 parameter geometry.",
    },
    "mc-0382": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct positive-response sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the lognormal univariate ordinary sigma random-"
            "intercept ML response-mask formula `(1 | id)` with a fixed mu regression. "
            "The check covers fixed mu and sigma coefficients, the sigma random-intercept "
            "SD, and conditional random-effect recovery. It does not promote sigma slopes, "
            "mu random effects, correlated blocks, structured effects, REML, another family, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining lognormal parameter geometry.",
    },
    "mc-0242": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus "
            "direct positive-response sentinel retapes, and G3 deterministic 25% MCAR "
            "known-DGP recovery validate the Gamma univariate ordinary sigma random-"
            "intercept ML response-mask formula `(1 | id)` with a fixed mu regression. "
            "The check covers fixed mu and sigma coefficients, the sigma random-intercept "
            "SD, and conditional random-effect recovery. It does not promote sigma slopes, "
            "mu random effects, correlated blocks, structured effects, REML, another family, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gamma parameter geometry.",
    },
    "mc-0267": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-row REML parameter and likelihood equality, plus direct response "
            "sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery validate "
            "the Gaussian univariate ordinary sigma random-intercept REML response-mask "
            "formula `(1 | group)` with a fixed mu regression. The check covers fixed mu "
            "and sigma coefficients, the sigma random-intercept SD, and conditional random-"
            "effect recovery. It does not promote sigma slopes, mu random effects, correlated "
            "or structured effects, bivariate formulas, another family, or missing predictors."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gaussian REML effect geometry.",
    },
    "mc-0060": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-row REML parameter and likelihood equality, plus direct binary "
            "response-sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the binomial univariate ordinary mu random-intercept REML response-"
            "mask formula `(1 | id)`. The check covers fixed mu coefficients, the mu random-"
            "intercept SD, and conditional random-effect recovery. It does not promote slopes, "
            "correlated or structured effects, other binomial REML formulas, another family, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for the remaining admitted binomial REML geometry.",
    },
    "mc-0062": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-row REML parameter and likelihood equality, plus direct grouped-"
            "binomial response-sentinel retapes, and G3 deterministic 25% MCAR known-DGP "
            "recovery validate the binomial univariate ordinary mu independent random-slope "
            "REML response-mask formula `(0 + x | id)`. The check covers fixed mu "
            "coefficients, the mu random-slope SD, and conditional slope-effect recovery. "
            "It does not promote correlated or structured effects, other binomial REML "
            "formulas, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for each remaining binomial REML geometry.",
    },
    "mc-0568": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus direct "
            "zero-one-beta response-sentinel retapes, and G3 deterministic 25% MCAR known-"
            "DGP recovery validate the zero-one-beta univariate ordinary sigma random-"
            "intercept ML response-mask formula `(1 | id)` with fixed mu, zoi, and coi "
            "regressions. The check covers the sigma random-intercept SD and conditional "
            "random-effect recovery. It does not promote sigma slopes, mu/zoi/coi random "
            "effects, correlated blocks, structured effects, REML, another family, or missing predictors."
        ),
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0569": {
        "formula_status": "formula_validated", "formula_mask_gate": "G3",
        "claim_boundary": "G2 observed-data equality and sentinel retapes, plus G3 deterministic MCAR recovery, validate zero-one-beta zoi random intercepts with fixed mu, sigma, and coi formulas. This does not promote zoi slopes, other random effects, structured effects, REML, or missing predictors.",
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0570": {
        "formula_status": "formula_validated", "formula_mask_gate": "G3",
        "claim_boundary": "G2 observed-data equality and sentinel retapes, plus G3 deterministic MCAR recovery, validate zero-one-beta coi random intercepts with fixed mu, sigma, and zoi formulas. This does not promote coi slopes, other random effects, structured effects, REML, or missing predictors.",
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0578": {
        "formula_status": "needs_formula_evidence", "formula_mask_gate": "G1", "replace_model_claim": True,
        "claim_boundary": "The zero-one-beta coi independent random-slope response-mask claim is not currently supported: the coi random-slope SD is estimated at 2.27e-04 against a true 0.45 with a slope-effect correlation of 0.253 against a 0.35 bound, a zero-boundary solution driven by roughly six atom observations per group in the cited fixture.",
        "next_gate": "Redesign the fixture for more atom observations per group (the current ~6-per-group density under-identifies the coi random slope) and re-run G3 recovery before re-validating this formula cell.",
    },
    "mc-0577": {
        "formula_status": "formula_validated", "formula_mask_gate": "G3",
        "claim_boundary": "G2 observed-data equality and sentinel retapes, plus G3 deterministic MCAR recovery, validate zero-one-beta zoi independent random slopes with fixed mu, sigma, and coi formulas. This does not promote zoi intercepts beyond their separate cell, other random effects, structured effects, REML, or missing predictors.",
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0576": {
        "formula_status": "formula_validated", "formula_mask_gate": "G3",
        "claim_boundary": "G2 observed-data equality and sentinel retapes, plus G3 deterministic MCAR recovery, validate zero-one-beta sigma independent random slopes with fixed mu, zoi, and coi formulas. This does not promote sigma intercepts beyond their separate cell, other random effects, structured effects, REML, or missing predictors.",
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
    },
    "mc-0510": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus direct "
            "positive-count response-sentinel retapes, and G3 deterministic 25% MCAR known-"
            "DGP recovery validate the truncated-NB2 univariate ordinary mu random-intercept "
            "ML response-mask formula `(1 | id)` with fixed sigma regression. The check covers "
            "fixed mu and sigma coefficients, the mu random-intercept SD, and conditional "
            "random-effect recovery. It does not promote slopes, correlated or structured "
            "effects, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining truncated-NB2 geometry.",
    },
    "mc-0511": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus direct "
            "positive-count response-sentinel retapes, and G3 deterministic 25% MCAR known-"
            "DGP recovery validate the truncated-NB2 univariate ordinary mu independent random-"
            "slope ML response-mask formula `(0 + x | id)` with fixed sigma regression. The "
            "check covers the mu slope, fixed sigma coefficients, the mu random-slope SD, and "
            "conditional random-effect recovery. It does not promote intercepts beyond their "
            "separate cell, correlated or structured effects, REML, another family, or missing-"
            "predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining truncated-NB2 geometry.",
    },
    "mc-0266": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-row ML parameter and likelihood equality, plus direct Gaussian "
            "response-sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the Gaussian univariate ordinary sigma random-intercept ML response-mask "
            "formula `(1 | group)`. The check covers fixed mu and sigma coefficients, the sigma "
            "random-intercept SD, and conditional random-effect recovery. It does not promote "
            "slopes, correlated or structured effects, REML, bivariate formulas, or missing-"
            "predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gaussian ML geometry.",
    },
    "mc-0270": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-row ML parameter and likelihood equality, plus direct Gaussian "
            "response-sentinel retapes, and G3 deterministic 25% MCAR known-DGP recovery "
            "validate the Gaussian univariate ordinary sigma independent random-slope ML "
            "response-mask formula `(0 + w | group)`. The check covers fixed mu and sigma "
            "coefficients, the sigma random-slope SD, and conditional random-effect recovery. "
            "It does not promote intercepts beyond their separate cell, correlated or structured "
            "effects, REML, bivariate formulas, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gaussian ML geometry.",
    },
    "mc-0463": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus direct "
            "continuous-response sentinel retapes, and G3 deterministic 25% MCAR known-DGP "
            "recovery validate the skew-normal univariate ordinary mu random-intercept ML "
            "response-mask formula `(1 | id)` with fixed sigma and nu regressions. The check "
            "covers fixed mu, sigma, and nu coefficients, the mu random-intercept SD, and "
            "conditional random-effect recovery. It does not promote slopes, correlated or "
            "structured effects, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining skew-normal geometry.",
    },
    "mc-0464": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus direct "
            "continuous-response sentinel retapes, and G3 deterministic 25% MCAR known-DGP "
            "recovery validate the skew-normal univariate ordinary mu independent random-slope "
            "ML response-mask formula `(0 + x | id)` with fixed sigma and nu regressions. "
            "The check covers fixed mu, sigma, and nu coefficients, the mu random-slope SD, "
            "and conditional random-slope recovery. It does not promote intercepts beyond "
            "their separate cell, correlated or structured effects, REML, another family, "
            "or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining skew-normal geometry.",
    },
    "mc-0538": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "claim_boundary": (
            "G2 observed-data complete-case parameter and likelihood equality, plus direct "
            "zero/positive response-sentinel retapes, and G3 deterministic 25% MCAR known-DGP "
            "recovery validate the Tweedie univariate ordinary mu random-intercept ML response-"
            "mask formula `(1 | id)` with fixed sigma and nu regressions. The check covers fixed "
            "mu, sigma, and nu coefficients, the mu random-intercept SD, and conditional random-"
            "effect recovery. It does not promote slopes beyond their separate cell, correlated "
            "or structured effects, REML, another family, or missing-predictor formulas."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Tweedie geometry.",
    },
    "mc-0017": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct beta-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact beta phylogenetic direct-SD ML formula "
            "`y ~ x_mu + phylo(1 | species, tree = tree)`, `sigma ~ x_sigma`, "
            "`sd(species, level = \"phylogenetic\") ~ z_species`. The check covers fixed "
            "mu and sigma coefficients and both direct latent-SD regression coefficients "
            "on a 96-tip, 12-observation-per-tip fixture with one masked response per tip. "
            "It does not promote q2+, labels, slopes, family-sigma phylogeny, ordinary "
            "random effects, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining beta structured geometry.",
    },
    "mc-0229": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional ordinal TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct ordinal-category sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact cumulative-logit ML formula `score ~ x + "
            "phylo(1 | species, tree = tree)`. The check covers the fixed location coefficient, "
            "both ordered cutpoints, and the phylogenetic SD on a 96-tip, 16-observation-per-"
            "tip star-tree fixture with one masked response per tip. This is not q2+, slopes, "
            "ordinary random effects, another ordinal endpoint, REML, missing predictors, "
            "intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining cumulative-logit geometry.",
    },
    "mc-0388": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 observed-row equality, direct positive-response sentinel retapes, and the "
            "lognormal-to-Gaussian transformed-response comparator, including its Jacobian "
            "and q1 relatedness field, plus G3 deterministic known-DGP recovery, validate "
            "the exact lognormal ML formula `y ~ x + relmat(1 | id, K = K)`, `sigma ~ 1`. "
            "The check covers fixed location and log-scale terms and the relatedness SD on a "
            "64-level, 16-observation-per-level fixture with one masked response per level. "
            "It does not promote phylo(), slopes, q2+, labels, structured sigma, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining lognormal structured geometry.",
    },
    "mc-0386": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 observed-row equality, direct positive-response sentinel retapes, and the "
            "lognormal-to-Gaussian transformed-response comparator, including its Jacobian "
            "and q1 phylogenetic field, plus G3 deterministic known-DGP recovery, validate "
            "the exact lognormal ML formula `y ~ x + phylo(1 | species, tree = tree)`, "
            "`sigma ~ 1`. The check covers fixed location and log-scale terms and the "
            "phylogenetic SD on a 64-tip, 16-observation-per-tip fixture with one masked "
            "response per tip. It does not promote relmat(), slopes, q2+, labels, structured "
            "sigma, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining lognormal structured geometry.",
    },
    "mc-0248": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Gamma TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct positive-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Gamma ML formula `y ~ x + relmat(1 | id, "
            "K = K)`, `sigma ~ 1`. The check covers fixed location and log-scale terms and the "
            "relatedness SD on a 64-level, 16-observation-per-level fixture with one masked "
            "response per level. It does not promote phylo(), slopes, q2+, labels, structured "
            "sigma, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gamma structured geometry.",
    },
    "mc-0251": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Gamma TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct positive-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Gamma ML formula `y ~ x + phylo(1 | species, "
            "tree = tree)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 tips, 16 "
            "observations per tip, and one masked response per tip; it checks the fixed slope, "
            "the uncentred-field intercept at its wider conditional tolerance, log-scale, and "
            "phylogenetic SD. It does not promote relmat(), slopes, q2+, labels, structured "
            "sigma, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Gamma structured geometry.",
    },
    "mc-0434": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `count ~ x + phylo(1 | "
            "species, tree = tree)`. The larger non-Gaussian fixture has 128 tips, 16 "
            "observations per tip, and one masked response per tip; it checks the fixed slope, "
            "the uncentred-field intercept at its wider conditional tolerance, and the "
            "phylogenetic SD. It does not promote the q1 slope, q2+, other providers, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0440": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_spatial ~ x + "
            "spatial(1 | site, coords = coords)`. The larger non-Gaussian fixture has 128 "
            "sites, 16 observations per site, and one masked response per site; it checks the "
            "fixed slope, the uncentred-field intercept at its wider conditional tolerance, and "
            "the spatial SD. It does not promote the q1 slope, q2+, other providers, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0447": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_known ~ x + "
            "animal(1 | id, Ainv = Q)`. The larger non-Gaussian fixture has 128 IDs, 16 "
            "observations per ID, one masked response per ID, and a seed distinct from relmat. "
            "It checks the fixed slope, the uncentred-field intercept at its wider conditional "
            "tolerance, and the animal SD. It does not promote the q1 slope, q2+, other "
            "providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0451": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_known ~ x + "
            "relmat(1 | id, Q = Q)`. The larger non-Gaussian fixture has 128 IDs, 16 "
            "observations per ID, one masked response per ID, and a seed distinct from animal. "
            "It checks the fixed slope, the uncentred-field intercept at its wider conditional "
            "tolerance, and the relatedness SD. It does not promote the q1 slope, q2+, other "
            "providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0441": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_spatial ~ x + "
            "spatial(0 + x | site, coords = coords)`. The larger non-Gaussian fixture has 128 "
            "sites, 16 observations per site, and one masked response per site; it checks the "
            "fixed intercept and slope and the spatial slope SD. It does not promote the q1 "
            "intercept, q2+, other providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0406": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-"
            "DGP recovery, validate the exact NB2 ML formula `nb2_spatial ~ x + spatial(1 | site, "
            "coords = coords)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 sites, 16 "
            "observations per site, and one masked response per site; it checks fixed effects, "
            "NB2 log-scale, and the spatial SD. It does not promote slopes, q2+, other providers, "
            "REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0407": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-"
            "DGP recovery, validate the exact NB2 ML formula `nb2_known ~ x + animal(1 | id, "
            "Ainv = Q)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 IDs, 16 observations "
            "per ID, one masked response per ID, and a seed distinct from relmat; it checks fixed "
            "effects, NB2 log-scale, and the animal SD. It does not promote slopes, q2+, other "
            "providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0408": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-"
            "DGP recovery, validate the exact NB2 ML formula `nb2_known ~ x + relmat(1 | id, "
            "Q = Q)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 IDs, 16 observations "
            "per ID, one masked response per ID, and a seed distinct from animal; it checks fixed "
            "effects, NB2 log-scale, and the relatedness SD. It does not promote slopes, q2+, other "
            "providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0405": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-"
            "DGP recovery, validate the exact NB2 ML formula `nb2_phylo ~ x + phylo(1 | site, "
            "tree = tree)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 tips, 16 "
            "observations per tip, one masked response per tip, and a data-generating phylogenetic "
            "intercept only. It checks fixed effects, NB2 log-sigma, and the phylogenetic SD. It "
            "does not promote slopes, q2+, other providers, REML, missing predictors, intervals, "
            "or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0410": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-"
            "DGP recovery, validate the exact NB2 ML formula `nb2_phylo ~ x + phylo(1 + x | "
            "site, tree = tree)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 tips, 16 "
            "observations per tip, and one masked response per tip; it checks fixed effects, NB2 "
            "log-sigma, and the independent phylogenetic intercept and slope SDs. It does not "
            "promote labelled q2 correlation, other providers, REML, missing predictors, intervals, "
            "or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0411": {
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "replace_model_claim": True,
        "claim_boundary": (
            "The NB2 spatial structured q1 intercept-slope response-mask claim is not currently "
            "supported: on the cited seed the residual log-sigma recovery misses at 0.29 against "
            "a 0.18 bound and the mu slope at 0.49 against a 0.20 bound; three independent reseeds "
            "also miss the sigma bound, with mixed sign (+0.29, -0.51, -0.20), which rules out a "
            "directional defect but does not establish the claim."
        ),
        "next_gate": "A >=20-seed replicated run reporting the exceedance fraction and an MCSE.",
    },
    "mc-0412": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-"
            "DGP recovery, validate the exact NB2 ML formula `nb2_known ~ x + animal(1 + x | id, "
            "Ainv = Q)`, `sigma ~ 1`. The larger non-Gaussian fixture has 128 IDs, 16 observations "
            "per ID, and one masked response per ID; it checks fixed effects, NB2 log-sigma, and the "
            "independent animal intercept and slope SDs. It does not promote labelled q2 correlation, "
            "other providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0413": {
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "replace_model_claim": True,
        "claim_boundary": (
            "The NB2 relmat structured q1 intercept-slope response-mask claim is not currently "
            "supported: the cited seed misses the residual log-sigma bound at 0.50 against 0.18, "
            "although two independent reseeds pass comfortably (0.12, 0.09), indicating an outlier "
            "committed seed rather than a systematic defect; the claim is withdrawn because the "
            "evidence it cites does not reproduce, not because the formula is wrong."
        ),
        "next_gate": (
            "Re-run recovery on a fresh committed seed (or a short multi-seed batch) and confirm "
            "the residual log-sigma bound clears before re-promoting; the two passing reseeds are "
            "supporting, not sufficient, evidence."
        ),
    },
    "mc-0418": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional NB2 phylogenetic covariance-objective and numerical-gradient "
            "equality, observed-row fit equality, and direct count-response sentinel retapes, plus "
            "G3 deterministic known-DGP recovery, validate the exact NB2 ML formula `nb2_phylo ~ "
            "x + phylo(1 + x | p | site, tree = tree)`, `sigma ~ 1`. The larger non-Gaussian "
            "fixture has 128 tips, 16 observations per tip, one masked response per tip, two "
            "phylogenetic SDs, and a true labelled intercept-slope correlation of 0.35. It checks "
            "fixed effects, NB2 log-sigma, both SDs, and the named correlation. It does not promote "
            "q1, unlabelled terms, other providers, q4+, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0409": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional NB2 phylogenetic-interaction objective and numerical-gradient "
            "equality, observed-row fit equality, and direct count-response sentinel retapes, plus "
            "G3 deterministic known-DGP recovery, validate the exact NB2 ML formula `nb2 ~ x + "
            "phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`, "
            "`sigma ~ 1`. The larger non-Gaussian fixture has 8 plant by 8 pollinator tips, 64 "
            "pairs, 64 observations per pair, and one masked response per pair. It checks fixed "
            "effects, NB2 log-sigma, and phylogenetic-interaction SD. It does not promote sigma-side "
            "interaction, other effect geometries, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0421": {
        "formula_status": "needs_formula_evidence",
        "formula_mask_gate": "G1",
        "replace_model_claim": True,
        "claim_boundary": (
            "The NB2 phylo log-sigma response-mask claim is not currently supported: "
            "the fixed log-sigma intercept lands 0.214 from truth against the cited "
            "0.200 bound on a single deterministic draw, and the evidence carries no "
            "Monte Carlo error, so the recovery claim is not currently reproduced."
        ),
        "next_gate": "Add a multi-seed Monte Carlo recovery campaign for this fixture (the current evidence is a single deterministic draw) and re-run G3 before re-validating this formula cell.",
    },
    "mc-0422": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 log-sigma TMB-objective and numerical-gradient equality, observed-"
            "row fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact NB2 ML formula `y ~ x`, `sigma ~ spatial(1 + x "
            "| site, coords = coords)`. The larger non-Gaussian fixture has 128 sites, 32 observations "
            "per site, one masked response per site, and nonzero spatial log-sigma intercept and slope "
            "fields. It checks fixed location, fixed log-sigma, and both sigma-side spatial SDs. It "
            "does not promote location-side structured effects, other providers, labelled covariance, "
            "REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0423": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 log-sigma TMB-objective and numerical-gradient equality, observed-"
            "row fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact NB2 ML formula `y ~ x`, `sigma ~ animal(1 + x "
            "| id, Ainv = Q)`. The larger non-Gaussian fixture has 128 IDs, 32 observations per ID, "
            "one masked response per ID, and nonzero animal log-sigma intercept and slope fields. "
            "It checks fixed location, fixed log-sigma, and both sigma-side animal SDs. It does not "
            "promote location-side structured effects, other providers, labelled covariance, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0424": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 log-sigma TMB-objective and numerical-gradient equality, observed-"
            "row fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact NB2 ML formula `y ~ x`, `sigma ~ relmat(1 + x "
            "| id, Q = Q)`. The larger non-Gaussian fixture has 128 IDs, 32 observations per ID, "
            "one masked response per ID, and nonzero relatedness log-sigma intercept and slope fields. "
            "It checks fixed location, fixed log-sigma, and both sigma-side relatedness SDs. It does "
            "not promote location-side structured effects, other providers, labelled covariance, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0425": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional NB2 phylogenetic-interaction log-sigma objective and numerical-"
            "gradient equality, observed-row fit equality, and direct count-response sentinel retapes, "
            "plus G3 deterministic known-DGP recovery, validate the exact NB2 ML formula `nb2 ~ x`, "
            "`sigma ~ phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`. "
            "The larger non-Gaussian fixture has 8 plant by 8 pollinator tips, 64 pairs, 64 observations "
            "per pair, and one masked response per pair. It checks fixed location, fixed log-sigma, and "
            "the sigma-side interaction SD. It does not promote location-side interaction, other effect "
            "geometries, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0435": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-DGP "
            "recovery, validate the exact Poisson ML formula `poisson_phylo ~ x + phylo(1 + x | site, "
            "tree = tree)`. The larger non-Gaussian fixture has 128 tips, 64 observations per tip, "
            "one masked response per tip, and independent phylogenetic intercept and slope fields. It "
            "checks fixed effects and both phylogenetic SDs. It does not promote q1 intercept-only, "
            "labelled q2 correlation, other providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0448": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-DGP "
            "recovery, validate the exact Poisson ML formula `poisson_known ~ x + animal(1 + x | id, "
            "Ainv = Q)`. The larger non-Gaussian fixture has 128 IDs, 64 observations per ID, one "
            "masked response per ID, and independent animal intercept and slope fields. It checks fixed "
            "effects and both animal SDs. It does not promote q1 intercept-only, labelled q2 correlation, "
            "other providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0452": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality, observed-row fit "
            "equality, and direct count-response sentinel retapes, plus G3 deterministic known-DGP "
            "recovery, validate the exact Poisson ML formula `poisson_known ~ x + relmat(1 + x | id, "
            "Q = Q)`. The larger non-Gaussian fixture has 128 IDs, 64 observations per ID, one masked "
            "response per ID, and independent relatedness intercept and slope fields. It checks fixed "
            "effects and both relatedness SDs. It does not promote q1 intercept-only, labelled q2 correlation, "
            "other providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0436": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional Poisson phylogenetic covariance-objective and numerical-gradient "
            "equality, observed-row fit equality, and direct count-response sentinel retapes, plus G3 "
            "deterministic known-DGP recovery, validate the exact Poisson ML formula `poisson_phylo ~ "
            "x + phylo(1 + x | p | site, tree = tree)`. The larger non-Gaussian fixture has 128 tips, "
            "64 observations per tip, one masked response per tip, two phylogenetic SDs, and a true "
            "labelled intercept-slope correlation of 0.35. It checks fixed effects, both SDs, and the "
            "named correlation. It does not promote q1, unlabelled terms, other providers, q4+, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0446": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional Poisson spatial covariance-objective and numerical-gradient equality, "
            "observed-row fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_spatial ~ x + spatial(1 + "
            "x | p | site, coords = coords)`. The larger non-Gaussian fixture has 128 sites, 64 observations "
            "per site, one masked response per site, two spatial SDs, and a true labelled intercept-slope "
            "correlation of 0.35. It checks fixed effects, both SDs, and the named correlation. It does not "
            "promote q1, unlabelled terms, other providers, q4+, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0450": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional Poisson animal covariance-objective and numerical-gradient equality, "
            "observed-row fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_known ~ x + animal(1 + x "
            "| p | id, Ainv = Q)`. The larger non-Gaussian fixture has 128 IDs, 64 observations per ID, "
            "one masked response per ID, two animal SDs, and a true labelled intercept-slope correlation "
            "of 0.35. It checks fixed effects, both SDs, and the named correlation. It does not promote q1, "
            "unlabelled terms, other providers, q4+, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0454": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional Poisson relatedness covariance-objective and numerical-gradient equality, "
            "observed-row fit equality, and direct count-response sentinel retapes, plus G3 deterministic "
            "known-DGP recovery, validate the exact Poisson ML formula `poisson_known ~ x + relmat(1 + x "
            "| p | id, Q = Q)`. The larger non-Gaussian fixture has 128 IDs, 64 observations per ID, one "
            "masked response per ID, two relatedness SDs, and a true labelled intercept-slope correlation "
            "of 0.35. It checks fixed effects, both SDs, and the named correlation. It does not promote q1, "
            "unlabelled terms, other providers, q4+, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0438": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional Poisson phylogenetic-interaction objective and numerical-gradient "
            "equality, observed-row fit equality, and direct count-response sentinel retapes, plus G3 "
            "deterministic known-DGP recovery, validate the exact Poisson ML formula `count ~ x + "
            "phylo_interaction(1 | plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)`. "
            "The larger non-Gaussian fixture has 8 plant by 8 pollinator tips, 64 pairs, 64 observations "
            "per pair, and one masked response per pair. It checks fixed effects and the phylogenetic-"
            "interaction SD. It does not promote interaction slopes, other effect geometries, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0443": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson spatial TMB-objective and numerical-gradient equality, observed-row "
            "fit equality, and direct count-response sentinel retapes, plus G3 deterministic known-DGP "
            "recovery, validate the exact Poisson ML formula `poisson_spatial ~ x + spatial(1 | p | site, "
            "coords = coords)`. The larger non-Gaussian fixture has 128 sites, 64 observations per site, "
            "and one masked response per site. It checks the fixed slope, the conditional intercept against "
            "the realised spatial-field mean, and spatial SD. It does not promote unlabelled q1, labelled "
            "one-slope or q2 covariance, other providers, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0442": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "This inventory row duplicates the exact admitted Poisson ML syntax already validated for "
            "mc-0441: `poisson_spatial ~ x + spatial(0 + x | site, coords = coords)`. G2 conditional "
            "Poisson TMB-objective and numerical-gradient equality, observed-row fit equality, and direct "
            "count-response sentinel retapes, plus G3 deterministic known-DGP recovery, therefore apply "
            "to this duplicate formula cell as well. The fixture has 128 sites, 16 observations per site, "
            "and one masked response per site; it checks fixed effects and the spatial slope SD. It does "
            "not promote intercept fields, labels, q2+, other providers, REML, missing predictors, intervals, "
            "or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0445": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Poisson TMB-objective and numerical-gradient equality across the "
            "ordinary and spatial latent blocks, observed-row fit equality, and direct count-"
            "response sentinel retapes, plus G3 deterministic known-DGP recovery, validate the "
            "exact Poisson ML formula `y ~ x + spatial(1 | site, coords = coords) + (1 | id)`. "
            "The larger non-Gaussian fixture has 64 sites, 256 IDs, four IDs per site, 64 "
            "observations per ID, and one masked response per ID. It checks the fixed slope, "
            "the conditional intercept against both realised-field means, and both the ordinary "
            "and spatial SDs. It does not promote another combined geometry, slopes, labelled "
            "covariance, another provider, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Poisson structured geometry.",
    },
    "mc-0417": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional NB2 TMB-objective and numerical-gradient equality across both "
            "structured precision blocks, observed-row fit equality, and direct count-response "
            "sentinel retapes, plus G3 deterministic known-DGP recovery, validate the bound "
            "spatial-plus-relatedness ML formula `y ~ x + spatial(1 | site, coords = coords) + "
            "relmat(1 | id, Q = Q)`, `sigma ~ 1`. The response-mask fixture keeps the established "
            "well-conditioned crossed 20-site by 24-ID structure but raises replication to 20 "
            "observations per pair (9,600 rows), with one masked response per ID. It checks fixed "
            "location, NB2 log-scale, and both structured SDs. This aggregate inventory cell remains "
            "bound only to spatial+relmat; it does not promote the other provider pairs, slopes, "
            "labelled covariance, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining NB2 structured geometry.",
    },
    "mc-0013": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Beta TMB-objective and numerical-gradient equality across both "
            "animal location-field priors, observed-row fit equality, and direct interior-response "
            "sentinel retapes, plus G3 deterministic known-DGP recovery, validate the exact ML "
            "formula `y ~ x + animal(1 + x | id, pedigree = pedigree)`, `sigma ~ 1`. The larger "
            "non-Gaussian fixture has a 40-individual three-generation pedigree, 40 observations "
            "per individual, and one masked response per individual. It checks the fixed slope, "
            "fixed log-scale, and both animal location SDs. It does not promote intercept-only "
            "animal mu, sigma-side animal effects, another provider, labelled covariance, REML, "
            "missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Beta structured geometry.",
    },
    "mc-0015": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Beta TMB-objective and numerical-gradient equality for the animal "
            "log-scale field, observed-row fit equality, and direct interior-response sentinel "
            "retapes, plus G3 deterministic known-DGP recovery, validate the exact ML formula "
            "`y ~ x`, `sigma ~ animal(1 | id, pedigree = pedigree)`. The larger non-Gaussian "
            "fixture has a 40-individual three-generation pedigree, 60 observations per individual, "
            "and one masked response per individual. It checks fixed location, fixed log-scale, "
            "and the animal scale SD. It does not promote animal location effects, another provider, "
            "slopes, labelled covariance, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Beta structured geometry.",
    },
    "mc-0012": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional Beta TMB-objective and numerical-gradient equality for the animal "
            "location field, observed-row fit equality, and direct interior-response sentinel "
            "retapes, plus G3 deterministic known-DGP recovery, validate the exact ML formula "
            "`y ~ x + animal(1 | id, pedigree = pedigree)`, `sigma ~ 1`. The larger non-Gaussian "
            "fixture has a 40-individual three-generation pedigree, 60 observations per individual, "
            "and one masked response per individual. It checks the fixed slope, fixed log-scale, "
            "and the animal location SD. It does not promote the intercept-plus-slope or sigma-side "
            "animal formulas, another provider, labelled covariance, REML, missing predictors, "
            "intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining Beta structured geometry.",
    },
    # -- Pass 2 (2026-08-14): zi_nbinom2/zi_poisson spatial mu/zi and gaussian/
    # zi_nbinom2 phylo_interaction mu/sigma promotions. See check-log.md for the
    # session-level verification that backs these five entries.
    "mc-0641": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional zi_nbinom2 TMB-objective and numerical-gradient equality "
            "against an INDEPENDENT hand-rolled `zi_dense_spatial_precision()` oracle, "
            "re-derived from the exponential kernel / median-distance / 1e-6 jitter "
            "construction rather than read from `fit$model$tmb_data`, validate `y ~ x + "
            "spatial(1 | site, coords = coords), sigma ~ 1, zi ~ 1` (single deterministic "
            "seed): objective agreement -1.77e-10 (tolerance 1e-8), gradient max "
            "difference 1.60e-05 (tolerance 2e-5), checked at in-support response "
            "sentinels c(0, 12); masked-versus-observed coefficients and sdpars are "
            "identical, nobs 3136 on a 64-site, 50-observation-per-site fixture with a "
            "realised observed split of 1270 zero / 1866 positive responses. G3 "
            "deterministic known-DGP recovery (single deterministic seed) validates the "
            "fixed mu slope (0.0093, bound 0.15), residual log-sigma (0.0905, bound "
            "0.20), the zero-inflation intercept (0.0783, bound 0.30), and the spatial "
            "mu random-intercept SD (0.0714, bound 0.30). The fixed mu INTERCEPT is "
            "deliberately not checked: on this fixture it is confounded with the finite "
            "Gaussian-random-field draw's non-zero empirical mean, so the claim covers "
            "the slope, residual scale, zero-inflation intercept, and spatial SD, not "
            "the location intercept. This is not another provider, a mu slope on the "
            "structured term, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": (
            "Add a multi-seed recovery campaign before claiming intervals or coverage; "
            "the mu intercept remains untested and should not be inferred from this evidence."
        ),
    },
    "mc-0662": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional zi_poisson TMB-objective and numerical-gradient equality "
            "against the same independent hand-rolled dense-spatial-precision oracle "
            "family used for mc-0641 validate `y ~ x + spatial(1 | site, coords = "
            "coords), zi ~ 1` (single deterministic seed): objective agreement "
            "-3.64e-10, gradient max difference 6.38e-06 (both well within the "
            "tolerance regime used across this oracle family), checked at in-support "
            "response sentinels c(0, 12), on a fixture with a realised observed split "
            "of 1315 zero / 1821 positive responses. G3 deterministic known-DGP "
            "recovery (single deterministic seed) validates the fixed mu slope (0.0243, "
            "bound 0.15), the zero-inflation intercept (0.0218, bound 0.25), and the "
            "spatial mu random-intercept SD (0.0351, bound 0.25). The fixed mu "
            "INTERCEPT is deliberately not checked, for the same field-draw confounding "
            "recorded for mc-0641; the claim covers the slope, zero-inflation "
            "intercept, and spatial SD, not the location intercept. This is not "
            "another provider, a mu slope on the structured term, REML, missing "
            "predictors, intervals, or coverage."
        ),
        "next_gate": (
            "Add a multi-seed recovery campaign before claiming intervals or coverage; "
            "the mu intercept remains untested and should not be inferred from this evidence."
        ),
    },
    "mc-0667": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 conditional zi_poisson TMB-objective and numerical-gradient equality "
            "against the same independent hand-rolled dense-spatial-precision oracle "
            "family used for mc-0641/mc-0662 validate `y ~ x, zi ~ spatial(1 | site, "
            "coords = coords)` (single deterministic seed): objective agreement "
            "-2.55e-11, gradient max difference 7.56e-06 (both well within the "
            "tolerance regime used across this oracle family), checked at in-support "
            "response sentinels c(0, 12), on a fixture with a realised observed split "
            "of 1406 zero / 1730 positive responses. G3 deterministic known-DGP "
            "recovery (single deterministic seed) validates the fixed mu coefficients "
            "(max|beta_mu| 0.0138, bound 0.15) and the spatial zi random-intercept SD "
            "(0.0604, bound 0.25); unlike mc-0641/mc-0662, the fixed mu intercept IS "
            "checked here because mu carries no structured term on this route. The zi "
            "INTERCEPT is deliberately not checked, mirroring the mu-intercept "
            "convention used on mc-0641/mc-0662 for the structured parameter's own "
            "intercept. This is not another provider, a zi slope on the structured "
            "term, REML, missing predictors, intervals, or coverage."
        ),
        "next_gate": (
            "Add a multi-seed recovery campaign before claiming intervals or coverage; "
            "the zi intercept remains untested and should not be inferred from this evidence."
        ),
    },
    "mc-0321": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional gaussian phylogenetic-interaction objective and "
            "numerical-gradient equality validate `y ~ x + phylo_interaction(1 | "
            "plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree)` (single "
            "deterministic seed): objective agreement -1.12e-10, gradient agreement "
            "within relative tolerance 2e-5, checked at in-domain response sentinels "
            "c(-1e6, 1e6) for this unbounded Gaussian response; nobs 4032 of 4096, 64 "
            "masked. G3 deterministic known-DGP recovery (seed 2026081771) validates "
            "the fixed mu intercept (0.177, bound 0.30), the fixed mu slope (0.0033, "
            "bound 0.20), and the phylogenetic-interaction mu SD (0.021, bound 0.22). "
            "An independent 5-seed sweep gave intercept errors ranging 0.007 to 0.177; "
            "the cited seed sits near the top of that range, so the 0.30 bound carries "
            "real margin rather than reflecting a favourable draw. This is not "
            "sigma-side interaction, other effect geometries, REML, missing "
            "predictors, intervals, or coverage."
        ),
        "next_gate": "Add formula-specific evidence for every remaining gaussian phylo_interaction geometry.",
    },
    "mc-0653": {
        "formula_status": "formula_validated",
        "formula_mask_gate": "G3",
        "replace_model_claim": True,
        "claim_boundary": (
            "G2 dense conditional zi_nbinom2 phylogenetic-interaction objective and "
            "numerical-gradient equality validate `y ~ x, sigma ~ phylo_interaction(1 "
            "| plant:pollinator, tree1 = plant_tree, tree2 = pollinator_tree), zi ~ "
            "1` (single deterministic seed): objective agreement -1.17e-10, gradient "
            "3.75e-05 raw, within relative tolerance 2e-5, checked at in-support "
            "response sentinels c(0, 12); 1152 rows, 64 masked, realised observed "
            "split 725 zero / 363 positive. G3 deterministic known-DGP recovery (seed "
            "2026073001, the file's canonical default already used by three sibling "
            "tests on this fixture) validates the fixed mu intercept (0.019, bound "
            "0.20), the fixed mu slope (0.0009, bound 0.15), the fixed sigma "
            "intercept (0.090, bound 0.20), the phylogenetic-interaction sigma SD "
            "(0.043, bound 0.25), and the zero-inflation intercept (0.0064, bound "
            "0.20). DISCLOSURE: an alternative probe seed (2026081781) gave a "
            "sigma-intercept error of 0.209 against the same 0.20 bound; the cited "
            "canonical seed passes at 0.090, but the bound sits near this cell's "
            "noise floor and the claim should not be read as having wide margin. "
            "This is not mu-side interaction, other effect geometries, REML "
            "(unavailable for this family), missing predictors, intervals, or "
            "coverage."
        ),
        "next_gate": (
            "Add a multi-seed recovery campaign before claiming intervals or coverage; "
            "the sigma-intercept bound is close to this cell's noise floor on the "
            "canonical fixture."
        ),
    },
}


def read_tsv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle, delimiter="\t"))


def formula_gate(row: dict[str, str]) -> tuple[str, str, str, str]:
    """Return status, evidence gate, next action, and claim prefix for one cell."""
    if row["cell_id"] in FORMULA_EVIDENCE:
        evidence = FORMULA_EVIDENCE[row["cell_id"]]
        return (
            evidence["formula_status"],
            evidence["formula_mask_gate"],
            evidence["next_gate"],
            evidence["claim_boundary"],
        )
    if row["capability_status"] != "implemented":
        return (
            "not_admitted", "G0",
            "Keep the response-mask cell absent until this formula is admitted.",
            "Family-level response-mask evidence does not promote this formula cell. "
        )
    if row["estimator"] == "REML":
        return (
            "blocked_reml", "G0",
            "Derive and validate the observed-response restricted likelihood before admission.",
            "Family-level response-mask evidence does not promote this formula cell. "
        )
    if row["dimension"] == "bivariate" and row["route_modifier"] == "meta_V":
        return (
            "blocked_dense_known_V", "G0",
            "Implement component-level covariance slicing and verify it against a dense-MVN oracle.",
            "Family-level response-mask evidence does not promote this formula cell. "
        )
    if row["effect_type"] == "fixed":
        return (
            "family_validated", "G3",
            "Retain the family-level sentinel and recovery evidence for this fixed-effect formula.",
            "Family-level response-mask evidence supports this fixed-effect formula. "
        )
    return (
        "needs_formula_evidence", "G1",
        "Add formula-specific G2 sentinel/oracle checks and G3 known-DGP recovery evidence.",
        "Family-level response-mask evidence does not promote this formula cell. "
    )


def build(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    model = [row for row in rows if row["axis"] == "model_surface"]
    # Mixture routes deliberately share a base ``family_type`` with their
    # Poisson/NB2 density, so ``family_type`` is not a primary key here.
    # ``family_route`` is the public response route and is unique on the
    # missing-response axis.
    missing = {row["family_route"]: row for row in rows if row["axis"] == "missing_response"}
    result: list[dict[str, str]] = []
    for row in model:
        if row["cell_id"] in EXPLICIT_MODEL_CELL_IDS:
            continue
        if row["family_route"] not in missing:
            raise ValueError(f"{row['cell_id']}: no missing-response family row")
        family = missing[row["family_route"]]
        status, gate, next_gate, claim_prefix = formula_gate(row)
        evidence = FORMULA_EVIDENCE.get(row["cell_id"], {})
        claim_boundary = claim_prefix
        if not evidence.get("replace_model_claim", False):
            claim_boundary += row["claim_boundary"]
        result.append({
            "formula_cell_id": f"rmf-{row['cell_id']}",
            "model_cell_id": row["cell_id"],
            "family_type": row["family_type"],
            "model_type": row["model_type"],
            "route_variant": row["route_variant"],
            "route_modifier": row["route_modifier"],
            "dpar": row["dpar"],
            "effect_type": row["effect_type"],
            "structure_provider": row["structure_provider"],
            "dimension": row["dimension"],
            "q_gate": row["q_gate"],
            "estimator": row["estimator"],
            "formula_status": status,
            "family_mask_gate": family["test_gate"],
            "formula_mask_gate": gate,
            "claim_boundary": claim_boundary,
            "next_gate": next_gate,
        })
    return result + list(EXPLICIT_BOUNDARIES)


def render(rows: list[dict[str, str]]) -> str:
    from io import StringIO

    output = StringIO(newline="")
    writer = csv.DictWriter(output, fieldnames=FIELDS, delimiter="\t", lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
    return output.getvalue()


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write", action="store_true")
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    if args.write == args.check:
        parser.error("choose exactly one of --write or --check")

    rendered = render(build(read_tsv(CELLS)))
    if args.write:
        OUTPUT.write_text(rendered, encoding="utf-8")
        print(OUTPUT.relative_to(ROOT))
    elif not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != rendered:
        raise SystemExit("response-mask formula inventory is stale; run --write")
    else:
        print("response-mask formula inventory: OK")


if __name__ == "__main__":
    main()
