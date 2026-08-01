# Lane C C17-B — mc-0577 zero-one-beta zoi slope receipt

## 1. Goal

Revalidate and prepare only `mc-0577` for `implemented` / `point_fit_recovery`:
ML `zero_one_beta()` with `bf(y ~ x, sigma ~ 1, zoi ~ x + (0 + x | id), coi ~ 1)`.

## 2. Implemented

No likelihood, formula grammar, estimator, or fitting behaviour changed. The
existing exact ordinary `zoi` slope-only q1 route was revalidated on current
source. Its family documentation, likelihood contract, link contract, and
missing-response diagnostic now describe the already implemented scope
consistently. Fresh R4 Fisher, Noether, and Rose review returned GO, and the
candidate ledger is promoted only at `point_fit_recovery`.

## 3a. Decisions and Rejected Alternatives

The fixed and random `zoi` predictors must be the same raw `x` symbol. Transformed
or mismatched predictors, a random intercept or intercept-plus-slope random term,
labels, covariance, other random dpars,
structured terms, missing responses, REML, profiles, intervals, coverage, and
inference-ready claims remain outside this receipt.

## 4. Files Touched

The scoped contract edits are in `R/family.R`, `R/drmTMB.R`,
`man/zero_one_beta.Rd`, `docs/design/03-likelihoods.md`, and
`docs/design/19-family-link-contract.md`. The authenticated rerun has its own
runner and evidence directory. The remaining changes are
`docs/dev-log/dashboard/capability-ledger/{cells,evidence,transitions}.tsv`, the
ledger's C17-B count guard, generated canonical ledger outputs, and this
receipt. `docs/dev-log/check-log.md` is explicitly deferred to PR #869 and was
not touched.

## 5. Checks Run

At source `ff5db60616e7ca362aa5f0c6d5817ab04e2baad9`, the focused command
`R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter =
"zero-one-beta", reporter = "summary")'` passed. It verifies the complete
three-part mixture plus normal-prior objective at `1e-8`, its gradient at `2e-5`,
an active numerical-guard objective probe at `1e-8`, the default-enabled
log-`sigma` clamp configuration (`[-12, 12]`, margin `3`), and nonzero
`log_sd_zoi` objective dependency. The guard probe activates the clamped
log-`sigma` path, guarded `mu` transform, and beta-shape floors together.

The source-bound runner
`tools/run-lane-c-c17b-zob-zoi-slope-current-source-recovery.R` (SHA-256
`c8fa117d29fabeaf17062204f06b6fa7a603b75cfcc8e3757ff1f996e9afcf87`) reran seeds
`2026073801:2026073804`.  It retained 4/4 attempts: convergence `0`, `pdHess=TRUE`,
maximum gradients `0.000326`--`0.003039`, no boundary hits, mode correlations
`0.667`--`0.838`, positive zero/one/interior support within every group, and mean
SD relative error `0.134522 <= 0.40`. Its provenance records the source SHA,
runner SHA-256, relevant source blobs, loaded namespace, UTC interval, exact
command, and dirty-state receipt. Empty terminal `error` cells in the retained
TSV files were normalized to the explicit sentinel `none` for the repository
whitespace gate; numerical fields and runner/source hashes were not changed.
Its boundary diagnostic remains separate.

`python3 tools/capability_ledger.py --check` and `git diff --check` pass on the
post-promotion candidate. The final stale-contract scan covers `README.md`,
`ROADMAP.md`, `R/`, `man/`, `vignettes/`, and `docs/` for fixed-only,
all-atom-effects-blocked, and atom-slope-planned wording. Historical rows are
retained only with explicit supersession; live user/status surfaces name the
exact same-raw-symbol point-fit-only exception.

The recorded search patterns were `zoi.{0,50}random`,
`random.{0,50}zoi`, `zero.one.beta.{0,45}random`,
`random.{0,45}zero.one.beta`, `sigma/zoi/coi random effects`, and
`planned bounded-response zoi/coi random slopes`. Rose's final targeted re-read
classified the surviving matches as exact-neighbour limitations or explicitly
historical statements, not live contradictions.

The full `devtools::test(reporter = "summary")` run completed the package suite.
It found no C17 failure and ended with five failures confined to stale line-number
pointers in `docs/dev-log/dashboard/estimator-surface-conformance.tsv`. The cited
REML error strings and behaviour were unchanged; their `R/profile.R` and
`R/drmTMB.R` source lines had moved. After updating only those five pointers,
`devtools::test(filter = "estimator-surface-conformance")` passed all
expectations. The full run's 72 expected warnings and 25 Julia/workflow skips
remain unrelated to this lane.

## 6. Tests of the Tests

