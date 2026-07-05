# After Task: Q-Series v1 Student nu and Poisson zi Local Fit-Only Recovery

## 1. Goal

Move the two cheapest remaining non-Gaussian q1 endpoint rows,
`student()` `nu ~ phylo(1 | id, tree = tree)` and zero-inflated `poisson()`
`zi ~ spatial(1 | id, coords = coords)`, into the v1.0 practical surface as
local fit-only recovery rows. Keep intervals, coverage, `inference_ready`,
`supported`, bridge, q2/q4, REML, AI-REML, retained denominators, host compute,
and public support out of scope.

## 2. Implemented

`drm_build_student_ls_spec()` now admits exactly one Student shape-side
structured route: unlabelled intercept-only `phylo()` on `nu`. The term is
stamped with `dpars = "nu"`, routed through the existing known-covariance
structured machinery, and rejected if combined with the existing Student
spatial `mu` structured route.

`drm_build_poisson_spec()` now admits exactly one zero-inflation structured
route: unlabelled intercept-only `spatial()` on `zi`. The route is rejected if
combined with ordinary or structured `mu` random effects.

The TMB objective now routes structured endpoint contributions by distributional
parameter code for these cases: Student `nu` contributions go to `eta_nu`, and
Poisson `zi` contributions go to `eta_zi`. The existing sparse known-covariance
prior block is reused. Extractors now expose endpoint-specific random effects
and SDs as `phylo_nu` / `sdpars$nu` and `spatial_zi` / `sdpars$zi`.

## 3a. Decisions and Rejected Alternatives

Decisions:

- Admit only Student `nu` phylo q1 intercept and Poisson `zi` spatial q1
  intercept as local fit-only recovery rows.
- Keep the fixtures deterministic, local, and cheap.
- Retire the two moved rows from the active structured-family rejection sidecar
  instead of leaving contradictory rejection evidence.
- Regenerate the v1.0 release ledger/status and candidate queue from the support
  cells.

Rejected alternatives:

- Do not run Totoro/DRAC; no retained denominator or coverage evidence is
  needed for this slice.
- Do not broaden to Student shape slopes, Poisson zero-inflation slopes, other
  providers, combined location-inflation blocks, q2/q4, bridge support, REML,
  AI-REML, intervals, coverage, `inference_ready`, `supported`, or public
  support.
- Do not use BFGS fallback to force the Student fixture; the stable fixture was
  made small and ordinary enough to converge under the standard optimizer path.

## 3b. Mathematical Contract

The Student row is:

```text
y_i ~ Student(mu_i, sigma, nu_i)
mu_i = X_i beta
nu_i = 2 + exp(eta_nu,i)
eta_nu,i = Z_i gamma + u_tip[i]
u ~ N(0, sigma_phylo^2 A_phylo)
```

The Poisson zero-inflation row is:

```text
y_i ~ zero-inflated Poisson(mu_i, pi_i)
log(mu_i) = X_i beta
logit(pi_i) = Z_i gamma + u_site[i]
u ~ N(0, sigma_spatial^2 C(distance))
```

Both contracts are local fit-only. They do not establish Wald/profile
intervals, retained-denominator rates, coverage, `inference_ready`, `supported`,
REML, AI-REML, q2/q4 behavior, bridge behavior, or public support.

## 4. Files Touched

- `R/drmTMB.R`
- `src/drmTMB.cpp`
- `tools/qseries-v1-first-four-rejection-smoke.R`
- `tools/qseries_v1_release_check.py`
- `tools/qseries_v1_claim_guard.py`
- `tools/validate-mission-control.py`
- `docs/dev-log/dashboard/README.md`
- `docs/design/218-structured-q-series-completion-map.md`
- `docs/dev-log/dashboard/structured-re-nongaussian-structured-family-rejection-contract.tsv`
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

- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "invisible(parse('R/drmTMB.R')); invisible(parse('tools/qseries-v1-first-four-rejection-smoke.R')); invisible(parse('tests/testthat/test-nongaussian-structured-boundary.R')); invisible(parse('tests/testthat/test-structured-re-conversion-contracts.R')); cat('r_parse_ok\n')"`: passed.
- `python3 -m py_compile tools/validate-mission-control.py tools/qseries_v1_release_check.py tools/qseries_v1_release_ledger.py tools/qseries_v1_claim_guard.py`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file -e "pkgbuild::compile_dll(debug = FALSE, quiet = TRUE); cat('compile_dll_ok\n')"`: passed earlier after the C++ endpoint routing edit.
- `/Users/z3437171/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin/node -e "const fs=require('fs'); const html=fs.readFileSync('docs/dev-log/dashboard/index.html','utf8'); const m=html.match(/<script>([\s\S]*)<\/script>/); if(!m) throw new Error('no script block'); new Function(m[1]); console.log('dashboard_js_syntax_ok');"`: passed.
- `R_PROFILE_USER=/dev/null /usr/local/bin/Rscript --no-init-file tools/qseries-v1-first-four-rejection-smoke.R`: passed with ten `expected_fit` rows and one `expected_rejection` row.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/validate-mission-control.py`: passed with `mission_control_ok`, 104 Q-Series cells, 8 exact `inference_ready` rows, 0 `supported` rows, 0 active count-slope sigma one-slope rejection rows, and 2 active structured-family rejection rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true python3 tools/qseries_v1_release_check.py --summary --check-report --check-candidates`: passed with 84/104 practical rows, 28/37 basic-distribution recovery rows, 8/104 exact `inference_ready` anchors, 0/104 `supported` authority rows, and 20/104 post-v1.0 rows.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'nongaussian-structured-boundary', reporter = 'summary')"`: passed.
- `R_PROFILE_USER=/dev/null NOT_CRAN=true /usr/local/bin/Rscript --no-init-file -e "devtools::test(filter = 'structured-re-conversion-contracts', reporter = 'summary')"`: passed after updating stale generated-artifact expectations.

## 6. Tests of the Tests

The first smoke run caught a real fixture issue: the Student `nu` route exposed
`phylo_nu` and `sdpars$nu`, but the original synthetic data triggered
`nlminb()` false convergence. I did not paper over that with fallback BFGS,
which produced an absurd objective. Instead, the fixture was made smaller and
more stable while keeping nonzero shape variation; it now converges under the
standard optimizer path.

The conversion-contract suite then caught stale row-accounting expectations:
the non-Gaussian rejected/point-only bucket counts and the generated first-four
queue had changed. Updating those expectations confirmed that the tests were
checking the new Mission Control state, not merely passing by inertia.

## 7a. Issue Ledger

No GitHub issue was opened or commented on. This was a focused local branch
checkpoint in the Q-Series v1.0 practical-surface lane.

## 8. Consistency Audit

Rose boundary: the active structured-family rejection sidecar now contains only
two rows, matching Mission Control and the support cells. The moved Student
`nu` and Poisson `zi` rows no longer appear as active rejection rows.

Fisher boundary: this is local fit-only evidence. No row gains interval,
coverage, retained-denominator, `inference_ready`, or `supported` status.

Gauss boundary: the endpoint routing is explicit in the objective. Student
`nu` uses dpar code 2 and Poisson `zi` uses dpar code 3. Other endpoints fall
back to the existing `mu`/`sigma` behavior.

Grace boundary: Mission Control, the release checker, R syntax, Python syntax,
dashboard JavaScript syntax, focused smoke, and focused R tests passed after
regenerating artifacts.

## 9. What Did Not Go Smoothly

The initial Student fixture fit but did not converge cleanly. The tempting
fallback optimizer path was rejected because it produced an implausible
objective. The final fixture is less dramatic but honest: it proves the route
and extractor without turning the test into a fragile optimization stunt.

The release checker also needed one generator update so count-structured `mu`
rejection rows can serve as future debug-fixture sources after the first-four
queue moved beyond the old structured-family sidecar.

## 10. Known Residuals

The two moved rows remain local fit-only recovery evidence. They are not
interval-ready, coverage-ready, `inference_ready`, `supported`,
bridge-supported, q2/q4, REML/AI-REML, labelled-covariance support,
location-shape support, location-inflation support, or public support.

The next generated first-four queue is design-first: ordinal phylo `mu`,
truncated-NB2 relmat `hu`, labelled count `mu` q2, and simultaneous-provider
count `mu`. None of these candidates authorizes compute or support-cell
movement without row-specific evidence and Rose/Fisher/Grace review.

## 11. Team Learning

Rose: when support rows move out of a rejection sidecar, update the prose that
describes the sidecar immediately; stale narrative is as risky as stale TSV.

Fisher: practical v1.0 accounting can reach 80% without lowering the inference
bar, as long as the row itself carries the negative denominator and coverage
language.

Grace: generator source lists should include every rejection sidecar that can
feed the next candidate queue; otherwise the queue works until it advances.

## Next Actions

The Q-Series v1.0 practical surface is now past the 80% row-accounting target
at 84/104. The next planning step should decide whether to bank another small
post-v1 design contract, pause Q-Series implementation, or pivot to the
broader v1.0 finish plan for `drmTMB` before planning the optional Julia twin
work.
