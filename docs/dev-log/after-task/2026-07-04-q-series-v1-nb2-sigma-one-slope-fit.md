# After Task: Q-Series v1 NB2 Sigma One-Slope Local Fit-Only Recovery

## 1. Goal

Move the four ordinary `nbinom2()` q1 `sigma` independent-one-slope structured
rows from active rejection/design work into local fit-only recovery for the
v1.0 basic-distribution surface, without opening denominator, interval,
coverage, bridge, q2/q4, REML, AI-REML, `inference_ready`, `supported`, or
public-support claims.

## 2. Implemented

`drm_build_nbinom2_spec()` now accepts exactly one structured `sigma`
independent-one-slope term for ordinary NB2 models:
`phylo(1 + x | id, tree = tree)`, `spatial(1 + x | id, coords = coords)`,
`animal(1 + x | id, Ainv = Q)`, or `relmat(1 + x | id, Q = Q)`.

The builder rejects multiple structured sigma providers, any accompanying
ordinary or structured `mu` random effect, ordinary `sigma` random effects,
labelled covariance, intercept-only, multiple slopes, zero-inflation, and
location-scale block variants. The admitted structured term is stamped with
`dpars = "sigma"` and routed through the existing structured known-covariance
machinery, which already sends NB2 structured endpoint `sigma` contributions to
the `log_sigma` predictor.

The local first-four smoke now checks nine rows: five prior fit/rejection rows
plus the four NB2 sigma one-slope provider fits. Mission Control and the v1.0
release ledger classify the four NB2 sigma rows as `point_fit` and
`extractor_ready`, with no denominator and no coverage or promotion authority.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only ordinary NB2 q1 `sigma` unlabelled independent-one-slope routes.
- Keep the route local-debug-only and source-authority only.
- Retire the count-slope sigma one-slope rejection sidecar to a header-only
  contract, while checking the recovered rows directly through support cells.
- Regenerate the v1.0 ledger and preflight artifacts so the visible accounting
  moves from 78/104 to 82/104 practical rows.

Rejected alternatives:

- Do not treat the four local fits as retained denominators.
- Do not move any row to `inference_ready` or `supported`.
- Do not broaden to labelled covariance, multiple structured slopes, q2/q4,
  zero-inflated NB2, simultaneous location-scale support, bridge support, REML,
  AI-REML, intervals, coverage, or public support.

## 3b. Mathematical Contract

The admitted local fit-only route is:

```text
y_i ~ NB2(mu_i, sigma_i)
log(mu_i) = X_i beta
log(sigma_i) = Z_i gamma + u0_id[i] + u1_id[i] x_i
u0 ~ N(0, sigma_0^2 K)
u1 ~ N(0, sigma_1^2 K)
cov(u0, u1) = 0
```

`K` is the provider covariance implied by the tree, spatial kernel, animal
precision, or relmat precision. The route estimates direct structured SDs for
the `sigma` intercept and one-slope components. It does not establish Wald or
profile intervals, retained-denominator rates, coverage, `inference_ready`,
`supported`, REML, AI-REML, q2/q4 behavior, bridge behavior, labelled
covariance, or public support.

## 4. Files Touched

- `R/drmTMB.R`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_release_check.py`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/dev-log/dashboard/structured-re-count-slope-sigma-one-slope-rejection-contract.tsv`
- `docs/dev-log/dashboard/structured-re-nongaussian-status-audit.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-support-cells.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-readiness-reset.tsv`
- `docs/dev-log/dashboard/structured-re-q-series-v1-release-ledger.tsv`
- `docs/dev-log/release-audits/q-series-v1-release-status.md`
- `docs/dev-log/release-audits/q-series-v1-preflight-report.md`
- `docs/dev-log/release-audits/q-series-v1-next-candidate-review.tsv`
- `docs/dev-log/release-audits/q-series-v1-75pct-review-packet.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-design-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-candidate-debug-fixture-contract.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-design-contracts.tsv`
- `docs/dev-log/release-audits/q-series-v1-first-four-debug-fixture-contracts.tsv`
- `tests/testthat/test-nongaussian-structured-boundary.R`
- `tests/testthat/test-structured-re-conversion-contracts.R`
- `docs/dev-log/check-log.md`

