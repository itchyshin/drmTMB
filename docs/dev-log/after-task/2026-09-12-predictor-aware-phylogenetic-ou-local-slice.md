# After-task report: predictor-aware phylogenetic OU local slice

## 1. Goal

Add an explicit OU alternative to the Brownian-motion default for the admitted
univariate Gaussian phylogenetic location intercept, and test the requested
location--scale--direct-SD body-mass form on Ayumi's all-species data without
claiming recovery, intervals, or a general BM-versus-OU preference.

## 2. Implemented

`phylo(..., model = "ou")` is explicit; omitted `model` remains BM. The admitted
route has one Gaussian `mu` phylogenetic intercept, fixed effects in `mu` and
`sigma`, and an optional direct phylogenetic-SD amplitude formula. Its positive
location rate is reported as `decay_phylo` (the compatibility name for
`alpha_mu`). Provider metadata now records a field identifier and an
`alpha_index0`; the compiled template holds `log_decay_phylo` as a vector and
selects the field's rate through that index. The current public route contains
one field at index zero. The follow-up hardening made that registry executable:
starts, TMB data, native root-and-edge prior, extraction, profile targets, and
diagnostics all read field-specific rate slots. A low-level two-field contract
proves separate slots affect the native objective while the public parser still
rejects that unadmitted configuration. Independent review found and the
permutation test repaired an ordering defect: native offsets and latent SDs now
both follow each field's recorded latent index, rather than registry position.
Noether's re-review found no remaining field-mapping mismatch.

The portable Ayumi runner and its fail-closed verifier retain the four-cell
BM/OU by constant/climate-residual-scale ladder, exact source commit and
checksums, model diagnostics, and the explicit claim boundary.

## 3. Mathematical Contract

For a positive location-side rate alpha and edge length ell,
`rho = exp(-alpha * ell)` and the stationary root-and-edge tree construction
defines the unit OU correlation. With a direct SD design, the marginal
phylogenetic covariance is `D_gamma C_OU(alpha_mu) D_gamma`; it replaces the
ordinary scalar phylogenetic scale instead of multiplying it. Fixed-effect
`sigma ~ temperature + precipitation` changes independent residual variation
and creates neither a second phylogenetic field nor `alpha_sigma`.

## 3a. Decisions and Rejected Alternatives

BM remains the default and OU is explicit. The first public slice is limited to
one univariate Gaussian location intercept; it deliberately rejects OU slopes,
sigma-side OU, bivariate/missing-response OU, temporal combinations, and new
data or forecast workflows. Fixed residual `sigma` and direct phylogenetic-SD
predictors are admitted because they are distinct from a second phylogenetic
OU field. A shared alpha and a sum-to-zero repair for intercept--field
separation were rejected because both would change the model rather than test
its identifiability honestly.

## 4. Files Touched

The implementation is in `R/drmTMB.R` and `src/drmTMB.cpp`; the independent
native-oracle and parser guards are in
`tests/testthat/test-phylo-ou-covariance-native.R` and
`tests/testthat/test-phylo-ou-covariance-parser.R`. Reproducibility tools are
`tools/phylo-ou-ayumi-bodymass-ladder.R`,
`tools/verify-phylo-ou-ayumi-bodymass-receipt.R`, and
`tools/phylo-ou-recovery-preflight.R`. Formula, likelihood, reader, and
capability wording was reconciled in the R help, `NEWS.md`, `README.md`,
`docs/design/01-formula-grammar.md`, `docs/design/03-likelihoods.md`,
`docs/dev-log/known-limitations.md`, and the phylogenetic/model-map vignettes.

## 5. Checks Run

Focused gates G1--G4 all emitted their required `PHYLO_OU_G*_PASS` markers
after the indexed-vector change. `devtools::document()` passed. The receipt
verifier passed against `/private/tmp/phylo-ou-ayumi-bodymass-ladder-verified`
at Ayumi source commit `6c52a46f67d9d86842ae5476dee828684f64a464` with 10,440
rows/tips and all four REML cells. `git diff --check` passed after the final
documentation and verifier changes.

## 6. Tests of the Tests

The dense independent covariance oracle compares objective, gradient, and
observed Hessian against the native sparse tree likelihood. Its mutations reject
wrong edge normalization, shared-depth covariance, wrong direct-SD placement,
and an accidental BM substitution. Parser tests reject sigma-side OU rather
than silently sharing `alpha_mu`; BM default/parity tests remain in the focused
suite. The receipt verifier checks schema, current source commit, source
checksums, four required cells, convergence/Hessian status, and `check_drm()`
diagnostic counts.

