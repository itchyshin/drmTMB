# Execution arcs

| Arc | State | Evidence / next gate |
|---|---|---|
| P0 inventory and source reconciliation | doing | 19,118 required rows retained; base-route and candidate identifiability review pending |
| P1a NotebookLM review | done | cited methods synthesis retained; primary-source verification and design acceptance continue under P1b |
| P1b symbolic/API contract | doing | reviewed mathematical contract; research acceptance pending |
| P2 common machinery | doing | ordinary target resolver committed; native selectors compiled; structured/block contracts remain |
| P3 Bernoulli both-engine implementation | doing | Native and direct Julia Binomial `phylo_interaction()` SD routes have focused synthetic checks; the Julia candidate test passed 33/33 locally, with a separate Totoro 33/33 receipt. The R-to-Julia bridge now covers coordinate-spatial intercept/slope-only and phylogenetic-interaction intercept SD routes for logit, probit, and cloglog. The interaction bridge has same-data TMB comparisons, pair-specific SD prediction, and seeded marginal simulation. Remaining Bernoulli routes and family/effect breadth are open. Boundary Hessian diagnostics remain; interval coverage calibration is deferred under P8 and no interval-calibration claim is made |
| P4-P7 all remaining required cells | doing | native Poisson relatedness/animal cells and one Gamma q1 animal-pedigree SD regression cell checked; same-data native/Julia Gamma comparisons cover a q1 animal intercept and a slope-only coefficient with unit-diagonal supplied covariance, with the slope-only run now bound by a refreshed 198-file source manifest. A new NB2 q1 animal-intercept test compares supplied `A` with equivalent pedigree input and passes coefficient, likelihood, and named-prediction checks. The LogNormal sigma-SD route also passes three fixed-seed bootstrap refits with target retention, as workflow evidence only. Complete-response native hurdle NB2 has point-recovery and workflow checks for one ordinary `mu` intercept, and for one independent slope when its coefficient has a matching predictor-dependent SD formula. ZIP now has source-stable native/Julia evidence for one mean intercept and one explicitly selected independent mean slope with fixed-effect-only `zi`; this is still one narrow cell per effect type. Broader family/provider/effect/Julia scope retained |
| P8 interval coverage calibration | deferred follow-up | staged design and timing evidence exist; defer campaign until implementation breadth, and keep all current uncertainty claims explicitly uncalibrated |
| P9 documentation/checks | doing | hurdle NB2 count example updated and rendered; formal grammar now names the paired hurdle intercept/slope route and positive-count SD-design rank rule; remaining breadth docs and checks are outstanding. Count, formula-grammar, and implementation-map vignettes rendered; `pkgdown::check_pkgdown()` passes. Full site and package checks remain |
| P10 independent closeout/reconciliation | todo | programme not complete |

## 2026-10-24 Binomial animal plus IID intercept recovery

The native combined animal and IID intercept candidate now has a balanced
recovery fixture with site assignment independent of the AR(1) animal order.
The focused test passes point recovery, separate target mapping, and save/reload.
This is one partial G3/G4 cell. It records a native point-recovery result and
closes no programme gate. The old
fixture failure and two larger-seed pilot estimates are recorded in
`docs/dev-log/after-task/2026-10-24-binomial-animal-iid-sd-recovery-design.md`.
The model still needs an independent objective oracle and Julia comparison.

## 2026-10-24 Julia Gamma animal simulation documentation

The public help and Julia guide now describe the tested complete-data animal
intercept and intercept-plus-slope marginal simulation routes, their fixed
`sigma ~ 1` requirement, and normalization of non-unit `A`. Four focused live
Julia tests passed, and the vignette and pkgdown reference checks passed. This
is partial G4 workflow evidence only. See
`docs/dev-log/after-task/2026-10-24-julia-gamma-animal-simulation-routes.md`.
The follow-up covariance audit found that Julia Gamma animal normalization
differs from the approved raw-kernel multiplier contract and native TMB for
non-unit `A`. It also conflicts with preserving existing Julia constant-SD
fits if the change is limited to SD-regression routes. Non-unit cross-engine
parity stays unresolved pending contract resolution.

