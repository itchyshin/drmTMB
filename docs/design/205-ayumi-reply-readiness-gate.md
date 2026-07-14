# Ayumi Reply Readiness Gate

> **Current-status correction (2026-07-14).** This readiness note predates the
> native structured-REML admissions summarized in
> `docs/design/211-structured-reml-status.md`. Use the corrected row-specific
> tiers below; no point-fit or recovery row inherits interval, coverage,
> `supported`, bridge, or HSquared AI-REML status.

## Purpose

This note banks A091-A099 without drafting or posting an Ayumi issue reply. It
is a readiness gate: it names the evidence that a future reply must use, the
claims that remain blocked, and the approval condition before any public
comment is written.

## Evidence Sections A Future Reply Must Cover

### Changed Since The Prior Reply

The local evidence map is materially clearer than before:

- Native TMB ML is balanced for univariate Gaussian `phylo()` intercept cells:
  `mu`, `sigma`, and matched `mu+sigma` have fit-target evidence and dashboard
  rows.
- Native TMB REML is exact-Gaussian and row-specific. Q1 mean-side has retained
  inference evidence; sigma-only and matched univariate q2 have point-fit
  evidence; bivariate mean-side q2 has point-fit evidence; and block-diagonal
  or dense q4 has recovery evidence. The latter rows do not inherit q1
  mean-side interval or coverage promotion.
- The R-via-Julia bridge has experimental sigma-phylo and matched sigma-phylo
  REML gates, including configured live bridge-admission tests for both cells,
  but it is not a promoted bridge route.
- Native q4 ML is diagnostic point/status evidence. q4 SD targets can be
  direct-ready, but q4 correlations are derived-only and interval support is
  not calibrated.
- Direct DRM.jl has q4 profile/bootstrap machinery, but prior direct bootstrap
  evidence records scale-axis undercoverage and does not promote the R bridge.

### Still Not Solved

Do not claim any of the following:

- inference-ready balanced phylogenetic REML across `mu` and `sigma`;
- native q4 REML intervals, coverage, or `supported` status beyond the current
  recovery-grade fit;
- non-Gaussian REML or AI-REML;
- HSquared AI-REML for q4;
- calibrated q4 profile/bootstrap coverage;
- 10,440-tip sigma-phylo intervals;
- public optimizer or `engine_control` support;
- R-via-Julia bridge support beyond row-specific experimental gates.

### What Can Be Run Now

The run-now applied path is Model A+: phylogenetic location effects for both
traits, fixed-effect `sigma1` and `sigma2`, and residual `rho12`. It is the
clean full-data anchor in current local evidence.

Matched native ML `mu+sigma` phylogenetic models can be used as diagnostics or
sensitivity checks when their `check_drm()` rows are clean. A `pdHess = FALSE`
scale-side row should be read as a Wald-inference warning, not as a settled
interval result.

Native q4 ML and direct DRM.jl q4 interval machinery should remain diagnostic
or experimental until row-specific native/direct/bridge parity and coverage
evidence exist.

## Audit Results

### Rose

The forbidden-claim audit should scan for balanced native REML, q4 AI-REML,
non-Gaussian REML, 10k interval claims, hidden bridge promotion, and public
optimizer control. Negative statements in evidence ledgers are acceptable; a
future public reply should avoid those phrases unless they are explicitly
framed as unsupported.

### Pat

An applied reader needs one clear primary choice and clear caveats. The primary
choice is Model A+. The caution is that a scale-side phylogenetic random field
with one observation per tip is weakly identified and needs replication,
penalty/prior sensitivity, or row-specific interval evidence before
interpretation.

### Gauss And Fisher

The statistical boundary is coherent: profile-target readiness is not coverage,
bootstrap plumbing is not calibrated uncertainty, and `pdHess = FALSE` is a
warning against Wald intervals. Direct DRM.jl q4 profile/bootstrap APIs are
useful engineering evidence, but scale-axis bootstrap undercoverage prevents a
simple uncertainty headline.

## Approval Gate

A public Ayumi reply is blocked until the maintainer explicitly approves a
reply task. At that time, draft from this readiness gate and the validator-owned
TSVs, then run the forbidden-claim scan again immediately before posting.

## A099 Status

A099 remains blocked. No issue comment was posted and no public reply draft was
created in this wave.
