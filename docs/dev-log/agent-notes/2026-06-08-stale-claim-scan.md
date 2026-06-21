# Stale-Claim Scan: q8 Coverage/Power And Skew-Normal Boundaries

Date: 2026-06-08

Reader: drmTMB maintainers checking whether public, design, test, simulation,
and after-task wording has drifted beyond the current evidence boundary.

## Scope

Read-only stale-claim scan, except for this note. I did not edit README, NEWS,
ROADMAP, design docs, tests, vignettes, or status ledgers.

Baseline used for classification:

- q8: the first ordinary Gaussian all-endpoint q8 block is fitted and has
  diagnostic smoke/recovery artifacts, but q8 coverage, q8 power, and q8
  interval readiness remain unavailable.
- `skew_normal()`: the univariate fixed-effect `mu`/`sigma`/`nu` first slice is
  implemented. Random effects, structured effects, known sampling covariance,
  bivariate skew-normal, residual `rho12`, latent `skew(id)`, and completed
  formal recovery grids remain unavailable.

## Exact Commands

```sh
rg -n --hidden -S --glob '!.git/**' --glob '!docs/dev-log/agent-notes/2026-06-08-stale-claim-scan.md' '(q8|p8).{0,100}(coverage|power|interval|ready|calibrat|recover|recovery|complete|done|support)|(?:coverage|power|interval|ready|calibrat|recover|recovery|complete|done|support).{0,100}(q8|p8)'
rg -n --hidden -S --glob '!.git/**' --glob '!docs/dev-log/agent-notes/2026-06-08-stale-claim-scan.md' '(skew_normal|skew normal|skew-family|skew family|skewed).{0,140}(random|structured|bivariate|rho12|skew\(|coverage|power|recover|recovery|complete|ready|support|family|formal)|(?:random|structured|bivariate|rho12|skew\(|coverage|power|recover|recovery|complete|ready|support|family|formal).{0,140}(skew_normal|skew normal|skew-family|skew family|skewed)'
rg -n --hidden -S --glob '!.git/**' --glob '!docs/dev-log/agent-notes/2026-06-08-stale-claim-scan.md' 'skew\([^)]*id|skew_normal\(|skew normal|skew_normal'
rg -n -S 'skew_normal\(\).*\(planned\)|skew_normal\(\).*planned|planned.*skew_normal\(\)|not yet fitted in `drmTMB`|no fitted skew-family|Use this planned syntax only|future `skew_normal\(\)`|skew_normal\(\).*not fitted|skew-normal.*not fitted|skew-family recovery grids|formal recovery.*(ready|complete|passed)|formal.*skew_normal.*(ready|complete|passed)' README.md NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md inst/sim/README.md vignettes R tests man --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/design/archive/**'
rg -n -S 'q8.*(coverage|power|interval).*(ready|passed|complete|supported|available|usable|claim)|q8.*(ready for coverage|ready for power|coverage-ready|power-ready|interval-ready)|q8.*Wald intervals.*usable|q8.*coverage result|q8.*power result|q8.*formal.*(recovery|coverage)|q8.*hold_diagnostic|q8.*diagnostic' README.md NEWS.md ROADMAP.md docs/design docs/dev-log/known-limitations.md inst/sim/README.md vignettes R tests man --glob '!docs/dev-log/check-log.md' --glob '!docs/dev-log/after-task/**' --glob '!docs/design/archive/**'
```

## Intended Boundary Wording

- `NEWS.md:4` correctly says `skew_normal()` fits only the first univariate
  fixed-effect location-scale-shape slice and keeps random effects,
  `sd(group)`, structured effects, known covariance, bivariate skew-normal,
  residual `rho12`, and latent `skew(id)` planned.
- `NEWS.md:5` correctly keeps q8 at `hold_diagnostic`, names the failed
  interval evidence, and says q8 has no coverage result, power claim, random
  `rho12`, structured q8 sibling, or non-Gaussian q8 route.
- `README.md:229` correctly describes `skew_normal()` as a fixed-effect first
  slice and keeps skew-normal random or structured effects planned.
