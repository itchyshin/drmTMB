# After Task: meta_V B3 contract hardening

## 1. Goal

Make the frozen Gaussian known-V B3 campaign compute-ready without starting a
smoke or formal campaign.

## 2. Implemented

The internal B3 contract now freezes the 14-cell registry, 1,200 replicates
per cell, formal seed map, source SHA-256 hashes, interval call, amendment
rule, and 96 deterministic shards of 175 attempts. A seed-4 K=12 boundary
smoke and a separate K=36 dense interior smoke are executable only through the
post-approval runner and are outside the formal denominator. The shard entry
point authenticates installed sources, writes a host/runtime receipt, runs one
sequential shard, and leaves aggregation to the retained-result reducer. The
smoke and campaign are deliberately distinct approvals: a Totoro-labelled
smoke authenticates the timing input, then a later campaign receipt chooses and
binds every shard to either Totoro or DRAC. The writer retains the hash-checked
smoke approval receipt beside the smoke artifact so that the evidence is
portable between those hosts.
The contract fingerprint uses explicit uncompressed RDS version 2 serialization
so the local R 4.6 authoring runtime and R 4.5 compute hosts authenticate the
same frozen object.

## 3. Mathematical Contract

The estimator remains Gaussian ML with `sigma ~ 1` and known `V`. Public
`confint(..., parm = "sigma", method = "wald")` endpoints are retained. A
`[0, Inf]` boundary interval is `degenerate_zero_infinite`, counts as no finite
usable interval in all-attempt accounting, and is not conditional coverage.

## 3a. Decisions and Rejected Alternatives

The generic Phase 18 runner was not widened beyond its established 10-worker
in-process cap. B3 instead uses explicitly enumerated one-worker shards, which
prevents nested parallelism and leaves the choice of Totoro versus DRAC behind
the approved timing smoke.

## 4. Files Touched

- `inst/sim/run/sim_meta_v_b3_contract.R`
- `tools/run-meta-v-b3-shard.R`
- `tests/testthat/test-phase18-meta-v-grid-writer.R`
- B3 decision packet and `docs/dev-log/check-log.md`

## 5. Checks Run

```sh
NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::test(filter = "phase18-meta-v-(dgp|grid-writer)|comparators", reporter = "summary")'
R_PROFILE_USER=/dev/null Rscript --no-init-file tools/run-meta-v-b3-shard.R
git diff --check
```

Focused tests passed: comparator tests, meta_V DGP tests, and B3 grid/contract
tests. The shard script correctly stopped at its required-arguments boundary.
Two prescribed full-suite attempts with `testthat::test_local(...,
reporter = "silent")` ended without a result table or diagnostic output in this
environment; no full-suite zero-failure claim is made.

## 6. Tests of the Tests

Tests reject a non-1,200 formal grid, missing scheduled attempts, wrong
parameter membership, inconsistent manifest failure counts, and loss of the
seed-4 degenerate-interval sentinel.

## 7a. Issue Ledger

Issue #59 is the relevant Phase 18 umbrella. No comment was posted because
this task produces no compute evidence or public state change.

## 8. Consistency Audit

`rg -n "meta_gaussian|tau ~|rho ~|meta_known_V\\([^V]" README.md ROADMAP.md
NEWS.md docs vignettes R tests` found only existing intended compatibility or
guardrail language. The B3 packet continues to state NO-GO and contains no
coverage, tier, CRAN, or public-support claim.

## 9. What Did Not Go Smoothly

Initial review found that a structural completion check and a registry-only
sentinel were insufficient. The repair binds completion to retained status and
interval fields, authenticates the installed source at launch, and adds the
actual smoke/reducer paths.

## 10. Known Residuals

No Totoro/DRAC smoke, timing measurement, campaign, capability promotion,
coverage certification, or CRAN action has occurred. Formal compute remains
blocked on the cleared Fisher/Rose review record and Shinichi's explicit
smoke-only approval.

## 11. Team Learning

For a boundary-sensitive campaign, a deterministic seed map alone is not a
reproducer. The known seed must be an explicit smoke sentinel, and the source
that executes it must be authenticated against the frozen contract.

## 12. Cross-Product Coverage

This is an internal simulation harness change. It does not alter the public R
API, formula grammar, likelihood, Rd files, pkgdown reader surface, Julia
bridge, or CRAN state. It does NOT cover REML, penalties, any alternative
engine, missing-data routes, `sigma ~ x`, profile/bootstrap intervals,
non-Gaussian meta-analysis, coverage certification, capability promotion, or
the resulting Totoro/DRAC compute evidence.

## Next Actions

Run the approved two-attempt smoke only after the reviews and explicit compute
approval. Inspect its retained artifacts before using its measured shard timing
to choose Totoro or the whole-campaign DRAC fallback.
