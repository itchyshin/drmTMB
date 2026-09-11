# Plan versus actual — phylogenetic-stable plus independent OU recovery diagnosis

## Planned

G9 would retain 24 deterministic balanced/unbalanced fixtures, 48 starts and all failures, then meet predeclared finite-fit and error thresholds.

## Actual

The corrected 50-species run retained 24 finite selected fits and 48 attempts. It passed median absolute log-SD error 0.153 and log-decay error 0.276, but failed mean fixed-effect error 0.182 against 0.150. A separate 80-species diagnostic with unchanged seeds/thresholds likewise retained 24/48 and passed variance/decay criteria but failed fixed-effect error 0.165. The intercept was the largest error component.

## Evidence

- `docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-local-recovery-v4/`
- `docs/dev-log/simulation-artifacts/2026-09-09-phylo-temporal-ou-local-recovery-v6-high-information/`
- earlier v1/v2/v3/v5 directories preserve runner and design diagnostics.

## Variance

G9 remains unchecked. No seeds, thresholds or failures were suppressed. Continuing to G10–G13 would require a documented revised recovery decision; no campaign was launched.
