# After Task: log(sigma) control documentation truth refresh

## Goal

Remove stale wording in the controls/convergence design note after the
`log(sigma)` clamp knob and first fixed-effect sensitivity pilot landed. The
reader is a future contributor checking whether the guard is still a hidden
constant or a documented control.

## Changed

- `docs/design/174-controls-and-convergence.md` no longer calls the
  `log(sigma)` clamp band planned.
- The control catalog now names
  `drm_control(logsigma_clamp = ..., logsigma_clamp_margin = ...)`, the default
  `c(-12, 12)` identity band with margin 3, and `logsigma_clamp = NULL` as the
  disable route.
- The same row now points to the first fixed-effect guard-sensitivity pilot:
  negligible impact when inactive in audited cells, material impact when the
  default band binds, and active-at-optimum diagnostics still future work.
- Cross-references now include
  `docs/design/176-numerical-guard-simulation-audit.md`.

## Checks Run

```sh
git diff --check
rg -n 'planned.*logsigma|logsigma.*planned|planned.*log\(sigma\)|planned knob|expose the band as a control' docs/design/174-controls-and-convergence.md
# forbidden-framing scan over touched prose: no hits
rg -n '^(<<<<<<<|=======|>>>>>>>)' docs/design/174-controls-and-convergence.md docs/dev-log/after-task/2026-06-17-logsigma-control-doc-truth-refresh.md docs/dev-log/check-log.md
```

## Boundary

Docs only. No package code, no `src/drmTMB.cpp`, no `R/control.R`, no Gaussian
clamp implementation change, no Ayumi path change, no DRM.jl code change, no
new guard-sensitivity simulation, and no release-promotion claim.
