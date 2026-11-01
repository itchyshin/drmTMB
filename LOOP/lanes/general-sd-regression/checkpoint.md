# 2026-10-29: Julia Binomial relmat SD bridge under probit and cloglog

The live R-to-Julia bridge test passed on Julia 1.10.0 for q1 relmat intercept
SD models under probit and cloglog. Each link was compared with native TMB on
the same fixed-seed data for slope recovery, likelihood, and group SD output.
Four native/Julia candidate rows were added and remain unreviewed. The family
table, formula guide, Julia vignette, and known-limitations note describe this
scoped development route. No coverage or broad-parity claim follows. Next Bernoulli audit: Julia q1 animal pedigree under logit. Current bridge comments reject pedigree marshalling; first verify whether the existing Julia A/Ainv animal fitter can consume an R-derived pedigree covariance without changing scaling, then choose the smallest implementation slice.

Report: `docs/dev-log/after-task/2026-10-29-julia-binomial-relmat-nonlogit-sd-bridge.md`.
Evidence: `docs/dev-log/general-sd-regression/evidence/julia-binomial-relmat-nonlogit-sd-bridge-live-20261029/`.

---

# 2026-10-29: Bernoulli phylo/relmat recovery assertion repair

The native fixed-seed Binomial phylogenetic plus relmat recovery test now
requires positive, non-negligible slopes within narrower bounds under logit,
probit, and cloglog. The focused test exited 0. A suspected q1 likelihood
omission was checked against the exact current source and found to be stale;
the existing branch scales and reports the predictor-dependent SD. No coverage
or Julia parity claim follows.

Report: `docs/dev-log/after-task/2026-10-29-binomial-phylo-relmat-recovery-assertions.md`.

---

# 2026-10-29: Julia Binomial animal-slope Ainv under logit

A new fixed-seed bridge fixture passed on Julia 1.10.0, comparing native TMB
and Julia for an animal numeric-slope SD model with supplied `Ainv`. The exact
source-bound receipt links two candidate rows; both remain unreviewed. This is
point-fit/output evidence only, with no coverage or broad-parity claim. The
overall goal remains active. Next, select another unresolved Bernoulli row from
the required-row ledger and verify base-engine support before editing.

