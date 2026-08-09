# After-task: live Workflow G `engine = "julia"` (#499 advance)

Date: 2026-08-09  
Branch: `feat/499-wfg-live-julia`  
Advances: [#499](https://github.com/itchyshin/drmTMB/issues/499) (does **not** close)

## What landed

- New skip-safe `tests/testthat/test-julia-workflow-g.R`: loads DRM.jl
  `test/parity/fixtures/<slug>/{data.csv,expected.toml}` for the eleven
  admitted Workflow G cells and fits `drmTMB(..., engine = "julia")` via
  callr, comparing coef/logLik to fixture tolerances.
- Opened FE Julia admission for the Workflow G family set in
  `drm_julia_family_tag()`; retired intentional gates
  `base_nonphylo_count` / student-as-unsupported; beta_binomial remains gated.
- Marshalling: `cbind(successes, failures)` column expansion;
  `meta_V(V = v)` / `pkg::meta_V` → positional `meta_V(v)` for DRM.jl.
- Regenerated `julia-gates.tsv` / `julia-capabilities.tsv`.

## Evidence

```text
NOT_CRAN=true DRM_JL_PATH=<DRM.jl> JULIA_HOME=$(julia -e 'print(Sys.BINDIR)') \
  Rscript -e 'pkgload::load_all(".", quiet=TRUE);
              testthat::test_file("tests/testthat/test-julia-workflow-g.R")'
# FAIL 0 | PASS 13 (11 live cells + map assertions) · ~193 s
```

Also green: `test-julia-gate-vs-engine.R` (140), `test-julia-bridge.R`,
`test-julia-phylo-count.R` gating.

## Rose claim fence

- Claim only: experimental live R round-trip of the **eleven** admitted
  Workflow G fixtures against committed 0.6.0 expected.toml numbers.
- Do **not** claim: CRAN-default Julia; full #499 closure; FIML; xfam;
  promotion beyond experimental.

## Not done / deferred

- Closing #499; FIML / missing-response deepen; regenerating fixtures;
  DRM.jl ship lanes.
