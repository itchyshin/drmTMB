# After Task: Version the Bernoulli 97.5% calibration path

> **Superseded interpretation (2026-10-19):** This report records an earlier, incorrect reading of the fitted-interval target. The approved two-look protocol uses 95% fitted profile intervals and 97.5% exact Monte Carlo confidence intervals. The 97.5%-profile run described here is historical exploratory evidence and cannot authorize another look. The earlier 95%-profile archive has the correct nominal interval level, but it lacks the metadata and current-source identity required for replay. See `../general-sd-regression/staged-calibration-contract.md` and `2026-10-19-bernoulli-calibration-contract-reconciliation.md`.

## 1. Goal

Preserve the original harness and build a separately pinned 97.5%-profile route after the interval contract was misread. This report now marks that route as historical; the approved current-source first look uses 95% fitted profiles and 97.5% Monte Carlo confidence intervals.

## 2. Implemented

The original `worker.R`, `prepare.R`, `run.py`, and `summarize.R` remain unchanged. The versioned `worker-0975.R` requested a 97.5% profile interval, verified the level returned by `confint()`, and recorded it in every result row. New `prepare-0975.R`, `run-0975.py`, and `summarize-0975.R` bound that historical route to a distinct source registry. The first-look replay rejects missing, non-finite, mixed, or wrong profile levels. The stage-two runner and adapter-qualification probe then used the versioned worker and required its result row to record 0.975; the current approved adapter now uses `worker-095.R` and requires 0.95.

## 3a. Decisions and Rejected Alternatives

At the time of this work, I incorrectly read the 0.025 spending at each look as requiring 97.5% fitted profile intervals. The approved contract instead uses 95% fitted profiles and 97.5% exact Monte Carlo intervals for the coverage and false-positive rates. The 97.5%-profile run is retained as historical exploratory evidence. The archived 95%-profile rows use the approved nominal level, but the current replay rejects them because they lack explicit level metadata and their model-source hashes do not match the current candidate. No profile endpoint was relabelled and no staged decision threshold changed.

## 4. Files Touched

Added `worker-0975.R`, `prepare-0975.R`, `run-0975.py`, `summarize-0975.R`, and `test-profile-level-harness.py`. Updated the stage-two profile-level validator and first-look replay, stage-two and qualification worker selection, Python/R regression tests, staged-calibration contract, stage-two execution design and README, G2 gate, check log, and this report. No public API, package likelihood, or pkgdown page changed.

## 5. Checks Run

- `python3 -m unittest tools/general-sd-regression/native-calibration-stage-two/test_stage_two.py`: **31 tests passed**.
- `python3 tools/general-sd-regression/native-calibration/test-profile-level-harness.py`: **4 tests passed**, including a check that the original worker, preparer, and runner have no diff from `HEAD`.
- `Rscript .../test-stage-two-rules.R ...`: **pass**, `STAGE_TWO_R_RULES_PASS offsets=3 metrics_tolerance=1e-12`.
- `Rscript .../test-combine-stage-two.R ...`: **pass**, expected marker `STAGE_TWO_LEGACY_PROFILE_REJECT_PASS` with nonzero subprocess status.
- Python byte-compilation for the versioned runner and stage-two adapter files: **pass**.
- R parse checks for the versioned worker, preparer, summarizer, and replay files: **pass**.
- `git diff --check`: **pass**; whitespace check: **pass**, eleven changed/new files.
- `Rscript .../check-after-task.R`: **structure check passed**; its acceptance-ledger audit correctly reported nine unmet programme gates, so this checkpoint does not close the approved goal.
- Prose-style check: **0 findings**; slop check: **4 hits per 908 words, 0 em dashes, 0 findings**.

## 6. Tests of the Tests

The new profile-level test failed before the validator existed with `could not find function`; it passed after implementation. Positive and negative cases cover 0.975, missing, 0.95, mixed, `NA`, and infinite values. The subprocess regression replays the retained historical fixture and confirms it stops before writing a combined decision. A second Python negative control changes a qualified probe result to 0.95 and confirms that qualification replay rejects it.

## 7a. Issue Ledger

The open-issue search `gh issue list --state open --search 'Bernoulli random effect SD calibration' --limit 20` returned no matches. No issue was opened, edited, closed, or commented on.

## 8. Consistency Audit

The versioned historical `worker-0975.R` path and its validators required `profile_level = 0.975`. The current `worker-095.R` route and stage-two adapter require `profile_level = 0.95`, matching the frozen contract. The original 95% files remain unchanged, and no saved historical endpoint has been relabelled. The 97.5%-profile results cannot authorize another look. The code change affects internal calibration validation only, so user-facing examples, README capability status, and pkgdown navigation did not need edits.

## 9. What Did Not Go Smoothly

The first updated Python run exposed old no-fit fixtures without a `profile_level` field. Those fixtures model the historical 0.975 worker output, and a dedicated negative case proves that changing its value to 0.95 fails that version-specific validation. The first attempt to enforce the rule in the frozen helper was reverted after the execution design confirmed that the first-look harness must remain untouched; the guard lives in the versioned summarizer and replay adapter.

## 10. Known Residuals

This is protocol plumbing only. The 97.5%-profile experiment has run and is historical; a current-source 95%-profile timing pre-run has since completed, but it is not calibration. A complete current-source 95% first look, recovery simulation, profile calibration, and second-look campaign remain outstanding. The current source and installed Bernoulli library still need a matched source-to-binary receipt for any future campaign. This work does not complete G2 or the broader cross-family, cross-effect, two-engine goal.

Next: prepare a source-bound current-source 95% first look using fresh frozen seeds, after a campaign-specific runtime and memory check. Recompute the frozen decision from all attempts before preparing a disjoint second look. If a projected run exceeds three hours, obtain the required pre-run result and new approval first.

## 11. Team Learning

An interval's confidence level is part of the result identity and must survive preparation, execution, summarization, and replay. Keep corrections to sealed calibration protocols in a new, hash-pinned version rather than changing the bytes that produced historical results.

## 12. Cross-Product Coverage

This slice covers only native Bernoulli calibration interval-level integrity. It does NOT cover a corrected 3,000-seed recovery, calibrated uncertainty, Julia parity, other response families, or other random-effect types.

## Prose Assessment

**Style:** 3/10, medium confidence. **Genre/coverage:** technical after-task report, read in full. **Evidence/repair:** the correction note now states the approved 95% fitted and 97.5% Monte Carlo levels; the residuals distinguish the historical 97.5%-profile experiment from the fresh current-source run still required. No wording change was needed. **Gates:** science = pass for the corrected interval contract and its separation from coverage-rate uncertainty; facts = pass against the listed code, test outputs, and later source-backed reconciliation; references = not applicable because the report cites no external sources. **Provenance:** self-review of this corrected saved draft, version dated 2026-10-19; related calibration reviews and the protocol were already read.
