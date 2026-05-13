# After Task: Slice 4 Labelled Block Design Start

## Goal

Freeze the completed slice-3 same-response `mu`/`sigma` covariance patch, then
start slice 4 on a separate branch as a design-first labelled covariance block
assembler.

## Implemented

Slice 3 was committed as `533790c` with message
`Add same-response mean-scale covariance`. Slice 4 now has its own branch,
`codex/labelled-covariance-block-design`, and a new design contract in
`docs/design/30-labelled-covariance-block-assembler.md`.

No fitted model behaviour changed in this slice-4 start. The design note says
that existing two-term covariance paths are compatibility bridges, while any
shared label with three or more members should be represented as one
positive-definite block.

## Mathematical Contract

For each labelled group-level block `b` with `q_b` members and `G_b` groups,
the planned contract is:

```text
z_bj ~ Normal(0, I_q)
r_bj = diag(sd_b) L_corr_b z_bj
```

where `L_corr_b L_corr_b'` is a valid correlation matrix and `r_bj` contributes
to the relevant `mu`, `sigma`, `mu1`, `mu2`, `sigma1`, or `sigma2` linear
predictor. Residual `rho12` remains separate.

## Files Changed

- `docs/design/30-labelled-covariance-block-assembler.md`
- `ROADMAP.md`
- `docs/design/17-correlated-random-effect-blocks.md`
- `docs/design/20-coscale-correlation-pairs.md`
- `docs/design/28-double-hierarchical-endpoint.md`
- `docs/dev-log/check-log.md`

## Checks Run

- `git status --short --branch`, `git diff --stat`, and the slice-3
  after-task report were inspected before committing slice 3.
- `git diff --check`: passed before the slice-3 commit and after the slice-4
  design edits.
- Conflict-marker scan before the slice-3 commit found no conflict markers.
- Local TMB inspection found version `1.9.21` and confirmed
  `UNSTRUCTURED_CORR_t` and `VECSCALE_t` are available in the installed
  headers.
- Positive reference scan confirmed the new design note is linked from the
  roadmap and older covariance design notes.
- Scope-guard scan for `meta_gaussian`, `tau ~`, `rho ~`, and malformed
  `meta_known_V()` patterns found only existing `meta_known_V()` roadmap
  guardrails.

No R tests were rerun for the slice-4 design start because no R, C++, roxygen,
or executable examples changed after the slice-3 commit.

## Tests Of The Tests

No new tests were added. The next implementation commit should first route the
existing two-member fitted cases through a block registry while keeping the
current slice-3 recovery tests green, then add a three-member simulation
recovery test before exposing larger shared labels.

## Consistency Audit

The design audit checked that `ROADMAP.md`,
`docs/design/17-correlated-random-effect-blocks.md`,
`docs/design/20-coscale-correlation-pairs.md`, and
`docs/design/28-double-hierarchical-endpoint.md` now point to
`docs/design/30-labelled-covariance-block-assembler.md` for slice 4.

The prose-style pass kept the reader as an R package contributor and preserved
the stable terms `sigma`, `rho12`, `corpairs()`, `check_drm()`, `phylo()`, and
`spatial()`.

## What Did Not Go Smoothly

Nothing failed in this design-start pass. The main risk is implementation
scope: it will be tempting to jump straight to bivariate random slopes, but the
block registry should land first.

## Team Learning

Ada's integration rule is to keep the branch reviewable: one commit froze slice
3, and slice 4 starts as a design contract. Gauss and Noether's rule is that a
shared label with more than two members needs one positive-definite covariance
matrix, not a sequence of pairwise `tanh()` transforms. Rose's rule is that
roadmap text must keep pairwise bridges and full double-hierarchical covariance
separate.

## Known Limitations

The design note does not implement the block registry, TMB data contract,
`corpairs()` derivation, `profile_targets()` mapping, or `check_drm()` block
diagnostics. It also does not change the parser surface or enable any currently
rejected shared-label syntax.

## Next Actions

Implement the R-side block registry and translate the existing two-member
covariance cases through it without changing user-facing behaviour. After that,
prototype the TMB block likelihood using `UNSTRUCTURED_CORR_t` and scaled
standard deviations, then add one three-member simulation recovery test.
