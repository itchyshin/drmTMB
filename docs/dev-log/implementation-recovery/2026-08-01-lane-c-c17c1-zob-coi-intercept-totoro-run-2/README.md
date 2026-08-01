# C17-C1 `coi` random-intercept recovery — Totoro run 2

## Verdict

`PASS_POINT_RECOVERY` for the exact complete-response ML-Laplace route

```r
bf(y ~ x, sigma ~ 1, zoi ~ 1, coi ~ 1 + (1 | id))
```

at the predeclared claim rung `M = 64`. All four frozen seeds passed the
diagnostic, support, recovery, and boundary-only `lme4::glmer()` comparator
gates. The `M = 16` and `M = 32` rungs remain diagnostic only.

## Authenticated source

- Source SHA: `19e5b045dfbaa1c5dea2453e255b717dda773c14`
- Runner SHA-256: `a4a8b1b8ba99fb1b6a94141d325bab1688cc3ed536f2024ff9d60a6a657d83ce`
- Host checkout: `/home/snakagaw/hsq_work/drmTMB-c17c1-19e5b045`
- Frozen seeds: `2026081701:2026081704`
- No support-conditioned resampling was used.

The exact source blobs, namespace path, command, timestamps, and pre-run dirty
state are recorded in `provenance.tsv` and `dirty-state.txt`.

## Claim-rung receipt

At `M = 64`, the four attempts had convergence zero and `pdHess = TRUE`.
Maximum gradient ranged from `0.000339` to `0.003951`; `tau_hat` ranged from
`0.4087` to `0.4802`; mode correlation ranged from `0.687` to `0.773`; and
every group had at least two zeroes, two ones, and twenty interior observations.
The mean relative `tau` error was `0.0715`. The maximum common-parameter
difference from the boundary-only `glmer()` comparator was `1.88e-05`, below
the frozen `1e-3` gate.

## Relationship to run 1

Run 1 is retained unchanged. Its single M=64 support failure came from the
runner constructing `id` with implicit lexicographic factor levels, which
reassigned the already-drawn random effects to groups. Run 2 declares the
intended `g1, ..., gM` factor levels explicitly and asserts their order. It
does not redraw, filter, or condition on observed support.

## Claim boundary

This receipt supports point-fit recovery only for the exact ordinary `coi`
random-intercept route above. It does not support a `coi` slope, simultaneous
atom random effects, structured or q2-plus effects, missing responses, REML,
AGHQ, profiles, intervals, coverage, inference readiness, or package-level
support.
