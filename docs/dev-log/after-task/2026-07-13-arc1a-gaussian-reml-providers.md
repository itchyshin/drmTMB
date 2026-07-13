# After Task: Arc 1a exact-Gaussian REML structured-provider parity

## 1. Goal

Extend native exact-Gaussian REML from the existing phylogenetic route to the
pure-`mu`, univariate `spatial()`, `animal()`, and `relmat()` intercept and
independent one-slope shapes, then admit and promote only the routes supported
by independent oracles, multi-seed recovery, profile coverage, and fresh D-43
review.

## 2. Implemented

`drmTMB(..., REML = TRUE)` now admits an unlabelled structured intercept or an
unlabelled intercept plus one independent numeric slope for each of the three
providers. The residual-scale model must be `sigma ~ 1` with no sigma random
effect. The final gate rejects slope-only and factor slopes, labelled or
multiple slopes, `sigma ~ x`, sigma random effects, matched structured
`mu+sigma`, bivariate and non-Gaussian routes, and the other pre-declared
boundaries.

The capability ledger promotes `mc-0287`, `mc-0299`, and `mc-0311` to
`implemented / verified / inference_ready_with_caveats`. No cell is promoted
to `supported`.

## 3. Mathematical Contract

For provider covariance matrix \(K_h\), the one-slope route fits

\[
y=X\beta+Zb_0+D_xZb_1+\varepsilon,\qquad
b_j\sim N(0,\tau_j^2K_h),\qquad
\varepsilon\sim N(0,\sigma^2I),
\]

with independent \(b_0\) and \(b_1\). The restricted objective is the standard
dense Gaussian restricted likelihood with the \(\log|X^TV^{-1}X|\)
adjustment. The structured scale \(\tau_j\) multiplies \(K_h\); it is not
generally a node-level marginal standard deviation.

## 3a. Decisions and Rejected Alternatives

The arc retained the existing exact-Gaussian engine and made a bounded R-side
admission change; the independent oracle showed no need for C++ estimator
work. Partial provider admission was rejected: each provider had to pass both
represented shapes. Continuous `M >= ...` claims, nominal-coverage wording,
`supported`, fixed-effect REML profiles, and campaign claims for Ainv/pedigree
or Q representations were rejected because the evidence does not support them.
Non-Gaussian REML, bivariate provider routes, matched `mu+sigma`, estimated
spatial range, and broad sparse-matrix work remain separate arcs.

## 4. Files Touched

- Admission, error wording, documentation, and focused deterministic tests:
  `R/drmTMB.R`, `man/drmTMB.Rd`, `README.md`, and
  `tests/testthat/test-reml-structured-location.R`.
- Campaign runner, summarizer, artifact reader, and the retained 29 MB Arc 1a
  evidence directory under `docs/dev-log/simulation-artifacts/`.
- Capability cells, evidence, transitions, census outputs, family map, tracked
  Markdown/HTML surface, REML scope boards, and their validators.
- `NEWS.md`, design notes 168/199/211, the candidate-arcs and Codex campaign
  plans, known limitations, check log, and this report.
- Seven older Ayumi/SR199 dashboard references were redirected from missing
  local checkpoint/output files to tracked after-task or design evidence; the
  paired contract expectation was updated.

## 5. Checks Run

- `pkgload::load_all(".")` compiled and loaded the package before live tests.
- Focused REML, oracle, representation, rejection, estimator-conformance, and
  structured-conversion tests passed.
- Full `devtools::test()` passed with zero failures, 24 expected unavailable-
  Julia skips, and 62 existing expected warnings.
- Genuine `rcmdcheck::rcmdcheck(args = "--as-cran")` completed in 7m06s with
  0 errors, 0 warnings, and 1 expected new-submission/development-version note.
- `pkgdown::check_pkgdown()` reported `No problems found`.
- `python3 tools/capability_ledger.py --write` and `--check` passed; all 14
  generator tests passed; `python3 tools/validate-mission-control.py` returned
  `mission_control_ok`; `git diff --check` passed.
- Full recovery/profile hash manifests passed read-back. The tracked capability
  HTML SHA-256 is
  `58d786abe86cadc038020957d76fd386d6e245e99c87d62cd8581f28aa6d5d12`.