Report: `docs/dev-log/after-task/2026-10-29-julia-binomial-animal-slope-Ainv-logit-bridge.md`.
Evidence: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-Ainv-logit-bridge-live-20261029/`.

---

# 2026-10-29: Julia Binomial animal-slope Ainv non-logit bridge

The R bridge now admits supplied `Ainv` for the existing Julia Binomial animal
slope-only SD route under probit and cloglog. The focused live file passed three
bridge test cases on macOS with Julia 1.10.0; the new animal-slope fixture
checks both links against native TMB for coefficient recovery, log likelihood,
and fitted group-SD output. The local guard and matrix-marshalling checks pass.
Evidence is linked to four exact required rows, which remain unreviewed; no
interval-coverage or broad-parity claim is made. Totoro cannot run this R-to-Julia
bridge because of the recorded R embedding segfault, and the local Julia binary
was absent from PATH until `~/.juliaup/bin` was added.

Shinichi confirmed that this lane owns the general SD implementation across
native R/TMB and Julia. This supersedes older checkpoint wording that assigned
all Julia parity to the separate DRM parity lane. Continue to coordinate on
shared Julia files and preserve that lane's unrelated changes. The docs and
capability audit lane remains separate.

Next: select the next unresolved Bernoulli q1 cell from the exact required-row
ledger, starting with pedigree animal input or another provider that has a
working base fitter. Keep interval coverage deferred and retain all failures.

Evidence: `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-slope-Ainv-nonlogit-bridge-live-20261029/`.

---

# 2026-10-29: animal q2 denominator correction

The finite universe omitted a within-endpoint animal intercept-plus-slope q2
block. Added `animal_correlated_block` / `A2-animal-within`, distinct from
independent q1 animal effects and labelled cross-endpoint blocks. The
generator now produces 20,350 required rows (28 mechanisms; 150 block-rule
rows), including 672 obligations for this q2 shape. No row has been promoted
to general support.

The 22 universe tests pass, including a regression that failed before the
correction. Evidence reconciliation passes with 12 new hash-verified records
for supplied-A Binomial q2 across both engines, both coefficient targets, and
logit/probit/cloglog. The Julia non-logit bridge remains limited to the tested
A-covariance input; pedigree/A-inverse parity and interval calibration remain
open. `universe-final-review.md` now states that its Oct 17 independent review
predates this correction; G0 remains open.

Next: investigate the source-review finding that Binomial q1 phylogenetic SD
coefficients may not affect the native likelihood. Confirm by perturbing only
the SD-slope coefficient in the objective, then repair and test the exact
likelihood route if the model is flat. Do not describe that issue as verified
until the local probe reproduces it. Preserve the current dirty checkout and
run fresh exact-path preflight before editing likelihood or bridge files.

Full universe-correction report:
`docs/dev-log/after-task/2026-10-29-animal-q2-universe-correction.md`.

---

## 2026-10-27 native Binomial q4 and animal-relmat non-logit checks

The native animal A/A-inverse/pedigree by relmat K/Q equivalence test passed 62 expectations for probit and cloglog. Eight open provider/link rows now have source-bound receipts. A separate correlated q=4 ordinary-block test passed 32 expectations across probit and cloglog, checking four predictor-dependent SD slopes and all six correlations. Four candidate rows are linked for the q=4 fixture. Evidence reconciliation now reports 139 linked rows out of 19,678 candidates and 161 evidence records. These are receipt counts, not completion percentages. No native source likelihood or builder code changed.

The probit q=4 fit had a non-positive-definite Hessian, so Wald standard errors are not trustworthy for that fit. The q=4 receipts are unreviewed point-recovery evidence for one block size only. Interval calibration is deferred, and this work does not establish Julia parity. Both the documentation-audit lane and Julia-parity lane received coordination updates. The aggregate acceptance gate remains UNKNOWN because its runner is unavailable.

Reports: `docs/dev-log/after-task/2026-10-27-native-binomial-animal-relmat-kernel-nonlogit-sd.md` and `docs/dev-log/after-task/2026-10-27-native-binomial-correlated-q4-nonlogit-sd.md`.

Next: select the next native Bernoulli row from the frozen universe, check its implementation path ownership, and coordinate any matching Julia or public-documentation cells with their active lanes.

---

## 2026-10-27 native Binomial animal plus relmat Q non-logit check

Added a source-bound native test for the animal A plus relmat Q route under probit and cloglog, compared with K covariance using the same synthetic responses. Sixteen focused expectations passed. Two exact native rows are linked; reconciliation now reports 127 linked of 19,678 candidate rows (149 records). This confirms input equivalence for this pair only, with no calibration or Julia-parity claim.

Report: `docs/dev-log/after-task/2026-10-27-native-binomial-animal-relmat-q-nonlogit-sd.md`.

---

## 2026-10-27 native Binomial animal-intercept inputs

Standalone native Binomial logit animal-intercept tests now have source-bound evidence for A covariance, A-inverse precision, and pedigree input. The three target test files passed 33 expectations. A neighboring Beta-binomial test passed; Julia live checks matched by the broad filter were skipped and are not counted. Reconciliation reports 125 linked of 19,678 candidate rows (147 receipt records); this is evidence traceability only. No interval coverage or Julia parity is claimed.

Report: `docs/dev-log/after-task/2026-10-27-native-binomial-animal-intercept-iid-kernels.md`.

---

## 2026-10-27 native Bernoulli ordinary plus animal input equivalence

Added separate fixed-seed native R/TMB tests for Binomial ordinary-iid plus animal SD regression. The logit comparison across A covariance, A-inverse precision, and pedigree passed 11 expectations. The probit and cloglog comparison passed 22 expectations across the same three equivalent inputs. Source-bound receipts link eight exact candidate rows. Evidence reconciliation now reports 122 linked of 19,678 candidate rows (144 receipt records); this is traceability, not goal completion or a support percentage. No source builder or likelihood code changed in this slice. No interval calibration or Julia parity is established.

Reports: `docs/dev-log/after-task/2026-10-27-native-binomial-ordinary-animal-kernel-equivalence-sd.md` and `docs/dev-log/after-task/2026-10-27-native-binomial-ordinary-animal-kernel-equivalence-nonlogit-sd.md`.

Next: recompute the remaining native and Julia Binomial row sets, then select the next focused implementation/evidence gap after exact-path preflight.

---

## 2026-10-27 Julia Binomial phylogenetic-interaction non-logit recovery

Strengthened the existing Julia phylogenetic-interaction intercept fixture to generate link-matched probit and cloglog outcomes and check SD-slope recovery, pair-level prediction, and simulation. Totoro Julia 1.10.12 passed 47/47 in 21.87 seconds; 107 source hashes matched. The universe now admits only these two exact link/provider/member rows and remains at 19,230 rows. The 19 universe tests passed. Report and receipt: `docs/dev-log/after-task/2026-10-27-julia-binomial-phylo-interaction-nonlogit-recovery.md` and `docs/dev-log/evidence/general-sd-regression/julia-binomial-phylo-interaction-nonlogit-totoro-20261027/`. No coverage, native parity, or independent dense-oracle claim.

Next: audit the next unresolved Bernoulli structured cell for a reusable implementation, then test and admit only the exact route.

---

## 2026-10-27 Julia nested Binomial non-logit SD

The same two-group Laplace route was verified for genuinely nested iid factors, with child levels unique within parent. `test/test_binomial_nonlogit_nested_sd_regression.jl` passed 44/44 on Totoro Julia 1.10.12, one thread, for probit and cloglog, crossed independent intercept and numeric-slope SDs. Its 107-entry source manifest matched before the run; receipt and hashes are in `docs/dev-log/evidence/general-sd-regression/julia-binomial-nested-nonlogit-totoro-20261027/`.

The finite universe admits two additional exact Julia Binomial rows, bringing the newly admitted non-logit subset to 30 and total universe to 19,230. Universe tests passed 19/19. Coverage and native parity remain untested for these exact routes.

Next: continue with the next unresolved Bernoulli structured route after ownership and exact source checks.

---

## 2026-10-27 Julia crossed Binomial non-logit SD

The Julia crossed additive iid fitter now dispatches probit/cloglog likelihood values, derivatives, and starting values through the family-aware Binomial path. The new independent synthetic test `test/test_binomial_nonlogit_crossed_sd_regression.jl` passed 44/44 on Totoro Julia 1.10.12 with one thread, covering crossed independent intercept and numeric-slope SD terms. A 107-file source manifest matched the tested snapshot; run receipt and hashes are under `docs/dev-log/evidence/general-sd-regression/julia-binomial-crossed-nonlogit-totoro-20261027/`.

The finite universe now has 28 additional Julia Binomial non-logit rows for probit/cloglog across animal, related-matrix, phylogenetic, q2/q3 correlated, and crossed iid routes. Total universe remains 19,230. No interval coverage or native parity claim. `docs/src/families.md` is owned by the active documentation audit lane; a bounded update was sent to that lane.

Next: continue with the next unresolved Bernoulli mechanism after checking source and ownership. Keep nested non-logit terms, bridge parity, other distributions, and uncertainty calibration open.

---

## 2026-10-27 Julia non-logit Binomial animal and related-matrix SD

Julia 1.10.12 focused tests passed for animal intercept (34/34), animal slope
(40/40), related-matrix slope (23/23), probit phylogenetic intercept and
derivative checks (42/42), cloglog phylogenetic plus mixed phylogenetic/IID
routes (29/29), correlated q2 recovery (28/28), and correlated q3 recovery
(26/26) for probit and cloglog on Totoro. The generator now admits only the
tested Julia probit/cloglog rows: animal intercept/slope with `A_covariance`
or `Ainv_precision`, related-matrix intercept/slope with `K_covariance`,
tree-backed phylogenetic intercepts, one tree plus IID pair, and exact
correlated q2/q3 coefficient blocks. The universe remains 19,230 rows; 26 rows
move from blocked or unresolved to required. Universe checks pass 19/19. This
is direct-engine point-recovery and workflow evidence, not native parity or
interval calibration. Pedigree, `Q_precision`, correlated blocks above the q3
anchor, other simultaneous providers and remaining non-logit structured rows
stay blocked. Full report:
`docs/dev-log/after-task/2026-10-27-julia-binomial-nonlogit-animal-sd.md`.

Next: select the next Bernoulli capability row after exact-path preflight.

## 2026-10-27 follow-up: Binomial interaction evidence rows reconciled

The formula grammar and known-limitations page now report the tested development
Julia bridge for one Binomial phylogenetic-interaction q1 intercept with logit,
probit, and cloglog links. The same hash-checked focused-test run is now linked to the three
link-specific candidate rows. Reconciliation reports 92 receipts linked to 72
of 19,118 frozen candidate rows. This count is evidence linkage only; rows are
not promoted to general support. Exact receipt and source hashes are in
`docs/dev-log/general-sd-regression/direct-sd-evidence.tsv` and
`docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-interaction-sd-bridge-20261027/source-manifest.json`.

## 2026-10-27 Binomial spatial bridge and phylogenetic interaction verification

The drmTMB Julia bridge now admits the existing coordinate-spatial Binomial
intercept and slope-only SD shapes for logit, probit, and cloglog. The live
JuliaCall 1.10.0 test passed; 13 fit-free route/payload assertions also passed.
The after-task report and `docs/dev-log/check-log.md` record the scope and
limits. This remains point/parity evidence, not interval calibration.

The direct Julia Binomial `phylo_interaction()` SD implementation is already
present in the candidate worktree. I reran
`JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project=. test/test_binomial_phylo_interaction_sd.jl`
locally: 10/10 formula-target and 23/23 fit/output assertions passed. The
existing Totoro report records 33/33 on Julia 1.10.10. No Julia source was
edited during this verification.

Next implementation slice: admit the same tightly scoped Binomial
phylogenetic-interaction SD route through the R-to-Julia bridge, beginning with
payload/marshalling tests. **Completed 2026-10-27:** the R-to-Julia bridge maps
this one q1 interaction intercept to a pair-level related-matrix `K`, retains
the public `sd_phylo(pair_id)` target, and supports pair prediction and seeded
marginal simulation. A live JuliaCall/TMB test passed for logit, probit, and
cloglog. Details: `docs/dev-log/after-task/2026-10-27-binomial-phylo-interaction-sd-julia-bridge.md`.
This is narrow point/parity evidence, not broad bridge parity or interval
calibration. Continue with the next Bernoulli implementation gap from the
capability universe.

## 2026-10-27 native Bernoulli phylogenetic-interaction SD

Native Binomial now admits an existing q1 `phylo_interaction()` location field
with `sd(pair_id, level = "phylogenetic_interaction") ~ predictors`. Pair IDs
are validated one-to-one against the two partner variables; predictors must
be pair-constant. The new independent synthetic recovery and target-order
test passes 9 expectations, and the adjacent Binomial phylogenetic SD test
passes 25. The focused formula grammar, combined with the existing legacy
deprecation case, gives 74 passes and one existing warning. `pkgdown::check_pkgdown()`
passes. The full site build completed successfully and rendered the updated
formula guide. A broader neighboring
interaction filter found one unrelated stale NB2 error-message assertion at
`test-phylo-interaction.R:841`; no NB2 change was made. The Julia engine and
bridge do not yet fit this provider. See
`docs/dev-log/after-task/2026-10-27-binomial-phylo-interaction-sd.md`.

Next: add direct Julia `phylo_interaction()` Binomial fitting or select the
next required Bernoulli capability row after checking its exact Julia source
and ownership. Do not claim Julia parity from this native evidence.

## 2026-10-26 paired Julia non-logit Binomial animal-slope Ainv bootstrap

The probit and complementary log-log animal numeric-slope fits using `Ainv`
each completed one bootstrap refit. The focused Julia test passed 40/40 in
18.6 seconds. This confirms that the precision-input model routes through
marginal simulation and refitting for both links; it does not establish
bootstrap reliability, interval calibration, or native parity. The exact
receipt is `julia-binomial-nonlogit-animal-slope-ainv-bootstrap-20261026`,
still unreviewed. The evidence overlay now has 89 receipt records linked to 69
distinct rows, with 19,049 candidate rows still unlinked; these are trace
counts, not a completion percentage. Check log and report:
`docs/dev-log/check-log.d/2026-10-26-julia-binomial-nonlogit-animal-slope-ainv-bootstrap.md`;
`../../../../general-sd-julia/docs/dev-log/after-task/2026-10-26-julia-binomial-nonlogit-animal-slope-ainv-bootstrap.md`.

Next: select the next Bernoulli implementation gap from the pinned universe
after preflighting the exact files against the audit and parity lanes.

## 2026-10-26 next Bernoulli implementation gate

The next reviewed candidate is the native Bernoulli phylogenetic profile
nuisance-convergence repair. It depends on Julia `src/inference.jl`, which
preflight reports has 33 refs carrying work absent from this checkout; the
paired sparse Laplace fitter has 38 such refs. The native TMB likelihood file
has 76 active refs. No source edits were made in these shared files. I asked
docs-audit owner `01a172e2-1377-7690-87e4-d37622486e0c` to confirm current
ownership and release the relevant path or identify a non-overlapping route.
Until then, continue only on documentation/evidence paths or implementation
files with a clean exact-path preflight.

## 2026-10-26 paired Julia NB2 animal Ainv bootstrap slice

The Julia NB2 animal mean-intercept SD route now simulates marginal responses
from sparse precision `Ainv`, and a one-refit parametric bootstrap passes. The
test failed first when simulator construction fell through to the covariance-
only matrix resolver. The focused test now passes 12/12, including a selected
SD-slope profile with finite 80% endpoints; the adjacent NB2 SD suite passed
53/53. A small-fit Hessian warning remains and withholds Wald SEs, so this is
not interval calibration.
The Julia family guide, R-side capability inventory, and G4 evidence ledger
record this as one Julia-only workflow cell. Receipt
`julia-nb2-animal-ainv-simulator-bootstrap-profile-20261026` links it to the
existing exact Julia NB2 animal `Ainv_precision` row; the row remains
unreviewed. At the time of that receipt, the evidence overlay had 87 receipts
linked to 67 rows, not a
completion percentage. Report and exact hashes:
`../../../../general-sd-julia/docs/dev-log/after-task/2026-10-26-julia-nb2-animal-sd-bootstrap-ainv.md`.

Next: select the next required row from the pinned capability universe and
preflight its implementation paths against the docs-audit and parity lanes.

## 2026-10-26 current-source Julia probit phylogenetic profile and bridge rerun

The direct Julia suite passed 55/55 on the current candidate source: joint fit/oracle 27/27, phylogenetic intercept 23/23, and probit SD-slope profile 5/5. The paired R-to-Julia bridge rerun exited 0 with three live Julia tests. Julia still emits a non-positive-definite Hessian warning and withholds Wald SEs. This is profile-workflow evidence for one fixture, not interval calibration. Transcripts and hashes are in `docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/direct-phylo-sd-test-20261026-profile-retry-current.log` and `docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-bridge-20261026/live-bridge-profile-retry-current.log`; exact candidate hashes are recorded in the updated inventory and after-task report.

Next: choose the next unresolved Bernoulli implementation cell from the capability universe; preserve the separate docs-audit and parity scopes.

## 2026-10-26 Julia probit phylogenetic Bernoulli SD bridge rerun

The current R candidate contains a probit phylogenetic SD admission route and
live TMB/Julia comparison test. The focused filter passed with exit code 0,
including two live Julia bridge test blocks. A 10-file source/configuration
manifest matched before and after the run; logs and hashes are in
`docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-bridge-20261026/`.
The test checks one seeded point-recovery case, cross-engine coefficients and
likelihood, convergence, and tip SD predictions. Julia warns that the chosen
tree is on the raw branch-length scale; the compared fits use that same
covariance. Interval calibration and broader Binomial support remain open.
The source-side changes are not part of this rerun, and their authorship and
handoff are still unconfirmed. `R/julia-bridge.R` remains under the active
`codex/docs-audit-r-current-20261025` path lease. The docs-audit thread is
`01a172e2-1377-7690-87e4-d37622486e0c`; it was still active at the last
check and has not answered the handoff request. Resume by checking that thread
and the exact current lease. If the owner releases the file, review the final
diff before any edit; otherwise take the next required row whose implementation
files have a clear non-overlapping lease. The lane efficiency gate requested a
fresh task before further work.

## 2026-10-25 Non-logit Binomial intercept-plus-slope SD bridge

The Julia bridge now admits one ordinary mean intercept and one independent
numeric slope on the same group for probit and complementary log-log links,
with a separate coefficient-selected SD formula for each. Fit-free checks
reject incomplete or mismatched targets. Same-data TMB/Julia tests passed for
both links and checked convergence, signed recovery, labels, and group-SD
predictions. The adjacent slope-only bridge fixture and both edited vignette
renders also passed. This is candidate point-recovery evidence only; no
correlated-block, released-Julia, or interval-calibration claim is made.
The focused live test also confirms both coefficient-specific SD targets are
listed for profile routing and that a two-refit Julia bootstrap smoke retains
the selected slope target, with at least one finite refit. This checks workflow
routing; interval calibration remains unmeasured. The follow-up run passed after removing
native-only bootstrap arguments from the Julia call.
Details: `docs/dev-log/after-task/2026-10-25-julia-binomial-nonlogit-intercept-slope-bridge.md`.
No programme gate closes.

## 2026-10-25 ZI-NB2 sigma-SD Julia bridge and workflow checks

The bridge now admits optional `zi` only as a fixed intercept for the narrow
ZI-NB2 sigma-SD route. Fit-free controls reject predictor-dependent and random
`zi`; the existing fixed-`zi` bridge fit and ordinary NB2 sigma intercept/slope
bridge test each passed one live Julia test. A native workflow smoke test
passed 12 expectations for profile-target registration and two bootstrap
refits retaining the SD coefficient target. A full profile CI attempt exceeded
four minutes without output and was stopped; it remains unverified for this
cell. Reports and commands are in
`docs/dev-log/after-task/2026-10-25-julia-zi-nbinom2-sigma-sd-bridge.md` and
`docs/dev-log/check-log.d/2026-10-25-julia-zi-nbinom2-sigma-sd-bridge.md`.
No programme gate closes. Next, select another required row from the full
capability inventory after checking current ownership.

## 2026-10-24 Julia Poisson animal-slope raw A/Ainv evidence registration

The source-bound Julia Poisson animal random-slope test reran locally and passed
25/25 checks in 21.8 seconds; four source/test hashes were stable across the
run. Its non-unit raw-A receipt now links the exact `A_covariance` and
`Ainv_precision` Julia rows as unreviewed focused-test evidence. The reconciler
passes with 50 records linked to 41 of 19,118 candidate rows; this is not a
completion percentage and closes no programme gate. No source code changed.
Full details:
`docs/dev-log/after-task/2026-10-24-julia-poisson-animal-slope-raw-a-evidence.md`.
Next, resolve ownership of the R-to-Julia bridge path before extending it.

## 2026-10-24 Julia Binomial animal-slope Ainv evidence registration

The existing Julia test passed 10/10 assertions in 15.3 seconds. I copied its
receipt, test, source hashes, and console log into the R/TMB evidence tree, then
linked the exact Julia Binomial animal numeric-slope `Ainv_precision` row as
unreviewed focused-test evidence. The reconciler passes with 48 records linked
to 39 of 19,118 candidate rows; this is not a completion percentage and closes
no programme gate. No fit was rerun and no source code changed. Full details:
`docs/dev-log/after-task/2026-10-24-julia-binomial-animal-ainv-slope-sd-evidence.md`.
Next, review the Poisson animal-slope `Ainv` bridge diff and ownership.

## 2026-10-24 Poisson ZIP mean-intercept cross-engine receipt

The focused TMB/Julia bridge test passed one live Julia fit, with stable before/after hashes for 169 source files. The two ordinary `zi_poisson` mean-intercept rows are linked as unreviewed focused-test evidence. No programme gate closes. ZIP slopes, structured effects, offsets, hurdle models, user docs, and interval coverage remain open. Details: `docs/dev-log/after-task/2026-10-24-poisson-zi-sd-cross-engine-evidence.md`.

## 2026-10-24 Bernoulli source-bound evidence refresh

The current focused Julia bridge filter passed five live tests with no failures or skips. Before/after hashes matched for 167 source files. Three existing Bernoulli ledger rows now point to the current receipt and remain unreviewed. The reconciler passes at 43 receipt records linked to 34 of 19,118 candidate rows. This is not a completion percentage and closes no programme gate. Details: `docs/dev-log/after-task/2026-10-24-bernoulli-ledger-receipt-refresh.md`.

# Recovery checkpoint: general SD regression

## 2026-10-26 Current-source probit/cloglog bridge rerun recorded

Completed the current-source rerun for ordinary Binomial mean random-intercept
SD models under probit and complementary log-log links. The focused bridge test
passed 27 expectations and now reports its one live bridge block through the
shared test counter; two TMB/Julia fit pairs ran. The source manifest, test
snapshot, log, and exit code are retained under
`docs/dev-log/general-sd-regression/evidence/julia-binomial-nonlogit-sd-bridge-20261026/`.
The evidence reconciler passes, with rows still unreviewed and no support
promotion. The after-task structure check passes; its gate audit is UNKNOWN
because the system Node/gate-check runtime is unavailable. This slice does not
cover structured non-logit bridge support or interval calibration. The q2 Julia
recovery fixture was separately strengthened to tighter slope and correlation
bounds and passed 28/28 on Totoro. Next: proceed with a required capability row
whose implementation files have an explicit available ownership path; the
structured probit/cloglog R bridge remains ownership-blocked in `R/julia-bridge.R`.

## 2026-10-24 Binomial animal plus IID intercept recovery design

Reproduced the old fixed-seed recovery miss (IID log-SD slope 1.014 versus
truth 0.25) and found that the fixture assigned contiguous animal IDs to sites
while the AR(1) matrix used the same ordering. Model/data source review found no
obvious mapping or scale-prior error. Replaced the recovery fixture with 192
animals, 48 sites, 24 observations per animal, balanced random site assignment,
and independent seeded SD slopes of 0.45. Two local pilots recovered animal
and IID slopes at 0.468/0.464 and 0.680/0.329. The final focused filter passed
with exit code 0; its console and hashes are in
`docs/dev-log/evidence/binomial-animal-iid-sd-recovery-20261024/`. No
programme gate closes. Next: add an independent numerical check and same-data
Julia fit for this combined structure, then update the user-facing formula
example when the documentation lane is clear.

## 2026-10-24 ZIP selected mean-slope cross-engine receipt

The source-stable R/TMB-to-Julia bridge filter passed two live Julia fits for
the ZIP mean intercept and selected independent mean slope, with no failures
or skips. The paired Julia ZIP regression tests passed 33 checks, including a
scalar likelihood oracle, seeded simulator oracle, finite profile intervals,
and one bootstrap refit. Refreshed the two intercept evidence rows after the
shared test file changed, then linked two new selected-slope rows. The evidence
reconciler passes with 47 records covering 38 of 19,118 candidate rows; this is
not a completion percentage and no programme gate closes. Receipt and exact
source hashes are in
`docs/dev-log/general-sd-regression/evidence/poisson-zi-slope-cross-engine-20261024/`.
User-facing ZIP documentation and wider family/effect/backend support remain
open. Next, coordinate the shared docs ownership and continue the required-cell
matrix.

## 2026-10-24 Gamma animal raw-`A` cross-engine decision

The user selected raw supplied `A` for Julia Gamma animal fitting and marginal simulation, matching native TMB. This is an explicit exception to the original plan's broad instruction to preserve kernel normalization: prior Julia Gamma animal fits with non-unit-diagonal `A`, including constant-SD fits, change. Gamma `relmat(K)` and other routes keep their existing conventions.

The focused Julia animal intercept, slope-only, and intercept-plus-slope tests passed 66 assertions. The paired R bridge filter for non-unit-kernel simulation and parity passed both live Julia tests. One same-data non-unit-diagonal fixture checks fitted SD coefficients, log likelihood, and named group SDs; the seeded simulator check uses raw `A`. Julia docs, the R candidate inventory, and after-task/check-log records now state this boundary. The former normalization report is historical and explicitly superseded.

The Julia docs build could not run because Documenter is absent from the configured docs environment. The after-task structure check passed, while its acceptance-ledger check returned `UNKNOWN` because no runnable ledger node/check command was present. No programme gate advanced; the programme remains at 1/9 formal gates met. Broad parity and interval calibration remain open. Details and hashes: `docs/dev-log/after-task/2026-10-24-gamma-animal-raw-kernel-parity.md` in the paired Julia candidate and `docs/dev-log/evidence/gamma-animal-raw-kernel-parity-20261024/source-manifest.md` in the drmTMB candidate.

## Previous checkpoints

## 2026-10-24 ZeroOneBeta Julia SD prediction output

The paired Julia candidate now returns the predictor-dependent SD for a
ZeroOneBeta ordinary mean-intercept fit through `predict_parameters()`. The
test was red before the family dispatch fix and passes 20/20 checks afterward,
covering link and response scales, finite delta-method standard errors, and
subset/reordered new data. Exact candidate source hashes and the focused
command are in
`../../../../general-sd-julia/docs/dev-log/after-task/2026-10-24-julia-zeroonebeta-sd-prediction.md`.
This is partial G4 output evidence for one Julia cell only. It does not add
TMB parity or interval calibration, and it closes no programme gate.

## 2026-10-23 Gamma animal q2 R-to-Julia bridge

The R bridge now preserves coefficient selectors for both Gamma animal SD
targets and maps the public selector-qualified keys to Julia's distinct fitted
blocks. On identical synthetic data with a unit-diagonal relatedness matrix,
TMB and Julia fit `animal(1 + x | id)` with separate group-level SD regressions
for the intercept and slope. The focused cross-engine test passed 19
expectations for convergence, coefficient labels and estimates, group SD
prediction, log likelihood, `sdpars` identities, `predict_parameters()`, and
save/reload. The existing Gamma bridge filter also passed five live Julia
tests after the change. R source parses and `git diff --check` pass.

Candidate hashes: `R/julia-bridge.R`
`231b80e92bb5cf3963d4ce52267238ad9d16c483a2e612c7a1b75a46053c48e1`,
`R/predict-parameters.R`
`646bb79de06de281a9e522182465c1eb96f9b08489386abb1ed10ceb87b41014`, and
`tests/testthat/test-gamma-animal-q2-cross-engine-sd.R`
`8d3e8a9139fa3d4b3fb7f3f5597298d90536e21c333f2f2b90256122c06a2903`; paired
Julia `src/gamma.jl` hash
`a3065b51bdaae48cd6862274145052c3700829cd1c4ae208dde91b95f88ace19` and
`test/test_gamma_animal_intercept_slope_sd.jl` hash
`1f7bd590b37dd46b79b9426a5f8dd9931731b480df8c913bc4e5c92b94b5b12b`. The
focused commands were `devtools::test(filter = "gamma-animal-q2-cross-engine-sd", reporter = "summary", stop_on_failure = TRUE)` and `devtools::test(filter = "julia-gamma-sd", reporter = "summary", stop_on_failure = TRUE)` with `DRM_JL_PATH` set to the paired Julia worktree, `JULIA_NUM_THREADS=1`, and `OPENBLAS_NUM_THREADS=1`. Simulation,
profile/bootstrap, uncertainty calibration, user documentation and full-suite
checks remain open. This is partial evidence for G3/G4, not a programme gate
pass; the programme remains at 1/9 formal gates met.

## 2026-10-23 Julia Poisson offsets across supported SD routes

The paired `codex/general-sd-regression` DRM.jl worktree now carries fixed
`offset(...)` terms through ordinary intercept/slope GHQ fits and the supported
structured phylogenetic, related-matrix, and animal Laplace fits. Animal support
includes intercept and slope-only coefficients and both `A` and intercept
`Ainv` routes. Ordinary Poisson tests passed 54 assertions; the structured
offset file passed 19, including dense Laplace oracles for each provider and a
seeded related-matrix simulation oracle. Neighboring relmat, animal-intercept,
and animal-slope files passed 17, 33, and 19 assertions. The guide, capability
table, NEWS, and after-task report record this boundary. Documenter is absent,
so rendering remains unverified. Offset parity in native TMB and other families,
package-wide checks, and calibrated uncertainty remain open; no programme gate
closes from this slice.

## 2026-10-23 current status reconciliation

The native programme ledger currently reports 1 of 9 gates met. G2 is met for
the bounded Bernoulli vertical slice. G0, G1, and G3 through G8 remain open;
in particular, the full required capability universe, cross-engine outputs,
calibrated uncertainty, rendered documentation, package checks, and independent
closeout are not complete.

The current direct-SD evidence summary is an evidence-only join over 19,118
candidate rows. It has 32 hash-verified receipt records linked to 26 distinct
rows, with 19,092 rows still unlinked. The receipts have not promoted any row
and do not establish support or interval calibration. These counts describe
evidence linkage, not the fraction of implementation complete. The latest
Tweedie related-matrix receipt adds one same-data native TMB/Julia bridge
comparison (24 assertions passed); see
`docs/dev-log/after-task/2026-10-23-tweedie-relmat-tmb-julia-current-source-parity-rerun.md`.

The native Gamma animal q2 intercept-plus-independent-slope test now passes
37/37 with no warnings using a task-specific temporary directory. The paired
Julia source and test hashes match its separate 35/35 focused receipt. This is
candidate evidence for the two engine slices, not a same-data bridge comparison,
non-unit-diagonal covariance-scale parity, or uncertainty calibration. The
native candidate is 6 commits ahead and 245 behind the local `origin/main`; no
programme gate closes. See
`docs/dev-log/after-task/2026-10-23-native-gamma-animal-q2-sd-verification.md`.

The existing Gamma phylogenetic non-unit-height parity fixture was rerun on
the current paired candidates after its earlier source hashes were found to be
stale. The current-source run passed 6 assertions with exit code 0 and one live
Julia bridge test. Julia retains raw branch-length scaling and reported tree
height 6.404475. This remains one same-data fixture, not recovery or calibrated
uncertainty. Exact hashes and console are in
`docs/dev-log/evidence/gamma-phylo-nonunit-current-source-20261023/`; the
overall programme remains at 1 of 9 formal gates met.
The Binomial related-matrix row now also has a 199-file source-bound receipt
for same-data TMB/Julia fitting, save/reload output preservation, and an
independent simulation oracle (35 assertions); see
`docs/dev-log/after-task/2026-10-23-julia-binomial-relmat-save-reload.md`.

The Julia Tweedie related-matrix fit now also tests save/reload of SD
coefficients, kernel-adjusted marginal SDs, and predicted SDs (39 assertions
pass). Its paired TMB/Julia parity test passed 24/24 assertions on the same
source-pinned candidate. This adds one output-workflow check for the existing
Tweedie row; it does not close another programme gate or establish interval
calibration. See `docs/dev-log/after-task/2026-10-23-julia-tweedie-relmat-save-reload.md`.

## 2026-10-23 direct-SD receipt-count reconciliation

The current evidence table has 32 hash-verified receipt records linked to 26
distinct candidate rows, leaving 19,092 of 19,118 candidate rows without a
linked receipt. Of the 26 linked rows, 25 are initially classified `required`
and one is `unresolved`; none of the other initial statuses has a linked row.
The generated summary and inventory now match this exact join. The denominator
is a combinatorial engine/family/endpoint/effect/provider/layout candidate
universe, not a count of implemented capabilities or independent engineering
tasks. Receipts document evidence and do not promote rows. See
`docs/dev-log/after-task/2026-10-23-general-sd-evidence-count-refresh.md`.

The paired Julia Binomial default-clamp slice passed 171 of 171 focused
assertions in about 94 seconds. The helper currently covers ordinary SD
regression and the combined phylogenetic-plus-ordinary route. Independent math
review confirmed that phylogenetic-only, animal, and related-matrix Binomial
routes still use unclamped scale predictors; custom or disabled clamp controls
also remain unforwarded by the Julia bridge. The shared Julia sparse-Laplace
file has changes on 29 other refs absent from the candidate, so it remains
untouched pending ownership reconciliation.

The reviewed candidates remain dirty and behind the local `origin/main` refs:
native `425bee815` is 6 ahead and 149 behind; Julia `70dbf564e` is 1 ahead and
197 behind. These counts were read from the local refs and do not claim a fresh
remote fetch. The focused clamp test and Tweedie bridge test close only their
listed slices. Continue the route audit and reconcile the whole required-row
universe before making a programme-wide completion claim.

## 2026-10-23 native Bernoulli SD integration rerun

The native candidate test filter `binomial-sd-integration` passed 381
expectations with no failures, warnings, or skips in 300.8 seconds. The filter
matched the Binomial integration file and the adjacent Beta-binomial
integration file (15 assertions). Exact source hashes, command, branch pin,
and limitations are recorded in
`docs/dev-log/check-log.d/2026-10-23-native-binomial-sd-recovery.md`.
This is current-candidate test evidence only: the branch is six commits ahead
and 102 behind `origin/main`, and the result does not establish current-main
integration, broad cross-engine parity, general capability support, or
calibrated uncertainty. The goal still requires the calibration gate.

## 2026-10-23 Julia NB2 animal Ainv evidence receipt

The paired Julia candidate's focused NB2 animal mean-intercept test passed
19/19 assertions in 15.6 seconds. A hash-bound, unreviewed receipt now links
the exact q1 `mu` animal-intercept `Ainv_precision` row. The test compares
equivalent `A` and `Ainv` fits and rejects malformed precision input; it is
not an independent likelihood oracle, native parity, or interval-calibration
evidence. The evidence reconciler passes with 19,118 candidate rows, 20
receipts, 19 linked rows, and 19,099 unlinked rows; its 11 focused tests pass.
This does not close any programme gate. Full report:
`docs/dev-log/after-task/2026-10-23-julia-nb2-animal-ainv-evidence.md`.

## 2026-10-22 Poisson animal-slope R/Julia parity

The focused bridge test was rerun from the native candidate and passed 17/17
checks, including same-data agreement for `sd_animal(id)` coefficients, log
likelihood, and group-named SD predictions. A first retry was blocked before
fitting by a sandbox-denied JuliaCall cache pidfile; the same test passed in
30.3 seconds after the required cache access was granted. The bridge admits one
complete-data, non-inflated Poisson animal slope-only coefficient with a
unit-diagonal supplied covariance and rejects three nearby formula shapes.
The adjacent native Poisson animal intercept/slope and live bridge filter also
passed 41/41 checks with no warnings or skips.
The guide, NEWS, known-limitations, capability status, check log, G3/G4/G6
partial evidence, and after-task report now record this exact boundary. This
does not close any programme gate or establish broader parity/coverage. Report:
`docs/dev-log/after-task/2026-10-22-poisson-animal-slope-julia-bridge-parity.md`.

## 2026-10-22 Julia Poisson animal-intercept SD

The paired Julia candidate now fits one Poisson `animal(1 | g)` mean intercept
with `sd(g, animal) ~ z` and supplied covariance `A`. Its focused test passed
20/20 checks for recovery, an independent dense Laplace objective, prediction,
marginal simulation, save/reload, constant-SD equivalence, within-group
predictor validation, and one bootstrap refit. The synthetic example ran
directly and public family/capability guidance was updated. Documenter is
unavailable, so the example has not been rendered. Julia normalizes `A` to a
unit-diagonal correlation matrix; non-unit-diagonal TMB parity remains
unverified. The unreviewed receipt links required row 7917 in
`docs/dev-log/general-sd-regression/evidence/poisson-animal-julia-20261022/`.
This is partial evidence for G3, G4, and G6, not a programme gate pass.
After-task report:
`../general-sd-julia/docs/dev-log/after-task/2026-10-22-julia-poisson-animal-sd-regression.md`.

## 2026-10-22 ZeroOneBeta Julia marginal simulation integrity

The paired Julia candidate's ZeroOneBeta marginal simulator now uses the
newly drawn random effect for the Beta-component mean. The independent seeded
oracle and one bootstrap refit pass; the neighboring ZeroOneBeta recovery,
intercept-SD, and slope-SD tests also pass. This contributes one narrow
workflow receipt to G4 only. It does not establish broad parity, calibrated
uncertainty, or coverage. Full report:
`docs/dev-log/after-task/2026-10-22-zeroonebeta-sd-marginal-simulation.md`.

## 2026-10-22 Gamma animal bridge parity

The R-to-Julia bridge now maps one Gamma q1 animal-intercept direct-SD formula
to Julia's fitted `sd` block. The synthetic live comparison passed for SD
coefficients and group-level SD predictions using a unit-diagonal supplied
covariance. A q2 ambiguity control confirms that the synthetic `resd` label is
retained when the coefficient is not unique. The focused Gamma bridge filter
ran four live tests; the neighbouring structured bridge filter ran one live
test. An independent review found no remaining concrete issue in this bridge
path. This is one candidate point-parity fixture, not broad Gamma/provider
parity or interval calibration. Details: `docs/dev-log/after-task/2026-10-22-julia-gamma-animal-sd-bridge-parity.md`.

## 2026-10-21 source-bound evidence expansion wave 2

The exact-key evidence overlay now links eight receipts to seven candidate
rows: native Binomial intercept profile and marginal-simulation workflows; a
native Poisson intercept single-fixture recovery/oracle test; Julia Binomial
intercept and independent-slope bridge tests; a Julia Binomial correlated-q2
bridge smoke; and Julia Gamma intercept and slope bridge tests. All records
remain unreviewed. The q2 row remains unresolved and its run logged
singular-Hessian warnings. No broad parity, support admission, or interval
calibration claim follows.

The reconciler now reads exact path/hash pairs from JSON, CSV, and checksum
manifests. Its ten tests pass, including cross-entry JSON mismatch rejection.
Reconciliation: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118
linked_rows=7 unlinked_rows=19111 evidence_records=8`. The required-row SHA-256
remains `3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.
After-task report: `docs/dev-log/after-task/2026-10-21-sd-evidence-expansion-wave2.md`.

## 2026-10-21 exact-key evidence expansion

Expanded the evidence-only overlay by three source-bound receipts: two native
TMB Bernoulli random-intercept workflow tests (profile and marginal simulation)
and one Julia Bernoulli correlated q2 bridge smoke. The overlay now has five
receipts linked to four exact candidate rows; 19,114 candidate rows remain
unlinked. All records remain unreviewed. The Julia q2 row remains unresolved,
and its run includes singular-Hessian warnings. No cross-engine parity,
recovery, calibrated uncertainty, general admission, or coverage claim follows.

Reconciliation: `EVIDENCE_RECONCILIATION_PASS candidate_rows=19118
linked_rows=4 unlinked_rows=19114 evidence_records=5`. The frozen required-row
SHA-256 is unchanged at
`3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.
Report: `docs/dev-log/after-task/2026-10-21-sd-evidence-expansion.md`.

## 2026-10-21 exact-key evidence reconciliation

Added a separate direct-SD evidence overlay, without modifying the 19,118-row
candidate universe. The reconciler verifies exact row keys, receipt and source
manifest hashes, test-source hashes, and that the test file is named in the
manifest. Its eight focused tests pass. Two unreviewed source-bound Julia
Binomial/logit rows are linked: the ordinary random intercept and one
independent numeric random slope. The report explicitly limits those receipts
to narrow fit/recovery evidence; 19,116 candidate rows remain unlinked in this
overlay. Frozen `required-rows.tsv` SHA-256 remains
`3183257b390c1994b2b0c6ffab0301943983089ab23b2ae6d57ed31682927253`.

Evidence summary: `docs/dev-log/general-sd-regression/direct-sd-evidence-summary.md`.
After-task report: `docs/dev-log/after-task/2026-10-21-direct-sd-evidence-overlay.md`.
Next: continue exact source-to-row reconciliation across the existing family
and effect slices, then address missing implementation or output work from the
verified gaps. This overlay does not establish broad support or programme
completion; the active programme gates remain open and interval calibration is
deferred.

