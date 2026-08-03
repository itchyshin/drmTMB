# Codex handover: spatial q2 Confidence Eye

## Goal and state

The fixed-kappa bivariate-Gaussian coordinate-spatial q2 Confidence Eye arc is
evidence-complete on branch `codex/spatial-q2-confidence-eye`. PR #893 is merged
and supplied the point-recovery prerequisite. The new prospective Fir campaign,
reader article, ledger promotion, and all required statistical/visual reviews
are complete. Only the final PR, CI, and merge ceremony remains at this
checkpoint.

## Earned result

- 1,500/1,500 datasets completed; 4,500/4,500 target outcomes retained.
- M = 36 sites x 3 observations: joint PASS and lowest tested passing rung.
- H = 36 x 8: joint PASS.
- L = 12 x 3: joint FAIL.
- Promoted cells: `mc-0199` and `mc-0672` to
  `inference_ready_with_caveats` at exact M/H baseline-ring configurations.
- Protected remainder: `mc-0673` unchanged and rejected.

## Exact target set

- `sd:mu:mu1:spatial(1 | p | site)`
- `sd:mu:mu2:spatial(1 | p | site)`
- `cor:spatial:cor(mu1:(Intercept),mu2:(Intercept) | p | site)`

The intervals are 95% endpoint profiles. Every attempt remains in the
denominator. Wald is diagnostic only and bootstrap cannot rescue a failed
profile target.

## Review receipts

- Noether/Fisher pre-compute: APPROVE/APPROVE.
- Grace: APPROVE_SMOKE and APPROVE_FULL.
- Same D43 panel after remediation: Noether/Fisher/Rose 3/3 PROMOTE.
- Final image-fed Florence and Puff reviews on the repaired spatial and
  association PNGs: APPROVE/APPROVE.

## Evidence anchors

- Immutable source: `9e6804deb48436b328a41cf6dffe1eb007a3cb88`
- Full packet digest: `ace841f7054abcfff6c6ae3be935b6c6bc62b82830bbe314d579093b1cb3281a`
- Source archive SHA-256: `be72034c0ef3e50ba0483388ecea3c61a7d0eeb52de46e1c03f223510b7accab`
- Fir jobs: setup `52570123`, array `52570124`, corrected closeout `52574025`
- Tracked evidence: `docs/dev-log/simulation-artifacts/2026-08-03-spatial-q2-confidence-eye/`
- Figure audit: `docs/dev-log/figure-audits/2026-08-03-spatial-q2-confidence-eye/`

## Validation state

- Focused Confidence Eye contract: 35 expectations, PASS.
- Capability-ledger regression suite: 51 tests, PASS.
- Live-source `spatial-models` article render: PASS.
- Live-source `bivariate-nongaussian` association article render after removing
  the repeated horizontal CI line: PASS.
- Live-source `formula-grammar` article and pkgdown home rebuild: PASS.

## Protected boundary

Do not claim mesh intervals, estimated range, spatial slopes, q4+,
non-Gaussian spatial models, spatial sigma models, derived observed
correlations, other geometries/information configurations, or `supported`.
Do not promote L. Do not reinterpret the Confidence Eye as validation beyond
the exact M/H ring configurations.

## Resume command

```sh
cd /private/tmp/drmtmb-spatial-q2-ci
git status --short --branch
```

Then open the evidence-complete PR, require green CI and mergeability, comment
the result on issue #682 without closing it, merge, and verify post-merge
`origin/main`.