The likelihood oracle includes the zero, one, and interior beta mixture pieces and
the normal random-slope penalty, rather than comparing a partial atom likelihood.
The altered-`log_sd_zoi` expectation proves the random-SD parameter is live.

## 7a. Issue Ledger

Following fresh D-43 GO, `mc-0577` is the sole cell changed from
`not_implemented` / `backlog` to `implemented` / `verified` /
`point_fit_recovery`, with the exact C17-B contract and recovery evidence IDs.
No other cell is a promotion candidate.

## 8. Consistency Audit

No likelihood, formula grammar, Lane A/B material, structured/q2-plus row,
profile, interval, coverage, or check-log change was made. The only executable
source edit improves the existing missing-response rejection message; it does
not admit a new route. The zero-true-SD run is recorded as
`BOUNDARY_DIAGNOSTIC_ONLY`, not recovery evidence.

The July evidence directory remains byte-for-byte historical relative to
`origin/main`; the current rerun lives in its own 2026-08-01 directory. After
promotion, the model-surface inventory is the canonical
`328 implemented / 340 rejected by design / 19 not implemented`. No other cell
status, evidence tier, profile, interval, coverage, or support claim changed.

## 8a. Documentation, pkgdown, and issue disposition

`zero_one_beta()` roxygen, `man/zero_one_beta.Rd`, the README, formula vignette,
formula-policy table, known-limitations register, likelihood/link contracts,
and Roadmap supersession rows now name the exact same-raw-symbol slope-only
gate and its exclusions. This is documentation synchronization for existing
syntax, not a parser or formula-grammar behaviour change. The generated
capability surface is refreshed by the canonical ledger tool. A live GitHub
issue search for `mc-0577` returned no
dedicated issue, so there is no issue to close or relabel. PR #869 remains open
and conflicting, owns `docs/dev-log/check-log.md`, and is not modified here.

## 9. What Did Not Go Smoothly

The first candidate incorrectly overwrote source-SHA fields in the historical
July evidence and left stale contract wording. The initial D-43 panel correctly
blocked it. The repair restored the July files, committed the scoped contract and
runner first, reran the frozen fixture against that immutable commit, and kept
the ledger unpromoted while a fresh panel reviewed the result. In review round
R4, Fisher and Noether returned GO. Rose returned BLOCK only because seven
reader-facing surfaces still stated the historical blanket atom-effect boundary.
Those README, implementation-map, distribution-family, model-map, source-map,
design-map, and NEWS statements now record the exact `zoi` q1 exceptions and
retain the broader limitations as warnings rather than blocks. Rose's first R4
re-read found two additional historical blanket statements in the family
registry and readiness matrix; both are now explicitly superseded for the same
two exact `zoi` gates and retained only for neighbouring requests.

Draft PR #882's first release CI run failed its ledger unit step because two
tests still froze the pre-C17 census, one reader-surface assertion expected the
pre-repair readiness sentence, and C14's strict source fingerprint included the
C17 missing-response diagnostic wording. The repair updates the explicit
`328 / 340 / 19`, frozen-recovery `175`, and total-recovery `176` invariants,
adds a direct C17-B promotion test, and normalizes only that pre-likelihood abort
message to its C14 wording before the C14 fit-source hash. All builder, carrier,
extractor, and model-15 likelihood bytes remain fingerprinted. The complete
47-test Python ledger suite, generator check, and runtime check then passed.

## 10. Known Residuals

This is one ordinary univariate ML zoi slope-only q1 cell at the frozen fixture.
It makes no claim about zero true SD, intercept-plus-slope, covariance, labels,
other random-effect endpoints, missingness, REML, profiles, intervals, coverage,
calibration, inference readiness, or broader support.

## 11. Team Learning

For atom-mixture random effects, retain zero and one support separately by group
and attach the rerun source SHA to every attempt; aggregate atom support alone is
not enough to authenticate the exact fixture.

## 12. Cross-Product Coverage

The claim is restricted to complete-response model type 15 with fixed `sigma` and
`coi`, one independent ordinary `zoi` slope, and ML-Laplace fitting. It does NOT cover
bivariate, association, high-q, structured, missing-response, REML, interval, coverage,
or any other family, endpoint, provider, or inference route.

## 13. Current verdict and next action

The recovery evidence and promotion are GO at the exact scoped point-fit level.
Fisher and Noether returned R4 GO. Rose retained R4 BLOCK after the first re-read
because two design statements survived; after those statements were repaired,
Rose's second re-read returned GO. `mc-0577` is now
`implemented / verified / point_fit_recovery`, and the generated ledger passes
its canonical check at `328 / 340 / 19`. The next action is a focused PR. No
merge may occur without fresh user authority after exact-head CI succeeds.
