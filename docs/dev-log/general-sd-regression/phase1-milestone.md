# Phase 1 milestone: priority-family slice queue

Set by Shinichi on 2026-11-01. This is a milestone, not the Definition of Done.
`LOOP/lanes/general-sd-regression/GOAL.md` stays the Definition of Done: it
remains open until every required gate passes (G0 to G4 and G6 to G8; G5
interval calibration is deferred and tracked separately). Nothing in this file
closes a gate or promotes a ledger row.

## What the milestone covers

The 30 bounded open slices ranked on 2026-11-01 across Gaussian,
Bernoulli/Binomial, Poisson, NB2 and Gamma (3 to 6 per family, about 98 hours
estimated by reading source, nothing timed). The list is a floor for those five
families, not the whole required universe.

## A slice counts as done only when it has all of

1. A focused test that was red for a stated reason, or a stated probe showing the
   route already worked, and now passes. An exact or dense oracle where one
   exists.
2. The neighbouring tests for its family still pass. Failures are triaged as
   caused by the slice or pre-existing; pre-existing ones are listed, not hidden.
3. An after-task report in `docs/dev-log/after-task/` that states what is not
   covered.
4. A source-hash receipt linked in the direct-SD evidence ledger. Linked is not
   reviewed and is not support.
5. Honest limits: engine named (native or Julia), no calibrated-interval claim,
   no parity claim from one fixture.

## Status at 2026-11-01 (tests and reports only; receipts not yet written)

Admitted or evidenced natively: Gamma correlated animal q2 with coefficient SDs;
Poisson animal slope with Ainv and pedigree (test-only); Gaussian same-group
intercept plus slope; Gaussian unlabelled correlated q2; Gaussian relmat,
coordinate-spatial and animal-slope providers; NB2 relmat and spatial intercept;
Poisson spatial. Not done: receipts for all of the above, Julia counterparts,
the remaining queue items, and the stale-fence test failures listed in the batch
report.

## Wide regression sweep, 2026-11-01 (109 native test files, four chunks)

Families: Poisson, NB2, Gamma, Gaussian, Beta, count-structured, Binomial
(non-Julia). Run with `NOT_CRAN=true`, one thread per process, after the guard
edits listed in the batch after-task reports. 109 of 109 files ran.

Failures found, with attribution (no clean baseline exists in this shared dirty
tree, so "not caused" means the failing route is untouched by these edits):

| File and line | Says | Attribution |
|---|---|---|
| `test-poisson-sd-assembly.R:138` | expects a refusal for Poisson correlated q2 | not caused; route admitted earlier in this tree |
| `test-poisson-slope-sd-assembly.R:34, :39, :42` | expect refusals for Poisson correlated q2, Binomial slope-only, Poisson with `zi` | not caused; routes admitted earlier in this tree |
| `test-beta-binomial.R:373` | expects `sigma ~ 1 + (1 \| id)` to be refused | not caused; beta-binomial untouched |
| `test-nbinom2-location-scale.R:314, :338` | expect old refusal wording for NB2 sigma random slope and labelled term | not caused; `validate_nbinom2_sigma_random_terms` untouched, wording changed by the 2026-10-25 NB2 sigma random-slope work |

Fixed because these edits made them stale: `test-gaussian-sd-slope-regression.R`
(correlated q2 now fits; its two ledger seals were refreshed in
`evidence/gaussian-sd-slope-refresh-20261101/`), `test-poisson-mean.R` (phylo
slope-only now assembles), `test-poisson-slope-sd-assembly.R:29` (same-group now
builds). All stale-fence failures above are left for the owner of those routes to
update; none was loosened to pass.

## Status update, 2026-11-01 evening

Receipts written and linked for the native slices below (fresh test runs, new
`evidence/*-20261101/` directories, 54 appended ledger records, all
`unreviewed`). The reconciler passes: 254 linked rows (was 214), 20,096 without
linked evidence, 295 evidence records. Linked means a receipt is attached; it is
not independent review, support, or a completion percentage.

