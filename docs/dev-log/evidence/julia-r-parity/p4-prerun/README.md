# A10 — P4 warm-workflow PRE-RUN on Totoro (2026-09-05)

**Reader:** the owner deciding whether the full P4 timing grid (12 routes × 2 engines
× ≥5 reps) may run. **Purpose:** the D-139 pre-run test designed in
`docs/dev-log/plan/2026-09-01-parity-programme-estimate.md` §"G5 pre-run test design".
**THE FULL GRID WAS NOT RUN** — it is the one owner gate and needs an explicit go.

## What was run

1 fixture cell — DRM.jl `test/parity/q4-reml/biv-q4-phylo-reml` (committed `data.csv` +
`tree.newick`, n = 128, 16 tips; `biv_gaussian`, REML) — × 2 **native** engines × (1 warm-up,
discarded + 3 timed reps), each engine in one process (warm workflow), single core, on
Totoro over the existing ControlMaster socket. The bridge (JuliaCall) is never used on
Totoro (it segfaults there, measured earlier).

| engine | call | script |
|---|---|---|
| drmTMB 0.7.0, `engine = "tmb"` | the fixture's own `r_call` from `expected.meta.toml`: `drmTMB(bf(mu1 = y1 ~ x + phylo(1 \| p \| species, tree = tree), mu2 = ..., sigma1 = ~ 1 + phylo(...), sigma2 = ~ 1 + phylo(...), rho12 = ~ 1), biv_gaussian(), dat, REML = TRUE, engine = "tmb", control = drm_control(optimizer_preset = "robust"))` | `prerun_r.R` |
| DRM.jl 430ef64cc, native `drm()` | the fixture test's own call (`test/test_parity_biv_q4_phylo_reml.jl:86`): `drm(form, Gaussian(); data = dat, tree = tree, method = :REML, q4_vcov = false)` | `prerun_jl.jl` |

Environment (measured on the host; `reps/r-env.json`, `reps/jl-env.json`): Totoro,
x86_64 Linux, R 4.5.3, TMB 1.9.21, drmTMB 0.7.0 built from the `v0.7.0` tag
(RemoteSha `d7eb81fe7f42…`, built 2026-09-05 02:34 UTC into `~/parity_joint/Rlib`),
Julia **1.12.6** (`~/.juliaup/bin/julia`), DRM.jl at `430ef64ccca5642c5abebd72194e00895314dfc2`
(`~/parity_joint/DRM.jl`, clean checkout, `Pkg.instantiate()` done — `logs/instantiate.log`).
Pins: `OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1`, `julia -t 1`,
`BLAS.set_num_threads(1)`; `/usr/bin/time -v` reported 100 % (R) and 99 % (Julia) CPU.

## Result (this run, 2026-09-05T11:26:28Z, `logs/`)

**G2 same optimum.** Both engines converged on every rep. logLik drmTMB
`-219.613986302588` vs DRM.jl `-219.614005474459` — gap `1.9172e-05` (≤ 1e-4); every
rep of each engine reproduced its logLik exactly. max |Δcoef| = `1.6948e-04`
(`sigma2_(Intercept)`), inside the fixture's declared `atol_coef = 0.00251`. This is the
same gap the fixture's own `reml_restriction_note` records (1.9e-5, 1.68e-4).

**G3 timings** (seconds; `reps/*-rep{0..3}.json`; rep 0 is the warm-up and is excluded):

| engine | warm-up wall (discarded) | timed wall | timed CPU | median wall |
|---|---|---|---|---|
| drmTMB native TMB | 0.220 | 0.181, 0.179, 0.179 | 0.180, 0.180, 0.180 | **0.179** |
| DRM.jl native | 35.227 (JIT of the whole route) | 0.386, 0.385, 0.383 | 0.386, 0.384, 0.383 | **0.385** |

Median ratio DRM.jl / drmTMB = **2.149 (wall), 2.135 (CPU)** — on Julia 1.12.6, with the
caveats below.

**G4 budget.** Whole leaf on Totoro: 48 s wall (R process 1.82 s, Julia process 45.48 s
including package load + JIT; max RSS 269 MB / 1020 MB). Zero processes left behind
(`pgrep -u snakagaw -af parity_joint` matched only the checking shell; the two `julia`
processes on the host belong to the other lane's `~/s7b_work` `Pkg.test()`, untouched).

## Caveats (also in `prerun-receipt.json`)

- **Julia 1.12.6**, not 1.10 — DRM.jl #629 notes timing differences between the two.
- drmTMB's fit includes its default `TMB::sdreport()`; DRM.jl ran with `q4_vcov = false`
  (the fixture test's and the bridge's default on this route; its Wald vcov is fenced,
  #495). The R number therefore includes an uncertainty step the Julia number omits.
- One tiny cell; says nothing about scaling.
- Thread pins by environment variable, not CPU affinity.

## Verdict for the owner

The pre-run proves what G5 asked for: non-empty timed output, warm-up discarded, per-rep
receipts retained, matched optima, and a sane ratio (~2×, not an optimum-mismatch
artefact). The grid's cost can now be estimated from this: ~0.2–0.4 s per rep on this
cell, dominated by the ~35 s Julia JIT per fresh process — so the grid should keep one
process per engine per route. **The full grid still needs your explicit go (D-139).**

## Files

- `prerun_r.R`, `prerun_jl.jl` — the two scripts exactly as run on Totoro (`~/parity_joint/`).
- `reps/` — per-rep JSON (rep 0 = warm-up) and the two environment records.
- `logs/` — stdout of both runs, `/usr/bin/time -v` records, epoch stamps, plus the
  install (`install-R.filtered.log`) and `Pkg.instantiate()` logs from the setup step.
- `make_receipt.py` — builds `prerun-receipt.json` from `reps/` and refuses (exit 1, no
  receipt) if any rep did not converge or the logLik gap exceeds 1e-4.
- `prerun-receipt.json` — the receipt.

Regenerate: `python3 make_receipt.py` (from this directory).
