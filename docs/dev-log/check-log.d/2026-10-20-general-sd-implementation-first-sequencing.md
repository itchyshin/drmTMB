# Check log: implementation-first sequencing for general SD regression, 2026-10-20

## Superseding decision, 2026-10-20

Shinichi approved the full implementation scope with interval-coverage
calibration deferred beyond this goal's finish line. The earlier sentence below
that kept P8 in the current finish line is superseded. The earlier 4-8 month
estimate is withdrawn; the plan now requires dependency-clustered re-estimation
after the capability and ownership audit. Current completion requires the
implementation and light-check gates, both engines, public outputs, and docs.
Do not claim interval coverage until a separate calibration study passes.

Updated `LOOP/lanes/general-sd-regression/ultra-plan.md` after Shinichi's
decision to stage implementation before formal interval calibration. P1a is
marked complete based on the filed NotebookLM methods review. P3 now
means Bernoulli implementation on both engines, targeted numerical and
constant-SD checks, a small independent synthetic recovery smoke, public
outputs, and documentation. Coverage validation is P8, after implementation
waves P3-P7. The full finish still includes P8; profile and bootstrap intervals
must be described as not coverage-validated until then.

Provisional timing in the plan: 1-2 weeks for the first Bernoulli implementation
milestone and 4-8 elapsed months for the full implementation breadth with 2-3
sustained contributors, excluding P8. These ranges need re-estimation after the
active capability inventory and existing work are reconciled.

Checks: scoped `git diff --check` passed; prose checks had zero findings; the
after-task structure check passed, while its full check correctly reports open
programme gates. The status-inventory search used
status-inventory search used
`rg -n -i 'calibrat(ed|ion)|coverage|profile interval|confidence interval' README.md docs/dev-log/internal-roadmap.md NEWS.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd vignettes/predictor-dependent-random-sd.Rmd _pkgdown.yml`.
The Bernoulli vignette already states that its examples do not establish
calibrated interval coverage. No model code or tests changed.

Light checks run after this plan update:

- Native TMB: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "binomial-phylo-sd-regression")'` passed 12/12 assertions in 5.3 seconds. This fits one synthetic 36-tip by 30-observation design and checks the phylogenetic SD slope, predictions, and constant-SD equivalence.
- Julia design: `JULIA_NUM_THREADS=4 OPENBLAS_NUM_THREADS=1 julia --project -e 'include("test/test_binomial_sd_formula_design.jl")'` passed 5/5 assertions in 4.1 seconds. It checks factor/interaction coding and rejection of a within-group-varying SD predictor; it does not fit a model.

The native result is a single-dataset recovery smoke, not interval calibration.
No live Julia inference or cross-engine fit was run because the Julia inference
file still requires its owner handoff.

At the time of the initial sequencing note, the unlazy `GATES.md` still listed
calibrated intervals in G2 and was under the live lease
`codex:general-sd-regression-clean-current-adapter-qualification-20261020`.
The later scope revision below supersedes that status.

## Follow-up after the finish-line revision

The live goal, plan, execution arcs, unlazy ledger, and checkpoint now agree:
coverage is a deferred P8/G5 follow-on, not a blocker for implementation
completion. Its detailed gate is retained at
`docs/dev-log/general-sd-regression/deferred/native-calibration-GATES.md`,
outside the active unlazy tree. Bernoulli and the broader capability universe
remain in scope.

On the current candidate, `Rscript -e 'devtools::test(filter = "lognormal-sd-assembly")'`
passed 24 assertions in 1.5 seconds, with no warnings or skips; this was a
fit-free assembly test. `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1
MKL_NUM_THREADS=1 Rscript -e 'devtools::test(filter =
"lognormal-sd-integration")'` passed 24 assertions in 69 seconds, with no
warnings or skips. The latter is a native integration/recovery smoke on its
fixture and is not interval-coverage evidence. Neither command exercised live
Julia. `git diff --check` and the prose checker passed for the revised goal,
plan, and ledger. The broader implementation goal remains active.