## 7a. Issue Ledger

Ayumi's public issue list was inspected read-only. Issue #12 is the
all-species location--scale--direct-SD body-mass specification; issue #2
describes future sigma-side phylogeny. No issue was opened, closed, or
commented on because this isolated implementation/evidence arc does not change
Ayumi's tracker state.

## 7b. Empirical and Recovery Evidence

The exact Ayumi ladder converged for all cells. BM constant/climate max gradients
were approximately `3.6e-10` and `9.9e-11`; OU constant/climate were `0.0157`
and `0.00121`, with BFGS fallback warnings and alpha estimates near zero. A
12-fit clean-versus-weak simulation preflight retained variable clean alpha
estimates and frequent weak-design non-positive-definite Hessians. These are
negative inference findings, so the public boundary remains local fit/oracle
only.

## 8. Consistency Audit

The formula grammar, likelihood design, README, model map, phylogenetic reader
article, NEWS, and limitations consistently distinguish `alpha_mu`, deterministic
residual `sigma`, direct-SD amplitude, and deferred `alpha_sigma`. The source
and generated reader surfaces therefore agree with the explicit boundaries in
the issue ledger.

## 9. What Did Not Go Smoothly

The receipt verifier originally checked the stored commit and diagnostics too
weakly; it now verifies the current source HEAD and required diagnostic columns.
The 1,000-tip OU-plus-climate-scale preflight took 55.97 seconds, converged only
after fallback, and had `pdHess = FALSE` with max gradient 5.2566678. Sandbox
restrictions prevented `/usr/bin/time -l` from querying RSS. The source-lane
lease registry was also unavailable for a durable write, although the isolated
worktree and preflight found no active file overlap.

An independent direct process sampler was then denied `ps` access by the same
sandbox and reproduced the numerical fit without an RSS value. This rules out
the two local telemetry paths used here; it does not establish a memory bound.

The inspected preflight was finally run outside that sandbox and completed in
54.89 seconds with maximum resident set size 594,640,896 bytes and peak memory
footprint 569,082,912 bytes. It retains its BFGS fallback, `pdHess = FALSE`, and
large gradient, so this closes only the sparse-resource measurement gate.

A source-current replay then ran each Ayumi ladder cell in its own process under
`/usr/bin/time -l`. The retained receipt records per-fit elapsed time, RSS,
peak-memory footprint, fixed effects, optimizer warning counts, and short
reconstructed OU alpha-profile diagnostics. Both OU fits again select alpha
near zero and have nearly flat local profiles; these observations are boundary
evidence only, not decay intervals or a BM-versus-OU choice.

## 10. Known Residuals

G0 remains open because the initial lane lease was not durably persisted before
the first edits; a later scoped lease protects this continuation but cannot
rewrite that history. G6 is met as a resource measurement while its weak
Hessian/gradient stay visible. G9 remains open. The provider has field-specific allocation, native loops, and
named extraction/profile seams, but it is not public multi-field OU support: a
future sigma-side field still needs its own formula/data layout, `alpha_sigma`,
and validation arc. There is no bivariate, missing-response, temporal, slope,
forecast, `newdata`, recovery, interval, coverage, or BM-preference claim.

## 11. Team Learning

The initial field registry was not sufficient on its own: native code must use
stored latent indices as well as alpha indices, and the permutation contract
is now retained to detect that class of mapping error. Empirical fit objects
cannot safely be profiled after a compiled-template data-layout change; the
profile helper therefore refuses a provenance mismatch and rebuilds a current
objective from a fresh compatible fit.

## 12. Cross-Product Coverage

This arc changes the formula parser, R-to-TMB provider metadata, native tree
prior, extraction/diagnostic/profile seams, mutation tests, user reference and
vignettes, reproducibility tools, empirical receipts, and the after-task/check
log. It does not cover the deferred sigma-side OU/`alpha_sigma` field,
bivariate or missing-response layouts, other families, or temporal P4/P5.

## Next Actions

Do not broaden this slice on the basis of the empirical fit or the completed
resource preflight. The next mathematically distinct arc is sigma-side
phylogeny with a separate `alpha_sigma`; it must not reuse `alpha_mu`
implicitly. A retained recovery or calibration campaign requires a fresh
estimate and approval if the preflight shows it will exceed 30 minutes.
