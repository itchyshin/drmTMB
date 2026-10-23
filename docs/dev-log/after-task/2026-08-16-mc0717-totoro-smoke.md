# After Task: mc-0717 Totoro 27-fit smoke

**Reader:** Shinichi and Fisher / Noether on the Wave 1 merge-path.  
**Lane:** `cursor/ng-correlated-slope-impl` (draft PR #1059; worktree `.worktrees/ng-corr-w1`).  
**GO:** Shinichi named this exact 27-fit Totoro smoke. Results stay local / dev-log.

## Goal

Run the predeclared `mc-0717` smoke on Totoro: nine complete-data binomial
draws, three methods each, recover `sd0`, `sd1`, and `rho_re` under
ML-Laplace, and keep the claim at `point_fit_recovery`.

## Verdict

**PASS.** Twenty-seven of twenty-seven fits stayed in the denominator.
Every fit converged (`opt$convergence == 0`) with `pdHess = TRUE` and
`exception_class = none`. All nine claim fits passed the absolute 0.30
gates on `sd0`, `sd1`, and `rho_re`. drmTMB and glmmTMB agreed to about
`1e-5` on the same draws. The five-neighbour rejection matrix stayed red.

This smoke does not promote `mc-0717`, does not open intervals, coverage,
REML, AGHQ, or `supported`, and does not authorize merge.

## Implemented

No package code changed. Totoro ran SHA `5d5048d8d` from
`cursor/ng-correlated-slope-impl`, installed into
`~/hsq_work/drmTMB-mc0717-library`. Methods on every draw:

1. claim `drmTMB(bf(cbind(success, failure) ~ x + (1 + x | id)), family = binomial())`
2. iid control `~ x + (1 | id) + (0 + x | id)` (`mc-0061` neighbour; no `rho_re`)
3. `glmmTMB` unstructured `(1 + x | id)` oracle

Seeds were the brief's unused set (`871401`–`871403`, `871801`–`871803`,
`871141`–`871143`). Laptop seed `20260811` stayed out of the denominator.

## Mathematical Contract

```text
logit(p_ij) = -0.25 + 0.70 x_ij + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
sd0 = 0.65, sd1 = 0.42, rho_re = 0.45
```

Group-level correlation is `rho_re`, never residual `rho12`. Extractors
matched Design 257 on every claim row:
`sdpars$mu["(1 + x | id):(Intercept)"]`,
`sdpars$mu["(1 + x | id):x"]`,
`corpars$mu["cor((Intercept),x | id)"]`.

## Files Changed

- `docs/dev-log/simulation-artifacts/2026-08-16-mc0717-totoro-smoke/` — TSV, logs, runner
- `docs/dev-log/after-task/2026-08-16-mc0717-totoro-smoke.md` — this note
- `docs/dev-log/research/2026-08-16-mc0717-totoro-smoke-brief.md` — launch status only
- `docs/dev-log/check-log.md` — this smoke

## Checks Run

| Gate | Result |
| --- | --- |
| 1-fit toy (seed `871000`, not in the 27) | PASS; finite Design 257 names |
| Rejection matrix (REML, missing-response, labelled, mixed, Poisson) | 5/5 stayed red |
| Denominator | 27/27 rows; 0 exceptions dropped |
| Claim convergence / finite extractors / `pdHess` | 9/9 / 9/9 / 9/9 TRUE |
| All-method convergence / `pdHess` | 27/27 / 27/27 |
| Absolute recovery 0.30 on claim `sd0` / `sd1` / `rho_re` | 9/9 / 9/9 / 9/9; max \|err\| 0.120 / 0.123 / 0.242 |
| Oracle max \|drmTMB − glmmTMB\| | 1.9e-5 / 1.0e-5 / 4.1e-5 |
| Wall / workers | 3 s for the 27 fits; 8 workers; cap 16; Totoro `nproc=384` |
| Process group | reaped; no leftover `mc0717` workers |
| Merge / DRAC / Ligges / #1033 | not touched |

## Tests Of The Tests

The 1-fit toy would have aborted on empty or NA extractors. The launcher
refuses a job list that is not exactly 27 rows and refuses a concatenated
table that is not 27 rows. A missing row file is written as
`exception_class = missing_row` rather than dropped.

## Consistency Audit

```sh
rg "interval|coverage|supported|REML = TRUE" docs/dev-log/after-task/2026-08-16-mc0717-totoro-smoke.md
rg "rho12" docs/dev-log/simulation-artifacts/2026-08-16-mc0717-totoro-smoke/results.tsv
```

The write-up names `point_fit_recovery` only. `rho12` does not appear in
the result table. Ledger, NEWS, and grammar were not edited.

## GitHub Issue Maintenance

Optional comment on draft PR #1059 with the smoke table. No merge request.
#1033 was not opened or commented.

## What Did Not Go Smoothly

`host-provenance.txt` recorded `nproc=1` even though a live `nproc` before
and after the run was 384 and the core guard would have refused eight
workers if `nproc` had been 1 at launch. The GNU parallel job log shows
eight concurrent starts. The file now carries that correction.

Wall time of 3 s is real (compiled TMB, n = 224–784). It is not a
certification cost estimate.

## Team Learning

A named 27-fit GO plus a 1-fit toy is enough to run this cell on Totoro
without a DRAC array. Keep the dedicated library
(`~/hsq_work/drmTMB-mc0717-library`) so a smoke does not overwrite another
lane's installed `drmTMB`.

## Known Limitations

`mc-0717` stays `point_fit_recovery`. Constant-within-group `x` is still
unidentified and still fits. The parser hint still says `experimental q = 2`.
Wave 2, REML, AGHQ, intervals, coverage, and `supported` remain closed.

## Next Actions

1. Keep draft PR #1059 unmerged.
2. Do not start a DRAC certification from this smoke.
3. Add the constant-within-group `x` rejection when someone next touches
   the prereq tests.
4. Stay off #1033, MSPL, and Ligges.