## 5. Checks Run

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('R/drmTMB.R')); invisible(parse('tools/qseries-v1-first-four-rejection-smoke.R')); invisible(parse('tests/testthat/test-nongaussian-structured-boundary.R')); invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('parse_ok\n')"`: passed.
- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "pkgbuild::compile_dll(debug = FALSE, quiet = TRUE); cat('compile_dll_ok\n')"`: passed.
- `/Users/z3437171/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node -e "const fs=require('fs'); const html=fs.readFileSync('docs/dev-log/dashboard/index.html','utf8'); const m=html.match(/<script>([\s\S]*)<\/script>/); if(!m) throw new Error('no script block'); new Function(m[1]); console.log('dashboard_js_syntax_ok');"`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`: passed with eight `expected_fit` rows and one `expected_rejection` row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, 104 Q-Series cells, 8 exact `inference_ready` rows, 0 `supported` rows, and 0 active count-slope sigma one-slope rejection rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`: passed with 82/104 practical rows, 26/37 basic-distribution recovery rows, 8/104 exact `inference_ready` anchors, 0/104 `supported` authority rows, and 22/104 post-v1.0 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`: passed after updating stale retired-sidecar expectations.
- `git diff --check`: passed.

## 6. Tests of the Tests

The first conversion-contract rerun failed because it still expected four active
count-slope sigma rejection rows. That failure proved the test was still
guarding the old boundary. The corrected test now checks that the rejection
sidecar is header-only and that the four support-cell rows are point-fit,
extractor-ready, local-debug-only, and still unsupported for bridge, intervals,
and coverage.

The focused boundary test also checks a fail-closed labelled-covariance NB2
sigma formula and expects the new unlabelled independent-one-slope guard to
reject it.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. The local `gh` CLI is not installed
in this shell, and this slice is a focused branch checkpoint for the active
v1.0 row-surface lane.

## 8. Consistency Audit

Rose boundary: this slice changes four local fit-only support cells and no
interval/coverage/support status. The Q-Series board still has 104 support
cells, 8 exact `inference_ready` anchors, 0 `supported` authority rows, 0 q4
coverage-authorized rows, and no non-Gaussian interval/coverage promotion.

Fisher boundary: the NB2 sigma provider fits are deterministic local recovery
smokes only. They are not retained denominators and include no profile, Wald,
coverage, MCSE, or admission interpretation.

Gauss boundary: the route stays inside ordinary NB2 and independent unlabelled
one-slope covariance. Labelled covariance, simultaneous location-scale, and
zero-inflation stop at the formula gate.

Grace boundary: Mission Control, the generated release checker, the focused R
tests, py_compile, parse checks, dashboard JavaScript syntax, and diff hygiene
all pass after regenerating the ledger and release artifacts.

## 9. What Did Not Go Smoothly

The first conversion-contract rerun exposed two stale expectations: the retired
count-sigma rejection sidecar still expected four rows, and the generated
preflight report expectation still looked for the previous NB2 sigma candidate
text. Both were test-accounting drift, not runtime failures.

## 10. Known Residuals

The four NB2 sigma one-slope rows remain local fit-only recovery evidence. They
are not interval-ready, coverage-ready, `inference_ready`, `supported`,
bridge-supported, q2/q4, REML/AI-REML, labelled-covariance support,
zero-inflated NB2 support, simultaneous location-scale support, or public
support.

The generated next review packet now starts with ordinal `mu` phylo, Student
`nu` phylo, Poisson `zi` spatial, and truncated NB2 `hu` relmat rows. Those are
design/recovery contract candidates only.

## 11. Team Learning

Rose: when a rejection sidecar is retired, keep a header-only file and add a
direct support-cell assertion so stale row movement cannot hide in either
direction.

Fisher: fit-only recovery can move v1.0 practical surface, but the denominator
language must stay negative in the same row.

Grace: the fastest honest closeout is the narrow smoke plus Mission Control,
release preflight, and focused conversion contracts; no cluster compute was
needed for this slice.

## Next Actions

At 82/104 practical rows, only two additional practical rows are needed to
reach the 80% row-accounting target. The next generated packet is
design-first, not implementation-first: any row movement still needs
row-specific recovery evidence plus Rose/Fisher/Grace review, and still
authorizes no coverage, `inference_ready`, `supported`, REML, AI-REML, q4/q8,
or public-support claim.