## 2026-10-25 SkewNormal independent-slope SD bridge probe

The focused native TMB SkewNormal SD test passed 17/17 checks. The paired
Julia direct SD test passed 20/20 checks in 28.8 seconds. A disposable
same-data public bridge probe then showed that the R bridge still refuses
SkewNormal random effects: its family registry marks the family fixed-effect
only, and `drm_julia_refuse_fe_only_random_effects()` stops the model before
Julia runs. No shared bridge file was changed. The DRM parity lane was asked
to confirm ownership; continue with the narrow bridge admission and same-data
test after its handoff. These checks add no capability row and close no gate.

## 2026-10-25 SkewNormal independent-slope SD Julia bridge

The R bridge now admits one complete-response SkewNormal ordinary `mu`
intercept or independent numeric slope with a matching `sd()` formula and
fixed `sigma ~ 1`, `nu ~ 1`. The first live Julia fit exposed a missing payload
label for its generic `sd` coefficient block; the narrow family route now maps
that block correctly. The final focused run passed 36 expectations, including
one live same-data TMB/Julia slope fixture and the native SkewNormal SD test.
This is one point-recovery fixture, not interval calibration or general parity.
The after-task report is
`docs/dev-log/after-task/2026-10-25-julia-skewnormal-sd-bridge.md`. P3 remains
doing and P4-P7 remain open; no programme gate closes.

## 2026-10-25 zero-truncated NB2 selected-slope Julia bridge

A narrow complete-positive-count bridge path now admits a matching selected
independent numeric `mu` slope with fixed `sigma`, while the existing Hurdle
route remains separate. The live R/TMB and Julia test passed 22 expectations;
its hash-bound receipt links one Julia candidate row as `focused_test`, with no
row promotion. The broader native quadrature filter was interrupted after its
60-second estimate and adds no passing evidence. Interval calibration and all
other zero-truncated NB2 shapes remain open.


## 2026-10-25 Gaussian sigma random-slope SD

The native Gaussian builder now admits one independent numeric random slope on
residual `sigma` with a group-constant fixed-predictor SD formula. The focused
intercept-plus-slope test filter passed, the source manifest is stable, and the
vignette/pkgdown checks passed with existing Pandoc deprecation warnings. The
unreviewed receipt links one native Gaussian sigma slope candidate row without
promoting it. Julia parity, interval calibration, broader Gaussian structures,
and the programme gates remain open. See
`docs/dev-log/after-task/2026-10-25-gaussian-sigma-slope-sd.md`.


## 2026-10-25 Native NB2 sigma random-slope SD

One independent numeric random slope on the non-inflated NB2 `sigma` predictor
now accepts a matching predictor-dependent SD formula under fixed `mu` and
complete-data conditions. The base constant-SD sigma-slope model is admitted
for equivalence under the same boundary. The exact intercept-plus-slope filter
passed with source-stable inputs; the tutorial rendered and pkgdown found no
problems with existing Pandoc warnings. One unreviewed native row is linked; no
Julia parity, interval calibration, or programme gate is claimed. Details:
`docs/dev-log/after-task/2026-10-25-nbinom2-sigma-slope-sd.md`.


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

## 2026-10-27 Julia Binomial coordinate-spatial SD

Direct Julia Binomial spatial intercept and independent-slope routes pass focused
logit, probit, and cloglog checks, including an extreme-SD prediction guard and
seeded marginal simulation. A math review caught and corrected an inconsistency
between the fitted likelihood, stored scales, and simulator. The family guide
now has a runnable synthetic spatial-slope example. Six exact Julia ledger rows
link to a source-bound receipt; they remain unreviewed. No interval coverage or
native TMB parity is claimed. The adjacent full Bernoulli SD test file is
partial after 172 passing assertions and an interruption during a phylogenetic
fit. See the checkpoint and after-task report for exact evidence and limits.