## 2026-10-22 Julia Gaussian independent-slope SD slice

The paired DRModels.jl candidate now fits Gaussian LSS direct-SD regression for
one ordinary mean intercept or one independent numeric mean slope. The slope
uses `sd(group, coef(x)) ~ z`, with group-constant fixed predictors, ML/REML,
rowwise coefficient-SD output, and a slope-aware marginal simulator and
bootstrap refit. The focused synthetic test passed 19/19 checks on the paired
candidate. Its independent dense ML/REML likelihood oracles, signed recovery,
rowwise output, loading-sensitive simulation oracle, bootstrap workflow smoke,
and constant-SD equivalence are documented in the DRModels.jl after-task
report. Earlier in this slice, Gaussian LSS REML and bootstrap-contract
regressions passed 41/41 and 60/60 checks.

This is Julia evidence for one ordinary Gaussian slice, not native TMB parity
or broad programme completion. The local DRModels.jl documentation build could
not start because `Documenter` is unavailable. Interval coverage calibration
remains deferred. Source hashes for the implementation snapshot are recorded
in the task evidence; continue with the parent capability-row reconciliation
before making a programme-wide progress claim.

## 2026-10-20 Gamma phylogenetic direct-SD test and example

The current Gamma builder already fits one q1 phylogenetic `mu` intercept
with a species-level direct-SD formula. A new native synthetic regression test
passes 11 assertions for positive-trend point recovery, tip-named SD
predictions, and equivalence between the explicit constant-SD formula and the
existing scalar phylogenetic model. The random-SD guide includes a synthetic
Gamma phylogenetic example and rendered from this worktree's loaded package.
The family and formula maps record this as one native point-fit cell. This adds
no production likelihood code and establishes neither interval calibration
nor Julia parity. G3, G4, G6, G7, and G8 remain open; G5 is deferred.

Report: `docs/dev-log/after-task/2026-10-20-gamma-phylo-sd-evidence.md`.

## 2026-10-20 Gamma animal-pedigree SD regression

One native Gamma q1 animal-intercept route now accepts predictor-dependent
SDs with pedigree, covariance, or precision input. Focused and neighboring
Gamma/Lognormal tests passed (110 assertions, two live-Julia skips), and the
synthetic random-SD vignette rendered. The test checks precision ordering,
point recovery, name-keyed SD prediction, constant-SD equivalence, and matching
likelihoods across the three input forms. It does not check profiles, bootstrap
refits, interval coverage, or Julia parity. G3, G4, G6, G7, and G8 remain open;
G5 is deferred, and the required capability universe is incomplete.

Report: `docs/dev-log/after-task/2026-10-20-gamma-animal-pedigree-sd-regression.md`.

## Current checkpoint, 2026-10-21

The paired Julia candidate now passes the complete Bernoulli SD regression
file, including the animal slope SD inference and marginal-simulation checks:
157/157 assertions passed on Julia 1.10.0 with four Julia threads and one
BLAS thread. Exact source hashes are `src/inference.jl`
`e1fd189d1e1258bc5efaeb7e50cc129e344880c18ec1f8fed37ec62023b8e24e` and
`test/test_binomial_sd_regression.jl`
`58af11e899b2776289a225361f04c8b1ae26d0058ac3972ef357ba986f882eac`.
Independent code review found no critical or high-priority issue. This remains
one Julia capability slice, not R/TMB parity or interval calibration. The
tested profile target's endpoints fail and are reported as failed, not as an
interval; the bootstrap checks are workflow smokes only. Bootstrap refits of
private Binomial fits created with a non-default `nq` still use the public
default order. Details: `../general-sd-julia/docs/dev-log/after-task/2026-10-21-julia-binomial-animal-slope-sd.md`.

The Julia Gamma structured-SD fitter now also accepts one `animal(1 | g)` mean
intercept with `sd(g, animal) ~ z`, preserving DRM.jl's unit-diagonal
normalization of `A`. The focused Gamma relmat and animal suites pass 35/35
assertions, including an independent dense Laplace objective, constant-SD
equivalence, prediction, seeded marginal simulation, serialization, and one
bootstrap refit. A separate read-only audit of the native TMB candidate
confirmed the same q1 Gamma animal-intercept SD route and a 14-assertion focused
test receipt. Native TMB retains the supplied `A` scale; Julia normalizes `A`,
so non-unit-diagonal scale parity remains unverified. Neither slice establishes
interval coverage. The native lane was left untouched. Report:
`../general-sd-julia/docs/dev-log/after-task/2026-10-21-julia-gamma-animal-sd-regression.md`.

The R-to-Julia animal-slope bridge remains under its separate live lease. Next
continue with that owner's evidence review after release; do not claim general
Julia or cross-engine support from this one route. G3 remains partial and
coverage calibration remains deferred.

## Current checkpoint, 2026-10-20

This status supersedes earlier summaries below where they conflict. The goal remains ACTIVE; the parent acceptance ledger has 8 gates with 7 unmet (G2 met, G5 deferred outside the implementation finish line), and no production campaign is running.

- **Native Poisson animal-model SD, 2026-10-20:** one complete-data, non-inflated q1 supplied-`A` intercept now accepts `sd(id, level = "animal") ~ z`. Its 192-group seeded fixture passed 11 checks for the SD slope, shuffled matrix dimnames, group predictions, simulation, save/reload, and constant-SD equivalence. The combined Poisson-animal, Bernoulli-animal, Poisson-relmat, and SD-level grammar filter passed 74 checks with one existing deprecation-throttle warning. The source-loaded tutorial rendered and `pkgdown::check_pkgdown()` passed. Full site build could not resolve `cloud.r-project.org`; the Sass cache under the user Library was not writable. No Julia parity or interval calibration is established. Report: `docs/dev-log/after-task/2026-10-20-poisson-animal-sd-regression.md`.

- **Native Bernoulli animal-model SD, 2026-10-20:** `sd(id, level = "animal") ~ z` now fits one q1 `animal(1 | id, A = A)` location intercept and keeps public target `sd_animal(id)`. Its focused test now passes 12 checks, including profile-target metadata and save/reload. The combined animal, SD-level grammar, Bernoulli phylogenetic, and relatedness-matrix result is recorded in the after-task report. The tutorial rendered, `devtools::document()` completed, and `pkgdown::check_pkgdown()` found no problems. This is a single native point-recovery/output cell, not Julia parity or interval calibration. Report: `docs/dev-log/after-task/2026-10-20-binomial-animal-sd-regression.md`.

- **Native Bernoulli relatedness-matrix verification, 2026-10-20:** `binomial-relmat-sd` passed 22 checks in 18.5 seconds, and the predictor-dependent SD tutorial rendered from current source with a synthetic Bernoulli `relmat()` example. The test covers one seeded intercept route and its public outputs. The paired DRM.jl candidate does not yet admit this route; its task is active on CMR and the relevant source files are dirty, so a source-owner handoff was requested and no Julia source was changed. Report: `docs/dev-log/after-task/2026-10-20-binomial-relmat-sd-verification.md`.

- **Native Poisson relatedness-matrix SD slice, 2026-10-20:** `sd(id, level = "relmat") ~ z` now fits one complete-data, non-inflated Poisson q=1 `relmat()` location intercept. The focused test passed 18 expectations for seeded slope recovery, fit/extraction/prediction, marginal simulation, save/reload prediction, and constant-SD equivalence. Neighboring Poisson phylo and Bernoulli relmat tests passed 46 expectations in total. The tutorial rendered from the current source; `pkgdown::check_pkgdown()` passed. The full site build was blocked by unavailable DNS for `cloud.r-project.org`. This is one native cell, not Julia parity or interval calibration. Report: `docs/dev-log/after-task/2026-10-20-poisson-relmat-sd-regression.md`.

- **Implementation-first finish line, 2026-10-20:** Shinichi approved keeping the full supported-family/effect/provider/two-engine scope while moving 95% interval-coverage calibration out of the current completion gate. The current goal requires light numerical/equivalence checks, small fixed-seed recovery checks, public-output integrity and documentation. Interval workflow checks do not validate coverage; docs must say so. The updated contract is in `LOOP/lanes/general-sd-regression/GOAL.md`, the phased plan in `ultra-plan.md`, the execution table in `arcs.md`, and the acceptance ledger in `.unlazy/general-sd-regression/GATES.md`. No coverage claim is authorized by this change.
- **Lognormal assembly smoke, 2026-10-20:** `Rscript -e 'devtools::test(filter = "lognormal-sd-assembly")'` passed 24 expectations with 0 failures, warnings or skips in 1.5 seconds. This covers native model assembly and formula/design checks only; it ran no fitted model and no live Julia test. It is a focused implementation check, not recovery or interval-coverage evidence.
- **Native beta-binomial SD smoke, 2026-10-20:** `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "beta-binomial-sd-integration")'` passed 15 checks in 155.1 seconds with no failures, warnings, or skips. This one synthetic ordinary-intercept fixture exercises coefficient recovery, SD predictions, independent groupwise likelihood quadrature and a reversed-group negative control, simulation, save/reload, profile/bootstrap routing (two refits), and constant-SD equivalence. No live Julia tests ran. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-beta-binomial-sd-smoke.md`.
- **Native Poisson SD smokes, 2026-10-20:** `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "poisson-sd-integration")'` passed 58 checks in 65.9 seconds with no failures, warnings, or skips. The filter matched ordinary Poisson (43 checks) and zero-inflated Poisson (15 checks). No live Julia tests ran. These are focused synthetic cases, not complete family or provider parity. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-poisson-sd-smoke.md`.
- **Native Gamma and NB2 SD smokes, 2026-10-20:** `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^(gamma|nbinom2)-sd-integration$")'` passed 75 checks in 148.9 seconds with no failures, warnings, or skips. Gamma contributed 23 checks; NB2 contributed 52. No live Julia tests ran. These are focused synthetic cases, not complete family or provider parity. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-gamma-nb2-sd-smoke.md`.
- **Native Beta SD smoke, 2026-10-20:** `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^beta-sd-integration$")'` passed 13 checks in 17.6 seconds with no failures, warnings, or skips. No live Julia tests ran. This is one focused synthetic case, not full family or provider parity. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-beta-sd-smoke.md`.
- **Native Student SD smoke, 2026-10-20:** `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "^student-sd-integration$")'` passed 30 checks in 46.2 seconds with no failures, warnings, or skips. No live Julia tests ran. This is one focused synthetic case, not full family or provider parity. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-student-sd-smoke.md`.
- **Native ordinal and Tweedie SD smokes, 2026-10-20:** cumulative-logit passed 10 checks in 34.0 seconds; Tweedie passed 14 checks in 10.4 seconds. Both had no failures, warnings, or skips; neither ran live Julia. These are focused native fixture results only. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-ordinal-tweedie-sd-smoke.md`.
- **Native zero-one Beta and truncated NB2 SD smokes, 2026-10-20:** zero-one Beta passed 13 checks in 188.0 seconds; truncated NB2 passed 10 checks in 65.4 seconds. Both had no failures, warnings, or skips; neither ran live Julia. Total time was 253.4 seconds. These are focused native fixture results only. The detailed receipt is `docs/dev-log/after-task/2026-10-20-native-zero-one-beta-truncated-nb2-smoke.md`.
- **Bernoulli G2 audit, 2026-10-20:** an independent review found adequate small native fit/recovery and likelihood-oracle evidence, but G2 stays open until the Julia bridge run is bound to exact hashes for the dirty Julia implementation sources (`src/binomial.jl`, `src/binomial_sd_regression.jl`, and inference code) and rerun for fitting/recovery/output behavior. Two singular-Hessian warnings in prior Julia fits rule out a Wald-uncertainty claim for those fits. This is an implementation evidence gap, not an interval-coverage requirement. The DRM.jl task is active on CJS work; no source ownership handoff has been confirmed.
- **Julia source snapshot for the pending rerun:** on the paired candidate worktree at `70dbf564eb670144c63c08f61ea099084d95add2`, read-only SHA-256 values are `src/binomial.jl` `7bfa5fc5c4fca1bf578830f7d4d6dd524b5c0624f791eae7f827f219e45c3e09`, `src/binomial_sd_regression.jl` `ada3807f2d8c3ee20666a8f5c8c69ae2bb54ccc8a90c367ab23f7a7b3aea4d67`, `src/inference.jl` `1f09f0c3605f55f93286477e414fb8dcbd6887180a7f51c95cebe88a35f98e09`, and `test/test_binomial_sd_regression.jl` `0ba3407b132c349ca84e0e9863389c82820bbc556de4f42bb7569dbceb1c4013`. These are current snapshots only, not a receipt for an executed test. Preflight confirms 24 refs carry missing `src/inference.jl` work and 21 carry missing `src/binomial.jl` work; no edits or tests were run against that worktree.

- **Clean-current Bernoulli adapter qualification, 2026-10-20:** the worker now validates adapter-only receipts as one frozen probe with `calibration_claim=false`, while production still requires an external-go status, a true claim, and all 3,000 rows. The source-bound Totoro v13 qualification passed 3/3 probes in 27.552 seconds; all intervals were valid and passed the independent Laplace-oracle check. Receipt replay passed. This is adapter qualification only, not calibration, and does not authorize the 9,000-attempt look. Evidence and hashes: `docs/dev-log/general-sd-regression/evidence/calibration-20261020/adapter-qualification-v13/`; report: `docs/dev-log/after-task/2026-10-20-clean-current-adapter-qualification.md`.

- **Exact-v4 Bernoulli timing pre-run, 2026-10-20:** Totoro completed 45/45 timing-only fits in 27.548 seconds with 16 workers. All 45 had valid 95% profiles and passed the independent Laplace oracle. The observed maximum fit time was 9.757 seconds; 188 waves per 3,000-fit batch plus 180 seconds overhead project 2,014.316 seconds per batch and 6,042.948 seconds overall (100.7 minutes). This is timing-only, not calibration or launch authorization. The 9,000-fit route still needs a freshly validated source-bound GO record. Full capsule: `docs/dev-log/general-sd-regression/evidence/calibration-20261020/timing-exact-v4-v2/`; report: `docs/dev-log/after-task/2026-10-20-exact-v4-timing-pre-run.md`.

- **Ownership:** These current edits are in the Codex `codex/general-sd-regression` worktree. The primary checkout is a different branch; the shared-source preflight still reports multiple active lanes. No edit to `R/drmTMB.R` or `src/drmTMB.cpp` was made in this continuation.

- **Clean-current adapter source mode, 2026-10-20:** the adapter preparation and runner now share a mode-aware source resolver. Clean-current mode checks the frozen `look2.csv` digest, row/schema contract, seed disjointness against supplied prior manifests, and the three probe mappings. Receipts retain source and worker modes, and the runner can replay the three-probe receipt. `python3 -m unittest test_stage_two.py` passes 50 tests; Python compilation and `git diff --check` pass. The runner integration test stubs the worker supervisor and launches no fits. The preparation CLI has not yet been exercised end-to-end, and the exact v4 installed library still needs a source-bound three-probe Totoro qualification. This is adapter plumbing only, not calibration or a second-look decision. See `docs/dev-log/after-task/2026-10-20-clean-current-adapter-source-mode.md`.

- **Clean-current first-look manifest verifier, 2026-10-20:** the replay verifier now checks the frozen clean-current first-look contract (3,000 ordered rows, `look1`, master seed `2026101901`, and its fixed design constants) while preserving the legacy production manifest contract. Fit-free R tests accept both frozen modes and reject changed mode, look, master seed, row ordering, and duplicate seeds. The R rules test, registry/tamper test, and all 50 Python stage-two tests pass. No fits ran. Totoro has the completed clean-current first-look replay, but the retained files do not include the external first-look seal needed to authenticate a new adapter preparation/replay; the three-probe source-bound qualification therefore remains outstanding. G0-G8 remain open.

- **Clean-current worker and combiner, 2026-10-20:** one no-fit Python test now runs the positive preparation CLI, sends the exact prepared root through `run_batches()`, and passes it to the full R combiner CLI. The output contains 12,000 attempts with clean-current source indices 1:9000 and typed `NA` for second-look-only provenance on first-look rows. This end-to-end path exposed and fixed a real row-bind failure. GO, binary, and replay verification are stubbed; all second-look supervisor cases terminate as errors, so no fits run. Python stage-two tests pass 43/43; R stage-two rules and the separate R combiner tests pass. Source-bound adapter qualification, look-two calibration, and all G0-G8 gates remain open. See `docs/dev-log/after-task/2026-10-20-clean-current-worker-receipt.md`.

- **Bernoulli phylogenetic interval smoke, 2026-10-20:** `tools/general-sd-regression/probes/bernoulli-phylo-interval-smoke.R` exits 0 on a seeded 16-tip synthetic fit. The slope target resolves; profile endpoints are `clamp_limited` with the boundary flag set; a two-refit parametric bootstrap returns an interval with 2/2 successful refits. This is dispatch-only evidence, not calibration. A NotebookLM query authenticated as `itchyshin@gmail.com`; its corpus did not directly calibrate predictor-dependent SD slopes. See `docs/dev-log/after-task/2026-10-20-bernoulli-phylo-sd-interval-smoke.md` and `docs/dev-log/check-log.d/2026-10-20-bernoulli-phylo-sd-interval-smoke.md`.
- **Current-source Bernoulli Julia bridge rerun, 2026-10-20:** `devtools::test(filter = "julia-binomial-sd")` passed with five live Julia tests against the paired candidate worktree. The suite emitted two singular-Hessian diagnostics (`rcond=9.23e-10`, coordinate 7; and `rcond=3.88e-17`); Wald standard errors remain untrusted for those fits. This refreshes fit/output/inference-dispatch evidence only, not interval calibration. Exact command, source hashes, and limitations: `docs/dev-log/after-task/2026-10-20-julia-binomial-sd-current-source-rerun.md`.
- **Higher-information Bernoulli phylogenetic profile, 2026-10-20:** `tools/general-sd-regression/probes/bernoulli-phylo-high-info-profile.R` exits 0 in about 47 seconds. On a 60-tip, 100-observation-per-tip fixture, the fitted SD slope was 0.480 (truth 0.45) and the 95% profile interval `[0.319, 0.652]` was finite, non-boundary, and contained truth. Compared with the earlier clamp-limited 16-tip fit, this supports weak information as a possible explanation but does not isolate it because the fixtures differ in seed and tree size. This is one interval, not calibration; full receipt is in `docs/dev-log/after-task/2026-10-20-bernoulli-phylo-sd-interval-smoke.md`.
- **Paired Bernoulli phylogenetic information diagnostics, 2026-10-20:** two seeded scripts preserve the same DGP to vary within-tip replication and group count. For one 16-tip seed, profiles clamped at both 12 and 100 observations per tip. On a separate 60-tip seed, the nested 16-tip and full 60-tip profiles were finite; the 16-tip interval was wider (`[0.157, 0.814]` vs `[0.319, 0.652]`) and covariance pruning matched to `2.22e-16`. These few fits support a role for group count and realized data in profile precision, not calibration or a group-count threshold. Full receipt is in `docs/dev-log/after-task/2026-10-20-bernoulli-phylo-sd-interval-smoke.md`.

The report validator confirmed the report structure, then exited 1 because the overall unlazy ledger still has unmet family, Julia, and calibration gates. Do not interpret the narrow Poisson extraction test as closing this programme.

