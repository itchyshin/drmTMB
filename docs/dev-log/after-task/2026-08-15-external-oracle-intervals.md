# After Task: External-oracle validation, including the first cross-package interval guard

## 1. Goal

Make drmTMB's post-fit surface trustworthy against evidence it did not manufacture itself.
The native reader-contract arc (PRs #1027, #1028) stabilised that surface, but every
assertion behind it was self-authored. This task tested the overlap region against
independent oracles — `lme4` and `glmmTMB` — and repaired a red `main` found on the way.

The reader is a contributor deciding how much weight the new comparator evidence carries,
and a maintainer deciding what may be claimed publicly before 0.7.0.

Ben Bolker, author of both comparator packages, independently warned that confidence
intervals are the least reliable part of this class of software
(`FOR-DRMTMB-2026-07-28-bolker-brief.md` §1). He never saw our coverage numbers, so that is
corroboration of caution already encoded, **not** validation of any figure. The task aimed
the sharpest external evidence at exactly that surface.

## 2. Implemented

**PR #1030 — pkgdown reference index (merged, `origin/main@859c0f6e6`).**
The post-merge `pkgdown` run `31842957306` on `main` failed at `build_reference_index()`:
`1 topic missing from index: "native_reader_contracts"`. The reader arc added
`man/native_reader_contracts.Rd` as a doc-only `@name` topic while `_pkgdown.yml` was one of
that arc's lane fences, so the topic landed without its index entry, the site stopped
deploying, and every later push to `main` would have repeated the failure. Registered the
topic in the `Model fitting and post-fit tools` reference section, immediately before
`check_drm`.

**PR #1031 — external-oracle harness (open, `00bff3227`).** Three test files:

- `tests/testthat/test-comparators-external-oracle.R` — point agreement against the matched
  `lmerMod` twins `fm_us1_lmer` and `fm_diag2_lmer`, plus **interval** agreement against
  `lme4`'s shipped `fm1P`, plus the `exp`/`tanh` transformation contract.
- `tests/testthat/test-reader-oldfit-compat.R` — the stored-old-fit backward-compatibility
  pattern from issue #859, applied to drmTMB's own fits.
- `tests/testthat/test-profile-shape-boundary.R` — pins a limitation rather than a feature.

Both corpora are read through `find.package()` at test time. Nothing is vendored:
`glmmTMB` is AGPL-3 and this package is GPL (>= 3). `lme4` and `glmmTMB` were already
accepted `Suggests`, so no dependency changed.

## 3a. Decisions and Rejected Alternatives

**Scope was cut before work began, on the repo's own recorded evidence.** `AGENTS.md`
records Arc A (2026-07-25) attempting this direction and closing PARTIAL because "the
brief's arithmetic was false": of the 176-cell pool, 122 structured, 18
`response_missingness` and 7 non-structured bivariate cells have no external comparator in
existence; parity reaches ~15 cells ever and 6 are wired. That ceiling was accepted rather
than re-litigated. The arc was rescoped to the one thing Arc A never attempted —
cross-package **interval** agreement — plus the deferred reader workflows of issue #60.

**No ledger row.** `docs/design/242-external-comparator-evidence-class.md` requires every
`external_comparator` `claim_boundary` to state it does not cover intervals, enforced at
`tools/tests/test_capability_ledger.py:2997`. Recording interval evidence would require
amending that policy. Rejected doing so inside this task: the evidence lands as a test-only
regression guard, and the amendment is proposed separately with the measured numbers in hand.

**Rejected: asserting REML interval parity.** drmTMB's REML point estimates and logLik match
`lme4` closely, but a REML-vs-REML profile spot check showed real gaps on three of four
targets. No REML interval claim appears anywhere.

**Rejected: building a non-monotone profile detector.** `badprof.rds` exposes a real gap,
but closing it is a separate arc with its own evidence. The task pins the limitation instead.

## 4. Files Touched

Created:
- `tests/testthat/test-comparators-external-oracle.R`
- `tests/testthat/test-reader-oldfit-compat.R`
- `tests/testthat/test-profile-shape-boundary.R`
- `docs/dev-log/external-oracle/{candidates.tsv,estimator-alignment.md,oldfit-compat.md,profile-shape-boundary.md,rose-audit.md}`
- `docs/dev-log/after-task/2026-08-15-external-oracle-intervals.md` (this file)

Modified:
- `_pkgdown.yml` (one line, PR #1030)
- `docs/dev-log/check-log.md`

None of the five receipt-pinned files was touched: `R/methods.R`, `R/drmTMB.R`,
`src/drmTMB.cpp`, `tests/testthat/test-zero-one-beta.R`,
`tools/run-lane-c-c17c1-c14-model15-compatibility.R`.

## 5. Checks Run

| Check | Outcome |
| --- | --- |
| `test-comparators-external-oracle.R` | 28 pass, 0 fail, 0 skip |
| `test-reader-oldfit-compat.R` | 15 pass, 0 fail, 0 skip |
| `test-profile-shape-boundary.R` | 25 pass, 0 fail, 0 skip |
| `test-reader-public-schema.R` (baseline) | 34 pass, no skips |
| `test-reader-journeys.R` (baseline) | 53 pass, no skips |
| `test_dir(package = "drmTMB")` (independent, Rose) | 176 pass / 0 fail / 0 skip / 0 error |
| `tools/check-reader-contracts.R` | `Reader vignette contract: OK` |
| `tools/capability_ledger.py --check` | `OK (31 generated outputs)` |
| ledger unit tests | 73 pass, `C17 current-source compatibility PASS` |
| `pkgdown::check_pkgdown()` | `No problems found` (aborts without the fix) |
| `pkgdown::build_reference_index()` | completes; topic present in rendered index |

**Not yet done:** CI on PR #1031's exact head, and the post-merge `pkgdown` deploy on `main`.
See §10.

## 6. Tests of the Tests

Every new assertion was checked for non-vacuity rather than assumed:

- **Interval bound.** Injecting a 5.643e-4 discrepancy fails **4 of 4** targets. Refitting
  the same model with `REML = TRUE` fails **3 of 4** by 1.800, 0.3985 and 1.928e-2 against a
  5e-4 budget. ML passes with worst case 3.114e-4 (62% of budget).
- **Failure diagnostics.** `expect_abs_close()` was checked by forcing a failure; the message
  names its target (`max abs diff [sigma profile CI: drmTMB vs lme4 fm1P]`).
- **pkgdown fix.** Verified in both directions — the check aborts without it and passes with it.
- **Skips.** Confirmed 0 skips suite-wide, so no new test is silently inert.

## 8. Consistency Audit

An adversarial audit gated the change and returned **NOT-DONE on three claims (3 × P0)**.
All three were defects in the written claims and one artifact, not in the tests:

1. `candidates.tsv` still asserted `fm_nest` was `EXPRESSIBLE` with the false note "drmTMB
   supports nested structures via formula expansion", while the commit message, check-log
   and PR body each independently claimed it had been corrected. drmTMB in fact rejects
   nested `(1 | Subject/fDays)`. Row now reads `NOT_EXPRESSIBLE` with the verbatim rejection.
2. The bound described as "5e-4 absolute" was **relative** — under testthat edition 3,
   `expect_equal(tolerance = )` routes to waldo — permitting absolute slack up to 2.6e-2,
   40× looser than the prose claimed. Converted to `expect_lt(max(abs(...)))`.
3. The claim that `fm1P`/`fm1B` are ML-derived was **withdrawn**. A converged REML/`bobyqa`
   refit reproduces `fm1P` to 5.63e-5, better than two of three ML reconstructions; the
   apparent 13× ML-vs-REML ratio is an optimizer artifact, with signal-to-noise about 1.1.

A re-audit confirmed all three closed and surfaced two further P2s (a stale comment naming
the wrong worst target; a lost failure diagnostic), both fixed. `estimator-alignment.md`
now carries a superseded banner scoped to the withdrawn section, with its body preserved
verbatim as the record of how the inference failed.

## 9. What Did Not Go Smoothly

- **Sub-agent tool grants were not audited at dispatch.** `reproducibility_engineer`,
  `inference_reviewer` and `math_consistency_reviewer` are review-only agent types with no
  Write/Edit grant. The plan assigned them implementation slices; they would have read as
  correctly routed and simply produced nothing. Caught before dispatch and rerouted to
  tool-capable agents carrying the same lens.
- **A sub-agent wrote into the protected primary checkout.** The oracle test file was written
  to `drmTMB/tests/testthat/` instead of the worktree — a checkout that is dirty and 999
  commits behind `main`, so the test was also validated against stale source. Caught by
  reading the returned path, not by any gate. Relocated, protected checkout confirmed clean,
  test re-run against `origin/main`.
- **A PR based on a non-main branch gets no CI at all.** `R-CMD-check` triggers on
  `pull_request: branches: [main, master]`. PR #1031 was first opened against the pkgdown
  branch and ran nothing. Retargeting the base did not trigger it either; only a rebase and
  push did.
- **A force-push did not always trigger a fresh run**, leaving an in-flight run pinned to a
  superseded commit — exactly the "nearby green badge" trap the prior lane warned about.
- **A routing commitment was honoured on one of three eligible slices.** The plan committed
  three bounded, read-only/mechanical slices to the scout tier; only the recon slice was
  dispatched that way. The pkgdown registration and the mechanical verification were run
  inline by the orchestrator because both were short, already fully specified, and needed to
  interleave with decisions the orchestrator was holding. That is a defensible call but it
  was not recorded at the time, which is the actual defect — an unrecorded reason is
  indistinguishable from an unnoticed omission.
- **Four slices ran under a different agent type than the plan names**, because of the
  tool-grant problem above. The plan's slice table still lists the review-only lenses, so a
  reader of the plan alone would believe the dedicated specialists ran. This report is the
  only landed record of the substitution.

## 10. Known Residuals

- **PR #1031 CI on its exact head is outstanding.** Verify with
  `gh run view <id> --json headSha` that the run's SHA equals the PR head before trusting it.
- **The `main` pkgdown deploy is merged but unconfirmed.** The first post-merge run skipped
  because its triggering `R-CMD-check` was cancelled by concurrency. Closure requires
  `R-CMD-check` green on `main`, then `pkgdown` green.
- **Rose's 5 × P1 and 4 × P2 findings remain open by choice**, recorded in
  `docs/dev-log/external-oracle/rose-audit.md`. They need a triage decision.
- **Old-fit compatibility is a within-version guarantee only.** No real older-release drmTMB
  fit artifact exists in the repo; freeze one once 0.7.0 ships.
- **`fm1P` provenance is unrecoverable** and the suite deliberately does not depend on it.
- **Issue #60's real-analysis workflows are deferred** to their own checkpoint.

## 11. Team Learning

Two process fixes worth promoting:

1. **Audit the tool grant, not just the model tier, when dispatching a slice.** A review-only
   lens handed implementation work reads as correctly routed and cannot write. This is the
   second recorded instance.
2. **Sub-agent briefs must state the working directory as the only writable root, and the
   orchestrator must verify the returned path.** A protected checkout is one `cd` away.

Also worth keeping: the adversarial gate paid for itself here. Three claims that read as
well-evidenced were wrong, and two of the three were wrong in the *prose* while the code was
fine — a failure mode self-review does not catch.

## 12. Cross-Product Coverage

No likelihood, estimand, formula grammar, family, random-effect, phylogenetic, spatial or
meta-analysis behaviour changed, so no design doc in that set needed updating. No capability
ledger status changed. `_pkgdown.yml` changed only to register an existing documentation
topic. The response-missing, joint-MI, MSPL, calibration, Julia and 0.7 CRAN-ladder lanes
were fenced and untouched.
