# After Task: Phase 18 Count First-Wave Closure, Slice C

## Goal

Close the next Phase 18 review lane after the common-family artifacts by
recording the count first-wave inventory, revalidating the focused count and
first-wave smoke tests, and naming the Slice D choices without adding new
syntax or new likelihood code.

## Implemented

Slice C is a documentation and validation lane. It adds
`docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md`,
updates the Phase 18 simulation programme, roadmap, common-family completion
map, and NEWS, and keeps Conway-Maxwell-Poisson/COM-Poisson as a later
count-family candidate rather than part of the current count closure.

The implemented claim is narrow: the current count first-wave story is
ordinary count mixed models plus q=1 phylogenetic smoke/formal-admission
routes. It is not broad count-family parity.

## Mathematical Contract

The closure note restates the two count contracts most likely to be confused.
For ordinary NB2 log-`sigma` random intercepts:

```text
a_j ~ Normal(0, sd_sigma_intercept^2)
eta_mu_jk = beta0 + beta1 * x_jk
mu_jk = exp(eta_mu_jk)
eta_sigma_jk = gamma0 + gamma1 * z_jk + a_j
sigma_jk = exp(eta_sigma_jk)
count_jk ~ NB2(mu_jk, size = 1 / sigma_jk^2)
```

For q=1 phylogenetic count routes, the structured effect remains a single
species-level random intercept in the log-`mu` predictor. NB2 q1 keeps
`sigma ~ z` fixed-effect overdispersion and remains at `hold_smoke_only` until
all 500-replicate formal shards are run, merged, and audited together.

## Files Changed

- `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `ROADMAP.md`
- `NEWS.md`

## Checks Run

```sh
air format NEWS.md ROADMAP.md docs/design/41-phase-18-simulation-programme.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md
Rscript -e "devtools::test(filter = '^phase18-(count-mu-random-effect-(grid-writer|pilot)|poisson-mu-random-effect|nbinom2-mu-random-effect|nbinom2-sigma-random-effect|poisson-phylo-q1|nbinom2-phylo-q1|first-wave-summary-smoke-runner|actions-runner)$', reporter = 'summary')"
gh issue list --repo itchyshin/drmTMB --state open --search "Phase 18 count NB2 Poisson phylo sigma COM-Poisson" --limit 20
Rscript -e "files <- c('docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md'); invisible(lapply(files, readLines)); cat('doc read ok\n')"
rg -n 'COM-Poisson.*(now fits|implemented|fitted|artifact lane)|Conway-Maxwell.*(now fits|implemented|fitted|artifact lane)|Slice C.*(adds|implements).*syntax|NB2 q1.*promote|promote_narrowly|500-replicate.*(passed|complete|completed|audited)|Tweedie.*now fits|skew_normal.*now fits|zero-one.*now fits|zoi.*now fits|coi.*now fits' README.md ROADMAP.md NEWS.md docs/design inst/sim tests/testthat -g '!*.html'
git diff --check
```

- Formatting completed without output.
- Focused tests completed with the final `DONE` banner and no failures.
- The issue search returned no matching open issue rows.
- The doc read check printed `doc read ok`.
- The stale scan returned only intentional `hold_smoke_only`,
  500-replicate-audit, and promotion-helper lines; it found no false claim
  that COM-Poisson, Tweedie, zero-one beta, skew-normal, or new count syntax is
  now fitted.
- `git diff --check` was clean.

## Tests Of The Tests

The focused test filter exercised the existing count evidence paths directly:
paired Poisson/NB2 `mu` random-effect pilots and grid writers, NB2 log-`sigma`
random-effect artifacts, Poisson q1 phylo artifacts, NB2 q1 phylo artifacts,
the first-wave summary smoke runner, and the Actions runner shard parser. This
is enough for a closure note because Slice C did not change R code.

## Consistency Audit

Ada kept the lane to count closure and D-roadmap wording. Boole checked that no
new formula grammar was introduced. Noether checked that the NB2 log-`sigma`
equation and q1 phylo syntax match the existing simulation contracts. Fisher
kept the distinction between smoke/formal-admission evidence and formal
coverage claims. Grace checked the focused test and `git diff --check` results.
Rose scanned for stale or over-promoted wording. Pat checked that the new note
tells applied readers which count surfaces are supported and what remains
later.

No spawned subagents were running.

## GitHub Issue Maintenance

The open-issue search for Phase 18 count, NB2, Poisson, phylo, sigma, and
COM-Poisson wording returned no matching open rows in `itchyshin/drmTMB`. No
issue was opened because this lane records repository evidence and a next-slice
choice rather than a new bug or user-facing feature request.

## What Did Not Go Smoothly

Most of Slice C had already landed on `main` through prior count PRs. The main
risk was therefore not missing code; it was over-claiming closure as formal
recovery. The new note keeps NB2 q1 at `hold_smoke_only` and keeps
COM-Poisson/Conway-Maxwell-Poisson out of this lane.

## Team Learning

Count work needs two labels: fitted route and evidence status. A model can be
fitted and still be smoke/formal-admission only until the formal artifact set
is complete enough to support recovery or coverage claims.

## Known Limitations

Slice C does not run the NB2 q1 500-replicate formal shards. It does not add
COM-Poisson, generalized Poisson, Tweedie, zero-one beta, skew-normal, ordinal
random effects, non-Gaussian structured slopes, or new count random-effect
syntax. It also does not add the heavier q1 phylogenetic lanes to the reusable
first-wave summary runner.

## Next Actions

Pick exactly one Slice D lane:

- D1: dispatch and audit the NB2 q1 500-replicate formal shards.
- D2: decide whether Student-t formal grids are enough before implementing
  skew-normal.
- D3: write the zero-one bounded-response design gate.
- D4: write the Tweedie fixed-effect design gate.
- D5: open a later count-family design gate for Conway-Maxwell-Poisson or
  generalized Poisson, with fixed-effect recovery before any random effects.