Slices with test, report and receipt: Gamma correlated animal q2, Gamma crossed
intercepts, Gamma relmat plus iid; Poisson animal slope Ainv/pedigree, spatial,
phylo/relmat slope, additive ordinary, iid plus structured; Gaussian same-group,
correlated q2, structured providers, mu plus sigma joint; NB2 relmat/spatial
intercept, NB2 and Gamma same-group, NB2 phylo/relmat slope; Binomial
probit/cloglog provider pairs, phylo plus animal pair, animal plus spatial pair.

Open: Julia counterparts for all of the above; NB2 sigma-endpoint phylogenetic
SD (held, decision needed: it admits a new public base route `sigma ~ phylo(1 |
sp)`); NB2 spatial slope-only; NB2 marginal simulation for slope SD; Gamma iid
plus animal/phylo/spatial; remaining queue items; stale-fence failures in other
lanes' tests (listed above); independent review of every receipt; interval
calibration (G5, deferred). Nothing is committed.

## Independent review of the day's edits (three read-only reviewers)

Triage is mine; each item is confirmed (reviewer read or reproduced the path) or
plausible. The fixes applied since are listed under "Fixes applied after review"
at the end of this file; the remaining items are still open. The seals must be
rebuilt after any test file changes.

Confirmed:
- Gamma correlated animal q2 (`test-gamma-animal-q2-correlated-sd.R`): the C++
  algebra and reporting check out, but the test has one fixture and no
  likelihood-pinning check, no test of the new refusals, and docs/NEWS say
  "three fixed-seed fits" that are not in the test or the receipt. Ledger grade is
  `recovery`.
- NB2/Gamma same-group test cannot tell the intercept SD formula from the slope
  one: a swapped selector still passes all bands (reviewer emulated it). No oracle.
- Poisson animal slope Ainv/pedigree test has no oracle; a positional bug
  passes its 0.4 band.
- Spatial and Toeplitz name-alignment fixtures use a reflection, which is a
  symmetry of the kernel, so they cannot detect positional misalignment (Poisson
  spatial, NB2 relmat/spatial, Gaussian structured providers). Their oracles
  build the covariance with the helper under test; only the Binomial batch4 file
  discloses this.
- Gaussian ordinary `sd()` plus any q>2 block gives an internal metadata error,
  not a designed refusal; the q3 "stays closed" test has no message pattern.
- Gamma `gamma_same_group_pair` admits any number of scalar terms on any groups
  (crossed slopes, three terms); only crossed intercepts and the two-term
  same-group pair are tested. NEWS overstates crossed slopes.
