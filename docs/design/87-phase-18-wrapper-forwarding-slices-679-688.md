# Phase 18 Wrapper Forwarding Slices 679-688

Reader: `drmTMB` contributors checking whether first grid and gallery wrappers
forward the bounded-runner settings rather than bypassing the shared execution
contract.

Slices 679-688 validate the current wrapper-forwarding state. The source tree
already contains the implementation: the relevant grid writers and count
gallery wrapper expose `cores` and `backend`, pass them to the shared
replicate-runner summaries, and keep Student-t shape and bivariate residual
`rho12` bootstrap backend settings separate from the replicate layer.

## Source Evidence

- `phase18_write_gaussian_ls_grid_outputs()` accepts `cores` and `backend` and
  forwards both to `phase18_summarise_gaussian_ls_smoke()`.
- `phase18_write_count_mu_re_grid_outputs()` and
  `phase18_render_count_mu_re_gallery_smoke()` accept `cores` and `backend`
  and forward both into the paired Poisson/NB2 `mu` random-effect pilot.
- `phase18_write_student_shape_grid_outputs()` and
  `phase18_write_biv_rho12_grid_outputs()` accept replicate-layer `cores` and
  `backend` plus separate `bootstrap_cores` and `bootstrap_backend`.
- The Student-t shape and bivariate residual `rho12` grid-writer tests verify
  that a bad bootstrap backend reaches the shared bootstrap planner and errors
  with the current `none` or Unix `multicore` boundary.

## Slice Map

| Slices | Purpose | Evidence |
| --- | --- | --- |
| 679-681 | Audit first grid-writer forwarding | Gaussian location-scale, Student-t shape, and bivariate `rho12` writer source and tests checked |
| 682-684 | Audit count wrapper forwarding | Paired Poisson/NB2 `mu` grid writer and count-gallery smoke wrapper source and tests checked |
| 685-686 | Validate bootstrap backend separation | Student-t shape, bivariate `rho12`, `sim-bootstrap`, and `sim-runner` tests passed |
| 687-688 | Record current-state status and boundaries | This note, after-task report, and check-log entry keep PSOCK and nested parallelism out |

## Commands

```sh
Rscript -e "devtools::test(filter = 'phase18-(gaussian-ls-grid-writer|student-shape-grid-writer|biv-rho12-grid-writer|count-mu-random-effect-grid-writer|count-gallery-smoke-runner|count-gallery-render-helper|sim-bootstrap|sim-runner)', reporter = 'summary')"
```

## Result

The focused wrapper-forwarding bundle completed with exit code 0. The passing
files were:

- `phase18-biv-rho12-grid-writer`
- `phase18-count-gallery-render-helper`
- `phase18-count-gallery-smoke-runner`
- `phase18-count-mu-random-effect-grid-writer`
- `phase18-gaussian-ls-grid-writer`
- `phase18-sim-bootstrap`
- `phase18-sim-runner`
- `phase18-student-shape-grid-writer`

This closes Slices 679-688 as a validation and evidence slice. It does not add
PSOCK support, public bootstrap interval expansion, nested replicate/bootstrap
parallelism, formula grammar, likelihood code, or new user-facing API.
