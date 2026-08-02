# Lane C C2 — Poisson phylogenetic q2 covariance

## Goal

```text
PLATFORM: Codex
Deliver exactly ordinary Poisson phylo labelled-q2 covariance for
count ~ x + phylo(1 + x | p | species, tree = tree), then retain a local
technical point-recovery receipt. Defer all other C0 cells, public capability,
interval, coverage, bootstrap, remote compute, and Lane A/B work.
```

## Sweep receipt

- Repo: `git status -sb`, `git log --oneline -5`, and Lane C preflight found a
  clean C0-04 baseline at `781fbd6c3`; the no-Claude result is weak evidence.
- Sister repos: DRM.jl and gllvmTMB contain Poisson phylo slope implementations,
  useful only as design references, not drmTMB evidence.
- Brain: `search_notes("drmTMB Lane C count q2 C0-07 Poisson phylo next arc recovery", search_all_projects = TRUE)` found prior Poisson q1 work but no existing drmTMB Poisson q2 receipt.
- Verdict: build the C0-07 gap only. C0-08–10 require distinct provider fences.

## Locked contract and checks

The latent field is (N\{0, \Sigma(\tau_0,\tau_1,\rho)\otimes Q^{-1}\})
with (\rho=.999999\tanh(\eta_{cor})). The Poisson C++ branch receives the
determinant-normalised cross-precision penalty; zero correlation reduces to its
previous independent q-vector form. Acceptance/rejection, dense objective,
AD-gradient, extraction, retained three-seed local recovery, and IID-DGP
control are required before closeout.

## Fence

No C0-08 spatial, C0-09 animal, C0-10 relmat, zero inflation, ordinary RE
coexistence, missingness, scale-side work, profiles, intervals, bootstrap,
coverage, capability ledger/dashboard, remote compute, API/default, Lane A, or
Lane B change is authorized by this arc.
