# Lane-B E0 binding-source recovery

**Scope:** internal campaign-readiness provenance only. This record changes no
capability-ledger row, public claim, default, association route, bootstrap
route, missing-response route, or compute state.

## Finding

The archived sources recover route/DGP provenance for two high-value batches,
but neither batch authorizes an interval campaign yet. The distinction is
intentional: a recovery DGP or a generic profile-target API test is not a
reviewed `cell × target` coverage contract.

| Batch | Candidate cells | Recovered source | What is recoverable | Still required before binding |
| --- | ---: | --- | --- | --- |
| Count q1 one-slope | `mc-0410`–`mc-0413`, `mc-0435`, `mc-0441`, `mc-0448`, `mc-0452` | `tools/slurm/count-slope-recovery-rorqual.sbatch`; `docs/dev-log/simulation-artifacts/2026-06-29-count-slope-recovery-rorqual/`; the eight `tools/run-structured-re-count-slope-*-local-micro-shard.R` runners | provider/family route, formula cell, 80 seeds `760001:760080`, source SHA receipts, and truth for fixed effects plus intercept and slope SDs | choose and review the exact profile estimand(s) per cell; recovery runners record estimates, not profile intervals |
| Bivariate REML fixed/q2/q4 | `mc-0182`–`mc-0185`, `mc-0208`–`mc-0209`, `mc-0212`–`mc-0219` | `tests/testthat/test-reml-bivariate.R`; `docs/design/221-native-reml-finish.md`; `R/profile.R` target construction | formulas, fixture truths, q2/q4 covariance construction, and direct target identities | select target cardinality for the fixed-effect routes and run a separate exact-DGP profile smoke; generic target tests explicitly permit `profile_failed` |

## Count-source boundary

The Rorqual sbatch records the exact eight provider/family shards and the
original seed block. Its copied replicate tables retain each seed, truth,
fit state, and `pdHess`, so their recovery provenance is stronger than a
ledger note. It remains recovery-only by its own contract: it never calls
`confint()`, has no interval endpoints, and labels its denominator
`not_coverage_evidence`. The one-slope DGPs contain *both* an intercept SD and
a slope SD. Therefore the archived `sd_mu_intercept` and `sd_mu_x` columns do
not license silently selecting either as the future profile target.

## REML-source boundary

The fixed bivariate fixture sets `beta1 = (0.3, 0.5)`, `beta2 = (0.1, 0.2)`,
residual SD1 `0.8`, and residual SD2 `0.9`; each fixed route can expose both
an intercept and an `x` profile target. The q2 and q4 fixtures identify their
structured axes, including the dense q4 adequate-power smoke. They establish
target names such as `sd:mu:mu1:phylo(1 | p | sp)` but not a completed profile
attempt for the exact REML campaign DGP. No source supports treating a finite
generic profile test as coverage evidence.

## Local technical smoke (route validation only)

On the then-current Lane-B readiness source, the recovered count fixture was
run locally at its archived first seed (`760001`) with the required named
`tree` object and exact q1 Poisson phylogeny formula
`poisson_phylo ~ x + phylo(1 + x | site, tree = tree)`. Both direct targets
were profile-ready and returned endpoint profiles: `sd:mu:phylo(1 | site)`
returned `[0, 0.4095412]`, and `sd:mu:phylo(0 + x | site)` returned
`[0, 0.3115247]` (both `conf.status = "profile"`). This is a local
formula/target-routing smoke only: one seed, no coverage denominator, no
historical-cell reclassification, no target-selection decision, and no remote
compute. It also caught and resolved the required grammar detail that the
marker must receive a named `tree` object rather than an inline `sim$tree`
expression.

## Binding rule carried forward

Only a canonical binding table may turn either recovery result into a schedule.
It must name an exact DGP function/version, formula, truth on its reporting
scale, one or more namespaced direct profile targets, information rung, and
source receipt. Any cell lacking all of those remains unavailable. K=12 keeps
its dedicated negative-control target and must remain incomplete/unavailable.
