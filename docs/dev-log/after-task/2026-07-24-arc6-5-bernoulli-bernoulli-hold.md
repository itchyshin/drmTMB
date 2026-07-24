# After Task: Arc 6.5 Bernoulli x Bernoulli HOLD landing

This report closes the documentation for an owner-authorized source landing. It
does not change the recovery verdict: the route remains a HOLD with no
point-recovery, interval, coverage, capability, or release claim.

## 1. Goal

Record an auditable closeout for the frozen-margin Bernoulli x Bernoulli
latent-normal association route while preserving the predeclared all-attempt
recovery HOLD.

## 2. Implemented

Commits `bc2c1c29` and `51647467` added the fixed-effect, complete-pair,
intercept-only `eta` route, a tail-stable conditional-normal rectangle
evaluator, its independent `mvtnorm::pmvnorm()` oracle tests, and an
all-attempt recovery runner. This closeout adds an artifact receipt at
`docs/dev-log/simulation-artifacts/2026-07-24-arc6-5-bernoulli-recovery/` and
aligns the limitation wording with the retained HOLD evidence.

## 3a. Decisions and Rejected Alternatives

The owner authorized landing the source as development work while retaining the
HOLD. The all-attempt denominator is unchanged: no failed attempt was removed,
no bias threshold was relaxed, and the `n = 120`, asymmetric-prevalence,
`eta = 0.5` cell was not reclassified. Merging this source does not promote a
capability ledger row or make a public recovery claim.

Rejected alternatives were to rescore only finite estimates, omit the
small-sample cell, treat the rare rows as evidence of a broader failure, or
turn the source-only route into interval inference. The first three would alter
the declared recovery estimand after observing the result; the last is invalid
because the stage-2 Hessian conditions on fitted margins.

## 4. Files Touched

- `docs/dev-log/after-task/2026-07-24-arc6-5-bernoulli-bernoulli-hold.md`
- `docs/dev-log/known-limitations.md`
- `docs/dev-log/simulation-artifacts/2026-07-24-arc6-5-bernoulli-recovery/README.md`

No R source, test, recovery runner, capability ledger, or check-log entry was
changed in this documentary closeout.

## 5. Checks Run

The Totoro result directory was read through the existing ControlMaster at
`/home/snakagaw/hsq_work/arc65-runs/2026-07-24-51647467-r10/`. Its
`git-sha.txt` is `51647467196f9f212dea0bcb323fe649462f570d`. SHA-256 values
and the reconstructed counts are recorded in the artifact receipt.

`raw-attempts.csv` contains 220 rows: 180 interior and 40 predeclared HOLD
rows. Its 18-cell interior summary has 17 passing cells and one failure. The
failed cell is `n = 120`, asymmetric prevalence, `eta = 0.5`, replicate 1,
seed 650016; it is `boundary_unresolved`, so the cell returned 9/10 finite
estimates. This confirms the written HOLD without rerunning the campaign.

The source-validation record is the existing Arc 6.5 check-log entry and
source tests: frozen margins, response-order symmetry, product and
normalization limits, an independent `mvtnorm` oracle, rare-tail finiteness,
simulation, and unsupported-method fences. Those tests were not rerun during
this documentation-only closeout.

The after-task structure validator was run from the shared brain tool:

```sh
R_PROFILE_USER=/dev/null Rscript --no-init-file -e \
  "source('/Users/z3437171/Dropbox/Github Local/Shinichi/tools/check-after-task.R'); \
  main_check_after_task('docs/dev-log/after-task/2026-07-24-arc6-5-bernoulli-bernoulli-hold.md')"
```

It passed. The checkout does not contain `tools/check-after-task.R`; the shared
validator is the project-prescribed source used by prior check-log entries.

## 6. Tests of the Tests