- `README.md:235` correctly says q8 smoke/recovery artifacts exist, but q8
  coverage and power remain closed.
- `docs/design/157-capability-completion-worklist.md:61-62` is the clearest
  current boundary: q8 coverage/power/interval claims remain unavailable, and
  fixed-effect `skew_normal()` has no completed formal recovery grid or
  random/structured/bivariate neighbours.
- `docs/design/02-family-registry.md:60,76-80`,
  `docs/design/41-phase-18-simulation-programme.md:39-41`,
  `docs/design/46-pre-simulation-readiness-matrix.md:137-144,167`,
  `vignettes/formula-grammar.Rmd:44`, and
  `vignettes/implementation-map.Rmd:121,152,169,186,202` also keep the current
  q8 and skew-normal boundaries mostly aligned.
- `tests/testthat/test-phase18-structured-workflow-registry.R:509` is intended
  boundary wording: "artifact-ready but diagnostic before power".

## Suspicious Or Stale Claims

- `vignettes/robust-student.Rmd:249-268` is stale. It says skew-normal residual
  asymmetry is "not a fitted option today", labels the example "Planned, not
  fitted yet", and tells readers to use the syntax only in design notes until
  density and recovery checks exist. That contradicts the current implemented
  fixed-effect first slice.
- `docs/design/158-phase-19-comparator-matrix.md:71` is stale. It lists
  `skew_normal()` as planned and "not yet fitted in `drmTMB` (Tier C in doc
  157)", but doc 157 now says fixed-effect `skew_normal()` is implemented
  first slice.
- `docs/design/41-phase-18-simulation-programme.md:1010-1017` is stale as
  unqualified prose. It says the skew-normal implementation gate keeps
  `skew_normal()` planned, not fitted, and adds no constructor or TMB branch.
  If retained as history, it needs a "before the 2026-06-08 implementation"
  qualifier.
- `docs/design/125-phase-18-next-two-team-slices-1619-1718.md:41-51` is stale
  unless read strictly as a historical slice note. It still says "future
  `skew_normal()` family" and labels the example "Planned, not fitted".
- `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md:97-101`
  is partially stale. The false-positive warning remains useful, but the line
  saying a positive result must not be reported as evidence that
  `skew_normal()` is fitted should now target broader claims, such as formal
  recovery, examples outside fixed-effect `mu`/`sigma`/`nu`, or random/structured
  support.
- `ROADMAP.md:2188` is not a q8 interval overclaim, but "source or artifact
  coverage" is ambiguous terminology next to q8. It can be read as interval
  coverage even though the row later says formal q > 2 recovery grids remain
  boundary-tested.

## Recommended Edits

1. In `vignettes/robust-student.Rmd`, replace the planned-only paragraph with
   fixed-effect first-slice wording:
   "`skew_normal()` is now available for one-response fixed-effect
   `mu`/`sigma`/`nu` models. Use it only for residual asymmetry after checking
   Gaussian and Student-t fits; random effects, structured effects, bivariate
   skew-normal, residual `rho12`, and latent `skew(id)` remain unsupported."
2. In `docs/design/158-phase-19-comparator-matrix.md`, change the row to
   "`skew_normal()` fixed-effect first slice" and replace "not yet fitted" with
   "fitted for univariate fixed-effect `mu`/`sigma`/`nu`; random/structured/
   bivariate routes and formal recovery grids are not complete."
3. In `docs/design/41-phase-18-simulation-programme.md` and
   `docs/design/125-phase-18-next-two-team-slices-1619-1718.md`, either add
   explicit historical qualifiers or update the local slice summaries to say
   they were superseded by the 2026-06-08 fixed-effect implementation.
4. In `docs/design/128-phase-18-skew-normal-test-contract-slices-1673-1702.md`,
   narrow the warning to "must not be reported as evidence for completed formal
   recovery or for random/structured/bivariate skew-normal support."
5. In `ROADMAP.md:2188`, replace "source or artifact coverage" with
   "source tests or artifact evidence" to avoid colliding with interval
   coverage terminology.
