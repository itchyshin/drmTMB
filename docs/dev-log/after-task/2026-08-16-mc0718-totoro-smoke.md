# After Task: mc-0718 Totoro 27-fit smoke

**Reader:** Shinichi and Fisher / Noether on the Wave 2 merge-path.  
**Lane:** `cursor/ng-correlated-slope-wave2` (draft PR #1060; worktree `.worktrees/ng-corr-w2`).  
**GO:** Shinichi named this exact 27-fit Totoro smoke. Results stay local / dev-log.

## Goal

Run the predeclared `mc-0718` smoke on Totoro: nine complete-data Poisson
draws, three methods each, recover `sd0`, `sd1`, and `rho_re` under
ML-Laplace, and keep the claim at `point_fit_recovery`.

## Verdict

**PASS** for the smoke contract. Twenty-seven of twenty-seven fits stayed
in the denominator. Every fit converged (`opt$convergence == 0`) with
`pdHess = TRUE` and `exception_class = none`. drmTMB and glmmTMB agreed
to about `1e-5` on the same draws. The five-neighbour rejection matrix
stayed red. The 1-fit toy (seed `881000`, not in the 27) returned finite
design-17 names.

Absolute 0.30 recovery on the nine claim fits is **8/9**. The miss is
`n_each = 4`, seed `881402`, `rho_re = 0.894` against truth `0.45`
(`|err| = 0.444`). glmmTMB on that same draw also returned `0.894`.
This is a small-`n_each` finite-sample miss shared with the oracle, not
an extractor or implementation split. `sd0` and `sd1` passed 9/9
(max `|err|` 0.173 / 0.217). All six claim fits at `n_each ∈ {8, 14}`
passed all three gates.

This smoke does not promote `mc-0718`, does not open intervals, coverage,
REML, AGHQ, NB2, or `supported`, and does not authorize merge.

## Implemented

No package code changed. Totoro ran SHA `3e8a9aaec` from
`cursor/ng-correlated-slope-wave2` (live PR #1060 head after the Wave 1
restack; the first deploy refused stale pin `aef4c860`), installed into
`~/hsq_work/drmTMB-mc0718-library`. Methods on every draw:

1. claim `drmTMB(bf(count ~ x + (1 + x | id)), family = poisson(link = "log"))`
2. iid control `~ x + (1 | id) + (0 + x | id)` (`mc-0431` neighbour; no `rho_re`)
3. `glmmTMB` unstructured `(1 + x | id)` oracle

Seeds were the brief's unused set (`881401`–`881403`, `881801`–`881803`,
`881141`–`881143`). Laptop seed `20260816` and the mc-0717 `871xxx` set
stayed out of the denominator.

## Mathematical Contract

```text
y_ij | λ_ij ~ Poisson(λ_ij)
log(λ_ij) = -0.25 + 0.70 x_ij + b_0j + x_ij b_1j
(b_0j, b_1j)' ~ MVN(0, Σ_g)
sd0 = 0.65, sd1 = 0.42, rho_re = 0.45
ρ = 0.999999 tanh(η)
```

Group-level correlation is `rho_re`, never residual `rho12`. Extractors
matched the design-17 table on every claim row:
`sdpars$mu["(1 + x | id):(Intercept)"]`,
`sdpars$mu["(1 + x | id):x"]`,
`corpars$mu["cor((Intercept),x | id)"]`.
`obj$report()` does not carry `logsech_mu_re`.

## Files Changed

- `docs/dev-log/research/2026-08-16-mc0718-totoro-smoke-brief.md` — predeclared ADEMP
- `docs/dev-log/simulation-artifacts/2026-08-16-mc0718-totoro-smoke/` — TSV, logs, runner
- `docs/dev-log/after-task/2026-08-16-mc0718-totoro-smoke.md` — this note
- `docs/dev-log/check-log.md` — this smoke

## Checks Run

| Gate | Result |
| --- | --- |
| 1-fit toy (seed `881000`, not in the 27) | PASS; finite design-17 names; `conv=0`, `pdHess=TRUE` |
| Rejection matrix (REML, missing-response, labelled, mixed, NB2) | 5/5 stayed red |
| Denominator | 27/27 rows; 0 exceptions dropped |
| Claim convergence / finite extractors / `pdHess` | 9/9 / 9/9 / 9/9 TRUE |
| All-method convergence / `pdHess` | 27/27 / 27/27 |
| Absolute recovery 0.30 on claim `sd0` / `sd1` / `rho_re` | 9/9 / 9/9 / **8/9**; max \|err\| 0.173 / 0.217 / 0.444 |
| Oracle max \|drmTMB − glmmTMB\| | 5.0e-6 / 5.8e-6 / 1.5e-5 |
| Wall / workers | 3 s for the 27 fits; 8 workers; cap 16; Totoro live `nproc=384` |
| Process group | finished; no leftover `mc0718` workers |
| Merge / DRAC / Ligges / #1033 | not touched |

## Tests Of The Tests

The 1-fit toy would have aborted on empty or NA extractors. The launcher
refuses a job list that is not exactly 27 rows and refuses a concatenated
table that is not 27 rows. A missing row file is written as
`exception_class = missing_row` rather than dropped. The first deploy
refused SHA `aef4c860` when the live PR head had moved to `3e8a9aaec`;
the pin was updated and the smoke was not launched on the stale SHA.

## Consistency Audit

```sh
rg "interval|coverage|supported|REML = TRUE" docs/dev-log/after-task/2026-08-16-mc0718-totoro-smoke.md
rg "rho12" docs/dev-log/simulation-artifacts/2026-08-16-mc0718-totoro-smoke/results.tsv
```

The write-up names `point_fit_recovery` only. `rho12` does not appear in
the result table. Ledger, NEWS, and grammar were not edited.

## GitHub Issue Maintenance

Comment on draft PR #1060 with the smoke table. No merge request.
#1033, #1049, and #1059 were not opened or commented.

## What Did Not Go Smoothly

`host-provenance.txt` recorded `nproc=1` even though a live `nproc`
before and after the run was 384 and the core guard would have refused
eight workers if `nproc` had been 1 at launch. The GNU parallel job log
shows 27 jobs with exit 0. Same Wave 1 artefact; recorded here, not
silently rewritten in the provenance file.

The first clone landed `3e8a9aaec` and the deploy script refused it
against the brief's then-current pin `aef4c860`. PR #1060 had been
restacked onto the Wave 1 smoke/docs commits. The pin was updated to the
live head before install.

Wall time of 3 s is real (compiled TMB, n = 224–784). It is not a
certification cost estimate.

## Team Learning

A named 27-fit GO plus a 1-fit toy is enough to run this cell on Totoro
without a DRAC array. Keep the dedicated library
(`~/hsq_work/drmTMB-mc0718-library`) so a smoke does not overwrite the
mc-0717 install. Pin the live PR SHA at launch, not a SHA read hours
earlier.

## Known Limitations

`mc-0718` stays `point_fit_recovery`. One `n_each = 4` claim draw missed
the 0.30 `rho_re` gate in lockstep with glmmTMB. NB2, labelled, mixed,
REML, missing-response, Wave 3, intervals, coverage, and `supported`
remain closed.

## Next Actions

1. Keep draft PR #1060 unmerged.
2. Do not start a DRAC certification from this smoke.
3. Do not admit NB2 in this PR.
4. Stay off #1033, MSPL, and Ligges.