## 6. Tests of the Tests

Clean pre-change `HEAD` rejected all six provider-by-shape positive routes, so
the admission tests fail before the implementation. The deterministic tests
also compare parameters and normalized objectives with an independent dense
restricted-likelihood calculation and exercise displaced common parameter
vectors. Noether's two adversarial probes found that checking only the fixed
sigma design leaked first `sigma ~ x` and then an ordinary sigma random effect;
both probes now have all-provider rejection regressions. The final clean-commit
replay produced 28/28 converged recovery fits with 42/42 finite target rows and
14/14 converged profile fits with 21/21 valid endpoints.

## 8. Consistency Audit

The implementation, symbolic model, examples, REML scope boards, capability
ledger, family map, NEWS, design notes, README, roadmap inventory, formula
grammar inventory, known limitations, and tracked HTML were checked together.
No formula grammar or pkgdown navigation change was needed because Arc 1a uses
existing public syntax. Exact stale-wording searches included:

```sh
rg "spatial\\(\\).*animal\\(\\).*relmat\\(\\).*reject|mean-side non-phylo.*remain.*(UNVALIDATED|rejected)|Task C remains deferred" README.md NEWS.md ROADMAP.md docs R tests vignettes
rg "currently supports only phylogenetic|Spatial, animal, and relatedness structured effects under REML are not validated yet" R tests docs
rg "Arc 1a|structured.*REML|REML.*structured" README.md ROADMAP.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd
```

Historical reports remain historical; current status documents and generated
surfaces now carry the superseding boundary.

## 7a. Issue Ledger

The open-issue search found only broad Phase 18 issue #59. It is not a focused
Arc 1a tracker and was left unchanged. No duplicate issue was opened. A focused
feature-branch pull request is the appropriate review surface; it must not be
merged without separate approval.

## 9. What Did Not Go Smoothly

The first admission helper checked the fixed sigma design but not the complete
sigma submodel. D-43 therefore found two sequential boundary leaks. The first
full-suite run also exposed one old test that required an untracked/missing
checkpoint filename even after Mission Control correctly rejected that
reference. The implementation and final verification were paused until each
problem was repaired and re-run.

## 11. Team Learning

An estimator admission guard must validate every component that changes the
claimed covariance model, not only the fixed-effect design matrix. Dashboard
validators must also resolve evidence from tracked files in a clean worktree;
untracked local artifacts cannot be load-bearing repository evidence. These
rules were added to `docs/dev-log/team-improvements.md`.

## 10. Known Residuals

The evidence is discrete: spatial and relmat use `M={8,16,32}`, animal uses one
fixed `M=8` pedigree, and every campaign cell uses `n_each=20`. The campaign
uses coordinates, animal `A`, and relmat `K`; Ainv/pedigree and Q equivalence is
deterministic-fixture evidence only. Coverage is mildly non-nominal with upper-
tail miss asymmetry and frequent zero-lower-bound slope profiles. Fixed-effect
REML profiles, estimated spatial range, large/sparse or ill-conditioned
matrices, labelled/multiple slopes, matched scale models, bivariate and
non-Gaussian REML remain outside the claim.

## 12. Cross-Product Coverage

The deterministic suite covers all three providers crossed with both admitted
shapes and all declared representation pairs, plus all-provider negative
guards. The campaign covers 14 provider-by-shape-by-M cells and every fitted
structured-scale target. Arc 1a **does NOT cover** sigma
random or structured effects, labelled or multiple slopes, bivariate models,
non-Gaussian families, missing-data engines, estimated spatial range, or broad
matrix geometries. Those absent combinations remain rejected or separately
deferred rather than inferred from neighbouring cells.

## Next Actions

Rose must audit the exact final tree and return DONE before any completion
claim. Then commit and push the closeout, open the feature-branch pull request,
and provide the canonical HTML path, generator command, commit SHA, and SHA-256
to Claude. The external `a1bf21a1` artifact remains pending until Claude
confirms an exact mirror read-back. Do not merge the Arc 1a PR without separate
approval.
