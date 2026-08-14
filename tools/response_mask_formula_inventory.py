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

# Formula-level evidence is deliberately enumerated here rather than inferred
# from a family mask or from the complete-response model-surface ledger.
FORMULA_EVIDENCE = {
    **{
        cell_id: {
            "formula_status": "formula_oracle_validated",
            "formula_mask_gate": "G2",
            "claim_boundary": (
                "G2 observed-data dense full marginal-Gaussian likelihood equality "
                "and direct sentinel retapes validate this univariate Gaussian "
                "unlabelled q1 structured mu intercept-plus-one-independent-slope "
                "ML response-mask formula. G3 recovery remains unvalidated, so this "
                "row does not promote recovery, intervals, coverage, q2/correlated "
                "structures, another provider, bivariate, non-Gaussian, or missing-"
                "predictor ML formulas."
            ),
            "next_gate": "Measure and approve a stable structured known-DGP recovery design before G3 promotion.",
        }
        for cell_id in ("mc-0286", "mc-0298", "mc-0310")
    },
    **{
        cell_id: {
            "formula_status": "formula_oracle_validated",
            "formula_mask_gate": "G2",
            "claim_boundary": (
                "G2 observed-data dense full marginal-Gaussian likelihood equality "
                "and direct sentinel retapes validate this univariate Gaussian "
                "unlabelled q1 structured mu random-intercept ML response-mask "
                "formula. G3 recovery remains unvalidated, so this row does not "
                "promote recovery, intervals, coverage, another provider, another "
                "structured geometry, bivariate, non-Gaussian, or missing-predictor "
                "ML formulas."
            ),
            "next_gate": "Measure and approve a stable structured known-DGP recovery design before G3 promotion.",
        }
        for cell_id in ("mc-0285", "mc-0297", "mc-0309")
    },
    **{
        cell_id: {
            "formula_status": "formula_oracle_validated",
            "formula_mask_gate": "G2",
            "claim_boundary": (
                "G2 observed-data dense restricted-likelihood equality and direct "
                "sentinel retapes validate this univariate Gaussian unlabelled q1 "
                "structured mu random-intercept REML response-mask formula. The "
                "single-draw structured fixture was not stable enough for a G3 "
                "recovery claim, so this row does not promote recovery, intervals, "
                "coverage, another provider, another structured geometry, bivariate, "
                "non-Gaussian, or missing-predictor REML formulas."
            ),
            "next_gate": "Measure and approve a stable structured known-DGP recovery design before G3 promotion.",
        }
        for cell_id in ("mc-0287", "mc-0299", "mc-0311")
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
        "formula_status": "formula_validated", "formula_mask_gate": "G3",
        "claim_boundary": "G2 observed-data equality and sentinel retapes, plus G3 deterministic MCAR recovery, validate zero-one-beta coi independent random slopes with fixed mu, sigma, and zoi formulas. This does not promote coi intercepts beyond their separate cell, other random effects, structured effects, REML, or missing predictors.",
        "next_gate": "Add formula-specific evidence for every remaining zero-one-beta parameter geometry.",
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
        if row["family_route"] not in missing:
            raise ValueError(f"{row['cell_id']}: no missing-response family row")
        family = missing[row["family_route"]]
        status, gate, next_gate, claim_prefix = formula_gate(row)
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
            "claim_boundary": (
                claim_prefix
                + row["claim_boundary"]
            ),
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