- Native Bernoulli first-look calibration: clean-current 95% profile run v4 completed all 3,000 attempts on Totoro, 1,000 at each true log-SD slope (-0.5, 0, 0.5). All produced fits and valid intervals. The staged decision is `look2_required`; overall qualification is false. Coverage at -0.5 and 0 and the null false-positive gate remain ambiguous under the frozen Monte Carlo bands; +0.5 coverage passes. A separate source-pinned v8 look-two attempt stopped incomplete after 366 of 3,000 planned attempts in batch 1 and produced no calibration decision; that attempt remains historical failure evidence. Evidence and hashes are in `docs/dev-log/general-sd-regression/evidence/calibration-20261019/current-source-bern-095-first-look-v4/` and `docs/dev-log/after-task/2026-10-19-bernoulli-sd-first-look-calibration.md`.
- Bernoulli correlated-q2 point/output comparison: the live R bridge suite compares TMB and Julia on the same synthetic data. Fixed effects, both SD regressions, correlation, predicted group SD values, and group labels pass the tolerances stated in the test. The fixture has 64 group-level latent draws for seven fitted parameters; Julia emitted singular-Hessian diagnostics at `rcond=9.23e-10` (coordinate 7 flagged) and `rcond=3.879e-17` (no flat coordinate flagged). Treat this as a plumbing/rough point-alignment check, not evidence that every estimate is practically well identified. The focused Julia bridge command passed 112 assertions with five live tests; the native correlated-q2 suite passed 60 assertions. A new live bridge test now exercises response-scale q2 correlation target discovery, profile intervals and a five-refit bootstrap interval. This proves inference dispatch plumbing only: public Wald intervals and calibration remain unresolved. See `docs/dev-log/check-log.d/2026-10-19-julia-binomial-q2-correlation-inference.md` and `docs/dev-log/after-task/2026-10-19-bernoulli-q2-same-data-parity.md`.
- Julia Bernoulli SD bridge: the dedicated live test passed 95 assertions with four live tests on the paired dirty candidates, drmTMB `425bee81572c625a634b2b083050c5c57c1dc1f1` and DRM.jl `70dbf564eb670144c63c08f61ea099084d95add2`. Two q2-related singular-Hessian diagnostics were emitted. This supports four tested bridge cases only; general same-data parity, q2 parity and interval calibration remain open. See `docs/dev-log/after-task/2026-10-19-bernoulli-sd-julia-bridge.md`.
- Bernoulli phylogenetic SD verification: native fit/recovery/prediction passed 12 assertions; the R-side Julia fixture passed its six synthetic output assertions. On 2026-10-20, the direct Julia phylogenetic intercept suite passed 21 assertions and the live R/TMB-to-Julia bridge filter exited 0 with one live fit. Both same-data fits converged and the fixture checked SD coefficients, log likelihood, predicted group SDs, and tree-scale conversion. This remains one synthetic parity fixture, not multi-seed recovery or calibrated uncertainty. Report: `docs/dev-log/after-task/2026-10-19-bernoulli-phylo-sd-verification.md`; check log: `docs/dev-log/check-log.d/2026-10-20-bernoulli-phylo-sd-live-julia.md`.
- Poisson phylogenetic SD coefficient extraction: `split_tmb_parameters()` now returns the fitted `sd_phylo(...)` coefficient vector with its formula target and design-column names. The focused Poisson assembly/extraction test passed; its Julia bridge step ran no live engine test. The live cross-engine Poisson fixture previously had two strict prediction expectations derived from the other engine's coefficients. Its earlier lease ledger named `codex:general-sd-scale-roundtrip`, but the current lease listing no longer shows it; leave the file untouched pending the owner handoff Shinichi requested. See `docs/dev-log/after-task/2026-10-19-poisson-phylo-sd-extraction.md`.
- Direct Julia Poisson phylogenetic SD oracle: the test now passes 42 assertions, including an extreme-predictor regression that previously disagreed with the independent dense oracle (`2.56e14` vs `7.04e14`). The phylogenetic Poisson likelihood and mode derivatives now use a consistent unclamped predictor. This is candidate numerical evidence for that objective only; it does not establish cross-engine bridge parity or calibration. Receipt and hashes: `DRM.jl/docs/dev-log/after-task/2026-10-19-poisson-phylo-sd-oracle.md`.
- The dedicated Julia test required a task-specific writable depot because the default `/Users/z3437171/.julia` lock write was denied by the sandbox. Its final command completed in 123.9 seconds with zero test failures, warnings or skips; Julia printed numerical Hessian diagnostics. The generic `julia-bridge` filter is not Bernoulli SD evidence because its live fits were sigma-side.
- The DRM.jl CMR lane is active on separate CJS quadrature/profile paths. The lane reports no source overlap with this programme. Do not edit its files.
- NotebookLM methods synthesis remains in `docs/dev-log/general-sd-regression/research.md`. On 2026-10-20, CLI auth for `itchyshin@gmail.com` was restored and verified (`token_fetch=true`); the existing 14-source notebook was queried. Two source entries are blocked publisher pages, and the new response had no structured citation references, so it remains triage. Primary-source checks support only the qualified literature conclusions already in `research.md`; no general identifiability or calibration claim follows.
- The updated Bernoulli phylogenetic after-task report passes structural validation and prose check (0 findings); `git diff --check` passes. The validator exits 1 because all nine programme-wide unlazy gates remain open; the report is well-formed but the programme is open. No email, push, merge, release or publication occurred.
- The stage-two adapter and campaign-integrity fixture suite passed 36/36 tests in 3.8 seconds without launching model fits. This validates receipt and runner guard logic only.

Next: continue the Bernoulli first-delivery recovery and uncertainty gates, while selecting an unowned implementation row from the capability ledger. Do not start the second calibration look until the adapter gate and its timed pre-run are satisfied. Leave `tests/testthat/test-julia-poisson-sd.R` untouched pending the requested owner handoff.

---


State: ACTIVE; no production campaign is running. The corrected native Bernoulli first look completed 3,000/3,000 fits at 97.5% profile level. Its staged decision is `look2_required` and overall qualification is `FALSE`. A methods review found the frozen coverage/FPR bands do not match the 97.5% fitted interval target; no second-look fit was launched and no calibration claim is made. Full campaign outputs are copied under `docs/dev-log/general-sd-regression/evidence/calibration-20261017/first-look-postfix-20261019-v2/`; key hashes match the remote receipts. The original v8 second-look attempt remains incomplete historical evidence. All programme G0-G8 gates remain open.
Worktree: /Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression
Branch: codex/general-sd-regression, native base d89db50975d96d9c2bcb13046453ae34c7fcf49b.
Use /Library/Developer/CommandLineTools/usr/bin/git; system Git is an Xcode stub.
Read GOAL.md, ultra-plan.md, arcs.md, this file, then git status/diff before edits.

## Verified checkpoint

- Native commits4da1572958,7c3dec4ab and discrete checkpoint47262cd45 exist locally.
- Scalar Bernoulli selectors and native Poisson ordinary unlabelled-intercept SD
  regression now pass305 assertions from a fresh Totoro build. Source-only tests
  pass120 assertions across23 tests. The label repair preserves group identities
  in predict_parameters(). Poisson labelled base terms remain fenced and required.
- Compiled source capsule SHA eaf3198f9a703c4d88e21b106dc0c9dbe16fa8adef1235be83da33aa7167c417.
  Final library /home/snakagaw/hsq_work/drmtmb-general-sd-poisson-20261017-03/library.
  Evidence: docs/dev-log/general-sd-regression/evidence/poisson-20261017/output/.
  Fitted code is unchanged by two later reference-prose qualifications and one
  added source-only negative assertion; post-build-reconciliation.json records them.
- Selector and Poisson leaf gates are met; they cannot close programme breadth
  or calibration. Report: docs/dev-log/after-task/2026-10-17-general-sd-discrete-checkpoint.md.
- Required denominator19118 rows, including6750 explicit endpoint-subset candidates,
  1440 native tagged-q4 mirrors and122 Julia link-union additions. There are90 narrow exclusions;
  base-route classifications and candidate identifiability keep G0 open.
- Private Julia module commit70dbf564e passes25 numerical assertions only. Shared
  dispatcher/include ownership question remains pending; no public fit/bridge parity.
- NotebookLM personal browser is connected. Reviewed research and rejected generated
  report boundaries are in research.md. Do not revive the earlier signed-out block.
- DRAC Fir job65660299 completed in2min; one seed fit/profile13.715s, healthy with
  oracle discrepancy7.5e-9. Evidence: evidence/drac-smoke-20261017/. This is feasibility.

## Calibration state and next action

Original native source capsule ede274abff60b948a296a9d09f259249535a8172aaec738f700eeafb5096190e
matches the original Totoro library at /home/snakagaw/hsq_work/drmtmb-general-sd-20261017-01/library.
Use that pair for the first Bernoulli calibration, not current Poisson source with
an older binary. Eight source/binary artifacts matched the original pilot receipt.

The first qualification job at /home/snakagaw/hsq_work/drmtmb-general-sd-calibration-20261017-01
completed three workers from master1704, but the summarizer failed a subset-manifest
path assumption. Preserve it as failed workflow evidence. No production launched.
Its external registry seal is1ee65b061c35c401bc38ba4de835e3f3eef0b50bcbb75d1196fc7259bdbb1d35.
Do not modify its pinned source or library. Local external seal and manifests are
under evidence/calibration-20261017/.

The subset-path repair and conditional false-positive reporting passed independent
pure review. A staged decision analyzer is being built and independently reviewed
before a fresh whole-harness seal and live qualification. Freeze a two-look rule
before production:1000 per truth initially;4000 cumulative only for ambiguity;
97.5% intervals at each look preserve the proposed two-look error budget. Stage-two
seeds and integration are not yet frozen. No15-process stress or production run.

Next: finish/review staged analyzer and stage-two seed contract; freeze new harness;
prepare on Totoro, retain external registry SHA; rerun3-case qualification under120s.
After healthy full summary, measure contention with5 supervisors ×3 workers (15total),
same qualification seeds, explicitly timing repeats. Conservative188-wave projection
plus overhead must be<=3000s before starting the<=3600s production campaign.
Production master1703, qualification1704 and pilot1702 remain disjoint. Any stage-two
compute exceeding3h still needs measured pre-run results and explicit approval.

## Live agents and boundaries

- sd_design: independent calibration and staged-inference review, Sol high.
- sd_inventory: bounded pinned ordinary base-route audit, Luna medium.
- plan_review: pure staged-decision analyzer and contract, Luna medium.
- Root owns integration, native code, checkpoint and exact evidence receipts.

No email, push, merge, release, settings change or production campaign has occurred.
Keep the active goal running; this is a local production checkpoint, not a handoff.

## Update after the second live qualification

Qual02 completed all3 workers and its summary in11.4s, healthy valid profiles,
max absolute oracle discrepancy2.6e-8; overall_qualified correctlyFALSE for
qualification mode. Receipt: evidence/calibration-20261017/staged-qualification/.
It used source capsule e7563077... and registryf9ca91ea...; source remains immutable.
Final two metadata-integrity guards and contention orchestrator are being frozen
for the new15-process timing seal; no production or stress has launched.
The pure contention test catches late completion beyond120s and reaps owned children.

Limited package check of exact47262cd45 source passed its exit check in3m16s.
Two warnings are both omitted-vignette artifacts; tests/examples/vignettes/manual
were intentionally skipped. Evidence: evidence/package-check-20261017/.
A deletion guard rejected optional temporary-directory cleanup; source/check
artifacts remain, and the remote check process has ended. Do not bypass that guard.

Link-union accounting is being finalized at19118 rows: Julia probit/cloglog
are122 required counterparts (104 blocked base link,18 structural single-endpoint).
All90 structural exclusions remain narrowly no-second-endpoint rows. G0 stays open.
Exact initial agent model/effort dispatches are in dispatch-receipt.json;3 reused
children, at most4 active agents including root. Efficiency gate observed global
compaction/guardian thresholds; this disk-goaled lane continues under its explicit
checkpoint-and-roll exception. No fresh user task or settings change was created.

## Current state: production started, 2026-10-17 22:05 UTC

This section supersedes earlier pending-launch statements. Final15-process timing
passed all15 healthy profiles and five summaries, with verified peak concurrency15.
The conservative projection was2652.14s, or44.2min. Independent inference and launcher
reviews authorize this bounded first look. The estimate is45-60min, hard cap3600s,
16workers,120s per case, no retries. No result is a calibration claim until reviewed.

Remote job: /home/snakagaw/hsq_work/drmtmb-general-sd-calibration-20261017-03
Results: production-prepared/; supervisor PID2920795; local exec session65519.
Registry SHA: d2e1080d7cadb5679fc711a76cacd4e64a6b5326b5f6689c0492587bdd628a91.
Harness archive SHA: d36bd0dac4c7bb8a8d7ce7a82e70299c95dcc5774e4a0071ea8bf2692e7aea60.
Launcher SHA:43cb61b59777bc7d9b6c6e527e6dd17577b3fbd5ca70fc723239510d7130f6a9.
The launcher owns its supervisor and worker cleanup; do not kill unrelated processes.
Simulation meter: general-sd-bernoulli-first-look, registered to this supervisor.
First-output check:46 completed,16 started,2938 not started; one inspected completed
row had a finite profile interval, healthy optimizer and oracle error-2.87e-8.

Monitor using the existing socket /Users/z3437171/.ssh/cm-snakag@totoro.biology.ualberta.ca:22.
Read production-prepared/supervisor-receipt.json for exact case states, not the
simulation meter's approximate CSV starts. Poll local session65519 for final exit.
After exit, copy all results, logs, RDS, receipts and summary; authenticate, apply the
frozen staged rule, independently review, then retire the meter. Never rerun cases.
Stage-two9000 seeds are frozen and disjoint, but runtime integration and compute
authorization are not complete. First-look ambiguity does not authorize an unmeasured
large run. Native current branch47262cd45 is separate from the frozen Bernoulli build.

Current agent assignments: sd_design read-only next native effect audit, sd_inventory
ordinary-base source audit, plan_review read-only Julia ownership/output audit.
Julia shared dispatcher/include ownership remains pending human answer.

## Native Gamma independent-slope SD slice, 2026-10-18

The current native Gamma adapter admits one independent numeric `mu` slope as an
SD target, retaining complete-response and fixed-`sigma` constraints. Gamma
model type 7 reports effective, soft-clamped group log-SDs for clamp diagnostics.
Assembly tests failed before the adapter change at the expected intercept-only
guard. Focused assembly passed17 assertions; focused integration passed23,
including deterministic synthetic slope recovery, prediction, simulation, and
save/reload. The first recovery sample was slightly outside the unchanged2.5-SE
rule, so group and repeat counts were increased with the truth, seed, and rule
fixed; the rerun passed. Evidence report:
`docs/dev-log/after-task/2026-10-18-gamma-independent-slope-sd.md`.
This is native point/recovery evidence only; Julia slope parity and interval
calibration remain open. Programme gatesG0-G8 remain open.

## Label and guide checkpoint, 2026-10-17 22:23 UTC

Poisson unique scalar labels now have39 source expectations and154 compiled
expectations on repaired capsule6ad295b3bed294db34bc32fd3dc59028942e5b38c1cb202576be55e994aa58d6.
R runtime d88ff6046bffa9f57aa258c0e19e1adf4ee46c7c8e05cfcf297420a27d7efe46.
The new gate is ordinary complete-data only; structured partners, missing-response
mode, NB2labels and labelledslopes remainfenced. Two negatives fail against the
earlier2cab capsule and pass now. Build/tests completed60s in separateTotoro job02.
Independent review, logs and manifests: evidence/poisson-label-20261017/.

The synthetic guide's two small fits executed on the earlier matching unlabelled
path, then HTML rendered locally and was visually inspected. v2sourceSHA9678c6d5caf89c8fc72a883f3d83532e0fe1d70e2c1f2cce7be0f419ea7e7150.
Compact diagnostics replace wide messages; known and fitted SD ratios remain
visible. Temporary localhost server PID10012 was stopped and browser tab closed.
No site deployment. Report2026-10-17-general-sd-label-and-guide-checkpoint.md is
exact-draft assessed atSHA7d14e48d4c4ee5944e35e7ee18a88a00932a3ec5faf3b1fb85bd92802f90c8eb.

Pinned ordinary base audit224 rows now fully source-classified: native52admitted/60blocked,
Julia16admitted/96blocked. Provider-prerequisite and G1open-contract reviews keep
G0/G1open. Latest production operational readback1104completed,16started,1880notstarted;
no interim coverage/bias decision. Supervisor2920795/session65519 still owns it.

Next native leaf: Poisson unique independent slope SD. Ledgerpoisson-slope.md exists
before implementation; independent scalar reference24expectations pass. New assembly
tests are RED at the current slope-admission fence, log/private/tmp/drmtmb-poisson-slope-red.log.
No slope admission code has been written yet. Commit verified foundation andlabel/guide
checkpoint before changing shared target admission. BroaderprogrammeG0-G8allremainopen.

## Poisson slope checkpoint, 2026-10-17 22:44 UTC

Local commitsad50858dc andb68417773 retain the programme foundation andlabel/guide
checkpoints. Native Poisson unique independent numeric slope SD now passes18source
and24independent-reference expectations. The fresh capsule6adcfc2451dc79367c60d3383fea673617480b5a88c6147ae0dc90d2a1376794
built successfully; corrected compiled/regression suite235expectations passes.
Initial profile assertion failure is retained, with test-only source reconciliation
and unchanged R/C++ runtime. Scope excludes mixed/crossed slopes, correlated blocks,
labels, structured/mi partners and other families. No slope calibration claim.
Evidence and reviewed after-task report: poisson-slope-20261017.

Production first-look supervisor2920795/session65519 remains active near its
45-60min estimate. Read operational counts only until terminal summary. Stage-two
execution design exists, with replica1001:4000 mapping and historical seed-label
preserved; no adapter or second-look launch. A qualified measured<=3h stage-two
run is covered by existing approval when the frozen first-look rule requires it.
Next: collect/authenticate first-look outputs; independently review stageddecision.
Native next leaf islognormal ordinary intercept SD; independent exact marginal
reference exists and source assembly RED tests are being prepared.

## First-look terminal state, 2026-10-17 22:46 UTC

Poisson slope checkpoint is local commit425bee81572c625a634b2b083050c5c57c1dc1f1.
Bernoulli first look finished with exit0: all3000 cases completed in2240.69s,
with no retries. The frozen decision is `look2_required`. Its only ambiguous gate
is coverage at a=-0.5:935/1000,97.5% CI[.9154,.9513], overlapping the declared
[.925,.975] band. Other12 gates pass; `overall_qualified` is FALSE. This is not acceptance.

Full9014-file evidence archive SHA:
4a5ba8a8f1092e366762b02cf733197a8c96ba8f4dd6d979b1fa71792286beb8.
Local archive: evidence/calibration-20261017/production-complete-evidence.tar.gz.
Extracted: /private/tmp/drmtmb-first-look-complete-20261017; compact receipts: first-look/.
Simulation meter retired; supervisor2920795 and session65519 finished with exit0.
Independent Sol inference audit is pending. Luna owns the new stage-two adapter
directory only. No second-look remote preparation or launch has occurred.
Measured3x37.35min=112min before conservative overhead. Qualify the adapter and
measure timing again before a run bounded at175min under the existing approval.

Lognormal ordinary-intercept SD R/C++ source changes are uncommitted. Source
positive cases pass apart from a test NULL-map assertion under repair. The
independent exact reference passes8 assertions. Root owns R/C++; sd_inventory owns
lognormal tests; plan_review owns the stage-two adapter; sd_design owns inference
review. Do not mix the current lognormal runtime with an older DLL.

## Native lognormal ordinary-intercept checkpoint, 2026-10-17

The ordinary location marginal simulator now uses the fitted group-specific SD
for every admitted ordinary mu SD route, not only binomial and Poisson. Structured
modeled scales, multi-coefficient covariance blocks, and correlation-pair routes
remain guarded. Fresh Totoro package build and compiled lognormal integration pass
24 expectations; the Bernoulli simulation regression passes15. The lognormal suite
includes an independent scalar marginal-likelihood oracle, wrong-group-design
negative control, profile/save-reload/bootstrap checks, fresh-effect variance-ratio
check, and constant-SD reduction. Source hash:
`bad56b4bf70e56972bc1fde2a10a578690789ccca6159e131e09e54176870ffa`.
Receipts: `docs/dev-log/general-sd-regression/evidence/lognormal-20261017/`.

`tools::checkRd("man/simulate.drmTMB.Rd")` and `pkgdown::check_pkgdown()` pass.
After-task report: `docs/dev-log/after-task/2026-10-17-general-sd-lognormal-marginal-sim-checkpoint.md`.
Full G0-G8 remain open. No Bernoulli interval-calibration qualification or Julia
public parity claim is supported by the lognormal slice.

Stage-two Bernoulli calibration adapter remains blocked pending its bounded fixes
and a fresh independent review. Do not prepare or launch the second look until that
review is GO. NotebookLM UI is signed into the requested personal account and has
a corrected methods review; CLI/MCP authentication remains unresolved because
Chrome-cookie refresh could not decrypt the Keychain values. This does not block
the code work. Roxygen also regenerated unrelated Rd pages; a guarded restore was
rejected under D-322, and the generated pages remain for review.

Next: finish the stage-two adapter contract and tests, obtain independent review,
then follow the frozen feasibility and compute gates before any calibration run.

Fresh independent review on the adapter returned NO-GO. Although the schema,
timing, timeout, and existing replay issues are repaired and the current pure
tests pass, a unique mutation to any prior seed row or truth/design field still
passes prior-stream validation. Registry creation also silently skips absent
mandatory adapter files. The owner is fixing both with fail-closed checks and
negative controls. No preparation, capsule, fit, or launch is authorized by this
review. Re-review is required after the repair.

## Updated evidence-integrity state — 2026-10-17

The scoped first-look reconstruction and result-digest repairs are complete.
Local Python tests pass 19/19; Totoro capsule-04 passes the same suite, the R
stage-two rules, and the copied-manifest registry test. The v2 seal
`67bcd657226c168477c041710e7f1e6e12eadde4a305da97b2275cba256dafb0` binds the
original seal, independently pinned archive, all 3,000 raw results, and five
source hashes. Full R replay verifies 3,000 standardized rows and reproduces
`look2_required`. Exact local artifact hashes and source-file checks are in
`docs/dev-log/general-sd-regression/stage-two-execution-design.md` and the
matching evidence directory. The earlier v1 reconstruction remains preserved
but lacks the source map and must not be used for later preparation.

The source-provenance and worker-partial-result findings are closed by the
focused independent reviews. The earlier adapter review also raised prior-row
validation and mandatory-file-registry findings; although current pure tests
now include those negative controls, a fresh whole-adapter review has not yet
confirmed closure. Keep G0-G8 open. No second-look batch is prepared, and no
additional model fit has run. The NotebookLM MCP server now confirms an active
personal session; this supersedes the earlier authentication warning.

The independent v2 artifact audit passed: the seal, replay receipt, and CSV
hashes match; all five sealed source hashes match current code; the receipt
binds the seal, source map, attempt digest, and CSV; and the table has 3,000
look-one rows. This confirms provenance and replay consistency only.

Next: request a fresh independent whole-adapter review against the current
source and v2 seal. If it clears the remaining gates, record a time estimate
before running the exact-source three-row adapter qualification. Keep the
9,000-fit second look gated on the measured runtime and its existing approval.

## Julia Bernoulli SD recovery and interval routing, 2026-10-17

The public Julia Bernoulli SD bridge test now checks one seeded recovery case at
300 groups, coefficient extraction, group SD outputs, fresh-data prediction,
RDS round-trip, profile target routing, and a three-refit bootstrap smoke check.
The live test passed with coefficient tolerance 0.25. A 120-group run with the
same seed estimated the log-SD slope at 0.20 versus truth 0.50 (about 2.2 SE);
this failure is retained as finite-sample evidence, not hidden by widening the
tolerance. At 300 groups the diagnostic fit converged and estimated intercept
-0.270 (truth -0.223, SE 0.082) and slope 0.512 (truth 0.500, SE 0.138).
Neither single-fit result establishes recovery calibration or interval coverage.
The phase report is `docs/dev-log/after-task/2026-10-17-julia-bernoulli-sd-inference-routing.md`.