- Several refusal messages are now false or misleading (Poisson structured-SD
  and ordinary-SD messages; `random-effect-targets.R` mentions a "correlated
  Binomial block" to all families).
- Receipt schema is uneven (only the Poisson receipts carry a grade field).

Plausible: C++ Gamma guard does not check `has_sd_phylo_coef_model`; the Gaussian
sigma-endpoint guard admits untested mixes (mu q2/q3, same-group mu and sigma
intercepts, `meta_V`); NB2/Poisson slope-only structured terms build under
`miss_control(response = "include")` with no tests; unit-diagonal K fixtures
cannot detect K-to-correlation conversion; Poisson correlated q2 oracle
tolerance is 0.5.

Not caused by today's edits: Poisson ZI slope unlock via any `sd()` formula; the
stale-fence failures already listed.

## Fixes applied after review

Applied after the independent review above. None changes a ledger grade, and the
receipts must be rebuilt by the main writer after the test files settle.

- Gaussian ordinary `sd()` combined with a q>2 block is now a clean, designed
  refusal instead of an internal metadata error.
- Gamma same-group pre-guard tightened: it now admits crossed intercepts on
  distinct groups or one same-group intercept plus slope pair only. Crossed
  slopes, a slope on a second group and chains of three or more terms are
  refused.
- The C++ Gamma correlated q2 guard now checks `has_sd_phylo_coef_model`
  (two coefficient SD formulas required), not only `has_sd_phylo_model`.
- Refusal messages corrected: the Poisson structured-SD and ordinary-SD messages,
  and the `random-effect-targets.R` message that mentioned a "correlated
  Binomial block" to every family.
- NB2 ordinary intercept plus structured intercept (relmat, animal, phylo) and
  Poisson `phylo_interaction()` slope-only SD are admitted
  (`test-nbinom2-batch5-sd-regression.R`, `test-poisson-batch5-sd-regression.R`).

Documentation corrected in the same round (`NEWS.md`, `docs/design/01`, `03`,
`18`, `capability-status.md`): the "three fixed-seed fits (0.45 to 0.53)" claim
for Gamma correlated animal q2 is removed, because the test file does not support
a number (it says: fixed-seed fixtures, loose band, no calibration); the Gamma
"crossed ordinary intercept and slope" wording now says crossed intercepts or one
same-group pair; the Poisson NEWS entry names which routes have an oracle
(additive ordinary, ordinary plus structured, phylo/relmat slope: dense Laplace;
spatial: none; animal slope `Ainv`/pedigree: none yet); and the labelled Gamma
density is written out in `03-likelihoods.md`.

Still open from the review: the NB2/Gamma same-group test cannot tell the
intercept SD from the slope SD; the Poisson animal slope `Ainv`/pedigree test has
no oracle; reflection fixtures cannot detect positional misalignment (Poisson
spatial, NB2 relmat/spatial, Gaussian structured providers); the receipt schema
is uneven; and the plausible items (Gaussian sigma-endpoint untested mixes,
slope-only structured terms under `miss_control(response = "include")`,
unit-diagonal K fixtures, Poisson correlated q2 tolerance 0.5).

## Decision during the origin/main merge: what `log_sd_mu_group` reports

Two tests pinned opposite contracts for the TMB report `log_sd_mu_group`. The lane
(2026-10-18, `test-zi-poisson-sd-regression.R`) stored the soft-clamped value so
the report matched predictions. Main (63a703e61, `test-arc-d-sd-overflow-guard.R`)
needs the raw linear predictor, because the R fit-time clamp-hit check
(`R/drmTMB.R`, the `log_sd_mu_group` field scan) fires only when a reported value
leaves the clamp band; a soft-clamped value never does, so under the lane's
version that warning could never fire for SD regression.

Decision: main's contract. All 18 C++ branches now store the raw value in
`log_sd_mu_group` and apply `drm_softclamp_log_sd()` inside `sd_mu_group`; the one
likelihood read of `log_sd_mu_group` (the Poisson branch `log_sd` term) applies the
clamp explicitly, so fitted likelihoods are unchanged. The ZIP test now asserts the
raw report and the clamped SD and predictions. Checked: arc-d, ZIP, Gaussian
random-effect scale, Poisson correlated q2, NB2, Gamma, Gamma correlated q2, Poisson
iid plus structured, Binomial SD integration and lognormal location-scale files pass.

Open inconsistency found during the merge (pre-existing, not changed): a
zero-inflated Poisson model with one independent `mu` slope builds only when an
`sd()` formula is present (`allow_zero_inflated_independent_slope` in
`drm_build_poisson_spec` requires `length(sd_mu_entries) > 0L`), while NB2 admits it
without one. The shared refusal message says the slope is supported. Fixing it
needs fit evidence for the plain zero-inflated Poisson slope first.

## Other-lane uncommitted work preserved during the merge (not committed here)

Eleven files modified by another lane (not this lane) were set aside before the
merge in stash commit `8f3daba95e22e9c0eb79b0d68edb94e8d76ec1f1`
(`claude-sd-merge-20261101-otherlane-docs`): `docs/dev-log/known-limitations.md`,
`docs/dev-log/team-improvements.md` and nine vignettes (count-nbinom2,
distribution-families, formula-grammar, julia-engine, location-scale-scale,
model-map, spatial-models, structural-dependence, which-scale). Re-applying them
after the merge conflicted in seven files, because main rewrote the same files.
They were not merged by guesswork: the working tree was returned to the committed
state and the stash is kept intact. The owner can recover them with
`git stash apply 8f3daba95e22e9c0eb79b0d68edb94e8d76ec1f1` and resolve against the
new main. Still uncommitted and untouched in this worktree:
`docs/dev-log/active-lane-split.md`, `vignettes/implementation-map.Rmd`,
`vignettes/predictor-dependent-random-sd.Rmd`.
