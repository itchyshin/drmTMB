# After Task: Zero-One Bounded-Response Design Gate, Slice D3

## Goal

Pick the next low-compute Slice D lane after the NB2 q1 shard audit by writing
the zero-one bounded-response design gate. The task should separate strict
`beta()`, denominator-aware `beta_binomial()`, and future exact-boundary
continuous-proportion models without opening a new likelihood, formula grammar,
or random-effect surface.

## Implemented

Slice D3 adds
`docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md`.
The implemented claim is a design claim only: fixed-effect zero-one beta is the
next bounded-response likelihood candidate, but runnable `zoi`/`coi` formulas,
zero-one random effects, bounded-response random slopes, structured
bounded-response effects, and mixed bounded-response models remain planned or
blocked.

The slice also corrected one stale public ledger row:
`vignettes/implementation-map.Rmd` now lists beta-binomial ordinary `mu` random
intercepts as fitted source-level first slices rather than `none`.

## Mathematical Contract

Strict continuous proportions stay on:

```r
drmTMB(
  bf(prop ~ x, sigma ~ z),
  family = beta(),
  data = dat
)
```

with `0 < prop_i < 1`, `logit(mu_i) = eta_mu_i`,
`log(sigma_i) = eta_sigma_i`, `phi_i = 1 / sigma_i^2`, and:

```text
prop_i ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

Counted successes out of known trials stay on:

```r
drmTMB(
  bf(cbind(success, failure) ~ x, sigma ~ z),
  family = beta_binomial(),
  data = dat
)
```

Future fixed-effect zero-one beta should model exact boundary mass separately:

```text
zoi_i = Pr(prop_i is exactly 0 or 1)
coi_i = Pr(prop_i = 1 | prop_i is exactly 0 or 1)
Pr(prop_i = 0) = zoi_i * (1 - coi_i)
Pr(prop_i = 1) = zoi_i * coi_i
Pr(0 < prop_i < 1) = 1 - zoi_i
prop_i | 0 < prop_i < 1 ~ Beta(mu_i * phi_i, (1 - mu_i) * phi_i)
```

The first code slice should be fixed-effect only for `mu`, `sigma`, `zoi`, and
`coi` coefficients. It should update formula grammar and likelihood docs in the
same PR that makes the family runnable.

## Files Changed

- `NEWS.md`
- `ROADMAP.md`
- `docs/design/02-family-registry.md`
- `docs/design/34-validation-debt-register.md`
- `docs/design/41-phase-18-simulation-programme.md`
- `docs/design/46-pre-simulation-readiness-matrix.md`
- `docs/design/79-supported-nongaussian-evidence-goal.md`
- `docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md`
- `docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md`
- `docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md`
- `docs/dev-log/check-log.md`
- `docs/dev-log/after-task/2026-05-26-zero-one-bounded-response-design-gate-slice-d3.md`
- `docs/dev-log/team-improvements.md`
- `vignettes/implementation-map.Rmd`

## Checks Run

```sh
gh issue list --repo itchyshin/drmTMB --state open --search "zero-one beta zoi coi bounded response" --limit 20
air format NEWS.md ROADMAP.md docs/design/02-family-registry.md docs/design/34-validation-debt-register.md docs/design/41-phase-18-simulation-programme.md docs/design/46-pre-simulation-readiness-matrix.md docs/design/79-supported-nongaussian-evidence-goal.md docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md docs/dev-log/check-log.md docs/dev-log/team-improvements.md docs/dev-log/after-task/2026-05-26-zero-one-bounded-response-design-gate-slice-d3.md vignettes/implementation-map.Rmd
Rscript --vanilla -e "files <- c('NEWS.md','ROADMAP.md','docs/design/02-family-registry.md','docs/design/34-validation-debt-register.md','docs/design/41-phase-18-simulation-programme.md','docs/design/46-pre-simulation-readiness-matrix.md','docs/design/79-supported-nongaussian-evidence-goal.md','docs/design/109-phase-18-core-family-completion-map-slices-1279-1288.md','docs/design/113-phase-18-count-first-wave-closure-slices-1319-1328.md','docs/design/114-phase-18-zero-one-bounded-response-design-gate-slice-d3.md','docs/dev-log/check-log.md','docs/dev-log/team-improvements.md','docs/dev-log/after-task/2026-05-26-zero-one-bounded-response-design-gate-slice-d3.md','vignettes/implementation-map.Rmd'); invisible(lapply(files, readLines)); cat('doc read ok\n')"
rg -n 'zero-one beta.*(now fits|now supports|now implemented)|zero-one.*(likelihood now|syntax now|TMB now)|zoi.*(now fits|now supports|now implemented|is fitted)|coi.*(now fits|now supports|now implemented|is fitted)|Slice D3.*(adds|implements).*(likelihood|syntax|TMB)|Tweedie.*now fits|skew_normal.*now fits|COM-Poisson.*now fits|Conway-Maxwell.*now fits|generalized Poisson.*now fits|NB2 q1.*until.*500|500-replicate.*shards.*not.*audited|until all 500-replicate shards' NEWS.md ROADMAP.md README.md docs/design vignettes -g '!*.html'
Rscript -e "pkgdown::check_pkgdown()"
git diff --check
```

Results:

- The issue search returned no matching open rows.
- `air format` completed without output.
- The doc read check printed `doc read ok`.
- The stale-claim scan returned no matches.
- `pkgdown::check_pkgdown()` reported no problems.
- `git diff --check` was clean.

## Tests Of The Tests

No R code, likelihood, formula parser, or simulation runner changed. The
relevant test for this slice is consistency: the stale scan would have failed
the task if the new prose said zero-one beta, `zoi`, `coi`, Tweedie,
skew-normal, COM-Poisson, generalized Poisson, or NB2 q1 promotion was now
fitted.

## Consistency Audit

Ada kept the lane to one design gate. Boole checked that no runnable formula
grammar was opened. Gauss and Noether checked that the future zero-one beta
probability decomposition is explicit and does not change current TMB
parameterization. Darwin and Pat checked that strict continuous proportions,
counted successes, and exact-boundary continuous proportions are separated for
applied readers. Fisher kept the first future implementation fixed-effect only.
Grace checked pkgdown and formatting. Rose caught the stale beta-binomial row in
the implementation map and added a team-improvement note. No spawned subagents
were running.

## GitHub Issue Maintenance

The open-issue search for zero-one beta, `zoi`, `coi`, and bounded-response
wording returned no rows. No issue was opened because this PR records the
repository design gate and next implementation contract rather than a user bug.

## What Did Not Go Smoothly

The bounded-response gate exposed one status-sync mismatch: the public
implementation map still said beta-binomial had no random effects. That stale
row was corrected in this slice.

## Team Learning

When a first-slice non-Gaussian random-effect route lands, Rose should scan both
the design ledgers and the public implementation-map table before a neighbouring
family design gate starts. The process note is recorded in
`docs/dev-log/team-improvements.md`.

## Known Limitations

Slice D3 does not implement zero-one beta, ordered beta, `zoi`/`coi` formulas,
zero-one random effects, bounded-response random slopes, bounded-response
`sigma` random effects, structured bounded-response effects, or bounded-response
known-covariance models. It also does not choose Tweedie, skew-normal,
COM-Poisson, or generalized Poisson as the next fitted family.

## Next Actions

If the project chooses this lane for code, implement only the fixed-effect
zero-one beta likelihood first. The PR should choose the family constructor
name, update formula grammar and likelihood docs, add simulation tests for
`mu`, `sigma`, `zoi`, and `coi`, document response-scale prediction semantics,
and keep random effects out.