A fresh read-only inference review of the second-look adapter returned NO-GO,
including for the three-row qualification preparation. The current adapter source
hashes differ from the v2 seal. The named-vector versus unnamed-JSON comparison
was repaired through `native_sd_stage_two_hash_maps_equal()` and current Python,
R rules, prior-seed, and registry tests pass. The v2 seal remains stale, so do
not prepare or run the qualification probe until a fresh source-bound seal is
retained and an independent review confirms the current source snapshot. This review does not change the
separate 9,000-fit campaign gate.

## V7 adapter qualification, 2026-10-18

The source-bound v7 three-registry Totoro probe is complete and passed in
60.2931 seconds. All three selected Bernoulli fits converged, produced valid
profile intervals, and passed the independent Laplace likelihood oracle. The
qualification receipt SHA-256 is
`5f7ace0329835c5db4f4ce46bce1d3046e37285a4f4f08e2d5a549ca892aed20`; the
externally retained preparation digest is
`148667c74bdfddd5d7260b4c15656deb89f4550003f3394b2caaed0012685598`.
Independent review rehashed all three local registry, manifest, supervisor,
and selected result files. Python tests pass 28/28; R stage-two rules and
prior-seed negative controls pass.

This is adapter qualification only. It records three attempts, not 9,000, and
sets `calibration_claim=false` and `campaign_complete=false`. The first-look
decision remains `look2_required`. A retained 15-process timing receipt
projects 7,956.41 seconds across three batches. Its registry matches the current
`worker.R` SHA-256
`166d35a2b06a3e72206942857f3ef06beec8d855cd0a00a65cd8445e646d9480` and the
v7 installed DLL SHA-256
`2f1b305ff24db9691507d60a5d0025e99cb41c02e0ed1bf32eb71f1e1ce156f2`. It is
below the 10,500-second hard cap. No GO record or second-look capsule has been
created yet. Julia parity and remaining family/effect support remain open.

After-task report:
`docs/dev-log/after-task/2026-10-18-general-sd-adapter-seal.md`.

## Julia Bernoulli SD live parity check, 2026-10-18

The DRM.jl Bernoulli SD regression and public-output tests pass 55/55 checks.
They cover a seeded slope-recovery fit, equivalence to a one-trial binomial,
an independent fixed-parameter likelihood integral, prediction and extraction,
profile output, bootstrap refit plumbing, and explicit unsupported-cell errors.
The `drmTMB(engine = "julia")` Bernoulli bridge test also passes with one live
Julia test recorded. This is one high-information recovery case and interval
plumbing evidence, not calibrated uncertainty. During JuliaCall startup,
LogExpFunctions emitted a non-fatal extension precompile error for
`loglogistic`; the fit and test completed, but the environment warning needs
triage before claiming a clean bridge run. Remaining families, effect types,
uncertainty calibration, and the interrupted Totoro second look remain open.

## Julia Gamma independent random-slope SD, 2026-10-18

The Julia Gamma SD route now covers one ordinary mean intercept or one
independent numeric mean slope, with fixed `sigma ~ 1`, complete responses,
and group-constant SD predictors. The focused Julia Gamma tests pass 32/32,
including an independent groupwise quadrature oracle. The new seeded slope
example recovered log-SD coefficients `(-0.8661, 0.5510)` for truth
`(-0.75, 0.50)`. The public `drmTMB(engine = "julia")` bridge tests pass
24/24 across Gamma intercept and slope; convergence was checked with the
public diagnostic and the rowwise SD mapping passed. JuliaCall still emits
the non-fatal LogExpFunctions `loglogistic` extension warning.

This is one seeded recovery and integration check, not interval calibration.
Native TMB Gamma SD regression remains intercept-only in this lane, so Gamma
slope parity is still open. Correlated and structured effects, other family
routes, full package checks, and calibrated uncertainty also remain open.
Report: `docs/dev-log/after-task/2026-10-18-julia-gamma-sd-random-slope.md`.

## Native beta-binomial SD focused verification, 2026-10-18

The current branch's `devtools::test(filter = "beta-binomial-sd")` completed
with 24 passed, 0 failed, 0 warnings, and 0 skips in 135.0 seconds. The
integration file passed 15 expectations, including the independent
groupwise marginal-likelihood oracle; the regression file passed 9. This is
focused validation of the native beta-binomial ordinary-intercept slice only.
It does not establish interval calibration, broader effect/provider support,
or Julia parity. The filter reported zero live Julia tests, so no Julia
execution is claimed here.

## Effective log-SD report consistency follow-up, 2026-10-18

The ZIP regression now also checks response-scale prediction against the
reported effective group SD, in addition to the existing report and link-scale
checks. Focused verification passed 33/33 expectations (15 integration and 18
regression), 0 failures, warnings, or skips, in 62.2 seconds. This strengthens
the clamp consistency check on the ZIP route only. The shared C++ comment at
`src/drmTMB.cpp:42` still says the raw predictor is reported; lane preflight
found 61 refs with edits missing from this checkout, so that shared file was
left untouched pending reconciliation. Programme gates remain open.

## Effective log-SD report consistency, 2026-10-18

Independent review found that several TMB family branches stored the raw SD
linear predictor in `log_sd_mu_group` while using its soft-clamped value to
construct `sd_mu_group`. A clamp-active regression test failed before the fix:
the TMB report returned 4.00 while the effective and public-prediction value
was 3.75. The five raw-report branches now store the clamped log SD and use
that same value to exponentiate the group SD. Rebuilt focused zero-inflated
Poisson tests pass 32/32, including the test that failed before the fix. This
is a report-consistency repair; no likelihood or admission boundary changed.
Full suite, family-wide clamp fixtures, Bernoulli interval calibration, and
programme gates remain open.

## Gamma slope cross-engine check, 2026-10-18

The Julia Gamma random-slope SD implementation was already present in the
shared Julia worktree. Its focused suite passed 32/32 assertions, including an
independent quadrature oracle. The live R bridge suite passed 26/26 assertions
with two live Julia fits; the same-data coefficient comparison against native
TMB passed at tolerance 0.2. JuliaCall emitted one non-fatal dependency-install
warning (`LogExpFunctionsInverseFunctionsExt`, `loglogistic` undefined). This
closes only the exact Gamma intercept/slope parity check, not broad parity or
interval calibration. See
`docs/dev-log/after-task/2026-10-18-gamma-independent-slope-sd.md` and the
matching check-log shard. All programme gates remain open.

## Julia Poisson independent random-slope SD reverified, 2026-10-18

The Julia Poisson focused suite passed 35/35 assertions, including slope
recovery, an independent likelihood integral, the intercept baseline, and
unsupported-design checks. The public R-to-Julia bridge passed 22/22 assertions
with two live Julia fits and a same-data native TMB coefficient comparison
within 0.25. JuliaCall emitted one non-fatal `LogExpFunctions` extension error
(`loglogistic` undefined) during setup; the bridge fits completed. After the
latest formula-guide edits, `pkgdown::check_pkgdown()` again reported no
problems, with only Pandoc `--mathml` deprecation notices. This verifies the
single Poisson intercept/slope route and its public bridge; it does not cover
interval calibration, other effects, or the remaining family/backend rows.
See `docs/dev-log/after-task/2026-10-18-poisson-julia-slope-bridge.md` and the
matching check-log shard.

## Bernoulli native integration and live Julia route, 2026-10-18

`Rscript -e 'devtools::test(filter = "binomial-sd-integration")'` passed
52/52 expectations in 252.8 seconds: 37 Bernoulli and 15 beta-binomial,
with zero failures, warnings, or skips. This is native integration evidence.

The first Julia bridge attempt skipped two live tests because the engine path
was not admitted by the runner. With `DRM_JL_PATH` set to the paired
`general-sd-julia` checkout and `DRMTMB_JULIA_TESTS=true`, Julia reached
version 1.10 but could not write `~/.julia/logs/manifest_usage.toml.pid` in
the sandbox. A rerun with a writable temporary depot first and the existing
depot second passed 55/55 expectations in 91.1 seconds, including two live
Julia fits. This verifies public fitting, recovery smoke, prediction and
bootstrap-refit plumbing; it does not establish interval calibration.

Check-log entry: `docs/dev-log/check-log.md`. Bernoulli calibration remains
open. The Totoro ControlMaster socket could not be accessed from this sandbox
(`Operation not permitted`), so no remote run state was inferred or changed.
The previous incomplete stage-two receipt remains non-calibration evidence.

The separate native marginal-simulation suite also passed 15/15 expectations
in 3.5 seconds. Its tests cover simulation plumbing and per-coefficient SD
scales; they are not a fitted-parameter recovery campaign. See the next
check-log row for the exact scope.

## Bernoulli same-group independent coefficient SDs, 2026-10-18

Native TMB now accepts separate coefficient-selected SD formulas for distinct
independent q=1 terms sharing one group, such as an intercept plus a slope.
A bare `sd(id)` remains ambiguous; correlated-block SD targets remain rejected.
The selector tests pass 55/55, including the correlated-block negative control.
The integration filter passes 381/381 in 267.8 s and includes fitted recovery,
public coefficient-specific predictions, and an independent 2D Laplace oracle.
`location-scale-scale.Rmd` renders. Docs describe this as native-only; Julia's
Bernoulli implementation still requires one term and one SD formula. No
interval-calibration claim is supported. See
`docs/dev-log/after-task/2026-10-18-binomial-same-group-coefficient-sd.md`.

Documentation verification note: both affected vignettes rendered; the
formula-grammar table render disabled chunk evaluation. `pkgdown::check_pkgdown()`
found no problems. A full temporary site build stopped before article rendering
because the sandbox could not resolve cdnjs to fetch Headroom. No generated site
was produced; retry only when network access is available.

## Bernoulli random-slope cross-engine check, 2026-10-18

The live R bridge filter `devtools::test(filter = "julia-binomial-sd")` passed
58/58 assertions in 51.1 s with two live Julia tests and zero failures,
warnings, or skips. One seeded Bernoulli random-slope dataset now fits in both
Julia and native TMB; their SD coefficients agree within absolute tolerance
0.35 and group-SD predictions within 0.45. The same test retains truth-recovery
checks, and Julia's suite includes an independent scalar-normal likelihood
oracle. This supports one cross-engine point-fit comparison only. Same-group
coefficient-specific formulas in Julia, interval calibration, structured
effects, and the complete capability matrix remain open. See
`docs/dev-log/after-task/2026-10-18-bernoulli-slope-cross-engine-check.md`.

## Julia selected-SD bridge follow-up, 2026-10-18

The R-to-Julia bridge now keeps a sole explicitly selected ordinary SD target
under the stable `sd` model block and resolves it back to the formula-level dpar
for public extraction and prediction. A combined live run passed 73 assertions
across Beta, Gamma, NB2, and Poisson bridge tests; Poisson-only rerun passed 23.
The combined run emitted two existing deprecated `beta()` family-probe warnings.
Closeout: `docs/dev-log/after-task/2026-10-18-julia-selected-sd-bridge.md`.
This verifies selected one-target workflow and point-estimate parity in the
listed cells only. Multiple targets, other families/effects, and uncertainty
calibration remain open; G0-G8 remain open.

## Julia same-group Bernoulli two-target bridge recheck, 2026-10-18

A fresh live R-to-Julia run of `julia-binomial-sd` passed 70 assertions across
three bridge tests in 82.8 s. This includes two separate selected SD formulas
for an intercept and independent slope sharing one group, coefficient and
prediction outputs, and profile/bootstrap target routing. Julia emitted
Hessian singularity diagnostics during refit checks; uncertainty calibration is
not established. The earlier note saying Julia lacks multiple selected SD
formulas is superseded for this Bernoulli independent-scalar cell only; other
families and correlated/structured blocks remain open. See
`docs/dev-log/after-task/2026-10-18-julia-bernoulli-two-target-bridge.md`.

## Native Student SD oracle recheck, 2026-10-18

The focused native Student SD integration/regression filter passed 34 assertions
(15 integration, 19 regression) with no failures, warnings, or skips in 13.9 s.
This verifies the independent fixed-parameter Laplace oracle, wrong-group
negative control, synthetic recovery, constant-SD equivalence, public prediction,
save/reload, and profile/bootstrap target-routing smoke. It does not establish
Student interval calibration or Julia Student support. The wave plan and adapter
map now record this evidence; independent review and G0-G8 remain open. See
`docs/dev-log/after-task/2026-10-18-student-sd-oracle-reverification.md`.

## Julia Student SD extension, 2026-10-18

The paired Julia worktree now admits one ordinary Student-t mean intercept or
one independent numeric mean slope with fixed `sigma ~ 1` and `nu ~ 1`, using
`sd(group) ~ z` or the matching `coef(intercept)` / `coef(x)` selector. The
focused SD suite passed 36 assertions, including signed recovery, independent
fixed-parameter QuadGK integrals with the row-level slope loading, coefficient-
SD predictions, and bootstrap-refit smokes. Existing Student intercept,
correlated-slope, and ordinary-Laplace suites passed 30 assertions. This is not
interval calibration, full-suite validation, or R bridge parity. Native
Student-slope parity and Julia Student correlated/structured SD effects remain
open. See the Julia paired worktree's report
`docs/dev-log/after-task/2026-10-18-julia-student-sd-regression.md`.
The native Student review and Bernoulli stage-two execution remain separate
open work; G0-G8 remain open.

## Bernoulli phylogenetic SD timing and recovery pilot, 2026-10-19

An ADEMP pilot design and a seeded DGP runner now cover 16 or 60 tips and 12
or 100 observations per tip. The final v4 Totoro run completed 12/12 fits.
Profile outcomes were 8 finite non-boundary intervals, 3 clamp-limited
intervals, and 1 profile failure; 7/8 returned intervals included the true
slope. Treat this as a timing and recovery smoke, never as interval coverage.
The largest cell median fit time was 6.568 s, and the maximum covariance
submatrix difference was `2.22e-16`. The exact tarball, installed binary,
runner, environment, seeds, and v1-v4 ledgers are under
`docs/dev-log/general-sd-regression/evidence/phylo-calibration-pilot-20261020/`.

The after-task structure check passed. All nine general-programme gates
G0-G8 remain open, so the overall goal remains incomplete. This phylogenetic
pilot did not start a production campaign. The separate Bernoulli look-two
attempt stopped incomplete after 366 of 3,000 planned attempts in batch 1;
it produced no calibration decision. See the stage-two execution design
and Bernoulli pilot-qualification report.

The local recovery summarizer was rerun from all 12 retained v4 attempts. It reports per-cell slope bias 0.134, 0.374, -0.005, and -0.043, and RMSE 0.994, 0.539, 0.210, and 0.049. Three replicates per cell make these descriptive only. Exact summarizer and output hashes are in the evidence README.

## G0 denominator artifact integrity, 2026-10-20

Added source-table hash pins for the four finite universe inputs and a test
that requires the checked-in 19,118-row TSV and summary to match the current
deterministic expansion. The generator now validates both artifacts after
writing them, and negative-control tests confirm that a stale TSV or summary
is rejected. The full universe suite passes 17 tests. These checks protect
input and artifact consistency; they do not show that every candidate row is
classified or close G0. The shared check-log and after-task paths remain under
other live leases, so this checkpoint records the work without editing those
files.

## 2026-10-20 Poisson animal precision-input SD evidence

The native Poisson animal q1 direct-SD route passed with `Ainv = Q` on a
seeded synthetic DGP generated from `A = solve(Q)`. The dedicated test passed
10 assertions, including non-identity matrix ordering, SD-slope recovery,
group-SD prediction, and constant-SD likelihood equivalence. Independent
static review passed. No production likelihood code changed. This is native
point-recovery evidence only; no live Julia fit or interval calibration ran.
Details: `docs/dev-log/after-task/2026-10-20-poisson-animal-ainv-sd-evidence.md`.

## 2026-10-20 Poisson animal pedigree SD evidence

The native Poisson animal q1 direct-SD test now checks that the sparse pedigree precision, reordered by its labels, equals the inverse of the dense additive relationship matrix. The focused test passes 11 assertions, including SD-slope recovery, name-keyed group predictions, and constant-SD equivalence. Independent static review passed the DGP and ordering checks. The combined animal, relmat, and grammar tests passed 95 assertions with one existing `sd_phylo()` deprecation warning and no failures or skips. `pkgdown::check_pkgdown()` found no problems, and `graft build` refreshed 29,642 nodes / 58,167 edges. The after-task structure check passed; programme-wide acceptance verification reports 11 unrelated unmet gates. G3/G4/G6 evidence remains partial. No production likelihood code changed; Julia parity and interval coverage remain outside this slice and open for the programme.

## 2026-10-20 Binomial animal pedigree SD evidence

Added a seeded native binary-response test using the pedigree animal intercept and predictor-dependent SD. The focused test passed 10 assertions with no warnings, failures, or skips. It checks the sparse precision against the dense covariance inverse, log-SD slope recovery, group predictions by animal name, and constant-SD equivalence. The combined animal, relmat, and grammar regression filter passed 105 assertions with one existing sd_phylo() deprecation warning and no failures or skips. Independent static review passed. The result extends evidence for one native family-provider combination only; it does not establish live Julia support or interval calibration. Report: docs/dev-log/after-task/2026-10-20-binomial-animal-pedigree-sd.md.

## 2026-10-20 Gamma relatedness-matrix direct-SD point-fit row

The native Gamma q1 `relmat()` direct-SD test passes 11 assertions for positive
slope recovery, group-named SD predictions, and constant-SD equivalence. The
kernel labels are reversed relative to factor order, exercising name-based
mapping. The random-SD tutorial now contains a synthetic relatedness example.
This remains one native point-fit row with no interval-calibration or Julia
parity claim. G3, G4, G6, G7, and G8 remain open; G5 remains deferred.
Report: `docs/dev-log/after-task/2026-10-20-gamma-relmat-sd-regression.md`.

## 2026-10-20 Gamma coordinate-spatial direct-SD regression

One native Gamma q1 coordinate-spatial `mu` intercept now accepts
`sd(site, level = "spatial") ~ z`. The focused synthetic test passed 11
assertions for trend recovery, site-named SD prediction, and constant-SD
equivalence. The predictor-dependent SD vignette and capability maps now
record the exact route. This does not establish interval calibration, Julia
parity, or mesh/SPDE SD support. G3, G4, G6, G7, and G8 remain open; G5 is
deferred.

Report: `docs/dev-log/after-task/2026-10-20-gamma-spatial-sd-regression.md`.

## 2026-10-20 Beta-binomial animal-pedigree marginal simulation

The native complete-data Beta-binomial q1 animal-pedigree `mu` intercept
already fit with a predictor-dependent SD. Its marginal simulation guard had
not admitted this model type. After confirming the guard was the blocker, the
focused test was extended to require two simulated count vectors with the
observed row count and values bounded by the trial total. It failed before the
guard change with the explicit heteroscedastic-scale error and passed after
adding Beta-binomial to the existing supported structured-count list. The full
focused test file now passes, including recovery, named predictions, founder
mapping, constant-SD equivalence, within-animal predictor rejection, and
marginal simulation. This is native point-fit/workflow evidence only; Julia,
A/Ainv, other providers, and interval calibration remain open. Programme gates
G3, G4, and G6 receive partial evidence only and remain unchecked. See
`docs/dev-log/after-task/2026-10-20-beta-binomial-animal-sd.md`.

## 2026-10-20 Beta-binomial animal matrix-input SD evidence

The Beta-binomial animal q1 direct-SD builder already accepts supplied
covariance `A` and precision `Ainv`. New tests fit both inputs from the same
synthetic pedigree DGP, jointly permute matrix labels, and check convergence,
log-SD slope recovery, observed-animal SD predictions, and likelihood
agreement with the pedigree fit. The focused file passes without production
code changes. The formula grammar, scale guide, limitations, adapter map,
inventory, NEWS, and tutorial now identify all three tested matrix inputs.
This is native point-fit and output evidence only; Julia parity, other
providers, interval calibration, and programme completion remain open. G3,
G4, and G6 gain partial evidence only. See
`docs/dev-log/after-task/2026-10-20-beta-binomial-animal-matrix-sd.md`.
## 2026-10-21 NB2 animal-model SD regression

Native NB2 now fits one complete-data q1 animal location intercept with
`sd(id, level = "animal") ~ z`, using a pedigree-built relationship structure.
The nine-expectation focused test passed for point recovery, animal-level SD
prediction, constant-SD likelihood equivalence, and rejection of a predictor
that varies within animal. The predictor-dependent-SD vignette rendered from
the loaded current worktree source, and `pkgdown::check_pkgdown()` found no
problems beyond existing Pandoc MathML deprecation warnings. The broad NB2,
Student-t, and animal-test filter completed with eight failures, so broad
regression status remains open. This route has no Julia-parity or
interval-calibration evidence and does not combine with ordinary random
effects, zero inflation, slopes, correlated blocks, or random `sigma`. G3, G4,
and G6 gain one row of partial evidence only; all programme gates remain
open.

Report: `docs/dev-log/after-task/2026-10-21-nbinom2-animal-sd.md`.

## 2026-10-21 Gamma animal slope-only SD regression

Native complete-data Gamma now admits one q1 animal location slope-only
coefficient with a group-level SD predictor and fixed `sigma`. The focused
Gamma slope and intercept suites passed (10 and 14 expectations). The guide
rendered with the current worktree loaded, `devtools::document()` completed,
and `pkgdown::check_pkgdown()` reported no problems. The structural-slope map,
help page, formula guide, NEWS, known limitations, adapter map, and inventory
record the exact route. It remains point-recovery evidence only; Julia parity
and interval calibration are open. The independent read-only reviewer found
the stale blanket wording in the structural-slope map, which is now qualified.

Report: `docs/dev-log/after-task/2026-10-21-gamma-animal-slope-sd.md`.

## 2026-10-21 Beta ordinary SD recovery smoke and next blocker

The Beta ordinary intercept and independent-slope smoke tests passed 26
expectations with `NOT_CRAN=true`; the existing Beta intercept/slope integration
files also passed. The adapter map, check log and after-task report now record
the limited native point-recovery evidence. The after-task structure check and
prose slop check pass. Julia parity and interval coverage remain open.

