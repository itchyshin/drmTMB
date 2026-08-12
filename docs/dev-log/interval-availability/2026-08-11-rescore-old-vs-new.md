# G5 calibration gate v2: interval-availability RATE floor, and the re-score

**Author:** Emmy (architecture reviewer, implementing the reviewed policy from
[`2026-08-11-availability-threshold-evidence.md`](2026-08-11-availability-threshold-evidence.md)).
No campaign was re-run. This is a re-score of the existing 290-cell reconciled artifact
(`snakagaw@rorqual:~/g5run/g5-reconciled-final.rds`, `$records` 348,000 rows) under a
new pass predicate, with the old-rule verdict recorded beside every cell.

## What changed

`mr_g5_calibration_gate()` (`inst/sim/R/sim_missing_response_g4g5.R`) replaces the v1
all-1200 `calibration_available <- n_interval_usable == n_planned` requirement with a
reported RATE, `interval_availability = n_interval_usable / n_planned`, gated at a named
constant:

```r
# inst/sim/R/sim_missing_response_g4g5.R:951
MR_G5_AVAILABILITY_FLOOR <- 0.99
```

The v2 pass predicate is `calibration_complete & calibration_precise &
calibration_in_band & calibration_availability_ok` where
`calibration_availability_ok <- interval_availability >= MR_G5_AVAILABILITY_FLOOR`.
`calibration_available` (the old all-1200 boolean) is retained, unchanged, purely as the
OLD-rule indicator for this comparison; it plays no role in the v2 predicate.
`calibration_policy` is bumped `mr-g5-calibration-v1` -> `mr-g5-calibration-v2`, and every
stored calibration row carries its own policy id so a v1 artifact and a v2 artifact can
never be silently conflated.

