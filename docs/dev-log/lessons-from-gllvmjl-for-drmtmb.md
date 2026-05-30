# GLLVM.jl Lessons for drmTMB: Provenance and Current Status

This note preserves Claude's GLLVM.jl scouting memo as a status-checked
development artifact. It is not an implementation plan. Each item below is a
candidate lesson from the Julia sister project, checked against current
`drmTMB` source and recent after-task reports.

The reader is a future `drmTMB` contributor deciding whether a sister-package
idea is already absorbed, needs a narrow validation slice, or belongs outside
the current one-response/two-response package scope.

## Provenance

Source repositories:

- `/Users/z3437171/Dropbox/Github Local/gllvmTMB.jl/`
- `/Users/z3437171/Dropbox/Github Local/gllvmTMB-julia-bench/`

Current local source state when this note was cleaned:

- `gllvmTMB.jl`: commit `6a0d090`, clean `main...origin/main`
- `gllvmTMB-julia-bench`: commit `9de254a`, dirty working tree

`gllvmTMB.jl` is MIT licensed by Shinichi Nakagawa. No code is copied into
`drmTMB` by this note. If a later task ports or adapts code, that task must
record the source file, source commit, license, adaptation, and reviewer in
`inst/COPYRIGHTS` before the task is complete. The benchmark repo did not have
a visible license file in the local checkout; treat it as internal evidence
until that is clarified.

The original scouting memo cited `report/note-to-russell.md`, but that file was
not present in either local sister checkout during this cleanup. Use the files
listed below instead.

## Evidence That Exists

The headline GLLVM.jl results are local sister-repo evidence, not direct
`drmTMB` evidence. They can motivate benchmarks and validation slices, but they
do not by themselves support `drmTMB` speed, recovery, or coverage claims.

| Lesson | Local GLLVM.jl evidence | drmTMB status |
| --- | --- | --- |
| Sparse augmented phylogenetic precision | `gllvmTMB.jl/src/sparse_phy.jl`, `src/likelihood_sparse_phy.jl`, and `gllvmTMB-julia-bench/report/comparison-final.md` | Already partly absorbed. `drmTMB` has `drm_phylo_augmented_precision()`, passes `Q_phylo`, and declares `DATA_SPARSE_MATRIX(Q_phylo)`. The next slice is a benchmark/API gate, not adding sparse phylogeny from scratch. |
| Transformed-Wald bounded intervals | `gllvmTMB.jl/src/confint_derived_wald.jl`; coverage table in `comparison-final.md` | Already source-checked for direct `rho12` and row-specific Wald `rho12` paths. Future derived bounded quantities need their own targets and simulations before claims. |
| Gaussian and bivariate Gaussian starts | `gllvmTMB.jl/src/ppca_init.jl` as the motivating principle | Already source-checked for `lm.fit()` location starts, residual-SD starts, and Fisher-z `rho12` starts. Do not repeat the stale claim that defaults are intercept-only zero slopes. |
| Positive-scale bootstrap percentiles | GLLVM.jl bootstrap coverage and implementation notes in `comparison-final.md` and related bench code | Already implemented for direct positive `exp` targets in `confint(..., method = "bootstrap")`. Coverage remains unclaimed without `drmTMB` simulations. |
| Sigma profile-out when `sigma ~ 1` | `gllvmTMB.jl/src/profile.jl` | Plausible future design gate. `drmTMB` does not currently profile out `beta_sigma`; changing this affects optimization geometry and `vcov()` expectations. |
| Edge-incidence and relaxed-clock ideas | `gllvmTMB.jl/src/edge_incidence.jl`, `src/relaxed_clock.jl`, related bench files | Mostly outside current `drmTMB` scope. Any branch-rate or relaxed-clock syntax would change formula grammar and should start as a design/ADEMP discussion, not a code slice. |
| EM/SQUAREM fallback | `gllvmTMB.jl/src/em_squarem.jl` and related bench files | Hypothesis only. `drmTMB` has no EM path; this would be a separate solver design, not a quick optimizer flag. |

## Already Absorbed or Source-Checked in drmTMB

These follow-up tasks converted the broad GLLVM.jl memo into narrower
`drmTMB` evidence:

- `docs/dev-log/after-task/2026-05-29-claude-gllvmjl-transfer-audit.md`
  checked transformed-Wald `rho12` routes and added a focused
  `predict_parameters()` regression.
- `docs/dev-log/after-task/2026-05-29-sparse-phylo-source-map.md` verified the
  current sparse phylogenetic precision source map and reframed the next step
  as benchmarking/API design.
- `docs/dev-log/after-task/2026-05-29-gaussian-start-contract.md` checked and
  tested Gaussian and bivariate Gaussian internal starts.
- `docs/dev-log/after-task/2026-05-29-bootstrap-log-scale-positive-intervals.md`
  implemented log-scale bootstrap percentiles for direct positive targets.

Those reports supersede the original memo wherever they disagree with it.

## Conservative Next Work

Good next slices are small, measurable, and compatible with the
one-response/two-response package contract:

1. Benchmark current sparse `phylo()` scaling on representative `drmTMB`
   fixtures, including small dense-parity checks and larger p = 50, 200, and
   1000 timing cells.
2. Design `sigma ~ 1` profile-out as an optimizer-geometry proposal, with
   equivalence checks against the current unprofiled likelihood before code
   changes.
3. Add package-specific simulations before making any transformed-Wald,
   bootstrap, or profile coverage claim transferred from GLLVM.jl.
4. Treat relaxed-clock or per-branch-rate ideas as out-of-lane unless the owner
   explicitly opens a formula-grammar and ADEMP design task.

## Guardrails

- Do not introduce `phylo_relaxed()` or branch-rate formula syntax from this
  memo. That would change formula grammar and needs
  `docs/design/01-formula-grammar.md` plus a separate design decision.
- Do not use `tau ~` for meta-analysis or branch-rate syntax. Keep `sigma`,
  `rho12`, `sd(group)`, `phylo()`, and `spatial()` stable in user-facing docs.
- Do not describe GLLVM.jl speedups as `drmTMB` speedups. Say "candidate
  benchmark target" until `drmTMB` has its own benchmark artifacts.
- Do not describe GLLVM.jl coverage as `drmTMB` coverage. Say "sister-repo
  hypothesis" until `drmTMB` has package-specific simulations with MCSE.
- Do not add code from GLLVM.jl without updating `inst/COPYRIGHTS`.

## Source Files for Future Readers

Read these files before opening a porting or benchmark slice:

- `gllvmTMB.jl/src/sparse_phy.jl`
- `gllvmTMB.jl/src/likelihood_sparse_phy.jl`
- `gllvmTMB.jl/src/confint_derived_wald.jl`
- `gllvmTMB.jl/src/ppca_init.jl`
- `gllvmTMB.jl/src/profile.jl`
- `gllvmTMB.jl/src/edge_incidence.jl`
- `gllvmTMB.jl/src/relaxed_clock.jl`
- `gllvmTMB.jl/src/em_squarem.jl`
- `gllvmTMB-julia-bench/report/comparison-final.md`

When using the bench report, first re-check the `gllvmTMB-julia-bench` working
tree because the local checkout was dirty when this note was cleaned.