A separate focused rerun confirmed the NB2 structured-sigma test and both
Poisson animal SD regression files pass. `test-student-sd-regression.R` has one
additional failure: its expected rejection of a phylogenetic SD formula does
not occur. The Student builder currently classifies `sd_phylo()` syntax but
can drop it when the matching structured effect is absent. This is a confirmed
input-validation defect, not evidence that Student phylogenetic SD is
implemented. The fix touches `R/drmTMB.R`, which the live
`gaussian-animal-direct-sd` lease owns; the lease tool refused our overlapping
claim. Do not bypass it. Resume this fix after that owner releases the source
file, then rerun `NOT_CRAN=true` focused Student SD checks.

The active goal now states that interval coverage is deferred and not a finish
gate for the implementation phase. The broader family/effect and Julia
acceptance gates remain unmet.

## 2026-10-21 Student-t ordinary SD integration and objective reconciliation

Current-source `test-student-sd-integration.R` passed with `NOT_CRAN=true`.
It checks independent grouped Student-t recovery, a separate Laplace
log-likelihood oracle, reversed-group predictor control, coefficient and SD
prediction behavior, simulation, save/reload, profile intervals, and two
bootstrap refits. These are route-level and interval-workflow checks, not
coverage calibration. The focused `test-student-sd-regression.R` still has one
failure: a structured phylogenetic SD formula is accepted without an error and
then omitted from the built spec. The correction remains pending release of
the live `gaussian-animal-direct-sd` lease on `R/drmTMB.R`.

The active Codex objective still requires calibrated uncertainty. The local
implementation ledger currently defers coverage outside its active acceptance
tree. Treat that as a phase boundary only; the full goal remains open until the
calibration requirement is met. The `.unlazy` ledger itself has a live lease,
so this checkpoint does not alter it.

## 2026-10-21 Structured SD silent-drop guard

The Student-t, skew-normal, and zero-one-beta builders each classified
structured SD formulas but did not place them in the returned model
specification. Before the fix, the Student phylogenetic rejection test and new
skew-normal and zero-one-beta animal-SD rejection tests all failed because the
builders returned a spec. A shared guard now errors with the requested effect
class instead of silently changing the model. All three focused family SD
regression files pass, including their ordinary intercept or slope assembly
checks. The adapter map and task evidence are updated.

This is an input-validation repair, not structured SD fitting. No Julia engine,
recovery campaign, or interval calibration was run. The broad objective still
requires all supported family/effect combinations, Julia parity, and calibrated
uncertainty. The live Gaussian animal lane's tests and design notes were left
untouched; this slice has separate path-scoped leases and its own check-log
fragment. See `docs/dev-log/after-task/2026-10-21-structured-sd-silent-drop-guard.md`.

## 2026-10-21 Hurdle NB2 location-SD route: test-first checkpoint

The next bounded implementation candidate is one complete-data hurdle NB2
location random intercept, with fixed `sigma` and `hu` intercepts and
`log(tau_g) = alpha_0 + alpha_1 z_g`. The positive-count component uses the
existing NB2 parameterization; `hu` remains the probability of a zero. No
random effects on `hu`, random slopes, structured providers, or interval
coverage claim are included in this slice.

The symbolic-to-test alignment is:

| Symbol | Formula or code | Synthetic truth | Recovery check |
| --- | --- | --- | --- |
| `alpha_0`, `alpha_1` | `sd(id) ~ z` | `(-1.0, 0.35)` | `coef(fit, "sd(id)")` |
| `u_g` | `(1 | id)` | `Normal(0, exp(alpha_0 + alpha_1 z_g)^2)` | latent intercept SD regression |
| `eta_mu` | `count ~ x + (1 | id)` | `0.55 - 0.2 x + u_g` | fit convergence and SD-slope recovery |
| `sigma` | `sigma ~ 1` | `0.55` | fixed hurdle likelihood parameter |
| `hu` | `hu ~ 1` | `logit^{-1}(-0.9)` | zero probability stays fixed-effect |
| `Y` | hurdle NB2 | structural zero or positive-truncated NB2 quantile draw | row-level synthetic recovery |

Added `tests/testthat/test-hurdle-nbinom2-sd-regression.R` first. The focused
test command, `Rscript -e 'devtools::test(filter =
"hurdle-nbinom2-sd-regression")'`, fails both assembly and fit expectations
at the current explicit hurdle-random-effect rejection. This is the expected
red result and confirms the route is not already implemented. The fit test
uses 100 groups by 20 observations; budget 20–40 minutes for focused
post-implementation recovery checks, including constant-SD equivalence and
targeted neighbouring hurdle regressions.

Source implementation is waiting on the live
`codex:general-sd-regression:gaussian-animal-direct-sd` lease for `R/drmTMB.R`
and `src/drmTMB.cpp`. The branch audit found a prior unmerged Claude commit
`4f7bb30d5` with the hurdle random-intercept base plumbing; its relevant
builder, start/map, likelihood and regression-test changes were reviewed as
the adaptation reference. Do not write the shared source files until the live
lease is released. Test files are held by
`codex:general-sd-regression:hurdle-nbinom2-sd-tests`; checkpoint by
`codex:general-sd-regression:hurdle-nbinom2-checkpoint`.

## 2026-10-21 Hurdle NB2 location-SD route: implementation checkpoint

The one-intercept hurdle NB2 slice is now implemented in native TMB. It admits
one ordinary count-side `mu` random intercept on complete responses, with fixed
`sigma` and `hu`, and optionally models that intercept's SD from a fixed
group-level design. The latent effect changes the positive-count NB2 density
and truncation normalizer; it does not enter the structural-zero probability.
Random slopes, structured effects, `hu` or `sigma` random effects, and Julia
parity remain outside this slice.

The focused recovery test passes 31 expectations. The combined hurdle NB2
test files pass 90 expectations, including the retained unsupported-input
checks. The count, formula-grammar, and implementation-map vignettes render
from this worktree. Interval coverage is explicitly deferred and remains
unvalidated. GitHub issue search failed because `gh` could not connect, so the
issue tracker was left unchanged. The project acceptance ledger still has a
live lease and was not edited.

Continue the broad family/effect/backend inventory after reconciling current
ownership. Do not mark G3, G4, G5, or programme closeout complete from this
single native hurdle row. This implementation supersedes the preceding
test-first paragraph's statement that source edits are waiting on the
Gaussian animal lease.

## 2026-10-21 Hurdle NB2 selected independent-slope SD

The hurdle NB2 route now also admits one independent numeric `mu` slope when
the matching coefficient is selected in a predictor-dependent `sd()` formula.
The scale predictor is checked at the grouping level. The latent slope enters
the positive-truncated NB2 component; `hu` remains a separate fixed-effect
zero probability. The intercept route can still be used without an SD formula.

The seeded slope recovery and workflow test, hurdle regression tests, and
zero-truncated NB2 boundary tests passed together: 119 expectations, 0
failures, warnings, or skips in 68.9 seconds. The count vignette rendered and
`git diff --check` passed. A reviewer caught and we corrected wording that
could have implied a slope worked without its matching SD formula. The formal
grammar and NEWS descriptions still mention only the intercept route; their
paths have many missing ref versions and require coordinated reconciliation.
This slice does not establish Julia parity or interval coverage. Report:
`docs/dev-log/after-task/2026-10-21-hurdle-nbinom2-slope-sd-regression.md`.

## 2026-10-21 Zero-one-beta slope SD: test-first continuation

The next native family candidate is an independent ordinary `mu` slope whose
standard deviation varies with a group-level predictor. The likelihood already
uses the group SD row for the selected random-effect coefficient. The R builder
currently rejects the route at its intercept-only SD guard, and the shared
scalar target helper is called without `allow_slopes = TRUE`.

Added `tests/testthat/test-zero-one-beta-sd-slope.R` with an assembly check for
`bf(prop ~ 0 + x + (0 + x | id), sd(id, coef = "x") ~ w)`. The focused command
`Rscript -e 'devtools::test(filter = "zero-one-beta-sd-slope")'` now fails at
the expected intercept-only guard. No model fit or coverage campaign ran.

The live lease `codex:general-sd-regression:hurdle-nbinom2-sd` still owns
`R/drmTMB.R` and `src/drmTMB.cpp`; I left both files unchanged. The new test
file is separately leased to
`codex:general-sd-regression-zobeta-slope-tests-20261021`. Resume by waiting
for the source owner to release `R/drmTMB.R`, then change the zero-one-beta SD
admission to allow one scalar intercept or selected independent slope and
pass `allow_slopes = TRUE` to the target resolver. Preserve the existing
exclusions for random effects on other distributional parameters, structured
effects, and missing responses. Add seeded slope recovery and constant-SD
equivalence only after the builder slice is green.

## 2026-10-21 Zero-one-beta slope SD: implementation continuation

The native TMB builder now admits one ordinary `mu` intercept or one selected
independent numeric `mu` slope for the zero-one beta direct-SD route. The slope
uses the existing group-SD row map. Complete responses remain required; other
random effects and structured effects remain excluded. The matched Julia bridge
now also admits this selected slope in the paired development candidate; the
live same-data check is recorded in
`docs/dev-log/after-task/2026-10-21-julia-zeroonebeta-sd-slope-bridge.md`. This
does not establish shared/released DRM.jl support or interval calibration.

The new seeded test file covers assembly, point recovery, group-SD prediction,
simulation, save/reload, and constant-SD equivalence. The earlier red assembly
assertion failed at the old intercept-only guard. On 2026-10-21, the focused
slope filter passed 17 tests with no failures, warnings, or skips in 14.7 s; the
existing SD-regression filter passed 14 tests. The current-source predictor-SD
vignette rendered in the prior turn. A broader family filter entered an
existing quadrature test and was interrupted after exceeding the short run
estimate; it is not a pass.

The family adapter map and formula grammar now distinguish native TMB slope
support from Julia's intercept-only route. A check-log.d receipt and after-task
report were added. The shared check log and random-effect-scale design page were initially
held by completed hurdle-NB2 subtask leases in this root session. Those leases
were reconciled, and the paths were updated after reviewing their local diffs.

`git diff --check` reported one existing blank line at EOF in
`tests/testthat/test-binomial-sd-integration.R`, outside this slice. No source
reset, commit, push, merge, coverage run, or Julia slope implementation was
performed. Continue with the next owned adapter after reconciling the live
source and test leases; do not mark the general goal complete.


## 2026-10-21 Zero-one-beta slope SD: documentation reconciliation

The native family adapter map, formula grammar, random-effect-scale design
page, NEWS, formula-grammar vignette, predictor-dependent-SD vignette, main
check log, check-log.d receipt, and after-task report now distinguish native
TMB and candidate Julia intercept/slope support from shared/released DRM.jl support. The exact status
inventory search covered README, internal roadmap, NEWS, known limitations,
formula grammar, and pkgdown navigation. No README, roadmap, known-limitations,
or navigation change was needed for this family slice.

## 2026-10-21 Lognormal sigma-endpoint SD: test-first discovery

Added `tests/testthat/test-lognormal-sigma-sd-regression.R` with an independent
synthetic DGP in which a group-level predictor changes the SD of an existing
lognormal `sigma` random intercept. The test also requires constant-SD
equivalence to the existing intercept model. The focused test is currently
red at formula parsing: `parse_sd_lhs()` rejects `dpar = "sigma"` before model
assembly. This confirms a concrete non-location endpoint gap; it is not a
fitting or recovery result.

An independent read-only review found the existing sigma random-intercept
latent is scaled by one term-level `exp(log_sd_sigma)` in TMB. A fitted route
will need a group-row SD design and parameter mapping, then endpoint-aware
prediction, extraction, simulation and save/reload behavior. The mathematical
review supports identifiability with enough groups, repeated observations and
within-group-constant predictor values, while warning of weak information at
small group counts or sparse replication. Keep this a lognormal-only slice
until its target and output contract is implemented; Gamma has a distinct CV
interpretation and needs a separate likelihood check.

Before editing shared parser and likelihood files, reconcile their active
cross-ref diffs and ownership. The parser preflight reports 14 refs with work
not present in this checkout, including temporal-formula changes. Do not
change the shared parser until those hunks are reconciled. No implementation,
Julia run, simulation campaign, or coverage claim was made in this test-first
checkpoint.

## 2026-10-22 Lognormal sigma-endpoint SD: verification follow-up

The 2026-10-21 test-first status above is historical. The current candidate now
parses and fits the complete-data LogNormal sigma random-intercept route
`sd(id, dpar = "sigma") ~ w` with fixed-effect `mu`. On 2026-10-22, the focused
test passed after adding a negative check that rejects a predictor varying
within `id`; the neighboring LogNormal location-scale, SD-assembly, and
SD-integration sweep also passed. The test checks point recovery, finite
coefficient covariance, profile-target readiness, group-SD prediction, positive
marginal simulation, save/reload, and constant-SD equivalence. An actual
profile-interval call on the 400-group recovery fit exceeded roughly two
minutes and was interrupted without a result; profiling is not verified.

The formula-grammar table contained duplicate identical rows for this target.
They are now one row with the complete tested boundary. The independent math
review found no critical mismatch in the likelihood-scale interpretation and
confirmed the native route uses the same endpoint-specific scale for fitting
and marginal simulation. Julia parity, conditional `sigma` prediction,
profile execution, bootstrap refits, and interval coverage remain unverified.
Coverage remains deferred under the active goal. Continue by taking the next
unclassified family/effect/backend row only after checking its shared-file
owner; the paired Julia candidate still needs a current read-only status audit.

## 2026-10-22 LogNormal sigma profile workflow follow-up

Two bounded native profile smokes completed for the synthetic
`sd(id, dpar = "sigma") ~ w` route. With 36 groups, the estimated slope was
-0.3279 and its 95% profile interval [-1.0568, 0.2807] missed truth 0.4. With
120 groups, the estimate was 0.6471 and the interval [0.3045, 1.0681]
contained truth. This is one replicate at each size: it verifies finite
profile execution only, not interval coverage. The 400-group profile call
still has no result. Exact run details are in
`docs/dev-log/check-log.d/2026-10-22-lognormal-sigma-sd-validation.md`.
The 120-group seeded profile is now a regression test. The focused LogNormal
sigma test and adjacent LogNormal regression filters passed after that
addition; neither run estimates coverage.

## 2026-10-22 LogNormal conditional sigma prediction follow-up

Added native assertions that fitted-data conditional `sigma` link predictions
equal the fixed predictor plus the fitted random-effect contribution and that
`sigma(fit)` equals the exponentiated link prediction. The focused
`lognormal-sigma-sd-regression` test exited 0. No live Julia test ran. This
closes one native output check only; Julia parity and bootstrap-refit integrity
remain open. Details: `docs/dev-log/check-log.d/2026-10-22-lognormal-sigma-sd-validation.md`.

## 2026-10-21 Gamma sigma-endpoint SD regression

The native Gamma builder now admits one complete-data `sigma` random
intercept with `sd(group, dpar = "sigma") ~ predictors`, fixed-effect `mu`,
and group-constant predictors. The focused seeded recovery/output test,
adjacent Gamma/LogNormal regression filter, current-source predictor-SD
vignette render, and `pkgdown::check_pkgdown()` passed. The test checks
coefficient recovery, finite covariance, group SDs, conditional sigma output,
save/reload, within-group validation, and constant-SD equivalence. The initial
vignette render exposed an accidental patch to the Gaussian builder; those
unintended hunks were restored and the current source render then passed.
Details are in `docs/dev-log/after-task/2026-10-21-gamma-sigma-sd-regression.md`.
This is one native endpoint/effect-shape cell. Julia parity, profile/bootstrap
refits, interval coverage, and the full family/effect/backend universe remain
open. Next inspect and claim the next uncovered row after a shared-file
ownership preflight; preserve all existing dirty work.
## 2026-10-22 Student-t endpoint guard follow-up

Added an explicit guard in `drm_build_student_ls_spec()` so Student-t
`sd(..., dpar = "nu")` formulas fail with a clear unsupported-endpoint error
instead of being silently dropped. The new regression assertion failed before
the guard and passed after it. The focused Student SD filter passed 28
assertions, the broader Student filter passed, and the explicitly configured
`julia-student-sd` filter passed two live Julia tests. No Student-t `sigma` or
`nu` SD route was added. After-task and exact check records are in
`docs/dev-log/after-task/2026-10-22-student-sd-target-guard.md` and
`docs/dev-log/check-log.d/2026-10-22-student-sd-target-guard.md`.

The Tweedie Julia bridge slice is implemented and tested. The bridge now admits
one ordinary `mu` intercept or one independent numeric slope with a matching
SD formula, fixed `sigma`, and intercept-only `nu`. Its focused Julia-enabled
test passed both live same-data comparisons (intercept and slope) against
native TMB; the native Tweedie SD integration filter passed 27 expectations.
The first Julia attempt stalled during JuliaCall's temporary dependency
bootstrap; the authorized retry completed setup and passed. This does not cover
structured/correlated effects, other endpoints, interval calibration, or broad
family/backend parity. Exact details are in
`docs/dev-log/after-task/2026-10-22-tweedie-julia-sd-bridge.md` and
`docs/dev-log/check-log.d/2026-10-22-tweedie-julia-sd-bridge.md`.

## 2026-10-22 NB2 animal supplied-covariance follow-up

The focused NB2 animal SD test passes 16 assertions. It checks that a supplied
covariance `A` and its equivalent pedigree representation give matching
convergence, SD coefficients, log likelihood, and group-name-keyed SD
predictions for one synthetic q1 animal-intercept route. No production code
changed. Exact receipt: `docs/dev-log/after-task/2026-10-22-nbinom2-animal-A-direct-sd.md`.

The existing Gamma animal slope-only same-data comparison also now has a
refreshed manifest binding 198 native/Julia source files and the saved console
log. It remains one unit-diagonal q1 slope-only fixture, not broad parity or
interval calibration. See `docs/dev-log/general-sd-regression/evidence/gamma-animal-slope-parity-20261022/source-manifest-animal-slope.json`.

Both after-task structure checks passed; their checker notes that the programme
ledger is not runnable in this environment, so gate state remains unknown from
that tool. `git diff --check` passes on the NB2 test and its touched inventory,
check-log, and report paths. Next, take a fresh row-level inventory candidate
and inspect shared-file ownership before making another implementation edit.

## 2026-10-22 LogNormal sigma-SD bootstrap workflow

The existing `lognormal sigma SD slope profile works on an informative smoke
fit` test passed 20 assertions after adding three fixed-seed serial bootstrap
refits. Each refit converged, retained the exact target, and contributed its
bootstrap draw. This is workflow integrity only and does not support interval
coverage. No production source changed. Exact report and command:
`docs/dev-log/after-task/2026-10-22-lognormal-sigma-bootstrap-workflow.md` and
`docs/dev-log/check-log.d/2026-10-22-lognormal-sigma-bootstrap-workflow.md`.

A fresh Julia audit recommends the next high-value parity gap: Julia Poisson
q1 animal-intercept SD with supplied covariance `A` (required row 7917;
native counterpart 17404). Native evidence exists, while Julia's Poisson
structured-SD branch currently admits relmat and phylogenetic routes only.
Before touching the dirty Julia source, review all relevant diffs and reconcile
its missing refs; the new test path itself has no missing-ref warning. The
agent audit is a lead, not yet independently verified.

## 2026-10-23 current-source timing checkpoint

The current native package source was transferred to Totoro, compiled cleanly
after removing macOS AppleDouble sidecars, and installed into an isolated
library. A fresh 45-row timing-only run completed all fits with valid 95%
profiles and independent Laplace-oracle passes. Source and installed-library
hashes were rechecked locally against the retained capsule. Timing-only status
remains `calibration_claim=false`; G5 is open. Source archive and receipts:
`docs/dev-log/general-sd-regression/evidence/calibration-20261023/timing-current-source-v1/`.

Next: qualify the adapter for this current source using a seed-disjoint stream
and a matching sealed first-look source. Do not reuse the earlier clean-current
probes that overlap look two. Then resume the calibration decision chain and
the still-open family/effect/backend capability rows.

## 2026-10-23 Julia cumulative-logit evidence

The current paired Julia candidate at `70dbf564eb670144c63c08f61ea099084d95add2` passed its cumulative-logit ordinary random-intercept and independent numeric-slope SD test: 39/39 assertions on Julia 1.10.0. Two unreviewed source-bound receipts now link the exact candidate rows. The evidence reconciler passes with 23 records covering 22 of 19,118 required rows. This is focused Julia test evidence, without native parity or interval-coverage claims. Details are in `docs/dev-log/after-task/2026-10-23-julia-cumulative-logit-sd-evidence.md`.

Next: continue full cross-family implementation; a native review flagged NB2 sigma-endpoint SD regression as a candidate, but shared R/TMB builder and likelihood ownership needs a clean handoff before edits.

## 2026-10-23 Julia simulator workflow receipts

Tweedie and ZeroOneBeta marginal simulator tests passed 10/10 each, with independent seeded draw reconstruction and one bootstrap refit each. Source hashes remained stable across the 56.6-second rerun. Two unreviewed workflow receipts are linked in the evidence ledger. Reconciliation now reports 25 receipts across 23 of 19,118 candidate rows. The `src/inference.jl` file remains under a live lane lease; coordination was requested before any edit. See `docs/dev-log/after-task/2026-10-23-julia-simulator-workflow-evidence.md`.

## 2026-10-23 current-source crossed Bernoulli Julia output check

The drmTMB R-to-Julia crossed-intercept bridge test reran with one live Julia
fit and command exit status 0. JuliaCall emitted its non-fatal
`LogExpFunctionsInverseFunctionsExt` precompile warning. The paired Julia test
also reran against current source and passed 20/20 assertions in 20.2 seconds.
The cross-engine test source, R/TMB source, paired Julia source, commands,
console output, and both candidate HEADs are recorded in the current-source
manifest and receipt. Reconciliation passes with 28 receipt records covering 24
of 19,118 candidate rows; the new receipt remains unreviewed and adds workflow
evidence only. G2 remains the only checked programme gate; G0, G1, and G3–G8
remain open, including calibrated uncertainty. See
`docs/dev-log/after-task/2026-10-23-bernoulli-crossed-julia-sd-output-parity.md`
and `docs/dev-log/check-log.d/2026-10-23-julia-binomial-crossed-current-source-rerun.md`.

