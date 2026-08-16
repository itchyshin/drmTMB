# Pre-registration — MSPL S0 defect gates

**2026-08-16, written BEFORE any result existed. S0 of the MSPL boundary programme
(`docs/dev-log/research/2026-08-16-drmtmb-mspl-transfer-packet.md` §6): formalise, in-repo and on
the shipped penalty's exact algebra, the two defects Fisher's exploratory 400-replicate port
surfaced (F1 scale anchoring; the anchor-sensitivity that makes F2's grid confound possible).**

## Experiments

**A — scale equivariance (Gaussian port of the shipped penalty).** The A1 Gaussian
random-intercept model (`y ~ x + (1|g)`, g=10, n_per=10, truths beta=0.5, sigma=0.7, sd_mu=0.5).
Per replicate: simulate once; fit plain ML via `drmTMB()`; construct the penalized objective
externally from the fit's TMB object — `fn_pen(par) = fn(par) - c_n * D(par[log_sd_mu])` with the
SHIPPED forms (`D` = negative Huber, `src/drmTMB.cpp:77-85`; `c_n = 2*sqrt(p/n_eff)`,
`R/mspl.R:112-128`) — and optimise from the ML solution. Do this for `y` and for `100*y`;
back-scale the second by 1/100. **Statistic: the per-replicate discrepancy
|sd_hat_pen(y) − sd_hat_pen(100y)/100|**, plus the same for plain ML as the control (which must be
~0 to numerical precision — ML IS equivariant; if the control fails, the harness is wrong).
200 replicates, seeds 20260816 + r.

**B — anchor-sensitivity ladder on the SHIPPED route.** Binomial GLMM (`y ~ x + (1|g)`, logit),
g=10, n_per=20, true logit-scale `sd_u ∈ {0.25, 0.5, 1, 2, 4}`, beta=0.5. Paired per seed:
`estimator="ml"` vs `estimator="mspl"` (the actual shipped code path). **Statistic: per-cell mean
relative bias of sd_hat for each estimator, and the MSPL−ML bias difference.** 300 replicates per
cell (raise if the smoke shows it cheap), seeds 20260816 + 1000*cell + r.

## Predictions (committed now)

- **A:** ML control discrepancy ≈ 0 (< 1e-6). Penalized discrepancy **materially nonzero** (order
  0.1+ at this design, per Fisher's exploration) — the penalty is not scale-equivariant.
- **B:** MSPL improves bias at sd_u below ~1, does roughly nothing near 1, and **worsens** bias at
  sd_u = 2 and 4 (pull-toward-anchor). Monotone-ish crossover near the anchor.

## Falsifiers

- If A's penalized discrepancy is ≈ 0, F1 is WRONG as stated for the Gaussian port and the packet
  must be corrected.
- If B shows MSPL helping (or neutral) across the whole ladder including sd_u = 4, the
  anchor-defect framing is overstated and S1's scale-equivariance requirement loses its measured
  motivation (the theoretical argument would remain, flagged as unmeasured).
- Harness falsifier: A's ML control failing equivariance, or B's ML arm biases wildly inconsistent
  with the known ML small-g downward bias, invalidates the harness — no defect claim either way.

## What S0 is NOT

Not a coverage study, not a claim about any repaired penalty, not evidence for or against S2/S3 —
it documents the shipped form's defects so S1's requirements rest on committed, seeded, in-repo
measurement instead of an exploratory port. Compute: Totoro only, ≤50 cores, smoke-first.