The new route's tests are not only fit-success probes: the rectangle evaluator
is compared state-by-state with `mvtnorm::pmvnorm()`, verifies the `eta = 0`
product identity and four-state normalization, exercises rare tails, swaps the
two margins, and asserts fences for `rho12()`, `vcov()`, `confint()`, new-data
prediction, and same-response inputs. The recovery runner retains failed
stage-1/stage-2 attempts before computing returned counts and bias. The Totoro
receipt independently confirms that the unresolved interior attempt remained in
the denominator.

## 7a. Issue Ledger

A read-only GitHub search for open issues containing `Bernoulli` found only
#496, Gaussian variational approximation, which is unrelated. No duplicate
issue was opened or changed. PR #821 is the tracked source landing; its HOLD
record, not an issue closure, is the appropriate state for this narrow route.

## 8. Consistency Audit

The source and documentation use `eta` for the frozen-margin latent-normal
association and keep it distinct from residual `rho12`, observed-scale
correlation, odds ratios, and random-effect correlation. The contract,
`NEWS.md`, cross-family vignette, and known-limitations entry all retain the
fixed-effect, complete-pair, intercept-only and no-inference boundary.

The status inventory was scanned with:

```sh
rg -n -i 'associate_pairs|latent_normal|bernoulli.?bernoulli|cross.family|frozen.margin|corpair|eta' \
  README.md ROADMAP.md NEWS.md docs/dev-log/known-limitations.md \
  docs/design/01-formula-grammar.md vignettes/formula-grammar.Rmd _pkgdown.yml
rg -n -i 'Arc 6.5|bernoulli.?bernoulli|HOLD|recovery.*(pass|passed)|capability.*(claim|promot)' \
  README.md ROADMAP.md NEWS.md docs vignettes
```

The first scan finds the development boundary in `NEWS.md`,
`known-limitations.md`, `vignettes/cross-family.Rmd`, and the deferred
cross-family pkgdown navigation; it finds no misleading Arc 6.5 status claim
in the README, roadmap, or formula grammar. The second scan found the old
limitation phrase "recovery evidence ... outside this first contract" despite a
retained HOLD campaign. It is now replaced with wording that distinguishes
existing HOLD evidence from a passing recovery claim.

## 9. What Did Not Go Smoothly

The first short report named the remote run directory but did not make its raw
ledger, frozen source, hashes, or failed seed independently inspectable. The
initial source checkout also lacks the named after-task validator, so this
closeout used the canonical shared validator rather than claiming a local tool
was run. The campaign result itself remains a failure of the predeclared gate,
not a documentation failure that can be repaired away.

## 10. Known Residuals

The source route is intentionally narrow and its recovery result is HOLD. The
single interior `boundary_unresolved` attempt prevents a point-recovery claim.
Twenty-seven additional rare-HOLD attempts were also boundary-unresolved; they
remain retained diagnostic evidence, not an interior-gate failure. The raw
campaign artifacts remain on Totoro and are referenced by path plus SHA-256
receipt rather than copied into the repository. Any future recovery redesign
requires a new owner decision, frozen design, and all-attempt campaign.

## 11. Team Learning

A campaign receipt needs more than an aggregate sentence: retain the frozen
source SHA, file hashes, row counts, failed-cell identity, denominator rule,
and artifact location before asking reviewers to interpret a gate. A HOLD is a
useful result only when it is reproducible and cannot be silently converted to
a pass by filtering. The after-task validator should be run before the PR
review, not after a closure audit finds missing sections.

## 12. Cross-Product Coverage

This development route does NOT cover association slopes, random,
phylogenetic, structured, scale-side, missing, weighted, offset, `mi()`,
`meta_V()`, REML, Julia, new-data, residual, `rho12`, `corpair()`, profile,
standard-error, interval, bootstrap, coverage, capability-tier, CRAN, or
general mixed-family claims. It covers only two literal Bernoulli-logit ML
margins on the same complete rows and an intercept-only frozen-margin
latent-normal point estimate when the fit diagnostics permit one. The retained
HOLD evidence does not expand that surface.
