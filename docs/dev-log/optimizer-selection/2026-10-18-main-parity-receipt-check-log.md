# Main parity receipt repair checks

Base: 476afc4ceff7bb819145af1831b9e973a97d1522. Runtime R and C++ sources remain byte-identical to that base.

Evidence directory: docs/dev-log/evidence/julia-r-parity/lss-tip-identity/.

1. Before replacement, ci-receipt-staleness.sh failed: 12 stale recorded R hashes and two new unrecorded R files; C14 passed.
2. Two Julia environment setup attempts failed before parity evaluation. Both JSON and execution logs are retained.
3. Offline Pkg.instantiate resolved the isolated pinned Julia source's cached dependencies, without changing source code. The resolved Manifest is retained.
4. run-julia-phylo-labels-public.R with explicit Julia 1.13.0, DRM.jl da8b3f8711beb5ef3186b890544c2e7850c7f194, and one thread passed in 98.531 seconds. Three converged fits; eight checks; 72 rows and 12 labels.
5. check-julia-phylo-labels-receipt.R public-001.json --current --self-test passed, rejecting all 12 mutations.
6. DRM_JL_PATH=/tmp/drmtmb-parity-drmodels-da8b3f871 bash tools/ci-receipt-staleness.sh passed all R, Julia, runner, structural and C14 checks.

Only evidence, logs and this report changed. No guard, tolerance, optimizer, numerical code or capability claim changed. Prior receipt files remain verbatim under historical-pre-2026-10-18/.
