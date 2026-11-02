# 2026-10-23 Gamma phylogenetic SD parity at non-unit tree height

- Goal: add a durable same-data parity check for a Gamma phylogenetic random-effect SD model when tree height is not one.
- Check: `DRMTMB_JULIA_TESTS=true DRM_JL_PATH="/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-julia" JULIA_DEPOT_PATH="/private/tmp/drmtmb-julia-depot:/Users/z3437171/.julia" OPENBLAS_NUM_THREADS=1 OMP_NUM_THREADS=1 JULIA_NUM_THREADS=1 Rscript -e 'devtools::test(filter = "julia-gamma-phylo-sd-scale", reporter = "summary")'`.
- Outcome: exit 0; 6 assertions passed; one live Julia bridge test ran. The test checks convergence, coefficient names and agreement, and tip-level SD predictions with tolerance 1e-3.
- Warnings retained: JuliaCall dependency setup failed to load `LogExpFunctionsInverseFunctionsExt` because `loglogistic` was undefined; bridge loading and the test continued. Julia also reported raw branch-length scale for tree height 6.404475.
- Evidence: `docs/dev-log/evidence/gamma-phylo-nonunit-parity-20261023/`.
- Scope: one synthetic Gamma fixture only. No recovery, interval calibration, non-ultrametric scaling, broad provider parity, or package-wide tests are established.
- Inventory search: `repo:itchyshin/drmTMB is:issue is:open "phylogenetic SD" Julia parity` returned issue #555, which tracks an unrelated Ayumi q4 Gaussian workflow. No issue was changed because it does not track this synthetic Gamma test.
