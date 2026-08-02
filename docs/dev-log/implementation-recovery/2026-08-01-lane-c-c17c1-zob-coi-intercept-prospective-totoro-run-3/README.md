# C17-C1 prospective recovery run 3 — blocked

## Verdict

`BLOCKED_POINT_RECOVERY` under the prospectively committed contract at
`docs/dev-log/evidence/2026-08-01-c17c1-prospective-recovery-contract.md`.
Do not promote `mc-0570`, merge the carrier, or begin `mc-0578` from this
receipt.

## Authenticated source

- Source SHA: `3645c9412f25667b15d4f10369d2864494ee70d4`
- Runner SHA-256: `b711ffe13097de00152c54d7bb8dfc9c16bae37b262c3ace6d4a777e90664767`
- Host checkout: `/home/snakagaw/hsq_work/drmTMB-c17c1-prospective-3645c941`
- Prospective seeds: `2026081711:2026081714`
- Pre-run worktree: clean
- Generation: once per `(M, seed)`, without support-conditioned resampling

## Result

All four M=64 fits passed the estimator diagnostics: convergence zero,
`pdHess = TRUE`, maximum gradient at most `0.00509`, finite interior
`sd_coi_hat`, and mode correlation from `0.564` to `0.742`. All fixed-effect,
`log_sigma`, relative-`sd_coi`, and boundary-only `glmer()` comparator means
also passed their gates. Mean relative `sd_coi` error was `0.2373`; the maximum
comparator difference was `6.29e-06`.

The hard support gate passed only 2/4 attempts:

| Seed | Minimum zeroes | Minimum ones | Minimum interiors | Support |
|---:|---:|---:|---:|:---:|
| 2026081711 | 1 | 1 | 23 | fail |
| 2026081712 | 2 | 2 | 22 | pass |
| 2026081713 | 3 | 4 | 21 | pass |
| 2026081714 | 3 | 0 | 24 | fail |

The contract required at least two zeroes, two ones, and ten interiors in every
group for all four M=64 attempts. The support failures therefore remain
load-bearing even though the fitted estimator behaved well.

## Review disposition

Fisher returned GO for the narrow point-fit claim from the estimator evidence.
Noether and Rose returned BLOCK because run 2 changed the realized DGP after a
support failure and the prospective denominator had not yet passed. Run 3 now
provides the prospective result and fails its hard support gate, so the two
BLOCK verdicts remain decisive under the approved D-43 rule.

Historical run-1/run-2 fields named the latent SD `tau`; those receipts remain
unchanged, non-load-bearing history. This finalized runner and receipt use the
model-aligned name `sd_coi`.

## Scope

This is negative evidence about the approved recovery contract, not evidence
against mathematical fit viability. The implementation branch is retained as
a checkpoint. No claim follows for a `coi` slope, simultaneous atom random
effects, structured/q2-plus effects, missing responses, REML/AGHQ, profiles,
intervals, coverage, inference readiness, or package-level support.
