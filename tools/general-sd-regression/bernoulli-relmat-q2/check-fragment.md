### 2026-10-28: native Bernoulli logit relmat K/Q q2 candidate

Source: `R/drmTMB.R` SHA-256 `5e2107f3496ad8268222177ed6e5a766f264d12b57301c5984add0cb42118346`;
`src/drmTMB.cpp` SHA-256 `54f635fd488b0887ea6d2e1f619cdcd80d196587b8d770214b5b4594c5ddeb77`;
rebuilt `src/drmTMB.so` SHA-256 `82f5d958e0f382a65da83b723baecb617bb397bb4a125bdabad00ef278565c6b`.
Temporary `-O0 -g0`, `MAKEFLAGS=-j1`, one BLAS/OpenMP thread. The first
compile call installed an existing object without compilation; `compile-real.log`
shows the actual C++ compile and native relink after source timestamp refresh.

Frozen main fixture: seed 2026102817, 160 groups x 32 observations, 58 PASS,
0 failures. Two SD slopes 0.578755 and -0.483936 versus 0.6 and -0.5.
Native versus independent dense Laplace NLL absolute gap `8.4343e-7`;
conditional eta maximum gap `8.90e-7`. Comparator: 65 PASS, 0 failures;
K/Q NLL gap 0; reversed SD order `1.14e-13`; constant SD versus no-SD
base `4.72e-10`. Five comparator fits converged. Public base SD names and
values passed. `pdHess=NULL` because `se=FALSE`; no interval conclusion.

Exact six-context Binomial neighbors: 484 PASS, 1 existing Julia setup error
(`DRMODELS_JL_PATH` unset), 212.2 s. The exact failed q1 probit/cloglog test
block then passed 26 expectations with the pinned unchanged q1 Julia candidate;
no new q2 Julia parity claim. The first unrelated beta-binomial filter match
was interrupted and is not evidence. Standalone synthetic example passed.

Design text is in `design-advisory.md`; the shared likelihood design file has
74 foreign refs and its active owner has not integrated this paragraph.
Candidate is dirty/uncommitted. Fresh q2 marginal simulation is implemented
and passed in the focused q2 test. A two-replicate bootstrap smoke also passed
after `bootstrap_refit_one()` was corrected to omit internal all-one weights.
The q2 profile target appears in `profile_targets()`, but profile endpoint
execution is not qualified: one 64-group fixture returned unavailable
endpoints, and the frozen high-information fixture exceeded the three-minute
stop rule. Outer-Hessian checks, coverage, q2 Julia parity, and public maps
remain open.

Continuation on 2026-10-28: the full `test-binomial-relmat-q2-sd.R` and
neighboring `test-binomial-sd-target-workflows.R` passed after the bootstrap
fix. `tools::checkRd("man/simulate.drmTMB.Rd")` passed. The 15-member exact
source capsule is `source-capsule.tar.gz`, SHA-256
`b59cb690ac400ca13c7844e9a09c46c765d6a5de7a6a602b62bac4cbc24d9acf`; member
hashes are listed in `source-manifest.json` and verified against the archive.