## 2026-10-23 current-source animal parity and row reconciliation

The Poisson supplied-A animal-intercept TMB/Julia test now passes one live
bridge test and links the exact native and Julia required rows as unreviewed
focused-test evidence. The full Gamma SD test file passed five live Julia tests
on the current candidate; its log-likelihood parity assertion is now at
tolerance `1e-3`, and six stale test-hash receipts were refreshed to this source.
Reconciliation passes with 30 receipts linked to 25 of 19,118 rows; 19,093 rows
remain unlinked. The test exposed an unimplemented required cell: Gamma
animal-intercept plus independent numeric-slope SD targets are not accepted by
either builder. Calibration remains required and open: the previous P8 status
wording was corrected in `arcs.md`. Exact details are in
`docs/dev-log/after-task/2026-10-23-cross-engine-animal-sd-parity.md`.

## 2026-10-23 latest direct-SD ledger status

The count refresh supersedes the preceding row-count paragraph: the current
ledger has 32 hash-verified receipt records linked to 26 distinct rows, not 30
records and 25 rows. Of these, 25 rows are initially `required` and one is
`unresolved`; no row has been promoted by this evidence join. The formal gate
checker reports G2 met and eight gates unmet. This gate fraction is not a
programme-completion percentage, and receipt linkage is not feature
completion. See `docs/dev-log/after-task/2026-10-23-general-sd-evidence-count-refresh.md`.

## 2026-10-23 native Gamma animal SD likelihood verification

Focused current-source tests passed for the separate Gamma animal-intercept
(14 assertions) and slope-only (15 assertions) routes. The exact TMB
`model_type == 5` branch applies the predictor-dependent group SD to the
structured field while retaining the `Q_phylo` Gaussian penalty; the previous
static audit concern was not borne out. This
does not cover the required combined intercept-plus-slope route, which remains
open in both engines. Julia 1.10 could not be run locally, and the sandbox
blocked the existing Totoro socket. Details:
`docs/dev-log/after-task/2026-10-23-gamma-animal-sd-likelihood-runtime-check.md`.

## 2026-10-24 Gamma animal intercept-plus-slope recovery check

The focused `gamma-animal-q2-cross-engine-sd` test passed with exit code 0:
19 expectations, one live Julia bridge fit, 40.4 seconds. The seeded fixture
checks both native log-SD coefficient vectors against their DGP values, expected
signs, same-data Julia/TMB coefficient and log-likelihood agreement, target
identity, predictions, and save/reload. The supplied relatedness matrix has a
unit diagonal. The capability inventory now names this as two separate
coefficient-specific SD targets within one animal term, not as a correlated
intercept-slope q2 block.

Exact test and source hashes plus remaining limits are in
`docs/dev-log/after-task/2026-10-24-gamma-animal-q2-cross-engine-sd.md` and
`docs/dev-log/check-log.d/2026-10-24-gamma-animal-q2-cross-engine-sd.md`. This
does not establish non-unit kernel scaling, interval calibration, broad
recovery, or close a required universe row or programme gate.

## 2026-10-24 ZeroOneBeta slope prediction output

The paired Julia candidate's existing ZeroOneBeta independent-slope test now
also checks public `predict_parameters()` output: response-scale SDs match the
fitted group SDs, link-scale SDs match their log values, and delta-method SEs
are finite. The focused test passed 13/13 checks in 32.0 seconds. The exact
source/test hashes and scope are recorded in
`../../../../general-sd-julia/docs/dev-log/after-task/2026-10-24-julia-zeroonebeta-sd-prediction.md`.
This extends one family's Julia output-integrity evidence and does not add a
family/provider capability row, establish TMB parity, calibrate intervals, or
close a programme gate. The next reviewed Julia row candidate is bivariate
Gaussian `mu1` IID q1, but its source is owned by the active #1174 lane; no
ownership release has been received.

## 2026-10-24 Julia Gamma animal simulation documentation

Public `simulate()` help and the Julia guide now document complete-data Gamma
animal q1 intercept and q2 intercept-plus-numeric-slope marginal simulation,
with separate coefficient SD formulas, fixed `sigma ~ 1`, unavailable
conditional simulation, and the Julia unit-diagonal covariance convention.
The guide includes self-contained synthetic data with non-unit-diagonal `A`.
Focused tests reran four live Julia cases successfully, including the q1 and q2
seeded marginal-simulation oracles. `devtools::document()`, vignette knitting,
and `pkgdown::check_pkgdown()` passed. This contributes partial G4 workflow
evidence only; no capability row or programme gate closes. Report and exact
candidate hashes: `docs/dev-log/after-task/2026-10-24-julia-gamma-animal-simulation-routes.md`
and `docs/dev-log/evidence/gamma-animal-marginal-simulation-docs-20261024/`.
Next: reconcile a required fitting row with shared-source preflight before
selecting another implementation slice. The read-only Gamma kernel audit found
that native TMB preserves raw `A`, while Julia normalizes it. This conflicts
with the approved raw-kernel SD contract and with preserving current Julia
constant-SD fits if only the predictor-dependent route is changed. See the
current inventory and after-task report; settle this contract conflict before
claiming non-unit-`A` parity.

## 2026-10-24 Beta-binomial ordinary SD bridge rerun

The paired Julia development candidate now passes the narrow R bridge for one
complete-response ordinary `mu` random intercept or one independent numeric
slope SD target when `sigma ~ 1`. The same-data native TMB/Julia tests passed
70/70 expectations with three live Julia fits, zero failures, warnings, or
skips, in 57.3 seconds. Exact source and test receipts are under
`docs/dev-log/general-sd-regression/evidence/betabinomial-ordinary-sd-parity-20261024-v1/`;
the after-task report is
`docs/dev-log/after-task/2026-10-24-julia-beta-binomial-ordinary-sd-parity.md`.
The evidence reconciler passes with 41 hash-verified receipts linked to 32 of
19,118 candidate rows; 19,086 rows remain without linked receipts. These are
evidence links, not a completion percentage. Structured/correlated Beta-binomial
routes, broader outputs, interval calibration, and the full family/effect/
provider/backend universe remain open. No programme gate closes. Continue with
the next exactly scoped required row after reviewing its current worktree and
lane ownership; the Gaussian Gamma animal kernel scaling conflict remains a
separate design issue and should not be mixed into this Beta-binomial slice.

## 2026-10-24 Gaussian ordinary mean-intercept parity

Added a same-data native TMB/Julia candidate check for one complete-data
Gaussian q1 `mu` random intercept with `sd(id) ~ z` and fixed `sigma ~ 1`.
Fourteen focused expectations passed, including signed recovery, coefficient
and likelihood agreement, group-SD output, and reordered-row prediction. The
exact source-bound receipts and test snapshot are in
`docs/dev-log/general-sd-regression/evidence/gaussian-ordinary-sd-parity-20261024-v1/`.
The evidence overlay now has 43 receipts linked to 34 rows, leaving 19,084 of
19,118 candidates without linked receipts. This does not quantify completion
and closes no programme gate. The next gap is another unlinked family/effect
row; Gaussian slope and structured parity remain open.


## 2026-10-25 Hurdle NB2 positive-count identifiability review repair

Independent review found a count-side SD identifiability hole: all-zero groups
contribute to `hu`, but do not inform the positive-count random-effect SD. The
native R/TMB builder and paired Julia fitter now require full rank on the
positive-count group subset, with a regression test in each engine. Native
rank-refusal test passed; Julia identifiability test passed 2/2; direct Julia
Hurdle NB2 SD test with scalar quadrature oracle passed 17/17; source-pinned
R-to-Julia bridge rerun passed one live bridge test. The review-repair source
manifest covers 152 files with identical before/after hashes. Documentation now
limits the parity wording to per-engine output checks. Exact logs and manifest:
`docs/dev-log/general-sd-regression/evidence/hurdle-nbinom2-sd-bridge-20261025/review-repair/`.
Evidence remains narrow and unreviewed; interval calibration and broader
hurdle effect/provider/backend rows remain open.

## 2026-10-25 SkewNormal SD bridge progress

The previous SkewNormal bridge probe is now implemented for one complete-
response ordinary numeric `mu` slope with a matching predictor-dependent SD
formula and fixed `sigma` and `nu`. The new live R/Julia test and the native
SkewNormal SD test passed 33 focused expectations together. The bridge uses
Julia's generic `sd` output block, with its R coefficient labels now aligned.
See `docs/dev-log/after-task/2026-10-25-julia-skewnormal-sd-bridge.md` and the
new check-log entry. No interval-calibration or broad parity claim is made.
Next, continue the uncompleted capability matrix after reviewing current source
and lane ownership. The broad goal remains active; no gate has closed.

## 2026-10-25 Julia Gamma sigma-slope bridge and Student live rerun

The Julia Gamma `sigma` random-slope SD route and paired R bridge now have
focused same-data fixtures for an intercept and an independent numeric slope.
The direct Julia filter passed 23 assertions, including a separate `QuadGK`
likelihood oracle; the live R bridge filter passed two fits. A later Student
bridge rerun with the paired Julia path configured passed 34 expectations,
including live intercept and slope fits, target labels, coefficient recovery,
group-SD predictions, and slope save/reload. The first Student attempt hit a
local depot-lock `ENOSPC`; a fresh R process using the existing home depot
passed. Reports and check logs are recorded in both candidate worktrees. These
focused checks do not establish broad parity or interval calibration. A
coordination update was sent to the active DRM lane before selecting another
Julia implementation row; response pending.
# 2026-10-26 07:08 MDT continuation checkpoint

The active work remains the Julia probit phylogenetic Bernoulli SD profile
workflow. In the drmTMB candidate, the test-only BackTracking overlay passed
both live R-to-Julia bridge cases. The proposed production retry patch is
`docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/profile-retry-candidate.patch`;
`git apply --check` passed in both the general-SD Julia candidate and the
docs-audit worktree. It has not been applied.

Ownership: the current lane lease covers the focused drmTMB bridge test,
evidence directory, after-task path, check log and this checkpoint. The
separate docs-audit lease still owns DRModels.jl `src/inference.jl`; do not edit
or claim that file until its owner releases it. At 07:00 MDT, workflow
`40314962162` on exact head `3c0d3794c7e6e4610048635f47cb4bac7c4e67d5` had three
successful Julia shards and shard 1/4 still running. Recheck before proceeding.

The repo handoff gate was run and returned inconclusive: the candidate has 925
uncommitted paths and is 547 commits behind `origin/main`; 12 acceptance ledgers
were not runnable with the configured checker. Preserve the candidate and do
not stage, commit, push, merge, or claim completion. Continue in
`/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`,
first rechecking the CI run and both leases. The same-lane lease ID is
`codex:general-sd-phylo-workflow-20261026` and expires at approximately 07:27
MDT. A refresh attempt did not return a grant while the shared lease registry
lock was busy. Do not remove the lock; retry the lease tool after the lock
clears.

## 2026-10-26 07:17 MDT: production profile failure reproduced

The focused direct Julia run on `general-sd-julia` used Julia 1.10.0 and took
68.25 seconds. `test_binomial_phylo_sd_regression.jl` passed 27/27 assertions
for the joint ordinary/phylogenetic SD case and 23/23 for the phylogenetic
intercept case. Its probit phylogenetic SD-slope profile test failed 2/5:
the upper finite-difference LBFGS nuisance fit returned `:not_converged`; the
lower endpoint was accepted. The fit warned that its finite-difference Hessian
was not positive definite and withheld Wald SEs. The four source hashes were
unchanged before and after. Full log:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/direct-phylo-sd-test-20261026-0715.log`.

I sent this concrete failure to the docs-audit owner. That lane still holds
`src/inference.jl`, so the prepared patch remains unapplied. Next: recheck the
owner reply and exact CI run `40314962162`; if the owner releases the file,
refresh the path lease, inspect the final diff and apply the patch. Keep the
profile regression strict and do not advertise interval calibration.


## 2026-10-26 07:42 MDT: isolated production retry passed

The profile retry patch was applied in `/tmp/codex-sd-probit-profile-probe-20261026`, a copy of the current Julia candidate. Julia 1.10.0 test command exited 0 with one Julia and BLAS thread: joint fit/oracle 27/27, phylogenetic intercept 23/23, probit phylogenetic SD-slope profile 5/5. Raw output and source/patch hashes are recorded in `docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-workflows-20261026/profile-retry-isolated-probe-20261026.log` and `source-state.md`. The Hessian is still non-positive-definite and Wald SEs are withheld; no coverage claim follows.

I reviewed the full current `src/inference.jl` candidate diff with an independent Julia-core review. It identified a missing NB2 precision bootstrap route and a dense inversion in the Poisson precision simulator; those are real follow-up issues within the broader distributional scope and remain open. The docs-audit task is still active, its lease covers `src/inference.jl` through 11:34 MDT, and the lane lease tool refused the profile-repair claim. The audit owner is now fixing the test dependency in PR #1210; the focused Julia file passes 94/94, while exact-head shards and docs remain in progress at head `38c3a13b48108a9daf5784e3b75a2c68d45facef`. I sent the owner the isolated retry result and requested release of only `src/inference.jl` after their committed docs hunk is settled.

Next: when that path is released, claim `DRM.jl/src/inference.jl`, inspect the current final diff, apply the prepared patch while preserving the docs changes, then run the focused test in the authoritative worktree and the R-to-Julia bridge filter. Keep the global SD-regression goal active.


## 2026-10-26 07:55 MDT: docs-audit exact-head update

PR #1210 remains open at exact head `38c3a13b48108a9daf5784e3b75a2c68d45facef`. Changes, docs build and docs preview pass; four Julia test shards remain in progress. The owner found three further wording gaps and a Gamma/Beta offset admission mismatch in the capability table, and is recording corrections before merge. The active docs-audit lease still covers `DRM.jl/src/inference.jl`. This profile-retry lane made no source edit there; its patch remains validated only in the isolated copy. Next: finish docs-audit status check, then claim the source path when its lease is released and verify the patch on the candidate.

## 2026-10-26: SD lane ownership and profile retry integrated

Shinichi assigned the predictor-dependent SD modeling lane to this goal. The
documentation-audit lane remains responsible for its audit and PR, and the DRM
parity lane remains responsible for its cross-repository parity work. I sent
both lanes the ownership update. I removed only `src/inference.jl` from the
docs-audit lease; its other paths and the committed API-documentation hunk in
PR #1210 were preserved. The SD lane now holds a scoped lease for the Julia
profile source, tests, and unique after-task/check-log files.

On candidate `70dbf564eb670144c63c08f61ea099084d95add2`, I applied the reviewed
44-line finite-difference profile retry to `DRM.jl/src/inference.jl`. Julia
1.10.0 reproduced the original probit phylogenetic upper-endpoint failure
before the change. Afterward, the focused phylogenetic file passed 55/55
assertions, the probit fit/oracle and derivative file passed 42/42, and
profile-nuisance status tests passed 70/70. The broader Binomial file exposed
four stale animal-slope assertions that expected unresolved endpoints; after
updating them to check status consistency and coefficient bracketing, the
isolated testset passed 31/31 in 8m45.2s. Its wrapper exited 1 afterward due
to zsh's read-only `status` variable, not a Julia test failure. The finite-
difference Hessian remains non-positive-definite in the probit fixture, so
Wald SEs are withheld.

The Julia after-task report and per-slice check-log entry are in
`docs/dev-log/after-task/2026-10-26-julia-binomial-probit-phylo-profile-retry.md`
and `docs/dev-log/check-log.d/2026-10-26-julia-binomial-probit-phylo-profile-retry.md`.
The report structure check passed; the checker still reports the larger
acceptance ledger as unknown because its gate runner is unavailable. There is
no interval-coverage, full-suite, R bridge, or R/TMB parity claim.

Next: continue the approved implementation-first SD scope. Choose the next
required Bernoulli row from the capability ledger after checking the current
parity-lane status and exact file leases. Keep coverage calibration deferred,
preserve the docs and parity lanes, and do not claim a programme gate closed.

## 2026-10-26: probit phylogenetic bridge verified

The SD lane then verified the candidate probit Bernoulli phylogenetic
intercept route through the live drmTMB R bridge. The focused
`julia-binomial-phylo-sd` test completed on Julia 1.10.0 in 118.5 seconds:
61 passed, 0 failed, 0 testthat warnings, 0 skipped; two live Julia fits ran
and were compared with native TMB. Coefficients, likelihoods, tip-level SDs,
reordered-tip predictions, and the selected Julia SD-slope profile workflow
were checked. The probit fit warns that two Hessian coordinates are nearly
singular, so their Wald SEs are not trustworthy and the profile interval is
not calibrated.

The exact command, source pins, and hashes are in
`docs/dev-log/check-log.d/2026-10-26-julia-binomial-probit-phylo-bridge.md`;
the trimmed console is under
`docs/dev-log/general-sd-regression/evidence/julia-binomial-probit-phylo-bridge-20261026/`.
The candidate inventory supersedes the earlier pre-retry failure statement.
The docs-audit and parity tasks remain separate and active; no files from their
scopes were changed. Coverage validation, a full suite, general parity, and
release status remain open. Next: choose the next unresolved Bernoulli cell
from the frozen inventory and claim its exact files under the SD lane.

## 2026-10-26: cloglog phylogenetic bridge added and checked

Following Shinichi's explicit ownership clarification, the SD modelling lane
owns this implementation slice; the documentation audit and Julia parity lanes
remain separate. The R bridge now admits the candidate Julia cloglog
phylogenetic random-intercept SD route alongside probit and rejects cauchit at
the family guard. The direct Julia cloglog/mixed-effect file passed 29/29, and
the final live R bridge filter passed 71/71 expectations with three live Julia
tests in 119.0 seconds. The cloglog report and check log are
`docs/dev-log/after-task/2026-10-26-julia-binomial-cloglog-phylo-bridge.md`
and `docs/dev-log/check-log.d/2026-10-26-julia-binomial-cloglog-phylo-bridge.md`;
the exact console is under
`docs/dev-log/general-sd-regression/evidence/julia-binomial-cloglog-phylo-bridge-20261026/`.

The combined run retains the probit near-singular Hessian warning, so its two
flagged Wald standard errors remain untrustworthy. No interval calibration,
broader parity, full suite, merge, or release is claimed. The documentation
audit and parity lanes were notified; no files in their scopes were edited.
The repo-wide diff check also finds a pre-existing extra blank line at EOF in
`tests/testthat/test-binomial-sd-integration.R`, which is outside this slice.
Next: continue with the next unresolved Bernoulli capability row after
checking current lane status and claiming only its exact files.


## 2026-10-26: correlated q3 Bernoulli Julia bridge bounded

The final q3 probit bridge test uses 80 groups × 12 observations and passed one
live Julia 1.10.0 test against native TMB without warnings, including
coefficients, correlations, group-SD predictions, and marginal simulation.
Earlier q3 probit attempts had a singular-Hessian warning and are superseded by
the final run. q3 logit failed same-data coefficient checks and had singular or
non-positive-definite Hessians; q3 cloglog remained nonconverged on two
fixtures. The public R bridge admits q3 probit and refuses q3 logit/cloglog.
The fit-free test passes 20 checks, including both refusals; the live test
passes. Receipt and report:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q3-sd-bridge-final-20261026/receipt.md`
and `docs/dev-log/after-task/2026-10-26-julia-binomial-correlated-q3-sd-bridge-bound.md`.
Coverage validation remains deferred. Next: investigate the q3 logit likelihood
and Hessian instability, without weakening the refusal gate or claiming broad
q3 support.


## 2026-10-26: high-information q3 logit bridge passed

A 160-group × 32-observation synthetic Bernoulli-logit q3 fixture now passes
a live same-data R-to-Julia test. Both engines converged; all three SD coefficient
vectors, pairwise correlations, and group-SD predictions agree within the
predeclared smoke tolerances, each SD slope is near its generating value, and
Julia marginal simulation returns binary outcomes. The live test passed 19
assertions without warnings. Lower-information q3 logit fixtures remain known
to be unstable, so the new admission is scoped to the high-information tested
route and is not a general reliability claim. q3 probit remains admitted; q3
cloglog remains refused after nonconvergence/Hessian failures. Receipt:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q3-sd-bridge-final-20261026/q3-logit-receipt.md`.

Coverage calibration is deferred. Next: test whether a high-information q3
cloglog design can meet the same convergence and covariance checks before
considering bridge admission.


## 2026-10-26: high-information q3 cloglog bridge passed

A 160-group × 32-observation synthetic Bernoulli-cloglog q3 fixture passed
the exact live R-to-Julia bridge test. TMB and Julia converged without warnings;
same-data coefficient/correlation checks, group-SD predictions, and marginal
simulation passed. The SD-trend check uses a 0.40 relative one-seed tolerance
because its three estimates differed from truth by 0.13–0.16 absolute; cross-
engine coefficient and prediction tolerances remain 0.20. Lower-information q3
cloglog fits remain unstable. Together with earlier focused checks, the ordinary
q3 Bernoulli bridge now admits probit, logit, and cloglog. Receipt:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q3-sd-bridge-final-20261026/q3-cloglog-receipt.md`.

This latest entry supersedes the earlier q3 logit checkpoint, which still
listed q3 cloglog as refused. Coverage calibration is deferred. Next: identify
the next unresolved Bernoulli family/effect/provider/backend row from the
capability ledger and inspect its current ownership before editing.


## 2026-10-27: q4 correlated Bernoulli bridge verified

The q4 correlated ordinary Bernoulli SD route now passes the live R-to-Julia
bridge test for logit, probit, and cloglog. The final focused run completed in
429.4 seconds with 90 assertions, zero failures, zero warnings, and zero skips.
It checked q4 target and coefficient labels, partial-to-marginal correlation
conversion, simulated covariance, convergence, recovery of the six marginal
correlations and four SD slopes for each link, group-level SD predictions, and
marginal binary simulation. The live command used
`DRMTMB_JULIA_TESTS=true`, `DRM_JL_PATH=.worktrees/general-sd-julia`, and
`DRM_JL_JULIA_HOME=/Users/z3437171/.juliaup/bin` with
`devtools::test(filter = "^julia-binomial-correlated-q4-sd-bridge$")`.