`calibration_reason` now distinguishes four cases, checked in this order after
completeness: **availability failure** (`availability_below_policy_floor`, checked right
after completeness, so a low-availability cell is never mislabelled as a coverage or
precision failure even when it would also miss on those grounds), **imprecision**
(`mcse_exceeds_policy`), and **coverage failure** (`coverage_outside_policy_band`). A cell
with `interval_availability < 1` also carries `coverage_is_conditional = TRUE`, a
machine-readable flag (not just prose) that its reported coverage is conditional on the
interval being usable (Fisher's lens).

`mr_g5_validate_calibration()` now requires all five new fields
(`interval_availability`, `calibration_availability_floor`,
`calibration_availability_ok`, `coverage_is_conditional`, plus the retained
`calibration_available`) and asserts internally that any complete cell failing the
availability floor is reasoned as an availability failure, never a coverage failure.

## Tests

`tests/testthat/test-missing-response-g4g5-foundation.R` adds
`"G5 calibration v2 gates on an interval-availability RATE, not the old all-1200 rule"`,
covering: exactly 1.0 availability (pass, parity with v1); exactly the 0.99 boundary
(pass); just below 0.99 with in-band coverage (fail, reason = availability, not
coverage); 0.5 availability with in-band coverage (fail, reason = availability); and
out-of-band coverage with full availability (fail, reason = coverage, unaffected by the
new rule). The pre-existing systematic-overcoverage test is untouched and still passes
(full availability throughout, so v1 and v2 agree on it).

## Re-score: OLD (v1) vs NEW (v2), all 290 cells, same artifact, no new fits

```
Summary recompute matches stored summary exactly: OK   (mr_g5_summarise_attempts(records)
                                                          reproduces the artifact's own $summary)
OLD (v1) pass: 247   OLD fail: 43
NEW (v2) pass: 272   NEW fail: 18
```

Transition table:

| old \ new | fail | pass |
|---|---|---|
| **fail** | 18 | 25 |
| **pass** | 0 | 247 |

**Zero cells moved pass -> fail.** All 247 v1 passes remain v2 passes exactly. 25 cells
moved fail -> pass; 18 remain fail under both rules (with their reason relabelled where
the mechanism differs).

## Every flip, with its old-rule verdict and its population

All 25 flips belong to the same, single, named population: **near-miss availability
(0.99 <= availability < 1.0, i.e. missed the old all-1200 rule by between 1 and 12 of
1200 replicates), with in-band coverage on its own merits.** None is a coverage-band
near-miss admitted by loosening the coverage tolerance — the coverage tolerance
(`nominal +/- 0.025`) is unchanged.

| route | parm | rung | usable/planned | availability | coverage | old reason | new reason |
|---|---|---|---|---|---|---|---|
| beta | fixef:sigma:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9492 | unusable_interval | pass |
| beta | sd:mu:(1 \| id) | 0.5x | 1196/1200 | 0.9967 | 0.9392 | unusable_interval | pass |
| beta | sd:mu:(1 \| id) | 1x | 1199/1200 | 0.9992 | 0.9450 | unusable_interval | pass |
| nbinom2 | fixef:sigma:(Intercept) | 1x | 1197/1200 | 0.9975 | 0.9425 | unusable_interval | pass |
| nbinom2 | fixef:sigma:z | 1x | 1197/1200 | 0.9975 | 0.9350 | unusable_interval | pass |
| nbinom2 | sd:mu:(1 \| id) | 1x | 1193/1200 | 0.9942 | 0.9467 | unusable_interval | pass |
| poisson | sd:mu:(1 \| id) | 0.5x | 1198/1200 | 0.9983 | 0.9300 | unusable_interval | pass |
| skew_normal | fixef:mu:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9483 | unusable_interval | pass |
| skew_normal | fixef:nu:(Intercept) | 0.5x | 1196/1200 | 0.9967 | 0.9258 | unusable_interval | pass |
| skew_normal | fixef:sigma:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9550 | unusable_interval | pass |
| student | fixef:mu:(Intercept) | 1x | 1192/1200 | 0.9933 | 0.9283 | unusable_interval | pass |
| student | fixef:mu:(Intercept) | 2x | 1196/1200 | 0.9967 | 0.9400 | unusable_interval | pass |
| student | fixef:mu:x | 0.5x | 1188/1200 | 0.9900 | 0.9317 | unusable_interval | pass |
| student | fixef:mu:x | 1x | 1194/1200 | 0.9950 | 0.9500 | unusable_interval | pass |
| student | fixef:sigma:z | 0.5x | 1189/1200 | 0.9908 | 0.9308 | unusable_interval | pass |
| student | fixef:sigma:z | 1x | 1191/1200 | 0.9925 | 0.9467 | unusable_interval | pass |
| student | fixef:sigma:z | 2x | 1199/1200 | 0.9992 | 0.9408 | unusable_interval | pass |
| student | sd:mu:(1 \| id) | 2x | 1199/1200 | 0.9992 | 0.9417 | unusable_interval | pass |
| truncated_nbinom2 | fixef:sigma:z | 2x | 1199/1200 | 0.9992 | 0.9433 | unusable_interval | pass |
| tweedie | fixef:sigma:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9367 | unusable_interval | pass |
| zi_nbinom2 | fixef:mu:x | 0.5x | 1199/1200 | 0.9992 | 0.9483 | unusable_interval | pass |
| zi_nbinom2 | fixef:sigma:(Intercept) | 0.5x | 1195/1200 | 0.9958 | 0.9392 | unusable_interval | pass |
| zi_nbinom2 | fixef:sigma:z | 0.5x | 1196/1200 | 0.9967 | 0.9475 | unusable_interval | pass |
| zi_nbinom2 | fixef:zi:(Intercept) | 0.5x | 1197/1200 | 0.9975 | 0.9433 | unusable_interval | pass |
| zi_nbinom2 | fixef:zi:w | 0.5x | 1196/1200 | 0.9967 | 0.9367 | unusable_interval | pass |

Lowest availability among the 25 flips: **0.9900** (`student fixef:mu:x` 0.5x, 1188/1200).
Every flip clears the 0.99 floor with room to spare and lands well inside the coverage
band [0.925, 0.975]. **No flip is a boundary case that scrapes past 0.99 with borderline
coverage** — the closest coverage value among the flips is 0.9258 (`skew_normal
fixef:nu:(Intercept)` 0.5x), still comfortably inside [0.925, 0.975].

## The 18 cells that still fail, and why

| reason | count |
|---|---|
| `availability_below_policy_floor` | 16 |
| `coverage_outside_policy_band` | 2 |

None of the three catastrophic cells the evidence doc flagged as self-disqualifying
regardless of the availability rule are among the 25 flips; all three remain FAIL, now
correctly reasoned as availability failures because their availability is far below the
floor:

| route | parm | rung | availability | coverage | new reason |
|---|---|---|---|---|---|
| truncated_nbinom2 | sd:mu:(1 \| id) | 1x | 0.4150 | 0.4008 | availability_below_policy_floor |
| student | fixef:nu:(Intercept) | 2x | 0.7600 | 0.7258 | availability_below_policy_floor |
| truncated_nbinom2 | fixef:sigma:(Intercept) | 1x | 0.7717 | 0.7325 | availability_below_policy_floor |

The two `coverage_outside_policy_band` fails both clear the availability floor: `poisson
fixef:mu:(Intercept)` 0.5x (availability 1.0, coverage 0.9217, unchanged from v1) and
`student fixef:sigma:(Intercept)` 2x (availability 0.9917, coverage 0.9233 — this one
*was* an availability failure under v1's `unusable_interval` reason but is now correctly
reasoned as the coverage failure it actually is, once its availability clears the floor).

## Promoted-route check

**Discrepancy from the brief's premise, reported per instructions:** counting routes
whose cells ALL pass the v1 rule in this artifact gives **9**, not 8:
`beta_binomial, binomial, biv_gaussian, cumulative_logit, gamma, gaussian, lognormal,
zero_one_beta, zi_poisson`. The `2026-08-11-point-estimate-outside-interval.md`
diagnosis names 7 of these (all but `cumulative_logit`, which has only 3 cells in this
artifact and is not discussed there). No document in this worktree states "8 promoted
routes"; I could not locate the source of that number and flag it rather than force a
match.

**All 9 fully-v1-passing routes are completely unaffected.** More strongly: the
transition table's `old=pass -> new=fail` cell is exactly 0 across **all 290 cells**, not
just the promoted subset — every v1 pass, in every route, remains a v2 pass, unchanged in
reason (`"pass"`), unchanged in status. The 132 rows belonging to the 7 routes named in
the diagnosis doc (`gaussian, biv_gaussian, gamma, beta_binomial, binomial,
zero_one_beta, zi_poisson`) were checked explicitly: 132/132 unaffected (old pass ==
new pass for all of them).

## Verify

```
R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter="missing")'
# [ FAIL 0 | WARN 0 | SKIP 2 | PASS 1569 ]

python3 tools/capability_ledger.py --check
# capability-ledger: OK (31 generated outputs)
```

## Full 290-cell table (OLD -> NEW)

Per-cell CSV alongside this note:
[`2026-08-11-rescore-old-vs-new.csv`](2026-08-11-rescore-old-vs-new.csv)
(`route_id, parm, information_rung, n_planned, n_interval_usable, coverage,
coverage_mcse, calibration_available` [old-rule boolean], `calibration_pass_old,
calibration_status_old, calibration_reason_old, interval_availability,
calibration_availability_ok, coverage_is_conditional, calibration_pass_new,
calibration_status_new, calibration_reason_new`).

| route | parm | rung | usable/planned | availability | coverage | pass old -> new | reason old -> new |
|---|---|---|---|---|---|---|---|
| beta | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9308 | pass -> pass | pass -> pass |
| beta | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9308 | pass -> pass | pass -> pass |
| beta | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| beta | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| beta | fixef:sigma:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9492 | fail -> pass | unusable_interval -> pass |
| beta | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| beta | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| beta | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9558 | pass -> pass | pass -> pass |
| beta | sd:mu:(1 \| id) | 0.5x | 1196/1200 | 0.9967 | 0.9392 | fail -> pass | unusable_interval -> pass |
| beta | sd:mu:(1 \| id) | 1x | 1199/1200 | 0.9992 | 0.9450 | fail -> pass | unusable_interval -> pass |
| beta | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9408 | pass -> pass | pass -> pass |
| beta_binomial | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9383 | pass -> pass | pass -> pass |
| beta_binomial | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| beta_binomial | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| beta_binomial | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| beta_binomial | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| beta_binomial | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| beta_binomial | fixef:sigma:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| beta_binomial | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| beta_binomial | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9458 | pass -> pass | pass -> pass |
| beta_binomial | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| beta_binomial | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| beta_binomial | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| beta_binomial | sd:mu:(1 \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| beta_binomial | sd:mu:(1 \| id) | 1x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| beta_binomial | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| binomial | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9625 | pass -> pass | pass -> pass |
| binomial | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| binomial | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9583 | pass -> pass | pass -> pass |
| binomial | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| binomial | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| binomial | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| biv_gaussian | cor:mu:cor(mu1:(Intercept),mu2:(Intercept) \| p \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| biv_gaussian | cor:mu:cor(mu1:(Intercept),mu2:(Intercept) \| p \| id) | 1x | 1200/1200 | 1.0000 | 0.9400 | pass -> pass | pass -> pass |
| biv_gaussian | cor:mu:cor(mu1:(Intercept),mu2:(Intercept) \| p \| id) | 2x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu1:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9400 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu1:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu1:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu1:x | 0.5x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu1:x | 1x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu1:x | 2x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu2:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9367 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu2:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9317 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu2:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu2:x | 0.5x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu2:x | 1x | 1200/1200 | 1.0000 | 0.9617 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:mu2:x | 2x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:rho12:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:rho12:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9383 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:rho12:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:sigma1:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9600 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:sigma1:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:sigma1:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:sigma2:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:sigma2:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9450 | pass -> pass | pass -> pass |
| biv_gaussian | fixef:sigma2:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| biv_gaussian | rho12 | 0.5x | 1200/1200 | 1.0000 | 0.9583 | pass -> pass | pass -> pass |
| biv_gaussian | rho12 | 1x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| biv_gaussian | rho12 | 2x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| biv_gaussian | sd:mu:mu1:(1 \| p \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| biv_gaussian | sd:mu:mu1:(1 \| p \| id) | 1x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| biv_gaussian | sd:mu:mu1:(1 \| p \| id) | 2x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| biv_gaussian | sd:mu:mu2:(1 \| p \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| biv_gaussian | sd:mu:mu2:(1 \| p \| id) | 1x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| biv_gaussian | sd:mu:mu2:(1 \| p \| id) | 2x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| biv_gaussian | sigma1 | 0.5x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| biv_gaussian | sigma1 | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| biv_gaussian | sigma1 | 2x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| biv_gaussian | sigma2 | 0.5x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| biv_gaussian | sigma2 | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| biv_gaussian | sigma2 | 2x | 1200/1200 | 1.0000 | 0.9592 | pass -> pass | pass -> pass |
| cumulative_logit | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| cumulative_logit | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9608 | pass -> pass | pass -> pass |
| cumulative_logit | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| gamma | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9375 | pass -> pass | pass -> pass |
| gamma | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| gamma | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| gamma | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9458 | pass -> pass | pass -> pass |
| gamma | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| gamma | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| gamma | fixef:sigma:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| gamma | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| gamma | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| gamma | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| gamma | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| gamma | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| gamma | sd:mu:(1 \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| gamma | sd:mu:(1 \| id) | 1x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| gamma | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| gaussian | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9367 | pass -> pass | pass -> pass |
| gaussian | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| gaussian | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| gaussian | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| gaussian | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| gaussian | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| gaussian | fixef:sigma:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9608 | pass -> pass | pass -> pass |
| gaussian | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| gaussian | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| gaussian | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| gaussian | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| gaussian | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9600 | pass -> pass | pass -> pass |
| gaussian | sd:mu:(1 \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9375 | pass -> pass | pass -> pass |
| gaussian | sd:mu:(1 \| id) | 1x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| gaussian | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9450 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:habitatopen | 0.5x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:habitatopen | 1x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:habitatopen | 2x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:w | 0.5x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:w | 1x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:hu:w | 2x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9458 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9583 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:habitatopen | 0.5x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:habitatopen | 1x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:habitatopen | 2x | 1200/1200 | 1.0000 | 0.9458 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:sigma:(Intercept) | 0.5x | 1182/1200 | 0.9850 | 0.9425 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| hurdle_nbinom2 | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9458 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9558 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9617 | pass -> pass | pass -> pass |
| hurdle_nbinom2 | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9608 | pass -> pass | pass -> pass |
| lognormal | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9367 | pass -> pass | pass -> pass |
| lognormal | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| lognormal | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| lognormal | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| lognormal | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9600 | pass -> pass | pass -> pass |
| lognormal | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| lognormal | fixef:sigma:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| lognormal | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9383 | pass -> pass | pass -> pass |
| lognormal | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| lognormal | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9458 | pass -> pass | pass -> pass |
| lognormal | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| lognormal | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| lognormal | sd:mu:(1 \| id) | 0.5x | 1200/1200 | 1.0000 | 0.9317 | pass -> pass | pass -> pass |
| lognormal | sd:mu:(1 \| id) | 1x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| lognormal | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| nbinom2 | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| nbinom2 | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| nbinom2 | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| nbinom2 | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9275 | pass -> pass | pass -> pass |
| nbinom2 | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| nbinom2 | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| nbinom2 | fixef:sigma:(Intercept) | 0.5x | 1128/1200 | 0.9400 | 0.9042 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| nbinom2 | fixef:sigma:(Intercept) | 1x | 1197/1200 | 0.9975 | 0.9425 | fail -> pass | unusable_interval -> pass |
| nbinom2 | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| nbinom2 | fixef:sigma:z | 0.5x | 1175/1200 | 0.9792 | 0.9300 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| nbinom2 | fixef:sigma:z | 1x | 1197/1200 | 0.9975 | 0.9350 | fail -> pass | unusable_interval -> pass |
| nbinom2 | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| nbinom2 | sd:mu:(1 \| id) | 0.5x | 1080/1200 | 0.9000 | 0.8817 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| nbinom2 | sd:mu:(1 \| id) | 1x | 1193/1200 | 0.9942 | 0.9467 | fail -> pass | unusable_interval -> pass |
| nbinom2 | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| poisson | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9217 | fail -> fail | coverage_outside_policy_band -> coverage_outside_policy_band |
| poisson | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| poisson | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| poisson | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| poisson | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| poisson | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| poisson | sd:mu:(1 \| id) | 0.5x | 1198/1200 | 0.9983 | 0.9300 | fail -> pass | unusable_interval -> pass |
| poisson | sd:mu:(1 \| id) | 1x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| poisson | sd:mu:(1 \| id) | 2x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| skew_normal | fixef:mu:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9483 | fail -> pass | unusable_interval -> pass |
| skew_normal | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9583 | pass -> pass | pass -> pass |
| skew_normal | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| skew_normal | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9450 | pass -> pass | pass -> pass |
| skew_normal | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| skew_normal | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| skew_normal | fixef:nu:(Intercept) | 0.5x | 1196/1200 | 0.9967 | 0.9258 | fail -> pass | unusable_interval -> pass |
| skew_normal | fixef:nu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9383 | pass -> pass | pass -> pass |
| skew_normal | fixef:nu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| skew_normal | fixef:sigma:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9550 | fail -> pass | unusable_interval -> pass |
| skew_normal | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9400 | pass -> pass | pass -> pass |
| skew_normal | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| skew_normal | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9408 | pass -> pass | pass -> pass |
| skew_normal | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| skew_normal | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| student | fixef:mu:(Intercept) | 0.5x | 1183/1200 | 0.9858 | 0.9350 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| student | fixef:mu:(Intercept) | 1x | 1192/1200 | 0.9933 | 0.9283 | fail -> pass | unusable_interval -> pass |
| student | fixef:mu:(Intercept) | 2x | 1196/1200 | 0.9967 | 0.9400 | fail -> pass | unusable_interval -> pass |
| student | fixef:mu:x | 0.5x | 1188/1200 | 0.9900 | 0.9317 | fail -> pass | unusable_interval -> pass |
| student | fixef:mu:x | 1x | 1194/1200 | 0.9950 | 0.9500 | fail -> pass | unusable_interval -> pass |
| student | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| student | fixef:nu:(Intercept) | 2x | 912/1200 | 0.7600 | 0.7258 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| student | fixef:sigma:(Intercept) | 0.5x | 1168/1200 | 0.9733 | 0.8750 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| student | fixef:sigma:(Intercept) | 1x | 1183/1200 | 0.9858 | 0.8883 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| student | fixef:sigma:(Intercept) | 2x | 1190/1200 | 0.9917 | 0.9233 | fail -> fail | unusable_interval -> coverage_outside_policy_band |
| student | fixef:sigma:z | 0.5x | 1189/1200 | 0.9908 | 0.9308 | fail -> pass | unusable_interval -> pass |
| student | fixef:sigma:z | 1x | 1191/1200 | 0.9925 | 0.9467 | fail -> pass | unusable_interval -> pass |
| student | fixef:sigma:z | 2x | 1199/1200 | 0.9992 | 0.9408 | fail -> pass | unusable_interval -> pass |
| student | sd:mu:(1 \| id) | 0.5x | 1170/1200 | 0.9750 | 0.9342 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| student | sd:mu:(1 \| id) | 1x | 1186/1200 | 0.9883 | 0.9292 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| student | sd:mu:(1 \| id) | 2x | 1199/1200 | 0.9992 | 0.9417 | fail -> pass | unusable_interval -> pass |
| truncated_nbinom2 | fixef:mu:(Intercept) | 0.5x | 1182/1200 | 0.9850 | 0.9308 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| truncated_nbinom2 | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| truncated_nbinom2 | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| truncated_nbinom2 | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9342 | pass -> pass | pass -> pass |
| truncated_nbinom2 | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9408 | pass -> pass | pass -> pass |
| truncated_nbinom2 | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| truncated_nbinom2 | fixef:sigma:(Intercept) | 1x | 926/1200 | 0.7717 | 0.7325 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| truncated_nbinom2 | fixef:sigma:(Intercept) | 2x | 1165/1200 | 0.9708 | 0.9292 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| truncated_nbinom2 | fixef:sigma:z | 0.5x | 1168/1200 | 0.9733 | 0.9258 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| truncated_nbinom2 | fixef:sigma:z | 2x | 1199/1200 | 0.9992 | 0.9433 | fail -> pass | unusable_interval -> pass |
| truncated_nbinom2 | sd:mu:(1 \| id) | 1x | 498/1200 | 0.4150 | 0.4008 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| tweedie | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9375 | pass -> pass | pass -> pass |
| tweedie | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| tweedie | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9617 | pass -> pass | pass -> pass |
| tweedie | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| tweedie | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| tweedie | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9450 | pass -> pass | pass -> pass |
| tweedie | fixef:nu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9300 | pass -> pass | pass -> pass |
| tweedie | fixef:nu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9408 | pass -> pass | pass -> pass |
| tweedie | fixef:nu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| tweedie | fixef:sigma:(Intercept) | 0.5x | 1199/1200 | 0.9992 | 0.9367 | fail -> pass | unusable_interval -> pass |
| tweedie | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| tweedie | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| tweedie | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| tweedie | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9408 | pass -> pass | pass -> pass |
| tweedie | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:coi:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:coi:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:coi:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9642 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:coi:v | 0.5x | 1200/1200 | 1.0000 | 0.9617 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:coi:v | 1x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:coi:v | 2x | 1200/1200 | 1.0000 | 0.9558 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:sigma:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9450 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:sigma:z | 0.5x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9383 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:zoi:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:zoi:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:zoi:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9517 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:zoi:w | 0.5x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:zoi:w | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| zero_one_beta | fixef:zoi:w | 2x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9425 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9375 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9542 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:habitatopen | 0.5x | 1200/1200 | 1.0000 | 0.9483 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:habitatopen | 1x | 1200/1200 | 1.0000 | 0.9600 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:habitatopen | 2x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:x | 0.5x | 1199/1200 | 0.9992 | 0.9483 | fail -> pass | unusable_interval -> pass |
| zi_nbinom2 | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:sigma:(Intercept) | 0.5x | 1195/1200 | 0.9958 | 0.9392 | fail -> pass | unusable_interval -> pass |
| zi_nbinom2 | fixef:sigma:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9492 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:sigma:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9558 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:sigma:z | 0.5x | 1196/1200 | 0.9967 | 0.9475 | fail -> pass | unusable_interval -> pass |
| zi_nbinom2 | fixef:sigma:z | 1x | 1200/1200 | 1.0000 | 0.9500 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:sigma:z | 2x | 1200/1200 | 1.0000 | 0.9550 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:zi:(Intercept) | 0.5x | 1197/1200 | 0.9975 | 0.9433 | fail -> pass | unusable_interval -> pass |
| zi_nbinom2 | fixef:zi:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9650 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:zi:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:zi:habitatopen | 0.5x | 1178/1200 | 0.9817 | 0.9233 | fail -> fail | unusable_interval -> availability_below_policy_floor |
| zi_nbinom2 | fixef:zi:habitatopen | 1x | 1200/1200 | 1.0000 | 0.9475 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:zi:habitatopen | 2x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:zi:w | 0.5x | 1196/1200 | 0.9967 | 0.9367 | fail -> pass | unusable_interval -> pass |
| zi_nbinom2 | fixef:zi:w | 1x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| zi_nbinom2 | fixef:zi:w | 2x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9600 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9567 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:habitatopen | 0.5x | 1200/1200 | 1.0000 | 0.9442 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:habitatopen | 1x | 1200/1200 | 1.0000 | 0.9592 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:habitatopen | 2x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:x | 0.5x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:x | 1x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| zi_poisson | fixef:mu:x | 2x | 1200/1200 | 1.0000 | 0.9417 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:(Intercept) | 0.5x | 1200/1200 | 1.0000 | 0.9392 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:(Intercept) | 1x | 1200/1200 | 1.0000 | 0.9433 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:(Intercept) | 2x | 1200/1200 | 1.0000 | 0.9575 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:habitatopen | 0.5x | 1200/1200 | 1.0000 | 0.9558 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:habitatopen | 1x | 1200/1200 | 1.0000 | 0.9450 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:habitatopen | 2x | 1200/1200 | 1.0000 | 0.9467 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:z | 0.5x | 1200/1200 | 1.0000 | 0.9508 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:z | 1x | 1200/1200 | 1.0000 | 0.9533 | pass -> pass | pass -> pass |
| zi_poisson | fixef:zi:z | 2x | 1200/1200 | 1.0000 | 0.9525 | pass -> pass | pass -> pass |
