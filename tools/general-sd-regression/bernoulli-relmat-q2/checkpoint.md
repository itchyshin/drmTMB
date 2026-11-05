# Recovery checkpoint: Bernoulli relmat q2 candidate

Worktree: `/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/general-sd-regression`
at HEAD `425bee81572c625a634b2b083050c5c57c1dc1f1`, branch
`codex/general-sd-regression`. This checkout has extensive foreign dirty work;
preserve it. The current work remains uncommitted, unpushed, and unmerged.

The implementation, frozen tests, independent oracle, and raw logs are in the
paths listed in `docs/dev-log/general-sd-regression/bernoulli-relmat-q2-report.md`.
The current exact source snapshot is `source-capsule.tar.gz` with
`source-manifest.json` under this directory. Its SHA-256 is
`b59cb690ac400ca13c7844e9a09c46c765d6a5de7a6a602b62bac4cbc24d9acf` and it
contains 15 members. The manifest member hashes were recomputed from the
archive and matched exactly.

The native `relmat` q2 simulator now draws both independent scaled fields from
their fitted group SDs. The test checks same-seed marginal simulation,
precision-node SD ordering, saved-object behavior, and a two-replicate
bootstrap refit. `bootstrap_refit_one()` now omits an internal all-one weight
vector, preserving the unweighted q2 route. The focused q2 test and neighboring
ordinary Binomial SD workflow test passed. No coverage claim follows from
these smoke checks.

Next: coordinate the q2 slice with the separate Julia parity lane, then resolve
q2 profile endpoint runtime on a diagnostic fixture. The 64-group diagnostic
returned unavailable endpoints and high-information profiling exceeded the
three-minute stop rule, so do not claim q2 profile intervals work. Outer
curvature, broader capability maps, interval calibration, and release remain
open. Keep this candidate local until the broader goal's required gates pass.
No new recovery seed or threshold may be substituted for the frozen result.

Resume by reading this checkpoint and the current ownership receipt first.
Compare source hashes against `source-manifest.json` before any edit. The
repository and worktree are heavily dirty; preserve foreign changes. The
candidate remains uncommitted, unpushed, and unmerged.