The first opt-in run found only test-fixture/API defects: this testthat version
does not accept `info` in `expect_lt()`, and the expected coefficient labels
were inadvertently unnamed. After correcting the assertions, all three fitted
links passed. This is one fixed-seed, high-information recovery fixture per
link and route; it is not coverage calibration and does not establish broad
low-information reliability.

The adjacent candidate evidence remains: native q4 correlated Bernoulli
passed 17/17 focused checks in 201 seconds; native q2/q3 regression passed
102/102 in 116.9 seconds; and direct Julia q4 passed 41/41 in 99.6 seconds,
with 30/30 q2/q3 equivalence and derivative checks. These are distinct
engine-specific receipts, not substitutes for the live bridge evidence.

The earlier Bernoulli map said a crossed ordinary bridge test was absent, but
`test-julia-binomial-crossed-sd.R` already contains a live native/Julia crossed
fit, target-specific SD prediction, serialization, and simulation test. Treat
crossed ordinary Bernoulli SD as tested at that narrower fixture and reconcile
the map before selecting the next gap. Coverage calibration, full Bernoulli
parity, spatial and phylogenetic-interaction Bernoulli routes, other response
families, full-suite checks, and programme completion remain open.


## 2026-10-27: phylogenetic Bernoulli random-slope SD vertical slice

Added Binomial phylogenetic random-slope SD support to both native TMB and
direct Julia for one slope-only `phylo(0 + x | species)` term with a matching
`sd(species, phylogenetic) ~ z` formula. The synthetic fixture uses independent
tree-based data and checks convergence, a fixed-seed SD-slope recovery bound,
tip-level target predictions, binary simulation, and save/reload consistency.
Native TMB passed 17/17 focused checks (11.0 s), including independent
logit/probit/cloglog slope-recovery fits. Direct Julia passed 22/22 checks,
including the same three links, save/reload prediction, an exact seeded
marginal-draw oracle, and one successful parametric-bootstrap refit for logit.

The bootstrap test first found that phylogenetic SD targets bypassed the
Binomial-specific marginal simulator. Routing now includes phylogenetic SD
targets. Neighboring Julia regression checks then caught and fixed an
intercept-parser regression: the same fitter now retains the established
phylogenetic intercept route. Final adjacent runs passed the Julia intercept
suite (23/23), the new slope suite (14/14 after save/reload checks), the probit slope/profile suite
(5/5), the probit intercept suite (12/12), and its derivative checks (30/30).
The joint-fit Hessian warnings were already guarded by withheld Wald SEs; this
smoke does not claim calibrated intervals.

Scope remains narrow: the Julia family documentation still needs to add the
direct slope route, and R-to-Julia bridge admission and a live bridge test for
the slope remain open. The documentation and parity lanes have received the
exact evidence and these boundaries. Coverage calibration and broad
phylogenetic-provider combinations remain deferred.


## 2026-10-27: Binomial phylogenetic slope bridge and ledger closeout

The R-to-Julia bridge test now passes for one tree-backed Binomial
phylogenetic slope-only SD term across logit, probit, and cloglog. The live
fixture checks same-data native/Julia coefficients and log likelihoods,
convergence, and tip-level SD predictions; its logit case also checks
save/reload predictions and seeded marginal simulation. The clean rerun passed
30 expectations with one live Julia test. Receipt:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-slope-sd-bridge-20261027/receipt.json`.

The generated capability ledger now marks only the probit/cloglog Julia
phylogenetic-slope tree rows as admitted exceptions to the broader blocked
non-logit link status. The source-universe suite passed 33/33, evidence
reconciliation passed, and `pkgdown::check_pkgdown()` found no problems with
existing MathML deprecation warnings. The full site build stalled for over
seven minutes and was stopped. No row was promoted and no interval calibration
is claimed. The older 2026-10-27 checkpoint that listed bridge admission as
open is superseded for this exact slope-only route.

Next: select the next Bernoulli required row from the regenerated universe and
inspect current test coverage and lane ownership before editing.

## 2026-10-27 Julia Binomial coordinate-spatial SD checkpoint

Direct Julia coordinate-spatial Binomial random intercept and independent numeric slope tests now pass 46/46 assertions across logit, probit, and cloglog. The suite checks fixed-seed recovery direction, group SD predictions, seeded marginal simulation, and extreme SD-predictor behavior. Independent math review found a clamp inconsistency between the sparse likelihood, stored group scales, and simulator; one shared transformation now keeps these paths aligned. The guide's synthetic spatial-slope example ran successfully.

The exact six Julia spatial intercept/slope link cells are linked to a source-bound focused-test receipt. Universe tests passed 33/33; evidence reconciliation passed with 101 records and 81 linked candidate rows. No row is promoted, and there is no interval-coverage or native TMB parity claim. The adjacent `test/test_binomial_sd_regression.jl` printed 172 passing assertions before being interrupted during a later CPU-bound phylogenetic fit. Its full-file status is partial, not pass. Report: `DRM.jl/docs/dev-log/after-task/2026-10-27-julia-binomial-spatial-sd.md`.

Next: reconcile the parity lane's ownership of coordinate-spatial R-to-Julia bridge work. Then select a separate Bernoulli provider or family row from the generated universe and inspect its test and source ownership before editing. Keep the general SD goal active; calibration, full package checks, and broad family/provider completion remain open.

## 2026-10-27: Bernoulli phylogenetic-interaction slope SD

The candidate already contained a native TMB slope-only interaction route. The
focused native test passes nine checks, and the independent review found the
pair covariance ordering and synthetic DGP consistent. Direct Julia now passes
14/14 on Totoro Julia 1.10.10. Its marginal simulator previously omitted the
observation-level slope loading; a zero-loading oracle failed before and passed
after the simulator fix. The Julia family guide now describes the one logit
Binomial slope route and its limits.

Added `phylo_interaction_numeric_slope` to the finite universe. The required
rows now include six Binomial link/engine cells: all three native links and all
three Julia links. The direct Julia fixture now uses link-matched synthetic
data and passes 14/14 for logit, probit, and cloglog. The two Julia non-logit
rows are narrowly admitted as exceptions for this interaction-slope route;
other structured non-logit rows remain governed by their own base-link status.
The generated universe has 19,230 rows and its 18 focused tests pass. No row
was promoted to direct-SD support. Coverage calibration remains deferred.

The updated family guide passed the prose lint. A local live bridge attempt
entered JuliaCall with Julia 1.10.12 but was interrupted after exceeding its
two-minute estimate, so it gives no new bridge verdict. I informed the active
parity lane and await its ownership response. The complete Julia docs build
started doctests but was stopped after more than seven minutes compiling
Makie dependencies; no full docs-build result is claimed. After-task report:
`docs/dev-log/after-task/2026-10-27-binomial-phylo-interaction-slope-sd.md`.

Adjacent native Bernoulli spatial-intercept and independent-slope tests have
now passed across logit, probit, and cloglog (42 focused expectations). These
are native TMB checks and do not establish Julia bridge parity.

## 2026-10-27: Binomial ordinary non-logit SD routes

Added a direct Julia test for ordinary Binomial intercept and numeric-slope SD
regression under probit and cloglog. It passed 32/32 on Julia 1.10.12. A new
native TMB recovery test passed both non-logit slope fits with 14 expectations.
The existing native non-logit intercept test remains in place. The universe now
marks Julia's four non-logit IID intercept/slope link cells as narrowly
admitted; its 19 source-expansion tests pass, and the denominator remains
19,230 rows. No coverage claim is made. Report:
`docs/dev-log/after-task/2026-10-27-binomial-nonlogit-ordinary-slope-sd.md`.

Next: continue across the remaining Bernoulli structured and block cells while
the parity lane owns its active full-suite run. Keep the broad family/effect
scope and deferred interval calibration unchanged.

Next: obtain the parity lane response, then either finish the focused live
bridge check without duplicating its edits or select the next Bernoulli
required row from the regenerated universe. Keep the broad SD goal active;
other families and effect types, interval calibration, full package checks,
and release remain open.

## 2026-10-27 continuation: Binomial mesh slopes across links

Native fixed-kappa Binomial mesh-slope SD now has focused point-recovery evidence for logit, probit, and cloglog. The test passed 40 expectations. Documentation and evidence records were refreshed; details are in `docs/dev-log/after-task/2026-10-27-native-binomial-mesh-slope-links.md` and evidence folder `docs/dev-log/general-sd-regression/evidence/native-binomial-mesh-slope-links-20261027/`. Interval coverage and Julia mesh parity remain open. The next audited native candidate is a logit q1 additive pair combining phylogenetic tree and coordinate spatial fields; `R/drmTMB.R` and `src/drmTMB.cpp` require full diff review and fresh path preflight before any edit.

## 2026-10-27 continuation: native Binomial structured SD evidence

Added independently simulated native R/TMB Binomial structured-route checks without editing the shared likelihood or builder in this slice. The phylo-tree plus animal pair now has logit/probit/cloglog recovery/output checks; the phylo plus relmat pair has probit/cloglog K-covariance recovery and K/Q equivalence for logit/probit/cloglog; animal plus relmat has probit/cloglog recovery and logit K/Q equivalence; phylo plus animal has logit A-inverse and pedigree equivalence checks; ordinary iid plus phylo has probit/cloglog recovery checks. All focused runs passed. Individual receipts and exact limits are in `docs/dev-log/general-sd-regression/evidence/native-binomial-*20261027/` and `docs/dev-log/after-task/2026-10-27-native-binomial-*.md`.

The evidence reconciler now verifies 111 distinct rows of 19,678 frozen candidates across 133 receipts. For context, 32/135 required native Binomial `mu` rows and 28/89 Julia Binomial `mu` rows have evidence receipts; these are evidence-ledger counts, not implementation-completion percentages. Coverage validation remains deferred. Julia parity, public-doc audit, remaining provider inputs, other families, and full programme gates remain open. The aggregate gate checker reports UNKNOWN because its runner is absent.

Next: read current status/diff, compare `required-rows.tsv` with `direct-sd-evidence.tsv`, and continue the next native Bernoulli row after fresh path preflight. Coordinate exact evidence with the documentation and Julia parity lanes; do not infer parity from native fits.

## 2026-10-27 continuation: current-source Bernoulli structured-pair records

The native phylogenetic plus coordinate-spatial Binomial focused suite was rerun on the current R/TMB source and passed 60 expectations. Its source manifest was refreshed; the existing probit and cloglog evidence records had been attached to the logit candidate row, so I corrected those row keys. Reconciliation now links the three phylo-spatial link rows separately.

A new synthetic native Binomial animal A-covariance plus coordinate-spatial pair test passed 16/16 for probit and cloglog. It checks both SD slopes, label-aligned predictions, and binary simulation output. The ledger now has 147 linked rows of 19,678 candidates and 167 receipt records. These are evidence counts, not completion percentages. No coverage, Julia parity, or broad family-support claim follows.

Next: continue through uncovered Bernoulli ordinary correlated-block and structured-slope rows, then use the cross-engine/family map to select the next implementation gap. Current slice receipts: `docs/dev-log/general-sd-regression/evidence/native-binomial-structured-pair-sd-20261027/` and `docs/dev-log/general-sd-regression/evidence/native-binomial-animal-spatial-nonlogit-20261027/`.

## 2026-10-27 continuation: native lognormal correlated q2 SD

Native lognormal now admits separate group-level SD formulas for intercept
and slope in one complete-data unlabelled `(1 + x | id)` block. The focused
test passed 40 expectations for both SD-slope estimates, group-SD predictions
matched to fitted formulas, and constant-SD likelihood equivalence. Source-bound receipt:
`docs/dev-log/general-sd-regression/evidence/native-lognormal-correlated-q2-sd-20261027/`.
The reconciled evidence ledger links two target members; 19,678 candidate rows
remain in the denominator, and the two rows remain unresolved pending gate reconciliation.
Both target guides rendered and pkgdown link checking passed. The full site
build was stopped after 6 minutes 46 seconds, so no full-build pass is claimed.
The DRM parity lane has been sent the exact route and receipt path. No Julia
parity or interval calibration is established.

Next: use the pinned capability ledger to choose the next native family/effect
cell with existing base-fit support, run file preflight, and preserve the
separate Julia parity lane and deferred coverage work.

## 2026-10-27 continuation: crossed Binomial intercepts under non-logit links

Added one synthetic native R/TMB crossed-intercept test for probit and cloglog. Both fits passed 18 expectations covering convergence, direction and broad recovery bounds for both SD slopes, named group SD predictions, and binary simulation. The evidence ledger now links 149 of 19,678 frozen candidates across 169 records. This remains point-recovery evidence, not interval calibration or Julia parity.

Next: inspect the still-unlinked Binomial correlated-block and structured-slope rows, verify candidate-to-receipt keys, and select a row with existing base fitting support before adding another test. Native-family breadth and Julia parity remain open.

## 2026-10-28 continuation: Bernoulli relmat q2 output workflows

Native logit Binomial `relmat(1 + x | id)` now has independent intercept and slope SD regressions through marginal simulation and a two-refit bootstrap smoke. The focused recovery/workflow block passed 31 assertions; the full q2 and neighboring target-workflow tests passed. The q2 test also checks the dense Laplace oracle, K/Q and formula-order equivalence, predictions, save/reload, and same-seed conditional versus marginal simulation. The after-task report passed its numbered-section check and prose lint. Profile endpoints remain unresolved and coverage calibration is deferred. Julia q2 parity remains unverified. Full evidence: `docs/dev-log/general-sd-regression/bernoulli-relmat-q2-report.md` and `docs/dev-log/after-task/2026-10-28-native-bernoulli-relmat-q2-marginal-bootstrap.md`.

Next: inspect the unlinked native Bernoulli structured-slope cells and select the next provider route with existing base-fit support. Confirm exact file ownership before editing; keep the separate Julia parity lane coordinated and interval-coverage work deferred.

## 2026-10-28 continuation: native Bernoulli animal q2 SD regression

Native Binomial logit now admits one unlabelled `animal(1 + x | id)` location
block with separate coefficient-selected SD formulas for supplied `A`,
`Ainv`, or pedigree inputs. The model retains the raw covariance scale and
requires complete unweighted 0/1 responses, with no other random effects.
Focused recovery and output/workflow checks passed 27 expectations; separate
assembly checks passed for all three animal inputs and retained rejection of
one-target and probit q2 routes. The existing relmat q2 suite passed 98 checks,
and the animal q1 slope suite passed 32. Report:
`docs/dev-log/after-task/2026-10-28-native-bernoulli-animal-q2-sd.md`.

The docs-audit lane was sent the capability boundary and asked to update the
public guide, README, and check log. The check-log preflight found 451 divergent
refs, so this slice did not edit that shared file. No Julia parity, interval
coverage, full package check, or user-facing docs build is established.

Next: reconcile the docs-audit response, then select the next unresolved
Bernoulli structured or block row. Preserve the separate Julia parity lane and
keep interval coverage calibration deferred.

## 2026-10-29 continuation: Julia Binomial animal q2 pedigree and mixed phylo-IID bridge

Added a fixed-seed R-to-Julia bridge test for the Binomial animal q2
intercept-plus-slope model using pedigree input. It passes on Julia 1.10.0 for
logit, probit, and cloglog, comparing the observed-animal covariance ordering,
native/Julia convergence and likelihood, coefficient-specific SD estimates,
group SD predictions aligned by animal label, and marginal binary simulation.
The model source was already present; this adds recovery and output evidence,
not a code-path change. Exact receipt:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-q2-pedigree-bridge-20261029/`.

Also reran the existing Julia Binomial phylogenetic-plus-IID bridge test live
with the paired Julia worktree configured. It passed for probit and cloglog;
the slope assertion supports a focused-test grade, not close recovery. The
separate receipt is
`docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-iid-live-rerun-20261029/`.

The evidence reconciliation passes with 20,350 candidate rows, 207 linked
rows, and 232 records. All new rows remain unreviewed; no support status or
coverage claim changed. The structural closeout check reports 13 acceptance
ledgers as not runnable because Node or `gate-check` is missing, so those gates
remain UNKNOWN. No full suite or docs build was run.

Next: check the remaining exact Bernoulli q1/q2 provider-link cells in the
current required-row table and choose one with an existing route but missing
live or recovery evidence. Keep interval coverage deferred, preserve all other
dirty edits, and leave broader public wording with the documentation audit
lane.

## 2026-10-29 continuation: mixed phylogenetic-IID Binomial logit bridge

Extended the existing Julia Binomial phylogenetic-intercept plus IID-intercept
bridge test to logit. The live candidate test now passes for logit, probit, and
cloglog, including both-engine convergence and likelihood checks, target labels
and SD predictions, and marginal simulation. No model code changed. The
evidence grade is focused-test because the SD-slope checks are directional and
broad-bound, not close recovery. Exact receipt:
`docs/dev-log/general-sd-regression/evidence/julia-binomial-phylo-iid-all-links-20261029/`.

The two earlier evidence snapshots remain verifiable. I reconstructed the
probit/cloglog-only test source by reversing only the new logit assertion and
loop edit, checked its digest against the old record, and retained it under the
older receipt directory. Current evidence reconciliation passes with 20,350
candidate rows, 208 linked rows, and 235 records; all new rows remain
unreviewed and no support status changed. Coverage and broad parity remain
open.

Next: use `required-rows.tsv` and the source map to choose the next uncovered
Bernoulli provider or block row. Prefer an existing candidate route with a
missing required test or output surface. Keep interval coverage deferred and
coordinate public wording with the documentation audit lane.

## 2026-10-29 continuation: correlated q2 Binomial bridge all links

Extended the ordinary correlated q2 live Julia bridge test to logit, probit, and cloglog. The focused run passed one live test with 50 expectations and no skips or failures. Source snapshot and receipt are under `docs/dev-log/general-sd-regression/evidence/julia-binomial-correlated-q2-all-links-bridge-20261029/`. Evidence reconciliation passes with 20,350 rows, 209 linked and 236 evidence records; the new row is unreviewed and no support status changed. No model code or coverage validation changed.

Next: select a Bernoulli row from the remaining unlinked provider/block cells that has a live implementation path but lacks a focused output or workflow test. Keep public support wording with the documentation audit lane.

## 2026-10-29 continuation: Binomial animal pedigree plus IID bridge

Added a direct synthetic logit bridge test for pedigree-derived animal covariance plus an independent IID site intercept, with separate SD predictors. Native TMB and Julia converged; the test checked payload ordering, target labels, likelihood and predicted group SD agreement, and marginal binary simulation. The exact source snapshot and receipt are under `docs/dev-log/general-sd-regression/evidence/julia-binomial-animal-pedigree-iid-bridge-20261029/`. Reconciliation passes with 20,350 candidate rows, 210 linked and 237 evidence records. The new row remains unreviewed; no support promotion or coverage claim.

Next: choose the next Bernoulli structured provider pair that is already admitted by the candidate, prioritizing an unlinked row with a direct bridge test path. Keep the public capability statement with the separate audit lane.

## 2026-10-29 continuation: Binomial animal Ainv plus IID bridge evidence

The existing independent-oracle animal-plus-IID test was rerun with `NOT_CRAN=true`; one live Julia bridge test passed with no failures or skips. It compares animal `Ainv` against equivalent `A`, fits both engines, checks predictions, and exercises marginal simulation. The exact `animal:Ainv_precision + group_factor` Julia logit row now has source-pinned focused-test evidence. Reconciliation passes with 20,350 rows, 211 linked and 238 records; evidence is unreviewed and no public support status changed.

Next: inspect the remaining Bernoulli structured-pair rows and identify a candidate route that still lacks implementation, rather than only accumulating duplicate evidence for already-tested inputs.

## 2026-10-29 continuation: Binomial animal Ainv plus IID bridge evidence

The existing independent-oracle animal-plus-IID test was rerun with `NOT_CRAN=true`; one live Julia bridge test passed with no failures or skips. It compares animal `Ainv` against equivalent `A`, fits both engines, checks predictions, and exercises marginal simulation. The exact `animal:Ainv_precision + group_factor` Julia logit row now has source-pinned focused-test evidence. Reconciliation passes with 20,350 rows, 211 linked and 238 records; evidence is unreviewed and no public support status changed.

Next: extend the live Julia q3 correlated Binomial bridge fixture to logit, where three exact target-member rows remain unlinked.

## 2026-10-29 continuation: current-source correlated q3 logit

The dedicated high-information Julia Binomial q3 logit bridge test passed against current source in 7:56, with one live bridge test and no failures or skips. Three SD targets, TMB comparisons, and simulation checks passed. Source-pinned recovery evidence now links the intercept and both random slopes. Reconciliation passes with 20,350 rows, 214 linked and 241 records; new records remain unreviewed and no support promotion or coverage claim occurred.

A preliminary smaller-fixture attempt exceeded its four-minute estimate and was stopped before producing a fit result. Its test edit was reverted and the prior source hash restored. Next: move from these Bernoulli route gaps to a missing non-Bernoulli family row with ordinary random intercept SD regression, choosing a route that can be implemented and checked end to end.

## 2026-10-29 continuation: current-source correlated q3 logit

The dedicated high-information Julia Binomial q3 logit bridge test passed against current source in 7:56, with one live bridge test and no failures or skips. Three SD targets, TMB comparisons, and simulation checks passed. Source-pinned recovery evidence now links the intercept and both random slopes. Reconciliation passes with 20,350 rows, 214 linked and 241 records; new records remain unreviewed and no support promotion or coverage claim occurred.

A preliminary smaller-fixture attempt exceeded its four-minute estimate and was stopped before producing a fit result. Its test edit was reverted and the prior source hash restored. Next: inspect the unresolved family/effect map and select a non-Bernoulli row with a concrete implementation gap, prioritizing a supported response family's ordinary random-effect SD regression.
